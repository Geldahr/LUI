import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.Party.party_layout"
import "LUI.src.Settings.Tabs.Party.party_vitals"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

PartyPage = class(SettingsTabbedPage)

function PartyPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false

    self:add_sub_page(TR("Layout"), PartyLayout)
    self:add_sub_page(TR("Vitals"), PartyVitals)
end

function PartyPage:load_from_settings(s, ui)
    self:load_pages(s, ui)
end

function PartyPage:apply_to_settings(s, ui)
    self:apply_pages(s, ui)
end
