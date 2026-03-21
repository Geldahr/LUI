command = Turbine.ShellCommand()

local HELP_COMMAND_COLOR = "#33C7FF"

local function _write_help_command(prefix, translated_line_key)
    local line = TR(translated_line_key)
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
    Turbine.Shell.WriteLine(TR("Available commands:"))
    _write_help_command("/lui config", "  /lui config     - Toggle configuration window")
    _write_help_command("/lui move", "  /lui move       - Toggle move mode")
    _write_help_command("/lui move cancel", "  /lui move cancel - Cancel move mode changes")
    _write_help_command("/lui inventory", "  /lui inventory  - Toggle inventory window")
    _write_help_command("/lui assets", "  /lui assets      - Toggle assets window")
    _write_help_command("/lui bestiary", "  /lui bestiary   - Toggle bestiary window")
    _write_help_command("/lui beast", "  /lui beast      - Alias for /lui bestiary")
    _write_help_command("/lui b", "  /lui b          - Short alias for /lui bestiary")
    _write_help_command("/lui card [monster name]", "  /lui card [monster name] - Open the bestiary card for a monster")
end

function command:Execute(_, str)
    if str == nil or string.len(str) == 0 then
        Turbine.Shell.WriteLine(TR("Missing Argument for more information type /lui help."))
        return
    end

    local list  = {}
    local index = 1

    -- Tokenize by whitespace (supports underscores/dots/etc in arguments).
    for word in str:gmatch("%S+") do
        list[index] = word
        index = index + 1
    end

    local cmd = string.lower(list[1])

    if cmd == "help" then
        display_help()
    elseif cmd == "move" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == "cancel" then
            cancel_move_mode()
        else
            toggle_move_mode()
        end
    elseif cmd == "config" then
        if _G.toggle_config_shortcut ~= nil then
            _G.toggle_config_shortcut()
        elseif CONFIG_WINDOW ~= nil then
            CONFIG_WINDOW:open()
        end
    elseif cmd == "inventory" or cmd == "inv" then
        if INVENTORY_WINDOW ~= nil and INVENTORY_WINDOW.toggle ~= nil then
            INVENTORY_WINDOW:toggle()
        end
    elseif cmd == "assets" or cmd == "a" then
        if _G.toggle_assets_shortcut ~= nil then
            _G.toggle_assets_shortcut()
        elseif ASSETS_WINDOW ~= nil and ASSETS_WINDOW.toggle ~= nil then
            ASSETS_WINDOW:toggle()
        end
    elseif cmd == "bestiary" or cmd == "beast" or cmd == "b" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == nil then
            if _G.toggle_bestiary_shortcut ~= nil then
                _G.toggle_bestiary_shortcut()
            else
                local window = _G.BESTIARY_WINDOW
                if window == nil and Bestiary ~= nil and Bestiary.BestiaryWindow ~= nil then
                    window = Bestiary.BestiaryWindow()
                    _G.BESTIARY_WINDOW = window
                end
                if window ~= nil and window.toggle ~= nil then
                    window:toggle()
                end
            end
        else
            display_help()
        end
    elseif cmd == "card" then
        local monster_name = table.concat(list, " ", 2)
        if monster_name == nil or monster_name == "" then
            Turbine.Shell.WriteLine(TR("Usage: /lui card [monster name]"))
            return
        end

        if BESTIARY_CARD:show_for_name(monster_name, nil) ~= true then
            Turbine.Shell.WriteLine(TR("Monster not found in bestiary: ") .. monster_name)
        end
    end
end

Turbine.Shell.AddCommand("LUI", command)
