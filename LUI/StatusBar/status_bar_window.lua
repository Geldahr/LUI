import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Geldahr.LUI.Utils.number_abbrev"
import "Geldahr.LUI.Utils.stretch"
import "Geldahr.LUI.Settings.enums"

local ICON_GAP = 4

local function _format_hhmm(date)
    if date == nil then
        return "--:--"
    end
    local h = date.Hour or 0
    local m = date.Minute or 0
    return string.format("%02d:%02d", h, m)
end

local GOLD_ICON = Turbine.UI.Graphic(0x41007e7b)
local SILVER_ICON = Turbine.UI.Graphic(0x41007e7c)
local COPPER_ICON = Turbine.UI.Graphic(0x41007e7d)
local INVENTORY_SPACE_ICON = Turbine.UI.Graphic(0x41008113) -- or 0x41008114 or 0x4113F1A8 or 0x41008113
local ICON_INSET = 4
local BACKPACK_ICON_W = 24
local BACKPACK_ICON_H = 30

local function _get_centered_icon_y(container_h, icon_h)
    return math.floor((container_h - icon_h) / 2)
end

local function _get_icon_size(bar_h)
    local size = bar_h - ICON_INSET
    if size < 0 then
        return 0
    end
    return size
end

local function _get_widget_icon_w(widget_key, icon_h)
    if widget_key == "inventory_space" then
        -- The backpack asset is 24x30, so keep that aspect ratio when fitting it to the bar height.
        return math.floor(((icon_h * BACKPACK_ICON_W) / BACKPACK_ICON_H) + 0.5)
    end
    return icon_h
end

local function _get_widget_icon(widget_key)
    if widget_key == "inventory_space" then
        return INVENTORY_SPACE_ICON
    end
    return nil
end

local function _widget_factory(widget_key, widget_w, bar_h, font, widget_cfg)
    local icon_enabled = widget_cfg ~= nil and widget_cfg.icon == true
    local icon_path = nil
    if icon_enabled == true then
        icon_path = _get_widget_icon(widget_key)
    end

    if widget_key == "time_local" then
        return TimeLocalWidget(widget_w, bar_h, font, icon_path, widget_cfg.content_alignment)
    elseif widget_key == "inventory_space" then
        return InventorySpaceWidget(widget_w, bar_h, font, icon_path, widget_cfg.color,
            widget_cfg.content_alignment)
    elseif widget_key == "money" then
        return MoneyWidget(widget_w, bar_h, font, icon_enabled, widget_cfg.content_alignment)
    end

    local alignment = Turbine.UI.ContentAlignment.MiddleLeft
    return DummyWidget(widget_key, widget_w, bar_h, font, widget_cfg.content_alignment or alignment, icon_path)
end

