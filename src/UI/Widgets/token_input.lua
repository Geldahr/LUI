-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- TokenInput: a one-line input that turns typed text into removable tokens
-- (chips). Enter adds the typed text as a token. Set by the owner:
--   set_leading_icon(name)          decoration in front (Widgets.Icons name)
--   set_placeholder(text)           shown when there is no token and no text
--   set_popup_host(window)          host window for the click-away catcher
-- Optional callbacks:
--   TokensChanged(sender)           tokens added / removed / cleared
--   Suggestions(sender, text)       current bar text -> items, from, to
--       items: { text = row text, value = inserted when picked,
--                icon = optional Widgets.Icons name (menu icon column),
--                hint = optional right-hand text,
--                final = true when the pick completes the field text }
--       from, to: character range of `text` that `value` replaces; text
--       after `to` is kept. No range = the whole text; no `to` = to the end.
--   FormatToken(sender, token)      -> icon_name_or_nil, label
-- Chips that do not fit scroll (mouse wheel) behind "< +N" / "> +N" markers;
-- clicking a marker lists the hidden chips. The suggestion list opens when
-- typing (or on double-click with an empty field); Up/Down move, Enter or a
-- click picks; Enter with no list adds the token.

local LUI = _G.LUI
local UI = LUI.UI
local Utils = LUI.Utils
local class = LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.native_scaling"
import "LUI.src.UI.Widgets.style"
import "LUI.src.UI.Widgets.icons"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.button"
import "LUI.src.UI.Widgets.menu"
import "LUI.src.UI.Widgets.base_window"
import "LUI.src.Utils.font"
import "LUI.src.Utils.text_width"

local Widgets = UI.Widgets
local Style = Widgets.Style
local Icons = Widgets.Icons
local Image = Widgets.Image
local LuiLabel = Widgets.LuiLabel
local LuiButton = Widgets.LuiButton
local LuiMenu = Widgets.LuiMenu
local FONT_TO_LOTRO = Utils.FONT_TO_LOTRO
local measure_text_width = Utils.measure_text_width

---@class TokenInput : Turbine.UI.Control
local TokenInput = class(Turbine.UI.Control)
Widgets.TokenInput = TokenInput

-- base sizes (scaled): COMPACT matches the 22px search / filter rows, LARGE
-- is a roomier 30px bar; both even so the 1px border leaves an even inner
TokenInput.COMPACT = {
    bar = 22, chip = 17, gap = 4, chip_pad = 5, lead = 13, lead_x = 5, lead_w = 22,
    marker_w = 30, marker_icon = 10, chip_icon = 11, chip_icon_w = 15,
    close_btn = 13, close_icon = 7, close_w = 16, clear_btn = 19, clear_icon = 10, clear_w = 24,
    text_h = 17, font = 0, edge = 4,
}
TokenInput.LARGE = {
    bar = 30, chip = 22, gap = 5, chip_pad = 6, lead = 16, lead_x = 7, lead_w = 28,
    marker_w = 34, marker_icon = 12, chip_icon = 14, chip_icon_w = 18,
    close_btn = 16, close_icon = 9, close_w = 20, clear_btn = 24, clear_icon = 12, clear_w = 32,
    text_h = 20, font = 1, edge = 6,
}

local MIN_TEXT_W = 100
-- key actions a focused TextBox receives (measured in game)
local ACTION_UP = 29
local ACTION_DOWN = 113

local function _set_alpha_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _trim(text)
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

-- size for an item centred in `area`: same parity, so the space above and
-- below is identical (no 1px/2px split)
local function _fit(value, area)
    if (area - value) % 2 ~= 0 then
        return value - 1
    end
    return value
end

-- a detached control is still drawn at the screen origin: hide first
local function _discard(control)
    control:SetVisible(false)
    control:SetParent(nil)
end

