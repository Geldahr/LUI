local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local DISPLAY_MODE_LABELS = {
    TR["List (Names)"],
    TR["Grid (Icons only)"],
}

local DISPLAY_MODE_VALUES = {
    "list",
    "grid",
}

local TravelPage = class(ConfigTabs)
Pages.TravelPage = TravelPage

function TravelPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox("travel_enabled", TR["Enabled"],
        function(value)
            self._settings.travel.enabled = value == true
        end,
        function()
            return self._settings.travel.enabled == true
        end)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    layout:add_dropdown("travel_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES,
        function(value)
            self._settings.travel.display_mode = value
        end,
        function()
            return self._settings.travel.display_mode
        end)
    layout.controls.travel_display_mode.visible_if = function()
        return self.controls.travel_enabled.cb:IsChecked() == true
    end
    self:add_tab(TR["Layout"], "layout", layout)
end

function TravelPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
