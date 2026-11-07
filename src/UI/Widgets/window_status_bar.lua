-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- LuiWindow's status bar: an optional bar at the
-- bottom of the window with labels, icons, separators, progress bars and
-- controls in three groups (left, center, right), plus a temporary message
-- in place of the left group. Created on first use, so windows without one
-- pay nothing; laid out by LuiWindow:_layout (no SizeChanged), placed by
-- window_status_layout.lua.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Utils = _G.LUI.Utils
local class = _G.LUI.Core.class
local Widgets = _G.LUI.UI.Widgets
import "LUI.src.Utils.text_width"
import "LUI.src.UI.Widgets.timer"
import "LUI.src.UI.Widgets.tooltip"

local LuiWindow = Widgets.LuiWindow
local LuiLabel = Widgets.LuiLabel
local Image = Widgets.Image
local LuiTimer = Widgets.LuiTimer
local LuiTooltip = Widgets.LuiTooltip
local Style = Widgets.Style

-- icons, separators and progress bars stay this far from the bar's top
-- (below its line) and bottom
local BASE_INSET = 3
local BASE_PROGRESS_W = 100
local HINT_Z = 2200

local ALIGNS = { left = true, center = true, right = true }

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _make_box(parent)
    local box = Turbine.UI.Control()
    box:SetParent(parent)
    box:SetMouseVisible(false)
    _set_blend(box)
    return box
end

local function _make_label(parent)
    local label = LuiLabel()
    label:SetParent(parent)
    label:SetMultiline(false)
    label:SetSelectable(false)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    return label
end

local function _options(opts)
    if opts == nil then
        return {}
    end
    return opts
end

local function _align(opts)
    if opts.align == nil then
        return "left"
    end
    return opts.align
end

-- ------------------------------------------------------------ items ----

-- a status bar entry; the window's user keeps it to change it later
local StatusItem = class()

function StatusItem:Constructor(window, kind, align, control)
    if ALIGNS[align] ~= true then
        error("Status bar align must be left, center or right, got " .. tostring(align))
    end
    self._window = window
    self._kind = kind
    self._align = align
    self.control = control
    self._visible = true
    -- label: full text, its measured width, the text on screen (cut or not)
    self._text = nil
    self._text_w = 0
    self._shown_text = nil
    self._icon = nil
    -- progress: 0..1
    self._value = 0
    -- progress / control: unscaled width
    self._base_w = nil
    self._tooltip = nil
    self._on_click = nil
end

function StatusItem:_require(kind, method)
    if self._kind ~= kind then
        error("Status " .. self._kind .. " item has no " .. method)
    end
end

function StatusItem:set_text(text)
    self:_require("label", "set_text")
    self._text = tostring(text)
    self._text_w = self._window:_status_text_width(self._text)
    self._window:_layout_status_items()
end

function StatusItem:get_text()
    self:_require("label", "get_text")
    return self._text
end

function StatusItem:set_icon(icon)
    self:_require("icon", "set_icon")
    self._icon = icon
    self._window:_size_status_icon(self)
end

-- 0..1 (clamped); repaints the fill only
function StatusItem:set_value(value)
    self:_require("progress", "set_value")
    self._value = math.max(0, math.min(1, value))
    self._window:_fill_status_progress(self)
end

function StatusItem:set_tooltip(text)
    self._tooltip = text
end

function StatusItem:set_visible(visible)
    self._visible = visible == true
    self._window:_layout_status_items()
end

-- ------------------------------------------------------------- hints ---

-- one hint tooltip per window (status items, toast), made on first hover
function LuiWindow:_show_window_hint(control, text)
    if self._hint == nil then
        self._hint = LuiTooltip()
        self._hint:SetZOrder(HINT_Z)
    end
    self._hint:set_scale(self._scale)
    self._hint:SetFont(FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE * self._scale))
    self._hint:ShowFor(control, text)
end

function LuiWindow:_hide_window_hint()
    if self._hint ~= nil then
        self._hint:Hide()
    end
end

-- its tooltip, else its full text when the bar cut it
function LuiWindow:_status_hint_text(item)
    if item._tooltip ~= nil then
        return item._tooltip
    end
    if item._text ~= nil and item._shown_text ~= item._text then
        return item._text
    end
    return nil
end

