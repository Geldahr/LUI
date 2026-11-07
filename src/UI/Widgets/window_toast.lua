-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- LuiWindow's toast: a short notice centered over the bottom
-- of the content (above the status bar) that hides by itself after a few
-- seconds, or on click. Its text wraps at a fixed width and keeps 2 lines
-- at most; the rest ends with "..." and its hover hints the full text. One
-- per window: a new toast replaces the current one. Fading out is the
-- global "fade_out_toasts" setting, stepped at the global refresh rate.
-- Created on first use; laid out by LuiWindow:_layout.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Utils = _G.LUI.Utils
local Widgets = _G.LUI.UI.Widgets
import "LUI.src.Utils.text_width"
import "LUI.src.UI.Widgets.timer"

local LuiWindow = Widgets.LuiWindow
local LuiLabel = Widgets.LuiLabel
local Image = Widgets.Image
local LuiTimer = Widgets.LuiTimer
local Style = Widgets.Style

-- text width before it wraps, and the lines it keeps
local BASE_MAX_TEXT_W = 300
local MAX_LINES = 2
local BASE_PAD_X = 10
local BASE_PAD_Y = 6
local BASE_GAP = 6
-- from the content's sides and bottom
local BASE_MARGIN = 8
local BASE_ICON = 14
local DEFAULT_SECONDS = 2
local FADE_SECONDS = 0.3
-- above the content's controls
local TOAST_Z = 100

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _global_settings()
    return _G.LUI.Settings.State.settings.global
end

-- SetOpacity is a silent no-op on plain controls: the toast fades through
-- the alpha of its colors (alpha-blended). A pre-scaled icon can't fade (a
-- tint covers its whole square): it hides halfway through.
local ICON_HIDE_ALPHA = 0.5
local function _faded(color, alpha)
    return Turbine.UI.Color(color.A * alpha, color.R, color.G, color.B)
end

function LuiWindow:_ensure_toast()
    if self._toast ~= nil then
        return
    end

    -- the frame color shows around the panel
    local toast = Turbine.UI.Control()
    toast:SetParent(self._inner)
    toast:SetZOrder(TOAST_Z)
    toast:SetMouseVisible(true)
    _set_blend(toast)
    toast:SetVisible(false)
    toast.MouseClick = function()
        self:hide_toast()
    end
    toast.MouseEnter = function()
        if self._toast_cut == true then
            self:_show_window_hint(toast, self._toast_text)
        end
    end
    toast.MouseLeave = function()
        self:_hide_window_hint()
    end

    local panel = Turbine.UI.Control()
    panel:SetParent(toast)
    panel:SetMouseVisible(false)
    _set_blend(panel)

    local icon = Image()
    icon:SetParent(panel)
    icon:SetMouseVisible(false)
    icon:SetVisible(false)

    local label = LuiLabel()
    label:SetParent(panel)
    label:SetMouseVisible(false)
    label:SetMultiline(true)
    label:SetSelectable(false)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self._toast = toast
    self._toast_panel = panel
    self._toast_icon = icon
    self._toast_label = label
    self._toast_text = nil
    self._toast_icon_asset = nil
    self._toast_alpha = 1
    -- the wrap of _toast_text: done for this text room (nil = wrap again),
    -- line count, label width, cut or not
    self._toast_room = nil
    self._toast_lines = 0
    self._toast_text_w = 0
    self._toast_cut = false
    self._toast_fade_start = 0
    self._toast_hold_timer = LuiTimer(function()
        self:_end_toast_hold()
    end)
    self._toast_fade_timer = LuiTimer(function()
        self:_fade_toast_step()
    end)
    self:_style_toast()
end

function LuiWindow:_style_toast()
    self._toast_font = FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE * self._scale)
    self._toast_label:SetFont(self._toast_font)
    self:_set_toast_alpha(1)
    self._toast_room = nil
end

-- 1 = as styled, 0 = invisible
function LuiWindow:_set_toast_alpha(alpha)
    self._toast_alpha = alpha
    self._toast:SetBackColor(_faded(Style.CONTROL_BORDER, alpha))
    -- the menu bar's background: lighter than the window's
    self._toast_panel:SetBackColor(_faded(Style.CONTROL_BACKGROUND, alpha))
    self._toast_label:SetForeColor(_faded(Style.FOREGROUND, alpha))
    self._toast_icon:SetVisible(self._toast_icon_asset ~= nil and alpha >= ICON_HIDE_ALPHA)
