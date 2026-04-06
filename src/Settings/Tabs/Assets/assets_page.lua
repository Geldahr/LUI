import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

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

AssetsPage = class(SettingsFormPage)

function AssetsPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    self:add_title(TR["Assets"])

    self:add_hr()
    self:add_title(TR["General"])
    self:add_checkbox("assets_enabled", TR["Enabled"])
    self:add_dropdown("assets_view_mode", TR["View"], VIEW_MODE_LABELS, VIEW_MODE_VALUES)

    self:add_hr()
    self:add_title(TR["Tiles"])
    self:add_dropdown("assets_tile_icons", TR["Icons"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    self:add_dropdown("assets_tile_details", TR["Details"], TILE_SIZE_LABELS, TILE_SIZE_VALUES)
end

function AssetsPage:load(assets)
    if assets == nil then
        return
    end

    self.loading = true
    self.controls.assets_enabled.cb:SetChecked(assets.enabled == true)
    self.controls.assets_view_mode:set_value(assets.view_mode)
    self.controls.assets_tile_icons:set_value(assets.tile.icons)
    self.controls.assets_tile_details:set_value(assets.tile.details)
    self.loading = false
end

function AssetsPage:apply(assets)
    if assets == nil then
        return
    end

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
