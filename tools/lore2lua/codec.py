# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Base-93 codec and Lua emission helpers for lore2lua.

Alphabet: printable ASCII 33..126 excluding ']' (93 chars), so blobs can never
close a Lua long-bracket literal. Digit d maps to byte d+33 for d < 60 and
d+34 for d >= 60 (skipping ']' = 93).
"""


def b93(value, width):
    if value < 0:
        raise ValueError("b93 cannot encode negative value %d" % value)
    chars = []
    v = value
    for _ in range(width):
        v, d = divmod(v, 93)
        chars.append(chr(d + 33 if d < 60 else d + 34))
    if v != 0:
        raise ValueError("value %d does not fit in width %d" % (value, width))
    return "".join(reversed(chars))


def u93(s, pos, width):
    """Decode width base-93 chars starting at 0-based pos (python mirror of the Lua decoder)."""
    v = 0
    for k in range(pos, pos + width):
        b = ord(s[k])
        v = v * 93 + (b - 34 if b > 93 else b - 33)
    return v


def width_for(max_value):
    w, cap = 1, 93
    while max_value >= cap:
        w += 1
        cap *= 93
    return w


def long_bracket(blob):
    """Pick a long-bracket level that cannot terminate inside blob."""
    for level in range(1, 10):
        if "]" + "=" * level + "]" not in blob:
            eq = "=" * level
            # sacrificial leading newline: Lua strips the first newline after [=[
            return "[%s[\n" % eq, "]%s]" % eq
    raise ValueError("no safe long-bracket level found")


def emit_blob(name, blob):
    op, cl = long_bracket(blob)
    return "D.%s = %s%s%s\n" % (name, op, blob, cl)
