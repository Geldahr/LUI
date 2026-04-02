import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets"

GLOBAL_MOVE_ENABLED = false
local MOVE_UI_PREVIEW_LOCKED = false

local GRID = {
    window = nil,
    active_count = 0,
    hud_visible = true,
    display_width = nil,
    display_height = nil,
    lines = {},
}

local MOVEABLE_INSTANCES = setmetatable({}, { __mode = "k" })
---@type CloseWindow
MOVE_UI_DONE_WINDOW = nil


local function _scaled_size(value)
    return value * _G.settings.global.scale
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

---@class CloseWindow: Turbine.UI.Window
---@field button LuiButton
CloseWindow = class(Turbine.UI.Window)
function CloseWindow:Constructor()
    Turbine.UI.Window.Constructor(self)

    self:SetSize(119, 22)
    self:SetVisible(false)
    self:SetMouseVisible(true)
    self:SetZOrder(999)
    self:SetOpacity(0.8)

    self.button = UI.Widgets.LuiButton()
    self.button:SetParent(self)
    self.button:SetSize(self:GetWidth(), self:GetHeight())
    self.button:SetPosition(0, 0)
    self.button:set_font(_scaled_font("Verdana", 13))
    self.button:set_text(TR("Done moving UI"))

    self.button.Click = function()
        set_move_ui_mode(false)
    end

    self:apply_style()
end

function CloseWindow:apply_style()
    local w = _scaled_int(119)
    local h = _scaled_int(22)

    self:SetSize(w, h)
    self.button:SetSize(w, h)
    self.button:set_font(_scaled_font("Verdana", 13))
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

local function _trim_submit_suffix(text)
    if type(text) ~= "string" then
        return nil
    end

    if string.sub(text, -1) ~= "\n" then
        return nil
    end

    return string.gsub(text, "[\r\n]+$", "")
end

local function _nudge_delta(action)
    if action == 29 then
        return 0, -1
    end
    if action == 113 then
        return 0, 1
    end
    if action == 127 then
        return -1, 0
    end
    if action == 108 then
        return 1, 0
    end
    return nil, nil
end

local function _apply_done_window_style()
    MOVE_UI_DONE_WINDOW:apply_style()
end

local function _ensure_move_ui_done_window()
    if MOVE_UI_DONE_WINDOW ~= nil then
        return
    end

    MOVE_UI_DONE_WINDOW = CloseWindow()

    center_move_ui_done_window()
end

local function _clear_lines()
    for i = 1, #GRID.lines do
        local c = GRID.lines[i]
        if c ~= nil then
            c:SetParent(nil)
        end
    end
    GRID.lines = {}
end

local function _add_vline(parent, x, thickness, color, width, height)
    if x < 0 or x > (width - thickness) then
        return
    end
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBackColor(color)
    c:SetPosition(x, 0)
    c:SetSize(thickness, height)
    table.insert(GRID.lines, c)
end

local function _add_hline(parent, y, thickness, color, width, height)
    if y < 0 or y > (height - thickness) then
        return
    end
    local c = Turbine.UI.Control()
    c:SetParent(parent)
    c:SetMouseVisible(false)
    c:SetBackColor(color)
    c:SetPosition(0, y)
    c:SetSize(width, thickness)
    table.insert(GRID.lines, c)
end

