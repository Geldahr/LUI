import "LUI.src.UI.Settings.Tabs.StatusBar.status_bar_page"

StatusBar = {
    key = "status_bar",
    text = TR("Status Bar"),
}

_G.LUI_SETTINGS_TABS = _G.LUI_SETTINGS_TABS or {}
_G.LUI_SETTINGS_TABS.status_bar = StatusBar

local function _status_bar_page(window)
    return window ~= nil and window._tab_pages ~= nil and window._tab_pages.status_bar or nil
end

function StatusBar.refresh_layout_help(window)
    local page = _status_bar_page(window)
    if page ~= nil and page.refresh_layout_help ~= nil then
        page:refresh_layout_help()
    end
end

function StatusBar.create_page(window)
    return StatusBarPage(window)
end

function StatusBar.load(window, s)
    local page = _status_bar_page(window)
    if page ~= nil and page.load ~= nil then
        page:load(s.status_bar)
    end
end

function StatusBar.apply(window, s)
    local page = _status_bar_page(window)
    if page ~= nil and page.apply ~= nil then
        page:apply(s.status_bar)
    end
end

_G.LUI_STATUS_BAR_REFRESH_LAYOUT_HELP = function()
    if _G.CONFIG_WINDOW ~= nil then
        StatusBar.refresh_layout_help(_G.CONFIG_WINDOW)
    end
end
