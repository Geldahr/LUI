import "Turbine.UI"

import "LUI.src.StatusBar.common"
import "LUI.src.UI.Widgets.hud"

Launcher = Launcher or {}

local S = _G.STATUS_BAR_COMMON
local Style = UI.Widgets.Style

local LOGO_BUTTON_ICON = "LUI/assets/logo_button.tga"
local ORIENTATION_HORIZONTAL = "horizontal"
local ORIENTATION_VERTICAL = "vertical"
local DIRECTION_AUTO = "auto"
local DIRECTION_UP = "up"
local DIRECTION_DOWN = "down"
local DIRECTION_LEFT = "left"
local DIRECTION_RIGHT = "right"
local UPDATE_INTERVAL = 0.20
local BUTTON_BORDER = 1
local BUTTON_PADDING = 2
local MOVE_MIN_W = 220
local MOVE_MIN_H = 64

local VALID_SHORTCUTS = {
    config = true,
    inventory = true,
    assets = true,
    craft = true,
    travel = true,
    bestiary = true,
}

local function _set_alpha_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _launcher_settings()
    return _G.settings.launcher
end

local function _button_footprint(count, icon_size, spacing)
    return (count * icon_size) + ((count - 1) * spacing)
end

local function _button_icon_size(icon_size)
    local inner = icon_size - ((BUTTON_BORDER + BUTTON_PADDING) * 2)
    if inner < 1 then
        inner = 1
    end
    return inner
end

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

---@class LauncherMenu : LuiHUD
LauncherMenu = class(LuiHUD)

function LauncherMenu:Constructor()
    LuiHUD.Constructor(self, {
        hud_key = "launcher",
        title = TR["LUI Menu"],
        mouse_visible = true,
    })

    self.expanded = false
    self.shortcut_buttons = {}
    self.shortcut_keys = {}
    self.last_update_at = 0

    _set_alpha_blend(self)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self:SetMouseVisible(true)
    self:SetZOrder(35)
    self:SetWantsUpdates(true)

    self.logo_button = self:_new_button(LOGO_BUTTON_ICON)
    self.logo_button.Click = function()
        self:toggle_expanded()
    end

    self.on_move_end = function()
        self:_layout_buttons()
    end
    self.on_move_mode_changed = function()
        self:_layout_buttons()
    end

    self:apply_settings()
    self:SetVisible(true)
end

function LauncherMenu:destroy()
    if self:is_move_mode() == true then
        self:set_move_mode(false)
    end
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self.logo_button:SetParent(nil)
    self:_clear_shortcut_buttons()
    self:unregister_hideable()
    self:SetParent(nil)
end

function LauncherMenu:apply_settings()
    self:apply_native_scaling()
    self:_rebuild_shortcut_buttons()
    self:_resize_window(self:is_move_mode())
    self:apply_hud_position()
    self:_layout_buttons()
    self:_refresh_button_states()
end

function LauncherMenu:set_move_mode(enabled)
    local want = enabled == true
    if want == self:is_move_mode() then
        return
    end

    if want == true then
        self:_resize_window(true)
        LuiHUD.set_move_mode(self, true)
    else
        LuiHUD.set_move_mode(self, false)
        self:_resize_window(false)
    end

    self:_layout_buttons()
end

function LauncherMenu:toggle_expanded()
    self:set_expanded(self.expanded ~= true)
end

function LauncherMenu:set_expanded(expanded)
    local want = expanded == true
    if self.expanded == want then
        return
    end

    self.expanded = want
    self:_layout_buttons()
    self:_refresh_button_states()
end

function LauncherMenu:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < UPDATE_INTERVAL then
        return
    end
    self.last_update_at = now
    self:_refresh_button_states()
end

function LauncherMenu:_new_button(icon)
    local button = UI.Widgets.LuiButton()
    button:SetParent(self)
    button:set_text("")
    button:set_border_thickness(BUTTON_BORDER)
    button:set_padding(BUTTON_PADDING)
    button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleCenter)
    button:set_back_color(Style.CONTROL_BACKGROUND)
    button:set_hover_back_color(Style.CONTROL_BACKGROUND_HOVER)
    button:set_pressed_back_color(Style.CONTROL_BACKGROUND_PRESSED)
    button:set_active_back_color(Style.CONTROL_BACKGROUND_ACTIVE)
    button:set_border_color(Style.CONTROL_BORDER)
    button:set_hover_border_color(Style.CONTROL_BORDER_HOVER)
    button:set_active_border_color(Style.CONTROL_BORDER_ACTIVE)
    button:set_disabled_border_color(Style.CONTROL_BORDER_DISABLED)
    button:SetZOrder(10)
    button._launcher_icon = icon
    return button
end

function LauncherMenu:_clear_shortcut_buttons()
    for i = 1, #self.shortcut_buttons do
        self.shortcut_buttons[i]:SetVisible(false)
        self.shortcut_buttons[i]:SetParent(nil)
    end
    self.shortcut_buttons = {}
    self.shortcut_keys = {}
end

