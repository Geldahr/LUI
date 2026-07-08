# data-extractor — LOTRO game data → packed Lua

Builds the LUI Items and Recipes databases directly from the LOTRO
client's `.dat` archives. Pure Python 3 stdlib, no intermediate files:
`extract.py` scans the client data once and calls
`tools/lore2lua/convert.py` in-process to emit the packed Lua under
`src/Data`.

## Usage

```
python3 tools/data-extractor/extract.py "G:\The Lord of the Rings Online"
```

Defaults: `--out src/Data --langs de,en,fr --db items,recipes`.
Windows and WSL paths both work. Runtime ~2.5 min. `--json <path>`
optionally dumps the raw records for inspection.

Localized names come from the client's locale archives
(`client_local_English/DE/FR.dat`) — keep all three languages installed
and patched. Label tables (item classes, qualities, crafting
categories, professions, player classes) come from the game's enum
mappers; classification, tracery and consumable data from item
properties.

## Layout

| Module | Role |
|---|---|
| `extract.py` | entry point: scan, decode items + recipes, pack via lore2lua |
| `lotrodat/archive.py` | `.dat` container: superblock, B-tree directory, block chains, zlib payloads |
| `lotrodat/properties.py` | property-definitions registry (DID `0x34000000`) + PropertiesSet decoding (all 22 value types); object properties live at `DID + 0x9000000` |
| `lotrodat/strings.py` | localized string tables, enum mappers, inline gender-variant rendering (`${PLAYERNAME:a[m]|b[f]}`) |
| `lotrodat/facade.py` | DID→archive routing, caching, per-language resolution |
| `lotrodat/__main__.py` | debug CLI: `info` / `props` / `raw` / `enum` / `scan` |

```
PYTHONPATH=tools/data-extractor python3 -m lotrodat props <game_dir> <did> --object [--lang fr]
```

## Pending

- **Nodes db** (`convert.py --db nodes`) still expects the legacy XML
  layout — port loot/container/craft-tier extraction before the next
  Nodes regeneration.
- **Bestiary localization** (`convert.py --db bestiary`) still expects
  legacy mob-name XML — port from MOB WState entries (class 1723,
  found via the `scan` CLI) before the next bestiary regeneration.
- The wiki bestiary tooling and other local-only artifacts live in
  `.tools/` (untracked).
