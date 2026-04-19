import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.window"
import "LUI.src.Utils.font"

local BASE_W = 360
local BASE_H = 190
local BASE_PAD = 10
local BASE_ROW_H = 24
local BASE_ACTION_W = 84
local BASE_ACTION_H = 20

local function _scale()
    local scale = _G.settings ~= nil and _G.settings.global ~= nil and tonumber(_G.settings.global.scale) or 1
    if scale == nil or scale <= 0 then
        scale = 1
    end
    return scale
end

local function _scaled_int(value)
    return math.floor((value * _scale()) + 0.5)
end

local function _scaled_font(size)
    return FONT_TO_LOTRO("Verdana", size * _scale())
end

local function _center_window(window)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local width, height = window:GetSize()
    window:SetPosition(math.floor((display_w - width) / 2), math.floor((display_h - height) / 2))
end

local function _layout_preview(window)
    local content = window:get_content_host()
    local width, height = content:GetSize()
    local pad = _scaled_int(BASE_PAD)
    local row_h = _scaled_int(BASE_ROW_H)

    window.preview_title:SetPosition(pad, pad)
    window.preview_title:SetSize(math.max(0, width - (pad * 2)), row_h)

    window.preview_body:SetPosition(pad, pad + row_h)
    window.preview_body:SetSize(math.max(0, width - (pad * 2)), math.max(0, height - (pad * 2) - row_h))
end

function UI.Widgets.open_lui_window_preview()
    local window = _G.LUI_WINDOW_PREVIEW
    if window == nil then
        window = LuiWindow()
        window:set_title("LuiWindow")
        window:set_icon(UI.AssetIds.feather, 18)
        window:set_title_bar_host_width(BASE_ACTION_W)
        window:SetResizable(true)
        window:SetSize(_scaled_int(BASE_W), _scaled_int(BASE_H))
        _center_window(window)

        local host = window:get_title_bar_host()
        window.preview_action = LuiButton()
        window.preview_action:SetParent(host)
        window.preview_action:set_text("Menu")
        window.preview_divider_visible = true
        window.preview_action.Click = function()
            window.preview_divider_visible = window.preview_divider_visible ~= true
            window:set_title_bar_divider_visible(window.preview_divider_visible)
        end

        local content = window:get_content_host()
        window.preview_title = LuiLabel()
        window.preview_title:SetParent(content)
        window.preview_title:SetMouseVisible(false)
        window.preview_title:SetSelectable(false)
        window.preview_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        window.preview_title:SetText("Custom window preview")

        window.preview_body = LuiLabel()
        window.preview_body:SetParent(content)
        window.preview_body:SetMouseVisible(false)
        window.preview_body:SetSelectable(false)
        window.preview_body:SetMultiline(true)
        window.preview_body:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
        window.preview_body:SetText("Drag the title bar. Resize with the native window edge. Close with the X.")

        window.SizeChanged = function()
            LuiWindow._layout(window)
            _layout_preview(window)
            local action_w = math.max(0, window:get_title_bar_host():GetWidth())
            local action_y = math.max(
                0,
                math.floor((window:get_title_bar_host():GetHeight() - _scaled_int(BASE_ACTION_H)) / 2)
            )
            window.preview_action:SetPosition(0, action_y)
            window.preview_action:SetSize(action_w, _scaled_int(BASE_ACTION_H))
        end

        _G.LUI_WINDOW_PREVIEW = window
    end

    window:apply_settings()
    window.preview_action:set_font(_scaled_font(10))
    window.preview_title:SetFont(_scaled_font(12))
    window.preview_body:SetFont(_scaled_font(10))
    window:open()
    window:SizeChanged()
end

_G.open_lui_window_preview = UI.Widgets.open_lui_window_preview
