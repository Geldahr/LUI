import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.native_scaling"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.checkbox"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.font"

local Style = UI.Widgets.Style

local BASE_TOP_MENU_H = 22
local BASE_TOP_MENU_MIN_W = 42
local BASE_TOP_PAD_X = 8
local BASE_ITEM_H = 21
local BASE_POPUP_MIN_W = 150
local BASE_POPUP_PAD_X = 6
local BASE_MARK_W = 20
local BASE_ARROW_W = 16
local BASE_OPEN_GAP = 1
local BASE_EDGE_PAD = 4
local BASE_ICON_SIZE = 16

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _text_width(scale, text)
    return _scaled_int(scale, (string.len(tostring(text or "")) * 7) + 2)
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _scaled_font(scale)
    return FONT_TO_LOTRO(Style.HELP_FONT_NAME, Style.HELP_FONT_SIZE * scale)
end

local function _close_other_popups()
    if LuiDropdown ~= nil and LuiDropdown._active ~= nil then
        LuiDropdown._active:Close()
    end
    if LuiCheckDropdown ~= nil and LuiCheckDropdown._active ~= nil then
        LuiCheckDropdown._active:Close()
    end
end

---@class LuiAction : Turbine.UI.Control
LuiAction = class(Turbine.UI.Control)

function LuiAction:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._text = ""
    self._callback = nil
    self._icon_asset = nil
    self._checkable = false
    self._checked = false
    self._enabled = true
    self._hover = false
    self._submenu_open = false
    self._owner_menu = nil
    self._submenu = nil
    self._font = _scaled_font(self._scale)

    self:SetMouseVisible(true)
    _set_blend(self)

    self._checkbox = LuiCheckBox()
    self._checkbox:SetParent(self)
    self._checkbox:SetText("")
    self._checkbox:SetMouseVisible(false)
    self._checkbox:set_scale(self._scale)
    self._checkbox:SetIconScale(0.85)

    self._icon = Image()
    self._icon:SetParent(self)
    self._icon:SetMouseVisible(false)
    self._icon:SetVisible(false)

    self._label = LuiLabel()
    self._label:SetParent(self)
    self._label:SetMouseVisible(false)
    self._label:SetSelectable(false)
    self._label:SetMultiline(false)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self._label:SetFont(self._font)

    self._arrow = LuiLabel()
    self._arrow:SetParent(self)
    self._arrow:SetMouseVisible(false)
    self._arrow:SetSelectable(false)
    self._arrow:SetMultiline(false)
    self._arrow:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._arrow:SetFont(self._font)
    self._arrow:SetText(">")
    self._arrow:SetVisible(false)

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        if self._enabled ~= true then
            return
        end
        self._hover = true
        self:_update_visual_state()
        if self._owner_menu ~= nil then
            self._owner_menu:_action_hovered(self)
        end
    end

    self.MouseLeave = function()
        self._hover = false
        self:_update_visual_state()
    end

    self.MouseClick = function(_, args)
        if self._enabled ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self:trigger()
    end

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_POPUP_MIN_W), _scaled_int(self._scale, BASE_ITEM_H))
    self:_layout()
    self:_update_visual_state()
end

function LuiAction:_set_owner_menu(menu)
    self._owner_menu = menu
end

function LuiAction:_set_submenu(menu)
    self._submenu = menu
    self._arrow:SetVisible(menu ~= nil)
    self:_layout()
end

function LuiAction:_set_submenu_open(open)
    self._submenu_open = open == true
    self:_update_visual_state()
end

function LuiAction:set_scale(scale)
    self._scale = tonumber(scale) or 1
    self._font = _scaled_font(self._scale)
    self._checkbox:set_scale(self._scale)
    self._label:SetFont(self._font)
    self._arrow:SetFont(self._font)
    self:_layout()
    self:_update_visual_state()
end

function LuiAction:set_font(font)
    if font == nil then
        return
    end
    self._font = font
    self._label:SetFont(font)
    self._arrow:SetFont(font)
end

function LuiAction:set_text(text)
    self._text = tostring(text or "")
    self._label:SetText(self._text)
end

function LuiAction:set_title(title)
    self:set_text(title)
end

function LuiAction:set_icon(icon)
    self._icon_asset = icon
    self:_layout()
end

function LuiAction:set_checkable(checkable)
    self._checkable = checkable == true
    if self._checkable == true then
        self._icon_asset = nil
    end
    self:_layout()
end

function LuiAction:set_checked(checked)
    self._checked = checked == true
    self:_update_visual_state()
end

function LuiAction:is_checked()
    return self._checked == true
end

