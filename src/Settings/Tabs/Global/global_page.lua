import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local configure_compact_form = FeatureShell.configure_compact_form

GlobalPage = class(SettingsFeatureSectionPage)

function GlobalPage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window)

    local digits_help = table.concat({
        TR["How many digits are shown before shortening."],
        TR["3 digits: 999 -> 999, 1000 -> 1.0k, 1000000 -> 1.0M"],
        TR["4 digits: 9999 -> 9999, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local width_help = table.concat({
        TR["Maximum number of characters used by the shortened numeric part. The decimal point counts. Values are truncated, never rounded up."],
        TR["3 chars: 1000 -> 1.0k, 10000 -> 10k, 100000 -> 100k"],
        TR["4 chars: 1000 -> 1.0k, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local method_help = table.concat({
        TR["Which style is used for all shortened numbers."],
        TR["k / M / G: 2500000000 -> 2.5G"],
        TR["k / M / B: 2500000000 -> 2.5B"],
        TR["k / m / M: 2500000000 -> 2.5M"],
        TR["e3 / e6 / e9: 2500000000 -> 2.5e9"],
    }, "\n")

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_text("scale", TR["UI Scale"])
    general:add_checkbox("native_scaling", TR["Use native LotRO UI scaling"], true)
    general:add_text("refresh_rate", TR["Refresh rate of some UI elements (fps)"])
    general:add_checkbox("move_mode_shortcut", TR["Use LotRO move mode shortcut"])
    general:add_checkbox("bestiary_capture", TR["Enable bestiary capture (English client only)"], true)
    self:add_section(TR["General"], "general", general)

    local numbers = configure_compact_form(SettingsFormPage(window), 4, nil)
    numbers:add_checkbox("abbrev_enabled", TR["Shorten large numbers"])
    numbers:add_dropdown("abbrev_digits", TR["Digits Before Shortening"], numbers.abbrev_digits_labels,
        numbers.abbrev_digits_values, digits_help)
    numbers:add_dropdown("abbrev_width", TR["Max Shortened Width"], numbers.abbrev_width_labels,
        numbers.abbrev_width_values, width_help)
    numbers:add_dropdown("abbrev_method", TR["Shortening Style"], numbers.abbrev_method_labels,
        numbers.abbrev_method_values, method_help)
    self:add_section(TR["Numbers"], "numbers", numbers)
end

function GlobalPage:load(s)
    local controls = self.controls
    self.loading = true
    controls.scale.tb:SetText(tostring(s.global.scale))
    controls.native_scaling.cb:SetChecked(s.global.native_scaling == true)
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
    s.global.native_scaling = controls.native_scaling.cb:IsChecked() == true
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
