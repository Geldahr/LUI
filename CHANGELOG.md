# Changelog

## Unreleased

### Added

- Added an `Orientation` setting (Horizontal / Vertical) to the Cooldowns window and both Expiring Effects windows (Self and Target). Vertical bars keep the icon at the chosen end (the side dropdowns now read `Left/Top` and `Right/Bottom`) and fill along the vertical axis; the remaining-time text is drawn horizontally across the bar in the same format as on horizontal bars; on thin bars it first steps the font down through the same family's smaller sizes to fit, and is dropped only when even the smallest size cannot fit — the configured thickness is never widened. The effect/skill name is hidden on vertical bars. The size settings are now axis-independent (`Item length`/`Item thickness` for cooldowns, `Bar length`/`Bar thickness` for effects), so switching orientation rotates the bars without re-entering sizes.
- Added a `Display time` setting to the Cooldowns and Expiring Effects windows to show or hide the remaining-time text on the bars (enabled by default).

### Changed

### Fixed

- Timer countdowns no longer show a `10.0s` frame when crossing the 10-second boundary: the decimal is now truncated instead of rounded, so the text reads `10s` and then `9.9s`, `9.8s`, ... (same fix for the unitless countdown on effect icons).

### Removed

## v2.0.0

### Added

- The Bestiary window is now the Encyclopedia: the bestiary became its first tab, joined by Equipment, Resources, Consumables, Housing, and Traceries item tabs with type/rarity/level filters, the shared search grammar (space = and, `|` = or, quotes = exact phrase), and result counts. Item tabs list as tables with icon, name, type, and level columns plus the link buttons. Consumables also covers recipe scrolls (grouped under a single `Recipes` type filter), stat tomes, boosters, and pipe-weed. New `/lui encyclopedia` and `/lui ency` commands open it; the old `/lui bestiary`, `/lui beast`, and `/lui b` aliases keep working.
- Added a Quests tab to the Encyclopedia with Quests and Deeds sub-tabs: 14,968 quests and 5,390 deeds extracted straight from the game client, listed with name, category, and level, searchable with the shared grammar plus category and level-range filters, fully localized (English, French, German). Clicking a row opens a quest card with the level and category, the bestowing NPC, the description, objectives, and dialog texts, and the reward items as clickable chips that link into the Encyclopedia item tabs.
- The Traceries tab covers the legendary item system: filter by tracery type, player class, usable character level (`Level` range, matched against the tracery's level band), and base item level (`iLvl` range, matched against the tracery's base — `450-499` shows the 450 tier only, never lower tiers whose enhancement cap covers it). The list is a real table with columns: icon, name, type, class, level band, base iLvl, and the enhancement limit.
- Added cross-window link buttons to Encyclopedia item rows: an anvil button opens the crafting window searched on the item (preselecting the producing recipe when it is craftable; on a recipe scroll it opens the recipe the scroll teaches), and a book button searches the bestiary for creatures dropping it (shown only for known drop names).
- Bestiary card drops that match a real item are now clickable, marked with a distinct border color: left click opens the item in the Encyclopedia on its matching tab, right click opens a context menu with `Open in Encyclopedia`, `How to craft this`, and `Show crafts using this` entries when they apply.
- Added a `Variant` selector to the crafting recipe details for multi-output recipes (choose which of the recipe's outputs to display), a `+x variants` line on their recipe list rows, and variant-aware build plans: the plan and queue show the chosen output, and the choice is saved with tracked plans.
- The crafting search and the Encyclopedia crafting links now cover critical results and alternate recipe outputs (for example `Adamant Earring of Combat` or `Carved Combat Bow`), which were previously unreachable.
- Added a `Separator color` setting under `Global > UI > Colors` for subtle interior lines such as table grid lines, independent from the border color, plus table style settings under `Global > UI > Layout`: vertical and horizontal grid line widths and an `Alternating table rows` toggle (disable it and raise the horizontal line width for a single-background look with row separators).
- Added a Resource card: double-clicking a targeted harvest node (ore deposits, branches, crop fields, scholar artifacts) opens a card showing the node's profession and tier with the in-game tier badge, what it always contains with quantity ranges (for example `Chunk of Gold Ore x1-3`), and what it may contain, with rare finds in the gold chest styling. Yield chips are clickable like bestiary card drops: left click opens the item in the Encyclopedia, right click offers the Encyclopedia and crafting actions. Node lookup is localized, so it also works on French and German clients.
- Added a `Merge similar drops` setting to the Drops window (enabled by default): picking up the same item again while its drop line is still showing adds to that line's count in place instead of stacking a duplicate line, and refreshes how long it stays visible.

### Changed

- The bestiary now works on French and German clients: localized creature names are bridged to the English bestiary data at pack time (~97% of entries; unmatched names find nothing), so target double-click cards and `/lui card` resolve localized targets. Bestiary content is displayed translated where the game data provides a label — creature names, taxonomy, tiers, locations, drops, quests, deeds, and abilities — with untranslated strings kept in English (ratings such as `Feeble` stay English). Search and chat capture stay English-only.
- The bestiary database now loads from packed local data with a background pre-warm instead of parsing a large Lua table at login, making plugin load and Encyclopedia opening faster.
- Crafting ingredient, plan, and queue rows derive their height from the item icon plus padding so icons fit exactly at every UI scale, and rows with only a name center their text vertically.
- Cross-window link buttons now always select the matching window tab (Recipes tab in crafting, Bestiary tab in the Encyclopedia).
- Stacked drops in the Drops window now show the real item: `[5 Hides]` displays as `Hide` with a count of 5, the item's icon, and its tooltip, instead of an unresolved plural line. Items whose name starts with a number (`100 Virtue XP`) are never mistaken for stacks.
- Crafting recipe lines are shorter: list rows read `Jeweller - Artisan - Level 35` (the level is the result's equip level) and the recipe details read `Jeweller - Artisan`, dropping the category that only repeated the level.

### Fixed

- Fixed the crafting critical-result row showing the normal item's icon and tooltip when the critical result is a different item with the same name (Heraldry recipes and similar); recipe lists always show the normal result.
- Fixed search text set by cross-window link buttons being invisible until the input box was clicked.
- HUD windows (cooldowns, expiring effects, drops, launcher) no longer set a window z-order, so they stop floating above every other window.
- Fixed the Recipes button in the Assets browser; it now shows properly how many known recipes can be crafted relatively to the filter applied in assets.

### Removed

- Removed the ready-ratio (`0/3`) status text from the crafting recipe details; per-ingredient readiness and the plan/queue ratios carry that information.
- Removed the Encyclopedia's `Order` title-bar menu (formerly the Bestiary order controls); bestiary results always list A-Z, matching the item tabs.

## v1.3.0

### Added

- Added a `Background effect tracking` setting to `Vitals > Fellowship` and `Vitals > Raid` (one per group, enabled by default). When disabled, LUI never reads or subscribes to that group's member effects in the background; targeting a member then shows no effects until one of their effects changes.
- Added a session earnings tooltip on the status bar Money widget that shows how much money you have gained or spent since the plugin loaded.
- Added a custom boss list under `Vitals > Boss > Custom Bosses` to show the Boss Vitals frame for your own listed target names.
- Added an `Edit > Add to Boss Targets` action to the Bestiary card that adds the shown creature to the custom boss list, disabled when it is already a boss target.
- Added Travel window `View` menu actions for switching between List and Grid display modes.
- Added Inventory window `View` menu actions for Small, Medium, and Large tile sizes.
- Added a `Global > General > Close LUI windows with Esc` setting (enabled by default) so the Escape key closes LUI windows.

### Changed

- Moved Inventory Sort and Merge actions under an `Edit` menu and made tile-size changes preserve the current row/column count while clamping the resized window to the screen.
- Effect icon countdown timers now drop the trailing `s` (for example `2.6` instead of `2.6s`) and show for the full final 10 seconds instead of the final 9.

### Fixed

- Fixed targeted fellowship/raid member effects not displaying, and disappearing on deselect/reselect, by restoring the v1.1.0 effect-manager behavior: shared managers are looked up by name again regardless of the target entity shape, and group member background tracking is re-enabled. The manager cache now lives in its own file (`target_effect_manager_cache.lua`). Note that pet and fellowship/raid member effects are still partially broken when they are targeted: the displayed effects can be missing or stale until one of their effects changes.
- Fixed target vitals not showing a freshly-summoned pet's buffs and debuffs when the pet was selected as the target.

### Removed

- Removed the exposed and persisted Inventory columns setting; inventory columns are now derived from saved window geometry.

## v1.2.0

### Added

- Added companion/pet vitals with configurable morale, power, labels, buffs, debuffs, preview support, move-mode placement, and shared cached effect tracking when the pet is selected as the target.
- Added vertical and corner resizing to the Inventory window, with capacity-aware minimum sizing so the window keeps enough rows/columns for all backpack slots while still resizing smoothly by pixels.

### Changed

- Moved Assets view/order/group/stack controls and Bestiary order controls into LuiWindow title-bar menus.

### Fixed

- Fixed vitals effect layout so `effects_height` is treated as total reserved space split between buffs and debuffs when they are on opposite sides of the frame.
- Fixed vitals effect shrinking so buffs and debuffs on the same side do not leave an empty reserved gap between the effect areas.
- Fixed live vitals positioning to match the preview when effects are split above and below the vitals, including layouts with the optional info section.

## v1.1.0

### Added

- Added the `_G.LUI` namespace as the public integration root for LUI APIs and plugin-owned runtime tables.
- Added the optional LUI Menu HUD launcher with configurable shortcuts for opening LUI features.
- Added LUI Menu settings for enablement, icon size, spacing, orientation, expansion direction, collapse-after-click behavior, and button order.
- Added LUI Menu integration with HUD move mode, saved HUD position, runtime settings refresh, and plugin unload cleanup.
- Added inventory cleanup commands in the Inventory window menu: `Sort` commands for `Category + A-Z`, `A-Z`, and `Quantity`, plus `Merge` commands for merging stacks up or down, including support for full bags, occupied buffer slots, partial stack merges, and interrupted live inventory changes.
- Added a responsive Inventory title slot count that shows used/max slots when the window has enough title space.

### Changed

- Changed the public LUI API access from `_G.LUI_API` to `_G.LUI.API` / `_G.LUI.api`.
- Centralized LUI shortcut labels, icons, availability checks, and actions so the LUI Menu and status bar shortcut buttons use the same shortcut definitions.
- Changed Inventory cleanup controls to use `Sort` and `Merge` window menus instead of an in-window action row/dropdown.
- Updated the Inventory window icon to match the LUI Menu backpack icon.
- Updated window menus so moving the mouse from an open menu to another menu opens the hovered menu.

### Removed

- Removed legacy standalone globals created by LUI; integrations should use the `_G.LUI` namespace instead.

## v1.0.3

### Added

- Added Help coverage for LUI features, hidden interactions, search syntax, status bar tokens, and command aliases.

### Changed

- Changed default raid vitals HUD X position to `0px`.

### Fixed

- Fixed hard PluginData parse failures by replacing corrupted save files with clean encoded files.
- Fixed typed PluginData decoding so malformed table values are dropped at load instead of reaching the save encoder.
- Fixed Bestiary cache merging so level morale/power observations keep their table shape.
- Fixed first-run quick setup text wrapping and spacing so longer localized text is not clipped.

## v1.0.2

### Fixed

- Fixed asset cache unload snapshots so dirty character asset changes are saved through the typed PluginData encoder.

## v1.0.1

### Added

- Added typed PluginData encoding and schema mapping for persisted settings, profiles, assets cache, and bestiary cache.

### Fixed

- Fixed German/French-client PluginData parse failures caused by locale-formatted numeric values and numeric keys.
- Fixed German/French translation loading by exporting language tables through their imported `LUI.src.Languages.*` namespaces.

## v1.0.0

### Added

- Highlight matching bestiary drops in search results, including split matches across multiple drop chips.
- Added Crafting to Bestiary links for ingredients and planned resources.
- Added locale-aware Bestiary data loading with localized drop table support.
- Added shared structured search filters across Bestiary, Crafting, and Assets, including Bestiary `loc:` / `gen:` / `lvl:` filters, Crafting rank filters, and Assets `owner:` / `store:` filters.
- Added the Drops HUD with chat-driven loot rows, move-mode support, preview, and layout settings.
- Added configurable multi-label text layouts for self, target, boss, target's target, fellowship, and raid vitals.
- Added `Vitals > General` enable toggles for Self, Target, Boss, Target's Target, Fellowship, and Raid vitals.
- Added left/right alignment settings for self, target, and boss vitals effects.
- Added Global UI settings for customizing LUI colors, backgrounds, borders, fonts, and overlays.
- Added configurable background opacity for vitals, cooldowns, and expiring effects.
- Added configurable bar opacity and matching background controls for cooldowns and expiring effects.

### Changed

- Use a distinct border color for matched drops and align chest chip backgrounds with the standard drop chip style.
- Improved Bestiary search opening for item and multi-resource queries from Crafting.
- Reorganized the configuration window around feature-first tabs with unified layouts for Vitals, Expiring Effects, Cooldowns, Drops, Inventory, Travel, and the remaining feature pages.
- Removed silent internal fallbacks across plugin wiring so missing internal modules, methods, and state now fail loudly instead of being masked.
- Self, Target, Fellowship, and Raid vitals now hand off cleanly to the built-in LotRO HUD when their LUI replacements are disabled.
- Boss vitals now follow the Target vitals enable state, while Target's Target remains independently toggleable.
- Added a new optional info box in the vitals, placed below power/wrath.
- Effects can be independently placed above or below the vitals (below the info box). There are four selectable areas around the vitals.
- Vitals now have four independent text items that can each be attached to morale, power/wrath, or the new info box.
- Made LUI windows and controls use the Global UI style settings consistently.
- Aligned color-related settings and configuration columns across feature pages.

### Fixed

- Fixed empty drop highlight states when a bestiary row matched the active search.
- Fixed Bestiary tracker global wiring and unload/update ordering issues that could crash Bestiary window updates.
- Fixed crafting dependency expansion to ignore obsolete item conversion recipes, preventing obsolete ingredients from polluting material chains.
- Fixed cooldown rows so long skill names no longer hide timers by giving the timer its own reserved column and wrapping long titles.
- Fixed self and target expiring effect rows to use the same reserved timer column layout, width clamping, and title wrapping behavior.
- Fixed group vitals move mode to keep the move overlay inside the real widget footprint while clearing live member content and stale bindings.
- Fixed timed row and drop row width calculations to reserve space from real timer and quantity text widths instead of fixed guesses.
- Fixed canceling Global UI style edits so unapplied changes are not kept.
- Fixed previews when temporarily clearing numeric settings fields.

### Removed

- Removed the old single expiring-effect bar color setting.

## v0.5.0

### Added

- Added the crafting browser with recipe search, tracked plans, and startup integration.
- Added the travel window with shared helpers for travel skills and routes.
- Added the new window UI and expanded localized strings for English, German, and French.

### Changed

- Refined crafting UX by hiding empty plan status text and starting the crafting store when enabled.
- Applied general cleanup for the v0.5.0 feature set and release packaging.

### Fixed

- Fixed party target effect source restore.
- Fixed HUD widget visibility refresh for LOTRO Update 48 compatibility.

### Removed

- Removed old mockups and leftover `af` files.

## v0.4.1

### Changed

- Finalized the v0.4.x release line and corrected release packaging behavior.

### Fixed

- Fixed alias handling.
- Fixed the release script.

## v0.4.0

### Added

- Added the bestiary data refresh and related assets update.

### Changed

- Expanded the built-in bestiary dataset coverage.

## v0.3.2

### Added

- Added the improved color picker.

### Changed

- Continued configuration cleanup and settings polish.

## v0.3.1

### Added

- Added new status bar features and the new tab bar widget.
- Added custom checkbox support.

### Changed

- Cleaned up configuration flows and updated plugin metadata.
- Optimized the bestiary chat listener.

### Fixed

- Fixed custom label refresh after font changes.

## v0.2.1

### Changed

- Refreshed the README and setup documentation.

### Fixed

- Fixed party target effect handling.

## v0.2.0

### Added

- Added the batch installer in the packaged ZIP.
- Added the bestiary builder.
- Added status bar shortcut buttons.
- Added a configurable minimum threshold for cooldown tracking.

### Changed

- Added version printing and general packaging updates.

### Fixed

- Fixed window bring-to-front behavior.
- Fixed unknown debuff state visibility when mixed curable filters are shown.

### Removed

- Removed debounce saves.

## v0.1.7

### Added

- Initial private LUI release with custom combat UI, configuration, and status bar foundations.
