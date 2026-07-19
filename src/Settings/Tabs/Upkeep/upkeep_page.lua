-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local Lore = _G.LUI.Data.Lore
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Style = UI.Widgets.Style
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Data.lore_db"
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local MAX_SLOTS = 12
local CELL_W = 68
local QS_SIZE = 36
local NAME_H = 12
local CLEAR_H = 15
local CELL_GAP = 6
local ROW_GAP = 8

-- even sides pair with even containers for exact pixel centering
local function _even_scaled(value)
    local out = scaled_int(value)
    if out % 2 ~= 0 then
        out = out - 1
    end
    return out
end

local function _slot_name_text(did_text)
    if type(did_text) ~= "string" or tonumber(did_text) == nil then
        return ""
    end
    local record = Lore.Skills.buffs_of(tonumber(did_text))
    if record == nil then
        return TR["Unknown skill"]
    end
    return record.name
end

-- The bound skill's icon image id: resolved from the trained skill by
-- localized name (same matching as the Upkeep bar), falling back to the
-- skill's first buff icon from the skills DB when the character has not
-- trained the skill.
local function _skill_icon_id(did)
    local record = Lore.Skills.buffs_of(did)
    if record == nil then
        return nil
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player ~= nil and player.GetTrainedSkills ~= nil then
        local list = player:GetTrainedSkills()
        if list ~= nil and list.GetCount ~= nil and list.GetItem ~= nil then
            for i = 1, (list:GetCount() or 0) do
                local skill = list:GetItem(i)
                if skill ~= nil and skill.GetSkillInfo ~= nil then
                    local info = skill:GetSkillInfo()
                    if info ~= nil and info.GetName ~= nil and info:GetName() == record.name and
                        info.GetIconImageID ~= nil then
                        return info:GetIconImageID()
                    end
                end
            end
        end
    end

    local effect = record.effects[1]
    if effect ~= nil then
        return effect.icon
    end
    return nil
end

