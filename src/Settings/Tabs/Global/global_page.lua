import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

GlobalPage = class(SettingsFormPage)

function GlobalPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    local digits_help = table.concat({
        TR("How many digits are shown before shortening."),
        TR("3 digits: 999 -> 999, 1000 -> 1.0k, 1000000 -> 1.0M"),
        TR("4 digits: 9999 -> 9999, 10000 -> 10.0k, 1000000 -> 1000k"),
    }, "\n")
    local width_help = table.concat({
        TR("Maximum number of characters used by the shortened numeric part. The decimal point counts. Values are truncated, never rounded up."),
        TR("3 chars: 1000 -> 1.0k, 10000 -> 10k, 100000 -> 100k"),
        TR("4 chars: 1000 -> 1.0k, 10000 -> 10.0k, 1000000 -> 1000k"),
    }, "\n")
    local method_help = table.concat({
        TR("Which style is used for all shortened numbers."),
        TR("k / M / G: 2500000000 -> 2.5G"),
        TR("k / M / B: 2500000000 -> 2.5B"),
        TR("k / m / M: 2500000000 -> 2.5M"),
        TR("e3 / e6 / e9: 2500000000 -> 2.5e9"),
    }, "\n")

    self:add_title(TR("Global"))
    self:add_break()
    self:add_text("scale", TR("UI Scale"))
    self:add_text("refresh_rate", TR("Refresh rate of some UI elements (fps)"))
    self:add_checkbox("move_mode_shortcut", TR("Use LotRO move mode shortcut"))
    self:add_checkbox("bestiary_capture", TR("Enable bestiary capture (English client only)"), true)

    self:add_hr()
    self:add_title(TR("Numbers"))
    self:add_checkbox("abbrev_enabled", TR("Shorten large numbers"))
    self:add_dropdown("abbrev_digits", TR("Digits Before Shortening"), self.abbrev_digits_labels,
        self.abbrev_digits_values, digits_help)
    self:add_dropdown("abbrev_width", TR("Max Shortened Width"), self.abbrev_width_labels, self.abbrev_width_values,
        width_help)
    self:add_dropdown("abbrev_method", TR("Shortening Style"), self.abbrev_method_labels, self.abbrev_method_values,
        method_help)
end

function GlobalPage:load(s)
    local controls = self.controls
    self.loading = true
    controls.scale.tb:SetText(tostring(s.global.scale))
    controls.refresh_rate.tb:SetText(tostring(s.global.refresh_rate))

    local abbrev = s.global.number_abbrev
    controls.move_mode_shortcut.cb:SetChecked(s.global.move_mode_shortcut == true)
    local english_only = is_lui_english_language == nil or is_lui_english_language() == true
    controls.bestiary_capture.cb:SetChecked(english_only == true and s.global.bestiary_capture == true)
    if controls.bestiary_capture.cb.SetEnabled ~= nil then
        controls.bestiary_capture.cb:SetEnabled(english_only == true)
    end
    controls.abbrev_enabled.cb:SetChecked(abbrev.enabled == true)
    controls.abbrev_digits:set_value(abbrev.digits)
    controls.abbrev_width:set_value(abbrev.width)
    controls.abbrev_method:set_value(abbrev.method)
    self.loading = false
    self:layout()
end

function GlobalPage:apply(s)
    local controls = self.controls
    local scale = tonumber(controls.scale.tb:GetText())
    if scale ~= nil and scale > 0 then
        s.global.scale = scale
    end
    local refresh_rate = tonumber(controls.refresh_rate.tb:GetText())
    if refresh_rate ~= nil and refresh_rate > 0 then
        s.global.refresh_rate = refresh_rate
    end

    s.global.move_mode_shortcut = controls.move_mode_shortcut.cb:IsChecked() == true
    if is_lui_english_language == nil or is_lui_english_language() == true then
        s.global.bestiary_capture = controls.bestiary_capture.cb:IsChecked() == true
    else
        s.global.bestiary_capture = false
    end
    s.global.number_abbrev.enabled = controls.abbrev_enabled.cb:IsChecked()
    s.global.number_abbrev.digits = controls.abbrev_digits:get_value()
    s.global.number_abbrev.width = controls.abbrev_width:get_value()
    s.global.number_abbrev.method = controls.abbrev_method:get_value()
end

function GlobalPage:load_from_settings(s)
    self:load(s)
end

function GlobalPage:apply_to_settings(s)
    self:apply(s)
end
