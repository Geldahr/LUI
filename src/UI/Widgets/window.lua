import "Turbine.UI"

import "LUI.src.UI.assets"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.menu"
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.font"

local Style = UI.Widgets.Style

local BASE_DEFAULT_W = 420
local BASE_DEFAULT_H = 280
local BASE_MIN_W = 160
local BASE_MIN_H = 90
local BASE_TITLE_BAR_H = 20
local BASE_GAP = 4
local BASE_ICON = 20
local BASE_CLOSE_ICON_RATIO = 0.6
local BASE_TITLE_FONT = 12
local BASE_RESIZE_EDGE = 4
local BASE_RESIZE_CORNER = 8
local BASE_RESIZE_HANDLE = 32

local RESIZE_LEFT = 1
local RESIZE_RIGHT = 2
local RESIZE_TOP = 4
local RESIZE_BOTTOM = 8

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

local function _clamp(value, min_value, max_value)
    if max_value < min_value then
        return min_value
    end
    return math.max(min_value, math.min(max_value, value))
end

local function _has_resize_dir(mask, dir)
    return math.floor((mask or 0) / dir) % 2 == 1
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _attach_drag_handlers(control, owner)
    control.MouseDown = function(_, args)
        owner:_start_drag(args)
    end
    control.MouseMove = function(_, args)
        owner:_drag_to(args)
    end
    control.MouseUp = function()
        owner:_stop_drag()
    end
end

local function _make_drag_region(parent, owner)
    local control = Turbine.UI.Control()
    control:SetParent(parent)
    control:SetMouseVisible(true)
    _set_blend(control)
    _attach_drag_handlers(control, owner)

    return control
end

local function _make_resize_region(parent, owner, mask)
    local control = Turbine.UI.Control()
    control:SetParent(parent)
    control:SetMouseVisible(true)
    control:SetZOrder(50)
    control._resize_mask = mask
    _set_blend(control)

    control.MouseEnter = function(sender, args)
        owner:_show_resize_handle(sender, args)
    end
    control.MouseLeave = function()
        if owner._resizing ~= true then
            owner:_hide_resize_handle()
        end
    end
    control.MouseDown = function(sender, args)
        owner:_start_resize(sender, args)
    end
    control.MouseMove = function(sender, args)
        if owner._resizing == true then
            owner:_resize_to(sender, args)
        else
            owner:_move_resize_handle(sender, args)
        end
    end
    control.MouseUp = function()
        owner:_stop_resize()
    end

    return control
end

local function _make_resize_handle(host)
    local image = Image()
    image:SetParent(host)
    image:SetMouseVisible(false)
    image:SetPosition(0, 0)
    image:SetVisible(false)
    return image
end

---@class LuiWindow : Turbine.UI.Window
LuiWindow = class(Turbine.UI.Window)

