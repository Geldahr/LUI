import "LUI.src.Settings.Tabs.feature_shell"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class

ConfigSectionPage = class(SettingsFeatureSectionPage)
_G.ConfigSectionPage = ConfigSectionPage
_G.LUI_SETTINGS_SHARED = _G.LUI_SETTINGS_SHARED or {}
_G.LUI_SETTINGS_SHARED.config_section_page = ConfigSectionPage

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
