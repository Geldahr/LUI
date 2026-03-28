import "LUI.src.UI.Settings.Tabs.Party.party_page"

PartyTab = {
    key = "party",
    text = TR("Party"),
}

_G.LUI_SETTINGS_TABS = _G.LUI_SETTINGS_TABS or {}
_G.LUI_SETTINGS_TABS.party = PartyTab

function PartyTab.create_page(window)
    return PartyPage(window)
end

function PartyTab.load(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.party or nil
    if page ~= nil and page.load_pages ~= nil then
        page:load_pages(s, ui)
    end
end

function PartyTab.apply(window, s, ui)
    local page = window._tab_pages ~= nil and window._tab_pages.party or nil
    if page ~= nil and page.apply_pages ~= nil then
        page:apply_pages(s, ui)
    end
end
