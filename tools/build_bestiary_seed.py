#!/usr/bin/env python3

from __future__ import annotations

import argparse
import html
import http.client
import json
import re
import sys
import time
import urllib.parse
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path


API_URL = "https://lotro-wiki.com/api.php"
USER_AGENT = "Bestiary Builder/1.0"
ROOT_CATEGORY = "Category:Creatures_by_Genus"
PAGE_BATCH_SIZE = 50
REQUEST_DELAY_SECONDS = 0.05
REQUEST_MAX_RETRIES = 4
REQUEST_RETRY_DELAY_SECONDS = 1.0

COMBAT_EFFECTIVENESS_FIELDS: list[tuple[str, str]] = [
    ("f", "finesse"),
    ("fm", "conj-immune"),
    ("sm", "stun_mez-imm"),
    ("rt", "root-immune"),
]

RESISTANCE_FIELDS: list[tuple[str, str]] = [
    ("cr", "cry"),
    ("so", "song"),
    ("ta", "tactical"),
    ("ph", "physical"),
]

MITIGATION_FIELDS: list[tuple[str, str]] = [
    ("co", "common"),
    ("ad", "ancientdwarf"),
    ("fi", "fire"),
    ("be", "beleriand"),
    ("li", "light"),
    ("we", "westernesse"),
    ("sh", "shadow"),
    ("fr", "frost"),
    ("lt", "lightning"),
]


def _decode_html_text(value: str | None) -> str | None:
    if not isinstance(value, str):
        return value

    decoded = html.unescape(value)
    decoded = decoded.replace("\xa0", " ")
    return decoded


def _merge_numeric_ranges(
    current_min: int | None, current_max: int | None, next_min: int | None, next_max: int | None
) -> tuple[int | None, int | None]:
    if next_min is None and next_max is None:
        return current_min, current_max

    if next_min is None:
        next_min = next_max
    if next_max is None:
        next_max = next_min

    if current_min is None or (next_min is not None and next_min < current_min):
        current_min = next_min
    if current_max is None or (next_max is not None and next_max > current_max):
        current_max = next_max

    return current_min, current_max


def _normalize_name(name: str | None) -> str | None:
    if not isinstance(name, str):
        return None

    normalized = _decode_html_text(name)
    if not isinstance(normalized, str):
        return None

    normalized = normalized.strip()
    if normalized == "":
        return None

    if normalized.lower().startswith("the "):
        normalized = normalized[4:].strip()

    normalized = re.sub(r"\s*\.+$", "", normalized).strip()
    if normalized == "":
        return None

    return normalized


def _clean_item_name(value: str) -> str | None:
    if not isinstance(value, str):
        return None

    cleaned = _decode_html_text(value)
    if not isinstance(cleaned, str):
        return None

    cleaned = cleaned.strip()
    cleaned = cleaned.replace("_", " ")
    cleaned = re.sub(r"^Item:", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"<!--.*?-->", "", cleaned)
    cleaned = cleaned.strip(" \t\r\n|{}[]")
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if cleaned == "":
        return None

    return cleaned


def _clean_reference_name(value: str | None) -> str | None:
    if not isinstance(value, str):
        return None

    cleaned = _decode_html_text(value)
    if not isinstance(cleaned, str):
        return None

    cleaned = cleaned.strip()
    cleaned = cleaned.replace("_", " ")
    cleaned = re.sub(r"^(?:Item|Quest|Deed):", "", cleaned, flags=re.IGNORECASE)
    cleaned = cleaned.strip(" \t\r\n|{}[]:")
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if cleaned == "":
        return None

    return cleaned


def _clean_field_text(value: str | None) -> str | None:
    if not isinstance(value, str):
        return None

    cleaned = _decode_html_text(value)
    if not isinstance(cleaned, str):
        return None

    cleaned = re.sub(r"<!--.*?-->", "", cleaned, flags=re.DOTALL)
    cleaned = cleaned.replace("_", " ")
    cleaned = re.sub(r"<br\s*/?>", ", ", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"</?[^>]+>", "", cleaned)
    cleaned = re.sub(r"\[https?://[^\s\]]+\s+([^\]]+)\]", r"\1", cleaned)
    cleaned = re.sub(r"\[https?://[^\]]+\]", "", cleaned)
    cleaned = re.sub(r"\[\[([^|\]]+)\|([^\]]+)\]\]", r"\2", cleaned)
    cleaned = re.sub(r"\[\[([^\]#]+)(?:#[^\]]+)?\]\]", r"\1", cleaned)
    cleaned = re.sub(r"\{\{[^{}]*\}\}", "", cleaned)
    cleaned = cleaned.replace("'''", "").replace("''", "")
    cleaned = re.sub(r"\s*,\s*", ", ", cleaned)
    cleaned = re.sub(r"\s*;\s*", "; ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" \t\r\n,;|-")
    if cleaned == "":
        return None

    return cleaned


def _parse_range(value: str | None) -> tuple[int | None, int | None]:
    if not isinstance(value, str):
        return None, None

    numbers = [int(token.replace(",", "")) for token in re.findall(r"\d[\d,]*", value)]
    if not numbers:
        return None, None

    return min(numbers), max(numbers)


def _lua_quote(value: str) -> str:
    return (
        '"'
        + value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "\\r").replace("\n", "\\n")
        + '"'
    )


