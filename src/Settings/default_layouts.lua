import "Turbine.UI"
import "LUI.src.Settings.default_bottom"
import "LUI.src.Settings.default_top"

_G.DefaultLayouts = _G.DefaultLayouts or {}
local DefaultLayouts = _G.DefaultLayouts

local BASE_DISPLAY_W = 2560
local BASE_DISPLAY_H = 1440
local BASE_SCALE = 1.35

local SOURCE_BY_KEY = {
    bottom = function()
        return _G.DEFAULT_LAYOUT_BOTTOM
    end,
    top = function()
        return _G.DEFAULT_LAYOUT_TOP
    end,
}

local function _round(n)
    return math.floor(n + 0.5)
end

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = _copy_table(v)
    end

    return copy
end

local function _load_layout_source(layout_key)
    local get_source = SOURCE_BY_KEY[layout_key]
    if get_source == nil then
        error("Unknown default layout: " .. tostring(layout_key))
    end

    local mod = get_source()
    if type(mod) ~= "table" then
        error("Failed to load default layout: " .. tostring(layout_key))
    end

    return mod
end

local function _scale_left(base_left, display_w)
    return math.max(0, _round((base_left / BASE_DISPLAY_W) * display_w))
end

local function _scale_top(base_top, display_h)
    return math.max(0, _round((base_top / BASE_DISPLAY_H) * display_h))
end

local function _scale_width(base_width, display_w)
    return math.max(1, _round((base_width / BASE_DISPLAY_W) * display_w))
end

local function _scale_height(base_height, display_h)
    return math.max(1, _round((base_height / BASE_DISPLAY_H) * display_h))
end

local function _adjust_window_positions(node, display_w, display_h)
    if type(node) ~= "table" then
        return
    end

    for key, value in pairs(node) do
        if type(value) == "table" then
            if key == "window" then
                if type(value.left) == "number" then
                    value.left = _scale_left(value.left, display_w)
                end
                if type(value.top) == "number" then
                    value.top = _scale_top(value.top, display_h)
                end
            elseif key == "config_window" then
                if type(value.left) == "number" then
                    value.left = _scale_left(value.left, display_w)
                end
                if type(value.top) == "number" then
                    value.top = _scale_top(value.top, display_h)
                end
                if type(value.width) == "number" then
                    value.width = _scale_width(value.width, display_w)
                end
                if type(value.height) == "number" then
                    value.height = _scale_height(value.height, display_h)
                end
            end

            _adjust_window_positions(value, display_w, display_h)
        end
    end
end

function DefaultLayouts.copy_table(value)
    return _copy_table(value)
end

function DefaultLayouts.get_resolution_scale()
    local _, display_h = Turbine.UI.Display.GetSize()
    local scale = display_h / 1080
    return math.floor((scale * 100) + 0.5) / 100
end

function DefaultLayouts.get_base_scale()
    return BASE_SCALE
end

function DefaultLayouts.build(layout_key, target_scale, preserved_config_window)
    local layout = _copy_table(_load_layout_source(layout_key))
    local display_w, display_h = Turbine.UI.Display.GetSize()
    _adjust_window_positions(layout, display_w, display_h)

    if type(layout.global) ~= "table" then
        layout.global = {}
    end
    layout.global.scale = target_scale

    if preserved_config_window ~= nil then
        layout.global.config_window = _copy_table(preserved_config_window)
    end

    return layout
end
