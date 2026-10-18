-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- White, tintable UI icons built by tools/icons/build_icons.py from
-- tools/icons/icons.txt and listed in UI.AssetIds.icons (assets.lua). Tint
-- them with the ICON_* style colors.

import "LUI.src.UI.Widgets.style"
import "LUI.src.UI.assets"

local UI = _G.LUI.UI
local Widgets = UI.Widgets
local Style = Widgets.Style

local Icons = {}
Widgets.Icons = Icons

Icons.WEIGHTS = { "thin", "bold" }

-- icon of every clear button (search bars, TokenInput); "x" switches them
-- all to the Lucide X
Icons.CLEAR = "window_close"

-- the icon of a name of UI.AssetIds.icons in the current line weight (Lucide
-- icons): a path, or a pre-scaled icon (UI.sized_icon) for the sized ones
local function _entry(name)
    local icon = UI.AssetIds.icons[name]
    if icon == nil then
        error("Unknown icon: " .. tostring(name))
    end
    -- entries are paths or tables only: a field test beats type()
    if icon.thin ~= nil then
        local weighted = icon[Style.ICON_WEIGHT]
        if weighted == nil then
            error("Unknown icon weight: " .. tostring(Style.ICON_WEIGHT))
        end
        return weighted
    end
    return icon
end

-- Two ways to draw an icon, because of two LotRO client limits:
--   * Icons.path: the 64 px file, stretched to its size. Tinted cleanly
--     (only the icon's pixels take the color), but a stretched picture
--     ignores its parent's clipping: inside a scrolling list it draws
--     outside the list.
--   * Icons.sized: the pre-scaled files (UI.sized_icon), drawn unstretched,
--     so they clip inside scrolling lists. Caveat: the client applies an
--     unstretched control's tint over its whole square, so a tinted one
--     shows a faint square on a light opaque background.
-- Rule: an icon goes sized when its control can sit in a scrolling area.
-- Icons built into widgets (checkbox, dropdown, spin box, pager, tab bar,
-- menu) are sized; the window title bar and the search bars never scroll
-- and stay stretched. A standalone button's icon (toolbar, shortcut,
-- favorite star) is stretched unless the button sits in a scrolling area.
-- No blend mode, window or layer gives both (measured in game 2026-10-18).

-- the stretched 64 px file of an icon (every icon, pre-scaled ones included)
function Icons.path(name)
    local icon = _entry(name)
    if icon.sized == true then
        return icon[UI.SIZED_ICON_MAX].img
    end
    return icon
end

-- the pre-scaled icon, for places inside a scrolling list (see above: it
-- clips, but a tint shows as a faint square on light backgrounds)
function Icons.sized(name)
    local icon = _entry(name)
    if icon.sized ~= true then
        error("Icon has no pre-scaled sizes: " .. tostring(name))
    end
    return icon
end

-- a money coin ("gold", "silver" or "copper"): the image and its tint, nil
-- for the game's coin art (the default; ICON_COINS_MODERN tints Lucide's)
local COIN_TINTS = {
    gold = "ICON_COIN_GOLD",
    silver = "ICON_COIN_SILVER",
    copper = "ICON_COIN_COPPER",
}
local LEGACY_COINS = {
    gold = UI.AssetIds.gold_coin,
    silver = UI.AssetIds.silver_coin,
    copper = UI.AssetIds.copper_coin,
}

function Icons.coin(metal)
    if Style.ICON_COINS_MODERN == true then
        return Icons.path("coins"), Style[COIN_TINTS[metal]]
    end
    return LEGACY_COINS[metal], nil
end

-- a new Image widget showing a money coin
function Icons.coin_image(metal)
    local icon, tint = Icons.coin(metal)
    local image = Widgets.Image(icon)
    if tint ~= nil then
        image:set_tint(tint)
    end
    return image
end
