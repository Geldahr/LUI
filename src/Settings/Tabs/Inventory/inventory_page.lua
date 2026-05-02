import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local configure_compact_form = FeatureShell.configure_compact_form

local TILE_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Medium (40)"],
    TR["Large (48)"],
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

InventoryPage = class(SettingsFeatureSectionPage)

function InventoryPage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window, nil, nil, nil, false)

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("inventory_enabled", TR["Enabled"], true)
    general:add_checkbox("inventory_replace", TR["Replace default backpack (I)"], true)
    self:add_section(TR["General"], "general", general)

    local window_page = configure_compact_form(SettingsFormPage(window), 4, nil)
    window_page:add_text("inventory_cols", TR["Columns"])
    self:add_section(TR["Window"], "window", window_page)

    local tiles = configure_compact_form(SettingsFormPage(window), 4, nil)
    tiles:add_dropdown("inventory_tile_size", TR["Tile Size"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    self:add_section(TR["Tiles"], "tiles", tiles)
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