local function _popup_window()
    local window = Turbine.UI.Window()
    UI.NativeScaling.apply_window(window)
    window:SetVisible(false)
    window:SetZOrder(3000)
    _set_alpha_blend(window)
    window:SetBackColor(Style.CONTROL_BORDER)
    local inner = Turbine.UI.Control()
    inner:SetParent(window)
    inner:SetPosition(1, 1)
    _set_alpha_blend(inner)
    inner:SetBackColor(Style.PANEL_BACKGROUND)
    inner:SetMouseVisible(false)
    return window, inner
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TokenInput:Constructor()
    Turbine.UI.Control.Constructor(self)
    _set_alpha_blend(self)
    self:SetMouseVisible(true)

    self.TokensChanged = nil
    self.Suggestions = nil
    self.FormatToken = nil

    self._scale = 1
    self._variant = TokenInput.COMPACT
    self._width = 200
    self._tokens = {} -- { text, icon, label, width }
    self._lead_icon = nil
    self._placeholder = ""
    self._host = nil

    self._first_visible = nil -- nil = follow the newest token
    self._shown_first = 1
    self._hidden = { left = {}, right = {} }
    self._chip_controls = {}
    self._overflow_side = nil
    self._overflow_chips = {}
    self._suggest_from = nil
    self._suggest_to = nil
    self._completed_text = nil
    -- true while the widget sets the field text itself (no TextChanged work)
    self._setting_text = false
    self._overflow_open = false
    self._pending_refresh = false

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetPosition(1, 1)
    _set_alpha_blend(self._inner)
    self._inner:SetMouseVisible(false)

    self._lead = Image()
    self._lead:SetParent(self)
    self._lead:SetVisible(false)

    self._chip_layer = Turbine.UI.Control()
    self._chip_layer:SetParent(self)
    self._chip_layer:SetMouseVisible(false)

    self._left_marker = self:_make_marker("chevron_left", "left")
    self._right_marker = self:_make_marker("chevron_right", "right")

    self._text_box = Turbine.UI.TextBox()
    self._text_box:SetParent(self)
    _set_alpha_blend(self._text_box)
    self._text_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self._placeholder_label = LuiLabel()
    self._placeholder_label:SetParent(self)
    self._placeholder_label:SetMouseVisible(false)
    self._placeholder_label:SetMultiline(false)
    self._placeholder_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self._clear = LuiButton()
    self._clear:SetParent(self)
    self._clear.Click = function()
        self:clear()
    end

    self._overflow, self._overflow_inner = _popup_window()
    -- suggestions are a regular LuiMenu (same look and dismissal as every
    -- menu), opened under the text box without taking the keyboard focus
    self._menu = LuiMenu()
    self._menu:SetParent(self)
    self._menu:SetVisible(false)

    -- click-away catcher (as LuiDropdown): an invisible control over the
    -- host window's content; the lists are windows above it
    self._click_away = Turbine.UI.Control()
    self._click_away:SetMouseVisible(true)
    self._click_away:SetZOrder(9999)
    self._click_away:SetVisible(false)
    self._click_away.MouseDown = function(_, args)
        self:_close_lists()
        -- a click on the bar is not "outside": keep typing there
        local sx, sy = self._click_away:PointToScreen(args.X, args.Y)
        local bx, by = self:PointToScreen(0, 0)
        local w, h = self:GetSize()
        if sx >= bx and sx < bx + w and sy >= by and sy < by + h then
            self._text_box:Focus()
        end
    end

    self:_wire_events()
    self:_apply_style()
    self:_layout()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TokenInput:set_scale(scale)
    self._scale = scale
    self._menu:set_scale(scale)
    self:_remeasure_tokens()
    self:_apply_style()
    self:_layout()
end

-- TokenInput.COMPACT or TokenInput.LARGE
function TokenInput:set_variant(variant)
    self._variant = variant
    self:_remeasure_tokens()
    self:_apply_style()
    self:_layout()
end

-- the height follows the variant and scale (always even); only the width
-- is taken from the caller
function TokenInput:SetSize(w, _)
    self._width = w
    self:_layout()
end

function TokenInput:SetWidth(w)
    self:SetSize(w)
end

function TokenInput:get_height()
    return self:_bar_height()
end

function TokenInput:set_popup_host(host)
    self._host = host
    self._click_away:SetParent(host)
end

function TokenInput:set_leading_icon(icon_name)
    self._lead_icon = icon_name
    self:_apply_style()
    self:_layout()
end

function TokenInput:set_placeholder(text)
    self._placeholder = text
    self._placeholder_label:SetText(text)
end

