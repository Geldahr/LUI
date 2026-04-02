import "LUI.src.UI.Widgets"

local S = _G.STATUS_BAR_COMMON
local BUTTON_FILL_COLOR = Turbine.UI.Color(1.00, 0.08, 0.10, 0.12)
local BUTTON_FILL_HOVER_COLOR = Turbine.UI.Color(1.00, 0.12, 0.15, 0.18)
local BUTTON_MARGIN = 2
local BUTTON_BORDER = 1

local ShortcutButtonWidget = class(Turbine.UI.Control)
_G.ShortcutButtonWidget = ShortcutButtonWidget

function ShortcutButtonWidget:Constructor(shortcut_key, display_mode, widget_w, bar_h, font)
    Turbine.UI.Control.Constructor(self)

    self.shortcut_key = shortcut_key
    self.display_mode = display_mode
    self.font = font
    self.icon_background = S.get_shortcut_icon(shortcut_key)
    self._available = nil

    self:SetSize(widget_w, bar_h)
    self:SetMouseVisible(false)

    self.button = LuiButton()
    self.button:SetParent(self)
    self.button:set_border_thickness(BUTTON_BORDER)
    self.button:set_border_color(S.SHORTCUT_BORDER_COLOR)
    self.button:set_hover_border_color(S.SHORTCUT_BORDER_HOVER_COLOR)
    self.button:set_active_border_color(S.SHORTCUT_BORDER_HOVER_COLOR)
    self.button:set_disabled_border_color(S.SHORTCUT_BORDER_COLOR)
    self.button:set_back_color(BUTTON_FILL_COLOR)
    self.button:set_hover_back_color(BUTTON_FILL_HOVER_COLOR)
    self.button:set_pressed_back_color(BUTTON_FILL_HOVER_COLOR)
    self.button:set_active_back_color(BUTTON_FILL_COLOR)
    self.button:set_disabled_back_color(BUTTON_FILL_COLOR)
    self.button:set_padding(0)
    self.button:set_text_alignment(Turbine.UI.ContentAlignment.MiddleCenter)

    if font ~= nil then
        if font.lotro ~= nil then
            self.button._label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            self.button._label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.outline_color ~= nil then
            self.button._label:SetOutlineColor(font.outline_color)
        end
        if font.color ~= nil then
            self.button:set_text_color(font.color)
            self.button:set_hover_text_color(font.color)
            self.button:set_pressed_text_color(font.color)
            self.button:set_active_text_color(font.color)
        end
    end
    self.button:set_disabled_text_color(S.with_alpha(font ~= nil and font.color or nil, 0.45))

    if self.display_mode == "icon" and self.icon_background ~= nil then
        self.button:set_text("")
    else
        self.button:set_icon(nil, nil, nil, nil, 0)
        self.button:set_text(S.get_shortcut_label(shortcut_key))
    end

    self.button.Click = function()
        S.activate_shortcut(self.shortcut_key)
        self:_refresh_state()
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
    self:_refresh_state()
end

function ShortcutButtonWidget:update(now)
    self:_refresh_state()
end

function ShortcutButtonWidget:destroy()
    self:SetVisible(false)
    if self.button ~= nil then
        self.button:SetVisible(false)
        self.button:SetParent(nil)
    end
    self:SetParent(nil)
end

function ShortcutButtonWidget:_layout()
    local w, h = self:GetSize()
    local margin = BUTTON_MARGIN
    if margin * 2 > w then
        margin = math.floor(w / 2)
    end
    if margin * 2 > h then
        margin = math.floor(h / 2)
    end

    local button_w = math.max(0, w - (margin * 2))
    local button_h = math.max(0, h - (margin * 2))
    self.button:SetPosition(margin, margin)
    self.button:SetSize(button_w, button_h)

    if self.display_mode == "icon" and self.icon_background ~= nil then
        local inner_h = math.max(0, button_h - (BUTTON_BORDER * 2))
        local icon_h = S.get_icon_size(inner_h)
        local icon_w = Image.get_size_for_height(self.icon_background, icon_h)
        self.button:set_icon(self.icon_background, nil, nil, nil, icon_w)
    end
end

function ShortcutButtonWidget:_refresh_state()
    local available = S.get_shortcut_state(self.shortcut_key)
    local is_available = available == true
    if is_available == self._available then
        return
    end

    self._available = is_available
    self.button:set_enabled(self._available)
end