local function _sum_widget_width(widgets, gap)
    if widgets == nil then
        return 0
    end
    local w = 0
    for i = 1, #widgets do
        local c = widgets[i]
        if c ~= nil and c.GetWidth ~= nil then
            w = w + c:GetWidth()
        end
    end
    if #widgets > 1 then
        w = w + (gap * (#widgets - 1))
    end
    return w
end

local function _split_money_copper(total_copper)
    local v = total_copper
    if type(v) ~= "number" then
        v = tonumber(v)
    end
    if v == nil then
        return nil
    end

    local gold = math.floor(v / 100000);
    local silver = math.floor(v / 100) - gold * 1000;
    local copper = v - gold * 100000 - silver * 100;
    return gold, silver, copper
end

local function _format_money_copper(total_copper)
    local gold, silver, copper = _split_money_copper(total_copper)
    if gold == nil then
        return "--"
    end
    return string.format("%dg %ds %dc", gold, silver, copper)
end

local function _format_gold_compact(gold)
    return lui_abbrev_gold(gold)
end

StatusBarWidgetBase = class(Turbine.UI.Control)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function StatusBarWidgetBase:Constructor(widget_key, widget_w, bar_h, font, content_alignment, icon_path)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = widget_key
    self._last_text = nil

    self:SetMouseVisible(false)
    -- self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    -- self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    -- self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
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
    -- self.label:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self.label:SetText("")

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
    local icon_h = _get_icon_size(h)
    local icon_w = _get_widget_icon_w(widget_key, icon_h)
    local show_icon = icon_h > 0 and icon_w > 0 and icon_path ~= nil

    if show_icon then
        local icon_y = _get_centered_icon_y(h, icon_h)
        prepare_background_stretch_mode_1(self.icon, icon_path)
        self.icon:SetPosition(0, icon_y)
        self.icon:SetSize(icon_w, icon_h)
        self.icon:SetVisible(true)
        self.label:SetPosition(icon_w + ICON_GAP, 0)
        self.label:SetSize(math.max(0, w - icon_w - ICON_GAP), h)
    else
        self.icon:SetVisible(false)
        self.label:SetPosition(0, 0)
        self.label:SetSize(w, h)
    end
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function StatusBarWidgetBase:set_text(text)
    local t = tostring(text or "")
    if t == self._last_text then
        return
    end
    self._last_text = t
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

TimeLocalWidget = class(StatusBarWidgetBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TimeLocalWidget:Constructor(widget_w, bar_h, font, icon_path, content_alignment)
    StatusBarWidgetBase.Constructor(self, "time_local", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleCenter, icon_path)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TimeLocalWidget:update(now)
    local date = Turbine.Engine.GetDate()
    self:set_text(_format_hhmm(date))
end

InventorySpaceWidget = class(StatusBarWidgetBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function InventorySpaceWidget:Constructor(widget_w, bar_h, font, icon_path, warn_color, content_alignment)
    StatusBarWidgetBase.Constructor(self, "inventory_space", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleRight, icon_path)
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = self.player ~= nil and self.player.GetBackpack ~= nil and self.player:GetBackpack() or nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._base_color = font ~= nil and font.color or nil
    self._last_color_key = nil
    self.warn_color = warn_color
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function InventorySpaceWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    local used, total = self:_scan()
    if used == nil or total == nil then
        self:set_text("--/--")
        if self._base_color ~= nil then
            self.label:SetForeColor(self._base_color)
            self._last_color_key = "base"
        end
        return
    end

    self:set_text(string.format("%d/%d", used, total))

    if total <= 0 then
        if self._base_color ~= nil and self._last_color_key ~= "base" then
            self.label:SetForeColor(self._base_color)
            self._last_color_key = "base"
        end
        return
    end

    local free_ratio = (total - used) / total
    local wc = self.warn_color
    local key = "base"
    local c = self._base_color
    if free_ratio <= 0.10 then
        key = "red"
        c = wc.red
    elseif free_ratio <= 0.20 then
        key = "orange"
        c = wc.orange
    elseif free_ratio <= 0.30 then
        key = "yellow"
        c = wc.yellow
    end

    if key ~= self._last_color_key and c ~= nil then
        self.label:SetForeColor(c)
        self._last_color_key = key
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function InventorySpaceWidget:_scan()
    local bp = self.backpack
    if bp == nil or bp.GetSize == nil or bp.GetItem == nil then
        return nil, nil
    end

    local size = bp:GetSize() or 0
    if type(size) ~= "number" then
        size = tonumber(size) or 0
    end
    if size <= 0 then
        return 0, 0
    end

    local used = 0
    for i = 1, size do
        if bp:GetItem(i) ~= nil then
            used = used + 1
        end
    end

    return used, size
end

MoneyWidget = class(Turbine.UI.Control)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

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

    self.text = Turbine.UI.Label()
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
    prepare_background_stretch_mode_1(self.g_icon, GOLD_ICON)
    self.g_icon:SetVisible(false)

    self.s_icon = Turbine.UI.Control()
    self.s_icon:SetParent(self)
    self.s_icon:SetMouseVisible(false)
    self.s_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.s_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.s_icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    prepare_background_stretch_mode_1(self.s_icon, SILVER_ICON)
    self.s_icon:SetVisible(false)

    self.c_icon = Turbine.UI.Control()
    self.c_icon:SetParent(self)
    self.c_icon:SetMouseVisible(false)
    self.c_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.c_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.c_icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    prepare_background_stretch_mode_1(self.c_icon, COPPER_ICON)
    self.c_icon:SetVisible(false)

    local function make_label()
        local l = Turbine.UI.Label()
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

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function MoneyWidget:update(now)
    local total = self:_get_total_money()
    if total == self._last_total then
        return
    end
    self._last_total = total

    local gold, silver, copper = _split_money_copper(total)
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
        self.g_label:SetText(_format_gold_compact(gold))
        self.s_label:SetText(tostring(silver))
        self.c_label:SetText(tostring(copper))
    else
        if self.text ~= nil then
            self.text:SetText(_format_money_copper(total))
        end
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

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function MoneyWidget:_layout()
    local w, h = self:GetSize()
    self.text:SetPosition(0, 0)
    self.text:SetSize(w, h)

    local size = _get_icon_size(h)

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
    local c_w = remaining - g_w - s_w

    local y = _get_centered_icon_y(h, size)
    local x = 0

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

DummyWidget = class(StatusBarWidgetBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function DummyWidget:Constructor(widget_key, widget_w, bar_h, font, content_alignment, icon_path)
    StatusBarWidgetBase.Constructor(self, widget_key, widget_w, bar_h, font, content_alignment, icon_path)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function DummyWidget:update(now)
    self:set_text("--")
end

StatusBarWindow = class(Turbine.UI.Window)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function StatusBarWindow:Constructor()
    Turbine.UI.Window.Constructor(self)

    self.last_update_at = 0
    self.update_every = 1.0
    self._last_display_w = nil
    self._display_check_due_at = 0

    self._widgets = {}
    self._update_widgets = {}
    self._zone_widgets_left = {}
    self._zone_widgets_center = {}
    self._zone_widgets_right = {}

    self:SetMouseVisible(false)
    -- self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetVisible(true)
    self:SetWantsUpdates(true)
    self:SetZOrder(-1)

    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function StatusBarWindow:apply_settings()
    local sb = _G.settings.status_bar

    local bg = sb.bg
    local bg_opacity = bg.opacity
    local bg_color = bg.color
    self:SetBackColor(Turbine.UI.Color(bg_opacity, bg_color.R, bg_color.G, bg_color.B))

    self._last_display_w = nil
    self._display_check_due_at = 0
    self:_sync_display_width(sb)

    self:_rebuild_widgets(sb)

    self.last_update_at = 0
end

function StatusBarWindow:Update()
    local now = Turbine.Engine.GetGameTime()

    if now >= (self._display_check_due_at or 0) then
        self._display_check_due_at = now + 0.5
        local sb = _G.settings.status_bar
        self:_sync_display_width(sb)
    end

    if now - self.last_update_at < self.update_every then
        return
    end
    self.last_update_at = now

    for i = 1, #self._update_widgets do
        local w = self._update_widgets[i]
        if w ~= nil then
            w:update(now)
        end
    end
end

function StatusBarWindow:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:_clear_widgets()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function StatusBarWindow:_clear_widgets()
    for i = 1, #self._widgets do
        local w = self._widgets[i]
        if w ~= nil and w.destroy ~= nil then
            w:destroy()
        end
    end
    self._widgets = {}
    self._update_widgets = {}
end

function StatusBarWindow:_layout_widgets(sb)
    local bar_w = self:GetWidth()
    local pad = sb.padding
    local gap = sb.gap

    local left_widgets = self._zone_widgets_left
    local center_widgets = self._zone_widgets_center
    local right_widgets = self._zone_widgets_right

    local left_w = _sum_widget_width(left_widgets, gap)
    local center_w = _sum_widget_width(center_widgets, gap)
    local right_w = _sum_widget_width(right_widgets, gap)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local function place(list, x0)
        local x = x0
        for i = 1, #list do
            local w = list[i]
            w:SetPosition(x, 0)
            x = x + w:GetWidth() + gap
        end
    end

    place(left_widgets, x_left)
    place(center_widgets, x_center)
    place(right_widgets, x_right)
end

function StatusBarWindow:_rebuild_widgets(sb)
    self:_clear_widgets()

    self._zone_widgets_left = {}
    self._zone_widgets_center = {}
    self._zone_widgets_right = {}

    local zones = sb.zones
    local widgets_cfg = sb.widgets

    local function build_zone(zone_key, dst)
        local list = zones[zone_key]
        for i = 1, #list do
            local widget_key = list[i]
            local cfg = widgets_cfg[widget_key]
            if cfg ~= nil and cfg.enabled == true then
                local inst = _widget_factory(widget_key, cfg.width, sb.height, sb.font, cfg)
                inst:SetParent(self)
                inst:SetZOrder(1)
                inst:SetVisible(false)
                table.insert(self._widgets, inst)
                table.insert(self._update_widgets, inst)
                table.insert(dst, inst)
            end
        end
    end

    build_zone("left", self._zone_widgets_left)
    build_zone("center", self._zone_widgets_center)
    build_zone("right", self._zone_widgets_right)

    self:_layout_widgets(sb)

    for i = 1, #self._widgets do
        local w = self._widgets[i]
        if w ~= nil then
            w:SetVisible(true)
        end
    end
end

function StatusBarWindow:_sync_display_width(sb)
    local display_w, _ = Turbine.UI.Display.GetSize()
    if display_w == self._last_display_w then
        return
    end

    self._last_display_w = display_w
    self:SetPosition(0, 0)
    self:SetSize(display_w, sb.height)
    self:_layout_widgets(sb)
end
