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

local function _write_status_bar_message(text)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. tostring(text or ""))
    end
end

local function _resolve_drop_zone_key(bar_w, mouse_x)
    local width = type(bar_w) == "number" and bar_w or 0
    if width <= 0 then
        return "right"
    end

    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        return "right"
    end

    if x < (width / 3) then
        return "left"
    elseif x < ((width * 2) / 3) then
        return "center"
    end
    return "right"
end

local function _sync_status_bar_after_raw_edit()
    if _G.rebuild_settings ~= nil then
        _G.rebuild_settings()
    end
    if apply_status_bar_settings ~= nil then
        apply_status_bar_settings()
    end
    if _G.save_settings ~= nil then
        _G.save_settings()
    end
end

local function _extract_layout_tokens(text)
    local tokens = {}
    local source = tostring(text or "")
    for token in source:gmatch("%%[^%%]+%%") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function _layout_token_is_visible(token)
    local inner = tostring(token or ""):match("^%%([^%%]+)%%$")
    if inner == nil then
        return false
    end

    if S.parse_status_bar_item_name(inner) ~= nil then
        return true
    end

    return S.STATUS_BAR_LAYOUT_TOKENS[string.lower(inner)] ~= nil
end

local function _insert_layout_token_at_visible_index(text, token, insert_index)
    local tokens = _extract_layout_tokens(text)
    if #tokens == 0 then
        return token
    end

    local wanted_index = insert_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        wanted_index = 1
    end

    local visible_before = 0
    for i = 1, #tokens do
        if _layout_token_is_visible(tokens[i]) == true then
            if wanted_index == (visible_before + 1) then
                table.insert(tokens, i, token)
                return table.concat(tokens, " ")
            end
            visible_before = visible_before + 1
        end
    end

    table.insert(tokens, token)
    return table.concat(tokens, " ")
end

