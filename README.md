# LUI

LUI is a custom user interface plugin for The Lord of the Rings Online. It focuses on cleaner combat frames, sharper text and borders, and precise control over layout, colors, fonts, thresholds, and scaling.

## Features

- Self, target, boss, fellowship, and raid vitals
- Target's target vitals
- Buff and debuff tracking on combat frames
- Expiring effect countdown bars for self and target
- Cooldown tracker with thresholds, whitelist and blacklist support
- Inventory window with optional default backpack replacement
- Assets window for server-wide item holdings across characters
- Status bar widgets for local time, inventory space, money, and more planned
- Bestiary browser, bestiary cards, and optional bestiary capture on English clients
- First-run quick setup to get you up and running quickly
- Profile management so multiple characters can reuse or switch configurations
- Localized UI strings for English, German, and French
- Fine-grained control over colors, sizes, fonts, text formats, thresholds, number abbreviations, refresh rate, and window positions. Explore `/lui config`.
- Precise move mode tools, including a grid, numeric positioning, and keyboard nudging

## What LUI Replaces

- Default player vitals
- Default target vitals
- Default fellowship and raid vitals
- Default backpack windows when inventory replacement is enabled

## Installation

### Method 1: from the ZIP file

1. Download the latest release from the [GitHub releases page](https://github.com/Geldahr/LUI/releases).
2. Extract it into `C:\Users\<your user>\Documents\The Lord of the Rings Online\Plugins`.
3. Keep the archive's folder structure intact. Do not flatten or rename the shipped folders.
4. In-game, load the plugin from the Plugin Manager.

### Method 2: from the batch installer

1. Download the latest batch installer release from the [GitHub releases page](https://github.com/Geldahr/LUI/releases).
2. Execute it to replace any existing `LUI` folder and install the files automatically to `C:\Users\<your user>\Documents\The Lord of the Rings Online\Plugins`.
3. In-game, load the plugin from the Plugin Manager.

### Method 3: from Git

If you install from source instead of a release ZIP or batch installer:

```bash
# WSL
mkdir "/mnt/c/Users/<your user>/Documents/The Lord of the Rings Online/Plugins"
cd "/mnt/c/Users/<your user>/Documents/The Lord of the Rings Online/Plugins"
git clone https://github.com/Geldahr/LUI.git
```

## Commands

- `/lui help` - Show the available commands
- `/lui config` - Toggle the configuration window
- `/lui move` - Toggle move mode
- `/lui move cancel` - Leave move mode without saving the current positions
- `/lui inventory` or `/lui inv` - Toggle the inventory window
- `/lui assets` or `/lui a` - Toggle the assets window
- `/lui bestiary`, `/lui beast`, or `/lui b` - Toggle the bestiary window
- `/lui card [monster name]` - Open the bestiary card for a monster

## Configuration Notes

- On first launch, LUI opens a quick setup flow for UI scale and a default top or bottom layout.
- The global LUI scale is separate from the built-in LotRO UI scale.
- Profile management is available from the configuration window and lets multiple characters share or switch settings.
- Bestiary capture is only available on English clients.

## Scaling Notes

LUI uses pixel-based scaling instead of LotRO UI scaling. That keeps borders and fonts sharper, but fractional values still snap to the nearest renderable size.

- `1 px` at `1.35` scale is still `1 px`
- Font sizes snap to the nearest available LotRO font size
- Border widths are rounded to the nearest rendered pixel

## Limitations

- Automatic item locking based on a whitelist or blacklist is not currently possible through the LotRO API.
- Bestiary capture is restricted to English clients.
- Bestiary and monster card data are only available in English.
- Translations are not up to date.

## Known Issues

- Targeting a player in your fellowship may not show effects immediately. The callback is not triggered and the event list stays empty until a buff or debuff changes.
- Target effect tracking can behave incorrectly when the target is the local player. This has not been seen since February 26, 2026.
- If you use labels that include level, they may not refresh when the target or a party member levels up unless morale or power also changes.

## Repository Notes

- `src/` contains the plugin source, assets, and localized strings.
- `tools/build_bestiary_seed.py` regenerates the seeded bestiary data file at `src/Bestiary/data.lua`.

## Support

Performance issues are considered critical, and I will address them as quickly as possible.

For bug reports, feature requests, or latest release downloads, use the [GitHub repository](https://github.com/Geldahr/LUI).
