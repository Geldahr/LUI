import "Turbine.UI"
import "Turbine.UI.Lotro"

UI = UI or {}
UI.Widgets = UI.Widgets or {}

local DEFAULTS = {
    BACKGROUND = Turbine.UI.Color(1, 0.08, 0.08, 0.08),
    FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.85, 0.85, 0.85),

    ALTERNATE_BACKGROUND = Turbine.UI.Color(1, 0.06, 0.06, 0.06),
    ALTERNATE_FOREGROUND = Turbine.UI.Color(0.88, 0.88, 0.88),

    CONTROL_BACKGROUND = Turbine.UI.Color(1, 0.15, 0.15, 0.15),
    CONTROL_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.18, 0.24, 0.34),
    CONTROL_BACKGROUND_PRESSED = Turbine.UI.Color(1, 0.10, 0.14, 0.20),
    CONTROL_BACKGROUND_ACTIVE = Turbine.UI.Color(1, 0.18, 0.30, 0.46),
    CONTROL_BACKGROUND_DISABLED = Turbine.UI.Color(1, 0.10, 0.10, 0.10),
    CONTROL_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_HOVER = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_PRESSED = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_ACTIVE = Turbine.UI.Color(1, 1, 1, 1),
    CONTROL_FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.85, 0.85, 0.85),
    CONTROL_BORDER = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_HOVER = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_ACTIVE = Turbine.UI.Color(1, 0.35, 0.40, 0.50),
    CONTROL_BORDER_DISABLED = Turbine.UI.Color(0.45, 0.62, 0.62, 0.62),
    CONTROL_BORDER_WIDTH = 1.5,

    ACCENT_BACKGROUND = Turbine.UI.Color(1, 0.68, 0.74, 0.88),
    ACCENT_BACKGROUND_DISABLED = Turbine.UI.Color(0.50, 0.68, 0.68, 0.68),
    ACCENT_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),

    SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.18, 0.30, 0.46),
    SELECTION_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.18, 0.24, 0.34),
    SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),
    ALTERNATE_SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.10, 0.14, 0.20),
    ALTERNATE_SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 1, 1),

    PANEL_BACKGROUND = Turbine.UI.Color(0.10, 0.10, 0.10),
    PANEL_INNER_BACKGROUND = Turbine.UI.Color(0.12, 0.12, 0.12),
    PLACEHOLDER_FOREGROUND = Turbine.UI.Color(1, 0.45, 0.45, 0.45),
    INVALID_BACKGROUND = Turbine.UI.Color(0.20, 0.20, 0.20),
    TRANSPARENT_BACKGROUND = Turbine.UI.Color(0, 0, 0, 0),

    DROPDOWN_ARROW = 0x41007e1a,
    DROPDOWN_ARROW_HOVER = 0x41007e1b,
    DROPDOWN_ARROW_PRESSED = 0x41007e19,
    DROPDOWN_ARROW_DISABLED = 0x41007e1a,
}

local FALLBACKS = {
    CONTROL_BACKGROUND_HOVER = "CONTROL_BACKGROUND",
    CONTROL_BACKGROUND_PRESSED = "CONTROL_BACKGROUND",
    CONTROL_BACKGROUND_ACTIVE = "SELECTION_BACKGROUND",
    CONTROL_BACKGROUND_DISABLED = "CONTROL_BACKGROUND",
    CONTROL_FOREGROUND = "FOREGROUND",
    CONTROL_FOREGROUND_HOVER = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_PRESSED = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_ACTIVE = "CONTROL_FOREGROUND",
    CONTROL_FOREGROUND_DISABLED = "FOREGROUND_DISABLED",
    CONTROL_BORDER_HOVER = "CONTROL_BORDER",
    CONTROL_BORDER_ACTIVE = "CONTROL_BORDER",
    CONTROL_BORDER_DISABLED = "CONTROL_BORDER",
    ACCENT_BACKGROUND_DISABLED = "ACCENT_BACKGROUND",
    SELECTION_BACKGROUND_HOVER = "SELECTION_BACKGROUND",
    SELECTION_FOREGROUND = "FOREGROUND",
    ALTERNATE_FOREGROUND = "FOREGROUND",
    ALTERNATE_SELECTION_BACKGROUND = "SELECTION_BACKGROUND",
    ALTERNATE_SELECTION_FOREGROUND = "SELECTION_FOREGROUND",
    PANEL_BACKGROUND = "BACKGROUND",
    PANEL_INNER_BACKGROUND = "BACKGROUND",
    PLACEHOLDER_FOREGROUND = "ALTERNATE_FOREGROUND",
    DROPDOWN_ARROW_HOVER = "DROPDOWN_ARROW",
    DROPDOWN_ARROW_PRESSED = "DROPDOWN_ARROW_HOVER",
    DROPDOWN_ARROW_DISABLED = "DROPDOWN_ARROW",
}

local Style = setmetatable({}, {
    __index = function(_, key)
        if _G.STYLE then
            local fallback = FALLBACKS[key]
            return _G.STYLE[key] or (fallback ~= nil and _G.STYLE[fallback]) or DEFAULTS[key]
        end

        return DEFAULTS[key]
    end,
})

function Style.apply_transparent_button(button)
    if button == nil then
        return
    end

    local transparent = Style.TRANSPARENT_BACKGROUND
    button:set_border_thickness(0)
    button:set_back_color(transparent)
    button:set_hover_back_color(transparent)
    button:set_pressed_back_color(transparent)
    button:set_active_back_color(transparent)
    button:set_disabled_back_color(transparent)
    button:set_border_color(transparent)
    button:set_hover_border_color(transparent)
    button:set_active_border_color(transparent)
    button:set_disabled_border_color(transparent)
end

function Style.apply_embedded_button(button)
    if button == nil then
        return
    end

    local transparent = Style.TRANSPARENT_BACKGROUND
    button:set_border_thickness(0)
    button:set_padding(0)
    button:set_back_color(transparent)
    button:set_hover_back_color(Style.CONTROL_BACKGROUND_HOVER)
    button:set_pressed_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_active_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_disabled_back_color(transparent)
    button:set_text_color(Style.CONTROL_FOREGROUND)
    button:set_hover_text_color(Style.CONTROL_FOREGROUND_HOVER)
    button:set_pressed_text_color(Style.CONTROL_FOREGROUND_PRESSED)
    button:set_active_text_color(Style.CONTROL_FOREGROUND_ACTIVE)
    button:set_disabled_text_color(Style.CONTROL_FOREGROUND_DISABLED)
end

function Style.apply_dropdown_arrow(button, width, position)
    if button == nil then
        return
    end

    button:set_icon(
        Style.DROPDOWN_ARROW,
        Style.DROPDOWN_ARROW_HOVER,
        Style.DROPDOWN_ARROW_PRESSED,
        Style.DROPDOWN_ARROW_DISABLED,
        width,
        nil,
        position
    )
end

UI.Widgets.Style = Style
