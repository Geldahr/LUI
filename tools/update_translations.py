#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


LITERAL_TR_PATTERN = re.compile(r'TR\(\s*"((?:\\.|[^"\\])*)"\s*\)')
IDENT_TR_PATTERN = re.compile(r'TR\(\s*([A-Z_][A-Z0-9_]*)\s*\)')
CONST_ASSIGN_PATTERN = re.compile(r'(?:^|\s)(?:local\s+)?([A-Z_][A-Z0-9_]*)\s*=\s*"((?:\\.|[^"\\])*)"')
ENTRY_PATTERN = re.compile(
    r'^(?P<indent>\s*)\[(?P<key>"(?:\\.|[^"\\])*")\]\s*=\s*(?P<value>"(?:\\.|[^"\\])*")(?P<sep>\s*[,;])?(?P<comment>\s*--.*)?\s*$'
)
NOTE_COMMENT = "-- NOTE: new!"


def _lua_unescape(raw: str) -> str:
    out: list[str] = []
    index = 0
    while index < len(raw):
        ch = raw[index]
        if ch != "\\":
            out.append(ch)
            index += 1
            continue

        index += 1
        if index >= len(raw):
            out.append("\\")
            break

        esc = raw[index]
        simple = {
            "a": "\a",
            "b": "\b",
            "f": "\f",
            "n": "\n",
            "r": "\r",
            "t": "\t",
            "v": "\v",
            "\\": "\\",
            '"': '"',
            "'": "'",
        }
        if esc in simple:
            out.append(simple[esc])
            index += 1
            continue

        if esc == "x" and index + 2 < len(raw):
            hex_digits = raw[index + 1 : index + 3]
            if re.fullmatch(r"[0-9a-fA-F]{2}", hex_digits):
                out.append(chr(int(hex_digits, 16)))
                index += 3
                continue

        if esc.isdigit():
            digits = [esc]
            index += 1
            for _ in range(2):
                if index >= len(raw) or not raw[index].isdigit():
                    break
                digits.append(raw[index])
                index += 1
            out.append(chr(int("".join(digits), 10)))
            continue

        out.append(esc)
        index += 1

    return "".join(out)


def _lua_quote(value: str) -> str:
    return (
        '"'
        + value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "\\r").replace("\n", "\\n")
        + '"'
    )


def _collect_source_strings(src_dir: Path) -> set[str]:
    strings: set[str] = set()

    for path in sorted(src_dir.rglob("*.lua")):
        if "Languages" in path.parts:
            continue

        text = path.read_text(encoding="utf-8")
        constants = {
            match.group(1): _lua_unescape(match.group(2))
            for match in CONST_ASSIGN_PATTERN.finditer(text)
        }

        for match in LITERAL_TR_PATTERN.finditer(text):
            strings.add(_lua_unescape(match.group(1)))

        for match in IDENT_TR_PATTERN.finditer(text):
            name = match.group(1)
            value = constants.get(name)
            if isinstance(value, str):
                strings.add(value)

    return strings


def _parse_translation_keys(lines: list[str]) -> set[str]:
    keys: set[str] = set()
    for line in lines:
        match = ENTRY_PATTERN.match(line)
        if match is None:
            continue
        keys.add(_lua_unescape(match.group("key")[1:-1]))
    return keys


def _find_insert_index(lines: list[str]) -> int:
    for index in range(len(lines) - 1, -1, -1):
        if lines[index].strip() == "}":
            return index
    raise ValueError("Could not find closing '}' in translation file")


def _ensure_trailing_separator(lines: list[str], insert_index: int) -> None:
    for index in range(insert_index - 1, -1, -1):
        stripped = lines[index].strip()
        if stripped == "":
            continue

        match = ENTRY_PATTERN.match(lines[index])
        if match is None:
            return

        if match.group("sep") is not None:
            return

        comment = match.group("comment") or ""
        base = lines[index]
        if comment:
            comment_index = base.index(comment)
            lines[index] = base[:comment_index] + "," + base[comment_index:]
        else:
            lines[index] = base.rstrip("\n") + ",\n"
        return


def _update_translation_file(language_path: Path, source_strings: set[str], check_only: bool) -> int:
    text = language_path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    existing_keys = _parse_translation_keys(lines)
    missing_keys = sorted(source_strings - existing_keys, key=lambda value: value.casefold())
    if not missing_keys:
        return 0

    if check_only:
        return len(missing_keys)

    insert_index = _find_insert_index(lines)
    _ensure_trailing_separator(lines, insert_index)

    new_lines = [f"    [{_lua_quote(key)}] = {_lua_quote(key)}, {NOTE_COMMENT}\n" for key in missing_keys]
    updated = lines[:insert_index] + new_lines + lines[insert_index:]
    language_path.write_text("".join(updated), encoding="utf-8")
    return len(missing_keys)


def _resolve_language_files(language_dir: Path, requested: list[str]) -> list[Path]:
    if not requested:
        return sorted(language_dir.glob("*.lua"))

    resolved: list[Path] = []
    for item in requested:
        candidate = Path(item)
        if not candidate.is_absolute():
            candidate = language_dir / item
        if candidate.suffix != ".lua":
            candidate = candidate.with_suffix(".lua")
        if not candidate.exists():
            raise FileNotFoundError(f"Language file not found: {candidate}")
        resolved.append(candidate)
    return resolved


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update Lua translation files with missing untranslated strings discovered from TR(...) calls."
    )
    parser.add_argument(
        "languages",
        nargs="*",
        help="Optional language files to update, for example: de fr or src/Languages/de.lua",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report missing translation counts without modifying files.",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    src_dir = repo_root / "src"
    language_dir = src_dir / "Languages"

    if not language_dir.is_dir():
        print(f"Language directory not found: {language_dir}", file=sys.stderr)
        return 1

    source_strings = _collect_source_strings(src_dir)
    language_files = _resolve_language_files(language_dir, args.languages)

    total_missing = 0
    for language_file in language_files:
        count = _update_translation_file(language_file, source_strings, check_only=args.check)
        total_missing += count
        action = "missing" if args.check else "added"
        print(f"{language_file.relative_to(repo_root)}: {count} {action}")

    if args.check and total_missing > 0:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
