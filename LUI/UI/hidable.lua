GLOBAL_HUD_VISIBLE = true
LUI_HUD_PREV = LUI_HUD_PREV or {}
LUI_LAST_HUD_TOGGLE_AT = LUI_LAST_HUD_TOGGLE_AT or 0

function _G.is_lui_hud_visible()
    return GLOBAL_HUD_VISIBLE == true
end

local function _remember_and_hide_window(key, win)
    if win == nil then
        return
    end
    if win.IsVisible ~= nil then
        LUI_HUD_PREV[key] = win:IsVisible()
    end
    if win.SetVisible ~= nil then
        win:SetVisible(false)
    end
end

local function _restore_window(key, win)
    if win == nil or win.SetVisible == nil then
        return
    end
    local prev = LUI_HUD_PREV[key]
    if prev == nil then
        return
    end
    win:SetVisible(prev == true)
end

function _G.set_lui_hud_visible(visible)
    if visible == nil then
        return
    end

    GLOBAL_HUD_VISIBLE = visible == true

    if UI ~= nil and UI.Moveable ~= nil and UI.Moveable.set_hud_visible ~= nil then
        UI.Moveable.set_hud_visible(GLOBAL_HUD_VISIBLE)
    elseif Moveable ~= nil and Moveable.set_hud_visible ~= nil then
        Moveable.set_hud_visible(GLOBAL_HUD_VISIBLE)
    end

    if not GLOBAL_HUD_VISIBLE then
        _remember_and_hide_window("player_vital", PLAYER_VITAL)
        _remember_and_hide_window("target_vital", TARGET_VITAL)
        _remember_and_hide_window("boss_vital", BOSS_VITAL)
        _remember_and_hide_window("targets_target_vital",
            TARGET_VITAL ~= nil and TARGET_VITAL.targets_target_window or nil)
        _remember_and_hide_window("party_vitals", PARTY_VITALS)
        _remember_and_hide_window("expiring_effects_self", EXPIRING_SELF_EFFECTS_WINDOW)
        _remember_and_hide_window("expiring_target_effects", EXPIRING_TARGET_EFFECTS_WINDOW)
        _remember_and_hide_window("inventory", INVENTORY_WINDOW)
        _remember_and_hide_window("status_bar", STATUS_BAR)
        _remember_and_hide_window("cooldowns", COOLDOWNS_WINDOW)
        _remember_and_hide_window("move_done", MOVE_UI_DONE_WINDOW)
        _remember_and_hide_window("config", CONFIG_WINDOW)
    else
        _restore_window("player_vital", PLAYER_VITAL)
        _restore_window("target_vital", TARGET_VITAL)
        _restore_window("boss_vital", BOSS_VITAL)
        _restore_window("targets_target_vital", TARGET_VITAL ~= nil and TARGET_VITAL.targets_target_window or nil)
        _restore_window("party_vitals", PARTY_VITALS)
        _restore_window("expiring_effects_self", EXPIRING_SELF_EFFECTS_WINDOW)
        _restore_window("expiring_target_effects", EXPIRING_TARGET_EFFECTS_WINDOW)
        _restore_window("inventory", INVENTORY_WINDOW)
        _restore_window("status_bar", STATUS_BAR)
        _restore_window("cooldowns", COOLDOWNS_WINDOW)
        _restore_window("move_done", MOVE_UI_DONE_WINDOW)
        _restore_window("config", CONFIG_WINDOW)
    end
end

function _G.toggle_lui_hud_visible()
    local now = Turbine.Engine.GetGameTime()
    if (now - (LUI_LAST_HUD_TOGGLE_AT or 0)) < 0.2 then
        return
    end
    LUI_LAST_HUD_TOGGLE_AT = now
    set_lui_hud_visible(not (GLOBAL_HUD_VISIBLE == true))
end
