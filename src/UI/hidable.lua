import "LUI.src.UI.popup_state"

GLOBAL_HUD_VISIBLE = GLOBAL_HUD_VISIBLE ~= false
LUI_LAST_HUD_TOGGLE_AT = LUI_LAST_HUD_TOGGLE_AT or 0

_G.LUI_HIDABLE = _G.LUI_HIDABLE or {}

local Hidable = _G.LUI_HIDABLE
local HidableMethods = {}

Hidable.register = nil
Hidable.unregister = nil
Hidable.set_visible = nil
Hidable.is_visible = nil

setmetatable(Hidable, {
    __mode = "k",
    __index = HidableMethods,
})

local function _is_registered_window(win, registered)
    return registered == true
end

local function _apply_global_visibility(win, visible)
    if win == nil then
        return
    end

    if win.global_hide ~= nil then
        win:global_hide(visible)
    elseif visible ~= true and win.SetVisible ~= nil then
        win:SetVisible(false)
    end
end

function HidableMethods.register(win)
    if win == nil then
        return
    end

    Hidable[win] = true
    if GLOBAL_HUD_VISIBLE ~= true then
        _apply_global_visibility(win, false)
    end
end

function HidableMethods.unregister(win)
    if win == nil then
        return
    end

    Hidable[win] = nil
end

function HidableMethods.set_visible(visible)
    if visible == nil then
        return
    end

    GLOBAL_HUD_VISIBLE = visible == true

    if GLOBAL_HUD_VISIBLE ~= true and _G.LUI_POPUP_STATE ~= nil and _G.LUI_POPUP_STATE.close_all ~= nil then
        _G.LUI_POPUP_STATE.close_all()
    end

    if LUI_MOVE_UI ~= nil and LUI_MOVE_UI.set_hud_visible ~= nil then
        LUI_MOVE_UI.set_hud_visible(GLOBAL_HUD_VISIBLE)
    end

    for win, registered in pairs(Hidable) do
        if _is_registered_window(win, registered) == true then
            _apply_global_visibility(win, GLOBAL_HUD_VISIBLE)
        end
    end
end

function HidableMethods.is_visible()
    return GLOBAL_HUD_VISIBLE == true
end

function _G.is_lui_hud_visible()
    return Hidable.is_visible()
end

function _G.set_lui_hud_visible(visible)
    Hidable.set_visible(visible)
end

function _G.toggle_lui_hud_visible()
    local now = Turbine.Engine.GetGameTime()
    if (now - (LUI_LAST_HUD_TOGGLE_AT or 0)) < 0.2 then
        return
    end
    LUI_LAST_HUD_TOGGLE_AT = now
    set_lui_hud_visible(not (GLOBAL_HUD_VISIBLE == true))
end
