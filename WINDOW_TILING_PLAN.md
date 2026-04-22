# LuiWindow Edge Tiling Plan

## Goal

Add simple edge tiling to `LuiWindow`:

- `maximized`: fills the available work area.
- `half_left`: fills the left half of the available work area.
- `half_right`: fills the right half of the available work area.

This should behave like lightweight edge snap, not a full tiling window manager.

Terminology note: `maximized` means "fill the work area". If the status bar is disabled, the work area is the full display, so `maximized` fills the screen. A future `full_screen` tile, if added, should mean true full display bounds even when the status bar is enabled.

## Scope

Implement for `LuiWindow` only. Windows that inherit `LuiWindow` get the behavior by default unless disabled.

Out of scope for the first pass:

- Quarter tiling.
- Drag preview overlays.
- Keyboard shortcuts.
- Multi-window layout orchestration.
- Saving or restoring groups of tiled windows.

## Terms

- `normal`: user-sized, user-positioned window.
- `maximized`: fills the current work area. It respects the status bar when the status bar is enabled.
- `full_screen`: reserved future meaning for true display bounds, ignoring status bar reservations.
- `tile`: edge-tiled state: `none`, `maximized`, `half_left`, `half_right`.
- `work area`: screen bounds excluding the status bar area, matching current maximize behavior.
- `tiled bounds`: the exact position and size computed for the active tile mode.
- `normal geometry`: the saved non-tiled bounds used when restoring.

## Proposed API

```lua
LuiWindow.TILE_NONE = "none"
LuiWindow.TILE_MAXIMIZED = "maximized"
LuiWindow.TILE_HALF_LEFT = "half_left"
LuiWindow.TILE_HALF_RIGHT = "half_right"

function LuiWindow:enable_tiling(enabled)
function LuiWindow:set_tile(tile)
function LuiWindow:get_tile()
function LuiWindow:clear_tile()
function LuiWindow:toggle_tile(tile)
function LuiWindow:get_geometry()
function LuiWindow:set_geometry(geometry)
```

Compatibility helpers can remain:

```lua
function LuiWindow:maximize()
function LuiWindow:restore()
function LuiWindow:is_maximized()
```

Internally, `maximize()` should call `set_tile(TILE_MAXIMIZED)`. `is_maximized()` should return true when `tile == TILE_MAXIMIZED`.

## Recommended State Model

Use one tile state:

```lua
self._tile_mode = LuiWindow.TILE_NONE
```

Persist:

```lua
state.tile = "none" | "maximized" | "half_left" | "half_right"
state.left = normal_left
state.top = normal_top
state.width = normal_width
state.height = normal_height
```

The saved `left/top/width/height` should always be the normal restore geometry, not the tiled bounds.

## Window State Helper

Add a shared helper so each window does not reimplement geometry capture/apply differently:

```lua
function LuiWindow:get_geometry()
    return {
        left = normal_left,
        top = normal_top,
        width = normal_width,
        height = normal_height,
        tile = self._tile_mode or LuiWindow.TILE_NONE,
    }
end

function LuiWindow:set_geometry(geometry)
    -- Reads left/top/width/height/tile and applies restore geometry plus tile state.
end
```

Rules:

- `get_geometry()` returns normal restore geometry when tiled, not current tiled bounds.
- `get_geometry()` returns current bounds when `tile = none`.
- `set_geometry()` applies normal bounds first, then applies tile bounds.
- `tile` is the only persisted tiled/window-state flag.
- Feature windows should use `window:get_geometry()` / `window:set_geometry(state)` instead of hand-writing left/top/width/height/tile logic where practical.

## Geometry

All tiling uses the same work area as maximize.

```lua
local x, y, width, height = self:_work_area()
```

Tile bounds:

- `maximized`: `x, y, width, height`
- `half_left`: `x, y, floor(width / 2), height`
- `half_right`: `x + floor(width / 2), y, width - floor(width / 2), height`

Tile bounds are authoritative. Every tile mode should behave like maximized sizing for its zone:

- The window is set to the exact tiled width and height.
- Adaptive windows must lay out inside the tiled bounds.
- Adaptive windows must not shrink their outer height back to content while tiled.
- Content can center, add/remove columns, scroll, or leave blank space inside the tiled bounds.
- Restoring clears tile state and returns to normal geometry.

Apply minimum size after computing tile bounds:

- If minimum width exceeds half width, clamp to minimum but keep the window on screen.
- If minimum height exceeds work area height, clamp to minimum only as current maximize does.

## Drag Behavior

### Applying Tile

On title-bar drag release:

- If title bar is near work-area top edge: `tile = maximized`.
- If pointer is near work-area left edge: `tile = half_left`.
- If pointer is near work-area right edge: `tile = half_right`.
- Otherwise keep normal geometry.

Suggested snap threshold:

```lua
EDGE_SNAP_THRESHOLD = scaled 10px
```

Use pointer screen position, not only window position, so snapping feels natural when the user drags quickly.

### Dragging Away From Tiled State

