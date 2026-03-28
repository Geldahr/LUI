import "LUI.src.UI.Settings.Tabs.Target.target_page"

TargetTab = {
    key = "target",
    text = TR("Target"),
}

function TargetTab.create_page(window)
    return TargetPage(window)
end

function TargetTab.load(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.target or nil
    if page ~= nil and page.load_pages ~= nil then
        page:load_pages(s, ui)
    end
end

function TargetTab.apply(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.target or nil
    if page ~= nil and page.apply_pages ~= nil then
        page:apply_pages(s, ui)
    end
end