-- call after assigning FormatToken when tokens already exist
function TokenInput:refresh_tokens()
    self:_remeasure_tokens()
    self:_layout()
end

function TokenInput:get_tokens()
    local out = {}
    for i = 1, #self._tokens do
        out[i] = self._tokens[i].text
    end
    return out
end

-- replaces all tokens; fires TokensChanged only when fire_event is true
function TokenInput:set_tokens(texts, fire_event)
    self._tokens = {}
    for i = 1, #texts do
        self._tokens[i] = self:_make_token(texts[i])
    end
    self._first_visible = nil
    self:_layout()
    if fire_event == true then
        self:_fire_changed()
    end
end

function TokenInput:add_token(text)
    self._tokens[#self._tokens + 1] = self:_make_token(text)
    self._first_visible = nil
    self:_layout()
    self:_fire_changed()
end

function TokenInput:remove_token(index)
    table.remove(self._tokens, index)
    self:_layout()
    self:_fire_changed()
end

function TokenInput:clear()
    self._tokens = {}
    self._first_visible = nil
    self._completed_text = nil
    self:_close_lists()
    self:_set_field_text("")
    self:_layout()
    self:_fire_changed()
end

function TokenInput:Focus()
    self._text_box:Focus()
end

function TokenInput:destroy()
    self:_close_lists()
    self:SetWantsUpdates(false)
    _discard(self._click_away)
    _discard(self._overflow)
end

---------------------------------------------------------------------
-- Private: tokens
---------------------------------------------------------------------

function TokenInput:_fire_changed()
    if type(self.TokensChanged) == "function" then
        self:TokensChanged()
    end
end

function TokenInput:_s(value)
    return math.floor((value * self._scale) + 0.5)
end

function TokenInput:_small_font_size()
    return Style.CONTENT_SMALL_FONT_SIZE + self._variant.font
end

function TokenInput:_font(size)
    local font = FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, size * self._scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(Style.CONTROL_FONT_NAME) .. " " .. tostring(size))
    end
    return font
end

-- formatted once per token (and again on scale/variant/formatter change),
-- so layouts never re-measure
function TokenInput:_make_token(text)
    local icon, label = nil, text
    if type(self.FormatToken) == "function" then
        icon, label = self:FormatToken(text)
    end
    local v = self._variant
    -- measured advances of the chip label font, +2 for glyph edges
    local text_w = measure_text_width(label, Style.CONTROL_FONT_NAME, self:_small_font_size() * self._scale) + 2
    local icon_w = icon ~= nil and self:_s(v.chip_icon_w) or 0
    return {
        text = text,
        icon = icon,
        label = label,
        label_w = text_w,
        width = self:_s(v.chip_pad) + icon_w + text_w + self:_s(v.close_w),
    }
end

function TokenInput:_remeasure_tokens()
    for i = 1, #self._tokens do
        self._tokens[i] = self:_make_token(self._tokens[i].text)
    end
end

---------------------------------------------------------------------
-- Private: building blocks
---------------------------------------------------------------------

function TokenInput:_bar_height()
    local h = self:_s(self._variant.bar)
    if h % 2 ~= 0 then
        h = h + 1
    end
    return h
end

function TokenInput:_chip_height()
    return _fit(self:_s(self._variant.chip), self:_bar_height())
end

function TokenInput:_label(parent, text, x, y, w, h, color)
    local label = LuiLabel()
    label:SetParent(parent)
    label:SetPosition(x, y)
    label:SetSize(w, h)
    label:SetFont(self:_font(self:_small_font_size()))
    label:SetForeColor(color)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    -- one line: a too-narrow label must clip, never wrap
    label:SetMultiline(false)
    label:SetText(text)
    label:SetMouseVisible(false)
    return label
end

function TokenInput:_icon(parent, name, size, x, y)
    local image = Image(Icons.path(name), size)
    image:SetParent(parent)
    image:SetPosition(x, y)
    image:set_tint(Style.ICON_FOREGROUND)
    return image
end

function TokenInput:_flat_button(parent, x, y, size, icon_size)
    local button = LuiButton()
    button:SetParent(parent)
    button:set_scale(self._scale)
    button:SetPosition(x, y)
    button:SetSize(size, size)
    button:set_tinted_icon(Icons.path("window_close"), icon_size)
    Style.apply_transparent_button(button)
    button:set_hover_back_color(Style.ACCENT_BACKGROUND_DISABLED)
    return button