def _chunked(values: list[str], size: int) -> list[list[str]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def _merge_text_values(current: str | None, next_value: str | None) -> str | None:
    if not isinstance(next_value, str) or next_value == "":
        return current
    if not isinstance(current, str) or current == "":
        return next_value
    if current.lower() == next_value.lower():
        return current

    parts: list[str] = []
    seen: set[str] = set()

    for source in (current, next_value):
        for part in source.split(" / "):
            candidate = part.strip()
            if candidate == "":
                continue

            key = candidate.lower()
            if key in seen:
                continue

            seen.add(key)
            parts.append(candidate)

    return " / ".join(parts)


def _merge_field_group(
    current: dict[str, str], params: dict[str, str], client: "WikiClient", field_defs: list[tuple[str, str]]
) -> dict[str, str]:
    for short_key, param_name in field_defs:
        next_value = _clean_field_text(_maybe_expand(client, params.get(param_name)))
        if isinstance(current.get(short_key), str) and current[short_key] != "":
            continue
        if isinstance(next_value, str) and next_value != "":
            current[short_key] = next_value

    return current


@dataclass
class PageRef:
    genus: str
    subcategory: str | None
    depth: int


def _is_better_ref(current: PageRef | None, candidate: PageRef) -> bool:
    if current is None:
        return True
    if candidate.depth != current.depth:
        return candidate.depth > current.depth
    if current.subcategory is None and candidate.subcategory is not None:
        return True
    return False


class WikiClient:
    def __init__(self) -> None:
        self._opener = urllib.request.build_opener()
        self._opener.addheaders = [("User-Agent", USER_AGENT)]
        self._expand_cache: dict[str, str] = {}

    def get_json(self, params: dict[str, str]) -> dict:
        query = urllib.parse.urlencode(params)
        request = urllib.request.Request(f"{API_URL}?{query}")

        for attempt in range(REQUEST_MAX_RETRIES):
            try:
                with self._opener.open(request, timeout=60) as response:
                    return json.load(response)
            except (http.client.HTTPException, TimeoutError, urllib.error.URLError) as error:
                if attempt + 1 >= REQUEST_MAX_RETRIES:
                    raise error
                time.sleep(REQUEST_RETRY_DELAY_SECONDS * (attempt + 1))

    def expand_text(self, text: str) -> str:
        cached = self._expand_cache.get(text)
        if cached is not None:
            return cached

        payload = self.get_json(
            {
                "action": "expandtemplates",
                "text": text,
                "prop": "wikitext",
                "format": "json",
            }
        )
        expanded = payload.get("expandtemplates", {}).get("wikitext")
        if not isinstance(expanded, str):
            expanded = text

        self._expand_cache[text] = expanded
        time.sleep(REQUEST_DELAY_SECONDS)
        return expanded


def _category_members(client: WikiClient, title: str) -> list[dict]:
    members: list[dict] = []
    continuation: dict[str, str] = {}

    while True:
        params = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": title,
            "cmlimit": "max",
            "format": "json",
        }
        params.update(continuation)
        payload = client.get_json(params)
        members.extend(payload.get("query", {}).get("categorymembers", []))

        if "continue" not in payload:
            break

        continuation = payload["continue"]
        time.sleep(REQUEST_DELAY_SECONDS)

    return members


def _strip_category_prefix(title: str) -> str:
    title = _decode_html_text(title) or title
    if title.startswith("Category:"):
        return title[len("Category:") :]
    return title


