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
--   KeywordOf(sender, text)         -> key of the keyword `text` starts
--       with (nil for plain text), and its value (nil when empty)
-- Double-clicking a chip puts its text back in the field for editing (Enter
-- adds it again). The bar shows the newest chips; older ones that do not
-- fit hide behind a "< +N" marker, which lists them on click. The suggestion list opens when
-- typing, on a click in the empty field, on Down, or on double-click;
-- Up/Down move, Enter or a click picks the highlighted entry. Only a
-- keyword's values start highlighted: over plain text, Enter adds the
-- typed text (Down first to pick a keyword). A keyword with no value
-- ("lvl:") is no token: Enter keeps it in the field.

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
import "LUI.src.UI.Widgets.tooltip"
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
local LuiTooltip = Widgets.LuiTooltip
local FONT_TO_LOTRO = Utils.FONT_TO_LOTRO
local measure_text_width = Utils.measure_text_width

---@class TokenInput : Turbine.UI.Control
local TokenInput = class(Turbine.UI.Control)
Widgets.TokenInput = TokenInput

-- base sizes (scaled): COMPACT matches the 22px search / filter rows; even
-- so the 1px border leaves an even inner
TokenInput.COMPACT = {
    bar = 22, chip = 17, gap = 4, chip_pad = 5, lead = 13, lead_x = 5, lead_w = 22,
    marker_w = 30, marker_icon = 10, chip_icon = 11, chip_icon_w = 15,
    close_btn = 13, close_icon = 7, close_w = 16, clear_btn = 19, clear_icon = 10, clear_w = 24,
    text_h = 17, font = 0, edge = 4,
}

local MIN_TEXT_W = 100
-- widest chip (a long label ends with ELLIPSIS), so a chip never takes
-- the text box's room on a usual bar
local MAX_CHIP_W = 220
local ELLIPSIS = "..."
-- one UTF-8 character (as the text measuring)
local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"
-- key actions a focused TextBox receives (measured in game)
local ACTION_UP = 29
local ACTION_DOWN = 113
-- Enter (EnterChatMode): arrives as KeyDown on a single-line TextBox only;
-- the client then enters chat mode, so the box takes the focus back on the
-- next frame
local ACTION_ENTER = 162

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
-- the overflow list shows at most this many chips, then scrolls
local OVERFLOW_MAX_ROWS = 12
-- the game scrollbar is drawn at a fixed width, never scaled (as LuiMenu)
local BASE_SCROLL_W = 10

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
    self.KeywordOf = nil

    self._scale = 1
    self._variant = TokenInput.COMPACT
    self._width = 200
    -- { text, icon, label, full_label, cut, label_w, width, chip, chip_w }:
    -- chip is the bar's control, built on first show and kept until the
    -- token goes
    self._tokens = {}
    -- full label of a cut chip on hover, created on the first one
    self._chip_hint = nil
    self._lead_icon = nil
    self._placeholder = ""
    self._host = nil

    -- first chip shown in the bar (the newest ones); the older ones are
    -- behind the marker
    self._shown_first = 1
    -- marker width, measured for this token count
    self._marker_w = nil
    self._marker_count = nil
    self._overflow_chips = {}
    self._suggest_from = nil
    self._suggest_to = nil
    -- entries the suggestion menu shows (compared on each refresh)
    self._suggest_entries = nil
    self._completed_text = nil
    -- true while the widget sets the field text itself (no TextChanged work)
    self._setting_text = false
    self._overflow_open = false
    self._pending_refresh = false
    self._pending_focus = false

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetPosition(1, 1)
    _set_alpha_blend(self._inner)
    self._inner:SetMouseVisible(false)

    self._lead = Image()
    self._lead:SetParent(self)
    self._lead:SetVisible(false)

    self._marker = self:_make_marker("chevron_left")

    self._text_box = Turbine.UI.TextBox()
    self._text_box:SetParent(self)
    _set_alpha_blend(self._text_box)
    -- one line: long text scrolls with the caret instead of wrapping onto a
    -- hidden second line (Enter comes through KeyDown, ACTION_ENTER)
    self._text_box:SetMultiline(false)
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
    -- hidden chips, one per row; scrolls past OVERFLOW_MAX_ROWS
    self._overflow_list = Turbine.UI.ListBox()
    self._overflow_list:SetParent(self._overflow_inner)
    self._overflow_scroll = Turbine.UI.Lotro.ScrollBar()
    self._overflow_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self._overflow_scroll:SetParent(self._overflow_inner)
    self._overflow_list:SetVerticalScrollBar(self._overflow_scroll)
    -- suggestions are a regular LuiMenu (same look and dismissal as every
    -- menu), opened under the text box without taking the keyboard focus
    self._menu = LuiMenu()
    self._menu:SetParent(self)
    self._menu:SetVisible(false)
    -- every suggestion is listed; long lists scroll
    self._menu:set_scroll_options({ scroll = true, max_visible = 12 })

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
    if self._chip_hint ~= nil then
        self._chip_hint:set_scale(scale)
    end
    self:_remeasure_tokens()
    self:_apply_style()
    self:_layout()
