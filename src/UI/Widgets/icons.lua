-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- White, tintable UI icons built by tools/icons/build_icons.py from
-- tools/icons/icons.txt. Tint them with the ICON_* style colors.

import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local Style = Widgets.Style

local Icons = {}
Widgets.Icons = Icons

local DIR = "LUI/assets/ui/icons/"

-- Lucide icons exist in both line weights (Style.ICON_WEIGHT).
local WEIGHTED = {
    chevron_down = true,
    chevron_up = true,
    chevron_left = true,
    chevron_right = true,
    dropdown_arrow = true,
    submenu_arrow = true,
    plus = true,
    minus = true,
    check = true,
    search = true,
    resize_corner = true,
    star = true,
    star_filled = true,
    locate = true,
    map_pin = true,
    level = true,
    family = true,
}

-- LUI's own icons have a single shape.
local FIXED = {
    window_close = true,
    window_maximize = true,
    window_restore = true,
}

local WEIGHTS = {
    thin = true,
    bold = true,
}

Icons.WEIGHTS = { "thin", "bold" }

function Icons.path_for_weight(name, weight)
    if WEIGHTED[name] ~= true then
        error("Unknown weighted icon: " .. tostring(name))
    end
    if WEIGHTS[weight] ~= true then
        error("Unknown icon weight: " .. tostring(weight))
    end
    return DIR .. name .. "_" .. weight .. "_64.tga"
end

function Icons.path(name)
    if FIXED[name] == true then
        return DIR .. name .. "_64.tga"
    end
    return Icons.path_for_weight(name, Style.ICON_WEIGHT)
end
