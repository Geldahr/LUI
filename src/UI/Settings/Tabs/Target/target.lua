import "LUI.src.UI.Settings.Tabs.Target.target_page"

TargetTab = {
    key = "target",
    text = TR("Target"),
}

_G.LUI_SETTINGS_TABS = _G.LUI_SETTINGS_TABS or {}
_G.LUI_SETTINGS_TABS.target = TargetTab

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