local function _ensure_grid()
    local display_width, display_height = Turbine.UI.Display.GetSize()

    if GRID.window == nil then
        GRID.window = Turbine.UI.Window()
        GRID.window:SetPosition(0, 0)
        GRID.window:SetMouseVisible(false)
        GRID.window:SetVisible(false)
        GRID.window:SetZOrder(-50)
    end

    if GRID.display_width == display_width and GRID.display_height == display_height then
        return
    end

    GRID.display_width = display_width
    GRID.display_height = display_height

    GRID.window:SetSize(display_width, display_height)
    GRID.window:SetBackColor(Turbine.UI.Color(0.10, 0, 0, 0))

    _clear_lines()

    local center_x = math.floor(display_width / 2)
    local center_y = math.floor(display_height / 2)

    local main_color = Turbine.UI.Color(0.30, 1, 1, 1)
    local hundred_color = Turbine.UI.Color(0.16, 1, 1, 1)
    local twenty_five_color = Turbine.UI.Color(0.08, 1, 1, 1)

    local main_thickness = 2
    local other_thickness = 1

    _add_vline(GRID.window, center_x - math.floor(main_thickness / 2), main_thickness, main_color, display_width,
        display_height)
    _add_hline(GRID.window, center_y - math.floor(main_thickness / 2), main_thickness, main_color, display_width,
        display_height)

    local max_x = math.max(center_x, display_width - center_x)
    local max_y = math.max(center_y, display_height - center_y)

    local offset = 100
    while offset <= max_x do
        _add_vline(GRID.window, center_x + offset, other_thickness, hundred_color, display_width, display_height)
        _add_vline(GRID.window, center_x - offset, other_thickness, hundred_color, display_width, display_height)
        offset = offset + 100
    end

    offset = 100
    while offset <= max_y do
        _add_hline(GRID.window, center_y + offset, other_thickness, hundred_color, display_width, display_height)
        _add_hline(GRID.window, center_y - offset, other_thickness, hundred_color, display_width, display_height)
        offset = offset + 100
    end

    offset = 25
    while offset <= max_x do
        if (offset % 100) ~= 0 then
            _add_vline(GRID.window, center_x + offset, other_thickness, twenty_five_color, display_width, display_height)
            _add_vline(GRID.window, center_x - offset, other_thickness, twenty_five_color, display_width, display_height)
        end
        offset = offset + 25
    end

    offset = 25
    while offset <= max_y do
        if (offset % 100) ~= 0 then
            _add_hline(GRID.window, center_y + offset, other_thickness, twenty_five_color, display_width, display_height)
            _add_hline(GRID.window, center_y - offset, other_thickness, twenty_five_color, display_width, display_height)
        end
        offset = offset + 25
    end
end

local function _grid_show()
    GRID.active_count = (GRID.active_count or 0) + 1
    _ensure_grid()
    if GRID.window ~= nil then
        GRID.window:SetVisible(GRID.hud_visible ~= false and MOVE_UI_PREVIEW_LOCKED ~= true)
    end
end

local function _grid_hide()
    GRID.active_count = (GRID.active_count or 0) - 1
    if GRID.active_count < 0 then
        GRID.active_count = 0
    end
    if GRID.active_count == 0 and GRID.window ~= nil then
        GRID.window:SetVisible(false)
    end
end

local MOVE_UI_POSITION_SNAPSHOT = nil

local function _snapshot_position(window)
    return {
        left = window.left,
        top = window.top,
    }
end

local function _capture_move_settings_snapshot()
    local s = _G.loaded_settings
    MOVE_UI_POSITION_SNAPSHOT = {
        self_vitals = _snapshot_position(s.self.vitals.window),
        target_vitals = _snapshot_position(s.target.vitals.window),
        target_targets_target = _snapshot_position(s.target.vitals.targets_target.window),
        target_boss_vitals = _snapshot_position(s.target.boss_vitals.window),
        party = _snapshot_position(s.party.window),
        self_expiring_effects = _snapshot_position(s.self.expiring_effects.window),
        target_expiring_effects = _snapshot_position(s.target.expiring_effects.window),
        cooldowns = _snapshot_position(s.self.cooldowns.window),
    }
end

local function _restore_position(window, snapshot)
    window.left = snapshot.left
    window.top = snapshot.top
end

