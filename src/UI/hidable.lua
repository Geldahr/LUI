GLOBAL_HUD_VISIBLE = GLOBAL_HUD_VISIBLE ~= false
LUI_HUD_PREV = LUI_HUD_PREV or {}
LUI_LAST_HUD_TOGGLE_AT = LUI_LAST_HUD_TOGGLE_AT or 0

_G.LUI_HIDABLE = _G.LUI_HIDABLE or {}

local Hidable = _G.LUI_HIDABLE
local REGISTRY = Hidable._registry or setmetatable({}, { __mode = "k" })
local WINDOW_PREV = Hidable._window_prev or setmetatable({}, { __mode = "k" })
Hidable._registry = REGISTRY
Hidable._window_prev = WINDOW_PREV

local function _prev_store_for(win)
    local key = REGISTRY[win]
    if key ~= nil and key ~= false then
        return LUI_HUD_PREV, key
    end
    return WINDOW_PREV, win
end

local function _remember_and_hide_window(win)
    if win == nil then
        return
    end

    local store, key = _prev_store_for(win)
    if win.IsVisible ~= nil then
        store[key] = win:IsVisible()
    end
    if win.SetVisible ~= nil then
        win:SetVisible(false)
    end
end

local function _restore_window(win)
    if win == nil or win.SetVisible == nil then
        return
    end

    local store, key = _prev_store_for(win)
    local prev = store[key]
    if prev == nil then
        return
    end
    win:SetVisible(prev == true)
    store[key] = nil
end

function Hidable.register(win, key)
    if win == nil then
        return
    end

    REGISTRY[win] = key or false
    if GLOBAL_HUD_VISIBLE ~= true and win.SetVisible ~= nil then
        win:SetVisible(false)
    end
end

function Hidable.unregister(win)
    if win == nil then
        return
    end

    local key = REGISTRY[win]
    REGISTRY[win] = nil
    WINDOW_PREV[win] = nil
    if key ~= nil and key ~= false then
        LUI_HUD_PREV[key] = nil
    end
end

function Hidable.set_visible(visible)
    if visible == nil then
        return
    end

    GLOBAL_HUD_VISIBLE = visible == true

    if LUI_MOVE_UI ~= nil and LUI_MOVE_UI.set_hud_visible ~= nil then
        LUI_MOVE_UI.set_hud_visible(GLOBAL_HUD_VISIBLE)
    end

    if GLOBAL_HUD_VISIBLE == true then
        for win in pairs(REGISTRY) do
            _restore_window(win)
        end
    else
        for win in pairs(REGISTRY) do
            _remember_and_hide_window(win)
        end
    end
end

function Hidable.is_visible()
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
