import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.font"

local Style = UI.Widgets.Style

local BASE_DEFAULT_W = 420
local BASE_DEFAULT_H = 280
local BASE_TITLE_BAR_H = 28
local BASE_PAD_X = 7
local BASE_GAP = 4
local BASE_ICON = 20
local BASE_CLOSE_BUTTON = 22
local BASE_CLOSE_ICON = 16
local BASE_TITLE_FONT = 12

local function _current_scale()
    local scale = _G.settings ~= nil and _G.settings.global ~= nil and tonumber(_G.settings.global.scale) or 1
    if scale == nil or scale <= 0 then
        scale = 1
    end
    return scale
end

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _scaled_font(scale, size)
    return FONT_TO_LOTRO("Verdana", size * scale)
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

---@class LuiWindow : Turbine.UI.Window
LuiWindow = class(Turbine.UI.Window)

function LuiWindow:Constructor()
    Turbine.UI.Window.Constructor(self)

    self._scale = _current_scale()
    self._icon_asset = nil
    self._title_bar_host_width = 0
    self._title_bar_divider_visible = true
    self._close_handler = nil
    self._draggable = true
    self._dragging = false
    self._drag_start_screen_x = 0
    self._drag_start_screen_y = 0
    self._drag_start_window_x = 0
    self._drag_start_window_y = 0

    self:SetVisible(false)
    self:SetMouseVisible(true)
    _set_blend(self)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetMouseVisible(false)
    _set_blend(self._inner)

    self._title_bar = Turbine.UI.Control()
    self._title_bar:SetParent(self._inner)
    self._title_bar:SetMouseVisible(true)
    _set_blend(self._title_bar)
    self._title_bar.MouseDown = function(_, args)
        self:_start_drag(args)
    end
    self._title_bar.MouseMove = function(_, args)
        self:_drag_to(args)
    end
    self._title_bar.MouseUp = function()
        self:_stop_drag()
    end

    self._icon = Image()
    self._icon:SetParent(self._title_bar)
    self._icon:SetMouseVisible(false)
    self._icon:SetVisible(false)

    self._title_bar_host = Turbine.UI.Control()
    self._title_bar_host:SetParent(self._title_bar)
    self._title_bar_host:SetMouseVisible(true)
    self._title_bar_host:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    _set_blend(self._title_bar_host)

    self._title_label = LuiLabel()
    self._title_label:SetParent(self._title_bar)
    self._title_label:SetMouseVisible(false)
    self._title_label:SetSelectable(false)
    self._title_label:SetMultiline(false)
    self._title_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._title_label:SetVisible(false)

    self._close_button = LuiButton()
    self._close_button:SetParent(self._title_bar)
    self._close_button:set_text("")
    self._close_button.Click = function()
        self:request_close()
    end

    self._divider = Turbine.UI.Control()
    self._divider:SetParent(self._inner)
    self._divider:SetMouseVisible(false)
    _set_blend(self._divider)

    self._content_host = Turbine.UI.Control()
    self._content_host:SetParent(self._inner)
    self._content_host:SetMouseVisible(true)
    _set_blend(self._content_host)

    self.SizeChanged = function()
        self:_layout()
    end

    self:apply_settings()
    self:SetSize(_scaled_int(self._scale, BASE_DEFAULT_W), _scaled_int(self._scale, BASE_DEFAULT_H))
end

function LuiWindow:set_title(text)
    local value = text ~= nil and tostring(text) or ""
    self._title_label:SetText(value)
    self._title_label:SetVisible(string.len(value) > 0)
    self:_layout()
end

function LuiWindow:set_icon(icon)
    self._icon_asset = icon
    self._icon:SetVisible(icon ~= nil)
    self:_layout()
end

function LuiWindow:clear_icon()
    self:set_icon(nil)
end

function LuiWindow:get_title_bar_host()
    return self._title_bar_host
end

function LuiWindow:set_title_bar_host_width(width)
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil or width < 0 then
        width = 0
    end
    self._title_bar_host_width = width
    self:_layout()
end

function LuiWindow:get_content_host()
    return self._content_host
end

function LuiWindow:get_content_size()
    return self._content_host:GetSize()
end

function LuiWindow:get_content_size_for_window(width, height)
    local border = self:_border()
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local divider_h = self:_divider_h()

    local content_w = math.max(0, (tonumber(width) or 0) - (border * 2))
    local content_h = math.max(0, (tonumber(height) or 0) - (border * 2) - title_h - divider_h)
    return content_w, content_h
end

function LuiWindow:get_chrome_size()
    local width, height = self:GetSize()
    local content_w, content_h = self:get_content_size()
    return math.max(0, width - content_w), math.max(0, height - content_h)
end

function LuiWindow:get_window_size_for_content(width, height)
    local chrome_w, chrome_h = self:get_chrome_size()
    return (tonumber(width) or 0) + chrome_w, (tonumber(height) or 0) + chrome_h
end

function LuiWindow:set_title_bar_divider_visible(visible)
    self._title_bar_divider_visible = visible == true
    self:_layout()
end

function LuiWindow:set_close_handler(handler)
    self._close_handler = handler
end

function LuiWindow:set_draggable(enabled)
    self._draggable = enabled == true
    if self._draggable ~= true then
        self:_stop_drag()
    end