local function _restore_saved_move_settings()
    if MOVE_UI_POSITION_SNAPSHOT == nil then
        return
    end

    local s = _G.loaded_settings
    _restore_position(s.self.vitals.window, MOVE_UI_POSITION_SNAPSHOT.self_vitals)
    _restore_position(s.target.vitals.window, MOVE_UI_POSITION_SNAPSHOT.target_vitals)
    _restore_position(s.target.vitals.targets_target.window, MOVE_UI_POSITION_SNAPSHOT.target_targets_target)
    _restore_position(s.target.boss_vitals.window, MOVE_UI_POSITION_SNAPSHOT.target_boss_vitals)
    _restore_position(s.party.window, MOVE_UI_POSITION_SNAPSHOT.party)
    _restore_position(s.self.expiring_effects.window, MOVE_UI_POSITION_SNAPSHOT.self_expiring_effects)
    _restore_position(s.target.expiring_effects.window, MOVE_UI_POSITION_SNAPSHOT.target_expiring_effects)
    _restore_position(s.self.cooldowns.window, MOVE_UI_POSITION_SNAPSHOT.cooldowns)

    if PLAYER_VITAL ~= nil and PLAYER_VITAL.resize ~= nil then
        PLAYER_VITAL:resize()
    end
    if TARGET_VITAL ~= nil and TARGET_VITAL.resize ~= nil then
        TARGET_VITAL:resize()
    end
    if BOSS_VITAL ~= nil and BOSS_VITAL.resize ~= nil then
        BOSS_VITAL:resize()
    end
    if PARTY_VITALS ~= nil and PARTY_VITALS.apply_settings ~= nil then
        PARTY_VITALS:apply_settings()
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil and EXPIRING_SELF_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:apply_settings()
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil and EXPIRING_TARGET_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:apply_settings()
    end
    if COOLDOWNS_WINDOW ~= nil and COOLDOWNS_WINDOW.apply_settings ~= nil then
        COOLDOWNS_WINDOW:apply_settings()
    end
    if PLAYER_VITAL ~= nil and PLAYER_VITAL.on_target_changed ~= nil then
        PLAYER_VITAL:on_target_changed()
    end

    MOVE_UI_POSITION_SNAPSHOT = nil
end

local move_ui_return_to_config = false

local function _refresh_move_ui_chrome()
    if GRID.window ~= nil then
        local show_grid = GLOBAL_MOVE_ENABLED == true and
            GRID.hud_visible ~= false and
            MOVE_UI_PREVIEW_LOCKED ~= true and
            (GRID.active_count or 0) > 0
        GRID.window:SetVisible(show_grid)
    end

    if MOVE_UI_DONE_WINDOW ~= nil then
        local show_done = GLOBAL_MOVE_ENABLED == true and MOVE_UI_PREVIEW_LOCKED ~= true
        MOVE_UI_DONE_WINDOW:SetVisible(show_done)
        if show_done then
            _apply_done_window_style()
            center_move_ui_done_window()
            MOVE_UI_DONE_WINDOW:SetZOrder(999)
        end
    end
end

function center_move_ui_done_window()
    if MOVE_UI_DONE_WINDOW == nil then
        return
    end

    local display_width, display_height = Turbine.UI.Display.GetSize()
    local w, h = MOVE_UI_DONE_WINDOW:GetSize()
    MOVE_UI_DONE_WINDOW:SetPosition(math.floor((display_width - w) / 2), math.floor((display_height - h) / 2))
end

function _G.toggle_move_mode()
    if FIRST_RUN_QUICK_SETUP_WINDOW ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW.IsVisible ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW:IsVisible() == true and
        FIRST_RUN_QUICK_SETUP_WINDOW.closing ~= true then
        return
    end

    if PLAYER_VITAL == nil then
        return
    end
    set_move_ui_mode(not PLAYER_VITAL:is_move_mode())
end

function _G.cancel_move_mode()
    if FIRST_RUN_QUICK_SETUP_WINDOW ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW.IsVisible ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW:IsVisible() == true and
        FIRST_RUN_QUICK_SETUP_WINDOW.closing ~= true then
        if FIRST_RUN_QUICK_SETUP_WINDOW.cancel_setup ~= nil then
            FIRST_RUN_QUICK_SETUP_WINDOW:cancel_setup()
        end
        return
    end

    if PLAYER_VITAL == nil or PLAYER_VITAL:is_move_mode() ~= true then
        return
    end

    set_move_ui_mode(false, nil, true)
end