If a tiled window is dragged by the title bar:

- Track distance from drag start.
- If movement exceeds the existing maximize restore threshold, clear tile and restore normal geometry.
- Continue the drag from the restored normal window.

Suggested threshold:

```lua
UNTILE_DRAG_THRESHOLD = scaled 80px
```

This should reuse the current maximized drag-away behavior.

## Restore Behavior

The restore button should clear tile state:

- `maximized` restores to normal geometry.
- `half_left` restores to normal geometry.
- `half_right` restores to normal geometry.

Button icon:

- Show restore icon for any tiled state.
- Show maximize icon when `tile = none`.

Clicking maximize button:

- If `tile = none`: set `tile = maximized`.
- Else: clear tile and restore normal geometry.

## Resizing While Tiled

First pass:

- Disable resize handles while tiled.
- Clear tile before user resizing if resize begins somehow.

Reason: resizing a half-tiled window creates ambiguous state. Keep the first pass simple.

## Moving And Bounds

Normal windows should continue to clamp to work area/status-bar rules.

Tiled windows should exactly match tile bounds and should update if:

- UI scale changes.
- Display size changes.
- Status bar position/height changes.
- Settings reload changes status bar enabled state.

When those events happen, reapply tile bounds if `tile ~= none`.

Do not let window-specific resize logic override tiled bounds. In tiled state, `LuiWindow` owns the outer rectangle; individual windows only lay out their contents inside it.

## Window-Specific Notes

Inventory:

- Horizontal-only resize mode should not prevent `tile = maximized` or half tiling.
- Inventory content should center and adjust columns as it does now.
- Tiled bounds are authoritative for all tile modes.
- Half tiling should use full work-area height for its half, just like `maximized` uses full work-area height.
- The inventory grid should center vertically/horizontally and may leave blank space inside the tiled window.

Assets:

- Tiled bounds are authoritative.
- Icons/details center inside the content area.
- Details cards stretch until another column fits.
- Blank space inside the tiled window is acceptable; the outer tiled rectangle should not shrink to the asset grid.

Bestiary:

- Tiling should work because it is fluid and already resizable.
- Full reflow should use existing debounce.
- Tiled bounds are authoritative; reflow should adapt content to the tile.

Crafting:

- Tiling should work because it is fluid and already resizable.
- If half-tiling feels heavy, revisit Crafting resize performance separately.
- Tiled bounds are authoritative; layout should fill the tile.

BestiaryCard:

- Tiling disabled. It is a popup/card, not a workspace window.

Config:

- Tiling can be enabled, but consider disabling by default if it feels odd for settings.
- If enabled, tiled bounds are authoritative.

## State Plan

1. Add `tile` support as the single saved window-state flag.
2. On load, normalize missing or invalid `state.tile` to `none`.
3. On save, write `tile` and normal restore geometry only.
4. Remove old `maximized` keys from saved window tables.

## Implementation Steps

1. Add tile constants and `enable_tiling` API to `src/UI/Widgets/window.lua`.
2. Add `get_geometry()` and `set_geometry()` to `src/UI/Widgets/window.lua`.
3. Replace maximize-only bounds logic with tile bounds helper:
   - `_tile_bounds(tile)`
   - `_apply_tile_bounds()`
   - `_capture_current_normal_geometry()`
   - `_restore_normal_bounds()`
4. Update feature windows to save with `get_geometry()`.
5. Update feature windows to restore with `set_geometry()`.
6. Update maximize/restore button icon logic to consider all tiled states.
7. Add title-bar drag-release edge detection.
8. Add drag-away-to-restore behavior for half tiles and maximized.
9. Update feature windows to use the shared geometry helper where practical.
10. Test with Inventory, Assets, Bestiary, Crafting, Config.

## Manual Test Matrix

- Drag window to top edge: enters `maximized`.
- Drag window to left edge: enters `half_left`.
- Drag window to right edge: enters `half_right`.
- Click restore button from each tiled state: returns to previous normal size/position.
- Drag tiled window away: restores and continues moving.
- Save/reload while tiled: returns to same tiled state.
- Disable status bar / enable status bar: tiled bounds respect work area.
- Inventory half-left/right: content centers and columns adjust.
- Inventory half-left/right: outer window uses full work-area height for that half.
- Assets half-left/right: details stretch and icons center.
- Assets half-left/right: outer window does not shrink to content/grid.
- Bestiary half-left/right: layout remains readable.
- Crafting half-left/right: no severe resize lag.
- With status bar enabled, `maximized` fills the work area and does not cover the status bar.
- With status bar disabled, `maximized` fills the full display.
- Saved window state contains `tile`, not `maximized`.
- `get_geometry()` returns normal restore geometry while tiled.

## Open Questions

- Should Config allow edge tiling by default?
- Should snapping happen immediately while dragging near edge, or only on mouse release?
- Do we need a subtle preview rectangle after the first pass?
- Do we ever need a separate `tile = full_screen` that ignores the status bar, or should that remain out of scope?
