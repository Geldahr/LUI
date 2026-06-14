# Changelog

## Unreleased

### Added

- Added Help coverage for LUI features, hidden interactions, search syntax, status bar tokens, and command aliases.

### Changed

- Changed default raid vitals HUD X position to `0px`.

### Fixed

- Fixed hard PluginData parse failures by replacing corrupted save files with clean encoded files.
- Fixed typed PluginData decoding so malformed table values are dropped at load instead of reaching the save encoder.
- Fixed Bestiary cache merging so level morale/power observations keep their table shape.
- Fixed first-run quick setup text wrapping and spacing so longer localized text is not clipped.

### Removed

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
