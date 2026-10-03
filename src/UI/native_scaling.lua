-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.UI"

local LUI = _G.LUI
local State = LUI.Settings.State
local NativeScaling = LUI.UI.NativeScaling

local DEFAULT_SCALE = 1
local DEFAULT_ORIGIN_LEFT = 0
local DEFAULT_ORIGIN_TOP = 0

local function _global_settings(settings)
    if type(settings) == "table" and type(settings.global) == "table" then
        return settings.global
    end
    if type(State.settings) == "table" and type(State.settings.global) == "table" then
        return State.settings.global
    end
    if type(State.loaded_settings) == "table" and type(State.loaded_settings.global) == "table" then
        return State.loaded_settings.global
    end
    return nil
end

local function _safe_window_call(window, method_name, ...)
    if window == nil then
        return false
    end

    local method = window[method_name]
    if type(method) ~= "function" then
        return false
    end

    local ok = pcall(method, window, ...)
    return ok == true
end

local function _to_number(value, fallback)
    local n = value
    if type(n) ~= "number" then
        n = tonumber(n)
    end
    if n == nil then
        return fallback
    end
    return n
end

function NativeScaling.get_configured_scale(settings)
    local global = _global_settings(settings)
    local scale = global ~= nil and global.scale or DEFAULT_SCALE
    local n = _to_number(scale, DEFAULT_SCALE)
    if n <= 0 then
        return DEFAULT_SCALE
    end
    return n
end

function NativeScaling.get_effective_scale(settings)
    return NativeScaling.get_configured_scale(settings)
end

function NativeScaling.scale_value(value, settings)
    return _to_number(value, 0) * NativeScaling.get_effective_scale(settings)
end

function NativeScaling.scaled_int(value, settings)
    return math.floor(NativeScaling.scale_value(value, settings) + 0.5)
end

-- LUI applies its own scale to every size it sets, so the game's UI scaling
-- must stay off its windows: a window left registered for Global scaling
-- would be scaled twice when the player enables "Use Global Scaling" for the
-- plugin. SetScale is never called: since U49.6 it turns native scaling ON
-- for the window when the plugin is not using Global scaling.
function NativeScaling.disable(window)
    _safe_window_call(window, "SetScalingOriginPoint", DEFAULT_ORIGIN_LEFT, DEFAULT_ORIGIN_TOP)
    _safe_window_call(window, "UnregisterForGlobalScaling")
end

function NativeScaling.apply_window(window)
    NativeScaling.disable(window)
end

function NativeScaling.get_ui_scale(settings)
    return NativeScaling.get_effective_scale(settings)
end

function NativeScaling.scale_ui_value(value, settings)
    return NativeScaling.scale_value(value, settings)
end

function NativeScaling.scaled_ui_int(value, settings)
    return NativeScaling.scaled_int(value, settings)
end
