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
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.color"

local TargetsTargetVitalsWindow = class(UI.Widgets.LuiHUD)
Vitals.TargetsTargetVitalsWindow = TargetsTargetVitalsWindow

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:Constructor(owner)
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "target_target_vitals",
        title = TR["Target's Target"],
    })

    self.owner = owner

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.targets_target_border = Turbine.UI.Control()
    self.targets_target_border:SetParent(self)
    self.targets_target_border:SetMouseVisible(false)

    self.targets_target_background = Turbine.UI.Control()
    self.targets_target_background:SetParent(self.targets_target_border)
    self.targets_target_background:SetMouseVisible(false)

    self.targets_target_morale = Turbine.UI.Control()
    self.targets_target_morale:SetParent(self.targets_target_background)
    self.targets_target_morale:SetMouseVisible(false)
    self.targets_target_morale:SetZOrder(2)

    self.targets_target_bubble = Turbine.UI.Control()
    self.targets_target_bubble:SetParent(self.targets_target_background)
    self.targets_target_bubble:SetMouseVisible(false)
    self.targets_target_bubble:SetZOrder(3)
    self.targets_target_bubble:SetVisible(false)

    self.targets_target_labels = {}
    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(self.targets_target_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(49 + i)
        self.targets_target_labels[i] = label
    end

    self.targets_control = Turbine.UI.Lotro.EntityControl()
    self.targets_control:SetParent(self)
    self.targets_control:SetMouseVisible(true)
    self.targets_control:SetEntity(nil)
    self.targets_control:SetZOrder(4)

    self:apply_settings()
    self:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:set_move_mode(enabled)
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    if State.loaded_settings.target.vitals.targets_target.enabled == true and enabled == true then
        self:SetVisible(true)
    elseif State.loaded_settings.target.vitals.targets_target.enabled ~= true then
        self:SetVisible(false)
    end
end

function TargetsTargetVitalsWindow:apply_settings()
    self:apply_native_scaling()

    local v = State.settings.target.vitals
    local tt = v.targets_target

    local border = tt.border_width
    local frame_w = tt.width
    local h = tt.height

    self:SetSize(frame_w, h)
    self:layout_move_chrome()

    self.targets_target_border:SetSize(frame_w, h)
    self.targets_target_border:SetBackColor(tt.color.border)

    local inner_w = frame_w - (2 * border)
    local inner_h = h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    self.targets_target_background:SetPosition(border, border)
    self.targets_target_background:SetSize(inner_w, inner_h)
    self.targets_target_background:SetBackColor(lui_apply_opacity_to_color(
        tt.color.background,
        tt.background_opacity
    ))

    self.targets_target_morale:SetPosition(0, 0)
    self.targets_target_morale:SetSize(inner_w, inner_h)

    self.targets_target_bubble:SetBackColor(tt.color.bubble)
    self.targets_target_bubble:SetTop(0)
    self.targets_target_bubble:SetHeight(inner_h)

    self.targets_control:SetSize(frame_w, h)
    self.targets_control:SetPosition(0, 0)

    self:apply_hud_position()
end
