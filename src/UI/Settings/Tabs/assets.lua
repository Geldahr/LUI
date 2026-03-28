import "LUI.src.UI.Settings.Tabs.assets_page"

AssetsTab = {
    key = "assets",
    text = TR("Assets"),
}

function AssetsTab.create_page(window)
    return AssetsPage(window)
end

function AssetsTab.load(window, s)
    local page = window._tab_pages ~= nil and window._tab_pages.assets or nil
    if page ~= nil and page.load ~= nil then
        page:load(s.assets)
    end
end

function AssetsTab.apply(window, s)
    local page = window._tab_pages ~= nil and window._tab_pages.assets or nil
    if page ~= nil and page.apply ~= nil then
        page:apply(s.assets)
    end
end
