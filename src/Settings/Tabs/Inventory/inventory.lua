import "LUI.src.Settings.Tabs.Inventory.inventory_page"

Inventory = {
    key = "inventory",
    text = TR["Inventory"],
}

function Inventory.create_page(window)
    return InventoryPage(window)
end

function Inventory.load(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "inventory"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s)
    end
end

function Inventory.apply(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "inventory"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s)
    end
end
