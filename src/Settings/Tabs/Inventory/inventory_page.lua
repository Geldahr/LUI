local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int

local TILE_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Medium (40)"],
    TR["Large (48)"],
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

local InventoryPage = class(ConfigTabs)
Pages.InventoryPage = InventoryPage

function InventoryPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox("inventory_enabled", TR["Enabled"],
        function(value)
            self._settings.inventory.enabled = value == true
        end,
        function()
            return self._settings.inventory.enabled == true
        end, true)
    general:add_checkbox("inventory_replace", TR["Replace default backpack (I)"],
        function(value)
            self._settings.inventory.replace = value == true
        end,
        function()
            return self._settings.inventory.replace == true
        end, true)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    layout:add_line_edit("inventory_cols", TR["Columns"],
        function(value)
            local cols = tonumber(value)
            if cols ~= nil then
                self._settings.inventory.cols = cols
            end
        end,
        function()
            return tostring(self._settings.inventory.cols)
        end)
    layout:add_dropdown("inventory_tile_size", TR["Tile Size"], TILE_SIZE_LABELS, TILE_SIZE_VALUES,
        function(value)
            self._settings.inventory.tile_size = value
        end,
        function()
            return self._settings.inventory.tile_size
        end)
    self:add_tab(TR["Layout"], "layout", layout)
end

function InventoryPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
