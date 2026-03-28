import "LUI.src.UI.Widgets"

local S = _G.STATUS_BAR_COMMON

local MoneyWidget = class(Turbine.UI.Control)
_G.MoneyWidget = MoneyWidget

function MoneyWidget:Constructor(widget_w, bar_h, font, content_alignment)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "money"
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._last_total = nil
    self._content_alignment = content_alignment or Turbine.UI.ContentAlignment.MiddleRight

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetSize(widget_w, bar_h)

    self.g_icon = Turbine.UI.Control()
    self.g_icon:SetParent(self)
    self.g_icon:SetMouseVisible(false)
    self.g_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.g_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.g_icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    prepare_background_stretch_mode_1(self.g_icon, S.GOLD_ICON)
    self.g_icon:SetVisible(false)

    self.s_icon = Turbine.UI.Control()
    self.s_icon:SetParent(self)
    self.s_icon:SetMouseVisible(false)
    self.s_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.s_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.s_icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    prepare_background_stretch_mode_1(self.s_icon, S.SILVER_ICON)
    self.s_icon:SetVisible(false)

    self.c_icon = Turbine.UI.Control()
    self.c_icon:SetParent(self)
    self.c_icon:SetMouseVisible(false)
    self.c_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.c_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.c_icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    prepare_background_stretch_mode_1(self.c_icon, S.COPPER_ICON)
    self.c_icon:SetVisible(false)

    self.g_label = UI.Widgets.LuiLabel()
    self.g_label:SetParent(self)
    self.g_label:SetMouseVisible(false)
    self.g_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.g_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.g_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.g_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.g_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.g_label:SetOutlineColor(font.outline_color)
        end
    end

    self.s_label = UI.Widgets.LuiLabel()
    self.s_label:SetParent(self)
    self.s_label:SetMouseVisible(false)
    self.s_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.s_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.s_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.s_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.s_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.s_label:SetOutlineColor(font.outline_color)
        end
    end

    self.c_label = UI.Widgets.LuiLabel()
    self.c_label:SetParent(self)
    self.c_label:SetMouseVisible(false)
    self.c_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.c_label:SetVisible(true)
    if font ~= nil then
        if font.lotro ~= nil then
            self.c_label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.c_label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.c_label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.c_label:SetOutlineColor(font.outline_color)
        end
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
end

function MoneyWidget:update(now)
    local total = self:_get_total_money()
    if total == self._last_total then
        return
    end
    self._last_total = total

    local gold, silver, copper = S.split_money_copper(total)
    if gold == nil then
        self.g_label:SetText("--")
        self.s_label:SetText("--")
        self.c_label:SetText("--")
        self:_layout()
        return
    end

    self.g_label:SetText(S.format_gold_compact(gold))
    self.s_label:SetText(tostring(silver))
    self.c_label:SetText(tostring(copper))
    self:_layout()
end

function MoneyWidget:destroy()
    if self.g_icon ~= nil then self.g_icon:SetParent(nil) end
    if self.s_icon ~= nil then self.s_icon:SetParent(nil) end
    if self.c_icon ~= nil then self.c_icon:SetParent(nil) end
    if self.g_label ~= nil then self.g_label:SetParent(nil) end
    if self.s_label ~= nil then self.s_label:SetParent(nil) end
    if self.c_label ~= nil then self.c_label:SetParent(nil) end
    self:SetParent(nil)
end

function MoneyWidget:_layout()
    local w, h = self:GetSize()
    local size = S.get_icon_size(h)
    if size <= 0 then
        self.g_icon:SetVisible(false)
        self.s_icon:SetVisible(false)
        self.c_icon:SetVisible(false)
        self.g_label:SetVisible(false)
        self.s_label:SetVisible(false)
        self.c_label:SetVisible(false)
        return
    end

    local gap = 4
    local fixed = (size * 3) + (gap * 5)
    local remaining = w - fixed
    if remaining < 0 then
        remaining = 0
    end
    local field_w = math.floor(remaining / 3)
    local extra = remaining - (field_w * 3)
    local g_w = field_w
    local s_w = field_w
    if extra > 0 then
        g_w = g_w + 1
        extra = extra - 1
    end
    if extra > 0 then
        s_w = s_w + 1
        extra = extra - 1
    end
    local c_w = field_w + extra
    local x = 0
    local y = S.get_centered_icon_y(h, size)

    self.g_icon:SetPosition(x, y)
    self.g_icon:SetSize(size, size)
    self.g_icon:SetVisible(true)
    x = x + size + gap

    self.g_label:SetPosition(x, 0)
    self.g_label:SetSize(g_w, h)
    self.g_label:SetVisible(g_w > 0)
    x = x + g_w + gap

    self.s_icon:SetPosition(x, y)
    self.s_icon:SetSize(size, size)
    self.s_icon:SetVisible(true)
    x = x + size + gap

    self.s_label:SetPosition(x, 0)
    self.s_label:SetSize(s_w, h)
    self.s_label:SetVisible(s_w > 0)
    x = x + s_w + gap

    self.c_icon:SetPosition(x, y)
    self.c_icon:SetSize(size, size)
    self.c_icon:SetVisible(true)
    x = x + size + gap

    self.c_label:SetPosition(x, 0)
    self.c_label:SetSize(c_w, h)
    self.c_label:SetVisible(c_w > 0)
end

function MoneyWidget:_get_total_money()
    local p = self.player
    if p == nil or p.GetAttributes == nil then
        return nil
    end
    local a = p:GetAttributes()
    if a == nil or a.GetMoney == nil then
        return nil
    end
    return a:GetMoney()
end
