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
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Vitals.vitals_base"

local function _self_vitals_enabled()
    return State.loaded_settings.self.vitals.enabled == true
end

---@class SelfVitals : VitalsBase
local SelfVitals = class(Vitals.VitalsBase)
Vitals.SelfVitals = SelfVitals

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfVitals:Constructor(entity)
    self.target_vitals = nil
    self.boss_vitals = nil
    Vitals.VitalsBase.Constructor(self, "self", entity, TR["Self Vitals"])
    self:apply_enabled_state()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfVitals:set_target_vitals(target_vitals, boss_vitals)
    self.target_vitals = target_vitals
    self.boss_vitals = boss_vitals
    -- Sync initial target state (plugin can load while a target is already selected).
    self:on_target_changed()
end

function SelfVitals:apply_enabled_state()
    self:SetVisible(_self_vitals_enabled())
end

function SelfVitals:on_target_changed()
    if self.target_vitals == nil and self.boss_vitals == nil then
        return
    end

    local target_vitals_enabled = State.loaded_settings.target.vitals.enabled == true
    local boss_vitals_enabled = target_vitals_enabled == true and State.loaded_settings.target.boss_vitals.enabled == true

    if self.entity == nil or self.entity.GetTarget == nil then
        if self.target_vitals ~= nil then
            self.target_vitals:set_entity(nil)
            self.target_vitals:SetVisible(target_vitals_enabled == true and self.target_vitals:is_move_mode())
        end
        if self.boss_vitals ~= nil then
            self.boss_vitals:set_entity(nil)
            self.boss_vitals:SetVisible(boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
        return
    end

    local t = self.entity:GetTarget()
    local is_boss = boss_vitals_enabled == true and
        t ~= nil and
        is_boss_target ~= nil and
        is_boss_target(t, self.entity) == true

    if self.target_vitals ~= nil then
        self.target_vitals:set_entity(t)
        if target_vitals_enabled ~= true then
            self.target_vitals:SetVisible(false)
        elseif t ~= nil and is_boss ~= true then
            self.target_vitals:SetVisible(true)
        else
            self.target_vitals:SetVisible(self.target_vitals:is_move_mode())
        end
    end

    if self.boss_vitals ~= nil then
        self.boss_vitals:set_entity(is_boss == true and t or nil)
        if is_boss == true then
            self.boss_vitals:SetVisible(true)
        else
            self.boss_vitals:SetVisible(boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function SelfVitals:_setup_effect_tracking()
    self:_setup_effect_tracking_default()
end