function LuiWindow:Constructor()
    Turbine.UI.Window.Constructor(self)

    self._scale = _current_scale()
    self._icon_asset = nil
    self._icon_size = BASE_ICON
    self._title_bar_host_width = 0
    self._explicit_title_bar_host_width = 0
    self._title_menus = {}
    self._title_bar_divider_visible = true
    self._close_handler = nil
    self._draggable = true
    self._dragging = false
    self._drag_start_screen_x = 0
    self._drag_start_screen_y = 0
    self._drag_start_window_x = 0
    self._drag_start_window_y = 0
    self._resizable = true
    self._minimum_width = nil
    self._minimum_height = nil
    self._resizing = false
    self._resize_mask = 0
    self._resize_start_screen_x = 0
    self._resize_start_screen_y = 0
    self._resize_start_window_x = 0
    self._resize_start_window_y = 0
    self._resize_start_window_w = 0
    self._resize_start_window_h = 0
    self._resize_handle_region = nil
    self._active_resize_handle = nil
    self._resize_handle_screen_x = nil
    self._resize_handle_screen_y = nil

    self:SetVisible(false)
    self:SetMouseVisible(true)
    _set_blend(self)

    self._frame = Turbine.UI.Control()
    self._frame:SetParent(self)
    self._frame:SetMouseVisible(false)
    _set_blend(self._frame)

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self._frame)
    self._inner:SetMouseVisible(false)
    _set_blend(self._inner)

    self._title_bar = Turbine.UI.Control()
    self._title_bar:SetParent(self._inner)
    self._title_bar:SetMouseVisible(false)
    _set_blend(self._title_bar)

    self._title_drag_left = _make_drag_region(self._title_bar, self)
    self._title_drag_body = _make_drag_region(self._title_bar, self)

    self._icon = Image()
    self._icon:SetParent(self._title_bar)
    self._icon:SetMouseVisible(false)
    self._icon:SetVisible(false)

    self._title_bar_host = Turbine.UI.Control()
    self._title_bar_host:SetParent(self._title_bar)
    self._title_bar_host:SetMouseVisible(true)
    self._title_bar_host:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    _set_blend(self._title_bar_host)
    self._title_bar_host:SetZOrder(10)
    _attach_drag_handlers(self._title_bar_host, self)

    self._title_label = LuiLabel()
    self._title_label:SetParent(self._title_bar)
    self._title_label:SetMouseVisible(false)
    self._title_label:SetSelectable(false)
    self._title_label:SetMultiline(false)
    self._title_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._title_label:SetVisible(false)
    self._title_label:SetZOrder(1)

    self._close_button = LuiButton()
    self._close_button:SetParent(self._title_bar)
    self._close_button:SetZOrder(10)
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

    self._resize_regions = {
        top = _make_resize_region(self, self, RESIZE_TOP),
        bottom = _make_resize_region(self, self, RESIZE_BOTTOM),
        left = _make_resize_region(self, self, RESIZE_LEFT),
        right = _make_resize_region(self, self, RESIZE_RIGHT),
        top_left = _make_resize_region(
            self,
            self,
            RESIZE_TOP + RESIZE_LEFT
        ),
        bottom_right = _make_resize_region(
            self,
            self,
            RESIZE_BOTTOM + RESIZE_RIGHT
        ),
        bottom_left = _make_resize_region(
            self,
            self,
            RESIZE_BOTTOM + RESIZE_LEFT
        ),
    }

    self._resize_handle_window = Turbine.UI.Window()
    self._resize_handle_window:SetMouseVisible(false)
    self._resize_handle_window:SetZOrder(10000)
    self._resize_handle_window:SetVisible(false)
    _set_blend(self._resize_handle_window)
    self._resize_handle_window:SetBackColor(Style.TRANSPARENT_BACKGROUND)

    self._resize_handles = {
        horizontal = _make_resize_handle(self._resize_handle_window),
        vertical = _make_resize_handle(self._resize_handle_window),
        diagonal_tl_br = _make_resize_handle(self._resize_handle_window),
        diagonal_tr_bl = _make_resize_handle(self._resize_handle_window),
    }

    self.SizeChanged = function()
        self:_layout()
    end

    LuiWindow.apply_settings(self)
    self:SetSize(_scaled_int(self._scale, BASE_DEFAULT_W), _scaled_int(self._scale, BASE_DEFAULT_H))
end

function LuiWindow:set_title(text)
    local value = text ~= nil and tostring(text) or ""
    self._title_label:SetText(value)
    self._title_label:SetVisible(string.len(value) > 0)
    self:_layout()
end

function LuiWindow:set_icon(icon, size)
    self._icon_asset = icon
    if size ~= nil then
        self:set_icon_size(size)
        return
    end
    self._icon:SetVisible(icon ~= nil)
    self:_layout()
end

function LuiWindow:set_icon_size(size)
    if type(size) ~= "number" then
        size = tonumber(size)
    end
    if size == nil or size <= 0 then
        size = BASE_ICON
    end
    self._icon_size = size
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
    self._explicit_title_bar_host_width = width
    self:_sync_title_bar_host_width()
    self:_layout_title_menus()
    self:_layout()
end

