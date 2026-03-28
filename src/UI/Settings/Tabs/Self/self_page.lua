import "LUI.src.UI.Settings.Tabs.tabbed_page"
import "LUI.src.UI.Settings.Tabs.Self.self_vitals"
import "LUI.src.UI.Settings.Tabs.Self.self_expiring_effects"
import "LUI.src.UI.Settings.Tabs.Self.cooldowns"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

SelfPage = class(SettingsTabbedPage)

function SelfPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)

    self:add_sub_page(TR("Vitals"), SelfVitals)
    self:add_sub_page(TR("Expiring Effects"), SelfExpiringEffects)
    self:add_sub_page(TR("Cooldowns"), Cooldowns)
end
