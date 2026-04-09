import "LUI.src.Settings.Tabs.Assets.assets_page"

AssetsTab = {
    key = "assets",
    text = TR["Assets"],
}

function AssetsTab.create_page(window)
    return AssetsPage(window)
end

function AssetsTab.load(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "assets"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s)
    end
end

function AssetsTab.apply(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "assets"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s)
    end
end
