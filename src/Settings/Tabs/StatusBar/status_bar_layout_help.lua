import "LUI.src.StatusBar.common"

local S = _G.STATUS_BAR_COMMON

function BuildStatusBarLayoutHelp()
    local lines = {
        TR["Tokens:"],
        TR["  %time% - local time (HH:MM)"],
        TR["  %inventory% - backpack used/total"],
        TR["  %durability% - equipped wear average% (weakest%)"],
        TR["  %gold% - money (g/s/c)"],
        TR["  %wallet% - selected wallet items"],
        TR["  %item:[Simple Fish]% - tracked total for one inventory item"],
        TR["  %config% - toggle configuration window"],
        TR["  %craft% - toggle crafting window"],
        TR["  %craft.plan% - tracked crafting plan resources"],
        TR["  %travel% - toggle travel window"],
        TR["  %bestiary% - toggle bestiary window"],
        TR["  %assets% - toggle assets window"],
    }

    local external_lines = S.get_status_bar_api_hint_lines()
    for i = 1, #external_lines do
        lines[#lines + 1] = external_lines[i]
    end

    return table.concat(lines, "\n")
end
