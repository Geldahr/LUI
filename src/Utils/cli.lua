-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Runtime = _G.LUI.Runtime
local Windows = Runtime.Windows
local Commands = Runtime.Commands
local UI = _G.LUI.UI
local Shortcuts = UI.Shortcuts
local MoveMode = UI.MoveMode
local StatusBarCommon = _G.LUI.Features.StatusBar.Common
local StatusBarApiCommandParser = _G.LUI.Features.StatusBar.APICommandParser
import "LUI.src.StatusBar.api_command_parser"

local command = Turbine.ShellCommand()
Commands.shell = command

local HELP_COMMAND_COLOR = "#33C7FF"
local STATUS_BAR_API_USAGE = "/lui api sb --add -k key -t title -i image -c /command"

local function _write_help_command(prefix, translated_line_key)
    local line = TR[translated_line_key]
    if type(line) ~= "string" then
        return
    end

    local start_at, end_at = string.find(line, prefix, 1, true)
    if start_at ~= nil and end_at ~= nil then
        Turbine.Shell.WriteLine(
            string.sub(line, 1, start_at - 1) ..
            "<rgb=" .. HELP_COMMAND_COLOR .. ">" .. prefix .. "</rgb>" ..
            string.sub(line, end_at + 1)
        )
        return
    end

    Turbine.Shell.WriteLine(line)
end

local function display_help()
    Turbine.Shell.WriteLine(TR["Available commands:"])
    _write_help_command("/lui help", "  /lui help       - Print slash command help")
    _write_help_command("/lui config", "  /lui config     - Toggle configuration window")
    _write_help_command("/lui move", "  /lui move       - Toggle move mode")
    _write_help_command("/lui move cancel", "  /lui move cancel - Cancel move mode changes")
    _write_help_command("/lui inventory", "  /lui inventory  - Toggle inventory window")
    _write_help_command("/lui inv", "  /lui inv        - Short alias for /lui inventory")
    _write_help_command("/lui assets", "  /lui assets      - Toggle assets window")
    _write_help_command("/lui a", "  /lui a          - Short alias for /lui assets")
    _write_help_command("/lui craft", "  /lui craft      - Toggle crafting window")
    _write_help_command("/lui travel", "  /lui travel     - Toggle travel window")
    _write_help_command("/lui trav", "  /lui trav       - Short alias for /lui travel")
    _write_help_command("/lui bestiary", "  /lui bestiary   - Toggle bestiary window")
    _write_help_command("/lui beast", "  /lui beast      - Alias for /lui bestiary")
    _write_help_command("/lui b", "  /lui b          - Short alias for /lui bestiary")
    _write_help_command("/lui card [monster name]", "  /lui card [monster name] - Open the bestiary card for a monster")
    _write_help_command("/lui api sb --add", "  /lui api sb --add -k key -t title -i image -c /command - Register a status bar API button")
end

local function _write_error(message)
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. tostring(message or ""))
end

local function _handle_status_bar_api_command(list, index)
    local spec, err = StatusBarApiCommandParser.parse_status_bar_api_spec(list, index)
    if spec == nil then
        return nil, err
    end

    return StatusBarCommon.register_status_bar_api_item(spec)
end

function command:Execute(_, str)
    if str == nil or string.len(str) == 0 then
        Turbine.Shell.WriteLine(TR["Missing Argument for more information type /lui help."])
        return
    end

    local list = StatusBarApiCommandParser.tokenize_command_arguments(str)
    if #list == 0 then
        Turbine.Shell.WriteLine(TR["Missing Argument for more information type /lui help."])
        return
    end

    local cmd = string.lower(list[1])

    if cmd == "help" then
        display_help()
    elseif cmd == "move" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == "cancel" then
            MoveMode.cancel()
        else
            MoveMode.toggle()
        end
    elseif cmd == "config" then
        Shortcuts.toggle_config()
    elseif cmd == "inventory" or cmd == "inv" then
        Shortcuts.toggle_inventory()
    elseif cmd == "assets" or cmd == "a" then
        Shortcuts.toggle_assets()
    elseif cmd == "craft" then
        Shortcuts.toggle_crafting()
    elseif cmd == "travel" or cmd == "trav" then
        Shortcuts.toggle_travel()
    elseif cmd == "bestiary" or cmd == "beast" or cmd == "b" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == nil then
            Shortcuts.toggle_bestiary()
        else
            display_help()
        end
    elseif cmd == "card" then
        local monster_name = table.concat(list, " ", 2)
        if monster_name == nil or monster_name == "" then
            Turbine.Shell.WriteLine(TR["Usage: /lui card [monster name]"])
            return
        end

        if Windows.bestiary_card:show_for_name(monster_name, nil) ~= true then
            Turbine.Shell.WriteLine(TR["Monster not found in bestiary: "] .. monster_name)
        end
    elseif cmd == "api.sb" or (cmd == "api" and list[2] ~= nil and string.lower(list[2]) == "sb") then
        local start_index = cmd == "api.sb" and 2 or 3
        local _, err = _handle_status_bar_api_command(list, start_index)
        if err ~= nil then
            _write_error(err)
            Turbine.Shell.WriteLine("  " .. STATUS_BAR_API_USAGE)
        end
    else
        if cmd == "api" then
            display_help()
        end
    end
end

Turbine.Shell.AddCommand("LUI", command)
