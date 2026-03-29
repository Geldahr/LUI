import "LUI.src.Settings.Tabs.Self.self_page"

SelfTab = {
    key = "self",
    text = TR("Self"),
}

function SelfTab.create_page(window)
    return SelfPage(window)
end

function SelfTab.load(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "self"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s, ui)
    end
end

function SelfTab.apply(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "self"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s, ui)
    end
end
