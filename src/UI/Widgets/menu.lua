-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Utils = _G.LUI.Utils
local FONT_TO_LOTRO = Utils.FONT_TO_LOTRO
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.native_scaling"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.checkbox"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"
import "LUI.src.UI.Widgets.icons"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.font"
import "LUI.src.Utils.text_width"

local Widgets = _G.LUI.UI.Widgets
local LuiButton = Widgets.LuiButton
local LuiCheckBox = Widgets.LuiCheckBox
local Image = Widgets.Image
local LuiLabel = Widgets.LuiLabel
local LuiDropdown = Widgets.LuiDropdown
local LuiCheckDropdown = Widgets.LuiCheckDropdown
local Style = Widgets.Style
local Icons = Widgets.Icons

local BASE_TOP_MENU_H = 22
local BASE_TOP_MENU_MIN_W = 42
local BASE_TOP_PAD_X = 8
local BASE_ITEM_H = 21
local BASE_POPUP_MIN_W = 150
local BASE_POPUP_PAD_X = 6
local BASE_MARK_W = 20
local BASE_ARROW_W = 16
local BASE_ARROW_ICON = 10
local BASE_HINT_GAP = 12
local BASE_OPEN_GAP = 1
local BASE_EDGE_PAD = 4
local BASE_ICON_SIZE = 16
local BASE_SEPARATOR_MARGIN_Y = 4
local BASE_SEPARATOR_LINE_H = 1
local BASE_SCROLL_W = 10
local DEFAULT_MAX_VISIBLE = 10
local SEPARATOR_WIDTH_FACTOR = 0.75

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

-- measured width of a text in the font it is drawn with, +2 for glyph edges
local function _text_width(font, text)
    return Utils.measure_text_width_in_font(tostring(text or ""), font) + 2
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _scaled_font(scale)
    return FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE * scale)
end

local function _close_other_popups()
    if LuiDropdown._active ~= nil then
        LuiDropdown._active:Close()
    end
    if LuiCheckDropdown._active ~= nil then
        LuiCheckDropdown._active:Close()
    end
end

---@class LuiAction : Turbine.UI.Control
local LuiAction = class(Turbine.UI.Control)
Widgets.LuiAction = LuiAction

function LuiAction:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._is_action = true
    self._scale = 1
    self._text = ""
    self._callback = nil
    self._icon_asset = nil
    -- white UI icon (Widgets.Icons) tinted with the ICON_* colors per state
    self._icon_tinted = false
    self._checkable = false
    self._checked = false
    self._enabled = true
    self._submenu_open = false
    self._owner_menu = nil
    self._submenu = nil
    self._hint = nil
    -- the one lit row: hover and keyboard both move it (owning menu)
    self._highlighted = false
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

    self._arrow = Image()
    self._arrow:SetParent(self)
    self._arrow:SetMouseVisible(false)
    self._arrow:SetVisible(false)

    -- optional dim text on the right (e.g. autocomplete descriptions)
    self._hint_label = LuiLabel()
    self._hint_label:SetParent(self)
    self._hint_label:SetMouseVisible(false)
    self._hint_label:SetSelectable(false)
    self._hint_label:SetMultiline(false)
    self._hint_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self._hint_label:SetFont(self._font)
    self._hint_label:SetVisible(false)

    -- hover moves the menu's highlight (no separate hover look: a hovered
    -- row and a keyboard-highlighted row would both light up)
    self.MouseEnter = function()
        if self._enabled ~= true then
            return
        end
        self._owner_menu:_action_hovered(self)
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
    self._hint_label:SetFont(self._font)
    self:_layout()
    self:_update_visual_state()
end

function LuiAction:set_font(font)
    if font == nil then
        return
    end
    self._font = font
    self._label:SetFont(font)
    self._hint_label:SetFont(font)
end

function LuiAction:set_text(text)
    self._text = tostring(text or "")
    self._label:SetText(self._text)
end

function LuiAction:set_title(title)
    self:set_text(title)
end

function LuiAction:set_hint(text)
    self._hint = text
    self._hint_label:SetText(text or "")
    self._hint_label:SetVisible(text ~= nil)
    self:_layout()
end