function LuiWindow:add_menu(title)
    local menu = LuiMenu()
    menu:SetParent(self._title_bar_host)
    menu:set_title(title)
    menu:set_scale(self._scale)
    menu:set_font(_scaled_font(self._scale, BASE_TITLE_FONT))
    menu:set_popup_host(self)

    self._title_menus[#self._title_menus + 1] = menu
    self:_sync_title_bar_host_width()
    self:_layout_title_menus()
    self:_layout()
    return menu
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

function LuiWindow:set_resizable(enabled)
    self._resizable = enabled == true
    if self._resizable ~= true then
        self:_stop_resize()
        self:_hide_resize_handle()
    end
    self:_layout_resize_regions()
end

function LuiWindow:set_minimum_size(width, height)
    self._minimum_width = tonumber(width)
    self._minimum_height = tonumber(height)
    self:_enforce_minimum_size()
end

function LuiWindow:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end

    self._scale = scale
    self:_apply_style()
end

function LuiWindow:apply_settings()
    self._scale = _current_scale()
    self:_apply_style()
end

function LuiWindow:_apply_style()
    self:SetBackColor(Style.CONTROL_BORDER)
    self._frame:SetBackColor(Style.CONTROL_BORDER)
    self._inner:SetBackColor(Style.BACKGROUND)
    self._title_bar:SetBackColor(Style.CONTROL_BACKGROUND)
    self._divider:SetBackColor(Style.CONTROL_BORDER)
    self._content_host:SetBackColor(Style.BACKGROUND)
    self._title_bar_host:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._title_label:SetForeColor(Style.FOREGROUND)
    self._title_label:SetFont(_scaled_font(self._scale, BASE_TITLE_FONT))

    for i = 1, #self._title_menus do
        local menu = self._title_menus[i]
        menu:set_scale(self._scale)
        menu:set_font(_scaled_font(self._scale, BASE_TITLE_FONT))
        menu:set_popup_host(self)
    end
    self:_sync_title_bar_host_width()
    self:_sync_resize_handle_icons()

    self._close_button:set_scale(self._scale)
    self._close_button:set_border_thickness(0)
    self._close_button:set_padding(0)
    self._close_button:set_back_color(Style.TRANSPARENT_BACKGROUND)
    self._close_button:set_hover_back_color(Style.TRANSPARENT_BACKGROUND)
    self._close_button:set_pressed_back_color(Style.TRANSPARENT_BACKGROUND)
    self._close_button:set_active_back_color(Style.TRANSPARENT_BACKGROUND)
    self._close_button:set_disabled_back_color(Style.TRANSPARENT_BACKGROUND)
    self._close_button:set_border_color(Style.CONTROL_BORDER)
    self._close_button:set_hover_border_color(Style.CONTROL_BORDER_HOVER)
    self._close_button:set_active_border_color(Style.CONTROL_BORDER_ACTIVE)
    self._close_button:set_disabled_border_color(Style.CONTROL_BORDER_DISABLED)
    self._close_button:set_icon(
        UI.AssetIds.x,
        UI.AssetIds.x_hover,
        UI.AssetIds.x_hover,
        UI.AssetIds.x,
        self:_base_close_icon_size(),
        self:_base_close_icon_size(),
        LuiButton.icon_position.RIGHT
    )

    self:_layout()
end

function LuiWindow:show()
    self:SetVisible(true)
    self:_bound_to_screen()
    self:bring_to_front()
end

function LuiWindow:request_close()
    if type(self._close_handler) == "function" then
        self._close_handler(self)
        return
    end
    self:hide()
end

function LuiWindow:hide()
    self:_hide_resize_handle()
    self:SetVisible(false)
end

function LuiWindow:toggle()
    if self:IsVisible() == true then
        self:hide()
    else
        self:show()
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
    return 1
end

function LuiWindow:_base_close_icon_size()
    return math.max(1, math.floor((BASE_TITLE_BAR_H * BASE_CLOSE_ICON_RATIO) + 0.5))
end

function LuiWindow:_sync_title_bar_host_width()
    local menu_width = 0
    for i = 1, #self._title_menus do
        menu_width = menu_width + self._title_menus[i]:preferred_width()
    end
    self._title_bar_host_width = math.max(self._explicit_title_bar_host_width or 0, menu_width)
end

function LuiWindow:_layout_title_menus()
    if self._title_bar_host == nil then
        return
    end

    local x = 0
    local height = self._title_bar_host:GetHeight()
    local width = self._title_bar_host:GetWidth()
    for i = 1, #self._title_menus do
        local menu = self._title_menus[i]
        local menu_w = math.min(menu:preferred_width(), math.max(0, width - x))
        menu:SetPosition(x, 0)
        menu:SetSize(menu_w, height)
        menu:SetVisible(menu_w > 0)
        x = x + menu_w
    end
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
    local width, height = self:GetSize()
    local x, y = self:_clamp_position_to_screen(
        self._drag_start_window_x + dx,
        self._drag_start_window_y + dy,
        width,
        height
    )
    self:SetPosition(x, y)
end

function LuiWindow:_stop_drag()
    self._dragging = false
end

function LuiWindow:_minimum_size()
    local min_w = self._minimum_width or _scaled_int(self._scale, BASE_MIN_W)
    local min_h = self._minimum_height or _scaled_int(self._scale, BASE_MIN_H)
    return math.max(1, min_w), math.max(1, min_h)
end

function LuiWindow:_enforce_minimum_size()
    local width, height = self:GetSize()
    local min_w, min_h = self:_minimum_size()
    self:SetSize(math.max(width, min_w), math.max(height, min_h))
    self:_bound_to_screen()
end

function LuiWindow:_display_size()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    return tonumber(display_w) or 0, tonumber(display_h) or 0
end

function LuiWindow:_fit_size_to_screen(width, height)
    local display_w, display_h = self:_display_size()
    local min_w, min_h = self:_minimum_size()
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if display_w > 0 then
        width = math.min(width, math.max(min_w, display_w))
    end
    if display_h > 0 then
        height = math.min(height, math.max(min_h, display_h))
    end

    return math.max(min_w, width), math.max(min_h, height)
end

function LuiWindow:_clamp_position_to_screen(x, y, width, height)
    local display_w, display_h = self:_display_size()
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if display_w > 0 then
        x = _clamp(x, 0, math.max(0, display_w - width))
    end
    if display_h > 0 then
        y = _clamp(y, 0, math.max(0, display_h - height))
    end

    return x, y
end

function LuiWindow:_bound_to_screen()
    local width, height = self:GetSize()
    local bounded_w, bounded_h = self:_fit_size_to_screen(width, height)
    if bounded_w ~= width or bounded_h ~= height then
        self:SetSize(bounded_w, bounded_h)
    end

    local x, y = self:GetPosition()
    local bounded_x, bounded_y = self:_clamp_position_to_screen(x, y, bounded_w, bounded_h)
    if bounded_x ~= x or bounded_y ~= y then
        self:SetPosition(bounded_x, bounded_y)
    end
end

function LuiWindow:_clamp_resize_to_screen(x, y, width, height)
    local display_w, display_h = self:_display_size()
    local min_w, min_h = self:_minimum_size()
    local mask = self._resize_mask or 0

    if display_w > 0 then
        if _has_resize_dir(mask, RESIZE_LEFT) and x < 0 then
            width = width + x
            x = 0
        elseif _has_resize_dir(mask, RESIZE_RIGHT) and x + width > display_w then
            width = display_w - x
        end
    end

    if display_h > 0 then
        if _has_resize_dir(mask, RESIZE_TOP) and y < 0 then
            height = height + y
            y = 0
        elseif _has_resize_dir(mask, RESIZE_BOTTOM) and y + height > display_h then
            height = display_h - y
        end
    end

    if width < min_w then
        if _has_resize_dir(mask, RESIZE_LEFT) then
            x = x + width - min_w
        end
        width = min_w
    end
    if height < min_h then
        if _has_resize_dir(mask, RESIZE_TOP) then
            y = y + height - min_h
        end
        height = min_h
    end

    x, y = self:_clamp_position_to_screen(x, y, width, height)
    return x, y, width, height
end

function LuiWindow:_start_resize(region, args)
    if self._resizable ~= true then
        return
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end

    self:_stop_drag()
    self._resizing = true
    self._resize_mask = region._resize_mask or 0
    self._resize_start_screen_x, self._resize_start_screen_y = region:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    self._resize_start_window_x, self._resize_start_window_y = self:GetPosition()
    self._resize_start_window_w, self._resize_start_window_h = self:GetSize()
    self:_show_resize_handle(region, args)
    self:bring_to_front()
end

function LuiWindow:_calculate_resize_bounds(region, args)
    local screen_x, screen_y = region:PointToScreen(
        args ~= nil and args.X or 0,
        args ~= nil and args.Y or 0
    )
    local dx = screen_x - self._resize_start_screen_x
    local dy = screen_y - self._resize_start_screen_y
    local min_w, min_h = self:_minimum_size()
    local x = self._resize_start_window_x
    local y = self._resize_start_window_y
    local w = self._resize_start_window_w
    local h = self._resize_start_window_h

    if _has_resize_dir(self._resize_mask, RESIZE_LEFT) then
        w = self._resize_start_window_w - dx
        if w < min_w then
            w = min_w
            x = self._resize_start_window_x + self._resize_start_window_w - min_w
        else
            x = self._resize_start_window_x + dx
        end
    elseif _has_resize_dir(self._resize_mask, RESIZE_RIGHT) then
        w = math.max(min_w, self._resize_start_window_w + dx)
    end

    if _has_resize_dir(self._resize_mask, RESIZE_TOP) then
        h = self._resize_start_window_h - dy
        if h < min_h then
            h = min_h
            y = self._resize_start_window_y + self._resize_start_window_h - min_h
        else
            y = self._resize_start_window_y + dy
        end
    elseif _has_resize_dir(self._resize_mask, RESIZE_BOTTOM) then
        h = math.max(min_h, self._resize_start_window_h + dy)
    end

    x, y, w, h = self:_clamp_resize_to_screen(x, y, w, h)
    return x, y, w, h
end

function LuiWindow:_apply_resize_bounds(x, y, width, height, region, args)
    self:SetPosition(x, y)
    self:SetSize(width, height)
end

function LuiWindow:_resize_to(region, args)
    if self._resizing ~= true then
        return
    end

    self:_remember_resize_handle_cursor(region, args)

    local x, y, w, h = self:_calculate_resize_bounds(region, args)
    self:_apply_resize_bounds(x, y, w, h, region, args)
    self:_layout_resize_handle(region)
end

function LuiWindow:_stop_resize()
    self._resizing = false
    self._resize_mask = 0
    self:_hide_resize_handle()
end

function LuiWindow:_show_resize_handle(region, args)
    if self._resizable ~= true or self._resize_handles == nil then
        return
    end

    self._resize_handle_region = region
    self:_remember_resize_handle_cursor(region, args)
    local handle = self:_resize_handle_for_region(region)
    if handle == nil then
        return
    end

    if self._active_resize_handle ~= nil and self._active_resize_handle ~= handle then
        self._active_resize_handle:SetVisible(false)
    end
    self._active_resize_handle = handle
    self:_layout_resize_handle(region)
    handle:SetVisible(true)
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetVisible(true)
        self._resize_handle_window:SetZOrder(10000)
    end
end

function LuiWindow:_move_resize_handle(region, args)
    if self._resizable ~= true or self._active_resize_handle == nil then
        return
    end

    self._resize_handle_region = region
    self:_remember_resize_handle_cursor(region, args)
    self:_layout_resize_handle(region)
end

function LuiWindow:_hide_resize_handle()
    self._resize_handle_region = nil
    self._resize_handle_screen_x = nil
    self._resize_handle_screen_y = nil
    if self._active_resize_handle ~= nil then
        self._active_resize_handle:SetVisible(false)
        self._active_resize_handle = nil
    end
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetVisible(false)
    end
end

function LuiWindow:_sync_resize_handle_icons()
    if self._resize_handles == nil then
        return
    end

    local handle = _scaled_int(self._scale, BASE_RESIZE_HANDLE)
    self._resize_handles.horizontal:set_icon(UI.AssetIds.resize_horizontal, handle, handle)
    self._resize_handles.vertical:set_icon(UI.AssetIds.resize_vertical, handle, handle)
    self._resize_handles.diagonal_tl_br:set_icon(UI.AssetIds.resize_diagonal_tl_br, handle, handle)
    self._resize_handles.diagonal_tr_bl:set_icon(UI.AssetIds.resize_diagonal_tr_bl, handle, handle)
    for _, resize_handle in pairs(self._resize_handles) do
        resize_handle:SetPosition(0, 0)
        resize_handle:SetVisible(resize_handle == self._active_resize_handle)
    end
    if self._resize_handle_window ~= nil then
        self._resize_handle_window:SetSize(handle, handle)
        self._resize_handle_window:SetVisible(self._active_resize_handle ~= nil)
    end
end

function LuiWindow:_resize_handle_for_region(region)
    if region == nil or self._resize_handles == nil then
        return nil
    end

    if region._resize_mask == RESIZE_BOTTOM + RESIZE_LEFT then
        return self._resize_handles.diagonal_tr_bl
    elseif region._resize_mask == RESIZE_LEFT or region._resize_mask == RESIZE_RIGHT then
        return self._resize_handles.horizontal
    elseif region._resize_mask == RESIZE_TOP or region._resize_mask == RESIZE_BOTTOM then
        return self._resize_handles.vertical
    end
    return self._resize_handles.diagonal_tl_br
end

function LuiWindow:_remember_resize_handle_cursor(region, args)
    if region == nil or args == nil then
        return
    end

    self._resize_handle_screen_x, self._resize_handle_screen_y = region:PointToScreen(
        args.X or 0,
        args.Y or 0
    )
end

function LuiWindow:_layout()
    if self._inner == nil then
        return
    end

    local width, height = self:GetSize()
    local border = self:_border()
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local gap = _scaled_int(self._scale, BASE_GAP)
    local icon_size = _scaled_int(self._scale, self._icon_size or BASE_ICON)
    local chrome_margin = math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH_THIN) or 1))
    local chrome_square = math.max(0, title_h - (chrome_margin * 2))
    local divider_h = self:_divider_h()

    self._frame:SetPosition(0, 0)
    self._frame:SetSize(width, height)

    local inner_w = math.max(0, width - (border * 2))
    local inner_h = math.max(0, height - (border * 2))
    self._inner:SetPosition(border, border)
    self._inner:SetSize(inner_w, inner_h)

    self._title_bar:SetPosition(0, 0)
    self._title_bar:SetSize(inner_w, math.min(title_h, inner_h))

    local close_x = math.max(0, inner_w - chrome_margin - chrome_square)
    local close_y = chrome_margin
    self._close_button:SetPosition(close_x, close_y)
    self._close_button:SetSize(chrome_square, chrome_square)

    local left_used = chrome_margin
    if self._icon_asset ~= nil and icon_size > 0 and chrome_square > 0 then
        local title_icon_size = math.min(icon_size, chrome_square)
        self._icon:set_icon(self._icon_asset, title_icon_size)
        local actual_w, actual_h = self._icon:get_size()
        actual_w = actual_w or title_icon_size
        actual_h = actual_h or title_icon_size
        local icon_x = chrome_margin + math.floor((chrome_square - actual_w) / 2)
        local icon_y = chrome_margin + math.floor((chrome_square - actual_h) / 2)
        self._icon:SetPosition(icon_x, icon_y)
        self._icon:SetVisible(true)
        left_used = chrome_margin + chrome_square + gap
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
    self._title_bar_host:SetZOrder(20)
    self._title_bar_host:SetVisible(host_w > 0)
    self:_layout_title_menus()
    if host_w > 0 then
        left_used = host_x + host_w + gap
    end

    self._title_drag_left:SetPosition(0, 0)
    self._title_drag_left:SetSize(math.max(0, host_x), title_h)

    local drag_body_x = host_x + host_w + gap
    local drag_body_w = math.max(0, close_x - gap - drag_body_x)
    self._title_drag_body:SetPosition(drag_body_x, 0)
    self._title_drag_body:SetSize(drag_body_w, title_h)

    self._title_label:SetPosition(0, 0)
    self._title_label:SetSize(inner_w, title_h)

    local divider_y = title_h
    self._divider:SetPosition(0, divider_y)
    self._divider:SetSize(inner_w, divider_h)
    self._divider:SetVisible(divider_h > 0)

    local content_y = title_h + divider_h
    local content_h = math.max(0, inner_h - content_y)
    self._content_host:SetPosition(0, content_y)
    self._content_host:SetSize(inner_w, content_h)

    self:_layout_resize_regions()
