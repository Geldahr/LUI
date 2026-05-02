import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local configure_compact_form = FeatureShell.configure_compact_form
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int

local DISPLAY_MODE_LABELS = {
    TR["List (Names)"],
    TR["Grid (Icons only)"],
}

local DISPLAY_MODE_VALUES = {
    "list",
    "grid",
}

TravelPage = class(SettingsTabbedPage)

function TravelPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("travel_enabled", TR["Enabled"])
    self:add_sub_page(TR["General"], module_for_page("general", general))

    local layout = configure_compact_form(SettingsFormPage(window), 4, nil)
    layout:add_dropdown("travel_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES)
    layout.controls.travel_display_mode.visible_if = function()
        return self.controls.travel_enabled.cb:IsChecked() == true
    end
    self:add_sub_page(TR["Layout"], module_for_page("layout", layout))
end

function TravelPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function TravelPage:load(travel)
    self.loading = true
    self.controls.travel_enabled.cb:SetChecked(travel.enabled == true)
    self.controls.travel_display_mode:set_value(travel.display_mode)
    self.loading = false
    self:layout()
end

function TravelPage:apply(travel)
    travel.enabled = self.controls.travel_enabled.cb:IsChecked() == true
    travel.display_mode = self.controls.travel_display_mode:get_value()
end

function TravelPage:load_from_settings(s)
    self:load(s.travel)
end

function TravelPage:apply_to_settings(s)
    self:apply(s.travel)
end
