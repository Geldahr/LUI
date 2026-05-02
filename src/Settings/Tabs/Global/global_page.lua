import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local scaled_int = FeatureShell.scaled_int

GlobalPage = class(ConfigTabs)

function GlobalPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

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

    local general = ConfigContent(window, 4)
    general:add_line_edit("scale", TR["UI Scale"],
        function(value)
            local scale = tonumber(value)
            if scale ~= nil and scale > 0 then
                self._settings.global.scale = scale
            end
        end,
        function()
            return tostring(self._settings.global.scale)
        end)
    general:add_checkbox("native_scaling", TR["Use native LotRO UI scaling"],
        function(value)
            self._settings.global.native_scaling = value == true
        end,
        function()
            return self._settings.global.native_scaling == true
        end, true)
    general:add_row_break()
    general:add_line_edit("refresh_rate", TR["Refresh rate of some UI elements (fps)"],
        function(value)
            local refresh_rate = tonumber(value)
            if refresh_rate ~= nil and refresh_rate > 0 then
                self._settings.global.refresh_rate = refresh_rate
            end
        end,
        function()
            return tostring(self._settings.global.refresh_rate)
        end)
    general:add_checkbox("move_mode_shortcut", TR["Use LotRO move mode shortcut"],
        function(value)
            self._settings.global.move_mode_shortcut = value == true
        end,
        function()
            return self._settings.global.move_mode_shortcut == true
        end)
    general:add_row_break()
    general:add_checkbox("bestiary_capture", TR["Enable bestiary capture (English client only)"],
        function(value)
            if is_lui_english_language() == true then
                self._settings.global.bestiary_capture = value == true
            else
                self._settings.global.bestiary_capture = false
            end
        end,
        function()
            return is_lui_english_language() == true and self._settings.global.bestiary_capture == true
        end, true)
    general.controls.bestiary_capture.load_fn = function()
        local english_only = is_lui_english_language() == true
        general.controls.bestiary_capture.cb:SetEnabled(english_only == true)
        return english_only == true and self._settings.global.bestiary_capture == true
    end
    self:add_tab(TR["General"], "general", general)

    local numbers = ConfigContent(window, 4)
    numbers:add_checkbox("abbrev_enabled", TR["Shorten large numbers"],
        function(value)
            self._settings.global.number_abbrev.enabled = value == true
        end,
        function()
            return self._settings.global.number_abbrev.enabled == true
        end)
    numbers:add_row_break()
    numbers:add_dropdown("abbrev_digits", TR["Digits Before Shortening"], numbers.abbrev_digits_labels,
        numbers.abbrev_digits_values,
        function(value)
            self._settings.global.number_abbrev.digits = value
        end,
        function()
            return self._settings.global.number_abbrev.digits
        end, digits_help)
    numbers:add_dropdown("abbrev_width", TR["Max Shortened Width"], numbers.abbrev_width_labels,
        numbers.abbrev_width_values,
        function(value)
            self._settings.global.number_abbrev.width = value
        end,
        function()
            return self._settings.global.number_abbrev.width
        end, width_help)
    numbers:add_dropdown("abbrev_method", TR["Shortening Style"], numbers.abbrev_method_labels,
        numbers.abbrev_method_values,
        function(value)
            self._settings.global.number_abbrev.method = value
        end,
        function()
            return self._settings.global.number_abbrev.method
        end, method_help)
    self:add_tab(TR["Numbers"], "numbers", numbers)
end

function GlobalPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
