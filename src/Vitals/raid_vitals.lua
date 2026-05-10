import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.raid_layout"
import "LUI.src.Vitals.group_snapshot"
import "LUI.src.Vitals.group_ordering"
import "LUI.src.Vitals.group_layout"
import "LUI.src.Vitals.group_member_vitals"
import "LUI.src.Vitals.raid_group_vitals"

local function _raid_vitals_enabled()
    return _G.loaded_settings.raid.enabled == true
end

local function _raid_split_enabled()
    return _G.loaded_settings.raid.split_by_group == true
end

local function _raid_active(snapshot)
    return snapshot.member_count >= 7
end

---@class RaidVitals : LuiHUD
RaidVitals = class(LuiHUD)

function RaidVitals:Constructor()
    LuiHUD.Constructor(self, {
        hud_key = "raid_vitals",
        title = TR["Raid Vitals"],
    })

    self.lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.group = nil
    self.members = {}
    self.group_windows = {
        RaidGroupVitalsWindow("a", 1),
        RaidGroupVitalsWindow("b", 2),
        RaidGroupVitalsWindow("c", 3),
        RaidGroupVitalsWindow("d", 4),
    }
    self.events = {
        party_changed = nil,
        raid_changed = nil,
        member_added = nil,
        member_removed = nil,
        leader_changed = nil,
    }

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    local vitals_settings = _G.settings.raid
    local initial_height = GroupLayout.member_height(vitals_settings)
    self:SetSize(vitals_settings.frame.width, initial_height)
    self:layout_move_chrome()
    self:apply_hud_position()

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

function RaidVitals:set_move_mode(enabled)
    if enabled == true and _raid_vitals_enabled() == true and _raid_split_enabled() ~= true then
        self:SetVisible(true)
    end

    LuiHUD.set_move_mode(self, enabled)
    for i = 1, #self.group_windows do
        self.group_windows[i]:set_move_mode(enabled)
    end
    self:update_members()
end

function RaidVitals:get_placeholder_count()
    return 24
end

function RaidVitals:detach_group_events()
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

function RaidVitals:attach_group_events()
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

function RaidVitals:refresh_group()
    local snapshot = GroupSnapshot.read(self.lp)
    local new_group = snapshot.group

    if self.group ~= new_group then
        self:detach_group_events()
        self.group = new_group
        self:attach_group_events()
    end

    self:update_members(snapshot)
    _G.apply_lotro_vitals_handoff()
end

function RaidVitals:ensure_member_windows(count)
    for i = #self.members + 1, count do
        local member_window = GroupMemberVitals("raid", nil)
        member_window:SetParent(self)
        member_window:SetZOrder(10)
        member_window.entity_control:SetMouseVisible(not self:is_move_mode())
        member_window:SetVisible(false)
        table.insert(self.members, member_window)
    end
end

function RaidVitals:layout_members(count)
    local vitals_settings = _G.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local total_width, total_height = GroupLayout.compute_raid_size(count, layout.mode, layout.spacing_x, layout.spacing_y,
        member_width, member_height)

    self:SetSize(total_width, total_height)
    GroupLayout.apply_raid_positions(self.members, count, layout.mode, layout.spacing_x, layout.spacing_y, member_width,
        member_height)

    if self:is_move_mode() then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
    end
end

function RaidVitals:update_visibility(active, visible_members)
    if _raid_vitals_enabled() ~= true or _raid_split_enabled() == true then
        self:SetVisible(false)
        return
    end
    if self:is_move_mode() then
        self:SetVisible(true)
        return
    end

    self:SetVisible(active == true and visible_members > 0)
end

function RaidVitals:apply_settings()
    self:apply_native_scaling()
    self:apply_hud_position()

    for i = 1, #self.members do
        self.members[i]:resize()
    end
    for i = 1, #self.group_windows do
        self.group_windows[i]:apply_settings()
    end

    self:update_members()
    _G.apply_lotro_vitals_handoff()
end

function RaidVitals:group_border_color(member_index)
    local group_index = RaidLayout.member_group_index(member_index)
    return self.group_windows[group_index]:get_border_color()
end

function RaidVitals:hide_combined_members()
    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(false)
        member_window:set_entity(nil)
        member_window:set_is_leader(false)
        member_window:SetVisible(false)
    end

    self:SetVisible(false)
end

function RaidVitals:update_combined_members(active, ordered_members, leader_name)
    if _raid_split_enabled() == true then
        self:hide_combined_members()
        return
    end

    local move_mode = self:is_move_mode()
    local desired_count = #ordered_members
    if move_mode == true and desired_count == 0 then
        desired_count = self:get_placeholder_count()
    elseif move_mode == true and active ~= true then
        desired_count = self:get_placeholder_count()
    end

    self:ensure_member_windows(desired_count)

    if move_mode == true then
        for i = 1, #self.members do
            local member_window = self.members[i]
            member_window.entity_control:SetMouseVisible(false)
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:set_frame_border_color_override(self:group_border_color(i))
            member_window:SetVisible(false)
        end

        self:layout_members(desired_count)
        self:update_visibility(active, #ordered_members)
        return
    end

    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(true)
        member_window:set_frame_border_color_override(self:group_border_color(i))

        if i <= #ordered_members then
            local entity = ordered_members[i]
            member_window:set_entity(entity)
            member_window:set_is_leader(leader_name ~= nil and entity:GetName() == leader_name)
            member_window:SetVisible(true)
        else
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:SetVisible(false)
        end
    end

    self:layout_members(desired_count)
    self:update_visibility(active, #ordered_members)
end

function RaidVitals:update_split_members(active, ordered_members, leader_name)
    local group_size = RaidLayout.group_size()

    for group_index = 1, #self.group_windows do
        local first_member = ((group_index - 1) * group_size) + 1
        local group_members = {}
        for offset = 0, group_size - 1 do
            local entity = ordered_members[first_member + offset]
            if entity ~= nil then
                group_members[#group_members + 1] = entity
            end
        end

        self.group_windows[group_index]:update_members(group_members, leader_name, active)
    end
end

function RaidVitals:update_members(snapshot)
    local current_snapshot = snapshot or GroupSnapshot.read(self.lp)
    local active = _raid_active(current_snapshot)
    local ordered_members = {}
    if active == true then
        ordered_members = GroupOrdering.raid_members(current_snapshot)
    end

    local leader_name = current_snapshot.leader_name
    self:update_combined_members(active, ordered_members, leader_name)
    self:update_split_members(active, ordered_members, leader_name)
end
