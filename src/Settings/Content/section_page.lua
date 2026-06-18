local Content = _G.LUI.Settings.Content
local Tabs = _G.LUI.Settings.Tabs
local class = _G.LUI.Core.class
import "LUI.src.Settings.Tabs.feature_shell"

local FeatureShell = Tabs.SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class

local ConfigSectionPage = class(SettingsFeatureSectionPage)
Content.ConfigSectionPage = ConfigSectionPage

function ConfigSectionPage:Constructor(window, preview_key, preview_height, preview_refresh_fn, use_button_tabs)
    SettingsFeatureSectionPage.Constructor(self, window, preview_key, preview_height, preview_refresh_fn,
        use_button_tabs)
end

function ConfigSectionPage:add_tab(text, key, page)
    self:add_section(text, key, page)
end

function ConfigSectionPage:load()
    for i = 1, #self._section_order do
        local page = self._sections[self._section_order[i]]
        page:load()
    end
end

function ConfigSectionPage:save()
    for i = 1, #self._section_order do
        local page = self._sections[self._section_order[i]]
        page:save()
    end
end
