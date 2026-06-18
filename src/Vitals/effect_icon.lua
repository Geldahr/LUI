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
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.time_format"

local EffectIcon = class(UI.Widgets.LuiBaseWindow)
Vitals.EffectIcon = EffectIcon

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function EffectIcon:Constructor(effect, size, font, font_style, font_color, outline_color)
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = false })

    self.effect = nil
    self.ending = 0

    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self:SetSize(size, size)

    self.icon = Turbine.UI.Lotro.EffectDisplay()
    self.icon:SetParent(self)
    self.icon:SetSize(size, size)
    self.icon:SetZOrder(1)

    self.label_back = Turbine.UI.Window()
    self:apply_native_scaling(self.label_back)
    self.label_back:SetParent(self)
    self.label_back:SetSize(size, size)
    self.label_back:SetVisible(true)
    self.label_back:SetMouseVisible(false)
    self.label_back:SetZOrder(5)

    self.timer = UI.Widgets.LuiLabel()
    self.timer:SetParent(self.label_back)
    self.timer:SetSize(size, size)
    self.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    self.timer:SetFont(font)
    if font_style ~= nil then
        self.timer:SetFontStyle(font_style)
    else
        self.timer:SetFontStyle(Turbine.UI.FontStyle.Outline)
    end
    if outline_color ~= nil then
        self.timer:SetOutlineColor(outline_color)
    end
    if font_color ~= nil then
        self.timer:SetForeColor(font_color)
    end
    self.timer:SetMouseVisible(false)
    self.timer:SetZOrder(5)

    self:SetVisible(true)

    self:set_effect(effect)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function EffectIcon:destroy()
    self.icon:SetEffect(nil)
    self.effect = nil
    self.ending = 0
    self:SetWantsUpdates(false)
    self.timer:SetText("")
    self.label_back:SetVisible(false)
    self:SetVisible(false)
end

function EffectIcon:get_effect_id()
    if self.effect == nil then
        return 0
    end
    return self.effect:GetID()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function EffectIcon:set_effect(effect)
    self.effect = effect
    self.last_update_at = -(self.update_every or 0)

    if effect == nil then
        self.icon:SetEffect(nil)
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        self.ending = 0
        return
    end

    self.icon:SetEffect(effect)
    self.label_back:SetVisible(true)
    self:SetVisible(true)

    local duration = (effect.GetDuration ~= nil and effect:GetDuration()) or 0
    if duration > 0 and duration < 9999 and effect.GetStartTime ~= nil then
        self.ending = effect:GetStartTime() + duration
    else
        self.ending = 0
    end

    self:SetWantsUpdates(true)
    self:Update()
end

function EffectIcon:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if self.effect == nil then
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        return
    end

    local duration = (self.effect.GetDuration ~= nil and self.effect:GetDuration()) or 0
    if duration <= 0 or duration >= 9999 or self.effect.GetStartTime == nil then
        self.ending = 0
        self.timer:SetText("")
        self:SetWantsUpdates(false)
        return
    end

    local start = self.effect:GetStartTime()
    self.ending = start + duration
    local time_left = self.ending - Turbine.Engine.GetGameTime()
    if time_left < 0 then
        self.timer:SetText("")
    elseif time_left < 9 then
        self.timer:SetText(lui_format_timeout(time_left))
    else
        self.timer:SetText("")
    end
end
