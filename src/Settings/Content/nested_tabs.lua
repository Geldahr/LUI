import "LUI.src.Settings.Tabs.feature_shell"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local module_for_page = FeatureShell.module_for_page

ConfigNestedTabs = class(SettingsFeatureNestedPage)
_G.ConfigNestedTabs = ConfigNestedTabs
_G.LUI_SETTINGS_SHARED = _G.LUI_SETTINGS_SHARED or {}
_G.LUI_SETTINGS_SHARED.config_nested_tabs = ConfigNestedTabs

function ConfigNestedTabs:Constructor(window, tab_position, scale_factor, font_size)
    SettingsFeatureNestedPage.Constructor(self, window, tab_position, scale_factor, font_size)
end

function ConfigNestedTabs:add_tab(text, key, page)
    if type(key) ~= "string" then
        error("ConfigNestedTabs:add_tab is missing key")
    end
    if page == nil then
        error("ConfigNestedTabs:add_tab is missing page: " .. tostring(key))
    end

    return self:add_sub_page(text, module_for_page(key, page))
end

function ConfigNestedTabs:get_page(key)
    return self._sub_pages[key]
end

function ConfigNestedTabs:load()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:load()
    end
end

function ConfigNestedTabs:save()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page:save()
    end
end
