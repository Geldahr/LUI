import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.window"
import "LUI.src.Utils.font"

local BASE_W = 360
local BASE_H = 190
local BASE_PAD = 10
local BASE_ROW_H = 24

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
        window:SetResizable(true)
        window:SetSize(_scaled_int(BASE_W), _scaled_int(BASE_H))
        _center_window(window)

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

        local menu = window:add_menu("Menu")
        menu:add_action({
            title = "Action",
            action = function()
                window.preview_body:SetText("Action clicked.")
            end,
        })
        menu:add_action({
            title = "Checkable",
            checkable = true,
            checked = true,
            action = function(action)
                window.preview_body:SetText("Checkable is " .. tostring(action:is_checked()) .. ".")
            end,
        })
        menu:add_action({
            title = "Icon action",
            icon = UI.AssetIds.feather,
            action = function()
                window.preview_body:SetText("Icon action clicked.")
            end,
        })

        local submenu = menu:add_menu("Submenu")
        submenu:add_action({
            title = "Action 2.1.1",
            action = function()
                window.preview_body:SetText("Nested action 2.1.1 clicked.")
            end,
        })
        submenu:add_action({
            title = "Action 2.1.2",
            action = function()
                window.preview_body:SetText("Nested action 2.1.2 clicked.")
            end,
        })

        local deep = submenu:add_menu("Deep")
        deep:add_action({
            title = "Action 2.1.1.1",
            action = function()
                window.preview_body:SetText("Deep action 2.1.1.1 clicked.")
            end,
        })
        deep:add_action({
            title = "Action 2.1.1.2",
            action = function()
                window.preview_body:SetText("Deep action 2.1.1.2 clicked.")
            end,
        })

        local other_menu = window:add_menu("Other")
        other_menu:add_action({
            title = "Other action",
            action = function()
                window.preview_body:SetText("Other menu action clicked.")
            end,
        })

        window.SizeChanged = function()
            LuiWindow._layout(window)
            _layout_preview(window)
        end

        _G.LUI_WINDOW_PREVIEW = window
    end

    window:apply_settings()
    window.preview_title:SetFont(_scaled_font(12))
    window.preview_body:SetFont(_scaled_font(10))
    window:open()
    window:SizeChanged()
end

_G.open_lui_window_preview = UI.Widgets.open_lui_window_preview
