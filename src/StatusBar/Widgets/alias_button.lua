import "Turbine.UI"
import "Turbine.UI.Lotro"

local S = _G.STATUS_BAR_COMMON
local BUTTON_FILL_COLOR = Turbine.UI.Color(1.00, 0.08, 0.10, 0.12)
local BUTTON_FILL_HOVER_COLOR = Turbine.UI.Color(1.00, 0.12, 0.15, 0.18)

local AliasButtonWidget = class(Turbine.UI.Control)
_G.AliasButtonWidget = AliasButtonWidget

function AliasButtonWidget:Constructor(command, icon_background, widget_w, bar_h)
    Turbine.UI.Control.Constructor(self)

    self.command = tostring(command or "")
    self.icon_background = icon_background
    self._hover = false
    self._pressed = false

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)
    self.border_top:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_top:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_top:SetBackColor(S.SHORTCUT_BORDER_COLOR)
    self.border_top:SetZOrder(3)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)
    self.border_bottom:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColor(S.SHORTCUT_BORDER_COLOR)
    self.border_bottom:SetZOrder(3)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)
    self.border_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColor(S.SHORTCUT_BORDER_COLOR)
    self.border_left:SetZOrder(3)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)
    self.border_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColor(S.SHORTCUT_BORDER_COLOR)
    self.border_right:SetZOrder(3)

    self.shortcut = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "")
    self.shortcut:SetData(self.command)

    self.slot = Turbine.UI.Lotro.Quickslot()
    self.slot:SetParent(self)
    self.slot:SetAllowDrop(false)
    self.slot:SetUseOnRightClick(false)
    self.slot:SetShortcut(self.shortcut)
    self.slot:SetVisible(true)

    -- This fill sits above the raw quickslot art so the button matches the built-in shortcut buttons.
    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.background:SetBackColor(BUTTON_FILL_COLOR)
    self.background:SetZOrder(1)

    self.icon = Turbine.UI.Control()
    self.icon:SetParent(self)
    self.icon:SetMouseVisible(false)
    self.icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self.icon:SetZOrder(2)
    if self.icon_background ~= nil then
        prepare_background_stretch_mode_1(self.icon, self.icon_background)
    end

    local function _forward(name, args)
        local handler = self[name]
        if type(handler) == "function" then
            handler(self, args)
        end
    end

    self.slot.MouseClick = function(_, args)
        _forward("MouseClick", args)
    end
    self.slot.MouseEnter = function(_, args)
        _forward("MouseEnter", args)
    end
    self.slot.MouseLeave = function(_, args)
        _forward("MouseLeave", args)
    end
    self.slot.MouseDown = function(_, args)
        _forward("MouseDown", args)
    end
    self.slot.MouseMove = function(_, args)
        _forward("MouseMove", args)
    end
    self.slot.MouseUp = function(_, args)
        _forward("MouseUp", args)
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = true
        self:_update_visual_state()
    end

    self.MouseUp = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self._pressed = false
        self:_update_visual_state()
    end

    self:_layout()
    self:set_interaction_enabled(true)
    self:_update_visual_state()
end

function AliasButtonWidget:set_interaction_enabled(enabled)
    if self.slot ~= nil and self.slot.SetMouseVisible ~= nil then
        self.slot:SetMouseVisible(enabled == true)
    end
end

function AliasButtonWidget:update(now)
end

function AliasButtonWidget:destroy()
    if self.border_top ~= nil then self.border_top:SetParent(nil) end
    if self.border_bottom ~= nil then self.border_bottom:SetParent(nil) end
    if self.border_left ~= nil then self.border_left:SetParent(nil) end
    if self.border_right ~= nil then self.border_right:SetParent(nil) end
    if self.slot ~= nil then self.slot:SetParent(nil) end
    if self.background ~= nil then self.background:SetParent(nil) end
    if self.icon ~= nil then self.icon:SetParent(nil) end
    self:SetParent(nil)
end

function AliasButtonWidget:_layout()
    local w, h = self:GetSize()
    local border_thickness = 1
    local inner_w = math.max(0, w - (border_thickness * 2))
    local inner_h = math.max(0, h - (border_thickness * 2))
    local slot_size = math.min(inner_w, inner_h)
    if slot_size < 0 then
        slot_size = 0
    end

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, math.min(border_thickness, h))

    self.border_bottom:SetPosition(0, math.max(0, h - border_thickness))
    self.border_bottom:SetSize(w, math.min(border_thickness, h))

    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(math.min(border_thickness, w), h)

    self.border_right:SetPosition(math.max(0, w - border_thickness), 0)
    self.border_right:SetSize(math.min(border_thickness, w), h)

    self.background:SetPosition(border_thickness, border_thickness)
    self.background:SetSize(inner_w, inner_h)
    self.background:SetVisible(inner_w > 0 and inner_h > 0)

    local slot_x = math.floor((w - slot_size) / 2)
    local slot_y = math.floor((h - slot_size) / 2)

    self.slot:SetPosition(slot_x, slot_y)
    self.slot:SetSize(slot_size, slot_size)

    local icon_h = S.get_icon_size(slot_size)
    local icon_w = S.get_shortcut_icon_w(self.icon_background, icon_h)
    local icon_x = math.floor((w - icon_w) / 2)
    local icon_y = S.get_centered_icon_y(h, icon_h)
    self.icon:SetPosition(icon_x, icon_y)
    self.icon:SetSize(icon_w, icon_h)
    self.icon:SetVisible(self.icon_background ~= nil and icon_h > 0 and icon_w > 0)
end

function AliasButtonWidget:_set_border_color(color)
    self.border_top:SetBackColor(color)
    self.border_bottom:SetBackColor(color)
    self.border_left:SetBackColor(color)
    self.border_right:SetBackColor(color)
end

function AliasButtonWidget:_update_visual_state()
    local border_color = S.SHORTCUT_BORDER_COLOR
    local fill_color = BUTTON_FILL_COLOR

    if self._hover or self._pressed then
        border_color = S.SHORTCUT_BORDER_HOVER_COLOR
        fill_color = BUTTON_FILL_HOVER_COLOR
    end

    self:_set_border_color(border_color)
    if self.background ~= nil then
        self.background:SetBackColor(fill_color)
    end
end
