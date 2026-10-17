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
    chevron_up_small = true,
    chevron_down_small = true,
    chevron_left_small = true,
    chevron_right_small = true,
    plus = true,
    minus = true,
    check = true,
    search = true,
    resize_horizontal = true,
    resize_vertical = true,
    resize_tl_br = true,
    resize_tr_bl = true,
    star = true,
    star_filled = true,
    map_pinned = true,
    x = true,
    level = true,
    tag = true,
    gem = true,
    shield = true,
    gauge = true,
    scroll_text = true,
    hammer = true,
    award = true,
    package_check = true,
    boxes = true,
    user = true,
    archive = true,
    settings = true,
    backpack = true,
    anvil = true,
    compass = true,
    briefcase = true,
    book_open_text = true,
    users = true,
    refresh_cw = true,
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

-- icon of every clear button (search bars, TokenInput); "x" switches them
-- all to the Lucide X
Icons.CLEAR = "window_close"

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