function LuiWindow:_bind_status_item(item)
    local control = item.control
    control:SetMouseVisible(true)
    control.MouseEnter = function()
        local text = self:_status_hint_text(item)
        if text ~= nil then
            self:_show_window_hint(control, text)
        end
    end
    control.MouseLeave = function()
        self:_hide_window_hint()
    end
    control.MouseClick = function()
        if item._on_click ~= nil then
            item._on_click(item)
        end
    end
end

-- -------------------------------------------------------------- bar ----

function LuiWindow:_ensure_status_bar()
    if self._status_bar ~= nil then
        return
    end

    local bar = _make_box(self._inner)
    bar:SetVisible(false)
    self._status_bar = bar
    self._status_line = _make_box(bar)
    self._status_items = {}

    self._status_message = StatusItem(self, "label", "left", _make_label(bar))
    self._status_message.control:SetVisible(false)
    self:_bind_status_item(self._status_message)
    self._status_message_timer = LuiTimer(function()
        self:clear_status_message()
    end)

    self:_style_status_bar()
end

function LuiWindow:is_status_bar_visible()
    return self._status_visible
end

-- a normal window grows / shrinks by the bar so its content keeps its
-- size; a maximized one keeps filling the screen and its content gives /
-- takes the bar's height (refit through the window's resize handler)
function LuiWindow:set_status_bar_visible(visible)
    visible = visible == true
    if visible == self._status_visible then
        return
    end
    self:_ensure_status_bar()

    local delta = self:_header_bar_h()
    if visible ~= true then
        delta = -delta
        self:_hide_window_hint()
    end
    self._status_visible = visible
    self._status_bar:SetVisible(visible)
    -- explicit minimums were measured with the old chrome
    if self._minimum_height ~= nil then
        self._minimum_height = self._minimum_height + delta
    end

    if self:is_maximized() == true then
        -- restoring keeps the content size too
        if self._restore_window_h ~= nil then
            self._restore_window_h = self._restore_window_h + delta
        end
        self:_fire_size_changed()
        return
    end

    local width, height = self:GetSize()
    self:SetSize(width, height + delta)
    self:_bound_to_screen()
    if self:GetHeight() ~= height + delta then
        -- the screen clamped it: the content changed size after all
        self:_fire_size_changed()
        return
    end
    self:_layout()
end

-- runs the window's resize handler (LuiWindow:_layout plus whatever the
-- subclass refits); the event field is a function or a callback list
function LuiWindow:_fire_size_changed()
    local handler = self.SizeChanged
    if type(handler) == "function" then
        handler(self, {})
        return
    end
    for i = 1, #handler do
        handler[i](self, {})
    end
end

-- height the bar takes from the window (0 when hidden)
function LuiWindow:_status_bar_h()
    if self._status_visible ~= true then
        return 0
    end
    return self:_header_bar_h()
end

function LuiWindow:_status_line_h()
    return math.max(1, _scaled_int(self._scale, Style.BORDER_WIDTH_THIN))
end

function LuiWindow:_status_inset()
    return _scaled_int(self._scale, BASE_INSET)
end

function LuiWindow:_status_icon_size()
    local item_h = self:_header_bar_h() - self:_status_line_h()
    return math.max(0, item_h - (2 * self:_status_inset()))
end

-- +2: glyph edges, as the header measures its title
function LuiWindow:_status_text_width(text)
    return Utils.measure_text_width_in_font(text, self._status_font) + 2
end

function LuiWindow:_style_status_bar()
    self._status_font = FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE * self._scale)
    self._status_bar:SetBackColor(Style.STATUS_BAR_BACKGROUND)
    self._status_line:SetBackColor(Style.SEPARATOR)
    self:_style_status_item(self._status_message)
    local items = self._status_items
    for i = 1, #items do
        self:_style_status_item(items[i])
    end
end

function LuiWindow:_style_status_item(item)
    local kind = item._kind
    if kind == "label" then
        item.control:SetFont(self._status_font)
        item.control:SetForeColor(Style.INFO_FOREGROUND)
        -- set again by the next layout
        item._shown_text = nil
        if item._text ~= nil then
            item._text_w = self:_status_text_width(item._text)
        end
    elseif kind == "icon" then
        self:_size_status_icon(item)
    elseif kind == "separator" then
        item.control:SetBackColor(Style.SEPARATOR)
    elseif kind == "progress" then
        item.control:SetBackColor(Style.CONTROL_BORDER)
        item._trough:SetBackColor(Style.CONTROL_BACKGROUND)
        item._fill:SetBackColor(Style.SELECTION_BACKGROUND)
    end
