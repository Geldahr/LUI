import "LUI.src.StatusBar.common"
import "LUI.src.StatusBar.widget_base"
import "LUI.src.StatusBar.Widgets"

local S = _G.STATUS_BAR_COMMON

local SHORTCUT_WIDGETS = {
    config_icon = { shortcut_key = "config", display_mode = "icon" },
    config_text = { shortcut_key = "config", display_mode = "text" },
    assets_icon = { shortcut_key = "assets", display_mode = "icon" },
    assets_text = { shortcut_key = "assets", display_mode = "text" },
    bestiary_icon = { shortcut_key = "bestiary", display_mode = "icon" },
    bestiary_text = { shortcut_key = "bestiary", display_mode = "text" },
}

local function _widgets_pkg()
    if StatusBar ~= nil and StatusBar.Widgets ~= nil then
        return StatusBar.Widgets
    end
    if LUI ~= nil and LUI.src ~= nil and LUI.src.StatusBar ~= nil then
        return LUI.src.StatusBar.Widgets
    end
    return nil
end

local function _widget_ctor(name)
    local widgets = _widgets_pkg()
    if widgets ~= nil and widgets[name] ~= nil then
        return widgets[name]
    end
    return _G[name]
end

local function _widget_factory(widget_key, widget_w, bar_h, font, widget_cfg)
    local shortcut_spec = SHORTCUT_WIDGETS[widget_key]
    if shortcut_spec ~= nil then
        local ctor = _widget_ctor("ShortcutButtonWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: ShortcutButtonWidget")
        end
        return ctor(
            shortcut_spec.shortcut_key,
            shortcut_spec.display_mode,
            widget_w,
            S.clamp_shortcut_height(widget_cfg ~= nil and widget_cfg.height or nil, bar_h),
            font
        )
    end

    local icon_enabled = widget_cfg ~= nil and widget_cfg.icon == true
    local icon_path = nil
    if icon_enabled == true then
        icon_path = S.get_widget_icon(widget_key)
    end

    if widget_key == "time_local" then
        local ctor = _widget_ctor("TimeLocalWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: TimeLocalWidget")
        end
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.content_alignment)
    elseif widget_key == "inventory_space" then
        local ctor = _widget_ctor("InventorySpaceWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: InventorySpaceWidget")
        end
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color,
            widget_cfg.content_alignment)
    elseif widget_key == "equipment_wear" then
        local ctor = _widget_ctor("EquipmentWearWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: EquipmentWearWidget")
        end
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color, widget_cfg.coloring,
            widget_cfg.content_alignment)
    elseif widget_key == "money" then
        local ctor = _widget_ctor("MoneyWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: MoneyWidget")
        end
        return ctor(widget_w, bar_h, font, icon_enabled, widget_cfg.content_alignment)
    end

    local alignment = Turbine.UI.ContentAlignment.MiddleLeft
    local ctor = _widget_ctor("DummyWidget")
    if ctor == nil then
        error("Missing StatusBar widget constructor: DummyWidget")
    end
    return ctor(widget_key, widget_w, bar_h, font, widget_cfg.content_alignment or alignment, icon_path)
end

StatusBarWindow = class(Turbine.UI.Window)

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
    self:SetVisible(true)
    self:SetWantsUpdates(true)
    self:SetZOrder(-1)

    self:apply_settings()
end

function StatusBarWindow:apply_settings()
    local sb = _G.settings.status_bar

    local bg = sb.bg
    self:SetBackColor(Turbine.UI.Color(bg.opacity, bg.color.R, bg.color.G, bg.color.B))

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
        self:_sync_display_width(_G.settings.status_bar)
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
    local bar_h = self:GetHeight()
    local pad = sb.padding
    local gap = sb.gap

    local left_widgets = self._zone_widgets_left
    local center_widgets = self._zone_widgets_center
    local right_widgets = self._zone_widgets_right

    local left_w = S.sum_widget_width(left_widgets, gap)
    local center_w = S.sum_widget_width(center_widgets, gap)
    local right_w = S.sum_widget_width(right_widgets, gap)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local function place(list, x0)
        local x = x0
        for i = 1, #list do
            local w = list[i]
            local y = math.floor((bar_h - w:GetHeight()) / 2)
            if y < 0 then y = 0 end
            w:SetPosition(x, y)
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
    local has_interactive_widgets = false

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
                if SHORTCUT_WIDGETS[widget_key] ~= nil then
                    has_interactive_widgets = true
                end
                table.insert(self._widgets, inst)
                table.insert(self._update_widgets, inst)
                table.insert(dst, inst)
            end
        end
    end

    build_zone("left", self._zone_widgets_left)
    build_zone("center", self._zone_widgets_center)
    build_zone("right", self._zone_widgets_right)
    self:SetMouseVisible(has_interactive_widgets)

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
