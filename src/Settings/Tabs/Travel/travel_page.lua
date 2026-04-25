import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local DISPLAY_MODE_LABELS = {
    TR["List (Names)"],
    TR["Grid (Icons only)"],
}

local DISPLAY_MODE_VALUES = {
    "list",
    "grid",
}

TravelPage = class(SettingsFormPage)

function TravelPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    self:add_title(TR["Travel"])

    self:add_hr()
    self:add_title(TR["General"])
    self:add_checkbox("travel_enabled", TR["Enabled"])

    self:add_hr()
    self:add_title(TR["Window"])
    self:add_dropdown("travel_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES)

    self.controls.travel_display_mode.visible_if = function()
        return self.controls.travel_enabled.cb:IsChecked() == true
    end
end

function TravelPage:load(travel)
    if travel == nil then
        return
    end

    self.loading = true
    self.controls.travel_enabled.cb:SetChecked(travel.enabled == true)
    self.controls.travel_display_mode:set_value(travel.display_mode)
    self.loading = false
end

function TravelPage:apply(travel)
    if travel == nil then
        return
    end

    travel.enabled = self.controls.travel_enabled.cb:IsChecked() == true
    travel.display_mode = self.controls.travel_display_mode:get_value()
end

function TravelPage:load_from_settings(s)
    self:load(s.travel)
end

function TravelPage:apply_to_settings(s)
    self:apply(s.travel)
end
