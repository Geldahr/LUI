-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Pre-scaled icons: one picture rendered at fixed pixel sizes
-- (<base><size>.tga, built by tools/icons/build_icons.py `sized`). The
-- Image widget draws them unstretched, so they clip inside scrolling lists
-- (stretched controls ignore their parent's clipping). Caveat: a tinted
-- unstretched icon shows its tint as a faint square on light backgrounds;
-- use them only in scrolling areas (Widgets.Icons.sized, see icons.lua).
--
-- icon[n] is the entry for an n px box (n = 0..64): { img = path, size = px },
-- the largest pre-scaled size <= n (44 -> 40), at least the smallest one.
-- icon.sized = true marks it (Turbine.UI.Graphic icons are tables too).

local UI = _G.LUI.UI

-- keep in sync with SIZED (+ 64) in tools/icons/build_icons.py
local SIZES = { 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48, 64 }
UI.SIZED_ICON_MAX = SIZES[#SIZES]

function UI.sized_icon(base)
    local entries = {}
    for i = 1, #SIZES do
        entries[i] = { img = base .. SIZES[i] .. ".tga", size = SIZES[i] }
    end
    local icon = { sized = true }
    local s = 1
    for n = 0, UI.SIZED_ICON_MAX do
        if SIZES[s + 1] ~= nil and SIZES[s + 1] <= n then
            s = s + 1
        end
        icon[n] = entries[s]
    end
    return icon
end
