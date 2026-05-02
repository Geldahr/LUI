import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local scaled_int = FeatureShell.scaled_int

local TILE_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Medium (40)"],
    TR["Large (48)"],
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

local VIEW_MODE_LABELS = {
    TR["Icons"],
    TR["Details"],
}

local VIEW_MODE_VALUES = {
    LUI_ENUMS.assets_view_mode.ICONS,
    LUI_ENUMS.assets_view_mode.DETAILS,
}

AssetsPage = class(ConfigTabs)

function AssetsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_bound_checkbox(TR["Enabled"], "assets_enabled",
        function(value)
            self._settings.assets.enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(self._settings.assets.enabled == true)
        end)
    general:add_bound_dropdown(TR["View"], "assets_view_mode", VIEW_MODE_LABELS, VIEW_MODE_VALUES,
        function(value)
            self._settings.assets.view_mode = value
        end,
        function(entry)
            entry:set_value(self._settings.assets.view_mode)
        end)
    self:add_tab(TR["General"], "general", general)

    local tiles = ConfigContent(window, 4)
    tiles:add_bound_dropdown(TR["Icons"], "assets_tile_icons", TILE_SIZE_LABELS, TILE_SIZE_VALUES,
        function(value)
            self._settings.assets.tile.icons = value
        end,
        function(entry)
            entry:set_value(self._settings.assets.tile.icons)
        end)
    tiles:add_bound_dropdown(TR["Details"], "assets_tile_details", TILE_SIZE_LABELS, TILE_SIZE_VALUES,
        function(value)
            self._settings.assets.tile.details = value
        end,
        function(entry)
            entry:set_value(self._settings.assets.tile.details)
        end)
    self:add_tab(TR["Tiles"], "tiles", tiles)
end

function AssetsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function AssetsPage:load_from_settings(s)
    self._settings = s
    self:load()
end

function AssetsPage:apply_to_settings(s)
    self._settings = s
    self:save()
end