def _discover_pages(client: WikiClient) -> dict[str, PageRef]:
    page_refs: dict[str, PageRef] = {}
    visited_categories: set[str] = set()

    root_members = _category_members(client, ROOT_CATEGORY)
    genus_categories = sorted(
        member["title"]
        for member in root_members
        if member.get("ns") == 14 and member.get("title", "").startswith("Category:")
    )

    def walk(category_title: str, genus: str, subcategory: str | None, depth: int) -> None:
        if category_title in visited_categories:
            return
        visited_categories.add(category_title)

        for member in _category_members(client, category_title):
            namespace = member.get("ns")
            title = member.get("title")
            if not isinstance(title, str):
                continue

            if namespace == 14 and title.startswith("Category:"):
                nested_title = _strip_category_prefix(title)
                next_subcategory = nested_title
                walk(title, genus, next_subcategory, depth + 1)
                continue

            if namespace != 0:
                continue

            candidate = PageRef(genus=genus, subcategory=subcategory, depth=depth)
            current = page_refs.get(title)
            if _is_better_ref(current, candidate):
                page_refs[title] = candidate

        time.sleep(REQUEST_DELAY_SECONDS)

    for category_title in genus_categories:
        genus = _strip_category_prefix(category_title)
        walk(category_title, genus, None, 0)

    return page_refs


def _extract_creature_param_sets(content: str) -> list[dict[str, str]]:
    params_list: list[dict[str, str]] = []
    params: dict[str, str] | None = None

    for raw_line in content.splitlines():
        line = raw_line.strip()
        if params is None:
            if line.startswith("{{Creature"):
                params = {}
            continue

        if line.startswith("}}"):
            params_list.append(params)
            params = None
            continue
        if not line.startswith("|"):
            continue

        key, separator, value = line[1:].partition("=")
        if separator != "=":
            continue

        params[key.strip().lower()] = value.strip()

    return params_list


def _extract_item_section(content: str, heading: str) -> list[str]:
    section_match = re.search(
        rf"==\s*{re.escape(heading)}\s*==\s*(.*?)(?=\n==[^=].*?==|\Z)", content, re.DOTALL | re.IGNORECASE
    )
    if section_match is None:
        return []

    section = section_match.group(1)
    names: set[str] = set()

    for alias, target in re.findall(r"\[\[(Item:[^|\]]+)(?:\|([^\]]+))?\]\]", section):
        item_name = _clean_item_name(target or alias)
        if item_name is not None:
            names.add(item_name)

    for target in re.findall(r"(?<!\[)\|+\s*(Item:[^|\]\n}]+)", section):
        item_name = _clean_item_name(target)
        if item_name is not None:
            names.add(item_name)

    return sorted(names, key=lambda value: value.lower())


def _extract_drops(content: str) -> list[str]:
    return _extract_item_section(content, "Drops")


def _extract_chest_drops(content: str) -> list[str]:
    chest_drops = _extract_item_section(content, "Chest Drops")
    if len(chest_drops) > 0:
        return chest_drops
    return _extract_item_section(content, "Chest Drop")


def _extract_section_items(content: str, heading: str) -> list[str]:
    section_match = re.search(
        rf"==\s*{re.escape(heading)}\s*==\s*(.*?)(?=\n==[^=].*?==|\Z)", content, re.DOTALL | re.IGNORECASE
    )
    if section_match is None:
        return []

    items: list[str] = []
    seen: set[str] = set()

    def append_unique(value: str | None) -> None:
        if not isinstance(value, str) or value == "":
            return

        key = value.lower()
        if key in seen:
            return

        seen.add(key)
        items.append(value)

    section = section_match.group(1)

    for target in re.findall(r"\{\{\s*:([^|}\n]+)(?:\|[^}]*)?\}\}", section):
        append_unique(_clean_reference_name(target))

    for target, alias in re.findall(r"\[\[([^|\]#]+)(?:#[^\]|]+)?(?:\|([^\]]+))?\]\]", section):
        append_unique(_clean_reference_name(alias or target))

    if len(items) > 0:
        return items

    for raw_line in section.splitlines():
        line = re.sub(r"^[*#:;]+\s*", "", raw_line.strip())
        append_unique(_clean_field_text(line))

    return items


def _merge_ordered_unique_strings(current: list[str], next_values: list[str]) -> list[str]:
    if not isinstance(current, list):
        current = []

    seen = {value.lower() for value in current if isinstance(value, str) and value != ""}
    for value in next_values:
        if not isinstance(value, str) or value == "":
            continue

        key = value.lower()
        if key in seen:
            continue

        seen.add(key)
        current.append(value)

    return current


