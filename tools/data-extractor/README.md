# data-extractor — LOTRO game data → packed Lua

Builds the LUI game-data databases (items, recipes, quests + deeds,
NPCs, skills, cooldown groups) directly from the LOTRO client's `.dat`
archives. Pure Python 3 stdlib, no intermediate files: `extract.py`
scans the client data once and calls `tools/lore2lua/convert.py`
in-process to emit the packed Lua under `src/Data`.

## Usage

One command, run from the repo root, regenerates **all** databases
under `src/Data`; the game directory is the only required argument
(Windows and WSL paths both work):

```
python3 tools/data-extractor/extract.py "G:\The Lord of the Rings Online"
```

Defaults: `--out src/Data --langs de,en,fr` and
`--db items,recipes,quests,npcs,skills,cooldown_groups` — every
database this pipeline produces. Pass `--db` with a comma-separated
subset to regenerate only some of them. Runtime ~2.5 min.
`--json <path>` optionally dumps the raw records for inspection.
Review the `src/Data` diff and commit the regenerated files like any
other change. Nodes and Bestiary data are not produced by this
pipeline yet — see Pending below.

The quests db covers quests **and** deeds (20,480 records, ~95 MB raw
/ ~26 MB zipped). Numeric records: kind, challenge level, min level,
category, XP/gold/virtue-XP tiers, flags (instance/shareable/
fellowship/small-fellowship/monster-play/session/raid), repeatability
(0 = once, 1 = unlimited, n+1 = n times), lock type, next-quest link,
prerequisite quest ids, reward items (id + quantity), dialog NPC ids,
and per-objective completion conditions (event type code + count,
aligned with the condition texts). Dialog entries are
(objective index, action, NPC): action 6 at objective 0 is the
quest giver (bestower), action 5 the end/turn-in dialog, others attach
to their objective. The `npcs` db (`src/Data/Npcs`, ~0.5 MB) maps the
NPC ids referenced by quest dialogs (8,526 of them) to localized
"name \\31 title" labels. Per-language content blobs
(`texts_<lang>.lua`): description, objectives and bestower dialogs per
record — sections split by \\30, objectives by \\31, and within one
objective the description + its \"how to complete\" condition texts
(progress/lore strings) by \\29. Localized name/search blobs and
quest/deed category tables as usual. Every `search_<lang>.lua`
(items/quests/recipes) also carries `D.STOP2`: the 2-char folded needles
matching >5% of the domain's entries, which the runtime query layer
treats as "still typing" instead of paying a tens-of-ms cold blob scan
(the current checked-in files were patched to match the emitter; the
next regeneration reproduces them). Records are stored in display
order — level ascending, then folded en name — so category/level
filters list correctly with zero runtime sorting; non-en languages get
an `order_<lang>.lua` ordinal permutation with the same level order but
their own name tie-break; id lookups go through the id-sorted IDX/IDO
index blobs instead of IDS. Dev placeholder
strings baked into the client (`TBD`/`DNT` markers, the
"This is your objective description." template in all languages) are
dropped at extraction, as are the dev quests the game never shows in
the journal (the "Test" quest category, the "HIDING CONTENT" phasing
quests and the content-hiding tracker quest).
No runtime loader consumes `src/Data/Quests` yet.

The skills db (`src/Data/Skills`) is the flattened **skill → visible
buff** table: every skill (WState class 827) resolved to the buff
effects it applies, following direct effect lists, `Effect_Combo_*`
add-chains and genesis → summoned-hotspot lists. Only leaves the
player can see are kept — a real localized name (no `DNT`/`TBD`) and
`Effect_UIVisible == 1` — and condition lists (required/barring/
consumed/presence checks) are never treated as granted. Skills with no
visible buff are dropped. `records.lua` holds skill ids + category
codes + per-skill buff ordinal lists and the buff table (effect ids,
icon ids, base durations in tenths of seconds, 0 = none);
`labels_<lang>.lua` the localized skill and buff names;
`categories.lua` the localized skill-category labels. The mapping is
many-to-many: trait-rank variants are distinct skill ids sharing one
name and one skill can grant several buffs. Only player skills are
packed -- those carrying a real `Skill_Category`, i.e. the ones the
client can quickslot and the player can drag onto an Upkeep slot.
Uncategorised skills (monster/NPC skills, and internal effect-carrier
variants of player skills) are not extracted; see the comment in
`extract.py` for the trade-off. No runtime loader consumes it yet.

The cooldown-groups db (`src/Data/Skills/cooldown_groups_<lang>.lua`)
maps lowercased localized skill names to their shared-cooldown channel
(the `Skill_RecoveryChannel` property): skills on one channel recover
together, and the Cooldowns window uses this table to collapse them
into a single entry. Dev-marker names (`DNT`/`TBD`), names that map to
more than one channel (ambiguous at runtime, where the name is the
only join key), and channels left with fewer than two distinct names
are dropped at pack time.

Stackable items (`Inventory_MaxQuantity > 1`) also get their localized
plural display name (the `PluralName` item property — the form loot
messages use, "Hides"/"Felle"/"Peaux"): plurals that differ from the
singular display name are packed into `Items/names_<lang>.lua` as a
sorted PNAM/PNOFF lookup (plural text → record ordinals, same entry
format as NAME/NOFF), so "[3 Hides]" can resolve to the item record
and icon with the same binary search the singular names use.

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