end

function LuiWindow:_size_status_icon(item)
    local size = self:_status_icon_size()
    item.control:set_icon(item._icon, size, size)
end

function LuiWindow:_fill_status_progress(item)
    local width, height = item.control:GetSize()
    local edge = self:_status_line_h()
    local inner_w = math.max(0, width - (2 * edge))
    local inner_h = math.max(0, height - (2 * edge))
    item._trough:SetPosition(edge, edge)
    item._trough:SetSize(inner_w, inner_h)
    item._fill:SetPosition(0, 0)
    item._fill:SetSize(math.floor((inner_w * item._value) + 0.5), inner_h)
end

-- -------------------------------------------------------------- add ----

function LuiWindow:_add_status_item(item, opts)
    item._tooltip = opts.tooltip
    item._on_click = opts.on_click
    local items = self._status_items
    items[#items + 1] = item
    self:_style_status_item(item)
    self:_layout_status_items()
    return item
end

-- opts: align ("left" default, "center", "right"), tooltip, on_click(item)
function LuiWindow:add_status_label(text, opts)
    opts = _options(opts)
    self:_ensure_status_bar()
    local item = StatusItem(self, "label", _align(opts), _make_label(self._status_bar))
    item._text = tostring(text)
    self:_bind_status_item(item)
    return self:_add_status_item(item, opts)
end

function LuiWindow:add_status_icon(icon, opts)
    opts = _options(opts)
    self:_ensure_status_bar()
    local image = Image()
    image:SetParent(self._status_bar)
    local item = StatusItem(self, "icon", _align(opts), image)
    item._icon = icon
    self:_bind_status_item(item)
    return self:_add_status_item(item, opts)
end

-- a thin vertical line
function LuiWindow:add_status_separator(opts)
    opts = _options(opts)
    self:_ensure_status_bar()
    local item = StatusItem(self, "separator", _align(opts), _make_box(self._status_bar))
    return self:_add_status_item(item, opts)
end

-- opts.width: unscaled px (default 100); opts.value: 0..1
function LuiWindow:add_status_progress(opts)
    opts = _options(opts)
    self:_ensure_status_bar()
    local frame = _make_box(self._status_bar)
    local item = StatusItem(self, "progress", _align(opts), frame)
    item._trough = _make_box(frame)
    item._fill = _make_box(item._trough)
    item._base_w = BASE_PROGRESS_W
    if opts.width ~= nil then
        item._base_w = opts.width
    end
    if opts.value ~= nil then
        item._value = math.max(0, math.min(1, opts.value))
    end
    self:_bind_status_item(item)
    return self:_add_status_item(item, opts)
end

-- any control, opts.width unscaled px (required); it keeps its own mouse
-- handlers, so no tooltip / on_click here
function LuiWindow:add_status_control(control, opts)
    if opts == nil or opts.width == nil then
        error("add_status_control needs opts.width (unscaled px)")
    end
    if opts.tooltip ~= nil or opts.on_click ~= nil then
        error("add_status_control: the control handles its own tooltip / clicks")
    end
    self:_ensure_status_bar()
    control:SetParent(self._status_bar)
    local item = StatusItem(self, "control", _align(opts), control)
    item._base_w = opts.width
    return self:_add_status_item(item, opts)
end

function LuiWindow:remove_status_item(item)
    local items = self._status_items
    for i = 1, #items do
        if items[i] == item then
            table.remove(items, i)
            self:_hide_window_hint()
            -- hidden before detaching: a detached control draws at the origin
            item.control:SetVisible(false)
            item.control:SetParent(nil)
            self:_layout_status_items()
            return
        end
    end
    error("Status item is not in this window's status bar")
end

-- ---------------------------------------------------------- message ----

-- a temporary message in place of the left group; seconds nil = until
-- cleared
function LuiWindow:show_status_message(text, seconds)
    self:_ensure_status_bar()
    local message = self._status_message
    message._text = tostring(text)
    message._text_w = self:_status_text_width(message._text)
    if seconds ~= nil then
        self._status_message_timer:start(seconds)
    else
        self._status_message_timer:stop()
    end
    self:_layout_status_items()
end

function LuiWindow:clear_status_message()
    self._status_message_timer:stop()
    self._status_message._text = nil
    self._status_message.control:SetVisible(false)
    self:_layout_status_items()
end

-- placing the items: needs the methods above
import "LUI.src.UI.Widgets.window_status_layout"
