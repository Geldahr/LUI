import "LUI.src.UI.Settings.Tabs.tabbed_page"
import "LUI.src.UI.Settings.Tabs.Party.party_layout"
import "LUI.src.UI.Settings.Tabs.Party.party_vitals"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

PartyPage = class(SettingsTabbedPage)

function PartyPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)

    self:add_sub_page(TR("Layout"), PartyLayout)
    self:add_sub_page(TR("Vitals"), PartyVitals)
end
