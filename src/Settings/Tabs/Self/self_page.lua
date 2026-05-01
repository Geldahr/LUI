import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.Self.self_expiring_effects"
import "LUI.src.Settings.Tabs.Self.cooldowns"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

SelfPage = class(SettingsTabbedPage)

function SelfPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false

    self:add_sub_page(TR["Expiring Effects"], SelfExpiringEffects)
    self:add_sub_page(TR["Cooldowns"], Cooldowns)
end

function SelfPage:load_from_settings(s, ui)
    self:load_pages(s, ui)
end

function SelfPage:apply_to_settings(s, ui)
    self:apply_pages(s, ui)
end