end

function LuiWindow:_layout_resize_regions()
    if self._resize_regions == nil then
        return
    end

    local width, height = self:GetSize()
    local edge = self:_border() + _scaled_int(self._scale, BASE_RESIZE_EDGE)
    local corner = math.max(edge, _scaled_int(self._scale, BASE_RESIZE_CORNER))
    local title_h = _scaled_int(self._scale, BASE_TITLE_BAR_H)
    local right_edge_top = math.min(height, title_h + edge)
    local edge_visible = self._resizable == true
    if edge_visible ~= true then
        self:_hide_resize_handle()
    end

    local top_w = math.max(0, width - (corner * 2))
    local side_h = math.max(0, height - right_edge_top - corner)
    local vertical_h = math.max(0, height - (corner * 2))

    self._resize_regions.top:SetPosition(corner, 0)
    self._resize_regions.top:SetSize(top_w, edge)

    self._resize_regions.bottom:SetPosition(corner, math.max(0, height - edge))
    self._resize_regions.bottom:SetSize(top_w, edge)

    self._resize_regions.left:SetPosition(0, corner)
    self._resize_regions.left:SetSize(edge, vertical_h)

    self._resize_regions.right:SetPosition(math.max(0, width - edge), right_edge_top)
    self._resize_regions.right:SetSize(edge, side_h)

    self._resize_regions.top_left:SetPosition(0, 0)
    self._resize_regions.top_left:SetSize(corner, corner)

    self._resize_regions.bottom_right:SetPosition(math.max(0, width - corner), math.max(0, height - corner))
    self._resize_regions.bottom_right:SetSize(corner, corner)

    self._resize_regions.bottom_left:SetPosition(0, math.max(0, height - corner))
    self._resize_regions.bottom_left:SetSize(corner, corner)

    for _, region in pairs(self._resize_regions) do
        region:SetVisible(edge_visible)
    end

    self:_layout_resize_handle(self._resize_handle_region)
