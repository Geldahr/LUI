import "LUI.src.UI.Settings.Tabs.Global.global_page"

Global = {
    key = "global",
    text = TR("Global"),
}

function Global.create_page(window)
    return GlobalPage(window)
end

function Global.load(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "global"
    end)
    if page == nil or page.load_from_settings == nil then
        return
    end
    page:load_from_settings(s)
end

function Global.apply(window, s)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "global"
    end)
    if page == nil or page.apply_to_settings == nil then
        return
    end
    page:apply_to_settings(s)
end
