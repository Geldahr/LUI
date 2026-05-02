import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.Party.party_layout"
import "LUI.src.Settings.Tabs.Party.party_vitals"

local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs

PartyPage = class(ConfigTabs)

function PartyPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false

    self:add_tab(TR["Layout"], "layout", PartyLayout(window))
    self:add_tab(TR["Vitals"], "vitals", PartyVitals(window))
end

function PartyPage:load_from_settings(s, ui)
    self:get_page("layout"):load_from_settings(s, ui)
    self:get_page("vitals"):load_from_settings(s, ui)
end

function PartyPage:apply_to_settings(s, ui)
    self:get_page("layout"):apply_to_settings(s, ui)
    self:get_page("vitals"):apply_to_settings(s, ui)
end