def _maybe_expand(client: WikiClient, value: str | None) -> str | None:
    if not isinstance(value, str):
        return value
    if "{{" in value or "}}" in value:
        return client.expand_text(value)
    return value


def _build_entry(page_title: str, page_ref: PageRef, content: str, client: WikiClient) -> tuple[str, dict] | None:
    params_list = _extract_creature_param_sets(content)
    if not params_list:
        return None

    level_min = None
    level_max = None
    morale_min = None
    morale_max = None
    power_min = None
    power_max = None
    display_name = None
    species = None
    region = None
    area = None
    instance = None
    creature_type = None
    combat_effectiveness: dict[str, str] = {}
    resistances: dict[str, str] = {}
    mitigation: dict[str, str] = {}
    abilities = _extract_section_items(content, "Abilities")
    quest_involvement = _extract_section_items(content, "Quest Involvement")
    deed_involvement = _extract_section_items(content, "Deed Involvement")

    for params in params_list:
        if display_name is None and isinstance(params.get("name"), str):
            display_name = params.get("name")
        species = _merge_text_values(species, _clean_field_text(_maybe_expand(client, params.get("species"))))

        region = _merge_text_values(region, _clean_field_text(_maybe_expand(client, params.get("location"))))
        area = _merge_text_values(area, _clean_field_text(_maybe_expand(client, params.get("area"))))
        instance = _merge_text_values(instance, _clean_field_text(_maybe_expand(client, params.get("instance"))))
        creature_type = _merge_text_values(
            creature_type, _clean_field_text(_maybe_expand(client, params.get("type")))
        )
        combat_effectiveness = _merge_field_group(combat_effectiveness, params, client, COMBAT_EFFECTIVENESS_FIELDS)
        resistances = _merge_field_group(resistances, params, client, RESISTANCE_FIELDS)
        mitigation = _merge_field_group(mitigation, params, client, MITIGATION_FIELDS)

        next_level_min, next_level_max = _parse_range(_maybe_expand(client, params.get("level")))
        next_morale_min, next_morale_max = _parse_range(_maybe_expand(client, params.get("max-health")))
        next_power_min, next_power_max = _parse_range(_maybe_expand(client, params.get("max-power")))
        next_wrath_min, next_wrath_max = _parse_range(_maybe_expand(client, params.get("max-wrath")))

        if next_power_min is None:
            next_power_min, next_power_max = next_wrath_min, next_wrath_max

        level_min, level_max = _merge_numeric_ranges(level_min, level_max, next_level_min, next_level_max)
        morale_min, morale_max = _merge_numeric_ranges(morale_min, morale_max, next_morale_min, next_morale_max)
        power_min, power_max = _merge_numeric_ranges(power_min, power_max, next_power_min, next_power_max)

    display_name = _decode_html_text(display_name or page_title)
    normalized_name = _normalize_name(display_name)
    if normalized_name is None:
        return None

    genus = _decode_html_text(page_ref.genus)
    subcategory = _decode_html_text(page_ref.subcategory)
    species = _decode_html_text(species)
    if (subcategory is None or subcategory == genus) and isinstance(species, str) and species.strip() != "":
        subcategory = species.strip()

    drops = _extract_drops(content)
    chest_drops = _extract_chest_drops(content)
    if (
        level_min is None
        and morale_min is None
        and power_min is None
        and len(drops) == 0
        and len(chest_drops) == 0
        and genus is None
        and subcategory is None
        and region is None
        and area is None
        and instance is None
        and creature_type is None
        and len(combat_effectiveness) == 0
        and len(resistances) == 0
        and len(mitigation) == 0
        and len(abilities) == 0
        and len(quest_involvement) == 0
        and len(deed_involvement) == 0
    ):
        return None

    entry: dict[str, object] = {}
    if display_name != normalized_name:
        entry["n"] = display_name
    if genus:
        entry["g"] = genus
    if subcategory and subcategory != genus:
        entry["s"] = subcategory
    if species:
        entry["sp"] = species
    if region:
        entry["r"] = region
    if area:
        entry["a"] = area
    if instance:
        entry["i"] = instance
    if creature_type:
        entry["t"] = creature_type
    if level_min is not None:
        entry["l"] = [level_min, level_max]
    if morale_min is not None:
        entry["m"] = [morale_min, morale_max]
    if power_min is not None:
        entry["p"] = [power_min, power_max]
    if combat_effectiveness:
        entry["ce"] = combat_effectiveness
    if resistances:
        entry["rs"] = resistances
    if mitigation:
        entry["mi"] = mitigation
    if abilities:
        entry["ab"] = abilities
    if quest_involvement:
        entry["qi"] = quest_involvement
    if deed_involvement:
        entry["di"] = deed_involvement
    if drops:
        entry["w"] = drops
    if chest_drops:
        entry["cw"] = chest_drops

    if not entry:
        return None

    return normalized_name, entry


