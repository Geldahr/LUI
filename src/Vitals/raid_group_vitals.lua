-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local GroupLayout = _G.LUI.Features.Vitals.GroupLayout
local RaidLayout = _G.LUI.Utils.RaidLayout
local TR = _G.LUI.Locale.TR
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local LUI_ENUMS = _G.LUI.Settings.Enums
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.raid_layout"
import "LUI.src.Vitals.group_layout"
import "LUI.src.Vitals.group_member_vitals"
import "LUI.src.Vitals.group_effects_area"

local function _raid_group_windows_enabled()
    return State.loaded_settings.raid.enabled == true and State.loaded_settings.raid.split_by_group == true
end

local function _set_border_visible(border, visible)
    border.top:SetVisible(visible)
    border.bottom:SetVisible(visible)
    border.left:SetVisible(visible)
    border.right:SetVisible(visible)
end

local function _apply_border(border, width, height, thickness, color)
    if thickness <= 0 or width <= 0 or height <= 0 then
        _set_border_visible(border, false)
        return
    end

    border.top:SetBackColor(color)
    border.bottom:SetBackColor(color)
    border.left:SetBackColor(color)
    border.right:SetBackColor(color)

    border.top:SetPosition(0, 0)
    border.top:SetSize(width, thickness)
    border.bottom:SetPosition(0, height - thickness)
    border.bottom:SetSize(width, thickness)
    border.left:SetPosition(0, 0)
    border.left:SetSize(thickness, height)
    border.right:SetPosition(width - thickness, 0)
    border.right:SetSize(thickness, height)
    _set_border_visible(border, true)
end

---@class RaidGroupVitalsWindow : UI.Widgets.LuiHUD
local RaidGroupVitalsWindow = class(UI.Widgets.LuiHUD)
Vitals.RaidGroupVitalsWindow = RaidGroupVitalsWindow

function RaidGroupVitalsWindow:Constructor(group_key, group_index)
    self.group_key = group_key
    self.group_index = group_index
    self.members = {}
    self.member_effects = {}
    self.current_members = {}
    self.current_leader_name = nil
    self.current_target_name = nil
    self.current_active = false
    self.current_enable_effects = false
    self.group_border = nil

    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "raid_group_" .. group_key .. "_vitals",
        title = TR["Raid Group "] .. string.upper(group_key),
    })

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetVisible(false)

    self.group_border = {
        top = Turbine.UI.Control(),
        bottom = Turbine.UI.Control(),
        left = Turbine.UI.Control(),
        right = Turbine.UI.Control(),
    }
    self.group_border.top:SetParent(self)
    self.group_border.bottom:SetParent(self)
    self.group_border.left:SetParent(self)
    self.group_border.right:SetParent(self)
    self.group_border.top:SetMouseVisible(false)
    self.group_border.bottom:SetMouseVisible(false)
    self.group_border.left:SetMouseVisible(false)
    self.group_border.right:SetMouseVisible(false)
    self.group_border.top:SetZOrder(30)
    self.group_border.bottom:SetZOrder(30)
    self.group_border.left:SetZOrder(30)
    self.group_border.right:SetZOrder(30)
    _set_border_visible(self.group_border, false)

    local vitals_settings = State.settings.raid
    local initial_height = GroupLayout.member_height(vitals_settings)
    self:SetSize(vitals_settings.frame.width, initial_height)
    self:layout_move_chrome()
    self:apply_hud_position()
end

function RaidGroupVitalsWindow:set_move_mode(enabled)
    if enabled == true and _raid_group_windows_enabled() == true then
        self:SetVisible(true)
    end

    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    self:update_members(self.current_members, self.current_leader_name, self.current_active, self.current_enable_effects)
end

function RaidGroupVitalsWindow:get_placeholder_count()
    return RaidLayout.group_size()
end

function RaidGroupVitalsWindow:ensure_member_windows(count)
    local vitals_settings = State.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)

    for i = #self.members + 1, count do
        local member_window = Vitals.GroupMemberVitals("raid", nil)
        member_window:SetParent(self)
        member_window:SetZOrder(10)
        member_window.entity_control:SetMouseVisible(not self:is_move_mode())
        member_window:SetVisible(false)
        table.insert(self.members, member_window)

        local effect_area = Vitals.GroupEffectsArea(member_width, vitals_settings.group_effects, member_height)
        effect_area:SetParent(self)
        effect_area:SetZOrder(9)
        effect_area:SetVisible(false)
        table.insert(self.member_effects, effect_area)
    end
end

function RaidGroupVitalsWindow:hide_member_effects()
    for i = 1, #self.member_effects do
        self.member_effects[i]:SetVisible(false)
    end
end

function RaidGroupVitalsWindow:get_border_color()
    return State.settings.raid.group_colors[self.group_key]
end

function RaidGroupVitalsWindow:effects_active()
    return self.current_enable_effects == true and not self:is_move_mode()
end

function RaidGroupVitalsWindow:layout_members(count)
    local vitals_settings = State.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    local layout = vitals_settings.layout
    local outer_border = vitals_settings.group_border_width

    if self:effects_active() == true then
        self:layout_members_with_effects(count, vitals_settings, member_width, member_height, outer_border)
    else
        self:hide_member_effects()
        local total_width, total_height = GroupLayout.compute_raid_group_size(count, layout.mode, layout.spacing_x,
            layout.spacing_y, member_width, member_height)

        self:SetSize(total_width + (2 * outer_border), total_height + (2 * outer_border))
        GroupLayout.apply_raid_group_positions(self.members, count, layout.mode, layout.spacing_x, layout.spacing_y,
            member_width, member_height)
        for i = 1, count do
            local member_window = self.members[i]
            local x, y = member_window:GetPosition()
            member_window:SetPosition(x + outer_border, y + outer_border)
        end
    end

    self:update_group_border(count)

    if self:is_move_mode() then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
    end
