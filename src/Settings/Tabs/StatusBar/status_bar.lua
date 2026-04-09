import "LUI.src.Settings.Tabs.StatusBar.status_bar_page"

StatusBar = {
    key = "status_bar",
    text = TR["Status Bar"],
}

function StatusBar.refresh_layout_help(window)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    if page ~= nil and page.refresh_layout_help ~= nil then
        page:refresh_layout_help()
    end
end

function StatusBar.create_page(window)
    return StatusBarPage(window)
end

function StatusBar.load(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s)
    end
end

function StatusBar.apply(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s)
    end
end
