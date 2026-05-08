import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"

---@class GroupMemberVitals : VitalsBase
GroupMemberVitals = class(VitalsBase)

function GroupMemberVitals:Constructor(settings_root, entity)
    self.settings_root = settings_root
    self.is_leader = false
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
    if self.entity ~= entity then
        self:_detach_silent_effect_manager()
    end

    VitalsBase.set_entity(self, entity)
    self:_update_class_icon()
    self:_update_leader_icon()
    self:_setup_silent_effect_manager()
end

function GroupMemberVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end
end

function GroupMemberVitals:get_lower_bars_height()
    return self:get_vitals_settings().power.height
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
