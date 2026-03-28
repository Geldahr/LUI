import "LUI.src.UI.Settings.Tabs.Self.self_page"

SelfTab = {
    key = "self",
    text = TR("Self"),
}

_G.LUI_SETTINGS_TABS = _G.LUI_SETTINGS_TABS or {}
_G.LUI_SETTINGS_TABS.self = SelfTab

function SelfTab.create_page(window)
    return SelfPage(window)
end

function SelfTab.load(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.self or nil
    if page ~= nil and page.load_pages ~= nil then
        page:load_pages(s, ui)
    end
end

function SelfTab.apply(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.self or nil
    if page ~= nil and page.apply_pages ~= nil then
        page:apply_pages(s, ui)
    end
end
