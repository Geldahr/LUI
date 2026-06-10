# Global UI Style Settings Reference

This document describes the proposed `Global > UI` settings and what each one changes.

These settings affect shared LUI chrome: common windows, panels, tabs, buttons, dropdowns, checkboxes, menus, tooltips, form fields, move/edit overlays, and other generic plugin UI that is routed through `UI.Widgets.Style`.

They do not replace feature-specific color settings. Combat/resource colors, cooldown colors, expiring effect colors, drops colors, status bar widget colors, and other semantic feature colors stay in their own feature pages.

Style resolution is `built-in defaults < developer/plugin style < user style`. Empty user style settings reveal the developer style layer, or built-in defaults where no developer override exists.

Style changes are applied after a plugin reload.

## Global > UI > General

| Setting | What it changes |
| --- | --- |
| Reload notice | Explains that saved UI style changes apply after reloading the plugin. |
| Reset shared UI style | Clears exposed shared UI user overrides. Apply/Save persists the cleared user layer, so developer style or built-in defaults are visible after reload. |

## Global > UI > Layout

| Setting | Style token | What it changes |
| --- | --- | --- |
| Border width | `BORDER_WIDTH` | Default border thickness for shared LUI chrome, including standard windows, buttons, tabs, dropdown popups, checkboxes, framed sections, and other common controls that use the normal border size. |
| Thin border width | `BORDER_WIDTH_THIN` | Thin border thickness for subtle chrome, such as tooltips, small separators, fine resize/edge details, and compact framed elements that intentionally use a lighter border. |
| Large border width | `BORDER_WIDTH_LARGE` | Large border thickness for emphasized chrome, when a control or window needs a stronger frame than the normal border. |

## Global > UI > Colors > Frame

| Setting | Style token | What it changes |
| --- | --- | --- |
| Border color | `CONTROL_BORDER` | Default border color for shared windows, controls, dropdown popups, tab outlines, checkboxes, framed settings sections, tooltips, and other generic frames. |
| Hover border color | `CONTROL_BORDER_HOVER` | Border color used when shared interactive controls are hovered, such as buttons, checkbox boxes, tabs, and similar controls. |
| Active border color | `CONTROL_BORDER_ACTIVE` | Border color for active or selected shared controls, such as active buttons, selected tabs, and focused/active framed controls where supported. |
| Disabled border color | `CONTROL_BORDER_DISABLED` | Border color for disabled shared controls. |

## Global > UI > Colors > Backgrounds

| Setting | Style token | What it changes |
| --- | --- | --- |
| Window background | `BACKGROUND` | Main shared background for LUI windows, settings pages, dropdown popups, menus, tab content areas, and generic window interiors. |
| Alternate background | `ALTERNATE_BACKGROUND` | Secondary background used for strips, alternate areas, compact side regions, spin-box button regions, and other subtle contrast surfaces. |
| Panel background | `PANEL_BACKGROUND` | Background for raised or overlay-style panels such as tooltips, color picker panels, modal/dialog panels, and other framed panel surfaces. |
| Panel inner background | `PANEL_INNER_BACKGROUND` | Inner background for nested panels, especially where a panel has an outer frame and a separate content surface. |
| Control background | `CONTROL_BACKGROUND` | Default fill color for buttons, dropdown buttons, title bars, menu entries, and shared controls in their normal state. |

## Global > UI > Colors > Controls

| Setting | Style token | What it changes |
| --- | --- | --- |
| Hover background | `CONTROL_BACKGROUND_HOVER` | Fill color for shared controls on hover, such as buttons, embedded buttons, menu rows, tabs, and clickable rows. |
| Pressed background | `CONTROL_BACKGROUND_PRESSED` | Fill color while a shared control is being pressed. |
| Active background | `CONTROL_BACKGROUND_ACTIVE` | Fill color for active shared controls, such as selected/active buttons or active control states. |
| Disabled background | `CONTROL_BACKGROUND_DISABLED` | Fill color for disabled shared controls. |
| Read-only background | `CONTROL_BACKGROUND_READONLY` | Fill color for read-only shared controls, such as non-editable help/link text boxes. |

## Global > UI > Colors > Selection