end

function LuiWindow:_layout_resize_handle(region)
    local handle_control = self._active_resize_handle
    if handle_control == nil or region == nil or self._resize_handle_window == nil then
        return
    end

    local width, height = self:GetSize()
    local handle = _scaled_int(self._scale, BASE_RESIZE_HANDLE)
    local mask = region._resize_mask or 0
    local has_left = _has_resize_dir(mask, RESIZE_LEFT)
    local has_right = _has_resize_dir(mask, RESIZE_RIGHT)
    local has_top = _has_resize_dir(mask, RESIZE_TOP)
    local has_bottom = _has_resize_dir(mask, RESIZE_BOTTOM)
    local has_horizontal = has_left or has_right
    local has_vertical = has_top or has_bottom
    local x = math.floor((width - handle) / 2)
    local y = math.floor((height - handle) / 2)
    local cursor_x = nil
    local cursor_y = nil

    if self._resize_handle_screen_x ~= nil and self._resize_handle_screen_y ~= nil then
        local window_x, window_y = self:PointToScreen(0, 0)
        cursor_x = self._resize_handle_screen_x - window_x
        cursor_y = self._resize_handle_screen_y - window_y
    end

    if has_left then
        x = 0
    elseif has_right then
        x = width - handle
    elseif cursor_x ~= nil and has_vertical then
        x = math.floor(cursor_x - (handle / 2))
    end

    if has_top then
        y = 0
    elseif has_bottom then
        y = height - handle
    elseif cursor_y ~= nil and has_horizontal then
        y = math.floor(cursor_y - (handle / 2))
    end

    x = math.max(0, math.min(math.max(0, width - handle), x))
    y = math.max(0, math.min(math.max(0, height - handle), y))

    local screen_x, screen_y = self:PointToScreen(math.max(0, x), math.max(0, y))
    self._resize_handle_window:SetPosition(screen_x, screen_y)
    self._resize_handle_window:SetSize(handle, handle)
    handle_control:SetPosition(0, 0)
    handle_control:SetSize(handle, handle)
end

UI.Widgets.LuiWindow = LuiWindow
