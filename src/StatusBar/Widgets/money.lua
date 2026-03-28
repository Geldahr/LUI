import "LUI.src.UI.Widgets"

local S = _G.STATUS_BAR_COMMON

local MoneyWidget = class(Turbine.UI.Control)
_G.MoneyWidget = MoneyWidget

function MoneyWidget:Constructor(widget_w, bar_h, font, icon_enabled, content_alignment)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "money"
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._last_total = nil
    self._use_icons = icon_enabled == true
    self._content_alignment = content_alignment or Turbine.UI.ContentAlignment.MiddleRight

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetSize(widget_w, bar_h)

    self.text = UI.Widgets.LuiLabel()
    self.text:SetParent(self)
    self.text:SetMouseVisible(false)
    self.text:SetTextAlignment(self._content_alignment)
    self.text:SetVisible(false)
    if font ~= nil then
        if font.lotro ~= nil then
            self.text:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.text:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.text:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.text:SetOutlineColor(font.outline_color)
        end
    end

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

    local function make_label()
        local l = UI.Widgets.LuiLabel()
        l:SetParent(self)
        l:SetMouseVisible(false)
        l:SetTextAlignment(self._content_alignment)
        l:SetVisible(false)
        if font ~= nil then
            if font.lotro ~= nil then
                l:SetFont(font.lotro)
            end
            if font.style ~= nil then
                l:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
            end
            if font.color ~= nil then
                l:SetForeColor(font.color)
            end
            if font.outline_color ~= nil then
                l:SetOutlineColor(font.outline_color)
            end
        end
        return l
    end

    self.g_label = make_label()
    self.s_label = make_label()
    self.c_label = make_label()

    self:_layout()
    self:_set_icon_mode(self._use_icons)
end

function MoneyWidget:update(now)
    local total = self:_get_total_money()
    if total == self._last_total then
        return
    end
    self._last_total = total

    local gold, silver, copper = S.split_money_copper(total)
    if gold == nil then
        if self._use_icons == true then
            self.g_label:SetText("--")
            self.s_label:SetText("--")
            self.c_label:SetText("--")
        else
            self.text:SetText("--")
        end
        return
    end

    if self._use_icons == true then
        self.g_label:SetText(S.format_gold_compact(gold))
        self.s_label:SetText(tostring(silver))
        self.c_label:SetText(tostring(copper))
    elseif self.text ~= nil then
        self.text:SetText(S.format_money_copper(total))
    end
end

function MoneyWidget:destroy()
    if self.text ~= nil then self.text:SetParent(nil) end
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
    self.text:SetPosition(0, 0)
    self.text:SetSize(w, h)

    local size = S.get_icon_size(h)
    local gap = 4
    local fixed = (size * 3) + (gap * 5)
    local remaining = w - fixed
    if remaining < 30 or size <= 0 then
        self._use_icons = false
        self:_set_icon_mode(false)
        return
    end

    local field_w = math.floor(remaining / 3)
    if field_w < 10 then
        self._use_icons = false
        self:_set_icon_mode(false)
        return
    end

    local g_w = field_w
    local s_w = field_w
    local x = 0
    local y = S.get_centered_icon_y(h, size)

    self.g_icon:SetPosition(x, y)
    self.g_icon:SetSize(size, size)
    x = x + size + gap
    self.g_label:SetPosition(x, 0)
    self.g_label:SetSize(g_w, h)
    x = x + g_w + gap

    self.s_icon:SetPosition(x, y)
    self.s_icon:SetSize(size, size)
    x = x + size + gap
    self.s_label:SetPosition(x, 0)
    self.s_label:SetSize(s_w, h)
    x = x + s_w + gap

    self.c_icon:SetPosition(x, y)
    self.c_icon:SetSize(size, size)
    x = x + size + gap
    self.c_label:SetPosition(x, 0)
    self.c_label:SetSize(math.max(0, w - x), h)
end

function MoneyWidget:_set_icon_mode(enabled)
    local use = enabled == true
    if self.text ~= nil then
        self.text:SetVisible(use ~= true)
    end
    self.g_icon:SetVisible(use)
    self.s_icon:SetVisible(use)
    self.c_icon:SetVisible(use)
    self.g_label:SetVisible(use)
    self.s_label:SetVisible(use)
    self.c_label:SetVisible(use)
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
