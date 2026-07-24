-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.Launcher.launcher_button_selector"

local CreateLauncherButtonSelector = _G.LUI.Settings.Controls.CreateLauncherButtonSelector
local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local ORIENTATION_LABELS = { TR["Vertical"], TR["Horizontal"] }
local ORIENTATION_VALUES = { "vertical", "horizontal" }
local DIRECTION_LABELS = { TR["Up"], TR["Down"], TR["Left"], TR["Right"] }
local DIRECTION_VALUES = { "up", "down", "left", "right" }

local BUTTONS = {
    { key = "config", label = TR["Config"] },
    { key = "inventory", label = TR["Inventory"] },
    { key = "assets", label = TR["Assets"] },
    { key = "craft", label = TR["Crafting"] },
    { key = "travel", label = TR["Travel"] },
    { key = "encyclopedia", label = TR["Encyclopedia"] },
    { key = "raid", label = TR["Raid Manager"] },
}

local function _normalize_direction(orientation, direction)
    if orientation == "vertical" then
        if direction == "up" or direction == "down" then
            return direction
        end
        return "down"
    end
    if orientation == "horizontal" then
        if direction == "left" or direction == "right" then
            return direction
        end
        return "right"
    end
    error("Invalid launcher orientation: " .. tostring(orientation))
end

local function _clamp_icon_size(value)
    local size = tonumber(value)
    if size == nil then
        return nil
    end
    if size < 16 then
        return 16
    end
    if size > 128 then
        return 128
    end
    return size
end

local LauncherPage = class(ConfigTabs)
Pages.LauncherPage = LauncherPage

function LauncherPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox("launcher_enabled", TR["Enabled"],
        function(value)
            self._settings.launcher.enabled = value == true
        end,
        function()
            return self._settings.launcher.enabled == true
        end, true)
    general:add_checkbox("launcher_collapse_after_click", TR["Collapse after shortcut click"],
        function(value)
            self._settings.launcher.collapse_after_click = value == true
        end,
        function()
            return self._settings.launcher.collapse_after_click == true
        end, true)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    layout:add_line_edit("launcher_icon_size", TR["Icon size (16..128)"],
        function(value)
            local size = _clamp_icon_size(value)
            if size ~= nil then
                self._settings.launcher.icon_size = size
            end
        end,
        function()
            local size = _clamp_icon_size(self._settings.launcher.icon_size)
            if size == nil then
                error("Invalid launcher icon size setting")
            end
            return tostring(size)
        end)
    layout:add_line_edit("launcher_spacing", TR["Spacing"],
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                self._settings.launcher.spacing = spacing
            end
        end,
        function()
            return tostring(self._settings.launcher.spacing)
        end)
    layout:add_dropdown("launcher_orientation", TR["Orientation"], ORIENTATION_LABELS, ORIENTATION_VALUES,
        function(value)
            self._settings.launcher.orientation = value
            self._settings.launcher.direction = _normalize_direction(value, self._settings.launcher.direction)
        end,
        function()
            return self._settings.launcher.orientation
        end)
    layout:add_dropdown("launcher_direction", TR["Direction"], DIRECTION_LABELS, DIRECTION_VALUES,
        function(value)
            self._settings.launcher.direction = _normalize_direction(self._settings.launcher.orientation, value)
        end,
        function()
            return self._settings.launcher.direction
        end)
    self:add_tab(TR["Layout"], "layout", layout)

    local buttons = ConfigContent(window, 4)
    local launcher_page = self
    CreateLauncherButtonSelector(buttons, "launcher_buttons", BUTTONS)
    local buttons_entry = buttons.controls.launcher_buttons
    local buttons_load = buttons.load
    local buttons_save = buttons.save
    function buttons:load()
        buttons_load(self)
        buttons_entry:set_items(launcher_page._settings.launcher.buttons)
    end
    function buttons:save()
        buttons_save(self)
        launcher_page._settings.launcher.buttons = buttons_entry:get_items()
    end
    self:add_tab(TR["Buttons"], "buttons", buttons)
end

function LauncherPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
