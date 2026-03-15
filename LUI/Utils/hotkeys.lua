import "Turbine.UI"

local BACKPACK_ACTION = 0x10000094
local ESCAPE_KEY = 0x91
local HUD_TOGGLE = 0x100000B3
local MOVE_MODE_TOGGLE = 0x1000007B

local function _close_active_color_picker()
    if LuiColorField == nil or LuiColorField._active == nil then
        return false
    end

    LuiColorField._active:_close_picker(true)
    return true
end

local function _close_config_window()
    if CONFIG_WINDOW == nil or CONFIG_WINDOW.IsVisible == nil or CONFIG_WINDOW:IsVisible() ~= true then
        return false
    end

    CONFIG_WINDOW:SetVisible(false)
    return true
end

local function _is_first_run_quick_setup_visible()
    if FIRST_RUN_QUICK_SETUP_WINDOW == nil or
        FIRST_RUN_QUICK_SETUP_WINDOW.IsVisible == nil or
        FIRST_RUN_QUICK_SETUP_WINDOW:IsVisible() ~= true then
        return false
    end

    return true
end

local function _close_inventory_window()
    if INVENTORY_WINDOW == nil or INVENTORY_WINDOW.IsVisible == nil or INVENTORY_WINDOW:IsVisible() ~= true then
        return false
    end

    INVENTORY_WINDOW:SetVisible(false)
    return true
end

local function _close_assets_window()
    if ASSETS_WINDOW == nil or ASSETS_WINDOW.IsVisible == nil or ASSETS_WINDOW:IsVisible() ~= true then
        return false
    end

    ASSETS_WINDOW:SetVisible(false)
    return true
end

local function _close_open_window()
    if _close_active_color_picker() == true then
        return true
    end
    if _close_config_window() == true then
        return true
    end
    if _close_inventory_window() == true then
        return true
    end
    if _close_assets_window() == true then
        return true
    end

    return false
end

HUD_ACTION_SINK = Turbine.UI.Control();
HUD_ACTION_SINK:SetVisible(false)
HUD_ACTION_SINK.KeyDown = function(_, args)
    if args.Action == BACKPACK_ACTION then
        local inv = _G.settings ~= nil and _G.settings.inventory or nil
        if inv ~= nil and inv.enabled == true and inv.replace == true and INVENTORY_WINDOW ~= nil and INVENTORY_WINDOW.toggle ~= nil then
            INVENTORY_WINDOW:toggle()
            return
        end
    end
    if args.Action == HUD_TOGGLE then
        toggle_lui_hud_visible()
    elseif args.Action == MOVE_MODE_TOGGLE then
        if _G.settings.global.move_mode_shortcut == true then
            toggle_move_mode()
        end
    elseif args.Action == ESCAPE_KEY then
        if _is_first_run_quick_setup_visible() == true then
            return
        end
        if _close_open_window() == true then
            return
        end
        if PLAYER_VITAL ~= nil and PLAYER_VITAL.is_move_mode ~= nil and PLAYER_VITAL:is_move_mode() == true then
            cancel_move_mode()
            return
        end
    end
end
HUD_ACTION_SINK:SetWantsKeyEvents(true)
