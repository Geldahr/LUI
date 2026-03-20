Inventory = {
    key = "inventory",
    text = TR("Inventory"),
}

local TILE_SIZE_LABELS = {
    TR("Small (32)"),
    TR("Medium (40)"),
    TR("Large (48)"),
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

function Inventory.create_controls(window, ui)
    ui.add_checkbox("inv_enabled", TR("Enabled"))
    ui.add_checkbox("inv_replace", TR("Replace default backpack (I)"))
    ui.add_text("inv_cols", TR("Columns"))
    ui.add_dropdown("inv_tile_size", TR("Tile Size"), TILE_SIZE_LABELS, TILE_SIZE_VALUES)
end

function Inventory.register(window, ui)
    return {
        ui.add_title(TR("Inventory")),

        ui.add_hr(),
        ui.add_title(TR("General")),
        window.controls.inv_enabled,
        window.controls.inv_replace,

        ui.add_hr(),
        ui.add_title(TR("Window")),
        window.controls.inv_cols,

        ui.add_hr(),
        ui.add_title(TR("Tiles")),
        window.controls.inv_tile_size,
    }
end

function Inventory.load(window, s)
    local inv = s.inventory
    window.controls.inv_enabled.cb:SetChecked(inv.enabled == true)
    window.controls.inv_replace.cb:SetChecked(inv.replace == true)
    window.controls.inv_cols.tb:SetText(tostring(inv.cols))
    window.controls.inv_tile_size:set_value(inv.tile_size)
end

function Inventory.apply(window, s)
    local inv = s.inventory
    inv.enabled = window.controls.inv_enabled.cb:IsChecked() == true
    inv.replace = window.controls.inv_replace.cb:IsChecked() == true

    local cols = tonumber(window.controls.inv_cols.tb:GetText())
    if cols ~= nil then inv.cols = cols end

    inv.tile_size = window.controls.inv_tile_size:get_value()
end