function LuiAction:_set_highlighted(highlighted)
    self._highlighted = highlighted == true
    self:_update_visual_state()
end

function LuiAction:set_icon(icon, tinted)
    self._icon_asset = icon
    self._icon_tinted = tinted == true
    self:_layout()
    self:_update_visual_state()
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

-- rewrites a reused row with a spec (as add_action builds a fresh one);
-- the owning menu lays it out
function LuiAction:_apply_spec(spec)
    self:set_text(spec.text or spec.title)
    self._checkable = spec.checkable == true
    if self._checkable == true then
        self._icon_asset = nil
        self._icon_tinted = false
    else
        self._icon_asset = spec.icon
        self._icon_tinted = spec.icon_tinted == true
    end
    self._checked = spec.checked == true
    self._enabled = spec.enabled ~= false
    self:SetMouseVisible(self._enabled)
    self._hint = spec.hint
    self._hint_label:SetText(spec.hint or "")
    self._hint_label:SetVisible(spec.hint ~= nil)
    self._highlighted = false
    self:set_triggered(spec.triggered or spec.action)
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
    width = width + _text_width(self._font, self._text)
    if self._hint ~= nil then
        width = width + _scaled_int(self._scale, BASE_HINT_GAP) + _text_width(self._font, self._hint)
    end
    return math.max(_scaled_int(self._scale, BASE_POPUP_MIN_W), width)
end

-- laid out here, not from SizeChanged: it does not fire reliably for a
-- programmatic SetSize (rows inside the scrolling list kept a stale width)
function LuiAction:SetSize(width, height)
    Turbine.UI.Control.SetSize(self, width, height)
    self:_layout()
end

function LuiAction:preferred_height()
    return _scaled_int(self._scale, BASE_ITEM_H)
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

    if self._hint ~= nil then
        local hint_w = _text_width(self._font, self._hint)
        local hint_x = math.max(label_x, width - arrow_w - pad - hint_w)
        self._hint_label:SetPosition(hint_x, 0)
        self._hint_label:SetSize(hint_w, height)
        label_w = math.max(0, hint_x - _scaled_int(self._scale, BASE_HINT_GAP) - label_x)
    end
    self._label:SetPosition(label_x, 0)
    self._label:SetSize(label_w, height)

    local arrow_icon = math.min(height, _scaled_int(self._scale, BASE_ARROW_ICON))
    self._arrow:set_icon(Icons.sized("submenu_arrow"), arrow_icon)
    -- set_icon shows the image; only submenu entries have an arrow
    self._arrow:SetVisible(self._submenu ~= nil)
    self._arrow:SetPosition(
        math.max(0, width - arrow_w - pad + math.floor((arrow_w - arrow_icon) / 2)),
        math.max(0, math.floor((height - arrow_icon) / 2)))
end

function LuiAction:_update_visual_state()
    local back = Style.BACKGROUND
    local text = Style.CONTROL_FOREGROUND
    local icon = Style.ICON_FOREGROUND

    if self._enabled ~= true then
        back = Style.CONTROL_BACKGROUND_DISABLED
        text = Style.CONTROL_FOREGROUND_DISABLED
        icon = Style.ICON_FOREGROUND_DISABLED
    elseif self._highlighted == true or self._submenu_open == true then
        back = Style.CONTROL_BACKGROUND_HOVER
        text = Style.CONTROL_FOREGROUND_HOVER
        icon = Style.ICON_FOREGROUND_HOVER
    end

    self:SetBackColor(back)
    self._label:SetForeColor(text)
    self._hint_label:SetForeColor(Style.ALTERNATE_FOREGROUND)
    self._arrow:set_tint(icon)
    if self._icon_tinted == true then
        self._icon:set_tint(icon)
    end
    self._checkbox:SetChecked(self._checkable == true and self._checked == true)
end

---@class LuiSeparator : Turbine.UI.Control
local LuiSeparator = class(Turbine.UI.Control)
Widgets.LuiSeparator = LuiSeparator

