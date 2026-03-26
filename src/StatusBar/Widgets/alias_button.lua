import "Turbine.UI"
import "Turbine.UI.Lotro"

local S = _G.STATUS_BAR_COMMON

local AliasButtonWidget = class(Turbine.UI.Control)
_G.AliasButtonWidget = AliasButtonWidget

function AliasButtonWidget:Constructor(command, icon_background, widget_w, bar_h)
    Turbine.UI.Control.Constructor(self)

    self.command = tostring(command or "")
    self.icon_background = icon_background

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(true)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.shortcut = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "")
    self.shortcut:SetData(self.command)

    self.slot = Turbine.UI.Lotro.Quickslot()
    self.slot:SetParent(self)
    self.slot:SetAllowDrop(false)
    self.slot:SetUseOnRightClick(false)
    self.slot:SetShortcut(self.shortcut)
    self.slot:SetVisible(true)

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

    self:_layout()
    self:set_interaction_enabled(true)
end

function AliasButtonWidget:set_interaction_enabled(enabled)
    if self.slot ~= nil and self.slot.SetMouseVisible ~= nil then
        self.slot:SetMouseVisible(enabled == true)
    end
end

function AliasButtonWidget:update(now)
end

function AliasButtonWidget:destroy()
    if self.slot ~= nil then self.slot:SetParent(nil) end
    if self.icon ~= nil then self.icon:SetParent(nil) end
    self:SetParent(nil)
end

function AliasButtonWidget:_layout()
    local w, h = self:GetSize()
    local slot_size = math.min(w, h)
    if slot_size < 0 then
        slot_size = 0
    end

    local slot_x = math.floor((w - slot_size) / 2)
    local slot_y = math.floor((h - slot_size) / 2)

    self.slot:SetPosition(slot_x, slot_y)
    self.slot:SetSize(slot_size, slot_size)

    self.icon:SetPosition(slot_x, slot_y)
    self.icon:SetSize(slot_size, slot_size)
    self.icon:SetVisible(self.icon_background ~= nil and slot_size > 0)
end
