# LotRO UI

## Description

LUI (LotRO UI) is a custom user interface for The Lord of the Rings Online (LotRO). It focuses on cleaner vitals, more readable resource information, and precise customization of the main combat-related UI elements.

It removes the character portrait from the resource bars (Vitals) and gives you tighter control over layout, colors, fonts, thresholds, refresh rate, and scaling.

## Features

- Your Vitals
- Target Vitals
- Boss Vitals
- Fellowship / Raid Vitals
- Your Target's Target Vitals
- Expiring effects countdown bars (for both self and target)
- Cooldown refresh bar
- Inventory
- Assets view (server assets accross multiple characters)
- Status bar
- Precise customization and positioning of UI elements
  - A grid is displayed in move mode
  - Each window can be moved via a pixel text input field for pixel-perfect positioning
  - Up/Down/Left/Right arrow keys to move a window pixel by pixel (Alt + arrow key to move by 10 pixels)

Almost everything can be configured:

- all colors
- all sizes
- text fonts
- text sizes
- dynamic morale coloring
- window positions
- various display thresholds
- what effects are displayed
- many features can be toggled on/off
- number abbreviations (`k`, `M`, `B` / `e3`, `e6`, `e9` / `k`, `m`, `M` / `k`, `M`, `G`)
- global frame rate limit for UI updates (for elements requiring frequent updates, e.g. expiring effects countdown bars)
- global scaling

## What LUI Replaces

- Replaces the default player vitals
- Replaces the default target vitals
- Replaces the default fellowship / raid vitals
- Can replace the default backpack windows when inventory replacement is enabled

## Installation

To install LUI, download the latest release from the [GitHub repository](https://github.com/Geldahr/LUI/releases).

### Windows

Copy the downloaded zip file to `C:\Users\[your user folder]\Documents\The Lord of the Rings Online\Plugins`.

Unzip it directly in that folder.

The final result inside the `Plugins` folder should look like this:

- Plugins/
  - Geldahr/
    - LUI/
    - LUI.plugin

## Commands

- `/lui help` - Show the available commands
- `/lui config` - Open the configuration window
- `/lui move` - Toggle move mode
- `/lui inventory` or `/lui inv` - Toggle the inventory window
- `/lui assets` - Toggle the assets window

## Scaling Notes

LUI does not use LotRO UI scaling. Instead, it uses pixel-based scaling for sizes and fonts. This keeps borders and fonts sharp instead of blurry.

This approach has some limitations:

- 1 px with 1.35 scaling is still 1 pixel
- font sizes are limited to a specific set. For example, a font size of 10 with 1.35 scaling will be displayed as 14, because a font size of 13.5 does not exist. In that range, only 12 and 14 are available, and 14 is the closest.

A 5 px border with 1.35 scaling will be displayed as 7 px, while a 4 px border will be displayed as 5 px. So if you want a 6 px border on screen, you can select a border of 4.5 px.

## Limitations

- Automatic item locking based on a whitelist / blacklist is not currently possible through the LotRO API.

## Support

If you need a new feature or want to report a bug, please open an issue on the [GitHub repository](https://github.com/Geldahr/LUI).

## Roadmap

- Additional raid improvements
- Additional status bar options
- Fix config text input clipping in some format string fields
- Settings export / import (for easy sharing)

## Known Issues

- Targeting a player in your fellowship may not show effects immediately. The callback is not triggered and the event list is empty until a buff or debuff changes
- Target effect tracking can behave incorrectly when the target is the local player (not seen since 2026-02-26)
- If you use a label with the level, it might not update when the target or party member levels up if morale or power does not change
