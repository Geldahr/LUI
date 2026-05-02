import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local configure_compact_form = FeatureShell.configure_compact_form

local DISPLAY_MODE_LABELS = {
    TR["List (Names)"],
    TR["Grid (Icons only)"],
}

local DISPLAY_MODE_VALUES = {
    "list",
    "grid",
}

TravelPage = class(SettingsFeatureSectionPage)

function TravelPage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window, nil, nil, nil, false)

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("travel_enabled", TR["Enabled"])
    self:add_section(TR["General"], "general", general)

    local window_page = configure_compact_form(SettingsFormPage(window), 4, nil)
    window_page:add_dropdown("travel_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES)
    window_page.controls.travel_display_mode.visible_if = function()
        return self.controls.travel_enabled.cb:IsChecked() == true
    end
    self:add_section(TR["Window"], "window", window_page)
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
