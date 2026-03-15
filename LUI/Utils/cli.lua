command = Turbine.ShellCommand()

local function display_help()
    Turbine.Shell.WriteLine(TR("Available commands:"))
    Turbine.Shell.WriteLine(TR("  /lui config     - Open configuration window"))
    Turbine.Shell.WriteLine(TR("  /lui move       - Toggle move mode"))
    Turbine.Shell.WriteLine(TR("  /lui move cancel - Cancel move mode changes"))
    Turbine.Shell.WriteLine(TR("  /lui inventory  - Toggle inventory window"))
    Turbine.Shell.WriteLine(TR("  /lui assets      - Toggle assets window"))
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
    end
end

Turbine.Shell.AddCommand("LUI", command)