end

-- the height follows the variant and scale (always even); only the width
-- is taken from the caller. Window resizes call this every frame: the
-- chips are only moved (see _layout)
function TokenInput:SetSize(w, _)
    self._width = w
    self:_layout(true)
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
    self:_discard_chips()
    self._tokens = {}
    for i = 1, #texts do
        self._tokens[i] = self:_make_token(texts[i])
    end
    self:_layout()
    if fire_event == true then
        self:_fire_changed()
    end
end

function TokenInput:add_token(text)
    self._tokens[#self._tokens + 1] = self:_make_token(text)
    self:_layout()
    self:_fire_changed()
end

function TokenInput:remove_token(index)
    self:_drop_token(index)
    self:_layout()
    self:_fire_changed()
end

-- the token's text goes back into the field for editing; the token is
-- removed (TokensChanged) and Enter adds the edited text again
function TokenInput:edit_token(index)
    local text = self._tokens[index].text
    self:_drop_token(index)
    self:_close_lists()
    self:_set_field_text(text)
    self._text_box:Focus()
    self._text_box:SetSelection(string.len(text) + 1, 0)
    self:_layout()
    self:_fire_changed()
end

function TokenInput:clear()
    self:_discard_chips()
    self._tokens = {}
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
    self:_hide_chip_hint()
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

-- measured width of a chip label (the font the game draws at this
-- scale), +2 for glyph edges
function TokenInput:_label_width(label)
    return measure_text_width(label, Style.CONTROL_FONT_NAME, self:_small_font_size() * self._scale) + 2
end

-- `label` cut to the characters that fit `max_w` with ELLIPSIS after them
function TokenInput:_ellipsize(label, max_w)
    local size = self:_small_font_size() * self._scale
    local room = max_w - measure_text_width(ELLIPSIS, Style.CONTROL_FONT_NAME, size)
    local used = 0
    local cut = 0
    for position, ch in string.gmatch(label, "()(" .. UTF8_CHAR .. ")") do
        used = used + measure_text_width(ch, Style.CONTROL_FONT_NAME, size)
        if used > room then
            break
        end
        cut = position + string.len(ch) - 1
    end
    return _trim(string.sub(label, 1, cut)) .. ELLIPSIS
end

-- formatted once per token (and again on scale/variant/formatter change),
-- so layouts never re-measure. A label too long for MAX_CHIP_W ends with
-- ELLIPSIS.
function TokenInput:_make_token(text)
    local icon, label = nil, text
    if type(self.FormatToken) == "function" then
        icon, label = self:FormatToken(text)
    end
    local v = self._variant
    local text_w = self:_label_width(label)
    local icon_w = icon ~= nil and self:_s(v.chip_icon_w) or 0
    local frame_w = self:_s(v.chip_pad) + icon_w + self:_s(v.close_w)
    local max_label_w = self:_s(MAX_CHIP_W) - frame_w
    local full_label = label
    local cut = text_w > max_label_w
    if cut == true then
        label = self:_ellipsize(label, max_label_w - 2)
        text_w = self:_label_width(label)
    end
    return {
        text = text,
        icon = icon,
        label = label,
        full_label = full_label,
        cut = cut,
        label_w = text_w,
        width = frame_w + text_w,
        chip = nil,
        chip_w = nil,
    }
end

function TokenInput:_remeasure_tokens()
    self:_discard_chips()
    for i = 1, #self._tokens do
        self._tokens[i] = self:_make_token(self._tokens[i].text)
    end
end

-- the bar chips are rebuilt on the next layout (tokens replaced, or
-- remeasured for a new scale / formatter)
function TokenInput:_discard_chips()
    self:_hide_chip_hint()
    for i = 1, #self._tokens do
        local token = self._tokens[i]
        if token.chip ~= nil then
            _discard(token.chip)
            token.chip = nil
        end
    end
end

function TokenInput:_drop_token(index)
    self:_hide_chip_hint()
    local token = self._tokens[index]
    if token.chip ~= nil then
        _discard(token.chip)
    end
    table.remove(self._tokens, index)
end

-- current index of a token (chips keep their token, indexes shift)
function TokenInput:_token_index(token)
    for i = 1, #self._tokens do
        if self._tokens[i] == token then
            return i
        end
    end
    error("TokenInput: token is not in the bar")
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

-- chip and marker icons; pre-scaled: chips are also listed in the
-- (scrolling) overflow list
function TokenInput:_icon(parent, name, size, x, y)
    local image = Image(Icons.sized(name), size)
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
    -- pre-scaled: chips are also listed in the overflow popup
    button:set_tinted_icon(Icons.sized(Icons.CLEAR), icon_size)
    -- no box, as the search-bar clear X: hover only brightens the icon
    Style.apply_transparent_button(button)
    return button
end

function TokenInput:_make_marker(icon_name)
    local marker = Turbine.UI.Control()
    marker:SetParent(self)
    marker:SetMouseVisible(true)
    _set_alpha_blend(marker)
    marker:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    marker:SetVisible(false)
    marker._icon_name = icon_name
    marker.MouseEnter = function()
        marker._hover = true
        self:_paint_marker(marker)
    end
    marker.MouseLeave = function()
        marker._hover = false
        self:_paint_marker(marker)
    end
    marker.MouseClick = function()
        if self._overflow_open == true then
            self:_close_overflow()
        else
            self:_refresh_overflow()
        end
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
    marker._label_x = self:_s(5) + icon_size
    marker._label = self:_label(content, "", marker._label_x, 0, w - marker._label_x, chip_h,
        Style.CONTROL_FOREGROUND)
    marker._content = content
end

-- marker width: room for "+N" of the largest possible count (every token
-- hidden), so the count is never cut
function TokenInput:_marker_width()
    local icon_x = self:_s(5) + _fit(self:_s(self._variant.marker_icon), self:_chip_height())
    local text_w = measure_text_width("+" .. tostring(#self._tokens), Style.CONTROL_FONT_NAME,
        self:_small_font_size() * self._scale) + 2
    return math.max(self:_s(self._variant.marker_w), icon_x + text_w + self:_s(5))
end

function TokenInput:_size_marker(marker, w)
    local chip_h = self:_chip_height()
    marker:SetSize(w, chip_h)
    marker._content:SetSize(w, chip_h)
    marker._label:SetSize(w - marker._label_x, chip_h)
end

function TokenInput:_paint_marker(marker)
    if self._overflow_open == true then
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
    self._clear:set_tinted_icon(Icons.path(Icons.CLEAR), v.clear_icon)
    Style.apply_transparent_button(self._clear)

    self:_build_marker_content(self._marker)
    -- the rebuilt markers are sized again by the next layout
    self._marker_count = nil
end

-- a chip `w` wide; the bar's chips are kept by their token and only
-- resized (_size_chip) while the bar resizes
function TokenInput:_make_chip(token, parent, w)
    local v = self._variant
    local chip_h = self:_chip_height()

    local chip = Turbine.UI.Control()
    chip:SetParent(parent)
    _set_alpha_blend(chip)
    chip:SetBackColor(Style.CONTROL_BACKGROUND)

    local tx = self:_s(v.chip_pad)
    if token.icon ~= nil then
        local icon_size = _fit(self:_s(v.chip_icon), chip_h)
        self:_icon(chip, token.icon, icon_size, tx, (chip_h - icon_size) / 2)
        tx = tx + self:_s(v.chip_icon_w)
    end
    chip._label_x = tx
    chip._label = self:_label(chip, token.label, tx, 0, token.label_w, chip_h, Style.CONTROL_FOREGROUND)

    chip._close = _fit(self:_s(v.close_btn), chip_h)
    chip._remove = self:_flat_button(chip, 0, (chip_h - chip._close) / 2, chip._close, v.close_icon)
    chip._remove.Click = function()
        self:remove_token(self:_token_index(token))
    end
    -- a single click only focuses the field: one that misses the X must
    -- not take the chip apart
    chip.MouseClick = function()
        self._text_box:Focus()
    end
    chip.MouseDoubleClick = function()
        self:edit_token(self:_token_index(token))
    end
    -- a cut chip (ellipsis, or a bar too narrow for it) shows its full
    -- label on hover
    chip.MouseEnter = function()
        if token.cut == true or chip:GetWidth() < token.width then
            self:_show_chip_hint(chip, token.full_label)
        end
    end
    chip.MouseLeave = function()
        self:_hide_chip_hint()
    end
    self:_size_chip(chip, w)
    return chip
end

function TokenInput:_show_chip_hint(chip, text)
    if self._chip_hint == nil then
        self._chip_hint = LuiTooltip()
        self._chip_hint:set_scale(self._scale)
        -- above the overflow list (3000), whose chips show it too
        self._chip_hint:SetZOrder(3100)
    end
    -- the chip font (set each time: the scale may have changed)
    self._chip_hint:SetFont(self:_font(self:_small_font_size()))
    self._chip_hint:ShowFor(chip, text)
    -- Update hides it when the bar's window closes under the mouse
    self:_sync_updates()
end

function TokenInput:_hide_chip_hint()
    if self._chip_hint ~= nil and self._chip_hint:IsVisible() == true then
        self._chip_hint:Hide()
        self:_sync_updates()
    end
end

-- the close button stays at the right edge; a chip cut below its width
-- (a bar too narrow for it) clips its label
function TokenInput:_size_chip(chip, w)
    local chip_h = self:_chip_height()
    chip:SetSize(w, chip_h)
    chip._label:SetSize(math.max(0, w - chip._label_x - self:_s(self._variant.close_w)), chip_h)
    chip._remove:SetPosition(w - chip._close - self:_s(3), (chip_h - chip._close) / 2)
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

-- resized: only the width changed (SetSize), no token did: an open
-- overflow list is rebuilt only when the hidden chips change. Per frame
-- during window resizes: chips are kept, moved and resized, never rebuilt
-- or measured.
function TokenInput:_layout(resized)
    local v = self._variant
    local w = self._width
    local h = self:_bar_height()
    Turbine.UI.Control.SetSize(self, w, h)
    self._inner:SetSize(math.max(0, w - 2), h - 2)

    local gap = self:_s(v.gap)
    local count = #self._tokens
    if self._marker_count ~= count then
        self._marker_count = count
        self._marker_w = self:_marker_width()
        self:_size_marker(self._marker, self._marker_w)
    end
    local marker_w = self._marker_w
    local chip_h = self:_chip_height()
    local chip_y = (h - chip_h) / 2
    local chips_x = self._lead_icon ~= nil and self:_s(v.lead_w) or self:_s(v.edge)
    -- the clear X only shows while there is something to clear
    local has_content = self:_has_content()
    self._clear:SetVisible(has_content)
    local clear_w = self:_s(v.edge)
    if has_content == true then
        clear_w = self:_s(v.clear_w)
    end

    -- the text box keeps MIN_TEXT_W: a chip wider than the room left (a
    -- narrow bar) is cut to it
    local space = w - chips_x - clear_w - self:_s(MIN_TEXT_W)
    local limit = space
    local first = 1
    if self:_fit_from(1, space) < count then
        -- not everything fits: the newest chips that fill the room after
        -- the marker (the newest one always shows, cut on a narrow bar)
        limit = space - marker_w - gap
        first = count
        local total = self._tokens[first].width
        while first > 1 and total + gap + self._tokens[first - 1].width <= limit do
            first = first - 1
            total = total + gap + self._tokens[first].width
        end
    end
    limit = math.max(limit, self:_s(v.chip_pad) + self:_s(v.close_w))
    local range_changed = first ~= self._shown_first
    self._shown_first = first

    local x = chips_x
    self._marker:SetVisible(first > 1)
    if first > 1 then
        self._marker:SetPosition(x, chip_y)
        self:_set_marker_count(self._marker, first - 1)
        x = x + marker_w + gap
    end
    for i = 1, count do
        local token = self._tokens[i]
        if i >= first then
            local chip_w = math.min(token.width, limit)
            if token.chip == nil then
                -- on the bar itself: a chip under a mouse-invisible parent
                -- gets clicks but no hover (MouseEnter / MouseLeave)
                token.chip = self:_make_chip(token, self, chip_w)
                token.chip_w = chip_w
            elseif token.chip_w ~= chip_w then
                self:_size_chip(token.chip, chip_w)
                token.chip_w = chip_w
            end
            token.chip:SetPosition(x, chip_y)
            token.chip:SetVisible(true)
            x = x + chip_w + gap
        elseif token.chip ~= nil then
            token.chip:SetVisible(false)
        end
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

    if self._overflow_open == true and (resized ~= true or range_changed == true) then
        self:_refresh_overflow()
    end
end

-- "+N" written only when N changes (layouts run per resize frame)
function TokenInput:_set_marker_count(marker, n)
    if marker._count ~= n then
        marker._count = n
        marker._label:SetText("+" .. tostring(n))
    end
end

function TokenInput:_has_content()
    return #self._tokens > 0 or (self._text_box:GetText() or "") ~= ""
end

function TokenInput:_sync_placeholder()
    self._placeholder_label:SetVisible(#self._tokens == 0 and (self._text_box:GetText() or "") == "")
end

-- the clear X and the placeholder follow the content; for every content
-- change, typed or not (a pick, Enter)
function TokenInput:_sync_content()
    if self:_has_content() ~= self._clear:IsVisible() then
        self:_layout(true)
    else
        self:_sync_placeholder()
    end
end

---------------------------------------------------------------------
-- Private: lists (overflow + suggestions)
---------------------------------------------------------------------

-- per-frame work only while needed: a deferred suggestion refresh, and
-- while a list is open, closing it once the bar is no longer on screen
-- (window hidden by Escape, tab switched, global UI hide...)
function TokenInput:_sync_updates()
    self:SetWantsUpdates(self._pending_refresh == true or self._pending_focus == true
        or self._menu:is_open() == true or self._overflow_open == true
        or (self._chip_hint ~= nil and self._chip_hint:IsVisible() == true))
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

-- hidden first: a control detached while visible keeps drawing at the
-- screen's top-left
function TokenInput:_clear_overflow_rows()
    self:_hide_chip_hint()
    for i = 1, #self._overflow_chips do
        self._overflow_chips[i]:SetVisible(false)
    end
    self._overflow_list:ClearItems()
    self._overflow_chips = {}
end

function TokenInput:_close_overflow()
    self:_clear_overflow_rows()
    self._overflow:SetVisible(false)
    self._overflow_open = false
    self:_sync_click_away()
    self:_paint_marker(self._marker)
end

function TokenInput:_refresh_overflow()
    -- the chips behind the marker
    local indexes = {}
    for i = 1, self._shown_first - 1 do
        indexes[#indexes + 1] = i
    end
    if #indexes == 0 then
        self:_close_overflow()
        return
    end
    self:_clear_overflow_rows()

    local chip_h = self:_chip_height()
    local gap = self:_s(self._variant.gap)
    local pad = self:_s(5)
    -- every row as wide as the widest hidden chip
    local width = 0
    for k = 1, #indexes do
        width = math.max(width, self._tokens[indexes[k]].width)
    end
    local row_h = chip_h + gap
    for k = 1, #indexes do
        local row = Turbine.UI.Control()
        row:SetSize(width, row_h)
        -- mouse-visible: the chip's hover (full label hint) needs it
        self:_make_chip(self._tokens[indexes[k]], row, width)
        self._overflow_list:AddItem(row)
        self._overflow_chips[k] = row
    end
    local rows = math.min(#indexes, OVERFLOW_MAX_ROWS)
    local list_h = rows * row_h - gap
    local scrolls = #indexes > OVERFLOW_MAX_ROWS
    local scroll_w = scrolls and BASE_SCROLL_W or 0
    -- the scrollbar runs the full height against the right border; the
    -- padding only surrounds the chips
    local inner_w = width + 2 * pad + scroll_w
    local inner_h = list_h + 2 * pad
    self._overflow_list:SetPosition(pad, pad)
    self._overflow_list:SetSize(width, list_h)
    self._overflow_scroll:SetVisible(scrolls)
    self._overflow_scroll:SetPosition(inner_w - scroll_w, 0)
    self._overflow_scroll:SetSize(scroll_w, inner_h)
    self._overflow_inner:SetSize(inner_w, inner_h)
    self._overflow:SetSize(inner_w + 2, inner_h + 2)
    local sx, sy = self._marker:PointToScreen(0, chip_h + self:_s(6))
    self._overflow:SetPosition(sx, sy)
    self._overflow:SetVisible(true)
    self._overflow_open = true
    -- the list is a fixed screen window: close it once the bar moves
    self._overflow_screen_x, self._overflow_screen_y = self:PointToScreen(0, 0)
    self:_sync_click_away()
    self:_paint_marker(self._marker)
end

function TokenInput:_close_suggest()
    self._menu:close()
    self:_sync_updates()
end

-- same rows: the pick callbacks only read value and final
local function _same_entries(a, b)
    if a == nil or #a ~= #b then
        return false
    end
    for i = 1, #b do
        local x, y = a[i], b[i]
        if x.text ~= y.text or x.hint ~= y.hint or x.icon ~= y.icon
            or x.value ~= y.value or x.final ~= y.final then
            return false
        end
    end
    return true
end

-- key and value of the keyword `text` starts with (KeywordOf); nil, nil
-- for plain text
function TokenInput:_typed_keyword(text)
    if type(self.KeywordOf) ~= "function" then
        return nil, nil
    end
    return self:KeywordOf(text)
end

-- a keyword's values start on the first one (Enter picks it); keyword
-- names over plain text start with none, so Enter adds the typed text
-- and Down reaches the list
function TokenInput:_default_highlight(text)
    if self:_typed_keyword(text) ~= nil then
        self._menu:set_highlight(1)
    else
        self._menu:clear_highlight()
    end
end

-- runs on every keystroke: an open list with the same entries is kept as
-- is, other entries are written into the menu's existing rows
function TokenInput:_open_suggest(text, entries, from, to)
    if #entries == 0 then
        self:_close_suggest()
        return
    end
    self._suggest_from = from
    self._suggest_to = to
    if self._menu:is_open() == true and _same_entries(self._suggest_entries, entries) then
        self:_default_highlight(text)
        return
    end
    self._suggest_entries = entries
    local specs = {}
    for _, entry in ipairs(entries) do
        local icon = nil
        if entry.icon ~= nil then
            -- pre-scaled: the suggestion menu scrolls
            icon = Icons.sized(entry.icon)
        end
        specs[#specs + 1] = {
            text = entry.text,
            hint = entry.hint,
            icon = icon,
            icon_tinted = true,
            action = function()
                self:_pick(entry, self._text_box:GetText() or "")
            end,
        }
    end
    self._menu:set_actions(specs)
    if self._menu:is_open() ~= true then
        self._menu:open_below(self._text_box)
    end
    self:_default_highlight(text)
    self:_sync_updates()
end

-- an empty field only lists suggestions on request (click, Down,
-- double-click); typing, or a pick that continues, opens the list by itself
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
    local entries, from, to = self:Suggestions(text)
    self:_open_suggest(text, entries, from, to)
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
    self:_sync_content()
    self:_refresh_suggest_later()
end

---------------------------------------------------------------------
-- Private: events
---------------------------------------------------------------------

-- Enter: picks the highlighted suggestion, else adds the typed text as a
-- token ("lvl:" alone stays in the field to type the value)
function TokenInput:_submit()
    local current = self._text_box:GetText() or ""
    local value = _trim(current)
    if self._menu:is_open() == true and self._menu:trigger_highlight() == true then
        return
    end
    local key, keyword_value = self:_typed_keyword(value)
    if key ~= nil and keyword_value == nil then
        self._text_box:SetSelection(string.len(current) + 1, 0)
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
end

function TokenInput:_wire_events()
    local open_on_request = function()
        self._text_box:Focus()
        self:_refresh_suggest(true)
    end
    -- a click in the empty field lists the suggestions; with text it only
    -- places the caret (no list popping up while editing)
    local click = function()
        if _trim(self._text_box:GetText() or "") == "" then
            open_on_request()
        else
            self._text_box:Focus()
        end
    end
    self.MouseClick = click
    self._text_box.MouseClick = click
    self.MouseDoubleClick = open_on_request
    self._text_box.MouseDoubleClick = open_on_request

    self.Update = function()
        if self._pending_focus == true then
            -- after Enter: the client moved the focus to the chat
            self._pending_focus = false
            if self:IsDisplayed() == true then
                self._text_box:Focus()
            end
        end
        if self._pending_refresh == true then
            self._pending_refresh = false
            self:_refresh_suggest()
        end
        if self:IsDisplayed() ~= true then
            if self._menu:is_open() == true or self._overflow_open == true then
                self:_close_lists()
            end
            self:_hide_chip_hint()
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
        -- key events reach every control that wants them, focused or not
        if self._text_box:HasFocus() ~= true then
            return
        end
        if args.Action == ACTION_ENTER then
            self:_submit()
            self._pending_focus = true
            self:_sync_updates()
            return
        end
        if self._menu:is_open() ~= true then
            -- Down opens the list (empty field included)
            if args.Action == ACTION_DOWN then
                self:_refresh_suggest(true)
            end
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
            -- a pasted line break: the field is one line (Enter is KeyDown)
            self:_set_field_text((string.gsub(text, "\n", "")))
            return
        end
        self:_sync_content()
        self:_refresh_suggest()
    end
end
