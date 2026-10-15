-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Shared scaffolding helpers for the Encyclopedia browser panels (item
-- and quest tabs): sizing and parsing math that must behave identically
-- in every tab lives here; panel-specific layout stays in each file.

local Utils = _G.LUI.Utils
local FONT_TO_LOTRO = Utils.FONT_TO_LOTRO
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.text_width"
local Style = _G.LUI.UI.Widgets.Style
local State = _G.LUI.Settings.State
local Encyclopedia = _G.LUI.Features.Encyclopedia

local BrowserShared = {}
Encyclopedia.BrowserShared = BrowserShared

-- filter dropdowns size to their longest option: measured width in the
-- dropdown font (CONTROL_FONT_NAME, CONTROL_FONT_SIZE - 2, see the browsers'
-- apply_fonts) at scale 1 + arrow/padding, clamped; callers scale the result.
-- The max clamp is per-tab (quest categories run longer than item types).
local BASE_DROPDOWN_PAD = 26
local BASE_DROPDOWN_MIN_W = 70

function BrowserShared.dropdown_base_w(labels, base_max_w)
    local longest = 0
    for i = 1, #labels do
        local n = Utils.measure_text_width(labels[i] or "", Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
        if n > longest then
            longest = n
        end
    end
    local w = longest + 2 + BASE_DROPDOWN_PAD
    return math.min(base_max_w, math.max(BASE_DROPDOWN_MIN_W, w))
end

function BrowserShared.scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

-- level/iLvl range boxes accept positive integers; anything else means
-- "no bound"
function BrowserShared.parse_level(text)
    local value = tonumber(text)
    if value == nil then
        return nil
    end
    value = math.floor(value)
    if value <= 0 then
        return nil
    end
    return value
end
