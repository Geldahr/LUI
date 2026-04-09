import "LUI.src.Settings.Tabs.Party.party_page"

PartyTab = {
    key = "party",
    text = TR["Party"],
}

function PartyTab.create_page(window)
    return PartyPage(window)
end

function PartyTab.load(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "party"
    end)
    if page ~= nil and page.load_from_settings ~= nil then
        page:load_from_settings(s, ui)
    end
end

function PartyTab.apply(window, s, ui)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "party"
    end)
    if page ~= nil and page.apply_to_settings ~= nil then
        page:apply_to_settings(s, ui)
    end
end
