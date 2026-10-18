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

-- the icon to draw for a name of UI.AssetIds.icons: a path, or a pre-scaled
-- icon (UI.sized_icon) that the Image widget draws unstretched; Lucide icons
-- in the current line weight
function Icons.path(name)
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