local function _zone_widgets_contains_x(widgets, mouse_x)
    if widgets == nil or #widgets == 0 or type(mouse_x) ~= "number" then
        return false
    end

    local first = widgets[1]
    local last = widgets[#widgets]
    if first == nil or last == nil then
        return false
    end

    local left = first:GetLeft()
    local right = last:GetLeft() + last:GetWidth()
    return mouse_x >= left and mouse_x <= right
end

local function _zone_insertion_index(widgets, mouse_x)
    if widgets == nil or #widgets == 0 then
        return 1
    end

    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        return #widgets + 1
    end

    for i = 1, #widgets do
        local widget = widgets[i]
        local midpoint = widget:GetLeft() + (widget:GetWidth() / 2)
        if x < midpoint then
            return i
        end
    end

    return #widgets + 1
end

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

local function _widget_factory(widget_key, widget_w, bar_h, font, widget_cfg, widget_entry)
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

    if widget_key == "time_local" then
        local ctor = _widget_ctor("TimeLocalWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: TimeLocalWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg.content_alignment, widget_cfg.time_format)
    elseif widget_key == "inventory_space" then
        local ctor = _widget_ctor("InventorySpaceWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: InventorySpaceWidget")
        end
        local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color,
            widget_cfg.content_alignment)
    elseif widget_key == "equipment_wear" then
        local ctor = _widget_ctor("EquipmentWearWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: EquipmentWearWidget")
        end
        local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color, widget_cfg.coloring,
            widget_cfg.content_alignment)
    elseif widget_key == "money" then
        local ctor = _widget_ctor("MoneyWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: MoneyWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg ~= nil and widget_cfg.icon == true, widget_cfg.content_alignment)
    elseif widget_key == "wallet" then
        local ctor = _widget_ctor("WalletWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: WalletWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg.content_alignment, widget_cfg.items)
    elseif widget_key == "item" then
        local ctor = _widget_ctor("ItemCountWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: ItemCountWidget")
        end
        return ctor(widget_entry ~= nil and widget_entry.name or nil, widget_w, bar_h, font,
            widget_entry ~= nil and widget_entry.icon_image_id or nil)
    end

    local alignment = Turbine.UI.ContentAlignment.MiddleLeft
    local ctor = _widget_ctor("DummyWidget")
    if ctor == nil then
        error("Missing StatusBar widget constructor: DummyWidget")
    end
    local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
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
    if self.SetAllowDrop ~= nil then
        self:SetAllowDrop(true)
    end
    self.DragDrop = function(_, args)
        self:_handle_drag_drop(args)
    end

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

    local zones = sb.zones
    local widgets_cfg = sb.widgets

    local function build_zone(zone_key, dst)
        local list = zones[zone_key]
        for i = 1, #list do
            local entry = list[i]
            local widget_key = entry
            local cfg = nil

            if S.is_status_bar_item_entry(entry) == true then
                widget_key = "item"
                cfg = widgets_cfg.item
            else
                cfg = widgets_cfg[widget_key]
            end

            if cfg ~= nil and (widget_key == "item" or cfg.enabled == true) then
                local inst = _widget_factory(widget_key, cfg.width, sb.height, sb.font, cfg, entry)
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
    self:SetMouseVisible(true)

    self:_layout_widgets(sb)

    for i = 1, #self._widgets do
        local w = self._widgets[i]
        if w ~= nil then
            w:SetVisible(true)
        end
    end
end

function StatusBarWindow:_get_drop_target()
    local mouse_x = nil
    if self.GetMousePosition ~= nil then
        mouse_x = select(1, self:GetMousePosition())
    end

    local zone_key = _resolve_drop_zone_key(self:GetWidth(), mouse_x)
    if _zone_widgets_contains_x(self._zone_widgets_left, mouse_x) == true then
        zone_key = "left"
    elseif _zone_widgets_contains_x(self._zone_widgets_center, mouse_x) == true then
        zone_key = "center"
    elseif _zone_widgets_contains_x(self._zone_widgets_right, mouse_x) == true then
        zone_key = "right"
    end

    local widgets = self._zone_widgets_left
    if zone_key == "center" then
        widgets = self._zone_widgets_center
    elseif zone_key == "right" then
        widgets = self._zone_widgets_right
    end

    return zone_key, _zone_insertion_index(widgets, mouse_x)
end

function StatusBarWindow:_handle_drag_drop(args)
    local drag_drop_info = args ~= nil and args.DragDropInfo or nil
    local details = S.extract_item_details_from_drag_drop_info(drag_drop_info)
    if details == nil or details.name == nil then
        return
    end

    local raw = _G.loaded_settings
    local raw_sb = raw ~= nil and raw.status_bar or nil
    if raw_sb == nil then
        return
    end

    raw_sb.layout = raw_sb.layout or {}
    raw_sb.layout.left = raw_sb.layout.left or ""
    raw_sb.layout.center = raw_sb.layout.center or ""
    raw_sb.layout.right = raw_sb.layout.right or ""
    raw_sb.item_registry = raw_sb.item_registry or {}

    local token = S.make_status_bar_item_token(details.name)
    if token == nil then
        return
    end

    local combined_layout = table.concat({
        tostring(raw_sb.layout.left or ""),
        tostring(raw_sb.layout.center or ""),
        tostring(raw_sb.layout.right or ""),
    }, " ")
    if S.status_bar_layout_has_item(combined_layout, details.name) == true then
        _write_status_bar_message(string.format("%s is already on the status bar.", token))
        return
    end

    local zone_key, insert_index = self:_get_drop_target()
    raw_sb.layout[zone_key] = _insert_layout_token_at_visible_index(raw_sb.layout[zone_key], token, insert_index)
    S.set_status_bar_item_registry_icon(raw_sb.item_registry, details.name, details.icon_image_id)

    _sync_status_bar_after_raw_edit()
    _write_status_bar_message(string.format("Added %s to the %s status bar zone.", token, zone_key))
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
