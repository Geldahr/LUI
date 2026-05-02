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

local VIEW_MODE_LABELS = {
    TR["Icons"],
    TR["Details"],
}

local VIEW_MODE_VALUES = {
    LUI_ENUMS.assets_view_mode.ICONS,
    LUI_ENUMS.assets_view_mode.DETAILS,
}

AssetsPage = class(SettingsTabbedPage)

function AssetsPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("assets_enabled", TR["Enabled"])
    general:add_dropdown("assets_view_mode", TR["View"], VIEW_MODE_LABELS, VIEW_MODE_VALUES)
    self:add_sub_page(TR["General"], module_for_page("general", general))

    local tiles = configure_compact_form(SettingsFormPage(window), 4, nil)
    tiles:add_dropdown("assets_tile_icons", TR["Icons"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    tiles:add_dropdown("assets_tile_details", TR["Details"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    self:add_sub_page(TR["Tiles"], module_for_page("tiles", tiles))
end

function AssetsPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function AssetsPage:load(assets)
    self.loading = true
    self.controls.assets_enabled.cb:SetChecked(assets.enabled == true)
    self.controls.assets_view_mode:set_value(assets.view_mode)
    self.controls.assets_tile_icons:set_value(assets.tile.icons)
    self.controls.assets_tile_details:set_value(assets.tile.details)
    self.loading = false
    self:layout()
end

function AssetsPage:apply(assets)
    assets.enabled = self.controls.assets_enabled.cb:IsChecked() == true
    assets.view_mode = self.controls.assets_view_mode:get_value()
    assets.tile.icons = self.controls.assets_tile_icons:get_value()
    assets.tile.details = self.controls.assets_tile_details:get_value()
end

function AssetsPage:load_from_settings(s)
    self:load(s.assets)
end

function AssetsPage:apply_to_settings(s)
    self:apply(s.assets)
end