end

function RaidGroupVitalsWindow:layout_members_with_effects(count, vitals_settings, member_width, member_height,
                                                           outer_border)
    local layout = vitals_settings.layout
    local ge = vitals_settings.group_effects
    local shape_cells = RaidLayout.group_shape_cells(layout.mode)
    local dims = RaidLayout.group_shape_dimensions(layout.mode)
    local cols = dims.columns
    local rows = dims.rows

    local max_column = 0
    local max_row = 0
    for i = 1, count do
        local cell = shape_cells[i]
        local bar_x, bar_y, area_x, area_y, placement = GroupLayout.place_with_effects(cell.column, cell.row, cols, rows,
            ge.side, layout.spacing_x, layout.spacing_y, member_width, member_height)

        self.members[i]:SetPosition(bar_x + outer_border, bar_y + outer_border)

        local effect_area = self.member_effects[i]
        effect_area:SetPosition(area_x + outer_border, area_y + outer_border)
        if placement == "left" then
            effect_area:set_horizontal_alignment(LUI_ENUMS.side.RIGHT)
        else
            effect_area:set_horizontal_alignment(LUI_ENUMS.side.LEFT)
        end

        if cell.column > max_column then
            max_column = cell.column
        end
        if cell.row > max_row then
            max_row = cell.row
        end
    end

    local total_width, total_height = GroupLayout.effect_grid_size(max_column, max_row, cols, rows, layout.spacing_x,
        layout.spacing_y, member_width, member_height)
    self:SetSize(total_width + (2 * outer_border), total_height + (2 * outer_border))
end

function RaidGroupVitalsWindow:update_group_border(count)
    if self:is_move_mode() == true or count <= 0 then
        _set_border_visible(self.group_border, false)
        return
    end

    local border_width = State.settings.raid.group_border_width
    local width, height = self:GetSize()
    _apply_border(self.group_border, width, height, border_width, self:get_border_color())
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

    local vitals_settings = State.settings.raid
    local member_width = vitals_settings.frame.width
    local member_height = GroupLayout.member_height(vitals_settings)
    for i = 1, #self.members do
        self.members[i]:resize()
        -- Drop the area assignment so update_members re-subscribes with the
        -- refreshed filter/icon settings and replays current effects.
        self.members[i]:set_effect_area(nil)
        self.member_effects[i]:apply_bar_settings(member_width, vitals_settings.group_effects, member_height)
    end

    self:update_members(self.current_members, self.current_leader_name, self.current_active, self.current_enable_effects)
end

function RaidGroupVitalsWindow:destroy()
    for i = 1, #self.members do
        self.members[i]:set_effect_area(nil)
    end
    self:SetVisible(false)
end

function RaidGroupVitalsWindow:set_target_name(target_name)
    self.current_target_name = target_name
    self:update_target_highlight()
end

function RaidGroupVitalsWindow:update_target_highlight()
    for i = 1, #self.members do
        self.members[i]:set_target_name(self.current_target_name)
    end
end

function RaidGroupVitalsWindow:update_members(members, leader_name, active, enable_effects)
    self.current_members = members
    self.current_leader_name = leader_name
    self.current_active = active == true
    self.current_enable_effects = enable_effects == true

    local ordered_members = members
    local move_mode = self:is_move_mode()
    local desired_count = #ordered_members
    if move_mode == true and desired_count < self:get_placeholder_count() then
        desired_count = self:get_placeholder_count()
    end

    self:ensure_member_windows(desired_count)

    if move_mode == true then
        for i = 1, #self.members do
            local member_window = self.members[i]
            member_window.entity_control:SetMouseVisible(false)
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:set_frame_border_color_override(nil)
            member_window:set_effect_area(nil)
            member_window:SetVisible(false)
            self.member_effects[i]:SetVisible(false)
        end

        self:layout_members(desired_count)
        self:update_target_highlight()
        self:update_visibility(active, #ordered_members)
        return
    end

    local effects_on = self:effects_active()
    for i = 1, #self.members do
        local member_window = self.members[i]
        local effect_area = self.member_effects[i]
        member_window.entity_control:SetMouseVisible(true)
        member_window:set_frame_border_color_override(nil)

        if i <= #ordered_members then
            local entity = ordered_members[i]
            member_window:set_entity(entity)
            member_window:set_is_leader(leader_name ~= nil and entity:GetName() == leader_name)
            member_window:SetVisible(true)
            if effects_on == true then
                member_window:set_effect_area(effect_area)
                effect_area:SetVisible(true)
            else
                member_window:set_effect_area(nil)
                effect_area:SetVisible(false)
            end
        else
            member_window:set_entity(nil)
            member_window:set_is_leader(false)
            member_window:set_effect_area(nil)
            member_window:SetVisible(false)
            effect_area:SetVisible(false)
        end
    end

    self:layout_members(desired_count)
    self:update_target_highlight()
    self:update_visibility(active, #ordered_members)
end
