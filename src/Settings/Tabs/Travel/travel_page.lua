local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local is_boss_target = _G.LUI.Utils.is_boss_target
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_format_timeout_seconds = _G.LUI.Utils.lui_format_timeout_seconds
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_timed_row_resolved_font_size = _G.LUI.Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_timed_row_min_item_width = _G.LUI.Utils.lui_timed_row_min_item_width
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_resolved_font_size = _G.LUI.Utils.lui_cooldown_resolved_font_size
local lui_cooldown_estimate_text_width = _G.LUI.Utils.lui_cooldown_estimate_text_width
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_cooldown_min_name_width = _G.LUI.Utils.lui_cooldown_min_name_width
local lui_cooldown_min_timed_bar_width = _G.LUI.Utils.lui_cooldown_min_timed_bar_width
local lui_cooldown_min_item_width = _G.LUI.Utils.lui_cooldown_min_item_width
local lui_clamp_ratio = _G.LUI.Utils.lui_clamp_ratio
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_lerp_number = _G.LUI.Utils.lui_lerp_number
local lui_lerp_color = _G.LUI.Utils.lui_lerp_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
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
