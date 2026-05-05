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

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    _ensure_window_tiles(windows)

    if is_lui_english_language ~= nil and is_lui_english_language() ~= true then
        local global = _ensure_table(_G.loaded_settings, "global")
        global.bestiary_capture = false
    end
end
