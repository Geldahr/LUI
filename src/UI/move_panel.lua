-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Move mode position panel: one shared window docked beside the HUD element
-- that was clicked last (left of it when the element sits in the right half
-- of the screen, right of it otherwise). It carries the element's title,
-- the X/Y fields, Reset (back to where the element was when move mode
-- started) and four 1 px nudge arrows (Alt: 10 px), so the elements
-- themselves no longer need room for any move controls. The arrow keys
-- nudge too while an X/Y field has the keyboard (a focused TextBox is the
-- only control that gets them).

local TR = _G.LUI.Locale.TR
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.Widgets"

local LUI = _G.LUI
local UI = LUI.UI
local Widgets = UI.Widgets
local MoveMode = UI.MoveMode
local State = LUI.Settings.State
local Style = Widgets.Style
local Icons = Widgets.Icons
local LuiBaseWindow = Widgets.LuiBaseWindow
local LuiButton = Widgets.LuiButton
local LuiLabel = Widgets.LuiLabel
local LuiLineEdit = Widgets.LuiLineEdit

-- base (unscaled) geometry
local PAD = 6
local GAP = 4
local HEADER_H = 20
local ROW_H = 20
local AXIS_LABEL_W = 12
local AXIS_BOX_W = 48
local AXIS_PAIR_GAP = 8
local ARROW_ICON_W = 14
-- distance between the element and the panel
local DOCK_GAP = 4

-- TextBox KeyDown actions of the arrow keys -> nudge direction (X/Y fields)
local KEY_NUDGES = {
    [29] = { 0, -1 },
    [113] = { 0, 1 },
    [127] = { -1, 0 },
    [108] = { 1, 0 },
}

local ARROWS = {
    { icon = "chevron_left_small", dx = -1, dy = 0 },
    { icon = "chevron_up_small", dx = 0, dy = -1 },
    { icon = "chevron_down_small", dx = 0, dy = 1 },
    { icon = "chevron_right_small", dx = 1, dy = 0 },
}

---@type MovePanel
local PANEL = nil
-- the HUD element the panel is docked to (one at a time)
local FOCUSED = nil
-- move chrome may show (move mode on, HUD shown, no preview lock)
local CHROME_VISIBLE = false
-- hud -> { x, y }: where each element was when move mode started (Reset)
local START_POSITIONS = {}

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end

local function _scaled_border(scale, value)
    if value <= 0 then
        return 0
    end
    return math.max(1, _scaled_int(scale, value))
end

local function _scaled_font(scale, name, size)
    local font = FONT_TO_LOTRO(name, size * scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size * scale))
    end
    return font
end

local function _capture_start(hud)
    local x, y = hud:GetPosition()
    START_POSITIONS[hud] = { x = x, y = y }
end

---@class MovePanel: UI.Widgets.LuiBaseWindow
local MovePanel = class(LuiBaseWindow)
MoveMode.MovePanel = MovePanel

function MovePanel:Constructor()
    LuiBaseWindow.Constructor(self, { hideable = false })

    self._target = nil
    self._scale = nil
    self._synced_x = nil
    self._synced_y = nil
    self._reset_enabled = nil

    self:SetVisible(false)
    self:SetMouseVisible(true)
    self:SetZOrder(999)
    self:SetBackColor(Style.CONTROL_BORDER)

    self.body = Turbine.UI.Control()
    self.body:SetParent(self)
    self.body:SetMouseVisible(false)
    self.body:SetBackColor(Style.PANEL_BACKGROUND)

    self.header = Turbine.UI.Control()
    self.header:SetParent(self.body)
    self.header:SetMouseVisible(false)
    self.header:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.header:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.header:SetBackColor(Style.MOVE_OVERLAY_HEADER_BACKGROUND)

    self.title = LuiLabel()
    self.title:SetParent(self.header)
    self.title:SetMouseVisible(false)
    self.title:SetSelectable(false)
    self.title:SetForeColor(Style.MOVE_OVERLAY_FOREGROUND)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.x_label, self.x_box = self:_new_axis("X")
    self.y_label, self.y_box = self:_new_axis("Y")

    self.reset_button = LuiButton()
    self.reset_button:SetParent(self.body)
    self.reset_button:set_text(TR["Reset"])
    self.reset_button.Click = function()
        local start = START_POSITIONS[self._target]
        self._target:move_to(start.x, start.y, true)
    end

    self.arrow_buttons = {}
    for i = 1, #ARROWS do
        local arrow = ARROWS[i]
        local button = LuiButton()
        button:SetParent(self.body)
        button:set_text("")
        button:set_tinted_icon(Icons.path(arrow.icon), ARROW_ICON_W)
        button.Click = function()
            self:_nudge(arrow.dx, arrow.dy)
        end
        self.arrow_buttons[i] = button
    end

    self:apply_style()
