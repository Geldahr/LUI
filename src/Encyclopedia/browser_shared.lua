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
local scaled_int = _G.LUI.UI.NativeScaling.scaled_int
local Encyclopedia = _G.LUI.Features.Encyclopedia

local BrowserShared = {}
Encyclopedia.BrowserShared = BrowserShared

-- filter dropdowns size to their longest option: measured width in the
-- dropdown font at the current scale (CONTROL_FONT_NAME, CONTROL_FONT_SIZE
-- - 2, the request the browsers' apply_fonts make) + arrow/padding, clamped.
-- The game snaps fonts to fixed sizes, so the text grows in steps, not
-- linearly: "too long" is decided at scale 1 (longest label + padding over
-- the per-tab max; quest categories run longer than item types): a label
-- that fits there fits at every scale (snapped sizes grow each label by a
-- different ratio), and a longer one keeps the share of its text the max
-- shows at scale 1. Scale-dependent: the browsers recompute it in
-- apply_fonts.
local BASE_DROPDOWN_PAD = 28
local BASE_DROPDOWN_MIN_W = 70

function BrowserShared.dropdown_w(labels, base_max_w)
    local base_size = Style.CONTROL_FONT_SIZE - 2
    local size = base_size * State.settings.global.scale
    local base_room = base_max_w - BASE_DROPDOWN_PAD
    local longest = 0
    local longest_base = 0
    local longest_fitting = 0
    for i = 1, #labels do
        local n = Utils.measure_text_width(labels[i], Style.CONTROL_FONT_NAME, size)
        local base_n = Utils.measure_text_width(labels[i], Style.CONTROL_FONT_NAME, base_size)
        if n > longest then
            longest = n
        end
        if base_n > longest_base then
            longest_base = base_n
        end
        if base_n <= base_room and n > longest_fitting then
            longest_fitting = n
        end
    end
    if longest_base > base_room then
        longest = math.max(longest_fitting, math.floor(longest * base_room / longest_base))
    end
    return math.max(scaled_int(BASE_DROPDOWN_MIN_W), longest + scaled_int(BASE_DROPDOWN_PAD))
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
