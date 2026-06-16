import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.Launcher.launcher_button_selector"

local FeatureShell = SettingsFeatureShell
local ConfigContent = ConfigContent
local ConfigTabs = ConfigTabs
local scaled_int = FeatureShell.scaled_int

local ORIENTATION_LABELS = { TR["Vertical"], TR["Horizontal"] }
local ORIENTATION_VALUES = { "vertical", "horizontal" }
local DIRECTION_LABELS = { TR["Auto"], TR["Up"], TR["Down"], TR["Left"], TR["Right"] }
local DIRECTION_VALUES = { "auto", "up", "down", "left", "right" }

local BUTTONS = {
    { key = "config", label = TR["Config"] },
    { key = "inventory", label = TR["Inventory"] },
    { key = "assets", label = TR["Assets"] },
    { key = "craft", label = TR["Crafting"] },
    { key = "travel", label = TR["Travel"] },
    { key = "bestiary", label = TR["Bestiary"] },
}

local function _direction_matches_orientation(orientation, direction)
    if direction == "auto" then
        return true
    end
    if orientation == "vertical" then
        return direction == "up" or direction == "down"
    end
    if orientation == "horizontal" then
        return direction == "left" or direction == "right"
    end
    return false
end

local function _normalize_direction(orientation, direction)
    if _direction_matches_orientation(orientation, direction) == true then
        return direction
    end
    return "auto"
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

LauncherPage = class(ConfigTabs)

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
