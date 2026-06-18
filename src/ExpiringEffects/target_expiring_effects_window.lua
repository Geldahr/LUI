local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local is_boss_target = _G.LUI.Utils.is_boss_target
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_format_timeout_seconds = _G.LUI.Utils.lui_format_timeout_seconds
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_timed_row_resolved_font_size = _G.LUI.Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_timed_row_min_item_width = _G.LUI.Utils.lui_timed_row_min_item_width
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_resolved_font_size = _G.LUI.Utils.lui_cooldown_resolved_font_size
local lui_cooldown_estimate_text_width = _G.LUI.Utils.lui_cooldown_estimate_text_width
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_cooldown_min_name_width = _G.LUI.Utils.lui_cooldown_min_name_width
local lui_cooldown_min_timed_bar_width = _G.LUI.Utils.lui_cooldown_min_timed_bar_width
local lui_cooldown_min_item_width = _G.LUI.Utils.lui_cooldown_min_item_width
local lui_clamp_ratio = _G.LUI.Utils.lui_clamp_ratio
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_lerp_number = _G.LUI.Utils.lui_lerp_number
local lui_lerp_color = _G.LUI.Utils.lui_lerp_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.ExpiringEffects.expiring_effects_window"
import "LUI.src.ExpiringEffects.target_expiring_effect_entry"

local TargetExpiringEffectsWindow = class(ExpiringEffects.ExpiringEffectsWindow)
ExpiringEffects.TargetExpiringEffectsWindow = TargetExpiringEffectsWindow

local function _target_is_local_player()
    if _G.LUI.Runtime.Windows.target_vital == nil or _G.LUI.Runtime.Windows.target_vital.entity == nil then
        return false
    end

    local entity = _G.LUI.Runtime.Windows.target_vital.entity
    local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    if lp == nil or entity.GetName == nil or lp.GetName == nil then
        return false
    end

    return entity:GetName() == lp:GetName()
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:Constructor()
    ExpiringEffects.ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Target)"] })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:get_settings()
    return State.settings.target.expiring_effects
end

function TargetExpiringEffectsWindow:get_hud_key()
    return "target_effects"
end

function TargetExpiringEffectsWindow:get_entry_class()
    return ExpiringEffects.TargetExpiringEffectEntry
end

function TargetExpiringEffectsWindow:get_effect_objects()
    if _G.LUI.Runtime.Windows.target_vital == nil then
        return {}
    end

    local out = {}
    if _target_is_local_player() == true then
        local list = Turbine.Gameplay.LocalPlayer.GetInstance():GetEffects()
        if list == nil or list.GetCount == nil then
            return {}
        end

        local count = list:GetCount() or 0
        for i = 1, count do
            local effect = list:Get(i)
            if effect ~= nil then
                table.insert(out, effect)
            end
        end
    else
        local em = _G.LUI.Runtime.Windows.target_vital.em
        if em == nil then
            return {}
        end

        for _, o in pairs(em.effects) do
            if o ~= nil then
                table.insert(out, o.effect)
            end
        end
    end
    return out
end
