import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.Target.expiring_target_effects"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

TargetPage = class(SettingsTabbedPage)

function TargetPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false

    self:add_sub_page(TR["Expiring Effects"], ExpiringTargetEffects)
end

function TargetPage:load_from_settings(s, ui)
    self:load_pages(s, ui)
end

function TargetPage:apply_to_settings(s, ui)
    self:apply_pages(s, ui)
end
