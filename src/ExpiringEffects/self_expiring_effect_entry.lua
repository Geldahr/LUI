-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_timed_row_time_format = _G.LUI.Utils.lui_timed_row_time_format
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"
import "LUI.src.Settings.enums"
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.Utils.color"

local SelfExpiringEffectEntry = class(Turbine.UI.Control)
ExpiringEffects.SelfExpiringEffectEntry = SelfExpiringEffectEntry

local LABEL_PAD = 3
local EFFECT_TIME_FORMAT = lui_timed_row_time_format.AUTO

local function _stable_effect_key(effect)
    if effect == nil then
        return 0
    end

    local id = effect:GetID()
    if type(id) ~= "number" then
        id = tonumber(id) or 0
    end
    return id
end

local function _truncate_name(name, max_chars)
    if type(name) ~= "string" then
        name = tostring(name or "")
    end

    local m = max_chars
    if m <= 0 then
        return name
    end

    m = math.floor(m + 0.5)
    if m < 1 then
        return ""
    end

    if string.len(name) <= m then
        return name
    end

    if m >= 4 then
        return string.sub(name, 1, m - 3) .. "..."
    end

    return string.sub(name, 1, m)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfExpiringEffectEntry:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.effect = nil
    self.effect_key = 0
    self.bar_inner_w = 0
    self.bar_anchor_right = false

    self:SetMouseVisible(false)

    self.bar_border = Turbine.UI.Control()
    self.bar_border:SetParent(self)
    self.bar_border:SetMouseVisible(false)

    self.bar_background = Turbine.UI.Control()
    self.bar_background:SetParent(self.bar_border)
    self.bar_background:SetMouseVisible(false)

    self.bar_fill = Turbine.UI.Control()
    self.bar_fill:SetParent(self.bar_background)
    self.bar_fill:SetMouseVisible(false)

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self.bar_background)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetSelectable(false)
    self.name_label:SetMultiline(true)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.name_label:SetText("")

    self.time_label = UI.Widgets.LuiLabel()
    self.time_label:SetParent(self.bar_background)
    self.time_label:SetMouseVisible(false)
    self.time_label:SetSelectable(false)
    self.time_label:SetMultiline(false)
    self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.time_label:SetText("")

    self.icon_border = Turbine.UI.Control()
    self.icon_border:SetParent(self)
    self.icon_border:SetMouseVisible(false)

    self.icon_background = Turbine.UI.Control()
    self.icon_background:SetParent(self.icon_border)
    self.icon_background:SetMouseVisible(false)

    self.icon = Turbine.UI.Lotro.EffectDisplay()
    self.icon:SetParent(self.icon_background)
    self.icon:SetMouseVisible(false)
    self.icon:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfExpiringEffectEntry:apply_settings()
    local s = State.settings.self.expiring_effects
    local border = s.border_width
    local border_color = s.color.border
    local back = lui_apply_opacity_to_color(s.color.background, s.background_opacity)

    local height = s.bar_height
    local bar_width = s.bar_width
    local min_bar_width = lui_timed_row_min_timed_bar_width(
        border,
        LABEL_PAD,
        s.font.name,
        s.font.size,
        s.threshold,
        EFFECT_TIME_FORMAT
    )
    if bar_width < min_bar_width then
        bar_width = min_bar_width
    end
    local icon_size = height

    self:SetSize(bar_width + icon_size, height)

    local icon_left = LUI_ENUMS.side_is_left[s.icon_side] == true
    self.bar_border:SetPosition(icon_left and icon_size or 0, 0)
    self.bar_border:SetSize(bar_width, height)
    self.bar_border:SetBackColor(border_color)

    self.icon_border:SetPosition(icon_left and 0 or bar_width, 0)
    self.icon_border:SetSize(icon_size, icon_size)
    self.icon_border:SetBackColor(border_color)

    if border < 0 then border = 0 end
    local max_border = math.floor(math.min(bar_width, height) / 2)
    if border > max_border then border = max_border end
    local inner_height = height - (2 * border)
    if inner_height < 1 then inner_height = 1 end

    -- Avoid a double border between bar and icon:
    -- keep the separator from the icon border, and extend the bar background to cover its adjacent border.
    local bar_inner_w = bar_width - border
    if bar_inner_w < 1 then bar_inner_w = 1 end
    self.bar_inner_w = bar_inner_w

    local bar_bg_x = icon_left and 0 or border
    self.bar_background:SetPosition(bar_bg_x, border)
    self.bar_background:SetSize(bar_inner_w, inner_height)

    self.bar_fill:SetPosition(0, 0)
    self.bar_fill:SetSize(bar_inner_w, inner_height)
    self:_apply_bar_colors()

    local time_width = lui_timed_row_time_label_width(
        s.font.name,
        s.font.size,
        s.threshold,
        EFFECT_TIME_FORMAT
    )
    local text_gap = lui_timed_row_text_gap(s.font.size)
    local title_width = bar_inner_w - (2 * LABEL_PAD) - time_width - text_gap
    if title_width < 1 then title_width = 1 end
    local time_x = LABEL_PAD + title_width + text_gap

    self.name_label:SetPosition(LABEL_PAD, 0)
    self.name_label:SetSize(title_width, inner_height)
    self.name_label:SetFont(s.font.lotro)
    self.name_label:SetFontStyle(LUI_TO_LOTRO.font_style[s.font.style] or Turbine.UI.FontStyle.None)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.name_label:SetOutlineColor(s.font.outline_color)
    self.name_label:SetForeColor(s.font.color)

    self.time_label:SetPosition(time_x, 0)
    self.time_label:SetSize(time_width, inner_height)
    self.time_label:SetFont(s.font.lotro)
    self.time_label:SetFontStyle(LUI_TO_LOTRO.font_style[s.font.style] or Turbine.UI.FontStyle.None)
    self.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.time_label:SetOutlineColor(s.font.outline_color)
    self.time_label:SetForeColor(s.font.color)

    local icon_inner = icon_size
    if icon_inner < 1 then icon_inner = 1 end
    self.icon_background:SetPosition(0, 0)
    self.icon_background:SetSize(icon_inner, icon_inner)
    self.icon_background:SetBackColor(back)

    self.icon:SetPosition(0, 0)
    self.icon:SetSize(icon_inner, icon_inner)

    local towards_right = s.bar_expire_towards == LUI_ENUMS.side.RIGHT
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        self.bar_anchor_right = towards_right ~= true
    else
        self.bar_anchor_right = towards_right
    end
