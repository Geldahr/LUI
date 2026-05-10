import "Turbine.UI"

import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.raid_layout"
import "LUI.src.Vitals.group_layout"
import "LUI.src.Vitals.group_member_vitals"

local function _raid_group_windows_enabled()
    return _G.loaded_settings.raid.enabled == true and _G.loaded_settings.raid.split_by_group == true
end

---@class RaidGroupVitalsWindow : LuiHUD
RaidGroupVitalsWindow = class(LuiHUD)

function RaidGroupVitalsWindow:Constructor(group_key, group_index)
    self.group_key = group_key
    self.group_index = group_index
    self.members = {}
    self.current_members = {}
    self.current_leader_name = nil
    self.current_active = false

    LuiHUD.Constructor(self, {
        hud_key = "raid_group_" .. group_key .. "_vitals",
        title = TR["Raid Group "] .. string.upper(group_key),
    })

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetVisible(false)

    local vitals_settings = _G.settings.raid
    local initial_height = GroupLayout.member_height(vitals_settings)
    self:SetSize(vitals_settings.frame.width, initial_height)
    self:layout_move_chrome()
    self:apply_hud_position()
end

function RaidGroupVitalsWindow:set_move_mode(enabled)
    if enabled == true and _raid_group_windows_enabled() == true then
        self:SetVisible(true)
    end

    LuiHUD.set_move_mode(self, enabled)
    self:update_members(self.current_members, self.current_leader_name, self.current_active)
end

function RaidGroupVitalsWindow:get_placeholder_count()
    return RaidLayout.group_size()
end

function RaidGroupVitalsWindow:ensure_member_windows(count)
    for i = #self.members + 1, count do
        local member_window = GroupMemberVitals("raid", nil)
        member_window:SetParent(self)
        member_window:SetZOrder(10)
        member_window.entity_control:SetMouseVisible(not self:is_move_mode())
        member_window:SetVisible(false)
        table.insert(self.members, member_window)
    end
end

function RaidGroupVitalsWindow:get_border_color()
    return _G.settings.raid.group_colors[self.group_key]
end

function RaidGroupVitalsWindow:layout_members(count)
    local vitals_settings = _G.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local total_width, total_height = GroupLayout.compute_raid_group_size(count, layout.mode, layout.spacing_x,
        layout.spacing_y, member_width, member_height)

    self:SetSize(total_width, total_height)
    GroupLayout.apply_raid_group_positions(self.members, count, layout.mode, layout.spacing_x, layout.spacing_y,
        member_width, member_height)

    if self:is_move_mode() then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
    end
end

function RaidGroupVitalsWindow:update_visibility(active, visible_members)
    if _raid_group_windows_enabled() ~= true then
        self:SetVisible(false)
        return
    end
    if self:is_move_mode() then
        self:SetVisible(true)
        return
    end

    self:SetVisible(active == true and visible_members > 0)
end

function RaidGroupVitalsWindow:apply_settings()
    self:apply_native_scaling()
    self:apply_hud_position()

    for i = 1, #self.members do
        self.members[i]:resize()
    end

    self:update_members(self.current_members, self.current_leader_name, self.current_active)
end

function RaidGroupVitalsWindow:update_members(members, leader_name, active)
    self.current_members = members
    self.current_leader_name = leader_name
    self.current_active = active == true

    local ordered_members = members
    local move_mode = self:is_move_mode()
    local desired_count = #ordered_members
    if move_mode == true and desired_count < self:get_placeholder_count() then
        desired_count = self:get_placeholder_count()
    end

    self:ensure_member_windows(desired_count)

    local border_color = self:get_border_color()

    if move_mode == true then
        for i = 1, #self.members do
            local member_window = self.members[i]
            member_window.entity_control:SetMouseVisible(false)
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:set_frame_border_color_override(border_color)
            member_window:SetVisible(false)
        end

        self:layout_members(desired_count)
        self:update_visibility(active, #ordered_members)
        return
    end

    for i = 1, #self.members do
        local member_window = self.members[i]
        member_window.entity_control:SetMouseVisible(true)
        member_window:set_frame_border_color_override(border_color)

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
