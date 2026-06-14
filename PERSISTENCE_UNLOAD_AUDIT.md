# Persistence / Unload Audit

## Findings

### Asset cache unload flush is still structurally dirty

- `src/Assets/assets_store.lua`: `AssetsStore:destroy()` currently snapshots asset sources and marks `_G.assets_cache_dirty`.
- This works, but teardown is doing persistence preparation.
- Cleaner shape: add an explicit `AssetsStore:flush_for_save()` and call it before unload teardown, then keep `destroy()` limited to callbacks, updates, and visibility.

### Crafting and Travel geometry can be skipped on unload

- `src/main.lua`: unload sets `_G.LUI_IS_UNLOADING = true`, then clears `CRAFTING_WINDOW` and `TRAVEL_WINDOW`, then calls `save_settings()`.
- `src/Settings/persistence.lua`: `capture_runtime_geometry()` skips crafting/travel geometry while `_G.LUI_IS_UNLOADING == true`.
- Result: crafting/travel window geometry can be missed during unload.
- Cleaner shape: capture runtime geometry before setting `_G.LUI_IS_UNLOADING = true` and before clearing those windows.

### Disabling Assets destroys the store but does not save the cache immediately

- `src/main.lua`: `apply_assets_settings()` calls `ASSETS_STORE:destroy()` when Assets are disabled.
- If destroy marks `_G.assets_cache_dirty`, the cache waits until a later save/unload.
- Decide whether disabling Assets should immediately call `save_assets_cache()` after flushing the store.

### First-run quick setup blocks saves while open

- `src/Settings/persistence.lua`: `save_settings()` returns early while `FIRST_RUN_QUICK_SETUP_WINDOW` exists and is not closing.
- This may be intentional to avoid saving partial setup.
- Decide explicitly what should happen if the plugin unloads while first-run setup is open.

## Checked

### Bestiary cache

- `src/main.lua`: unload calls `BESTIARY_TRACKER:save()` before `BESTIARY_TRACKER:destroy()`.
- `Bestiary.Collector:save()` flushes pending kills and calls `save_bestiary_cache()`.
- This path looks structurally okay.
