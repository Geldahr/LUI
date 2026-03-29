import "LUI.src.Settings.Tabs.Help.help_page"

Help = {
    key = "help",
    text = TR("Help"),
}

function Help.create_page(window)
    return HelpPage(window)
end
