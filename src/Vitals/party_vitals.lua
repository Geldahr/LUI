import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.UI.moveable"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"

local function _is_local_player(entity)
    local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    if entity == nil or lp == nil then
        return false
    end
    if entity.GetName == nil or lp.GetName == nil then
        return false
    end
    return entity:GetName() == lp:GetName()
end

---@class PartyMemberVitals : VitalsBase
PartyMemberVitals = class(VitalsBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function PartyMemberVitals:Constructor(entity)
    self.is_leader = false
    self.em = nil
    self.em_added_event = nil
    VitalsBase.Constructor(self, "party", entity, "Party Member", {
        show_effects = false,
        show_moveable = false,
        managed_position = true,
    })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function PartyMemberVitals:set_is_leader(is_leader)
    self.is_leader = is_leader == true
    self:_update_leader_icon()
end

function PartyMemberVitals:set_entity(entity)
    if self.entity ~= entity then
        self:_detach_silent_effect_manager()
    end

    VitalsBase.set_entity(self, entity)
    self:_update_class_icon()
    self:_update_leader_icon()
    self:_setup_silent_effect_manager()
end

function PartyMemberVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end
end

function PartyMemberVitals:get_lower_bars_height()
    local v = self:get_vitals_settings()
    return v.power.height
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function PartyMemberVitals:_setup_silent_effect_manager()
    if self.em ~= nil then
        self:SetWantsUpdates(true)
        return
    end

    if self.entity == nil or _is_local_player(self.entity) == true then
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

function PartyMemberVitals:_detach_silent_effect_manager()
    if self.em == nil then
        self.em_added_event = nil
        self:SetWantsUpdates(false)
        return
    end

    if self.em_added_event ~= nil and self.em.unregister_added_event ~= nil then
        self.em:unregister_added_event(self.em_added_event)
        self.em_added_event = nil
    end

    self.em:delete()
    self.em = nil
    self:SetWantsUpdates(false)
end

function PartyMemberVitals:_update_class_icon()
    local v = self:get_vitals_settings()
    local ci = v.class_icon
    if ci.enabled ~= true then
        self.class_icon:SetVisible(false)
        return
    end
    local size = ci.size

    if size <= 0 or self.entity == nil then
        self.class_icon:SetVisible(false)
        return
    end

    local icon = _G.get_class_icon(self.entity:GetClass(), ci.size)
    if icon == nil then
        self.class_icon:SetVisible(false)
        return
    end

    self.class_icon:SetPosition(ci.x, ci.y)
    self.class_icon:set_icon(icon, ci.size, ci.size)
    self.class_icon:SetVisible(true)
end

function PartyMemberVitals:_update_leader_icon()
    local v = self:get_vitals_settings()
    local li = v.leader_icon

    if li.enabled ~= true or self.is_leader ~= true then
        self.leader_icon:SetVisible(false)
        return
    end

    if li.size <= 0 then
        self.leader_icon:SetVisible(false)
        return
    end

    local icon = _G.get_party_leader_icon ~= nil and _G.get_party_leader_icon() or nil
    if icon == nil then
        self.leader_icon:SetVisible(false)
        return
    end

    self.leader_icon:SetPosition(li.x, li.y)
    self.leader_icon:set_icon(icon, li.size, li.size)
    self.leader_icon:SetVisible(true)
end

function PartyMemberVitals:_build_extra_controls()
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

function PartyMemberVitals:_resize_extra_controls()
    local v = self:get_vitals_settings()
    local ci = v.class_icon
    if ci.enabled == true and ci.size > 0 then
        self.class_icon:set_size(ci.size, ci.size)
        self.class_icon:SetPosition(ci.x, ci.y)
    else
        self.class_icon:SetVisible(false)
    end

    local li = v.leader_icon
    if li.enabled == true and li.size > 0 then
        self.leader_icon:set_size(li.size, li.size)
        self.leader_icon:SetPosition(li.x, li.y)
    else
        self.leader_icon:SetVisible(false)
    end

    self:_update_class_icon()
    self:_update_leader_icon()
end

---@class PartyVitals : Turbine.UI.Window
PartyVitals = class(Turbine.UI.Window)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function PartyVitals:Constructor()
    Turbine.UI.Window.Constructor(self)

    self.lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.group = nil
    self.group_type = nil

    self.members = {}
    self.events = {
        party_changed = nil,
        raid_changed = nil,
        member_added = nil,
        member_removed = nil,
        leader_changed = nil,
    }

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    local v = _G.settings.party
    local hud = _G.settings.ui.hud.party_vitals
    self:SetPosition(hud.left, hud.top)
    local bw = v.frame.border_width
    local initial_h = v.morale.height + v.power.height - bw
    if initial_h < 1 then initial_h = 1 end
    self:SetSize(v.frame.width, initial_h)

    self.moveable = UI.Moveable(self, function(x, y)
        self:SetPosition(x, y)
    end, TR["Party Vitals"])

    self.moveable:set_on_move_end(function(x, y)
        self:persist_position(x, y)
    end)

    self.events.party_changed = add_callback(self.lp, "PartyChanged", function()
        self:refresh_group()
    end)
    if self.lp ~= nil and self.lp.RaidChanged ~= nil then
        self.events.raid_changed = add_callback(self.lp, "RaidChanged", function()
            self:refresh_group()
        end)
    end

    self:refresh_group()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function PartyVitals:is_move_mode()
    return self.moveable ~= nil and self.moveable:is_move_mode() or false
end

function PartyVitals:set_move_mode(enabled)
    if is_lui_hud_visible() ~= true then
        self:SetVisible(false)
        if self.moveable ~= nil then
            self.moveable:set_move_mode(enabled)
        end
        return
    end

    if enabled == true then
        self:SetVisible(true)
    end
    if self.moveable ~= nil then
        self.moveable:set_move_mode(enabled)
    end
    self:update_members()
    if self.moveable ~= nil then
        self.moveable:update_size()
        self.moveable:sync_from_target()
        self.moveable:sync_inputs_from_target()
    end
end

function PartyVitals:persist_position(x, y)
    local hud = _G.get_ui_hud_state("party_vitals")
    hud.left = x
    hud.top = y
end

function PartyVitals:get_placeholder_count()
    return 24
end

function PartyVitals:detach_group_events()
    if self.group == nil then
        return
    end
    remove_callback(self.group, "MemberAdded", self.events.member_added)
    self.events.member_added = nil
    remove_callback(self.group, "MemberRemoved", self.events.member_removed)
    self.events.member_removed = nil
    remove_callback(self.group, "LeaderChanged", self.events.leader_changed)
    self.events.leader_changed = nil
end

function PartyVitals:attach_group_events()
    if self.group == nil then
        return
    end
    self.events.member_added = add_callback(self.group, "MemberAdded", function()
        self:update_members()
    end)
    self.events.member_removed = add_callback(self.group, "MemberRemoved", function()
        self:update_members()
    end)
    self.events.leader_changed = add_callback(self.group, "LeaderChanged", function()
        self:update_members()
    end)
end

function PartyVitals:refresh_group()
    local new_group, new_type = self:_get_current_group()

    if self.group ~= new_group then
        self:detach_group_events()
        self.group = new_group
        self.group_type = new_type
        self:attach_group_events()
    else
        self.group_type = new_type
    end

    self:update_members()
end

function PartyVitals:ensure_member_windows(n)
    for i = #self.members + 1, n do
        local m = PartyMemberVitals(nil)
        m:SetParent(self)
        m:SetZOrder(10)
        if m.entity_control ~= nil then
            m.entity_control:SetMouseVisible(not self:is_move_mode())
        end
        m:SetVisible(false)
        table.insert(self.members, m)
    end
end

function PartyVitals:get_member_count()
    if self.group == nil or self.group.GetMemberCount == nil then
        return 0
    end
    return self.group:GetMemberCount() or 0
end

function PartyVitals:layout_members(count)
    local v = _G.settings.party
    local layout = v.layout
    local rows = layout.rows
    local spacing_x = layout.spacing_x
    local spacing_y = layout.spacing_y

    local member_w = v.frame.width
    local bw = v.frame.border_width
    local member_h = v.morale.height + v.power.height - bw
    if member_h < 1 then member_h = 1 end

    if count < 0 then count = 0 end

    local columns = 1
    if count > 0 then
        columns = math.ceil(count / rows)
        if columns < 1 then columns = 1 end
    end

    local used_rows = count
    if used_rows > rows then used_rows = rows end
    if used_rows < 1 then used_rows = 1 end

    local total_w = (columns * member_w) + ((columns - 1) * spacing_x)
    local total_h = (used_rows * member_h) + ((used_rows - 1) * spacing_y)
    if total_w < member_w then total_w = member_w end
    if total_h < member_h then total_h = member_h end

    self:SetSize(total_w, total_h)

    for i = 1, #self.members do
        local m = self.members[i]
        if m ~= nil then
            if i <= count then
                local idx = i - 1
                local col = math.floor(idx / rows)
                local row = idx - (col * rows)
                local x = col * (member_w + spacing_x)
                local y = row * (member_h + spacing_y)
                m:SetPosition(x, y)
            else
                m:SetPosition(0, 0)
            end
        end
    end

    if self:is_move_mode() and self.moveable ~= nil and self.moveable.update_size ~= nil then
        self.moveable:update_size()
    end
end

function PartyVitals:update_visibility(member_count)
    if is_lui_hud_visible() ~= true then
        self:SetVisible(false)
        return
    end

    if self:is_move_mode() then
        self:SetVisible(true)
        return
    end
    self:SetVisible(member_count ~= nil and member_count > 0)
end

function PartyVitals:apply_settings()
    local v = _G.settings.party
    local hud = _G.settings.ui.hud.party_vitals
    self:SetPosition(hud.left, hud.top)

    for i = 1, #self.members do
        local m = self.members[i]
        if m ~= nil and m.resize ~= nil then
            m:resize()
        end
    end
    self:update_members()
end

function PartyVitals:update_members()
    local entities = {}
    local total = self:get_member_count()
    for i = 1, total do
        local e = nil
        if self.group ~= nil and self.group.GetMember ~= nil then
            e = self.group:GetMember(i)
        end
        if e ~= nil then
            table.insert(entities, e)
        end
    end

    local party_count = #entities
    local desired = party_count
    if self:is_move_mode() and desired == 0 then
        desired = self:get_placeholder_count()
    end

    local leader_name = nil
    if self.group ~= nil then
        if self.group.GetLeader ~= nil then
            local leader = self.group:GetLeader()
            if leader ~= nil and leader.GetName ~= nil then
                leader_name = leader:GetName()
            end
        end
    end

    self:ensure_member_windows(desired)

    for i = 1, #self.members do
        local m = self.members[i]
        if m ~= nil then
            if m.entity_control ~= nil then
                m.entity_control:SetMouseVisible(not self:is_move_mode())
            end
            if i <= party_count then
                m:set_entity(entities[i])
                if leader_name ~= nil and entities[i].GetName ~= nil then
                    m:set_is_leader(entities[i]:GetName() == leader_name)
                else
                    m:set_is_leader(false)
                end
                m:SetVisible(true)
            elseif self:is_move_mode() and i <= desired then
                m:set_entity(nil)
                m:set_is_leader(i == 1)
                m:SetVisible(true)
            else
                m:set_entity(nil)
                m:set_is_leader(false)
                m:SetVisible(false)
            end
        end
    end

    self:layout_members(desired)
    self:update_visibility(party_count)
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function PartyVitals:_is_local_player(entity)
    if entity == nil or self.lp == nil then
        return false
    end
    if entity.GetName == nil or self.lp.GetName == nil then
        return false
    end
    return entity:GetName() == self.lp:GetName()
end

function PartyVitals:_get_current_group()
    if self.lp == nil then
        return nil, nil
    end

    if self.lp.GetParty ~= nil then
        local party = self.lp:GetParty()
        if party ~= nil then
            local group_type = "party"
            if party.GetMemberCount ~= nil then
                local count = party:GetMemberCount() or 0
                if count > 6 then
                    group_type = "raid"
                end
            end
            return party, group_type
        end
    end

    return nil, nil
end