| Setting | Style token | What it changes |
| --- | --- | --- |
| Selection background | `SELECTION_BACKGROUND` | Background for selected shared UI states, especially selected tabs and selected button-style options. |
| Selection hover background | `SELECTION_BACKGROUND_HOVER` | Background for selected items when hovered. |
| Selection text | `SELECTION_FOREGROUND` | Text color on selected shared UI states. |
| Alternate selection background | `ALTERNATE_SELECTION_BACKGROUND` | Secondary selected-state background used where the UI needs a lower-emphasis selected state. |
| Alternate selection text | `ALTERNATE_SELECTION_FOREGROUND` | Text color for alternate selected states. |

## Global > UI > Colors > Text

| Setting | Style token | What it changes |
| --- | --- | --- |
| Main text | `FOREGROUND` | Primary shared UI text color, including window titles, tooltip text, common labels, and generic readable text. |
| Secondary text | `ALTERNATE_FOREGROUND` | Secondary/shared supporting text color, such as inactive tab text, metadata-style labels, hints, and lower-emphasis text. |
| Info text | `INFO_FOREGROUND` | Informational text color for first-run notes, help hints, and other non-warning guidance text. |
| Disabled text | `FOREGROUND_DISABLED` | Generic disabled text color where a control does not use a control-specific disabled text token. |
| Placeholder text | `PLACEHOLDER_FOREGROUND` | Placeholder text color in shared text inputs and search/filter fields. |
| Text outline | `TEXT_OUTLINE` | Shared outline color for generic outlined labels, such as travel labels, bestiary labels, item quantity text, and other routed non-feature labels. |

## Global > UI > Colors > Control Text

| Setting | Style token | What it changes |
| --- | --- | --- |
| Control text | `CONTROL_FOREGROUND` | Text color inside shared controls in normal state, such as buttons, dropdowns, checkboxes, menu rows, and tab buttons. |
| Control hover text | `CONTROL_FOREGROUND_HOVER` | Text color inside shared controls on hover. |
| Control pressed text | `CONTROL_FOREGROUND_PRESSED` | Text color inside shared controls while pressed. |
| Control active text | `CONTROL_FOREGROUND_ACTIVE` | Text color inside shared controls in active/selected state. |
| Control disabled text | `CONTROL_FOREGROUND_DISABLED` | Text color inside disabled shared controls. |

## Global > UI > Colors > Accents

| Setting | Style token | What it changes |
| --- | --- | --- |
| Accent background | `ACCENT_BACKGROUND` | Accent fill used by shared UI controls, such as checkbox check indicators and other small emphasized UI marks. |
| Accent text | `ACCENT_FOREGROUND` | Text color used on accent backgrounds when a shared control needs text over an accent fill. |
| Disabled accent | `ACCENT_BACKGROUND_DISABLED` | Accent fill for disabled shared controls. |
| Invalid background | `INVALID_BACKGROUND` | Background for invalid shared UI states, such as invalid color input swatches or validation-style fields. |

## Global > UI > Colors > Overlays

Opacity settings in this section use `0.00` for transparent and `1.00` for fully opaque.

| Setting | Style token | What it changes |
| --- | --- | --- |
| Modal overlay background | `MODAL_OVERLAY_BACKGROUND` | Dimmed full-window overlay behind confirmation dialogs or modal UI. |
| Modal overlay opacity | `MODAL_OVERLAY_BACKGROUND` | Alpha/opacity of the modal overlay background. |
| Modal dialog background | `MODAL_DIALOG_BACKGROUND` | Background of the actual confirmation/modal dialog panel. |
| Modal dialog opacity | `MODAL_DIALOG_BACKGROUND` | Alpha/opacity of the modal dialog background. |
| Preview overlay background | `PREVIEW_OVERLAY_BACKGROUND` | Dimmed overlay used by preview/setup UI where the user is inspecting a temporary layout or sample view. |
| Preview overlay opacity | `PREVIEW_OVERLAY_BACKGROUND` | Alpha/opacity of the preview overlay background. |
| Drag ghost background | `DRAG_GHOST_BACKGROUND` | Background for drag ghost/previews in edit modes. |
| Drag ghost opacity | `DRAG_GHOST_BACKGROUND` | Alpha/opacity of the drag ghost background. |
| Drag ghost border | `DRAG_GHOST_BORDER` | Border/edge color for drag ghost/previews in edit modes. |
| Drag ghost text | `DRAG_GHOST_FOREGROUND` | Text color inside drag ghost/previews. |
| Drag preview fill | `DRAG_PREVIEW_FILL` | Fill color for the translucent rectangle shown while dragging status-bar widgets. |
| Drag preview fill opacity | `DRAG_PREVIEW_FILL` | Alpha/opacity of the drag preview fill. |
| Drag preview edge | `DRAG_PREVIEW_EDGE` | Edge color for the translucent rectangle shown while dragging status-bar widgets. |
| Drag preview edge opacity | `DRAG_PREVIEW_EDGE` | Alpha/opacity of the drag preview edge. |