function _G.refresh_move_mode_snapshot()
    if PLAYER_VITAL == nil or PLAYER_VITAL.is_move_mode == nil or PLAYER_VITAL:is_move_mode() ~= true then
        return
    end

    _capture_move_settings_snapshot()
end

function _G.set_move_ui_preview_lock(locked)
    MOVE_UI_PREVIEW_LOCKED = locked == true
    _refresh_move_ui_chrome()
end

function _G.set_move_ui_mode(enabled, return_to_config, cancel_changes)
    if PLAYER_VITAL == nil or TARGET_VITAL == nil then
        return
    end

    local save_changes = cancel_changes ~= true

    if enabled and CONFIG_WINDOW ~= nil and CONFIG_WINDOW:IsVisible() then
        move_ui_return_to_config = true
        CONFIG_WINDOW:SetVisible(false)
    elseif return_to_config == true then
        move_ui_return_to_config = true
    end

    GLOBAL_MOVE_ENABLED = enabled == true

    if enabled then
        _capture_move_settings_snapshot()
    end

    PLAYER_VITAL:set_move_mode(enabled)
    TARGET_VITAL:set_move_mode(enabled)
    if BOSS_VITAL ~= nil and BOSS_VITAL.set_move_mode ~= nil then
        BOSS_VITAL:set_move_mode(enabled)
    end
    if PARTY_VITALS ~= nil and PARTY_VITALS.set_move_mode ~= nil then
        PARTY_VITALS:set_move_mode(enabled)
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:set_move_mode(enabled)
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:set_move_mode(enabled)
    end
    if COOLDOWNS_WINDOW ~= nil and COOLDOWNS_WINDOW.set_move_mode ~= nil then
        COOLDOWNS_WINDOW:set_move_mode(enabled)
    end

    if enabled then
        _ensure_move_ui_done_window()
    end

    if MOVE_UI_DONE_WINDOW ~= nil then
        _refresh_move_ui_chrome()
    end

    if not enabled then
        if save_changes == true then
            MOVE_UI_POSITION_SNAPSHOT = nil
        else
            _restore_saved_move_settings()
        end
    end

    if not enabled then
        _refresh_move_ui_chrome()
    end

    if (not enabled) and move_ui_return_to_config and CONFIG_WINDOW ~= nil then
        move_ui_return_to_config = false
        CONFIG_WINDOW:SetVisible(true)
        CONFIG_WINDOW:bring_to_front()
    end
end