end

function MovePanel:_new_axis(text)
    local label = LuiLabel()
    label:SetParent(self.body)
    label:SetMouseVisible(false)
    label:SetSelectable(false)
    label:SetForeColor(Style.MOVE_OVERLAY_FOREGROUND)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    label:SetText(text)

    -- positions are clamped to the screen, never negative: digits only,
    -- and Enter arrives as Submitted
    local box = LuiLineEdit()
    box:SetParent(self.body)
    box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    box:SetWantsKeyEvents(true)
    box:set_digits_only(true)
    box.Submitted = function()
        self:_apply_inputs()
    end
    box.FocusLost = function()
        self:_apply_inputs()
    end
    box.KeyDown = function(_, args)
        self:_nudge_key(args.Action)
    end

    return label, box
end

function MovePanel:apply_style()
    local scale = State.settings.global.scale
    if self._scale == scale then
        return
    end
    self._scale = scale

    local border = _scaled_border(scale, Style.BORDER_WIDTH)
    local pad = _scaled_int(scale, PAD)
    local gap = _scaled_int(scale, GAP)
    local header_h = _scaled_int(scale, HEADER_H)
    local row_h = _scaled_int(scale, ROW_H)
    local axis_label_w = _scaled_int(scale, AXIS_LABEL_W)
    local axis_box_w = _scaled_int(scale, AXIS_BOX_W)
    local pair_gap = _scaled_int(scale, AXIS_PAIR_GAP)
    local content_w = (2 * (axis_label_w + gap + axis_box_w)) + pair_gap
    local body_w = content_w + (2 * pad)
    local body_h = header_h + pad + (3 * row_h) + (2 * gap) + pad

    self:SetSize(body_w + (2 * border), body_h + (2 * border))
    self.body:SetPosition(border, border)
    self.body:SetSize(body_w, body_h)

    self.header:SetPosition(0, 0)
    self.header:SetSize(body_w, header_h)
    self.title:SetPosition(pad, 0)
    self.title:SetSize(body_w - (2 * pad), header_h)
    self.title:SetFont(_scaled_font(scale, Style.WINDOW_TITLE_FONT_NAME, Style.WINDOW_TITLE_FONT_SIZE))

    local font = _scaled_font(scale, Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE)
    local y = header_h + pad
    local x = pad
    self.x_label:SetPosition(x, y)
    self.x_label:SetSize(axis_label_w, row_h)
    self.x_label:SetFont(font)
    x = x + axis_label_w + gap
    self.x_box:SetPosition(x, y)
    self.x_box:SetSize(axis_box_w, row_h)
    self.x_box:SetFont(font)
    x = x + axis_box_w + pair_gap
    self.y_label:SetPosition(x, y)
    self.y_label:SetSize(axis_label_w, row_h)
    self.y_label:SetFont(font)
    x = x + axis_label_w + gap
    self.y_box:SetPosition(x, y)
    self.y_box:SetSize(axis_box_w, row_h)
    self.y_box:SetFont(font)

    y = y + row_h + gap
    self.reset_button:set_scale(scale)
    self.reset_button:SetPosition(pad, y)
    self.reset_button:SetSize(content_w, row_h)

    y = y + row_h + gap
    local count = #self.arrow_buttons
    local arrow_w = math.floor((content_w - ((count - 1) * gap)) / count)
    x = pad + math.floor((content_w - ((count * arrow_w) + ((count - 1) * gap))) / 2)
    for i = 1, count do
        local button = self.arrow_buttons[i]
        button:set_scale(scale)
        button:SetPosition(x, y)
        button:SetSize(arrow_w, row_h)
        x = x + arrow_w + gap
    end

    self:_dock()
end

-- dock beside the target: left of it when its center is in the right half
-- of the screen, right of it otherwise; kept on screen
function MovePanel:_dock()
    local target = self._target
    if target == nil then
        return
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    local hx, hy = target:PointToScreen(0, 0)
    local hw, hh = target:GetSize()
    local pw, ph = self:GetSize()
    local gap = _scaled_int(self._scale, DOCK_GAP)

    local left
    if (hx + (hw / 2)) > (display_w / 2) then
        left = hx - gap - pw
    else
        left = hx + hw + gap
    end
    left = math.max(0, math.min(left, display_w - pw))
    local top = math.max(0, math.min(hy, display_h - ph))
    self:SetPosition(left, top)
end

function MovePanel:get_target()
    return self._target
end

