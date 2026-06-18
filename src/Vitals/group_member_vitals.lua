import "LUI.src.Utils.callbacks"
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
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local get_class_icon = _G.LUI.Utils.get_class_icon
local get_party_leader_icon = _G.LUI.Utils.get_party_leader_icon
local Vitals = _G.LUI.Features.Vitals
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"

local DEAD_STATE_COLOR = Turbine.UI.Color(0.78, 0.20, 0.02, 0.02)
local OFFLINE_STATE_COLOR = Turbine.UI.Color(0.78, 0.03, 0.03, 0.03)
local STATE_TEXT_COLOR = Turbine.UI.Color(1, 1, 1, 1)
local STATE_OUTLINE_COLOR = Turbine.UI.Color(1, 0, 0, 0)

local function _set_select_border_visible(border, visible)
    border.top:SetVisible(visible)
    border.bottom:SetVisible(visible)
    border.left:SetVisible(visible)
    border.right:SetVisible(visible)
end

local function _set_select_border_color(border, color)
    border.top:SetBackColor(color)
    border.bottom:SetBackColor(color)
    border.left:SetBackColor(color)
    border.right:SetBackColor(color)
end

local function _apply_select_border(border, x, y, width, height, thickness, color)
    if thickness <= 0 or width <= 0 or height <= 0 then
        _set_select_border_visible(border, false)
        return
    end

    _set_select_border_color(border, color)

    border.top:SetPosition(x, y)
    border.top:SetSize(width, thickness)
    border.top:SetVisible(true)

    border.bottom:SetPosition(x, y + height - thickness)
    border.bottom:SetSize(width, thickness)
    border.bottom:SetVisible(true)

    border.left:SetPosition(x, y)
    border.left:SetSize(thickness, height)
    border.left:SetVisible(true)

    border.right:SetPosition(x + width - thickness, y)
    border.right:SetSize(thickness, height)
    border.right:SetVisible(true)
end

---@class GroupMemberVitals : VitalsBase
local GroupMemberVitals = class(Vitals.VitalsBase)
Vitals.GroupMemberVitals = GroupMemberVitals

function GroupMemberVitals:Constructor(settings_root, entity)
    self.settings_root = settings_root
    self.is_leader = false
    self.target_highlighted = false
    self.link_dead_event = nil
    self.em = nil
    self.em_added_event = nil

    Vitals.VitalsBase.Constructor(self, settings_root, entity, "Group Member", {
        hud_key = settings_root .. "_vitals",
        show_effects = false,
        move_ui = false,
        managed_position = true,
    })
end

function GroupMemberVitals:set_is_leader(is_leader)
    self.is_leader = is_leader == true
    self:_update_leader_icon()
end

function GroupMemberVitals:set_entity(entity)
    local entity_changed = self.entity ~= entity
    if entity_changed == true then
        self:_detach_silent_effect_manager()
        self:_detach_link_dead_event()
        self.target_highlighted = false
    end

    Vitals.VitalsBase.set_entity(self, entity)
    self:_attach_link_dead_event()
    self:_update_class_icon()
    self:_update_leader_icon()
    self:_setup_silent_effect_manager()
    self:_update_member_state()
    self:_apply_target_highlight()
end

function GroupMemberVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end
end

function GroupMemberVitals:get_lower_bars_height()
    return self:get_vitals_settings().power.height
end

function GroupMemberVitals:set_target_highlighted(highlighted)
    self.target_highlighted = highlighted == true
    self:_apply_target_highlight()
end

function GroupMemberVitals:set_target_name(target_name)
    if target_name == nil or self.entity == nil or self.entity.GetName == nil then
        self:set_target_highlighted(false)
        return
    end

    self:set_target_highlighted(self.entity:GetName() == target_name)
end

function GroupMemberVitals:self_morale_changed()
    Vitals.VitalsBase.self_morale_changed(self)
    self:_update_member_state()
end

function GroupMemberVitals:_is_local_player(entity)
    local local_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if entity == nil or local_player == nil then
        return false
    end
    if entity.GetName == nil or local_player.GetName == nil then
        return false
    end

    return entity:GetName() == local_player:GetName()