Moveable = class(Turbine.UI.Window)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function Moveable:Constructor(target_window, on_move, title)
    Turbine.UI.Window.Constructor(self)

    self.target = target_window
    self.on_move = on_move
    self.on_move_end = nil
    self.title_text = title

    self.enabled = false
    self.dragging = false
    self.drag_start_x = 0
    self.drag_start_y = 0
    self.drag_start_screen_x = 0
    self.drag_start_screen_y = 0
    self.drag_start_win_x = 0
    self.drag_start_win_y = 0

    self.updating_xy = false
    self._grid_shown = false
    self._syncing = false
    self.focused_input = nil

    MOVEABLE_INSTANCES[self] = true

    local x, y = 0, 0
    if self.target ~= nil then
        x, y = self.target:GetPosition()
    end
    self:SetPosition(x, y)
    self:SetMouseVisible(false)
    self:SetVisible(false)
    self:SetZOrder(999)
    self:SetBackColor(Turbine.UI.Color(0.35, 0, 0, 0))

    self.header_height = 30

    self.header = Turbine.UI.Control()
    self.header:SetParent(self)
    self.header:SetMouseVisible(false)
    self.header:SetBackColor(Turbine.UI.Color(0.45, 0, 0, 0))

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self.header)
    self.title:SetMouseVisible(false)
    self.title:SetSelectable(false)
    self.title:SetForeColor(Turbine.UI.Color(1, 1, 1))
    self.title:SetFont(_scaled_font("Verdana", 12))
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.xy_container = Turbine.UI.Control()
    self.xy_container:SetParent(self.header)
    self.xy_container:SetMouseVisible(false)

    self.x_label = UI.Widgets.LuiLabel()
    self.x_label:SetParent(self.xy_container)
    self.x_label:SetMouseVisible(false)
    self.x_label:SetSelectable(false)
    self.x_label:SetForeColor(Turbine.UI.Color(1, 1, 1))
    self.x_label:SetFont(_scaled_font("Verdana", 10))
    self.x_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.x_label:SetText("X")

    self.x_box = Turbine.UI.Lotro.TextBox()
    self.x_box:SetParent(self.xy_container)
    self.x_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.x_box:SetWantsKeyEvents(true)

    self.y_label = UI.Widgets.LuiLabel()
    self.y_label:SetParent(self.xy_container)
    self.y_label:SetMouseVisible(false)
    self.y_label:SetSelectable(false)
    self.y_label:SetForeColor(Turbine.UI.Color(1, 1, 1))
    self.y_label:SetFont(_scaled_font("Verdana", 10))
    self.y_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.y_label:SetText("Y")

    self.y_box = Turbine.UI.Lotro.TextBox()
    self.y_box:SetParent(self.xy_container)
    self.y_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.y_box:SetWantsKeyEvents(true)

    self.x_box.FocusGained = function()
        self.focused_input = "x"
    end
    self.y_box.FocusGained = function()
        self.focused_input = "y"
    end

    self.x_box.KeyDown = function(_, args)
        if self.focused_input ~= "x" or self.x_box:HasFocus() ~= true or args == nil then
            return
        end

        local dx, dy = _nudge_delta(args.Action)
        if dx == nil or dy == nil then
            return
        end

        if Turbine.UI.Control.IsControlKeyDown() then
            return
        end

        local step = Turbine.UI.Control.IsAltKeyDown() and 10 or 1
        local x, y = self.target:GetPosition()
        self:move_to(x + (dx * step), y + (dy * step), true)
    end
    self.y_box.KeyDown = function(_, args)
        if self.focused_input ~= "y" or self.y_box:HasFocus() ~= true or args == nil then
            return
        end

        local dx, dy = _nudge_delta(args.Action)
        if dx == nil or dy == nil then
            return
        end

        if Turbine.UI.Control.IsControlKeyDown() then
            return
        end

        local step = Turbine.UI.Control.IsAltKeyDown() and 10 or 1
        local x, y = self.target:GetPosition()
        self:move_to(x + (dx * step), y + (dy * step), true)
    end

    self.x_box.TextChanged = function()
        if self.updating_xy then
            return
        end

        local trimmed = _trim_submit_suffix(self.x_box:GetText())
        if trimmed ~= nil then
            self.updating_xy = true
            self.x_box:SetText(trimmed)
            self.updating_xy = false
            self:apply_from_inputs(true)
        end
    end

    self.y_box.TextChanged = function()
        if self.updating_xy then
            return
        end

        local trimmed = _trim_submit_suffix(self.y_box:GetText())
        if trimmed ~= nil then
            self.updating_xy = true
            self.y_box:SetText(trimmed)
            self.updating_xy = false
            self:apply_from_inputs(true)
        end
    end

    self.x_box.FocusLost = function()
        if self.focused_input == "x" then
            self.focused_input = nil
        end
        self:apply_from_inputs(true)
    end
    self.y_box.FocusLost = function()
        if self.focused_input == "y" then
            self.focused_input = nil
        end
        self:apply_from_inputs(true)
    end

    self.MouseDown = function(_, args)
        if args.Button == Turbine.UI.MouseButton.Left then
            self.dragging = true
            self.drag_start_x = args.X
            self.drag_start_y = args.Y
            self.drag_start_screen_x, self.drag_start_screen_y = self:PointToScreen(args.X, args.Y)
            self.drag_start_win_x, self.drag_start_win_y = self.target:GetPosition()
        end
    end

    self.MouseMove = function(_, args)
        if self.dragging then
            local sx, sy = self:PointToScreen(args.X, args.Y)
            local dx = sx - self.drag_start_screen_x
            local dy = sy - self.drag_start_screen_y
            self:move_to(self.drag_start_win_x + dx, self.drag_start_win_y + dy, false)
        end
    end

    self.MouseUp = function(_, args)
        if args.Button == Turbine.UI.MouseButton.Left then
            local was_dragging = self.dragging
            self.dragging = false
            if was_dragging then
                self:commit()
            end
        end
    end

    self:update_title()
    self:update_size()

    add_callback(self.target, "SizeChanged", function() self:update_size() end)
    add_callback(self.target, "PositionChanged", function()
        self:sync_from_target()
        self:sync_inputs_from_target()
    end)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function Moveable.set_hud_visible(visible)
    GRID.hud_visible = visible == true
    if GRID.window ~= nil then
        if GRID.hud_visible then
            if (GRID.active_count or 0) > 0 then
                _ensure_grid()
                GRID.window:SetVisible(true)
            end
        else
            GRID.window:SetVisible(false)
        end
    end

    for inst in pairs(MOVEABLE_INSTANCES) do
        if inst ~= nil and inst.enabled == true then
            local want_visible = GRID.hud_visible ~= false
            inst:SetVisible(want_visible)
            inst:SetMouseVisible(want_visible)
            if want_visible then
                inst:update_size()
                inst:sync_from_target()
            end
        end
    end
