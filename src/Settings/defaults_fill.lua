import "LUI.src.Settings.default_layouts"

local function _ensure_table(t, key)
    if type(t[key]) ~= "table" then
        t[key] = {}
    end
    return t[key]
end

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = _copy_table(child)
    end

    return copy
end

local function _apply_missing_values(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, default_value in pairs(defaults) do
        local current_value = target[key]
        if current_value == nil then
            target[key] = _copy_table(default_value)
        elseif type(current_value) == "table" and type(default_value) == "table" then
            _apply_missing_values(current_value, default_value)
        end
    end
end

local function _seed_group_vitals_compatibility(loaded, defaults)
    local default_party_source = defaults.party
    local fellowship_source = loaded.party
    if type(fellowship_source) ~= "table" then
        fellowship_source = default_party_source
        loaded.party = _copy_table(default_party_source)
    end

    local raid_source = default_party_source

    if type(loaded.fellowship) ~= "table" then
        loaded.fellowship = _copy_table(fellowship_source)
    else
        _apply_missing_values(loaded.fellowship, fellowship_source)
    end
    if loaded.fellowship.show_self_in_fellowship == nil then
        loaded.fellowship.show_self_in_fellowship = true
    end

    if type(loaded.raid) ~= "table" then
        loaded.raid = _copy_table(raid_source)
    else
        _apply_missing_values(loaded.raid, raid_source)
    end

    local hud = _ensure_table(_ensure_table(loaded, "ui"), "hud")
    local default_party_hud_source = defaults.ui.hud.party_vitals
    local fellowship_hud_source = hud.party_vitals
    if type(fellowship_hud_source) ~= "table" then
        fellowship_hud_source = default_party_hud_source
        hud.party_vitals = _copy_table(default_party_hud_source)
    end

    local raid_hud_source = default_party_hud_source

    if type(hud.fellowship_vitals) ~= "table" then
        hud.fellowship_vitals = _copy_table(fellowship_hud_source)
    else
        _apply_missing_values(hud.fellowship_vitals, fellowship_hud_source)
    end

    if type(hud.raid_vitals) ~= "table" then
        hud.raid_vitals = _copy_table(raid_hud_source)
    else
        _apply_missing_values(hud.raid_vitals, raid_hud_source)
    end
end

local function _ensure_window_tiles(windows)
    if type(windows) ~= "table" then
        return
    end

    for _, window in pairs(windows) do
        if type(window) == "table" and window.tile ~= "maximized" then
            window.tile = "none"
        end
    end
end

local function _defaults_source()
    local loaded = _G.loaded_settings
    local target_scale = _G.DefaultLayouts.get_resolution_scale()
    if type(loaded) == "table" then
        local global = loaded.global
        if type(global) == "table" then
            local scale = tonumber(global.scale)
            if type(scale) == "number" then
                target_scale = scale
            end
        end
    end

    return _G.DefaultLayouts.build("top", target_scale)
end

function _G.get_ui_window_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(_G.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    return _ensure_table(windows, key)
end

function _G.get_ui_hud_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(_G.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local hud = _ensure_table(ui, "hud")
    return _ensure_table(hud, key)
end

function _G.ensure_loaded_settings()
    if type(_G.loaded_settings) ~= "table" then
        _G.loaded_settings = {}
    end

    local defaults = _defaults_source()
    _apply_missing_values(_G.loaded_settings, defaults)
    _seed_group_vitals_compatibility(_G.loaded_settings, defaults)

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    _ensure_window_tiles(windows)

    if is_lui_english_language ~= nil and is_lui_english_language() ~= true then
        local global = _ensure_table(_G.loaded_settings, "global")
        global.bestiary_capture = false
    end
end