function MovePanel:set_target(hud)
    -- a value typed for the previous element still belongs to it
    if self._target ~= nil and self._target ~= hud and (self.x_box:HasFocus() or self.y_box:HasFocus()) then
        self:_apply_inputs()
    end

    self._target = hud
    self._synced_x = nil
    self._synced_y = nil
    if hud == nil then
        return
    end

    self.title:SetText(hud:get_move_title())
    self:sync()
end

-- the target moved or resized: refresh the fields and Reset, re-dock
function MovePanel:sync()
    local target = self._target
    local x, y = target:GetPosition()
    if x ~= self._synced_x then
        self._synced_x = x
        self.x_box:SetText(tostring(x))
    end
    if y ~= self._synced_y then
        self._synced_y = y
        self.y_box:SetText(tostring(y))
    end

    local start = START_POSITIONS[target]
    local reset_enabled = x ~= start.x or y ~= start.y
    if reset_enabled ~= self._reset_enabled then
        self._reset_enabled = reset_enabled
        self.reset_button:set_enabled(reset_enabled)
    end

    self:_dock()
end

-- the TextBox does not paint text set while its window was hidden
function MovePanel:refresh_texts()
    self.x_box:refresh_text_async()
    self.y_box:refresh_text_async()
end

function MovePanel:_apply_inputs()
    local target = self._target
    if target == nil then
        return
    end

    local cur_x, cur_y = target:GetPosition()
    -- an emptied field keeps that axis where it is
    local x = tonumber(self.x_box:GetText())
    if x == nil then
        x = cur_x
    end
    local y = tonumber(self.y_box:GetText())
    if y == nil then
        y = cur_y
    end

    -- rewrite both fields even when the clamped result did not move
    self._synced_x = nil
    self._synced_y = nil
    if x == cur_x and y == cur_y then
        self:sync()
        return
    end
    target:move_to(x, y, true)
end

function MovePanel:_nudge_key(action)
    -- a field can keep the keyboard a moment after its target left
    if self._target == nil or Turbine.UI.Control.IsControlKeyDown() then
        return
    end
    local nudge = KEY_NUDGES[action]
    if nudge ~= nil then
        self:_nudge(nudge[1], nudge[2])
    end
end

function MovePanel:_nudge(dx, dy)
    local step = 1
    if Turbine.UI.Control.IsAltKeyDown() then
        step = 10
    end
    local x, y = self._target:GetPosition()
    self._target:move_to(x + (dx * step), y + (dy * step), true)
end

---------------------------------------------------------------------
-- MoveMode hooks
---------------------------------------------------------------------

local function _refresh_panel()
    if CHROME_VISIBLE ~= true or FOCUSED == nil then
        if PANEL ~= nil then
            PANEL:SetVisible(false)
        end
        return
    end

    local was_visible = PANEL:IsVisible()
    PANEL:apply_style()
    PANEL:sync()
    PANEL:SetVisible(true)
    PANEL:SetZOrder(999)
    if was_visible ~= true then
        PANEL:refresh_texts()
    end
end

-- a HUD element was clicked in move mode: dock the panel to it
function MoveMode.focus_hud(hud)
    if FOCUSED == hud then
        return
    end

    if START_POSITIONS[hud] == nil then
        _capture_start(hud)
    end
    if PANEL == nil then
        PANEL = MovePanel()
    end

    if FOCUSED ~= nil then
        FOCUSED:set_move_focused(false)
    end
    FOCUSED = hud
    hud:set_move_focused(true)
    PANEL:set_target(hud)
    _refresh_panel()
end

-- a HUD element left move mode: undock the panel when it was the target
function MoveMode.release_hud(hud)
    if FOCUSED ~= hud then
        return
    end

    hud:set_move_focused(false)
    FOCUSED = nil
    PANEL:set_target(nil)
    _refresh_panel()
end

-- move mode ended: nothing stays selected, so the next one starts fresh
-- (no element framed, panel hidden)
function MoveMode.clear_focus()
    if FOCUSED ~= nil then
        MoveMode.release_hud(FOCUSED)
    end
end

-- a HUD element moved or resized
function MoveMode.hud_geometry_changed(hud)
    if FOCUSED ~= hud then
        return
    end
    PANEL:sync()
end

function MoveMode.set_panel_visible(visible)
    CHROME_VISIBLE = visible == true
    _refresh_panel()
end

-- Reset targets: positions are taken again from now on (move mode
-- entered/left, or the quick setup applied a new layout)
function MoveMode.reset_start_positions()
    START_POSITIONS = {}
    if FOCUSED ~= nil then
        _capture_start(FOCUSED)
        PANEL:sync()
    end
end