end

function Moveable:set_on_move_end(callback)
    self.on_move_end = callback
end

function Moveable:is_move_mode()
    return self.enabled == true
end

function Moveable:set_title(title)
    self.title_text = title
    self:update_title()
end

function Moveable:update_title()
    if type(self.title_text) == "string" then
        self.title:SetText(self.title_text)
    else
        self.title:SetText("")
    end
end

function Moveable:update_size()
    if self.target == nil then
        return
    end
    self:apply_ui_scale()
    local w, h = self.target:GetSize()
    self:SetSize(w, h)
    self:sync_from_target()

    local padding = _scaled_int(4)
    local input_w = _scaled_int(52)
    local input_h = _scaled_int(16)
    local gap = _scaled_int(4)
    local label_w = _scaled_int(10)

    local single_header_h = _scaled_int(22)
    local title_row_h = _scaled_int(19)
    local row_h = _scaled_int(19)

    local xy_single_w = (label_w + input_w) * 2 + gap * 3
    local min_title_w = _scaled_int(59)
    local need_single_w = (padding * 2) + xy_single_w + min_title_w
    local stacked = w < need_single_w

    if stacked then
        self.header_height = title_row_h + (row_h * 2)
    else
        self.header_height = single_header_h
    end

    self.header:SetPosition(0, 0)
    self.header:SetSize(w, self.header_height)

    if stacked then
        self.title:SetPosition(padding, 0)
        self.title:SetSize(w - (padding * 2), title_row_h)

        local xy_w = w - (padding * 2)
        if xy_w < _scaled_int(30) then xy_w = _scaled_int(30) end
        self.xy_container:SetPosition(padding, title_row_h)
        self.xy_container:SetSize(xy_w, row_h * 2)

        local box_w = xy_w - label_w - gap
        if box_w < _scaled_int(15) then box_w = _scaled_int(15) end

        self.x_label:SetPosition(0, 0)
        self.x_label:SetSize(label_w, row_h)
        self.x_box:SetPosition(label_w + gap, math.floor((row_h - input_h) / 2))
        self.x_box:SetSize(box_w, input_h)

        self.y_label:SetPosition(0, row_h)
        self.y_label:SetSize(label_w, row_h)
        self.y_box:SetPosition(label_w + gap, row_h + math.floor((row_h - input_h) / 2))
        self.y_box:SetSize(box_w, input_h)
    else
        local xy_w = xy_single_w
        if xy_w > (w - _scaled_int(7)) then
            xy_w = w - _scaled_int(7)
            if xy_w < _scaled_int(30) then xy_w = _scaled_int(30) end
        end
        self.xy_container:SetSize(xy_w, self.header_height)
        self.xy_container:SetPosition(w - xy_w - padding, 0)

        local x = gap
        local y = math.floor((self.header_height - input_h) / 2)
        self.x_label:SetPosition(x, 0)
        self.x_label:SetSize(label_w, self.header_height)
        x = x + label_w
        self.x_box:SetPosition(x, y)
        self.x_box:SetSize(input_w, input_h)
        x = x + input_w + gap
        self.y_label:SetPosition(x, 0)
        self.y_label:SetSize(label_w, self.header_height)
        x = x + label_w
        self.y_box:SetPosition(x, y)
        self.y_box:SetSize(input_w, input_h)

        self.title:SetPosition(padding, 0)
        self.title:SetSize(w - xy_w - padding * 2, self.header_height)
    end
