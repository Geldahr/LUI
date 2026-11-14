-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.UI.Widgets.base_window"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local LUI = _G.LUI
local State = LUI.Settings.State
local UI = LUI.UI
local Widgets = UI.Widgets
local MoveMode = UI.MoveMode
local LuiBaseWindow = Widgets.LuiBaseWindow
local LuiLabel = Widgets.LuiLabel
local Style = Widgets.Style

local DEFAULT_TITLE = "HUD"

local function _scale()
    if State.settings == nil or State.settings.global == nil then
        return 1
    end

    local scale = tonumber(State.settings.global.scale)
    if scale == nil or scale <= 0 then
        return 1
    end
    return scale
end

local function _scaled_size(value)
    return value * _scale()
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local function _int(n)
    local v = n
    if type(v) ~= "number" then
        v = tonumber(v)
    end
    if v == nil then
        return nil
    end
    return math.floor(v + 0.5)
end

local function _clamp(n, min, max)
    if n < min then
        return min
    end
    if n > max then
        return max
    end
    return n
end

---@class LuiHUD : LuiBaseWindow
local LuiHUD = class(LuiBaseWindow)
Widgets.LuiHUD = LuiHUD

function LuiHUD:Constructor(opts)
    if type(opts) ~= "table" then
        opts = {}
    end
    local base_opts = {
        hideable = opts.hideable ~= false,
    }
    LuiBaseWindow.Constructor(self, base_opts)

    self._hud_key = opts.hud_key
    self._move_title = opts.title or DEFAULT_TITLE
    self._hud_mouse_visible = opts.mouse_visible == true
    self._move_enabled = false
    self._move_dragging = false
    self._move_drag_start_x = 0
    self._move_drag_start_y = 0
    self._move_drag_start_screen_x = 0
    self._move_drag_start_screen_y = 0
    self._move_drag_start_window_x = 0
    self._move_drag_start_window_y = 0
    self._move_focused = false
    self._move_grid_shown = false
    self._move_ui_scale = nil

    self.on_move_mode_changed = nil
    self.on_move_end = nil

    self:SetMouseVisible(self._hud_mouse_visible)

    self._move_layer = Turbine.UI.Control()
    self._move_layer:SetParent(self)
    self._move_layer:SetMouseVisible(false)
    self._move_layer:SetVisible(false)
    self._move_layer:SetZOrder(999)
    self._move_layer:SetBackColor(Style.MOVE_OVERLAY_BACKGROUND)

    -- the element's title, centered; the position controls live in the
    -- shared move panel (move_panel.lua) docked beside the clicked element
    self._move_title_label = LuiLabel()
    self._move_title_label:SetParent(self._move_layer)
    self._move_title_label:SetMouseVisible(false)
    self._move_title_label:SetSelectable(false)
    self._move_title_label:SetForeColor(Style.MOVE_OVERLAY_FOREGROUND)
    self._move_title_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    -- frame of every element in move mode: a thin subtle grey line, the
    -- active border on the element the move panel is docked to
    self._move_frame = {}
    for i = 1, 4 do
        local edge = Turbine.UI.Control()
        edge:SetParent(self._move_layer)
        edge:SetMouseVisible(false)
        edge:SetBackColor(Style.SUBTLE_FOREGROUND)
        self._move_frame[i] = edge
    end

    self:_bind_move_chrome()
    self:set_move_title(self._move_title)
    self:apply_move_ui_scale()
end

function LuiHUD:set_hud_key(hud_key)
    self._hud_key = hud_key
end

function LuiHUD:get_hud_key()
    return self._hud_key
end

function LuiHUD:set_move_title(title)
    if type(title) == "string" then
        self._move_title = title
    else
        self._move_title = DEFAULT_TITLE
    end

    if self._move_title_label ~= nil then
        self._move_title_label:SetText(self._move_title)
    end
end

function LuiHUD:get_move_title()
    return self._move_title
end

function LuiHUD:set_hud_mouse_visible(visible)
    self._hud_mouse_visible = visible == true
    if self._move_enabled ~= true then
        self:SetMouseVisible(self._hud_mouse_visible)
    end
end

function LuiHUD:get_loaded_hud_settings()
    if self._hud_key == nil then
        return nil
    end
    return LUI.Settings.Defaults.get_ui_hud_state(self._hud_key)
end

function LuiHUD:get_hud_settings()
    if self._hud_key == nil or State.settings == nil or State.settings.ui == nil or type(State.settings.ui.hud) ~= "table" then
        return nil
    end
    return State.settings.ui.hud[self._hud_key]
end

function LuiHUD:apply_hud_position()
    local hud = self:get_hud_settings()
    if type(hud) ~= "table" then
        return
    end

    local left = _int(hud.left)
    local top = _int(hud.top)
    if left == nil or top == nil then
        error("Invalid HUD position for " .. tostring(self._hud_key))
    end

    left, top = self:_clamp_to_screen(left, top)
    self:SetPosition(left, top)
    self:sync_move_inputs_from_position()
end

function LuiHUD:persist_position(x, y)
    local hud = self:get_loaded_hud_settings()
    if type(hud) ~= "table" then
        return
    end

    hud.left = _int(x) or 0
    hud.top = _int(y) or 0
end

function LuiHUD:is_move_mode()
    return self._move_enabled == true
end

