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
        self:_layout()
        return
    end

    self.g_label:SetText(S.format_gold_compact(gold))
    self:_layout()
end

function MoneyWidget:destroy()
    if self.g_icon ~= nil then self.g_icon:SetParent(nil) end
    if self.s_icon ~= nil then self.s_icon:SetParent(nil) end
    if self.c_icon ~= nil then self.c_icon:SetParent(nil) end
    if self.g_label ~= nil then self.g_label:SetParent(nil) end
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
        return
    end

    local gap = 4
    local gold_text_w = math.ceil(self.g_label:GetTextLength() or 0)
    if gold_text_w < 0 then
        gold_text_w = 0
    end
    local gold_label_gap = gold_text_w > 0 and gap or 0
    local gold_group_w = size + gold_label_gap + gold_text_w
    local group_w = gold_group_w + gap + size + gap + size
    local x = 0
    if self._content_alignment == Turbine.UI.ContentAlignment.MiddleCenter then
        x = math.floor((w - group_w) / 2)
    elseif self._content_alignment == Turbine.UI.ContentAlignment.MiddleRight then
        x = w - group_w
    end
    if x < 0 then
        x = 0
    end
    local y = S.get_centered_icon_y(h, size)

    self.g_icon:SetPosition(x, y)
    self.g_icon:SetSize(size, size)
    self.g_icon:SetVisible(true)

    if gold_text_w > 0 then
        self.g_label:SetPosition(x + size + gold_label_gap, 0)
        self.g_label:SetSize(gold_text_w, h)
        self.g_label:SetVisible(true)
    else
        self.g_label:SetVisible(false)
    end

    x = x + gold_group_w + gap

    self.s_icon:SetPosition(x, y)
    self.s_icon:SetSize(size, size)
    self.s_icon:SetVisible(true)
    x = x + size + gap

    self.c_icon:SetPosition(x, y)
    self.c_icon:SetSize(size, size)
    self.c_icon:SetVisible(true)
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