end

function TokenInput:_make_marker(icon_name, side)
    local marker = Turbine.UI.Control()
    marker:SetParent(self)
    marker:SetMouseVisible(true)
    _set_alpha_blend(marker)
    marker:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    marker:SetVisible(false)
    marker._icon_name = icon_name
    marker._side = side
    marker.MouseEnter = function()
        marker._hover = true
        self:_paint_marker(marker)
    end
    marker.MouseLeave = function()
        marker._hover = false
        self:_paint_marker(marker)
    end
    marker.MouseClick = function()
        if self._overflow_side == side then
            self._overflow_side = nil
        else
            self._overflow_side = side
        end
        self:_refresh_overflow()
    end
    marker.MouseWheel = function(_, args)
        self:_on_wheel(args)
    end
    return marker
end

-- chip-sized marker content, rebuilt on style/scale changes
function TokenInput:_build_marker_content(marker)
    if marker._content ~= nil then
        _discard(marker._content)
    end
    local chip_h = self:_chip_height()
    local w = self:_s(self._variant.marker_w)
    marker:SetSize(w, chip_h)
    local content = Turbine.UI.Control()
    content:SetParent(marker)
    content:SetSize(w, chip_h)
    content:SetMouseVisible(false)
    local icon_size = _fit(self:_s(self._variant.marker_icon), chip_h)
    self:_icon(content, marker._icon_name, icon_size, self:_s(5), (chip_h - icon_size) / 2)
    marker._label = self:_label(content, "", self:_s(5) + icon_size, 0, w - self:_s(5) - icon_size, chip_h,
        Style.CONTROL_FOREGROUND)
    marker._content = content
end

function TokenInput:_paint_marker(marker)
    if self._overflow_side == marker._side then
        marker:SetBackColor(Style.CONTROL_BACKGROUND_ACTIVE)
    elseif marker._hover == true then
        marker:SetBackColor(Style.CONTROL_BACKGROUND_HOVER)
    else
        marker:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    end
end

function TokenInput:_apply_style()
    local v = self._variant
    local h = self:_bar_height()
    self:SetBackColor(Style.CONTROL_BORDER)
    self._inner:SetBackColor(Style.ALTERNATE_BACKGROUND)

    self._text_box:SetFont(self:_font(Style.CONTROL_FONT_SIZE))
    self._text_box:SetForeColor(Style.CONTROL_FOREGROUND)
    -- same color as the bar; a transparent TextBox shows the 3D world
    self._text_box:SetBackColor(Style.ALTERNATE_BACKGROUND)

    self._placeholder_label:SetFont(self:_font(self:_small_font_size()))
    self._placeholder_label:SetForeColor(Style.PLACEHOLDER_FOREGROUND)

    if self._lead_icon ~= nil then
        local size = _fit(self:_s(v.lead), h)
        self._lead:set_icon(Icons.path(self._lead_icon), size)
        self._lead:set_tint(Style.ICON_FOREGROUND)
        self._lead:SetPosition(self:_s(v.lead_x), (h - size) / 2)
        self._lead:SetVisible(true)
    else
        self._lead:SetVisible(false)
    end

    local clear_size = _fit(self:_s(v.clear_btn), h)
    self._clear:set_scale(self._scale)
    self._clear:SetSize(clear_size, clear_size)
    self._clear:set_tinted_icon(Icons.path("window_close"), v.clear_icon)
    Style.apply_transparent_button(self._clear)
    self._clear:set_hover_back_color(Style.ACCENT_BACKGROUND_DISABLED)

    self:_build_marker_content(self._left_marker)
    self:_build_marker_content(self._right_marker)
end

