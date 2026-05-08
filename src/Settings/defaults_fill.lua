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

local function _sanitize_with_defaults(source, defaults)
    if type(defaults) ~= "table" then
        if source == nil then
            return defaults
        end
        return source
    end

    local sanitized = _copy_table(defaults)
    if type(source) ~= "table" then
        return sanitized
    end

    for key, default_value in pairs(defaults) do
        local source_value = source[key]
        if type(default_value) == "table" then
            sanitized[key] = _sanitize_with_defaults(source_value, default_value)
        elseif source_value ~= nil then
            sanitized[key] = source_value
        end
    end

    for key, source_value in pairs(source) do
        if defaults[key] == nil and source_value ~= nil then
            sanitized[key] = _copy_table(source_value)
        end
    end

    return sanitized
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

local function _hud_position_matches(lhs, rhs)
    if type(lhs) ~= "table" or type(rhs) ~= "table" then
        return false
    end

    return lhs.left == rhs.left and lhs.top == rhs.top
end

local function _seed_group_vitals_compatibility(loaded, defaults)
    local default_party_source = defaults.party
    local fellowship_source = _sanitize_with_defaults(loaded.party, default_party_source)
    loaded.party = fellowship_source

    local raid_source = default_party_source

    loaded.fellowship = _sanitize_with_defaults(loaded.fellowship, fellowship_source)
    if loaded.fellowship.show_self_in_fellowship == nil then
        loaded.fellowship.show_self_in_fellowship = true
    end

    loaded.raid = _sanitize_with_defaults(loaded.raid, raid_source)

    local hud = _ensure_table(_ensure_table(loaded, "ui"), "hud")
    local default_party_hud_source = defaults.ui.hud.party_vitals
    local default_fellowship_hud_source = defaults.ui.hud.fellowship_vitals
    local default_raid_hud_source = defaults.ui.hud.raid_vitals
    local fellowship_hud_source = _sanitize_with_defaults(hud.party_vitals, default_fellowship_hud_source)
    hud.party_vitals = fellowship_hud_source

    local raid_hud_source = hud.raid_vitals
    if _hud_position_matches(raid_hud_source, fellowship_hud_source) == true then
        raid_hud_source = default_raid_hud_source
    end

    hud.fellowship_vitals = _sanitize_with_defaults(hud.fellowship_vitals, fellowship_hud_source)
    hud.raid_vitals = _sanitize_with_defaults(raid_hud_source, default_raid_hud_source)
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
    _G.loaded_settings = _sanitize_with_defaults(_G.loaded_settings, defaults)
    _seed_group_vitals_compatibility(_G.loaded_settings, defaults)

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    _ensure_window_tiles(windows)

    if is_lui_english_language ~= nil and is_lui_english_language() ~= true then
        local global = _ensure_table(_G.loaded_settings, "global")
        global.bestiary_capture = false
    end
end