function LuiAction:set_enabled(enabled)
    self._enabled = enabled == true
    self:SetMouseVisible(self._enabled)
    self:_update_visual_state()
end

function LuiAction:set_action(callback)
    self._callback = type(callback) == "function" and callback or nil
end

function LuiAction:set_triggered(callback)
    self:set_action(callback)
end

function LuiAction:trigger()
    if self._submenu ~= nil then
        if self._owner_menu ~= nil then
            self._owner_menu:_action_hovered(self)
        end
        return
    end

    if self._checkable == true then
        self:set_checked(self._checked ~= true)
    end

    if type(self._callback) == "function" then
        self._callback(self)
    end

    if self._owner_menu ~= nil then
        self._owner_menu:_close_root()
    end
end

function LuiAction:preferred_width()
    local width = _scaled_int(self._scale, (BASE_POPUP_PAD_X * 2) + BASE_MARK_W + BASE_ARROW_W)
    width = width + _text_width(self._scale, self._text)
    return math.max(_scaled_int(self._scale, BASE_POPUP_MIN_W), width)
end

function LuiAction:_layout()
    local width, height = self:GetSize()
    local pad = _scaled_int(self._scale, BASE_POPUP_PAD_X)
    local mark_w = _scaled_int(self._scale, BASE_MARK_W)
    local arrow_w = _scaled_int(self._scale, BASE_ARROW_W)
    local icon_size = math.min(height, _scaled_int(self._scale, BASE_ICON_SIZE))
    local icon_y = math.max(0, math.floor((height - icon_size) / 2))
    local label_x = pad + mark_w
    local label_w = math.max(0, width - label_x - arrow_w - pad)

    self._checkbox:SetPosition(pad, math.max(0, math.floor((height - icon_size) / 2)))
    self._checkbox:SetSize(icon_size, icon_size)
    self._checkbox:SetVisible(self._checkable == true)

    if self._checkable ~= true and self._icon_asset ~= nil then
        self._icon:set_icon(self._icon_asset, icon_size, icon_size)
        self._icon:SetPosition(pad, icon_y)
        self._icon:SetVisible(true)
    else
        self._icon:SetVisible(false)
    end

    self._label:SetPosition(label_x, 0)
    self._label:SetSize(label_w, height)

    self._arrow:SetPosition(math.max(0, width - arrow_w - pad), 0)
    self._arrow:SetSize(arrow_w, height)
end

function LuiAction:_update_visual_state()
    local back = Style.BACKGROUND
    local text = Style.CONTROL_FOREGROUND

    if self._enabled ~= true then
        back = Style.CONTROL_BACKGROUND_DISABLED
        text = Style.CONTROL_FOREGROUND_DISABLED
    elseif self._hover == true or self._submenu_open == true then
        back = Style.CONTROL_BACKGROUND_HOVER
        text = Style.CONTROL_FOREGROUND_HOVER
    end

    self:SetBackColor(back)
    self._label:SetForeColor(text)
    self._arrow:SetForeColor(text)
    self._checkbox:SetChecked(self._checkable == true and self._checked == true)
end

---@class LuiMenu : Turbine.UI.Control
LuiMenu = class(Turbine.UI.Control)

function LuiMenu:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._title = ""
    self._font = _scaled_font(self._scale)
    self._items = {}
    self._parent_menu = nil
    self._parent_action = nil
    self._open_child = nil
    self._popup_overlay = nil

    self.button = LuiButton()
    self.button:SetParent(self)
    self.button:SetZOrder(20)
    self.button:set_scale(self._scale)
    self.button:set_border_thickness(0)
    self.button:set_padding(0)
    self.button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.button:set_font(self._font)
    Style.apply_embedded_button(self.button)
    self.button.Click = function()
        self:toggle()
    end

    self.popup = Turbine.UI.Window()
    UI.NativeScaling.apply_window(self.popup)
    self.popup:SetVisible(false)
    self.popup:SetZOrder(3100)
    self.popup:SetMouseVisible(true)
    self.popup:SetBackColor(Style.CONTROL_BORDER)
    self.popup:SetWantsKeyEvents(true)
    self.popup.KeyDown = function(_, args)
        if args ~= nil and args.Action ~= nil and args.Action == Turbine.UI.Lotro.Action.Escape then
            self:_close_root()
        end
    end

    self.popup_inner = Turbine.UI.Control()
    self.popup_inner:SetParent(self.popup)
    self.popup_inner:SetMouseVisible(true)
    self.popup_inner:SetBackColor(Style.BACKGROUND)

    self.SizeChanged = function()
        self.button:SetSize(self:GetSize())
    end

    Turbine.UI.Control.SetSize(self, self:preferred_width(), _scaled_int(self._scale, BASE_TOP_MENU_H))
