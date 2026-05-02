import "LUI.src.Settings.Tabs.tabbed_page"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage

local function _module_for_page(key, page)
    return {
        key = key,
        create_page = function()
            return page
        end,
    }
end

ConfigTabs = class(SettingsTabbedPage)
_G.ConfigTabs = ConfigTabs
_G.LUI_SETTINGS_SHARED = _G.LUI_SETTINGS_SHARED or {}
_G.LUI_SETTINGS_SHARED.config_tabs = ConfigTabs

function ConfigTabs:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
end

function ConfigTabs:add_tab(text, key, page)
    if type(key) ~= "string" then
        error("ConfigTabs:add_tab is missing key")
    end
    if page == nil then
        error("ConfigTabs:add_tab is missing page: " .. tostring(key))
    end

    return self:add_sub_page(text, _module_for_page(key, page))
end

function ConfigTabs:get_page(key)
    return self._sub_pages[key]
end

function ConfigTabs:load()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        if page.load ~= nil then
            page:load()
        end
    end
end

function ConfigTabs:save()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        if page.save ~= nil then
            page:save()
        end
    end
end
