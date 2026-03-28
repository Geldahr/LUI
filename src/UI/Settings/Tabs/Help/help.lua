import "LUI.src.UI.Settings.Tabs.Help.help_page"

Help = {
    key = "help",
    text = TR("Help"),
}

_G.LUI_SETTINGS_TABS = _G.LUI_SETTINGS_TABS or {}
_G.LUI_SETTINGS_TABS.help = Help

function Help.create_page(window)
    return HelpPage(window)
end