end

function SelfExpiringEffectEntry:set_effect(effect)
    if effect == nil then
        if self.effect == nil and (self.effect_key == nil or self.effect_key == 0) then
            return
        end
        self.effect = nil
        self.effect_key = 0
        self:_apply_bar_colors()
        self.icon:SetEffect(nil)
        self.icon:SetVisible(false)
        return
    end

    local next_key = _stable_effect_key(effect)
    if next_key ~= 0 and next_key == self.effect_key then
        -- Same underlying effect (possibly new wrapper) -> avoid EffectDisplay rebinding.
        self.effect = effect
        self:_apply_bar_colors()
        self.icon:SetVisible(true)
        return
    end

    self.effect = effect
    self.effect_key = next_key
    self:_apply_bar_colors()
    self.icon:SetVisible(true)
    self.icon:SetEffect(effect)
end

function SelfExpiringEffectEntry:update_remaining(remaining_seconds, initial_seconds)
    if self.effect == nil then
        self.name_label:SetText("")
        self.time_label:SetText("")
        self.bar_fill:SetWidth(0)
        return
    end

    local s = State.settings.self.expiring_effects
    local inner_width = self.bar_inner_w

    local base = initial_seconds
    if type(base) ~= "number" or base <= 0 then
        base = remaining_seconds
    end

    local percent = remaining_seconds / base
    if percent < 0 then percent = 0 end
    if percent > 1 then percent = 1 end
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - percent
    end

    local fill_width = math.floor(inner_width * percent + 0.5)
    if fill_width < 0 then fill_width = 0 end
    if fill_width > inner_width then fill_width = inner_width end

    if self.bar_anchor_right then
        self.bar_fill:SetPosition(inner_width - fill_width, 0)
    else
        self.bar_fill:SetPosition(0, 0)
    end
    self.bar_fill:SetWidth(fill_width)

    local name = _truncate_name(tostring(self.effect:GetName() or ""), s.name_max_chars)
    self.name_label:SetText(name)
    self.time_label:SetText(lui_timed_row_format_time(remaining_seconds, EFFECT_TIME_FORMAT))
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function SelfExpiringEffectEntry:_apply_bar_colors()
    local s = State.settings.self.expiring_effects
    local bar_color = self:_resolve_bar_color()
    self.bar_background:SetBackColor(self:_resolve_bar_background_color(bar_color))
    self.bar_fill:SetBackColor(lui_apply_opacity_to_color(bar_color, s.bar_opacity))
end

function SelfExpiringEffectEntry:_resolve_bar_background_color(bar_color)
    local s = State.settings.self.expiring_effects
    local color

    if s.bar_background_matches_fill == true then
        color = lui_dim_color(bar_color, s.bar_background_dimming)
    else
        color = s.color.background
    end

    return lui_apply_opacity_to_color(color, s.background_opacity)
end

function SelfExpiringEffectEntry:_resolve_bar_color()
    local s = State.settings.self.expiring_effects

    if self.effect == nil then
        return s.color.bar_buff
    end

    local is_debuff = self.effect.IsDebuff ~= nil and self.effect:IsDebuff()
    if not is_debuff then
        return s.color.bar_buff
    end

    local is_curable = self.effect.IsCurable ~= nil and self.effect:IsCurable()
    if is_curable then
        return s.color.bar_debuff_curable
    end

    return s.color.bar_debuff_noncurable
end