end

function GroupMemberVitals:_entity_is_link_dead()
    if self.entity == nil or self.entity.IsLinkDead == nil then
        return false
    end

    return self.entity:IsLinkDead() == true
end

function GroupMemberVitals:_entity_is_dead()
    if self.entity == nil or self.entity.GetMorale == nil then
        return false
    end

    local morale = self.entity:GetMorale()
    return type(morale) == "number" and morale <= 0
end

function GroupMemberVitals:_attach_link_dead_event()
    if self.link_dead_event ~= nil then
        return
    end
    if self.entity == nil or self.entity.IsLinkDead == nil then
        return
    end

    self.link_dead_event = add_callback(self.entity, "IsLinkDeadChanged", function()
        self:_update_member_state()
    end)
end

function GroupMemberVitals:_detach_link_dead_event()
    if self.link_dead_event == nil then
        return
    end

    remove_callback(self.entity, "IsLinkDeadChanged", self.link_dead_event)
    self.link_dead_event = nil
end

function GroupMemberVitals:_set_member_state(text, color)
    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()

    self.state_overlay:SetPosition(x, y)
    self.state_overlay:SetSize(width, height)
    self.state_overlay:SetBackColor(color)
    self.state_label:SetSize(width, height)
    self.state_label:SetText(text)
    self.state_overlay:SetVisible(true)
    self.state_label:SetVisible(true)
end

function GroupMemberVitals:_clear_member_state()
    self.state_label:SetText("")
    self.state_label:SetVisible(false)
    self.state_overlay:SetVisible(false)
end

function GroupMemberVitals:_apply_target_highlight()
    local select_settings = self:get_vitals_settings().select
    if self.target_highlighted ~= true or select_settings.enabled ~= true then
        _set_select_border_visible(self.select_border, false)
        return
    end

    local x, y = self.entity_control:GetPosition()
    local width, height = self.entity_control:GetSize()
    _apply_select_border(self.select_border, x, y, width, height, select_settings.border_width,
        select_settings.border_color)
end

function GroupMemberVitals:_update_member_state()
    if self:_entity_is_link_dead() == true then
        self:_set_member_state(TR["OFFLINE"], OFFLINE_STATE_COLOR)
    elseif self:_entity_is_dead() == true then
        self:_set_member_state(TR["DEAD"], DEAD_STATE_COLOR)
    else
        self:_clear_member_state()
    end
end