-- The slot editor: one skill drop area per Upkeep slot, with the bound
-- skill's name and a clear button underneath. Bindings live in the editor
-- until Apply writes them back to settings (same transactional model as
-- every other control on the page).
local function _create_slots_editor(content, window, get_count)
    local entry = content:add_custom("upkeep_slots_editor", 150)
    entry._slots = {}
    entry._cells = {}

    for i = 1, MAX_SLOTS do
        local cell = {}

        cell.holder = Turbine.UI.Control()
        cell.holder:SetParent(entry.control)
        cell.holder:SetMouseVisible(false)
        cell.holder:SetVisible(false)

        -- a border ring marks the drop target; the bound skill's icon is
        -- drawn by our own image on top
        cell.frame = Turbine.UI.Control()
        cell.frame:SetParent(cell.holder)
        cell.frame:SetMouseVisible(false)
        cell.frame:SetBackColor(Style.CONTROL_BORDER)

        cell.frame_inner = Turbine.UI.Control()
        cell.frame_inner:SetParent(cell.frame)
        cell.frame_inner:SetMouseVisible(false)
        cell.frame_inner:SetBackColor(Style.BACKGROUND)

        -- a plain drop area, never a quickslot: the game hands the dragged
        -- shortcut to any control via DragDrop args, while quickslot
        -- socketing is blocked by client-side quickslot state for some
        -- players
        cell.drop = Turbine.UI.Control()
        cell.drop:SetParent(cell.holder)
        if cell.drop.SetAllowDrop ~= nil then
            cell.drop:SetAllowDrop(true)
        end

        cell.icon = UI.Widgets.Image()
        cell.icon:SetParent(cell.drop)

        cell.name = UI.Widgets.LuiLabel()
        cell.name:SetParent(cell.holder)
        cell.name:SetMouseVisible(false)
        cell.name:SetSelectable(false)
        cell.name:SetMultiline(false)
        cell.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        cell.name:SetFont(window.field_label_font)

        cell.clear = UI.Widgets.LuiButton()
        cell.clear:SetParent(cell.holder)
        cell.clear:set_scale(State.settings.global.scale)
        cell.clear:set_font(window.input_font)
        cell.clear:set_text(TR["Clear"])

        cell.drop.DragDrop = function(_, args)
            local info = args ~= nil and args.DragDropInfo or nil
            if info == nil or info.GetShortcut == nil then
                return
            end
            local shortcut = info:GetShortcut()
            local data = nil
            if shortcut ~= nil and shortcut.GetType ~= nil and
                shortcut:GetType() == Turbine.UI.Lotro.ShortcutType.Skill then
                data = shortcut:GetData()
            end
            if type(data) ~= "string" or tonumber(data) == nil then
                -- not a skill: ignore the drop, keep the stored binding
                return
            end

            entry._slots[i] = data
            entry:sync_cell(i)
        end

        cell.clear.Click = function()
            entry._slots[i] = ""
            entry:sync_cell(i)
        end

        entry._cells[i] = cell
    end

    function entry:sync_cell(index)
        local cell = self._cells[index]
        local did_text = self._slots[index]
        local icon_id = nil
        if type(did_text) == "string" and tonumber(did_text) ~= nil then
            icon_id = _skill_icon_id(tonumber(did_text))
        end
        if icon_id ~= nil then
            local qs = _even_scaled(QS_SIZE)
            cell.icon:set_icon(Turbine.UI.Graphic(icon_id), qs, qs)
        else
            cell.icon:set_icon(nil)
            cell.icon:SetVisible(false)
        end
        cell.name:SetText(_slot_name_text(did_text))
    end

    function entry:get_value()
        local out = {}
        local last = 0
        for i = 1, MAX_SLOTS do
            local did_text = self._slots[i]
            if type(did_text) ~= "string" then
                did_text = ""
            end
            out[i] = did_text
            if did_text ~= "" then
                last = i
            end
        end
        for i = MAX_SLOTS, last + 1, -1 do
            out[i] = nil
        end
        return out
    end

    function entry:set_value(value)
        for i = 1, MAX_SLOTS do
            local did_text = type(value) == "table" and value[i] or nil
            if type(did_text) ~= "string" then
                did_text = ""
            end
            self._slots[i] = did_text
            self:sync_cell(i)
        end
        self:layout_cells()
    end

    function entry:layout_cells()
        local count = get_count()
        local qs = _even_scaled(QS_SIZE)
        local cell_w = _even_scaled(CELL_W)
        local name_h = scaled_int(NAME_H)
        local clear_h = scaled_int(CLEAR_H)
        local gap = scaled_int(CELL_GAP)
        local row_gap = scaled_int(ROW_GAP)
        local pad = scaled_int(2)
        local border = scaled_int(Style.BORDER_WIDTH_THIN)
        local frame_size = qs + (2 * border)
        local cell_h = frame_size + pad + name_h + pad + clear_h

        local width = entry.control:GetWidth()
        local per_row = math.floor((width + gap) / (cell_w + gap))
        if per_row < 1 then
            per_row = 1
        end

        for i = 1, MAX_SLOTS do
            local cell = self._cells[i]
            if i <= count then
                local row = math.floor((i - 1) / per_row)
                local col = (i - 1) % per_row
                cell.holder:SetPosition(col * (cell_w + gap), row * (cell_h + row_gap))
                cell.holder:SetSize(cell_w, cell_h)

                local frame_x = math.floor((cell_w - frame_size) / 2)
                cell.frame:SetPosition(frame_x, 0)
                cell.frame:SetSize(frame_size, frame_size)
                cell.frame_inner:SetPosition(border, border)
                cell.frame_inner:SetSize(qs, qs)
                cell.drop:SetPosition(frame_x + border, border)
                cell.drop:SetSize(qs, qs)
                cell.icon:SetPosition(0, 0)
                cell.icon:set_size(qs, qs)
                cell.name:SetPosition(0, frame_size + pad)
                cell.name:SetSize(cell_w, name_h)
                cell.clear:SetPosition(frame_x + border, frame_size + pad + name_h + pad)
                cell.clear:SetSize(qs, clear_h)

                cell.holder:SetVisible(true)
            else
                cell.holder:SetVisible(false)
            end
        end

        local rows = math.ceil(count / per_row)
        local base_height = (rows * (QS_SIZE + (2 * Style.BORDER_WIDTH_THIN) + 2 + NAME_H + 2 + CLEAR_H)) + ((rows - 1) * ROW_GAP) + 4
        if base_height ~= self.base_height then
            self.base_height = base_height
            self.height = scaled_int(base_height)
            content:layout()
        end
    end

    entry.apply_ui_scale = function()
        for i = 1, MAX_SLOTS do
            local cell = entry._cells[i]
            cell.name:SetFont(window.field_label_font)
            cell.clear:set_scale(State.settings.global.scale)
            cell.clear:set_font(window.input_font)
        end
        entry:layout_cells()
    end

    entry.control.SizeChanged = function()
        entry:layout_cells()
    end

    return entry
