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
local TARGET_HIGHLIGHT_COLOR = Turbine.UI.Color(1, 1, 0.82, 0.12)

---@class GroupMemberVitals : VitalsBase
GroupMemberVitals = class(VitalsBase)

function GroupMemberVitals:Constructor(settings_root, entity)
    self.settings_root = settings_root
    self.is_leader = false
    self.target_highlighted = false
    self.link_dead_event = nil
    self.em = nil
    self.em_added_event = nil

    VitalsBase.Constructor(self, settings_root, entity, "Group Member", {
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

    VitalsBase.set_entity(self, entity)
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
    VitalsBase.self_morale_changed(self)
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
    if self.target_highlighted == true then
        self:set_frame_border_color_override(TARGET_HIGHLIGHT_COLOR)
    else
        self:set_frame_border_color_override(nil)
    end
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

    self.em = TargetEffectManager.acquire_silent(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
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

    local icon = _G.get_class_icon(self.entity:GetClass(), size)
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

    local icon = _G.get_party_leader_icon()
    if icon == nil then
        self.leader_icon:SetVisible(false)
        return
    end

    self.leader_icon:SetPosition(leader_icon_settings.x, leader_icon_settings.y)
    self.leader_icon:set_icon(icon, leader_icon_settings.size, leader_icon_settings.size)
    self.leader_icon:SetVisible(true)
end

function GroupMemberVitals:_build_extra_controls()
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

    self.class_icon = Image()
    self.class_icon:SetParent(self)
    self.class_icon:SetZOrder(10)
    self.class_icon:SetVisible(false)

    self.leader_icon = Image()
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
