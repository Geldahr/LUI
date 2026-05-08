import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.native_scaling"
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

local function _disable_native_scaling(window)
    local native_scaling = UI.NativeScaling or _G.LUI_NATIVE_SCALING
    native_scaling.disable(window)
end

---@class CloseWindow: LuiBaseWindow
---@field button LuiButton
CloseWindow = class(LuiBaseWindow)
function CloseWindow:Constructor()
    LuiBaseWindow.Constructor(self, { hideable = false })

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
    self.button:set_text(TR["Done moving UI"])

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

local function _apply_done_window_style()
    MOVE_UI_DONE_WINDOW:apply_native_scaling()
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
        _disable_native_scaling(GRID.window)
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
        GRID.window:SetVisible(GLOBAL_MOVE_ENABLED == true and GRID.hud_visible ~= false and
            MOVE_UI_PREVIEW_LOCKED ~= true)
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

_G.LUI_MOVE_UI = _G.LUI_MOVE_UI or {}
local LUI_MOVE_UI = _G.LUI_MOVE_UI

local MOVE_UI_POSITION_SNAPSHOT = nil
local move_ui_show_done_button = true

local function _snapshot_position(window)
    return {
        left = window.left,
        top = window.top,
    }
end

local function _capture_move_settings_snapshot()
    local hud = _G.loaded_settings.ui.hud
    MOVE_UI_POSITION_SNAPSHOT = {
        self_vitals = _snapshot_position(hud.self_vitals),
        target_vitals = _snapshot_position(hud.target_vitals),
        target_target_vitals = _snapshot_position(hud.target_target_vitals),
        boss_vitals = _snapshot_position(hud.boss_vitals),
        fellowship_vitals = _snapshot_position(hud.fellowship_vitals),
        raid_vitals = _snapshot_position(hud.raid_vitals),
        self_effects = _snapshot_position(hud.self_effects),
        target_effects = _snapshot_position(hud.target_effects),
        cooldowns = _snapshot_position(hud.cooldowns),
        drops = _snapshot_position(hud.drops),
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

    local hud = _G.loaded_settings.ui.hud
    _restore_position(hud.self_vitals, MOVE_UI_POSITION_SNAPSHOT.self_vitals)
    _restore_position(hud.target_vitals, MOVE_UI_POSITION_SNAPSHOT.target_vitals)
    _restore_position(hud.target_target_vitals, MOVE_UI_POSITION_SNAPSHOT.target_target_vitals)
    _restore_position(hud.boss_vitals, MOVE_UI_POSITION_SNAPSHOT.boss_vitals)
    _restore_position(hud.fellowship_vitals, MOVE_UI_POSITION_SNAPSHOT.fellowship_vitals)
    _restore_position(hud.raid_vitals, MOVE_UI_POSITION_SNAPSHOT.raid_vitals)
    _restore_position(hud.self_effects, MOVE_UI_POSITION_SNAPSHOT.self_effects)
    _restore_position(hud.target_effects, MOVE_UI_POSITION_SNAPSHOT.target_effects)
    _restore_position(hud.cooldowns, MOVE_UI_POSITION_SNAPSHOT.cooldowns)
    _restore_position(hud.drops, MOVE_UI_POSITION_SNAPSHOT.drops)

    if PLAYER_VITAL ~= nil then
        PLAYER_VITAL:resize()
    end
    if TARGET_VITAL ~= nil then
        TARGET_VITAL:resize()
    end
    if BOSS_VITAL ~= nil then
        BOSS_VITAL:resize()
    end
    if FELLOWSHIP_VITALS ~= nil then
        FELLOWSHIP_VITALS:apply_settings()
    end
    if RAID_VITALS ~= nil then
        RAID_VITALS:apply_settings()
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:apply_settings()
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:apply_settings()
    end
    if COOLDOWNS_WINDOW ~= nil then
        COOLDOWNS_WINDOW:apply_settings()
    end
    if DROPS_WINDOW ~= nil then
        DROPS_WINDOW:apply_settings()
    end
    if PLAYER_VITAL ~= nil then
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
        local show_done = GLOBAL_MOVE_ENABLED == true and
            GRID.hud_visible ~= false and
            MOVE_UI_PREVIEW_LOCKED ~= true and
            move_ui_show_done_button == true
        MOVE_UI_DONE_WINDOW:SetVisible(show_done)
        if show_done then
            _apply_done_window_style()
            center_move_ui_done_window()
            MOVE_UI_DONE_WINDOW:SetZOrder(999)
        end
    end
end

function LUI_MOVE_UI.show_grid()
    _grid_show()
    _refresh_move_ui_chrome()
end

function LUI_MOVE_UI.hide_grid()
    _grid_hide()
    _refresh_move_ui_chrome()
end

function LUI_MOVE_UI.set_hud_visible(visible)
    GRID.hud_visible = visible == true
    _refresh_move_ui_chrome()
end

function center_move_ui_done_window()
    if MOVE_UI_DONE_WINDOW == nil then
        return
    end

    local display_width, display_height = Turbine.UI.Display.GetSize()
    local w, h = MOVE_UI_DONE_WINDOW:GetSize()
    MOVE_UI_DONE_WINDOW:SetPosition(math.floor((display_width - w) / 2), math.floor((display_height - h) / 2))
end

function _G.toggle_move_mode(show_done_button)
    if FIRST_RUN_QUICK_SETUP_WINDOW ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW:IsVisible() == true and
        FIRST_RUN_QUICK_SETUP_WINDOW.closing ~= true then
        return
    end

    if PLAYER_VITAL == nil then
        return
    end
    set_move_ui_mode(not PLAYER_VITAL:is_move_mode(), nil, nil, show_done_button)
end

function _G.cancel_move_mode()
    if FIRST_RUN_QUICK_SETUP_WINDOW ~= nil and
        FIRST_RUN_QUICK_SETUP_WINDOW:IsVisible() == true and
        FIRST_RUN_QUICK_SETUP_WINDOW.closing ~= true then
        FIRST_RUN_QUICK_SETUP_WINDOW:cancel_setup()
        return
    end

    if PLAYER_VITAL == nil or PLAYER_VITAL:is_move_mode() ~= true then
        return
    end

    set_move_ui_mode(false, nil, true)
end

function _G.refresh_move_mode_snapshot()
    if PLAYER_VITAL == nil or PLAYER_VITAL:is_move_mode() ~= true then
        return
    end

    _capture_move_settings_snapshot()
end

function _G.set_move_ui_preview_lock(locked)
    MOVE_UI_PREVIEW_LOCKED = locked == true
    _refresh_move_ui_chrome()
end

function _G.set_move_ui_mode(enabled, return_to_config, cancel_changes, show_done_button)
    if PLAYER_VITAL == nil or TARGET_VITAL == nil then
        return
    end

    if enabled == true and is_lui_hud_visible() ~= true then
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
    move_ui_show_done_button = enabled == true and show_done_button ~= false

    if enabled then
        _capture_move_settings_snapshot()
    end

    PLAYER_VITAL:set_move_mode(enabled)
    TARGET_VITAL:set_move_mode(enabled)
    if BOSS_VITAL ~= nil then
        BOSS_VITAL:set_move_mode(enabled)
    end
    if FELLOWSHIP_VITALS ~= nil then
        FELLOWSHIP_VITALS:set_move_mode(enabled)
    end
    if RAID_VITALS ~= nil then
        RAID_VITALS:set_move_mode(enabled)
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:set_move_mode(enabled)
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:set_move_mode(enabled)
    end
    if COOLDOWNS_WINDOW ~= nil then
        COOLDOWNS_WINDOW:set_move_mode(enabled)
    end
    if DROPS_WINDOW ~= nil then
        DROPS_WINDOW:set_move_mode(enabled)
    end

    if enabled and move_ui_show_done_button == true then
        _ensure_move_ui_done_window()
    end

    _refresh_move_ui_chrome()

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
