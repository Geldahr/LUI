import "LUI.src.UI.Settings.Tabs.Inventory.inventory_page"

Inventory = {
    key = "inventory",
    text = TR("Inventory"),
}

function Inventory.create_page(window)
    return InventoryPage(window)
end

function Inventory.load(window, s)
    local page = window._tab_pages ~= nil and window._tab_pages.inventory or nil
    if page ~= nil and page.load ~= nil then
        page:load(s.inventory)
    end
end

function Inventory.apply(window, s)
    local page = window._tab_pages ~= nil and window._tab_pages.inventory or nil
    if page ~= nil and page.apply ~= nil then
        page:apply(s.inventory)
    end
end
