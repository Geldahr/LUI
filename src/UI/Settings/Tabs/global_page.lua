import "LUI.src.UI.Settings.Tabs.form_page"

GlobalPage = class(SettingsFormPage)

function GlobalPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

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