end

function LuiMenu:set_title(title)
    self._title = tostring(title or "")
    self.button:set_text(self._title)
end

function LuiMenu:set_scale(scale)
    self._scale = tonumber(scale) or 1
    self._font = _scaled_font(self._scale)
    self.button:set_scale(self._scale)
    self.button:set_font(self._font)
    Style.apply_embedded_button(self.button)

    for i = 1, #self._items do
        self._items[i]:set_scale(self._scale)
        local submenu = self._items[i]._submenu
        if submenu ~= nil then
            submenu:set_scale(self._scale)
        end
    end
end

function LuiMenu:set_font(font)
    if font == nil then
        return
    end
    self._font = font
    self.button:set_font(font)
    for i = 1, #self._items do
        self._items[i]:set_font(font)
    end
end

function LuiMenu:add_action(spec)
    if type(spec) ~= "table" then
        spec = { text = spec }
    end

    local action = LuiAction()
    action:SetParent(self.popup_inner)
    action:_set_owner_menu(self)
    action:set_scale(self._scale)
    action:set_font(self._font)
    action:set_text(spec.text or spec.title)
    action:set_checkable(spec.checkable == true)
    if spec.checkable ~= true then
        action:set_icon(spec.icon)
    end
    action:set_checked(spec.checked == true)
    action:set_enabled(spec.enabled ~= false)
    action:set_triggered(spec.triggered or spec.action)

    self._items[#self._items + 1] = action
    self:_layout_popup()
    return action
end

function LuiMenu:add_menu(title)
    local submenu = LuiMenu()
    submenu:set_title(title)
    submenu._parent_menu = self
    submenu:set_scale(self._scale)
    submenu:set_font(self._font)

    local action = self:add_action({ text = title })
    action:_set_submenu(submenu)
    submenu._parent_action = action
    return submenu
end

function LuiMenu:preferred_width()
    return math.max(
        _scaled_int(self._scale, BASE_TOP_MENU_MIN_W),
        _scaled_int(self._scale, BASE_TOP_PAD_X * 2) + _text_width(self._scale, self._title)
    )
end

function LuiMenu:is_open()
    return self.popup ~= nil and self.popup:IsVisible() == true
end

function LuiMenu:open()
    if #self._items == 0 then
        return
    end

    _close_other_popups()

    local root = self:_root_menu()
    if LuiMenu._active_root ~= nil and LuiMenu._active_root ~= root then
        LuiMenu._active_root:close()
    end
    LuiMenu._active_root = root

    if self._parent_menu ~= nil then
        self._parent_menu:_set_open_child(self)
    end

    self:_layout_popup()
    self:_position_popup()
    UI.NativeScaling.apply_window(self.popup)
    root:_open_host_overlay()
    self.popup:SetVisible(true)
    self.button:set_active(true)
    if self._parent_action ~= nil then
        self._parent_action:_set_submenu_open(true)
    end
end

function LuiMenu:close()
    if self._popup_overlay ~= nil then
        self._popup_overlay:SetVisible(false)
        self._popup_overlay = nil
    end

    if self._open_child ~= nil then
        self._open_child:close()
        self._open_child = nil
    end

    self.popup:SetVisible(false)
    self.button:set_active(false)
    if self._parent_action ~= nil then
        self._parent_action:_set_submenu_open(false)
    end
    if LuiMenu._active_root == self then
        LuiMenu._active_root = nil
    end
end

function LuiMenu:toggle()
    if self:is_open() == true then
        self:close()
        return
    end
    self:open()
end

function LuiMenu:_root_menu()
    local menu = self
    while menu._parent_menu ~= nil do
        menu = menu._parent_menu
    end
    return menu
end

function LuiMenu:_get_root_widget()
    local widget = self:_root_menu()
    while widget ~= nil and widget.GetParent ~= nil do
        local parent = widget:GetParent()
        if parent == nil then
            return widget
        end
        widget = parent
    end
    return widget
end

function LuiMenu:_close_root()
    self:_root_menu():close()
end

function LuiMenu:_open_host_overlay()
    if self._parent_menu ~= nil or self._popup_overlay ~= nil then
        return
    end

    local host = self:_get_root_widget()
    if host == nil or host == self then
        return
    end

    local overlay = Turbine.UI.Control()
    overlay:SetParent(host)
    overlay:SetPosition(0, 0)
    overlay:SetSize(host:GetWidth(), host:GetHeight())
    overlay:SetMouseVisible(true)
    overlay:SetZOrder(9999)
    overlay:SetVisible(true)
    overlay.MouseDown = function()
        self:close()
    end

    self._popup_overlay = overlay
end

function LuiMenu:_set_open_child(child)
    if self._open_child ~= nil and self._open_child ~= child then
        self._open_child:close()
    end
    self._open_child = child
end

function LuiMenu:_action_hovered(action)
    if action._submenu ~= nil then
        action._submenu:open()
        return
    end

    if self._open_child ~= nil then
        self._open_child:close()
        self._open_child = nil
    end
end

function LuiMenu:_popup_border()
    return math.max(1, _scaled_int(self._scale, tonumber(Style.BORDER_WIDTH) or 1))
end

function LuiMenu:_popup_width()
    local width = _scaled_int(self._scale, BASE_POPUP_MIN_W)
    for i = 1, #self._items do
        width = math.max(width, self._items[i]:preferred_width())
    end
    return width
end

function LuiMenu:_layout_popup()
    local border = self:_popup_border()
    local width = self:_popup_width()
    local item_h = _scaled_int(self._scale, BASE_ITEM_H)
    local inner_w = math.max(0, width - (2 * border))
    local inner_h = item_h * #self._items

    self.popup:SetSize(width, inner_h + (2 * border))
    self.popup_inner:SetPosition(border, border)
    self.popup_inner:SetSize(inner_w, inner_h)
    self.popup_inner:SetBackColor(Style.BACKGROUND)

    for i = 1, #self._items do
        local action = self._items[i]
        action:SetPosition(0, (i - 1) * item_h)
        action:SetSize(inner_w, item_h)
    end
end

function LuiMenu:_position_popup()
    local x, y
    local gap = _scaled_int(self._scale, BASE_OPEN_GAP)

    if self._parent_action ~= nil then
        x, y = self._parent_action:PointToScreen(self._parent_action:GetWidth(), 0)
    else
        x, y = self:PointToScreen(0, self:GetHeight() + gap)
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    local popup_w, popup_h = self.popup:GetSize()
    local edge_pad = _scaled_int(self._scale, BASE_EDGE_PAD)

    if x + popup_w > display_w then
        if self._parent_action ~= nil then
            local parent_x = self._parent_action:PointToScreen(0, 0)
            x = parent_x - popup_w
        else
            x = display_w - popup_w - edge_pad
        end
    end
    if y + popup_h > display_h then
        y = display_h - popup_h - edge_pad
    end
    if x < edge_pad then x = edge_pad end
    if y < edge_pad then y = edge_pad end

    self.popup:SetPosition(x, y)
end

---@class LuiMenuBar : Turbine.UI.Control
LuiMenuBar = class(Turbine.UI.Control)

function LuiMenuBar:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._font = _scaled_font(self._scale)
    self._menus = {}

    self:SetMouseVisible(true)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    _set_blend(self)

    self.SizeChanged = function()
        self:_layout()
    end
end

function LuiMenuBar:set_scale(scale)
    self._scale = tonumber(scale) or 1
    self._font = _scaled_font(self._scale)
    for i = 1, #self._menus do
        self._menus[i]:set_scale(self._scale)
        self._menus[i]:set_font(self._font)
    end
    self:_layout()
end

function LuiMenuBar:set_font(font)
    if font == nil then
        return
    end
    self._font = font
    for i = 1, #self._menus do
        self._menus[i]:set_font(font)
    end
end

function LuiMenuBar:add_menu(title)
    local menu = LuiMenu()
    menu:SetParent(self)
    menu:set_title(title)
    menu:set_scale(self._scale)
    menu:set_font(self._font)

    self._menus[#self._menus + 1] = menu
    self:_layout()
    if type(self.Changed) == "function" then
        self:Changed()
    end
    return menu
end

function LuiMenuBar:preferred_width()
    local width = 0
    for i = 1, #self._menus do
        width = width + self._menus[i]:preferred_width()
    end
    return width
end

function LuiMenuBar:_layout()
    local x = 0
    local height = self:GetHeight()
    local width = self:GetWidth()
    for i = 1, #self._menus do
        local menu = self._menus[i]
        local menu_w = math.min(menu:preferred_width(), math.max(0, width - x))
        menu:SetPosition(x, 0)
        menu:SetSize(menu_w, height)
        menu:SetVisible(menu_w > 0)
        x = x + menu_w
    end
end

UI.Widgets.LuiAction = LuiAction
UI.Widgets.LuiMenu = LuiMenu
UI.Widgets.LuiMenuBar = LuiMenuBar
