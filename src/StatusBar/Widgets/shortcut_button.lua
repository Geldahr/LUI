local S = _G.STATUS_BAR_COMMON

local ShortcutButtonWidget = class(Turbine.UI.Control)
_G.ShortcutButtonWidget = ShortcutButtonWidget

function ShortcutButtonWidget:Constructor(shortcut_key, display_mode, widget_w, bar_h, font)
    Turbine.UI.Control.Constructor(self)

    self.shortcut_key = shortcut_key
    self.display_mode = display_mode
    self.font = font
    self.icon_background = S.get_shortcut_icon(shortcut_key)

    self._hover = false
    self._pressed = false
    self._available = nil
    self._active = nil

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

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)
    self.border_bottom:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_bottom:SetBackColor(S.SHORTCUT_BORDER_COLOR)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)
    self.border_left:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_left:SetBackColor(S.SHORTCUT_BORDER_COLOR)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)
    self.border_right:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.border_right:SetBackColor(S.SHORTCUT_BORDER_COLOR)

    self.icon = Turbine.UI.Control()
    self.icon:SetParent(self)
    self.icon:SetMouseVisible(false)
    self.icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    if self.icon_background ~= nil then
        prepare_background_stretch_mode_1(self.icon, self.icon_background)
    end

    self.label = Turbine.UI.Label()
    self.label:SetParent(self)
    self.label:SetMouseVisible(false)
    self.label:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.label:SetText(S.get_shortcut_label(shortcut_key))

    if font ~= nil then
        if font.lotro ~= nil then
            self.label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.outline_color ~= nil then
            self.label:SetOutlineColor(font.outline_color)
        end
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
        if self._available ~= true then
            return
        end
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

    self.MouseClick = function(_, args)
        if self._available ~= true then
            return
        end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        S.activate_shortcut(self.shortcut_key)
        self:_refresh_state()
    end

    self:_layout()
    self:_refresh_state()
end

function ShortcutButtonWidget:update(now)
    self:_refresh_state()
end

function ShortcutButtonWidget:destroy()
    if self.border_top ~= nil then self.border_top:SetParent(nil) end
    if self.border_bottom ~= nil then self.border_bottom:SetParent(nil) end
    if self.border_left ~= nil then self.border_left:SetParent(nil) end
    if self.border_right ~= nil then self.border_right:SetParent(nil) end
    if self.icon ~= nil then self.icon:SetParent(nil) end
    if self.label ~= nil then self.label:SetParent(nil) end
    self:SetParent(nil)
end

function ShortcutButtonWidget:_layout()
    local w, h = self:GetSize()
    local border_thickness = 1

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, math.min(border_thickness, h))

    self.border_bottom:SetPosition(0, math.max(0, h - border_thickness))
    self.border_bottom:SetSize(w, math.min(border_thickness, h))

    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(math.min(border_thickness, w), h)

    self.border_right:SetPosition(math.max(0, w - border_thickness), 0)
    self.border_right:SetSize(math.min(border_thickness, w), h)

    self.label:SetPosition(0, 0)
    self.label:SetSize(w, h)

    local icon_h = S.get_icon_size(h)
    local icon_w = S.get_shortcut_icon_w(self.icon_background, icon_h)
    local icon_x = math.floor((w - icon_w) / 2)
    local icon_y = S.get_centered_icon_y(h, icon_h)
    self.icon:SetPosition(icon_x, icon_y)
    self.icon:SetSize(icon_w, icon_h)
    self.icon:SetVisible(self.display_mode == "icon" and self.icon_background ~= nil and icon_h > 0 and icon_w > 0)
    self.label:SetVisible(self.display_mode ~= "icon")
end

function ShortcutButtonWidget:_refresh_state()
    local available, active = S.get_shortcut_state(self.shortcut_key)
    if available == self._available and active == self._active then
        return
    end

    self._available = available == true
    self._active = active == true
    self:_update_visual_state()
end

function ShortcutButtonWidget:_set_border_color(color)
    self.border_top:SetBackColor(color)
    self.border_bottom:SetBackColor(color)
    self.border_left:SetBackColor(color)
    self.border_right:SetBackColor(color)
end

function ShortcutButtonWidget:_update_visual_state()
    local label_color = self.font ~= nil and self.font.color or nil
    local border_color = S.SHORTCUT_BORDER_COLOR

    if self._available ~= true then
        label_color = S.with_alpha(label_color, 0.45)
    elseif self._hover or self._pressed then
        border_color = S.SHORTCUT_BORDER_HOVER_COLOR
    end

    self:_set_border_color(border_color)

    if label_color ~= nil then
        self.label:SetForeColor(label_color)
    end
end
