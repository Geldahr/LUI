local S = _G.STATUS_BAR_COMMON

local StatusBarWidgetBase = class(Turbine.UI.Control)
_G.StatusBarWidgetBase = StatusBarWidgetBase

if StatusBar ~= nil then
    StatusBar.WidgetBase = StatusBarWidgetBase
elseif LUI ~= nil and LUI.src ~= nil and LUI.src.StatusBar ~= nil then
    LUI.src.StatusBar.WidgetBase = StatusBarWidgetBase
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function StatusBarWidgetBase:Constructor(widget_key, widget_w, bar_h, font, content_alignment, icon_path)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = widget_key
    self._last_text = nil
    self._last_markup_enabled = false

    self:SetMouseVisible(false)
    self:SetSize(widget_w, bar_h)

    self.icon = Turbine.UI.Control()
    self.icon:SetParent(self)
    self.icon:SetMouseVisible(false)
    self.icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self.icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon:SetVisible(false)

    self.label = Turbine.UI.Label()
    self.label:SetParent(self)
    self.label:SetMouseVisible(false)
    self.label:SetText("")
    if self.label.SetMarkupEnabled ~= nil then
        self.label:SetMarkupEnabled(false)
    end

    if font ~= nil then
        if font.lotro ~= nil then
            self.label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            self.label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            self.label:SetOutlineColor(font.outline_color)
        end
    end

    if content_alignment ~= nil then
        self.label:SetTextAlignment(content_alignment)
    else
        self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    end

    local w, h = self:GetSize()
    local icon_h = S.get_icon_size(h)
    local icon_w = S.get_widget_icon_w(widget_key, icon_h)
    local show_icon = icon_h > 0 and icon_w > 0 and icon_path ~= nil

    if show_icon then
        local icon_y = S.get_centered_icon_y(h, icon_h)
        prepare_background_stretch_mode_1(self.icon, icon_path)
        self.icon:SetPosition(0, icon_y)
        self.icon:SetSize(icon_w, icon_h)
        self.icon:SetVisible(true)
        self.label:SetPosition(icon_w + S.ICON_GAP, 0)
        self.label:SetSize(math.max(0, w - icon_w - S.ICON_GAP), h)
    else
        self.icon:SetVisible(false)
        self.label:SetPosition(0, 0)
        self.label:SetSize(w, h)
    end
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function StatusBarWidgetBase:set_text(text, markup_enabled)
    local t = tostring(text or "")
    local use_markup = markup_enabled == true
    if t == self._last_text and use_markup == self._last_markup_enabled then
        return
    end
    if self.label ~= nil and self.label.SetMarkupEnabled ~= nil and use_markup ~= self._last_markup_enabled then
        self.label:SetMarkupEnabled(use_markup)
    end
    self._last_text = t
    self._last_markup_enabled = use_markup
    self.label:SetText(t)
end

function StatusBarWidgetBase:update(now)
end

function StatusBarWidgetBase:destroy()
    if self.icon ~= nil then
        self.icon:SetVisible(false)
        self.icon:SetParent(nil)
    end
    if self.label ~= nil then
        self.label:SetVisible(false)
        self.label:SetParent(nil)
    end
    self:SetVisible(false)
    self:SetParent(nil)
end
