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

local DRAG_PREVIEW_FILL_COLOR = Turbine.UI.Color(0.28, 1.00, 1.00, 1.00)
local DRAG_PREVIEW_EDGE_COLOR = Turbine.UI.Color(0.95, 1.00, 1.00, 1.00)
local DRAG_PREVIEW_EDGE_W = 2

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

local function _remove_visible_layout_token_at_index(text, remove_index)
    local tokens = _extract_layout_tokens(text)
    local wanted_index = remove_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        return tostring(text or ""), nil
    end

    local visible_index = 0
    for i = 1, #tokens do
        if _layout_token_is_visible(tokens[i]) == true then
            visible_index = visible_index + 1
            if visible_index == wanted_index then
                local removed_token = tokens[i]
                table.remove(tokens, i)
                return table.concat(tokens, " "), removed_token
            end
        end
    end

    return table.concat(tokens, " "), nil
end

local function _get_widget_menu_title(widget_key, widget_entry)
    if S.is_status_bar_item_entry(widget_entry) == true then
        return widget_entry.name or ""
    end

    if widget_key == "time_local" then
        return TR("Time (local)")
    elseif widget_key == "inventory_space" then
        return TR("Inventory space")
    elseif widget_key == "equipment_wear" then
        return TR("Equipment wear")
    elseif widget_key == "money" then
        return TR("Money")
    elseif widget_key == "wallet" then
        return TR("Wallet")
    elseif widget_key == "config_icon" or widget_key == "config_text" then
        return S.get_shortcut_label("config")
    elseif widget_key == "assets_icon" or widget_key == "assets_text" then
        return S.get_shortcut_label("assets")
    elseif widget_key == "bestiary_icon" or widget_key == "bestiary_text" then
        return S.get_shortcut_label("bestiary")
    end

    return tostring(widget_key or "")
end