function LuiSeparator:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._submenu = nil

    self:SetMouseVisible(false)
    self:SetBackColor(Style.BACKGROUND)
    _set_blend(self)

    self._line = Turbine.UI.Control()
    self._line:SetParent(self)
    self._line:SetMouseVisible(false)
    self._line:SetBackColor(Style.SUBTLE_FOREGROUND)
    _set_blend(self._line)

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_POPUP_MIN_W), self:preferred_height())
    self:_layout()
end

-- laid out here, not from SizeChanged: it does not fire reliably for a
-- programmatic SetSize (rows inside the scrolling list kept a stale width)
function LuiSeparator:SetSize(width, height)
    Turbine.UI.Control.SetSize(self, width, height)
    self:_layout()
end

function LuiSeparator:set_scale(scale)
    self._scale = tonumber(scale) or 1
    self:_layout()
end

function LuiSeparator:set_font()
end

function LuiSeparator:preferred_width()
    return _scaled_int(self._scale, BASE_POPUP_MIN_W)
end

function LuiSeparator:preferred_height()
    return (2 * _scaled_int(self._scale, BASE_SEPARATOR_MARGIN_Y)) +
        math.max(1, _scaled_int(self._scale, BASE_SEPARATOR_LINE_H))
end

function LuiSeparator:_layout()
    local width, height = self:GetSize()
    local line_h = math.max(1, _scaled_int(self._scale, BASE_SEPARATOR_LINE_H))
    local line_w = math.floor((width * SEPARATOR_WIDTH_FACTOR) + 0.5)
    local line_x = math.max(0, math.floor((width - line_w) / 2))
    local line_y = math.max(0, math.floor((height - line_h) / 2))

    self:SetBackColor(Style.BACKGROUND)
    self._line:SetBackColor(Style.SUBTLE_FOREGROUND)
    self._line:SetPosition(line_x, line_y)
    self._line:SetSize(line_w, line_h)
end

---@class LuiMenu : Turbine.UI.Control
local LuiMenu = class(Turbine.UI.Control)
Widgets.LuiMenu = LuiMenu

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
    -- click-away overlays, created on the first open and reused after
    self._host_overlay = nil
    self._host_overlay_parent = nil
    self._screen_overlay = nil
    -- detached rows set_actions keeps for a later longer list
    self._spare_actions = {}
    self._scroll_enabled = false
    self._max_visible = DEFAULT_MAX_VISIBLE
    self._scroll_options = nil
    self._context_x = nil
    self._context_y = nil
    self._in_menu_bar = false
    -- control the popup opens under (open_below)
    self._anchor = nil
    -- index in _items of the highlighted action (keyboard / hover)
    self._highlight = nil

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
    local prior_button_mouse_enter = self.button.MouseEnter
    self.button.MouseEnter = function(sender, args)
        if type(prior_button_mouse_enter) == "function" then
            prior_button_mouse_enter(sender, args)
        end
        self:_open_from_active_root_hover()
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
    self.popup.FocusLost = function()
        -- Context popups (opened at a screen point) dismiss on any click
        -- elsewhere, like LuiDropdown. Menu-bar popups keep overlay-based
        -- dismissal: submenu navigation moves focus between popup windows
        -- and a blur-close would kill the menu mid-navigation.
        if self._context_x == nil then
            return
        end
        if self._open_child ~= nil then
            return
        end
        self:close()
    end

    self.popup_inner = Turbine.UI.Control()
    self.popup_inner:SetParent(self.popup)
    self.popup_inner:SetMouseVisible(true)
    self.popup_inner:SetBackColor(Style.BACKGROUND)

    self.popup_list = Turbine.UI.ListBox()
    self.popup_list:SetParent(self.popup_inner)
    self.popup_list:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.popup_list:SetBackColor(Style.BACKGROUND)
    self.popup_list:SetVisible(false)

    self.popup_scroll = Turbine.UI.Lotro.ScrollBar()
    self.popup_scroll:SetParent(self.popup_inner)
    self.popup_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.popup_scroll:SetWidth(BASE_SCROLL_W)
    self.popup_scroll:SetVisible(false)
    self.popup_list:SetVerticalScrollBar(self.popup_scroll)

    self.SizeChanged = function()
        self.button:SetSize(self:GetSize())
    end

    Turbine.UI.Control.SetSize(self, self:preferred_width(), _scaled_int(self._scale, BASE_TOP_MENU_H))