end

function Moveable:apply_ui_scale()
    local title_font = _scaled_font("Verdana", 12)
    local label_font = _scaled_font("Verdana", 10)
    local input_font = _scaled_font("Verdana", 10)

    self.title:SetFont(title_font)
    self.x_label:SetFont(label_font)
    self.x_box:SetFont(input_font)
    self.y_label:SetFont(label_font)
    self.y_box:SetFont(input_font)
end

function Moveable:sync_from_target()
    if self.enabled ~= true then
        return
    end
    if self.target == nil then
        return
    end
    if self._syncing then
        return
    end
    self._syncing = true
    local x, y = self.target:GetPosition()
    self:SetPosition(_int(x) or 0, _int(y) or 0)
    self._syncing = false
end

function Moveable:sync_inputs_from_target()
    if self.enabled ~= true then
        return
    end
    if self.updating_xy then
        return
    end
    self.updating_xy = true
    local x, y = self.target:GetPosition()
    self.x_box:SetText(tostring(_int(x) or 0))
    self.y_box:SetText(tostring(_int(y) or 0))
    self.updating_xy = false
end

function Moveable:move_to(x, y, commit)
    local nx = _int(x)
    local ny = _int(y)
    if nx == nil or ny == nil then
        return
    end

    nx, ny = self:_clamp_to_screen(nx, ny)

    if self.on_move ~= nil then
        self.on_move(nx, ny)
    else
        self.target:SetPosition(nx, ny)
    end

    self:sync_from_target()
    self:sync_inputs_from_target()

    if commit == true then
        self:commit()
    end
end

function Moveable:apply_from_inputs(commit)
    if self.target == nil then
        return
    end

    local cur_x, cur_y = self.target:GetPosition()
    local x = _int(self.x_box:GetText())
    local y = _int(self.y_box:GetText())
    if x == nil then x = _int(cur_x) or 0 end
    if y == nil then y = _int(cur_y) or 0 end

    self:move_to(x, y, commit == true)
end

function Moveable:commit()
    if self.on_move_end ~= nil then
        local x, y = self.target:GetPosition()
        self.on_move_end(_int(x) or 0, _int(y) or 0)
    end
end

function Moveable:set_move_mode(enabled)
    local want = enabled == true
    if want == self.enabled then
        return
    end

    self.enabled = want
    self.dragging = false

    if self.enabled then
        local want_visible = GRID.hud_visible ~= false
        self:SetVisible(want_visible)
        self:SetMouseVisible(want_visible)
        self:update_size()
        self:sync_inputs_from_target()
        if self.target ~= nil then
            local x, y = self.target:GetPosition()
            local nx, ny = self:_clamp_to_screen(_int(x) or 0, _int(y) or 0)
            if nx ~= _int(x) or ny ~= _int(y) then
                self:move_to(nx, ny, true)
            end
        end

        if self._grid_shown ~= true then
            self._grid_shown = true
            _grid_show()
        end
    else
        self.focused_input = nil
        self:SetVisible(false)
        self:SetMouseVisible(false)

        if self._grid_shown == true then
            self._grid_shown = false
            _grid_hide()
        end
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function Moveable:_clamp_to_screen(x, y)
    if self.target == nil then
        return x, y
    end

    local display_width, display_height = Turbine.UI.Display.GetSize()
    local w, h = self.target:GetSize()
    local max_x = display_width - w
    local max_y = display_height - h
    if max_x < 0 then max_x = 0 end
    if max_y < 0 then max_y = 0 end

    return _clamp(x, 0, max_x), _clamp(y, 0, max_y)
end
