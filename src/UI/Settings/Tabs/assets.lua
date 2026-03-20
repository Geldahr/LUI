AssetsTab = {
    key = "assets",
    text = TR("Assets"),
}

local TILE_SIZE_LABELS = {
    TR("Small (32)"),
    TR("Medium (40)"),
    TR("Large (48)"),
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

local VIEW_MODE_LABELS = {
    TR("Icons"),
    TR("Details"),
}

local VIEW_MODE_VALUES = {
    LUI_ENUMS.assets_view_mode.ICONS,
    LUI_ENUMS.assets_view_mode.DETAILS,
}

function AssetsTab.create_controls(window, ui)
    ui.add_checkbox("assets_enabled", TR("Enabled"))
    ui.add_dropdown("assets_view_mode", TR("View"), VIEW_MODE_LABELS, VIEW_MODE_VALUES)
    ui.add_dropdown("assets_tile_icons", TR("Icons"), TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    ui.add_dropdown("assets_tile_details", TR("Details"), TILE_SIZE_LABELS, TILE_SIZE_VALUES)
end

function AssetsTab.register(window, ui)
    return {
        ui.add_title(TR("Assets")),

        ui.add_hr(),
        ui.add_title(TR("General")),
        window.controls.assets_enabled,
        window.controls.assets_view_mode,

        ui.add_hr(),
        ui.add_title(TR("Tiles")),
        window.controls.assets_tile_icons,
        window.controls.assets_tile_details,
    }
end

function AssetsTab.load(window, s)
    local assets = s.assets
    window.controls.assets_enabled.cb:SetChecked(assets.enabled == true)
    window.controls.assets_view_mode:set_value(assets.view_mode)
    window.controls.assets_tile_icons:set_value(assets.tile.icons)
    window.controls.assets_tile_details:set_value(assets.tile.details)
end

function AssetsTab.apply(window, s)
    local assets = s.assets
    assets.enabled = window.controls.assets_enabled.cb:IsChecked() == true
    assets.view_mode = window.controls.assets_view_mode:get_value()
    assets.tile.icons = window.controls.assets_tile_icons:get_value()
    assets.tile.details = window.controls.assets_tile_details:get_value()
end
