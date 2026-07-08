"""String tables (localized labels) and enum mappers.

String tables live in the client_local_<Lang>.dat archives
(DID range 0x25000000-0x26FFFFFF). A StringInfo (table DID, token)
resolves through them, per language.
"""
import os
import re

from .binio import Reader
from .properties import read_string_info, StringInfo


class StringTable:
    __slots__ = ("did", "entries")

    def __init__(self, did):
        self.did = did
        self.entries = {}  # token -> (parts, variable_ids)


def load_string_table(buf):
    r = Reader(buf)
    did = r.u32()
    table = StringTable(did)
    unknown = r.u32()
    if unknown > 2:
        raise ValueError("string table 0x%08X: header value %d" % (did, unknown))
    for _ in range(r.tsize()):
        token = r.u32()
        zero = r.u32()
        if zero != 0:
            raise ValueError("string table 0x%08X: entry pad %d" % (did, zero))
        parts = [r.utf16_string() for _ in range(r.u32())]
        variable_ids = [r.u32() for _ in range(r.u32())]
        if r.boolean():  # optional variable names, unused (hash names win)
            for _ in range(r.u32()):
                r.utf16_string()
        table.entries[token] = (parts, variable_ids)
    return table


# ---- variable hash names ---------------------------------------------------

def _elf_hash(s):
    h = 0
    for ch in s.encode("ascii"):
        h = ((h << 4) + ch) & 0xFFFFFFFFFFFFFFFF
        h ^= (h & 0xF0000000) >> 24
    return h & 0xFFFFFFF


def _load_known_variables():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "KnownVariables.txt")
    text = open(path, encoding="utf-8").read()
    names = re.findall(r'"([^"]+)"', text)
    table = {_elf_hash(name): name for name in names}
    # extra hashes not derivable from the name list
    table.update({65808821: "PLAYER", 246996147: "CLASS", 65824981: "RACE",
                  788899: "CURRENT", 104736179: "MAX"})
    return table


_KNOWN_VARIABLES = None


def variable_name(hash_value):
    global _KNOWN_VARIABLES
    if _KNOWN_VARIABLES is None:
        _KNOWN_VARIABLES = _load_known_variables()
    return _KNOWN_VARIABLES.get(hash_value)


# ---- inline variable syntax (#N:{a|b} references) -------------------------

_TAG_CODES = set("1bBCDEfFGHIKLmMnNOpPRSTUvVW")


def _parse_option(option):
    """-> (text, rendered_tags or None); negated tags render as !x."""
    bracket = option.find("[")
    if bracket == -1:
        return (option, None)
    close = option.find("]", bracket + 1)
    if close == -1:
        close = len(option)
    tags_str = option[bracket + 1:close]
    tags = []
    negative = False
    for ch in tags_str:
        if ch == ",":
            continue
        if ch == "!":
            negative = True
            continue
        if ch in _TAG_CODES:
            tags.append(("!" + ch) if negative else ch)
        negative = False
    return (option[:bracket], tags)


def _parse_variable_ref(text, index):
    """Parse one #N:{...} reference -> (start, end, number, options)."""
    sharp = text.find("#", index)
    if sharp == -1:
        return None
    colon = text.find(":", sharp + 1)
    if colon == -1:
        return None
    start = sharp
    if colon == sharp + 1:
        colon = text.find(":", sharp + 2)
        sharp += 1
        if colon == -1:
            return None
    number_str = text[sharp + 1:colon]
    try:
        number = int(number_str)
    except ValueError:
        return None
    options = None
    end = colon
    open_brace = text.find("{", colon + 1)
    if open_brace != -1:
        close_brace = text.find("}", open_brace + 1)
        if close_brace != -1:
            end = close_brace
        options = [_parse_option(o)
                   for o in text[open_brace + 1:close_brace].split("|")]
    return (start, end, number, options)


def _parse_parts(text):
    """Split a label part into ('lit', s) / ('var', number, options) nodes."""
    out = []
    index = 0
    while index < len(text):
        ref = _parse_variable_ref(text, index)
        if ref is None:
            out.append(("lit", text[index:]))
            break
        start, end, number, options = ref
        if start > index:
            out.append(("lit", text[index:start]))
        out.append(("var", number, options))
        index = end + 1
    return out


def render_entry(parts, variable_ids):
    """Join label parts, resolving inline #N:{a[m]|b[f]} variable
    references into ${VAR:a[m]|b[f]} templates."""
    decoded = [_parse_parts(part) if part else [("lit", "")] for part in parts]
    has_variables = any(node[0] == "var" for nodes in decoded for node in nodes)

    if not has_variables:
        out = [parts[0]]
        for i in range(1, len(parts)):
            if len(variable_ids) >= i:
                name = variable_name(variable_ids[i - 1])
                if name is None:
                    name = "#%d" % variable_ids[i - 1]
                out.append("${%s}" % name)
            out.append(parts[i])
        return "".join(out)

    # first-seen variable index -> next variable id
    names = {}
    position = 0
    for nodes in decoded:
        for node in nodes:
            if node[0] == "var" and node[1] not in names:
                var_id = variable_ids[position]
                name = variable_name(var_id)
                names[node[1]] = name if name is not None else str(var_id)
                position += 1

    out = []
    for nodes in decoded:
        for node in nodes:
            if node[0] == "lit":
                out.append(node[1])
                continue
            _, number, options = node
            if options is None:
                if number > 0:
                    out.append("${%s}" % names[number])
                continue
            rendered = []
            for text, tags in options:
                if tags:
                    rendered.append("%s[%s]" % (text, ",".join(tags)))
                else:
                    rendered.append(text)
            out.append("${%s:%s}" % (names[number], "|".join(rendered)))
    return "".join(out)


_MARKS = re.compile(r"\[[^\]]*\]|\{\[|\]\}")


def strip_marks(text):
    """Remove gender/declension mark blocks like [...] from a rendered name."""
    return _MARKS.sub("", text).strip()


class EnumMapper:
    __slots__ = ("did", "base_did", "entries")

    def __init__(self, did):
        self.did = did
        self.base_did = 0
        self.entries = {}  # code -> label

    def get(self, code, default=None):
        return self.entries.get(code, default)


def load_enum_mapper(buf, resolve_string_info=None):
    """Decode an enum mapper resource.

    resolve_string_info: optional callable(StringInfo) -> str used for
    localized entry labels; when None those entries keep their raw
    pascal-string label from the first section.
    """
    raw = load_enum_raw(buf)
    mapper = EnumMapper(raw.did)
    mapper.base_did = raw.base_did
    mapper.entries.update(raw.entries)
    if resolve_string_info is not None:
        for key, info in raw.string_infos.items():
            label = resolve_string_info(info)
            if label is not None:
                mapper.entries[key] = label
    return mapper


class RawEnum:
    """Enum mapper with unresolved string infos (render per language)."""

    __slots__ = ("did", "base_did", "entries", "string_infos")

    def __init__(self, did):
        self.did = did
        self.base_did = 0
        self.entries = {}       # code -> raw pascal label
        self.string_infos = {}  # code -> StringInfo (localizable label)


def load_enum_raw(buf):
    r = Reader(buf)
    raw = RawEnum(r.u32())
    raw.base_did = r.u32()
    for _ in range(r.tsize()):
        key = r.u32()
        raw.entries[key] = r.pascal_string()
    for _ in range(r.tsize()):
        key = r.u32()
        raw.string_infos[key] = read_string_info(r)
    if r.remaining() > 0:
        raise ValueError("enum 0x%08X: %d trailing bytes" % (
            raw.did, r.remaining()))
    return raw