end

function LuiWindow:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end

    self._scale = scale
    self:apply_settings()
end

function LuiWindow:apply_settings()
    self:SetBackColor(Style.CONTROL_BORDER)
    self._inner:SetBackColor(Style.BACKGROUND)
    self._title_bar:SetBackColor(Style.CONTROL_BACKGROUND)
    self._divider:SetBackColor(Style.CONTROL_BORDER)
    self._content_host:SetBackColor(Style.BACKGROUND)
    self._title_bar_host:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._title_label:SetForeColor(Style.FOREGROUND)
    self._title_label:SetFont(_scaled_font(self._scale, BASE_TITLE_FONT))

    self._close_button:set_scale(self._scale)
    Style.apply_transparent_button(self._close_button)
    self._close_button:set_icon(
        UI.AssetIds.x,
        UI.AssetIds.x_hover,
        UI.AssetIds.x_hover,
        UI.AssetIds.x,
        BASE_CLOSE_ICON,
        BASE_CLOSE_ICON,
        LuiButton.icon_position.RIGHT
    )

    self:_layout()
end

function LuiWindow:open()
    self:SetVisible(true)
    self:bring_to_front()
end

function LuiWindow:request_close()
    if type(self._close_handler) == "function" then
        self._close_handler(self)
        return
    end
    self:close()
end

function LuiWindow:close()
    self:SetVisible(false)
end

function LuiWindow:toggle()
    self:SetVisible(not self:IsVisible())
    if self:IsVisible() == true then
        self:bring_to_front()
    end
end

function LuiWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function LuiWindow:_border()
    return math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH) or 1))
end

function LuiWindow:_divider_h()
    if self._title_bar_divider_visible ~= true then
        return 0
    end
    return math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH_THIN) or 1))
end

function LuiWindow:_start_drag(args)
    if self._draggable ~= true then
        return
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end

    self._dragging = true
    self._drag_start_screen_x, self._drag_start_screen_y = self._title_bar:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    self._drag_start_window_x, self._drag_start_window_y = self:GetPosition()
    self:bring_to_front()
end

function LuiWindow:_drag_to(args)
    if self._dragging ~= true then
        return
    end

    local screen_x, screen_y = self._title_bar:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    local dx = screen_x - self._drag_start_screen_x
    local dy = screen_y - self._drag_start_screen_y
    self:SetPosition(self._drag_start_window_x + dx, self._drag_start_window_y + dy)
end

function LuiWindow:_stop_drag()
    self._dragging = false
end

function LuiWindow:_layout()
    if self._inner == nil then
        return
    end

    local width, height = self:GetSize()
    local border = self:_border()
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local pad_x = _scaled_int(self._scale, BASE_PAD_X)
    local gap = _scaled_int(self._scale, BASE_GAP)
    local icon_size = _scaled_int(self._scale, BASE_ICON)
    local close_size = _scaled_int(self._scale, BASE_CLOSE_BUTTON)
    local divider_h = self:_divider_h()

    local inner_w = math.max(0, width - (border * 2))
    local inner_h = math.max(0, height - (border * 2))
    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)

    self._title_bar:SetPosition(0, 0)
    self._title_bar:SetSize(inner_w, math.min(title_h, inner_h))

    local close_x = math.max(0, inner_w - pad_x - close_size)
    local close_y = math.max(0, math.floor((title_h - close_size) / 2))
    self._close_button:SetPosition(close_x, close_y)
    self._close_button:SetSize(close_size, close_size)

    local left_used = pad_x
    if self._icon_asset ~= nil and icon_size > 0 and title_h > 0 then
        local icon_y = math.max(0, math.floor((title_h - icon_size) / 2))
        self._icon:set_icon(self._icon_asset, icon_size, icon_size)
        self._icon:SetPosition(pad_x, icon_y)
        self._icon:SetVisible(true)
        left_used = pad_x + icon_size + gap
    else
        self._icon:SetVisible(false)
    end

    local host_w = _scaled_int(self._scale, self._title_bar_host_width or 0)
    local host_x = left_used
    local max_host_w = math.max(0, close_x - gap - host_x)
    if host_w > max_host_w then
        host_w = max_host_w
    end
    self._title_bar_host:SetPosition(host_x, 0)
    self._title_bar_host:SetSize(host_w, title_h)
    self._title_bar_host:SetVisible(host_w > 0)
    if host_w > 0 then
        left_used = host_x + host_w + gap
    end

    local right_used = math.max(0, inner_w - close_x + gap)
    local safe_margin = math.max(left_used, right_used)
    local title_x = safe_margin
    local title_w = math.max(0, inner_w - (safe_margin * 2))
    self._title_label:SetPosition(title_x, 0)
    self._title_label:SetSize(title_w, title_h)

    local divider_y = title_h
    self._divider:SetPosition(0, divider_y)
    self._divider:SetSize(inner_w, divider_h)
    self._divider:SetVisible(divider_h > 0)

    local content_y = title_h + divider_h
    local content_h = math.max(0, inner_h - content_y)
    self._content_host:SetPosition(0, content_y)
    self._content_host:SetSize(inner_w, content_h)
end

UI.Widgets.LuiWindow = LuiWindow
