-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- A window's menu bar: its menus side by side. Too narrow for all of them
-- (LuiWindow decides), it collapses into a single "Menu" whose rows open
-- the same menus as submenus: the menu objects and their actions are
-- reused, never copied, so checks, enabled states and callbacks stay right
-- in both modes.

local TR = _G.LUI.Locale.TR
local Utils = _G.LUI.Utils
local FONT_TO_LOTRO = Utils.FONT_TO_LOTRO
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.Widgets.menu"
import "LUI.src.UI.Widgets.style"
import "LUI.src.Utils.font"

local Widgets = UI.Widgets
local LuiMenu = Widgets.LuiMenu
local Style = Widgets.Style

local function _scaled_font(scale)
    return FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE * scale)
end

local function _set_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

-- The "Menu" of a collapsed bar: one row per bar menu. Each open copies the
-- menus' current title and enabled state onto the rows (a disabled bar menu
-- cannot open, so its row is greyed).
---@class LuiCollapsedMenu : LuiMenu
local LuiCollapsedMenu = class(LuiMenu)

function LuiCollapsedMenu:open()
    for i = 1, #self._items do
        local row = self._items[i]
        local menu = row._submenu
        row:set_text(menu._title)
        row:set_enabled(menu.button._enabled == true)
    end
    LuiMenu.open(self)
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
    -- the menus' total width, nil = measure again
    self._expanded_w = nil
    self._collapsed = false
    -- the "Menu" host and its rows (by menu index), built on the first
    -- collapse and again when menus are added or removed
    self._collapse_menu = nil
    self._collapse_rows = nil

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
    self._expanded_w = nil
    for i = 1, #self._menus do
        self._menus[i]:set_scale(self._scale)
        self._menus[i]:set_font(self._font)
    end
    if self._collapse_menu ~= nil then
        self._collapse_menu:set_scale(self._scale)
        self._collapse_menu:set_font(self._font)
    end
    self:_layout()
end

function LuiMenuBar:set_font(font)
    if font == nil then
        return
    end
    self._font = font
    self._expanded_w = nil
    for i = 1, #self._menus do
        self._menus[i]:set_font(font)
    end
    if self._collapse_menu ~= nil then
        self._collapse_menu:set_font(font)
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
    -- menu-bar menus cover the whole host window (header bar included) so
    -- hovering across the bar switches menus
    menu._in_menu_bar = true
    if type(title_or_menu) ~= "table" then
        menu:set_scroll_options(options)
    end
    menu:set_scale(self._scale)
    menu:set_font(self._font)

    self._menus[#self._menus + 1] = menu
    self:_menus_changed()
    return menu
end

function LuiMenuBar:remove_menu(menu)
    for i = 1, #self._menus do
        if self._menus[i] == menu then
            menu:close()
            self:_unlink(menu)
            menu:SetParent(nil)
            table.remove(self._menus, i)
            self:_menus_changed()
            return menu
        end
    end
    error("LuiMenuBar:remove_menu menu is not registered")
end

-- a collapsed bar is linked again to the new menu list
function LuiMenuBar:_menus_changed()
    self._expanded_w = nil
    self:_discard_collapse_menu()
    if self._collapsed == true then
        if #self._menus == 0 then
            self._collapsed = false
        else
            self:_link_collapsed()
        end
    end
    self:_layout()
    if self.on_change ~= nil then
        self:on_change()
    end
end

-- the width with every menu shown
function LuiMenuBar:expanded_width()
    if self._expanded_w == nil then
        local width = 0
        for i = 1, #self._menus do
            width = width + self._menus[i]:preferred_width()
        end
        self._expanded_w = width
    end
    return self._expanded_w
end

function LuiMenuBar:preferred_width()
    if self._collapsed == true then
        return self._collapse_menu:preferred_width()
    end
    return self:expanded_width()
end

function LuiMenuBar:is_collapsed()
    return self._collapsed
end

-- Shows the menus side by side, or the single "Menu" (never for an empty
-- bar). Only a change of state re-links anything.
function LuiMenuBar:set_collapsed(collapsed)
    collapsed = collapsed == true and #self._menus > 0
    if collapsed == self._collapsed then
        return
    end
    self:_close_all()
    self._collapsed = collapsed
    if collapsed == true then
        self:_link_collapsed()
    else
        for i = 1, #self._menus do
            self:_unlink(self._menus[i])
        end
        self._collapse_menu:SetVisible(false)
    end
    self:_layout()
end

function LuiMenuBar:_close_all()
    for i = 1, #self._menus do
        self._menus[i]:close()
    end
    if self._collapse_menu ~= nil then
        self._collapse_menu:close()
    end
end

-- The host is rebuilt, never emptied: LuiMenu:clear_items() also clears the
-- submenus, which are the bar's own menus.
function LuiMenuBar:_ensure_collapse_menu()
    if self._collapse_menu ~= nil then
        return
    end
    local host = LuiCollapsedMenu()
    host:set_title(TR["Menu"])
    host:SetParent(self)
    host._in_menu_bar = true
    host:set_scale(self._scale)
    host:set_font(self._font)
    host:SetVisible(false)
    local rows = {}
    for i = 1, #self._menus do
        local menu = self._menus[i]
        local row = host:add_action({ text = menu._title })
        row:_set_submenu(menu)
        rows[i] = row
    end
    self._collapse_menu = host
    self._collapse_rows = rows
end

function LuiMenuBar:_discard_collapse_menu()
    local host = self._collapse_menu
    if host == nil then
        return
    end
    host:close()
    -- hidden before detaching: a control detached while visible keeps
    -- drawing at the screen's top-left
    host:SetVisible(false)
    host:SetParent(nil)
    self._collapse_menu = nil
    self._collapse_rows = nil
end

-- every menu becomes a submenu of the host, opened from its row
function LuiMenuBar:_link_collapsed()
    self:_ensure_collapse_menu()
    for i = 1, #self._menus do
        local menu = self._menus[i]
        menu._parent_menu = self._collapse_menu
        menu._parent_action = self._collapse_rows[i]
        menu._in_menu_bar = false
        menu:SetVisible(false)
    end
end

-- a menu back in the bar (its title button shows again in _layout)
function LuiMenuBar:_unlink(menu)
    menu._parent_menu = nil
    menu._parent_action = nil
    menu._in_menu_bar = true
end

function LuiMenuBar:_layout()
    local height = self:GetHeight()
    local width = self:GetWidth()
    if self._collapsed == true then
        local host = self._collapse_menu
        local host_w = math.min(host:preferred_width(), width)
        host:SetPosition(0, 0)
        host:SetSize(host_w, height)
        host:SetVisible(host_w > 0)
        return
    end
    local x = 0
    for i = 1, #self._menus do
        local menu = self._menus[i]
        local menu_w = math.min(menu:preferred_width(), math.max(0, width - x))
        menu:SetPosition(x, 0)
        menu:SetSize(menu_w, height)
        menu:SetVisible(menu_w > 0)
        x = x + menu_w
    end
end

UI.Widgets.LuiMenuBar = LuiMenuBar
