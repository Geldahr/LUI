import "LUI.src.Settings.Tabs.Target.target_page"

TargetTab = {
    key = "target",
    text = TR["Target"],
}

function TargetTab.create_page(window)
    return TargetPage(window)
end

function TargetTab.load(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "target"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s, ui)
    end
end

function TargetTab.apply(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "target"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s, ui)
    end
end