def _serialize_lua_field_group(values: dict[str, str], field_defs: list[tuple[str, str]]) -> str:
    parts: list[str] = []
    for short_key, _ in field_defs:
        value = values.get(short_key)
        if isinstance(value, str) and value != "":
            parts.append(f"{short_key} = {_lua_quote(value)}")

    return "{ " + ", ".join(parts) + " }"


def _fetch_page_wikitext(client: WikiClient, titles: list[str]) -> dict[str, str]:
    pages_by_title: dict[str, str] = {}

    for chunk in _chunked(titles, PAGE_BATCH_SIZE):
        params = {
            "action": "query",
            "prop": "revisions",
            "rvslots": "main",
            "rvprop": "content",
            "formatversion": "2",
            "format": "json",
            "titles": "|".join(chunk),
        }
        payload = client.get_json(params)
        for page in payload.get("query", {}).get("pages", []):
            title = page.get("title")
            revisions = page.get("revisions") or []
            if not isinstance(title, str) or not revisions:
                continue

            content = revisions[0].get("slots", {}).get("main", {}).get("content")
            if isinstance(content, str):
                pages_by_title[title] = content

        time.sleep(REQUEST_DELAY_SECONDS)

    return pages_by_title


def _serialize_lua_entry(entry: dict[str, object]) -> str:
    parts: list[str] = []

    if "n" in entry:
        parts.append(f"n = {_lua_quote(entry['n'])}")
    if "g" in entry:
        parts.append(f"g = {_lua_quote(entry['g'])}")
    if "s" in entry:
        parts.append(f"s = {_lua_quote(entry['s'])}")
    if "sp" in entry:
        parts.append(f"sp = {_lua_quote(entry['sp'])}")
    if isinstance(entry.get("r"), str):
        parts.append(f"r = {_lua_quote(entry['r'])}")
    if isinstance(entry.get("a"), str):
        parts.append(f"a = {_lua_quote(entry['a'])}")
    if isinstance(entry.get("i"), str):
        parts.append(f"i = {_lua_quote(entry['i'])}")
    if isinstance(entry.get("t"), str):
        parts.append(f"t = {_lua_quote(entry['t'])}")
    if "l" in entry:
        level_range = entry["l"]
        parts.append(f"l = {{ {level_range[0]}, {level_range[1]} }}")
    if "m" in entry:
        morale_range = entry["m"]
        parts.append(f"m = {{ {morale_range[0]}, {morale_range[1]} }}")
    if "p" in entry:
        power_range = entry["p"]
        parts.append(f"p = {{ {power_range[0]}, {power_range[1]} }}")
    if isinstance(entry.get("ce"), dict):
        parts.append(f"ce = {_serialize_lua_field_group(entry['ce'], COMBAT_EFFECTIVENESS_FIELDS)}")
    if isinstance(entry.get("rs"), dict):
        parts.append(f"rs = {_serialize_lua_field_group(entry['rs'], RESISTANCE_FIELDS)}")
    if isinstance(entry.get("mi"), dict):
        parts.append(f"mi = {_serialize_lua_field_group(entry['mi'], MITIGATION_FIELDS)}")
    if "ab" in entry:
        abilities = ", ".join(_lua_quote(ability) for ability in entry["ab"])
        parts.append(f"ab = {{ {abilities} }}")
    if "qi" in entry:
        quest_involvement = ", ".join(_lua_quote(quest_name) for quest_name in entry["qi"])
        parts.append(f"qi = {{ {quest_involvement} }}")
    if "di" in entry:
        deed_involvement = ", ".join(_lua_quote(deed_name) for deed_name in entry["di"])
        parts.append(f"di = {{ {deed_involvement} }}")
    if "w" in entry:
        drops = ", ".join(_lua_quote(drop) for drop in entry["w"])
        parts.append(f"w = {{ {drops} }}")
    if "cw" in entry:
        chest_drops = ", ".join(_lua_quote(drop) for drop in entry["cw"])
        parts.append(f"cw = {{ {chest_drops} }}")

    return "{ " + ", ".join(parts) + " }"