end

function LuiMenu:set_title(title)
    self._title = tostring(title or "")
    self.button:set_text(self._title)
end

function LuiMenu:set_scroll_options(options)
    if options ~= nil and options.scroll == true then
        self._scroll_enabled = true
        self._max_visible = math.max(1, math.floor((tonumber(options.max_visible) or DEFAULT_MAX_VISIBLE) + 0.5))
        self._scroll_options = {
            scroll = true,
            max_visible = self._max_visible,
        }
    else
        self._scroll_enabled = false
        self._max_visible = DEFAULT_MAX_VISIBLE
        self._scroll_options = nil
    end

    self:_sync_action_parents()
    self:_layout_popup()
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
    for i = 1, #self._spare_actions do
        self._spare_actions[i]:set_scale(self._scale)
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
    for i = 1, #self._spare_actions do
        self._spare_actions[i]:set_font(font)
    end
end

function LuiMenu:_sync_action_parents()
    self.popup_list:ClearItems()
    for i = 1, #self._items do
        local action = self._items[i]
        if self._scroll_enabled == true then
            self.popup_list:AddItem(action)
        else
            action:SetParent(self.popup_inner)
        end
    end
end

-- many actions at once (suggestion lists): one popup layout at the end
-- instead of one per action
function LuiMenu:add_actions(specs)
    self._batch_adding = true
    for i = 1, #specs do
        self:add_action(specs[i])
    end
    self._batch_adding = false
    self:_layout_popup()
end

