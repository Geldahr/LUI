-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
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
    general:add_row_break()
    self.bag_order_entry = general:add_button("inventory_bag_order_guide", TR["Open the bag order guide"],
        function()
            UI.Shortcuts.open_bag_order_guide()
        end,
        TR["Guides you step by step to put the rows of the game's bags back in slot order. Needs the LUI inventory (enable it and Apply first)."])
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    layout:add_dropdown("inventory_tile_size", TR["Tile Size"], TILE_SIZE_LABELS, TILE_SIZE_VALUES,
        function(value)
            self._settings.inventory.tile_size = value
        end,
        function()
            return self._settings.inventory.tile_size
        end)
    self:add_tab(TR["Layout"], "layout", layout)
end

-- the guide's marker moves run in the LUI inventory window
function InventoryPage:load()
    ConfigTabs.load(self)
    self.bag_order_entry.button:set_enabled(Windows.inventory ~= nil)
end

function InventoryPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
