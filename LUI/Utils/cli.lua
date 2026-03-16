command = Turbine.ShellCommand()

local function display_help()
    Turbine.Shell.WriteLine(TR("Available commands:"))
    Turbine.Shell.WriteLine(TR("  /lui config     - Open configuration window"))
    Turbine.Shell.WriteLine(TR("  /lui move       - Toggle move mode"))
    Turbine.Shell.WriteLine(TR("  /lui move cancel - Cancel move mode changes"))
    Turbine.Shell.WriteLine(TR("  /lui inventory  - Toggle inventory window"))
    Turbine.Shell.WriteLine(TR("  /lui assets      - Toggle assets window"))
    Turbine.Shell.WriteLine(TR("  /lui bestiary   - Toggle bestiary window"))
    Turbine.Shell.WriteLine(TR("  /lui bestiary export - Dump captured bestiary data as Lua"))
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
        if CONFIG_WINDOW ~= nil then
            CONFIG_WINDOW:open()
        end
    elseif cmd == "inventory" or cmd == "inv" then
        if INVENTORY_WINDOW ~= nil and INVENTORY_WINDOW.toggle ~= nil then
            INVENTORY_WINDOW:toggle()
        end
    elseif cmd == "assets" or cmd == "a" then
        if ASSETS_WINDOW ~= nil and ASSETS_WINDOW.toggle ~= nil then
            ASSETS_WINDOW:toggle()
        end
    elseif cmd == "bestiary" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == "export" then
            if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.export_to_shell ~= nil then
                BESTIARY_TRACKER:export_to_shell()
            end
        elseif action == nil then
            if BESTIARY_WINDOW == nil and Bestiary ~= nil and Bestiary.BestiaryWindow ~= nil then
                BESTIARY_WINDOW = Bestiary.BestiaryWindow()
            end
            if BESTIARY_WINDOW ~= nil and BESTIARY_WINDOW.toggle ~= nil then
                BESTIARY_WINDOW:toggle()
            end
        else
            display_help()
        end
    end
end

Turbine.Shell.AddCommand("LUI", command)