-- Replaces the items with one action per spec (add_action specs), reusing
-- the existing rows: suggestion lists are rewritten on every keystroke.
-- Flat action menus only (no separators, no submenus). An open popup is
-- laid out and placed again; a closed one is laid out by open().
function LuiMenu:set_actions(specs)
    local items = self._items
    local spare = self._spare_actions
    local scroll = self._scroll_enabled == true
    self:_set_highlight_item(nil)
    -- surplus rows are hidden before they are detached: a control detached
    -- while visible keeps drawing at the screen's top-left
    for i = #items, #specs + 1, -1 do
        local action = items[i]
        action:SetVisible(false)
        if scroll == true then
            self.popup_list:RemoveItemAt(i)
        else
            action:SetParent(nil)
        end
        items[i] = nil
        spare[#spare + 1] = action
    end
    for i = 1, #specs do
        local action = items[i]
        if action == nil then
            action = spare[#spare]
            if action ~= nil then
                spare[#spare] = nil
            else
                action = LuiAction()
                action:_set_owner_menu(self)
                action:set_scale(self._scale)
                action:set_font(self._font)
            end
            if scroll == true then
                self.popup_list:AddItem(action)
            else
                action:SetParent(self.popup_inner)
            end
            action:SetVisible(true)
            items[i] = action
        end
        action:_apply_spec(specs[i])
    end
    if self:is_open() == true then
        self:_layout_popup()
        self:_position_popup()
    end
end

function LuiMenu:add_action(spec)
    if type(spec) ~= "table" then
        spec = { text = spec }
    end

    local action = LuiAction()
    if self._scroll_enabled == true then
        self.popup_list:AddItem(action)
    else
        action:SetParent(self.popup_inner)
    end
    action:_set_owner_menu(self)
    action:set_scale(self._scale)
    action:set_font(self._font)
    action:set_text(spec.text or spec.title)
    action:set_checkable(spec.checkable == true)
    if spec.checkable ~= true then
        action:set_icon(spec.icon, spec.icon_tinted)
    end
    action:set_checked(spec.checked == true)
    action:set_enabled(spec.enabled ~= false)
    if spec.hint ~= nil then
        action:set_hint(spec.hint)
    end
    action:set_triggered(spec.triggered or spec.action)

    self._items[#self._items + 1] = action
    if self._batch_adding ~= true then
        self:_layout_popup()
    end
    return action
end

function LuiMenu:add_separator()
    local separator = LuiSeparator()
    if self._scroll_enabled == true then
        self.popup_list:AddItem(separator)
    else
        separator:SetParent(self.popup_inner)
    end
    separator:set_scale(self._scale)

    self._items[#self._items + 1] = separator
    self:_layout_popup()
    return separator
end

function LuiMenu:add_menu(title, options)
    local submenu = LuiMenu()
    submenu:set_title(title)
    submenu._parent_menu = self
    submenu:set_scroll_options(options or self._scroll_options)
    submenu:set_scale(self._scale)
    submenu:set_font(self._font)

    local action = self:add_action({ text = title })
    action:_set_submenu(submenu)
    submenu._parent_action = action
    return submenu
end

function LuiMenu:clear_items()
    self:close()
    -- hidden first: a control detached while visible keeps drawing at the
    -- screen's top-left
    for i = 1, #self._items do
        self._items[i]:SetVisible(false)
    end
    self.popup_list:ClearItems()
    for i = 1, #self._items do
        local action = self._items[i]
        if action._submenu ~= nil then
            action._submenu:clear_items()
        end
        if self._scroll_enabled ~= true then
            action:SetParent(nil)
        end
    end
    self._items = {}
    self._highlight = nil
    self:_layout_popup()
end

function LuiMenu:preferred_width()
    return math.max(
        _scaled_int(self._scale, BASE_TOP_MENU_MIN_W),
        _scaled_int(self._scale, BASE_TOP_PAD_X * 2) + _text_width(self._font, self._title)
    )
end

function LuiMenu:is_open()
    return self.popup ~= nil and self.popup:IsVisible() == true
end

function LuiMenu:open()
    if self.button._enabled ~= true then
        return
    end
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

-- Open under `control` (any control inside the host window), without taking
-- the keyboard focus: the control keeps receiving key input (autocomplete).
-- Dismissal uses the host-window overlay. Nothing is highlighted: the
-- caller decides (set_highlight).
function LuiMenu:open_below(control)
    self._anchor = control
    self:open()
    if self:is_open() ~= true then
        self._anchor = nil
    end
end

local function _is_action(item)
    return item._is_action == true and item._enabled == true
end

-- highlight the index-th selectable action (1-based among actions)
function LuiMenu:set_highlight(index)
    local count = 0
    local target = nil
    for i = 1, #self._items do
        if _is_action(self._items[i]) then
            count = count + 1
            if count == index then
                target = i
            end
        end
    end
    self:_set_highlight_item(target, true)
end

function LuiMenu:clear_highlight()
    self:_set_highlight_item(nil)
end

-- reveal: scroll mode scrolls the row into view (list index = item index,
-- every item is a list row). Only keyboard moves reveal: a hovered row is
-- under the cursor already, and scrolling it would put the next row under
-- the cursor, hover it, scroll again... down to the last row.
function LuiMenu:_set_highlight_item(item_index, reveal)
    if self._highlight ~= nil and self._items[self._highlight] ~= nil then
        self._items[self._highlight]:_set_highlighted(false)
    end
    self._highlight = item_index
    if item_index ~= nil then
        self._items[item_index]:_set_highlighted(true)
        if reveal == true and self._scroll_enabled == true then
            self.popup_list:EnsureVisible(item_index)
        end
    end
end

-- move the highlight by delta selectable actions, clamped
function LuiMenu:move_highlight(delta)
    local actions = {}
    local current = 0
    for i = 1, #self._items do
        if _is_action(self._items[i]) then
            actions[#actions + 1] = i
            if i == self._highlight then
                current = #actions
            end
        end
    end
    if #actions == 0 then
        return
    end
    local target = math.max(1, math.min(#actions, current + delta))
    self:_set_highlight_item(actions[target], true)
end

-- run the highlighted action; false when nothing is highlighted
function LuiMenu:trigger_highlight()
    if self._highlight == nil then
        return false
    end
    self._items[self._highlight]:trigger()
    return true
end

-- Open as a standalone context menu at a screen point: no menu bar, no
-- sibling hover chaining; the popup anchors to the given point instead of
-- the menu button.
function LuiMenu:open_at_screen(screen_x, screen_y)
    self._context_x = screen_x
    self._context_y = screen_y
    self:open()
    if self:is_open() ~= true then
        self._context_x = nil
        self._context_y = nil
        return
    end

    -- take focus so FocusLost fires on a click anywhere else and the
    -- context popup dismisses without needing a click on its host
    self.popup:Focus()
end

function LuiMenu:close()
    self._context_x = nil
    self._context_y = nil
    self._anchor = nil
    -- a reopened menu starts unlit (the mouse may have left a row while
    -- the popup closed)
    self:_set_highlight_item(nil)
    -- the overlay stays attached, hidden, for the next open
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

function LuiMenu:_open_from_active_root_hover()
    if self._parent_menu ~= nil then
        return
    end

    local active_root = LuiMenu._active_root
    if active_root ~= nil and active_root ~= self and active_root:GetParent() == self:GetParent() then
        self:open()
    end
end

function LuiMenu:_open_sibling_at_screen_point(screen_x, screen_y)
    local menu_bar = self:GetParent()
    if menu_bar == nil or menu_bar._menus == nil then
        -- standalone context menus have no menu-bar siblings
        return false
    end
    for i = 1, #menu_bar._menus do
        local menu = menu_bar._menus[i]
        local menu_x, menu_y = menu:PointToScreen(0, 0)
        local menu_w, menu_h = menu:GetSize()
        if menu ~= self and menu:IsVisible() == true and menu_w > 0 and menu_h > 0 and
            screen_x >= menu_x and screen_x <= (menu_x + menu_w) and
            screen_y >= menu_y and screen_y <= (menu_y + menu_h) then
            menu:open()
            return true
        end
    end

    return false
end

function LuiMenu:_open_host_overlay()
    if self._parent_menu ~= nil or self._popup_overlay ~= nil then
        return
    end

    -- Context popups get a full-screen click-away overlay: their host is
    -- often a small HUD (e.g. the status bar), so a host-sized overlay
    -- would only dismiss on clicks over the host itself. Like the native
    -- context menu, the dismissing click is swallowed.
    if self._context_x ~= nil then
        local overlay = self._screen_overlay
        if overlay == nil then
            overlay = Turbine.UI.Window()
            overlay:SetPosition(0, 0)
            overlay:SetMouseVisible(true)
            overlay:SetZOrder(3090)
            overlay.MouseDown = function()
                self:close()
            end
            self._screen_overlay = overlay
        end
        overlay:SetSize(Turbine.UI.Display.GetSize())
        overlay:SetVisible(true)
        self._popup_overlay = overlay
        return
    end

    local host = self:_get_root_widget()
    if host == nil or host == self then
        return
    end

    -- one overlay per menu, not one per open: a hidden control stays
    -- parented to the host (the suggestion menu opens on every keystroke)
    local overlay = self._host_overlay
    if overlay == nil then
        overlay = self:_make_host_overlay()
    end
    if self._host_overlay_parent ~= host then
        -- still hidden here: safe to move between hosts
        overlay:SetParent(host)
        self._host_overlay_parent = host
    end
    if self._in_menu_bar ~= true then
        -- in-content menus leave the title bar usable (close, maximize,
        -- drag); LuiWindow closes the menu when it moves or resizes
        local x, y, w, h = Widgets.popup_catcher_rect(host)
        overlay:SetPosition(x, y)
        overlay:SetSize(w, h)
    else
        overlay:SetPosition(0, 0)
        overlay:SetSize(host:GetWidth(), host:GetHeight())
    end
    overlay:SetVisible(true)
    self._popup_overlay = overlay
end

function LuiMenu:_make_host_overlay()
    local overlay = Turbine.UI.Control()
    overlay:SetVisible(false)
    overlay:SetMouseVisible(true)
    overlay:SetZOrder(9999)
    overlay.MouseMove = function(_, args)
        if args == nil or type(args.X) ~= "number" or type(args.Y) ~= "number" then
            return
        end
        local screen_x, screen_y = overlay:PointToScreen(args.X, args.Y)
        self:_open_sibling_at_screen_point(screen_x, screen_y)
    end
    overlay.MouseDown = function(_, args)
        if args ~= nil and type(args.X) == "number" and type(args.Y) == "number" then
            local screen_x, screen_y = overlay:PointToScreen(args.X, args.Y)
            if self:_open_sibling_at_screen_point(screen_x, screen_y) == true then
                return
            end
        end
        self:close()
    end

    self._host_overlay = overlay
    return overlay
end

function LuiMenu:_set_open_child(child)
    if self._open_child ~= nil and self._open_child ~= child then
        self._open_child:close()
    end
    self._open_child = child
end

function LuiMenu:_action_hovered(action)
    -- hover and keyboard share one highlight
    for i = 1, #self._items do
        if self._items[i] == action then
            self:_set_highlight_item(i)
        end
    end
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
    local item_count = #self._items
    local visible_count = item_count
    if self._scroll_enabled == true then
        visible_count = math.min(item_count, self._max_visible)
    end
    local inner_h = 0
    for i = 1, visible_count do
        inner_h = inner_h + self._items[i]:preferred_height()
    end
    local use_scroll = self._scroll_enabled == true and item_count > visible_count
    local scroll_w = use_scroll == true and BASE_SCROLL_W or 0
    -- the scrollbar and the border widen the popup instead of narrowing
    -- the rows below their preferred width
    local width = self:_popup_width() + scroll_w + (2 * border)
    local inner_w = math.max(0, width - (2 * border))
    local item_w = math.max(0, inner_w - scroll_w)

    self.popup:SetSize(width, inner_h + (2 * border))
    self.popup_inner:SetPosition(border, border)
    self.popup_inner:SetSize(inner_w, inner_h)
    self.popup_inner:SetBackColor(Style.BACKGROUND)
    self.popup_list:SetVisible(self._scroll_enabled == true)
    self.popup_list:SetPosition(0, 0)
    self.popup_list:SetSize(item_w, inner_h)
    self.popup_scroll:SetPosition(item_w, 0)
    self.popup_scroll:SetSize(BASE_SCROLL_W, inner_h)
    self.popup_scroll:SetVisible(use_scroll)

    local item_y = 0
    for i = 1, item_count do
        local action = self._items[i]
        local item_h = action:preferred_height()
        if self._scroll_enabled == true then
            action:SetSize(item_w, item_h)
        else
            action:SetPosition(0, item_y)
            action:SetSize(inner_w, item_h)
        end
        item_y = item_y + item_h
    end
end

function LuiMenu:_position_popup()
    local x, y
    local gap = _scaled_int(self._scale, BASE_OPEN_GAP)

    if self._context_x ~= nil then
        x, y = self._context_x, self._context_y
    elseif self._anchor ~= nil then
        x, y = self._anchor:PointToScreen(0, self._anchor:GetHeight() + gap)
    elseif self._parent_action ~= nil then
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
local LuiMenuBar = class(Turbine.UI.Control)
Widgets.LuiMenuBar = LuiMenuBar

function LuiMenuBar:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._font = _scaled_font(self._scale)
    self._menus = {}
    self.on_change = nil

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

function LuiMenuBar:add_menu(title_or_menu, options)
    local menu = title_or_menu
    if type(title_or_menu) ~= "table" then
        menu = LuiMenu()
        menu:set_title(title_or_menu)
    elseif options ~= nil then
        menu:set_scroll_options(options)
    end

    menu:SetParent(self)
    -- menu-bar menus cover the whole host window (title bar included) so
    -- hovering across the bar switches menus
    menu._in_menu_bar = true
    if type(title_or_menu) ~= "table" then
        menu:set_scroll_options(options)
    end
    menu:set_scale(self._scale)
    menu:set_font(self._font)

    self._menus[#self._menus + 1] = menu
    self:_layout()
    if self.on_change ~= nil then
        self:on_change()
    end
    return menu
end

function LuiMenuBar:remove_menu(menu)
    for i = 1, #self._menus do
        if self._menus[i] == menu then
            menu:close()
            menu:SetParent(nil)
            table.remove(self._menus, i)
            self:_layout()
            if self.on_change ~= nil then
                self:on_change()
            end
            return menu
        end
    end
    error("LuiMenuBar:remove_menu menu is not registered")
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
UI.Widgets.LuiSeparator = LuiSeparator
UI.Widgets.LuiMenu = LuiMenu
UI.Widgets.LuiMenuBar = LuiMenuBar