function TokenInput:_make_chip(index, parent, x, y, full_width)
    local token = self._tokens[index]
    local v = self._variant
    local chip_h = self:_chip_height()
    local w = full_width or token.width

    local chip = Turbine.UI.Control()
    chip:SetParent(parent)
    chip:SetPosition(x, y)
    chip:SetSize(w, chip_h)
    _set_alpha_blend(chip)
    chip:SetBackColor(Style.CONTROL_BACKGROUND)

    local tx = self:_s(v.chip_pad)
    if token.icon ~= nil then
        local icon_size = _fit(self:_s(v.chip_icon), chip_h)
        self:_icon(chip, token.icon, icon_size, tx, (chip_h - icon_size) / 2)
        tx = tx + self:_s(v.chip_icon_w)
    end
    self:_label(chip, token.label, tx, 0, token.label_w, chip_h, Style.CONTROL_FOREGROUND)

    local close = _fit(self:_s(v.close_btn), chip_h)
    local remove = self:_flat_button(chip, w - close - self:_s(3), (chip_h - close) / 2, close, v.close_icon)
    remove.Click = function()
        self:remove_token(index)
    end
    if parent == self._chip_layer then
        local wheel = function(_, args)
            self:_on_wheel(args)
        end
        chip.MouseWheel = wheel
        remove.MouseWheel = wheel
    end
    return chip
end

---------------------------------------------------------------------
-- Private: layout
---------------------------------------------------------------------

-- tokens from `first` that fit in `space`
function TokenInput:_fit_from(first, space)
    local gap = self:_s(self._variant.gap)
    local used = 0
    local last = first - 1
    for i = first, #self._tokens do
        local add = self._tokens[i].width + (i > first and gap or 0)
        if used + add > space and i > first then
            break
        end
        used = used + add
        last = i
    end
    return last
end