function GroupMemberVitals:_setup_silent_effect_manager()
    if self.em ~= nil then
        self:SetWantsUpdates(true)
        return
    end

    if self.entity == nil or self:_is_local_player(self.entity) == true then
        self:SetWantsUpdates(false)
        return
    end

    if self.entity.GetEffects == nil or self.entity:GetEffects() == nil then
        self:SetWantsUpdates(false)
        return
    end

    self.em = Vitals.TargetEffectManager.acquire_silent(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
    self.em_added_event = self.em:register_added_event(function()
    end)
    self:SetWantsUpdates(true)
end

function GroupMemberVitals:_detach_silent_effect_manager()
    if self.em == nil then
        self.em_added_event = nil
        self:SetWantsUpdates(false)
        return
    end

    if self.em_added_event ~= nil then
        self.em:unregister_added_event(self.em_added_event)
        self.em_added_event = nil
    end

    self.em:delete()
    self.em = nil
    self:SetWantsUpdates(false)
end

function GroupMemberVitals:_update_class_icon()
    local class_icon_settings = self:get_vitals_settings().class_icon
    if class_icon_settings.enabled ~= true then
        self.class_icon:SetVisible(false)
        return
    end

    local size = class_icon_settings.size
    if size <= 0 or self.entity == nil then
        self.class_icon:SetVisible(false)
        return
    end

    local icon = get_class_icon(self.entity:GetClass(), size)
    if icon == nil then
        self.class_icon:SetVisible(false)
        return
    end

    self.class_icon:SetPosition(class_icon_settings.x, class_icon_settings.y)
    self.class_icon:set_icon(icon, size, size)
    self.class_icon:SetVisible(true)
end

function GroupMemberVitals:_update_leader_icon()
    local leader_icon_settings = self:get_vitals_settings().leader_icon
    if leader_icon_settings.enabled ~= true or self.is_leader ~= true then
        self.leader_icon:SetVisible(false)
        return
    end
    if leader_icon_settings.size <= 0 then
        self.leader_icon:SetVisible(false)
        return
    end

    local icon = get_party_leader_icon()
    if icon == nil then
        self.leader_icon:SetVisible(false)
        return
    end

    self.leader_icon:SetPosition(leader_icon_settings.x, leader_icon_settings.y)
    self.leader_icon:set_icon(icon, leader_icon_settings.size, leader_icon_settings.size)
    self.leader_icon:SetVisible(true)
end

function GroupMemberVitals:_build_extra_controls()
    self.select_border = {
        top = Turbine.UI.Control(),
        bottom = Turbine.UI.Control(),
        left = Turbine.UI.Control(),
        right = Turbine.UI.Control(),
    }
    self.select_border.top:SetParent(self)
    self.select_border.top:SetMouseVisible(false)
    self.select_border.top:SetZOrder(75)
    self.select_border.top:SetVisible(false)
    self.select_border.bottom:SetParent(self)
    self.select_border.bottom:SetMouseVisible(false)
    self.select_border.bottom:SetZOrder(75)
    self.select_border.bottom:SetVisible(false)
    self.select_border.left:SetParent(self)
    self.select_border.left:SetMouseVisible(false)
    self.select_border.left:SetZOrder(75)
    self.select_border.left:SetVisible(false)
    self.select_border.right:SetParent(self)
    self.select_border.right:SetMouseVisible(false)
    self.select_border.right:SetZOrder(75)
    self.select_border.right:SetVisible(false)

    self.state_overlay = Turbine.UI.Control()
    self.state_overlay:SetParent(self)
    self.state_overlay:SetMouseVisible(false)
    self.state_overlay:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.state_overlay:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.state_overlay:SetZOrder(60)
    self.state_overlay:SetVisible(false)

    self.state_label = UI.Widgets.LuiLabel()
    self.state_label:SetParent(self.state_overlay)
    self.state_label:SetMouseVisible(false)
    self.state_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.state_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.state_label:SetForeColor(STATE_TEXT_COLOR)
    self.state_label:SetOutlineColor(STATE_OUTLINE_COLOR)
    self.state_label:SetZOrder(1)
    self.state_label:SetVisible(false)

    self.class_icon = UI.Widgets.Image()
    self.class_icon:SetParent(self)
    self.class_icon:SetZOrder(10)
    self.class_icon:SetVisible(false)

    self.leader_icon = UI.Widgets.Image()
    self.leader_icon:SetParent(self)
    self.leader_icon:SetZOrder(11)
    self.leader_icon:SetVisible(false)

    self:_resize_extra_controls()
    self:_update_class_icon()
    self:_update_leader_icon()
end

function GroupMemberVitals:_resize_extra_controls()
    local vitals_settings = self:get_vitals_settings()
    self.state_label:SetFont(vitals_settings.labels[1].font.lotro)
    self:_update_member_state()
    self:_apply_target_highlight()

    local class_icon_settings = vitals_settings.class_icon
    if class_icon_settings.enabled == true and class_icon_settings.size > 0 then
        self.class_icon:set_size(class_icon_settings.size, class_icon_settings.size)
        self.class_icon:SetPosition(class_icon_settings.x, class_icon_settings.y)
    else
        self.class_icon:SetVisible(false)
    end

    local leader_icon_settings = vitals_settings.leader_icon
    if leader_icon_settings.enabled == true and leader_icon_settings.size > 0 then
        self.leader_icon:set_size(leader_icon_settings.size, leader_icon_settings.size)
        self.leader_icon:SetPosition(leader_icon_settings.x, leader_icon_settings.y)
    else
        self.leader_icon:SetVisible(false)
    end

    self:_update_class_icon()
    self:_update_leader_icon()
end