end

-- opts: seconds (default 2), icon (an Icons.sized icon)
function LuiWindow:show_toast(text, opts)
    if opts == nil then
        opts = {}
    end
    local seconds = opts.seconds
    if seconds == nil then
        seconds = DEFAULT_SECONDS
    end
    self:_ensure_toast()

    self._toast_text = tostring(text)
    self._toast_icon_asset = opts.icon
    self._toast_room = nil
    self._toast_fade_timer:stop()
    self:_set_toast_alpha(1)
    self:_layout_toast()
    self._toast:SetVisible(true)
    self._toast_hold_timer:start(seconds)
end

function LuiWindow:hide_toast()
    if self._toast == nil then
        return
    end
    self._toast_hold_timer:stop()
    self._toast_fade_timer:stop()
    self._toast:SetVisible(false)
    self:_set_toast_alpha(1)
    self._toast_text = nil
    self:_hide_window_hint()
end

function LuiWindow:_end_toast_hold()
    self._toast_hold_timer:stop()
    local global = _global_settings()
    if global.fade_out_toasts ~= true then
        self:hide_toast()
        return
    end
    self._toast_fade_start = Turbine.Engine.GetGameTime()
    self._toast_fade_timer:start(1 / global.refresh_rate)
end

function LuiWindow:_fade_toast_step()
    local done = (Turbine.Engine.GetGameTime() - self._toast_fade_start) / FADE_SECONDS
    if done >= 1 then
        self:hide_toast()
        return
    end
    self:_set_toast_alpha(1 - done)
end

-- centered over the bottom of the content area (LuiWindow:_layout stores
-- it); the text wraps again only when its room changes
function LuiWindow:_layout_toast()
    if self._toast_text == nil then
        return
    end

    local scale = self._scale
    local pad_x = _scaled_int(scale, BASE_PAD_X)
    local pad_y = _scaled_int(scale, BASE_PAD_Y)
    local gap = _scaled_int(scale, BASE_GAP)
    local margin = _scaled_int(scale, BASE_MARGIN)
    local border = math.max(1, _scaled_int(scale, Style.BORDER_WIDTH_THIN))
    local icon_size = _scaled_int(scale, BASE_ICON)
    -- a label wraps this far inside its width; +2: glyph edges
    local label_extra = _scaled_int(scale, Utils.LABEL_WRAP_INSET) + 2
    local icon_w = 0
    if self._toast_icon_asset ~= nil then
        icon_w = icon_size + gap
    end

    local area_w = self._content_rect_w
    local frame_w = (2 * border) + (2 * pad_x) + icon_w
    local room = math.max(0, math.min(_scaled_int(scale, BASE_MAX_TEXT_W),
        area_w - (2 * margin) - frame_w - label_extra))
    if self._toast_room ~= room then
        self._toast_room = room
        local shown, lines, widest, cut = Utils.clamp_text_lines(self._toast_text, self._toast_font, room, MAX_LINES)
        self._toast_label:SetText(shown)
        self._toast_lines = lines
        self._toast_text_w = widest + label_extra
        self._toast_cut = cut
    end

    local text_h = self._toast_lines * Utils.font_object_size(self._toast_font)
    local width = math.min(frame_w + self._toast_text_w, math.max(0, area_w - (2 * margin)))
    local height = (2 * border) + (2 * pad_y) + text_h
    self._toast:SetPosition(math.floor((area_w - width) / 2), math.max(0, self._content_bottom - margin - height))
    self._toast:SetSize(width, height)
    local panel_h = math.max(0, height - (2 * border))
    self._toast_panel:SetPosition(border, border)
    self._toast_panel:SetSize(math.max(0, width - (2 * border)), panel_h)

    local text_x = pad_x
    if self._toast_icon_asset ~= nil then
        self._toast_icon:set_icon(self._toast_icon_asset, icon_size, icon_size)
        self._toast_icon:SetPosition(pad_x, math.floor((panel_h - icon_size) / 2))
        self._toast_icon:SetVisible(self._toast_alpha >= ICON_HIDE_ALPHA)
        text_x = pad_x + icon_w
    else
        self._toast_icon:SetVisible(false)
    end
    self._toast_label:SetPosition(text_x, pad_y)
    self._toast_label:SetSize(self._toast_text_w, text_h)
end