## Global > UI > Colors > Move Mode

Opacity settings in this section use `0.00` for transparent and `1.00` for fully opaque.

| Setting | Style token | What it changes |
| --- | --- | --- |
| Move overlay background | `MOVE_OVERLAY_BACKGROUND` | Main move-mode overlay background shown over draggable HUD/windows. |
| Move overlay opacity | `MOVE_OVERLAY_BACKGROUND` | Alpha/opacity of the main move-mode overlay background. |
| Move header background | `MOVE_OVERLAY_HEADER_BACKGROUND` | Header strip/background in move-mode overlays. |
| Move header opacity | `MOVE_OVERLAY_HEADER_BACKGROUND` | Alpha/opacity of the move-mode header background. |
| Move text | `MOVE_OVERLAY_FOREGROUND` | Text color used inside move-mode overlays. |
| Move grid background | `MOVE_GRID_BACKGROUND` | Background tint behind the move-mode snap grid. |
| Move grid opacity | `MOVE_GRID_BACKGROUND` | Alpha/opacity of the move-mode snap grid background. |
| Move grid center line | `MOVE_GRID_CENTER_LINE` | Center crosshair line color in move-mode snap grid. |
| Move grid center opacity | `MOVE_GRID_CENTER_LINE` | Alpha/opacity of the center crosshair line. |
| Move grid major line | `MOVE_GRID_MAJOR_LINE` | Major interval grid-line color in move-mode snap grid. |
| Move grid major opacity | `MOVE_GRID_MAJOR_LINE` | Alpha/opacity of major interval grid lines. |
| Move grid minor line | `MOVE_GRID_MINOR_LINE` | Minor interval grid-line color in move-mode snap grid. |
| Move grid minor opacity | `MOVE_GRID_MINOR_LINE` | Alpha/opacity of minor interval grid lines. |

## Global > UI > Text

These settings control shared UI font identity and size. They do not affect feature-specific text systems such as vitals labels, cooldown entries, expiring effects, drops, or status bar widgets.

| Setting | What it changes |
| --- | --- |
| Default control font | Font family for shared controls, such as buttons, tabs, dropdowns, menus, spin-box text fields, settings form labels, settings inputs, and settings action buttons. |
| Default control font size | Font size for shared controls, such as buttons, tabs, dropdowns, menus, spin-box text fields, settings form labels, settings inputs, and settings action buttons. Settings action buttons and some tab levels keep their current relative hierarchy. |
| Window title font | Font family for shared LUI window title bars. |
| Window title font size | Font size for shared LUI window title bars. |
| H1 font | Font family for top-level shared UI headings. |
| H1 font size | Font size for top-level shared UI headings. |
| H2 font | Font family for secondary shared UI headings. |
| H2 font size | Font size for secondary shared UI headings. |
| Large content font | Font family for prominent regular content text that is not a heading. |
| Large content font size | Font size for prominent regular content text that is not a heading. |
| Medium content font | Font family for normal regular content text that is not a heading or control. |
| Medium content font size | Font size for normal regular content text that is not a heading or control. |
| Small content font | Font family for supporting regular content text, hints, tooltip text, metadata, and edit-mode ghost labels. |
| Small content font size | Font size for supporting regular content text, hints, tooltip text, metadata, and edit-mode ghost labels. Edit-mode ghost labels keep their current one-point larger hierarchy. |

## Feature-Specific Settings Outside Global UI

The following are intentionally not controlled by `Global > UI`:

- Vitals morale, power, wrath, bubble, threshold, and selection colors.
- Cooldown frame/bar/text colors.
- Expiring effect frame/bar/text colors.
- Drops HUD/item background colors.
- Status bar background, font, inventory warning, equipment wear, and crafting-plan ready/missing/loading colors.
- Crafting ready/missing/automatic status colors, plan-row readiness tints, and source colors.
- Asset item-quality, summary metric, and source colors such as backpack, bank, vault, and shared storage.
- Bestiary stat, combat-scale, drop/chest, and match colors.
- Preview-only sample colors.
- Color picker hue/value/cursor colors.