end

local UpkeepPage = class(ConfigTabs)
Pages.UpkeepPage = UpkeepPage

function UpkeepPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self.controls = self.controls or {}

    local orientation_labels = { TR["Horizontal"], TR["Vertical"] }
    local orientation_values = { LUI_ENUMS.orientation.HORIZONTAL, LUI_ENUMS.orientation.VERTICAL }
    local time_format_labels = { TR["Auto precision"], TR["Whole seconds"] }
    local time_format_values = {
        LUI_ENUMS.cooldown_time_format.AUTO,
        LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
    }

    local settings_getter = function()
        return self._settings.self.upkeep
    end

    local general = ConfigContent(window, 4)
    general:add_checkbox("uk_enabled", TR["Enabled"],
        function(value)
            settings_getter().enabled = value == true
        end,
        function()
            return settings_getter().enabled == true
        end, true)
    general:add_row_break()
    general:add_dropdown("uk_orientation", TR["Orientation"], orientation_labels, orientation_values,
        function(value)
            settings_getter().orientation = value
        end,
        function()
            return settings_getter().orientation
        end)
    general:add_line_edit("uk_count", TR["Slots"],
        function(value)
            local count = tonumber(value)
            if count ~= nil then
                settings_getter().count = count
            end
        end,
        function()
            return tostring(settings_getter().count)
        end)
    general:add_line_edit("uk_icon_size", TR["Icon size (px)"],
        function(value)
            local icon_size = tonumber(value)
            if icon_size ~= nil then
                settings_getter().icon_size = icon_size
            end
        end,
        function()
            return tostring(settings_getter().icon_size)
        end)
    general:add_line_edit("uk_spacing", TR["Spacing (px)"],
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function()
            return tostring(settings_getter().spacing)
        end)
    general:add_row_break()
    general:add_checkbox("uk_auto_order", TR["Auto order by next activation"],
        function(value)
            settings_getter().auto_order = value == true
        end,
        function()
            return settings_getter().auto_order == true
        end)
    general:add_dropdown("uk_auto_order_anchor", TR["Next skill at"],
        { TR["Left/Top"], TR["Right/Bottom"] }, { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT },
        function(value)
            settings_getter().auto_order_anchor = value
        end,
        function()
            return settings_getter().auto_order_anchor
        end)
    self:add_tab(TR["General"], "general", general)

    local get_count = function()
        local entry = self.controls.uk_count
        local count = entry ~= nil and tonumber(entry:get_value()) or nil
        if count == nil and self._settings ~= nil then
            count = self._settings.self.upkeep.count
        end
        if count == nil then
            count = 1
        end
        count = math.floor(count + 0.5)
        if count < 1 then count = 1 end
        if count > MAX_SLOTS then count = MAX_SLOTS end
        return count
    end

    local skills = ConfigContent(window, 1)
    skills:add_info(
        TR["Drag and drop a skill icon from the game's Skills panel (or an action bar) into a slot below to bind it. Clear removes the binding."],
        34)
    local editor = _create_slots_editor(skills, window, get_count)
    skills:bind(editor,
        function(value)
            settings_getter().slots = value
        end,
        function()
            return settings_getter().slots
        end)
    self:add_tab(TR["Skills"], "skills", skills)

    -- slot-count edits reflow the editor live
    local count_entry = self.controls.uk_count
    local prev_count_changed = count_entry.on_changed
    count_entry.on_changed = function(value)
        if prev_count_changed ~= nil then
            prev_count_changed(value)
        end
        editor:layout_cells()
    end

    local active = ConfigContent(window, 4)
    active:add_checkbox("uk_show_time", TR["Display time"],
        function(value)
            settings_getter().show_time = value == true
        end,
        function()
            return settings_getter().show_time == true
        end)
    active:add_color_picker("uk_active_text_color", TR["Text color"],
        function(value)
            settings_getter().active_text_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().active_text_color)
        end)
    active:add_row_break()
    active:add_checkbox("uk_drain_enabled", TR["Drain overlay"],
        function(value)
            settings_getter().drain_enabled = value == true
        end,
        function()
            return settings_getter().drain_enabled == true
        end)
    active:add_color_picker("uk_drain_color", TR["Drain color"],
        function(value)
            settings_getter().drain_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().drain_color)
        end)
    active:add_line_edit("uk_drain_opacity", TR["Drain opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().drain_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().drain_opacity)
        end)
    self:add_tab(TR["Buff active"], "active", active)

    local cooldown = ConfigContent(window, 4)
    cooldown:add_checkbox("uk_cd_show_time", TR["Display time"],
        function(value)
            settings_getter().cd_show_time = value == true
        end,
        function()
            return settings_getter().cd_show_time == true
        end)
    cooldown:add_color_picker("uk_cooldown_text_color", TR["Text color"],
        function(value)
            settings_getter().cooldown_text_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().cooldown_text_color)
        end)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_shade", TR["Shaded"],
        function(value)
            settings_getter().cd_shade = value == true
        end,
        function()
            return settings_getter().cd_shade == true
        end)
    cooldown:add_color_picker("uk_cd_shade_color", TR["Shade color"],
        function(value)
            settings_getter().cd_shade_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().cd_shade_color)
        end)
    cooldown:add_line_edit("uk_cd_shade_opacity", TR["Shade opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().cd_shade_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().cd_shade_opacity)
        end)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_during_active", TR["Show cooldown while the buff is active"],
        function(value)
            settings_getter().cd_during_active = value == true
        end,
        function()
            return settings_getter().cd_during_active == true
        end, true)
    cooldown:add_row_break()
    cooldown:add_checkbox("uk_cd_transparent", TR["Transparent"],
        function(value)
            settings_getter().cd_transparent = value == true
        end,
        function()
            return settings_getter().cd_transparent == true
        end)
    cooldown:add_line_edit("uk_cd_transparent_opacity", TR["Icon opacity"],
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().cd_transparent_opacity = opacity
            end
        end,
        function()
            return tostring(settings_getter().cd_transparent_opacity)
        end)
    self:add_tab(TR["On cooldown"], "cooldown", cooldown)

    local text = ConfigContent(window, 4)
    text:add_dropdown("uk_font_name", TR["Font"], text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function()
            return settings_getter().font.name
        end)
    text:add_line_edit("uk_font_size", TR["Font size"],
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function()
            return tostring(settings_getter().font.size)
        end)
    text:add_dropdown("uk_font_style", TR["Font style"], text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function()
            return settings_getter().font.style
        end)
    text:add_color_picker("uk_font_outline_color", TR["Outline color"],
        function(value)
            settings_getter().font.outline_color = window._ui.hex_to_color(value)
        end,
        function()
            return window._ui.color_to_hex(settings_getter().font.outline_color)
        end)
    text:add_row_break()
    text:add_dropdown("uk_time_format", TR["Time format"], time_format_labels, time_format_values,
        function(value)
            settings_getter().time_format = value
        end,
        function()
            return settings_getter().time_format
        end)
    self:add_tab(TR["Text"], "text", text)

    self.controls.uk_font_outline_color.visible_if = function()
        return self.controls.uk_font_style:get_value() == LUI_ENUMS.font_style.OUTLINE
    end
    local prev_style_changed = self.controls.uk_font_style.on_changed
    self.controls.uk_font_style.on_changed = function(value)
        if prev_style_changed ~= nil then
            prev_style_changed(value)
        end
        text:layout()
    end
end

function UpkeepPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