function LuiHUD:set_move_mode(enabled)
    local want = enabled == true
    if want == self._move_enabled then
        return
    end

    if want ~= true then
        MoveMode.release_hud(self)
    end

    self._move_enabled = want
    self._move_dragging = false
    self:SetMouseVisible(want or self._hud_mouse_visible)
    self._move_layer:SetVisible(want)
    self._move_layer:SetMouseVisible(want)

    if want then
        self:layout_move_chrome()
        self:sync_move_inputs_from_position()
        local x, y = self:GetPosition()
        local nx, ny = self:_clamp_to_screen(_int(x) or 0, _int(y) or 0)
        if nx ~= _int(x) or ny ~= _int(y) then
            self:move_to(nx, ny, true)
        end

        if self._move_grid_shown ~= true then
            self._move_grid_shown = true
            MoveMode.show_grid()
        end
    elseif self._move_grid_shown == true then
        self._move_grid_shown = false
        MoveMode.hide_grid()
    end

    if self.on_move_mode_changed ~= nil then
        self:on_move_mode_changed(want)
    end
end

function LuiHUD:_sync_move_ui_scale()
    local scale = _scale()
    if self._move_ui_scale == scale then
        return
    end

    self._move_ui_scale = scale
    self._move_title_label:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
end

function LuiHUD:apply_move_ui_scale()
    self:_sync_move_ui_scale()
    self:layout_move_chrome()
end

function LuiHUD:layout_move_chrome()
    if self._move_layer == nil then
        return
    end

    self:_sync_move_ui_scale()

    local w, h = self:GetSize()
    self._move_layer:SetPosition(0, 0)
    self._move_layer:SetSize(w, h)
    self._move_title_label:SetPosition(0, 0)
    self._move_title_label:SetSize(w, h)
    self:_layout_move_frame()

    MoveMode.hud_geometry_changed(self)
end

function LuiHUD:_layout_move_frame()
    local w, h = self:GetSize()
    local width = Style.BORDER_WIDTH_THIN
    if self._move_focused == true then
        width = Style.BORDER_WIDTH_LARGE
    end
    local t = math.max(1, _scaled_int(width))
    local frame = self._move_frame
    frame[1]:SetPosition(0, 0)
    frame[1]:SetSize(w, t)
    frame[2]:SetPosition(0, h - t)
    frame[2]:SetSize(w, t)
    frame[3]:SetPosition(0, 0)
    frame[3]:SetSize(t, h)
    frame[4]:SetPosition(w - t, 0)
    frame[4]:SetSize(t, h)
end

-- the move panel is docked to this element (or left it)
function LuiHUD:set_move_focused(focused)
    self._move_focused = focused == true
    local color = Style.SUBTLE_FOREGROUND
    if self._move_focused then
        color = Style.CONTROL_BORDER_ACTIVE
    end
    for i = 1, 4 do
        self._move_frame[i]:SetBackColor(color)
    end
    self:_layout_move_frame()
end

-- refresh the move panel's fields when it is docked to this element
function LuiHUD:sync_move_inputs_from_position()
    MoveMode.hud_geometry_changed(self)
end

function LuiHUD:move_to(x, y, commit)
    local nx = _int(x)
    local ny = _int(y)
    if nx == nil or ny == nil then
        return
    end

    nx, ny = self:_clamp_to_screen(nx, ny)
    self:SetPosition(nx, ny)
    self:sync_move_inputs_from_position()

    if commit == true then
        self:commit_move()
    end
end

function LuiHUD:commit_move()
    local x, y = self:GetPosition()
    x = _int(x) or 0
    y = _int(y) or 0
    self:persist_position(x, y)

    if self.on_move_end ~= nil then
        self:on_move_end(x, y)
    end
end

function LuiHUD:_bind_move_chrome()
    local function start_drag(_, args)
        if self._move_enabled ~= true or args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end

        MoveMode.focus_hud(self)
        self._move_dragging = true
        self._move_drag_start_x = args.X
        self._move_drag_start_y = args.Y
        self._move_drag_start_screen_x, self._move_drag_start_screen_y = self:PointToScreen(args.X, args.Y)
        self._move_drag_start_window_x, self._move_drag_start_window_y = self:GetPosition()
    end

    local function continue_drag(_, args)
        if self._move_enabled ~= true or self._move_dragging ~= true or args == nil then
            return
        end

        local sx, sy = self:PointToScreen(args.X, args.Y)
        local dx = sx - self._move_drag_start_screen_x
        local dy = sy - self._move_drag_start_screen_y
        self:move_to(self._move_drag_start_window_x + dx, self._move_drag_start_window_y + dy, false)
    end

    local function stop_drag(_, args)
        if self._move_enabled ~= true or args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end

        local was_dragging = self._move_dragging
        self._move_dragging = false
        if was_dragging then
            self:commit_move()
        end
    end

    self._move_layer.MouseDown = start_drag
    self._move_layer.MouseMove = continue_drag
    self._move_layer.MouseUp = stop_drag
end

function LuiHUD:_clamp_to_screen(x, y)
    local display_width, display_height = Turbine.UI.Display.GetSize()
    local w, h = self:GetSize()
    local max_x = display_width - w
    local max_y = display_height - h
    if max_x < 0 then max_x = 0 end
    if max_y < 0 then max_y = 0 end
    return _clamp(x, 0, max_x), _clamp(y, 0, max_y)
end
