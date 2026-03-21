import "Turbine.UI"

local BACKPACK_ACTION = 0x10000094
local HUD_TOGGLE = 0x100000B3
local MOVE_MODE_TOGGLE = 0x1000007B

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
    end
end
HUD_ACTION_SINK:SetWantsKeyEvents(true)