def _write_lua_file(output_path: Path, entries: dict[str, dict]) -> None:
    lines = [
        "Bestiary = Bestiary or {}",
        "-- Generated from Lotro-Wiki creature pages by tools/build_bestiary_seed.py.",
        "Bestiary.Data = {",
    ]

    for key in sorted(entries.keys(), key=lambda value: value.lower()):
        lines.append(f"    [{_lua_quote(key)}] = {_serialize_lua_entry(entries[key])},")

    lines.append("}")
    lines.append("")
    output_path.write_text("\n".join(lines), encoding="utf-8")


def _merge_entry_field_group(current: dict, entry: dict, field_name: str, field_defs: list[tuple[str, str]]) -> None:
    next_values = entry.get(field_name)
    if not isinstance(next_values, dict):
        return

    current_values = current.get(field_name)
    if not isinstance(current_values, dict):
        current_values = {}
        current[field_name] = current_values

    for short_key, _ in field_defs:
        if isinstance(current_values.get(short_key), str) and current_values[short_key] != "":
            continue
        next_value = next_values.get(short_key)
        if isinstance(next_value, str) and next_value != "":
            current_values[short_key] = next_value


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the seeded LUI bestiary data file from Lotro-Wiki.")
    parser.add_argument(
        "--output",
        default="src/Bestiary/data.lua",
        help="Relative output path for the generated Lua data file.",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    output_path = repo_root / args.output

    client = WikiClient()
    page_refs = _discover_pages(client)
    titles = sorted(page_refs.keys(), key=lambda value: value.lower())
    contents = _fetch_page_wikitext(client, titles)

    entries: dict[str, dict] = {}
    skipped_titles: list[str] = []

    for title in titles:
        content = contents.get(title)
        if content is None:
            skipped_titles.append(title)
            continue

        built = _build_entry(title, page_refs[title], content, client)
        if built is None:
            skipped_titles.append(title)
            continue

        key, entry = built
        current = entries.get(key)
        if current is None:
            entries[key] = entry
            continue

        if "n" not in current and "n" in entry:
            current["n"] = entry["n"]
        if "g" not in current and "g" in entry:
            current["g"] = entry["g"]
        if "s" not in current and "s" in entry:
            current["s"] = entry["s"]
        merged_species = _merge_text_values(current.get("sp"), entry.get("sp"))
        if isinstance(merged_species, str) and merged_species != "":
            current["sp"] = merged_species
        merged_type = _merge_text_values(current.get("t"), entry.get("t"))
        if isinstance(merged_type, str) and merged_type != "":
            current["t"] = merged_type
        for field_name in ("r", "a", "i"):
            merged_text = _merge_text_values(current.get(field_name), entry.get(field_name))
            if isinstance(merged_text, str) and merged_text != "":
                current[field_name] = merged_text

        for field_name in ("l", "m", "p"):
            next_range = entry.get(field_name)
            if next_range is None:
                continue

            current_range = current.get(field_name)
            if current_range is None:
                current[field_name] = list(next_range)
            else:
                current[field_name][0] = min(current_range[0], next_range[0])
                current[field_name][1] = max(current_range[1], next_range[1])

        if "w" in entry:
            current_drops = set(current.get("w", []))
            current_drops.update(entry["w"])
            current["w"] = sorted(current_drops, key=lambda value: value.lower())
        if "cw" in entry:
            current_chest_drops = set(current.get("cw", []))
            current_chest_drops.update(entry["cw"])
            current["cw"] = sorted(current_chest_drops, key=lambda value: value.lower())

        _merge_entry_field_group(current, entry, "ce", COMBAT_EFFECTIVENESS_FIELDS)
        _merge_entry_field_group(current, entry, "rs", RESISTANCE_FIELDS)
        _merge_entry_field_group(current, entry, "mi", MITIGATION_FIELDS)
        current["ab"] = _merge_ordered_unique_strings(current.get("ab", []), entry.get("ab", []))
        current["qi"] = _merge_ordered_unique_strings(current.get("qi", []), entry.get("qi", []))
        current["di"] = _merge_ordered_unique_strings(current.get("di", []), entry.get("di", []))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    _write_lua_file(output_path, entries)

    print(
        json.dumps(
            {
                "pages_discovered": len(page_refs),
                "pages_fetched": len(contents),
                "entries_written": len(entries),
                "pages_skipped": len(skipped_titles),
                "output": str(output_path),
            },
            indent=2,
        )
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
