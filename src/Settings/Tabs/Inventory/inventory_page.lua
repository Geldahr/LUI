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

InventoryPage = class(ConfigTabs)

function InventoryPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_bound_checkbox(TR["Enabled"], "inventory_enabled",
        function(value)
            self._settings.inventory.enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(self._settings.inventory.enabled == true)
        end, true)
    general:add_bound_checkbox(TR["Replace default backpack (I)"], "inventory_replace",
        function(value)
            self._settings.inventory.replace = value == true
        end,
        function(entry)
            entry.cb:SetChecked(self._settings.inventory.replace == true)
        end, true)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    layout:add_bound_line_edit(TR["Columns"], "inventory_cols",
        function(value)
            local cols = tonumber(value)
            if cols ~= nil then
                self._settings.inventory.cols = cols
            end
        end,
        function(entry)
            entry:set_value(tostring(self._settings.inventory.cols))
        end)
    layout:add_bound_dropdown(TR["Tile Size"], "inventory_tile_size", TILE_SIZE_LABELS, TILE_SIZE_VALUES,
        function(value)
            self._settings.inventory.tile_size = value
        end,
        function(entry)
            entry:set_value(self._settings.inventory.tile_size)
        end)
    self:add_tab(TR["Layout"], "layout", layout)
end

function InventoryPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