function TokenInput:_layout()
    local v = self._variant
    local w = self._width
    local h = self:_bar_height()
    Turbine.UI.Control.SetSize(self, w, h)
    self._inner:SetSize(math.max(0, w - 2), h - 2)
    self._chip_layer:SetSize(w, h)

    for i = 1, #self._chip_controls do
        _discard(self._chip_controls[i])
    end
    self._chip_controls = {}

    local gap = self:_s(v.gap)
    local marker_w = self:_s(v.marker_w)
    local chip_h = self:_chip_height()
    local chip_y = (h - chip_h) / 2
    local chips_x = self._lead_icon ~= nil and self:_s(v.lead_w) or self:_s(v.edge)
    local clear_w = self:_s(v.clear_w)
    local count = #self._tokens

    local space = w - chips_x - clear_w - self:_s(MIN_TEXT_W)
    local first = 1
    local last = self:_fit_from(1, space)
    if last < count then
        -- not everything fits: room for both markers, then pick the window
        local window_space = space - (2 * (marker_w + gap))
        if self._first_visible == nil then
            first = count
            local total = self._tokens[first].width
            while first > 1 and total + gap + self._tokens[first - 1].width <= window_space do
                first = first - 1
                total = total + gap + self._tokens[first].width
            end
        else
            first = math.max(1, math.min(self._first_visible, count))
        end
        last = self:_fit_from(first, window_space)
    end
    self._shown_first = first

    local x = chips_x
    self._left_marker:SetVisible(first > 1)
    if first > 1 then
        self._left_marker:SetPosition(x, chip_y)
        self._left_marker._label:SetText("+" .. tostring(first - 1))
        x = x + marker_w + gap
    end
    for i = first, last do
        self._chip_controls[#self._chip_controls + 1] = self:_make_chip(i, self._chip_layer, x, chip_y)
        x = x + self._tokens[i].width + gap
    end
    self._hidden.left = {}
    for i = 1, first - 1 do
        self._hidden.left[#self._hidden.left + 1] = i
    end
    self._hidden.right = {}
    for i = last + 1, count do
        self._hidden.right[#self._hidden.right + 1] = i
    end
    self._right_marker:SetVisible(last < count)
    if last < count then
        self._right_marker:SetPosition(x, chip_y)
        self._right_marker._label:SetText("+" .. tostring(count - last))
        x = x + marker_w
    end

    local tx = x + self:_s(2)
    local text_h = _fit(self:_s(v.text_h), h)
    self._text_box:SetPosition(tx, (h - text_h) / 2)
    self._text_box:SetSize(math.max(0, w - tx - clear_w), text_h)
    self._placeholder_label:SetPosition(tx, 0)
    self._placeholder_label:SetSize(math.max(0, w - tx - clear_w), h)
    self:_sync_placeholder()

    local clear_size = self._clear:GetWidth()
    self._clear:SetPosition(w - clear_size - self:_s(4), (h - clear_size) / 2)

    if self._overflow_side ~= nil then
        self:_refresh_overflow()
    end
end

function TokenInput:_sync_placeholder()
    self._placeholder_label:SetVisible(#self._tokens == 0 and (self._text_box:GetText() or "") == "")
end

function TokenInput:_on_wheel(args)
    if #self._hidden.left == 0 and #self._hidden.right == 0 then
        return
    end
    self._first_visible = math.max(1, math.min(self._shown_first - args.Direction, #self._tokens))
    self:_layout()
end

---------------------------------------------------------------------
-- Private: lists (overflow + suggestions)
---------------------------------------------------------------------

-- per-frame work only while needed: a deferred suggestion refresh, and
-- while a list is open, closing it once the bar is no longer on screen
-- (window hidden by Escape, tab switched, global UI hide...)
function TokenInput:_sync_updates()
    self:SetWantsUpdates(self._pending_refresh == true or self._menu:is_open() == true or self._overflow_open == true)
end

function TokenInput:_sync_click_away()
    if self._overflow_open == true then
        -- leave a LuiWindow's title bar usable (close, maximize, drag)
        local x, y, w, h = Widgets.popup_catcher_rect(self._host)
        self._click_away:SetPosition(x, y)
        self._click_away:SetSize(w, h)
        self._click_away:SetVisible(true)
    else
        self._click_away:SetVisible(false)
    end
    self:_sync_updates()
end

function TokenInput:_close_lists()
    self:_close_suggest()
    self:_close_overflow()
end

function TokenInput:_close_overflow()
    for i = 1, #self._overflow_chips do
        _discard(self._overflow_chips[i])
    end
    self._overflow_chips = {}
    self._overflow_side = nil
    self._overflow:SetVisible(false)
    self._overflow_open = false
    self:_sync_click_away()
    self:_paint_marker(self._left_marker)
    self:_paint_marker(self._right_marker)
end

function TokenInput:_refresh_overflow()
    local side = self._overflow_side
    local indexes = side ~= nil and self._hidden[side] or {}
    if side == nil or #indexes == 0 then
        self:_close_overflow()
        return
    end
    for i = 1, #self._overflow_chips do
        _discard(self._overflow_chips[i])
    end
    self._overflow_chips = {}

    local chip_h = self:_chip_height()
    local gap = self:_s(self._variant.gap)
    local pad = self:_s(5)
    -- every row as wide as the widest hidden chip
    local width = 0
    for k = 1, #indexes do
        width = math.max(width, self._tokens[indexes[k]].width)
    end
    for k = 1, #indexes do
        self._overflow_chips[k] = self:_make_chip(indexes[k], self._overflow_inner, pad,
            pad + (k - 1) * (chip_h + gap), width)
    end
    local inner_w = width + 2 * pad
    local inner_h = #indexes * chip_h + (#indexes - 1) * gap + 2 * pad
    self._overflow_inner:SetSize(inner_w, inner_h)
    self._overflow:SetSize(inner_w + 2, inner_h + 2)
    local marker = side == "left" and self._left_marker or self._right_marker
    local sx, sy = marker:PointToScreen(0, chip_h + self:_s(6))
    self._overflow:SetPosition(sx, sy)
    self._overflow:SetVisible(true)
    self._overflow_open = true
    -- the list is a fixed screen window: close it once the bar moves
    self._overflow_screen_x, self._overflow_screen_y = self:PointToScreen(0, 0)
    self:_sync_click_away()
    self:_paint_marker(self._left_marker)
    self:_paint_marker(self._right_marker)
end

function TokenInput:_close_suggest()
    self._menu:close()
    self:_sync_updates()
end

function TokenInput:_open_suggest(entries, from, to)
    self._menu:clear_items()
    if #entries == 0 then
        self:_sync_updates()
        return
    end
    self._suggest_from = from
    self._suggest_to = to
    for _, entry in ipairs(entries) do
        local icon = nil
        if entry.icon ~= nil then
            icon = Icons.path(entry.icon)
        end
        self._menu:add_action({
            text = entry.text,
            hint = entry.hint,
            icon = icon,
            icon_tinted = true,
            action = function()
                self:_pick(entry, self._text_box:GetText() or "")
            end,
        })
    end
    self._menu:open_below(self._text_box)
    self:_sync_updates()
end

-- an empty field only lists suggestions on request (double-click); typing,
-- or a pick that continues, opens the list by itself
function TokenInput:_refresh_suggest(requested)
    if type(self.Suggestions) ~= "function" then
        return
    end
    local text = self._text_box:GetText() or ""
    if (self._completed_text ~= nil and text == self._completed_text)
        or (_trim(text) == "" and requested ~= true) then
        self:_close_suggest()
        return
    end
    self:_open_suggest(self:Suggestions(text))
end

-- a pick happens inside a row click (or the Enter TextChanged), where
-- SetText does not reliably fire TextChanged: refresh on the next frame
function TokenInput:_refresh_suggest_later()
    self._pending_refresh = true
    self:_sync_updates()
end

-- `text` with the suggestion range replaced by `value`; returns the new
-- text and the caret position right after the inserted value
local function _replace_range(text, value, from, to)
    if from == nil then
        return value, string.len(value) + 1
    end
    if to == nil then
        to = string.len(text)
    end
    local head = string.sub(text, 1, from - 1)
    return head .. value .. string.sub(text, to + 1), string.len(head) + string.len(value) + 1
end

-- sets the field text without running the TextChanged handling
function TokenInput:_set_field_text(text)
    self._setting_text = true
    self._text_box:SetText(text)
    self._setting_text = false
end

function TokenInput:_pick(entry, text)
    local value, caret = _replace_range(text, entry.value, self._suggest_from, self._suggest_to)
    if entry.final == true then
        self._completed_text = value
    end
    self:_set_field_text(value)
    self._text_box:Focus()
    self._text_box:SetSelection(caret, 0)
    self._placeholder_label:SetVisible(false)
    self:_refresh_suggest_later()
end

---------------------------------------------------------------------
-- Private: events
---------------------------------------------------------------------

function TokenInput:_wire_events()
    local wheel = function(_, args)
        self:_on_wheel(args)
    end
    self.MouseWheel = wheel
    self._text_box.MouseWheel = wheel
    self._clear.MouseWheel = wheel

    self.MouseClick = function()
        self._text_box:Focus()
    end
    local open_on_request = function()
        self._text_box:Focus()
        self:_refresh_suggest(true)
    end
    self.MouseDoubleClick = open_on_request
    self._text_box.MouseDoubleClick = open_on_request

    self.Update = function()
        if self._pending_refresh == true then
            self._pending_refresh = false
            self:_refresh_suggest()
        end
        if (self._menu:is_open() == true or self._overflow_open == true) and self:IsDisplayed() ~= true then
            self:_close_lists()
        elseif self._overflow_open == true then
            local x, y = self:PointToScreen(0, 0)
            if x ~= self._overflow_screen_x or y ~= self._overflow_screen_y then
                self:_close_overflow()
            end
        end
        self:_sync_updates()
    end

    self._text_box:SetWantsKeyEvents(true)
    self._text_box.KeyDown = function(_, args)
        if self._menu:is_open() ~= true then
            return
        end
        if args.Action == ACTION_UP then
            self._menu:move_highlight(-1)
        elseif args.Action == ACTION_DOWN then
            self._menu:move_highlight(1)
        end
    end

    self._text_box.TextChanged = function()
        if self._setting_text == true then
            return
        end
        local text = self._text_box:GetText() or ""
        if string.find(text, "\n", 1, true) ~= nil then
            local value = _trim(string.gsub(text, "\n", ""))
            -- Enter with an open list picks the highlighted entry
            if self._menu:is_open() == true then
                -- the field text without the newline Enter inserted, then
                -- the highlighted suggestion is picked from it
                local current = string.gsub(text, "\n", "")
                self:_set_field_text(current)
                self._menu:trigger_highlight()
                return
            end
            self:_set_field_text("")
            self:_close_suggest()
            self._completed_text = nil
            if value ~= "" then
                self:add_token(value)
            else
                self:_layout()
            end
            return
        end
        self:_sync_placeholder()
        self:_refresh_suggest()
    end
end