function LauncherMenu:_rebuild_shortcut_buttons()
    self:_clear_shortcut_buttons()

    local configured = _launcher_settings().buttons
    for i = 1, #configured do
        local shortcut_key = configured[i]
        if VALID_SHORTCUTS[shortcut_key] ~= true then
            error("Unknown launcher shortcut: " .. tostring(shortcut_key))
        end

        local icon = S.get_shortcut_icon(shortcut_key)
        if icon == nil then
            error("Missing launcher shortcut icon: " .. tostring(shortcut_key))
        end

        local button = self:_new_button(icon)
        button.shortcut_key = shortcut_key
        button.Click = function()
            S.activate_shortcut(shortcut_key)
            if _launcher_settings().collapse_after_click == true then
                self:set_expanded(false)
            else
                self:_refresh_button_states()
            end
        end

        self.shortcut_keys[#self.shortcut_keys + 1] = shortcut_key
        self.shortcut_buttons[#self.shortcut_buttons + 1] = button
    end
end

function LauncherMenu:_menu_footprint()
    local s = _launcher_settings()
    if s.icon_size < 1 then
        error("Invalid launcher icon size: " .. tostring(s.icon_size))
    end
    if s.spacing < 0 then
        error("Invalid launcher spacing: " .. tostring(s.spacing))
    end

    local count = #self.shortcut_buttons + 1
    local length = _button_footprint(count, s.icon_size, s.spacing)

    if s.orientation == ORIENTATION_HORIZONTAL then
        return length, s.icon_size
    end

    if s.orientation == ORIENTATION_VERTICAL then
        return s.icon_size, length
    end

    error("Invalid launcher orientation: " .. tostring(s.orientation))
end

function LauncherMenu:_resize_window(move_mode)
    local menu_w, menu_h = self:_menu_footprint()
    local width = menu_w
    local height = menu_h

    if move_mode == true then
        width = math.max(width, _scaled_int(MOVE_MIN_W))
        height = math.max(height, _scaled_int(MOVE_MIN_H))
    end

    self:SetSize(width, height)
    self:layout_move_chrome()
end

function LauncherMenu:_resolve_direction()
    local s = _launcher_settings()
    if s.direction ~= DIRECTION_AUTO then
        if s.orientation == ORIENTATION_HORIZONTAL and
            (s.direction == DIRECTION_LEFT or s.direction == DIRECTION_RIGHT) then
            return s.direction
        end
        if s.orientation == ORIENTATION_VERTICAL and
            (s.direction == DIRECTION_UP or s.direction == DIRECTION_DOWN) then
            return s.direction
        end
        error("Invalid launcher direction for orientation: " .. tostring(s.direction))
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left, top = self:GetPosition()
    local width, height = self:_menu_footprint()

    if s.orientation == ORIENTATION_HORIZONTAL then
        if (left + math.floor(width / 2)) < math.floor(display_w / 2) then
            return DIRECTION_RIGHT
        end
        return DIRECTION_LEFT
    end

    if (top + math.floor(height / 2)) < math.floor(display_h / 2) then
        return DIRECTION_DOWN
    end
    return DIRECTION_UP
end

function LauncherMenu:_apply_button_icon(button, size, icon_size)
    button:SetSize(size, size)
    button:set_icon(button._launcher_icon, nil, nil, nil, icon_size, icon_size, LuiButton.icon_position.RIGHT)
end

function LauncherMenu:_layout_buttons()
    local s = _launcher_settings()
    local size = s.icon_size
    local spacing = s.spacing
    local icon_size = _button_icon_size(size)
    local direction = self:_resolve_direction()
    local total_w, total_h = self:GetSize()
    local menu_w, menu_h = self:_menu_footprint()
    local menu_x = 0
    local menu_y = 0

    self:_apply_button_icon(self.logo_button, size, icon_size)

    if s.orientation == ORIENTATION_HORIZONTAL then
        if direction == DIRECTION_LEFT then
            menu_x = total_w - menu_w
        end

        local logo_x = 0
        if direction == DIRECTION_LEFT then
            logo_x = menu_x + menu_w - size
        elseif direction ~= DIRECTION_RIGHT then
            error("Invalid horizontal launcher direction: " .. tostring(direction))
        end
        self.logo_button:SetPosition(logo_x, 0)

        for i = 1, #self.shortcut_buttons do
            local button = self.shortcut_buttons[i]
            self:_apply_button_icon(button, size, icon_size)
            local step = i * (size + spacing)
            local x = direction == DIRECTION_LEFT and (logo_x - step) or (menu_x + step)
            button:SetPosition(x, 0)
            button:SetVisible(self.expanded == true)
        end
        return
    end

    if s.orientation ~= ORIENTATION_VERTICAL then
        error("Invalid launcher orientation: " .. tostring(s.orientation))
    end

    local logo_y = 0
    if direction == DIRECTION_UP then
        menu_y = total_h - menu_h
        logo_y = menu_y + menu_h - size
    elseif direction ~= DIRECTION_DOWN then
        error("Invalid vertical launcher direction: " .. tostring(direction))
    end
    self.logo_button:SetPosition(0, logo_y)

    for i = 1, #self.shortcut_buttons do
        local button = self.shortcut_buttons[i]
        self:_apply_button_icon(button, size, icon_size)
        local step = i * (size + spacing)
        local y = direction == DIRECTION_UP and (logo_y - step) or (menu_y + step)
        button:SetPosition(0, y)
        button:SetVisible(self.expanded == true)
    end
end

function LauncherMenu:_refresh_button_states()
    self.logo_button:set_active(self.expanded == true)

    for i = 1, #self.shortcut_buttons do
        local button = self.shortcut_buttons[i]
        local available, active = S.get_shortcut_state(button.shortcut_key)
        button:set_enabled(available == true)
        button:set_active(active == true)
    end
end

Launcher.LauncherMenu = LauncherMenu