local function _bind_widget_interactions(owner, widget, menu_title)
    if owner == nil or widget == nil then
        return
    end

    widget._status_bar_menu_title = tostring(menu_title or "")
    widget:SetMouseVisible(true)
    if widget.SetAllowDrop ~= nil then
        widget:SetAllowDrop(true)
    end

    local prior_mouse_click = widget.MouseClick
    widget.MouseClick = function(sender, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Right then
            owner:_show_widget_menu(widget)
            return
        end
        if prior_mouse_click ~= nil then
            prior_mouse_click(sender, args)
        end
    end

    widget.DragDrop = function(_, args)
        owner:_handle_drag_drop(widget, args)
    end
    widget.DragEnter = function(_, args)
        owner:_handle_drag_enter(widget, args)
    end
    widget.DragLeave = function(_, args)
        owner:_handle_drag_leave(widget, args)
    end

    local prior_mouse_move = widget.MouseMove
    widget.MouseMove = function(sender, args)
        owner:_handle_drag_move(widget, args)
        if prior_mouse_move ~= nil then
            prior_mouse_move(sender, args)
        end
    end
end

local function _sum_zone_width_with_preview(widgets, gap, preview_width)
    local total = S.sum_widget_width(widgets, gap)
    if type(preview_width) == "number" and preview_width > 0 then
        if widgets ~= nil and #widgets > 0 then
            total = total + gap
        end
        total = total + preview_width
    end
    return total
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
    self._drag_preview_details = nil
    self._drag_preview_next_at = 0
    self._drag_preview_zone_key = nil
    self._drag_preview_insert_index = nil
    self._drag_preview_window = Turbine.UI.Window()
    self._drag_preview_window:SetMouseVisible(false)
    self._drag_preview_window:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self._drag_preview_window:SetVisible(true)
    self._drag_preview_window:SetZOrder(200)

    self._drag_preview_fill = Turbine.UI.Control()
    self._drag_preview_fill:SetParent(self._drag_preview_window)
    self._drag_preview_fill:SetMouseVisible(false)
    self._drag_preview_fill:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_fill:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_fill:SetBackColor(DRAG_PREVIEW_FILL_COLOR)
    self._drag_preview_fill:SetVisible(false)
    self._drag_preview_fill:SetZOrder(100)

    self._drag_preview_edge = Turbine.UI.Control()
    self._drag_preview_edge:SetParent(self._drag_preview_window)
    self._drag_preview_edge:SetMouseVisible(false)
    self._drag_preview_edge:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_edge:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_edge:SetBackColor(DRAG_PREVIEW_EDGE_COLOR)
    self._drag_preview_edge:SetVisible(false)
    self._drag_preview_edge:SetZOrder(101)

    self._drag_preview_trailing_edge = Turbine.UI.Control()
    self._drag_preview_trailing_edge:SetParent(self._drag_preview_window)
    self._drag_preview_trailing_edge:SetMouseVisible(false)
    self._drag_preview_trailing_edge:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_trailing_edge:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_trailing_edge:SetBackColor(DRAG_PREVIEW_EDGE_COLOR)
    self._drag_preview_trailing_edge:SetVisible(false)
    self._drag_preview_trailing_edge:SetZOrder(101)

    self:SetMouseVisible(false)
    self:SetVisible(true)
    self:SetWantsUpdates(true)
    self:SetZOrder(-1)
    if self.SetAllowDrop ~= nil then
        self:SetAllowDrop(true)
    end
    self.DragEnter = function(_, args)
        self:_handle_drag_enter(self, args)
    end
    self.DragLeave = function(_, args)
        self:_handle_drag_leave(self, args)
    end
    self.DragDrop = function(_, args)
        self:_handle_drag_drop(self, args)
    end
    self.MouseMove = function(_, args)
        self:_handle_drag_move(self, args)
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

    if self._drag_preview_details ~= nil and now >= (self._drag_preview_next_at or 0) then
        self:_refresh_drag_preview_target_from_mouse()
        self:_update_drag_preview(now, false)
    end

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
    if self._drag_preview_fill ~= nil then self._drag_preview_fill:SetParent(nil) end
    if self._drag_preview_edge ~= nil then self._drag_preview_edge:SetParent(nil) end
    if self._drag_preview_trailing_edge ~= nil then self._drag_preview_trailing_edge:SetParent(nil) end
    if self._drag_preview_window ~= nil then
        self._drag_preview_window:SetVisible(false)
    end
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

    local preview_zone_key = self._drag_preview_zone_key
    local preview_insert_index = self._drag_preview_insert_index
    local preview_width = self._drag_preview_details ~= nil and self:_get_drag_preview_width() or nil

    local left_preview_w = preview_zone_key == "left" and preview_width or nil
    local center_preview_w = preview_zone_key == "center" and preview_width or nil
    local right_preview_w = preview_zone_key == "right" and preview_width or nil

    local left_w = _sum_zone_width_with_preview(left_widgets, gap, left_preview_w)
    local center_w = _sum_zone_width_with_preview(center_widgets, gap, center_preview_w)
    local right_w = _sum_zone_width_with_preview(right_widgets, gap, right_preview_w)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local function place(zone_key, list, x0)
        local x = x0
        local zone_preview_w = zone_key == preview_zone_key and preview_width or nil
        local zone_preview_index = zone_key == preview_zone_key and preview_insert_index or nil
        for i = 1, #list do
            if zone_preview_w ~= nil and zone_preview_index == i then
                x = x + zone_preview_w + gap
            end
            local w = list[i]
            local y = math.floor((bar_h - w:GetHeight()) / 2)
            if y < 0 then y = 0 end
            w:SetPosition(x, y)
            x = x + w:GetWidth() + gap
        end
    end

    place("left", left_widgets, x_left)
    place("center", center_widgets, x_center)
    place("right", right_widgets, x_right)

    if self._drag_preview_details ~= nil then
        self:_update_drag_preview(Turbine.Engine.GetGameTime(), true)
    end
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
                inst._status_bar_zone_key = zone_key
                inst._status_bar_visible_index = i
                inst:SetParent(self)
                inst:SetZOrder(1)
                inst:SetVisible(false)
                _bind_widget_interactions(self, inst, _get_widget_menu_title(widget_key, entry))
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
    local mouse_x = select(1, self:_get_mouse_position_in_bar())
    return self:_get_drop_target_from_mouse_x(mouse_x)
end

function StatusBarWindow:_get_drop_target_from_mouse_x(mouse_x)
    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end

    local zone_key = _resolve_drop_zone_key(self:GetWidth(), x)
    if _zone_widgets_contains_x(self._zone_widgets_left, x) == true then
        zone_key = "left"
    elseif _zone_widgets_contains_x(self._zone_widgets_center, x) == true then
        zone_key = "center"
    elseif _zone_widgets_contains_x(self._zone_widgets_right, x) == true then
        zone_key = "right"
    end

    local widgets = self._zone_widgets_left
    if zone_key == "center" then
        widgets = self._zone_widgets_center
    elseif zone_key == "right" then
        widgets = self._zone_widgets_right
    end

    return zone_key, _zone_insertion_index(widgets, x)
end

function StatusBarWindow:_get_drag_preview_refresh_interval()
    local fps = _G.settings ~= nil and _G.settings.global ~= nil and _G.settings.global.refresh_rate or nil
    if type(fps) ~= "number" then
        fps = tonumber(fps)
    end
    if fps == nil or fps <= 0 then
        fps = 30
    end
    return 1 / fps
end

function StatusBarWindow:_hide_drag_preview()
    local had_preview = self._drag_preview_details ~= nil or self._drag_preview_zone_key ~= nil or
        self._drag_preview_insert_index ~= nil
    self._drag_preview_details = nil
    self._drag_preview_next_at = 0
    self._drag_preview_zone_key = nil
    self._drag_preview_insert_index = nil
    self._drag_preview_fill:SetVisible(false)
    self._drag_preview_edge:SetVisible(false)
    self._drag_preview_trailing_edge:SetVisible(false)
    if had_preview == true then
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_can_preview_drag_item()
    local raw = _G.loaded_settings
    local raw_sb = raw ~= nil and raw.status_bar or nil
    return raw_sb ~= nil
end

function StatusBarWindow:_relayout_after_drag_preview_change()
    local sb = _G.settings ~= nil and _G.settings.status_bar or nil
    if sb ~= nil then
        self:_layout_widgets(sb)
    end
end

function StatusBarWindow:_resolve_drag_target(source, args)
    if source ~= nil and source ~= self and source._status_bar_zone_key ~= nil and
        source._status_bar_visible_index ~= nil then
        local insert_index = source._status_bar_visible_index
        local x = args ~= nil and args.X or nil
        if type(x) ~= "number" then
            x = tonumber(x)
        end
        if type(x) == "number" and x >= (source:GetWidth() / 2) then
            insert_index = insert_index + 1
        end
        return source._status_bar_zone_key, insert_index
    end

    local x = args ~= nil and args.X or nil
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        return self:_get_drop_target()
    end
    return self:_get_drop_target_from_mouse_x(x)
end

function StatusBarWindow:_handle_drag_enter(source, args)
    local drag_drop_info = args ~= nil and args.DragDropInfo or nil
    local details = S.extract_item_details_from_drag_drop_info(drag_drop_info)
    if drag_drop_info ~= nil and details == nil then
        self:_hide_drag_preview()
        return
    end
    if details == nil then
        details = { name = "" }
    end
    if self:_can_preview_drag_item() ~= true then
        self:_hide_drag_preview()
        return
    end

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    if zone_key == nil or insert_index == nil then
        self:_hide_drag_preview()
        return
    end

    self._drag_preview_details = details
    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index
    self:_relayout_after_drag_preview_change()
end

function StatusBarWindow:_handle_drag_leave(source, _)
    if source == self then
        self:_hide_drag_preview()
    end
end

function StatusBarWindow:_handle_drag_move(source, args)
    if self._drag_preview_details == nil then
        return
    end

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    if zone_key == nil or insert_index == nil then
        return
    end

    if zone_key == self._drag_preview_zone_key and insert_index == self._drag_preview_insert_index then
        return
    end

    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index

    local now = Turbine.Engine.GetGameTime()
    if now >= (self._drag_preview_next_at or 0) then
        self._drag_preview_next_at = now + self:_get_drag_preview_refresh_interval()
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_refresh_drag_preview_target_from_mouse()
    if self._drag_preview_details == nil then
        return
    end

    local x, y = self:_get_mouse_position_in_bar()
    local bar_w, bar_h = self:GetSize()
    if type(x) ~= "number" or type(y) ~= "number" then
        return
    end
    if x < 0 or x > bar_w or y < 0 or y > bar_h then
        return
    end

    local zone_key, insert_index = self:_get_drop_target_from_mouse_x(x)
    if zone_key == nil or insert_index == nil then
        return
    end

    if zone_key == self._drag_preview_zone_key and insert_index == self._drag_preview_insert_index then
        return
    end

    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index
    self:_relayout_after_drag_preview_change()
end

function StatusBarWindow:_get_mouse_position_in_bar()
    if Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Display ~= nil and
        Turbine.UI.Display.GetMousePosition ~= nil and self.PointToClient ~= nil then
        local sx, sy = Turbine.UI.Display.GetMousePosition()
        if type(sx) == "number" and type(sy) == "number" then
            return self:PointToClient(sx, sy)
        end
    end

    if self.GetMousePosition ~= nil then
        return self:GetMousePosition()
    end

    return nil, nil
end

function StatusBarWindow:_get_drag_preview_width()
    local item_cfg = _G.settings ~= nil and _G.settings.status_bar ~= nil and _G.settings.status_bar.widgets ~= nil and
        _G.settings.status_bar.widgets.item or nil
    local width = item_cfg ~= nil and item_cfg.width or nil
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil or width < 1 then
        width = math.max(24, self:GetHeight())
    end
    return width
end

function StatusBarWindow:_get_drag_preview_x(zone_key, insert_index, preview_width)
    local sb = _G.settings.status_bar
    local gap = sb.gap
    local pad = sb.padding
    local bar_w = self:GetWidth()

    local left_preview_w = zone_key == "left" and preview_width or nil
    local center_preview_w = zone_key == "center" and preview_width or nil
    local right_preview_w = zone_key == "right" and preview_width or nil

    local left_w = _sum_zone_width_with_preview(self._zone_widgets_left, gap, left_preview_w)
    local center_w = _sum_zone_width_with_preview(self._zone_widgets_center, gap, center_preview_w)
    local right_w = _sum_zone_width_with_preview(self._zone_widgets_right, gap, right_preview_w)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local widgets = self._zone_widgets_left
    local x = x_left
    if zone_key == "center" then
        widgets = self._zone_widgets_center
        x = x_center
    elseif zone_key == "right" then
        widgets = self._zone_widgets_right
        x = x_right
    end

    local wanted_index = insert_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        wanted_index = 1
    end

    for i = 1, #widgets + 1 do
        if i == wanted_index then
            return x
        end
        local widget = widgets[i]
        if widget == nil then
            return x
        end
        x = x + widget:GetWidth() + gap
    end

    return x
end

function StatusBarWindow:_update_drag_preview(now, force)
    if self._drag_preview_details == nil then
        self._drag_preview_fill:SetVisible(false)
        self._drag_preview_edge:SetVisible(false)
        self._drag_preview_trailing_edge:SetVisible(false)
        return
    end

    local zone_key = self._drag_preview_zone_key
    local insert_index = self._drag_preview_insert_index
    if zone_key == nil or insert_index == nil then
        self:_hide_drag_preview()
        return
    end

    if force ~= true then
        self._drag_preview_next_at = now + self:_get_drag_preview_refresh_interval()
    end

    local preview_width = self:_get_drag_preview_width()
    local preview_x = self:_get_drag_preview_x(zone_key, insert_index, preview_width)
    local preview_y = self:GetHeight() > 2 and 1 or 0
    local preview_h = math.max(1, self:GetHeight() - (preview_y * 2))

    self._drag_preview_fill:SetPosition(preview_x, preview_y)
    self._drag_preview_fill:SetSize(preview_width, preview_h)
    self._drag_preview_fill:SetVisible(true)

    self._drag_preview_edge:SetPosition(preview_x, 0)
    self._drag_preview_edge:SetSize(DRAG_PREVIEW_EDGE_W, self:GetHeight())
    self._drag_preview_edge:SetVisible(true)

    self._drag_preview_trailing_edge:SetPosition(preview_x + preview_width - DRAG_PREVIEW_EDGE_W, 0)
    self._drag_preview_trailing_edge:SetSize(DRAG_PREVIEW_EDGE_W, self:GetHeight())
    self._drag_preview_trailing_edge:SetVisible(true)
end

function StatusBarWindow:_handle_drag_drop(source, args)
    self:_hide_drag_preview()

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

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    raw_sb.layout[zone_key] = _insert_layout_token_at_visible_index(raw_sb.layout[zone_key], token, insert_index)
    S.set_status_bar_item_registry_icon(raw_sb.item_registry, details.name, details.icon_image_id)

    _sync_status_bar_after_raw_edit()
    _write_status_bar_message(string.format("Added %s to the %s status bar zone.", token, zone_key))
end

function StatusBarWindow:_show_widget_menu(widget)
    if widget == nil then
        return
    end

    local menu = Turbine.UI.ContextMenu()
    local items = menu:GetItems()

    items:Add(Turbine.UI.MenuItem(widget._status_bar_menu_title or "", false))

    local remove = Turbine.UI.MenuItem(TR("Remove"))
    remove.Click = function()
        self:_remove_widget_instance(widget)
    end
    items:Add(remove)

    self._widget_context_menu = menu
    menu:ShowMenu()
end

function StatusBarWindow:_remove_widget_instance(widget)
    local zone_key = widget ~= nil and widget._status_bar_zone_key or nil
    local visible_index = widget ~= nil and widget._status_bar_visible_index or nil
    local raw = _G.loaded_settings
    local raw_sb = raw ~= nil and raw.status_bar or nil
    if raw_sb == nil or zone_key == nil then
        return
    end

    raw_sb.layout = raw_sb.layout or {}
    raw_sb.layout.left = raw_sb.layout.left or ""
    raw_sb.layout.center = raw_sb.layout.center or ""
    raw_sb.layout.right = raw_sb.layout.right or ""

    local updated, removed_token = _remove_visible_layout_token_at_index(raw_sb.layout[zone_key], visible_index)
    if removed_token == nil then
        return
    end
    raw_sb.layout[zone_key] = updated

    local inner = tostring(removed_token):match("^%%([^%%]+)%%$")
    local item_name = inner ~= nil and S.parse_status_bar_item_name(inner) or nil
    if item_name ~= nil and type(raw_sb.item_registry) == "table" then
        local combined_layout = table.concat({
            tostring(raw_sb.layout.left or ""),
            tostring(raw_sb.layout.center or ""),
            tostring(raw_sb.layout.right or ""),
        }, " ")
        if S.status_bar_layout_has_item(combined_layout, item_name) ~= true then
            local key = S.make_status_bar_item_registry_key(item_name)
            if key ~= nil then
                raw_sb.item_registry[key] = nil
            end
        end
    end

    _sync_status_bar_after_raw_edit()
    _write_status_bar_message(string.format("Removed %s from the status bar.", widget._status_bar_menu_title or "widget"))
end

function StatusBarWindow:_sync_display_width(sb)
    local display_w, _ = Turbine.UI.Display.GetSize()
    if display_w == self._last_display_w then
        return
    end

    self._last_display_w = display_w
    self:SetPosition(0, 0)
    self:SetSize(display_w, sb.height)
    if self._drag_preview_window ~= nil then
        self._drag_preview_window:SetPosition(0, 0)
        self._drag_preview_window:SetSize(display_w, sb.height)
    end
    self:_layout_widgets(sb)
end
