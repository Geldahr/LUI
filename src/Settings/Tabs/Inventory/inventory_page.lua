import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local configure_compact_form = FeatureShell.configure_compact_form
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int

local TILE_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Medium (40)"],
    TR["Large (48)"],
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

InventoryPage = class(SettingsTabbedPage)

function InventoryPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("inventory_enabled", TR["Enabled"], true)
    general:add_checkbox("inventory_replace", TR["Replace default backpack (I)"], true)
    self:add_sub_page(TR["General"], module_for_page("general", general))

    local layout = configure_compact_form(SettingsFormPage(window), 4, nil)
    layout:add_text("inventory_cols", TR["Columns"])
    layout:add_dropdown("inventory_tile_size", TR["Tile Size"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    self:add_sub_page(TR["Layout"], module_for_page("layout", layout))
end

function InventoryPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function InventoryPage:load(inv)
    self.loading = true
    self.controls.inventory_enabled.cb:SetChecked(inv.enabled == true)
    self.controls.inventory_replace.cb:SetChecked(inv.replace == true)
    self.controls.inventory_cols.tb:SetText(tostring(inv.cols))
    self.controls.inventory_tile_size:set_value(inv.tile_size)
    self.loading = false
    self:layout()
end

function InventoryPage:apply(inv)
    inv.enabled = self.controls.inventory_enabled.cb:IsChecked() == true
    inv.replace = self.controls.inventory_replace.cb:IsChecked() == true

    local cols = tonumber(self.controls.inventory_cols.tb:GetText())
    if cols ~= nil then
        inv.cols = cols
    end

    inv.tile_size = self.controls.inventory_tile_size:get_value()
end

function InventoryPage:load_from_settings(s)
    self:load(s.inventory)
end

function InventoryPage:apply_to_settings(s)
    self:apply(s.inventory)
end
