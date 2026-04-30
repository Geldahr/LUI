import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.base_window"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"

local CHAT_DISPLAY_DELAY = 0.25
local ITEM_MATCH_WINDOW = 1.00
local KILL_ATTRIBUTION_WINDOW = 0.20
local EXIT_FADE_DURATION = 0.50

local BASE_ROW_PADDING = 4
local BASE_SPACING = 0
local MIN_WIDTH = 140

local function _with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

local function _normalize_item_name(name)
    local trimmed = _trim(name)
    if trimmed == nil then
        return nil
    end

    trimmed = trimmed:gsub("[%s]+", " ")
    return string.lower(trimmed)
end

local function _strip_timestamp(message)
    if type(message) ~= "string" then
        return ""
    end
    return message:gsub("^%[%d%d/%d%d .-%]%s*", "")
end

local function _parse_kill_name(message)
    if type(message) ~= "string" or string.find(message, " defeated ", 1, true) == nil then
        return nil
    end

    local victim = message:match("^.- defeated the (.+)%.?$")
    if victim == nil then
        victim = message:match("^.- defeated (.+)%.?$")
    end
    return victim
end

local function _parse_quantity_prefix(text)
    if type(text) ~= "string" then
        return 1
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return 1
    end

    local plain = trimmed:match("^(%d+)$")
    if plain ~= nil then
        return tonumber(plain) or 1
    end

    local x_suffix = trimmed:match("^(%d+)%s*[xX]$")
    if x_suffix ~= nil then
        return tonumber(x_suffix) or 1
    end

    local x_prefix = trimmed:match("^[xX]%s*(%d+)$")
    if x_prefix ~= nil then
        return tonumber(x_prefix) or 1
    end

    return 1
end

local function _parse_drop_message(message)
    if type(message) ~= "string" then
        return nil, nil
    end

    local prefix = nil
    local bracketed = nil
    if string.find(message, "You have acquired:", 1, true) == 1 then
        bracketed = message:match("%b[]")
        if bracketed ~= nil then
            prefix = message:match("^You have acquired:%s*(.-)%s*%b[]")
        end
    elseif string.find(message, "Gathered ", 1, true) == 1 and
        string.find(message, " into the ", 1, true) ~= nil then
        bracketed = message:match("%b[]")
        if bracketed ~= nil then
            prefix = message:match("^Gathered%s*(.-)%s*%b[]")
        end
    end

    if bracketed == nil then
        return nil, nil
    end

    local name = _trim(string.sub(bracketed, 2, -2))
    if name == nil then
        return nil, nil
    end

    return name, _parse_quantity_prefix(prefix)
end

local function _safe_item_name(item)
    if item == nil then
        return nil
    end

    local name = nil
    if item.GetName ~= nil then
        name = item:GetName()
    end
    if _trim(name) ~= nil then
        return name
    end

    if item.GetItemInfo ~= nil then
        local item_info = item:GetItemInfo()
        if item_info ~= nil and item_info.GetName ~= nil then
            return item_info:GetName()
        end
    end

    return nil
end

local function _find_backpack_item_by_name(backpack, normalized_name)
    if backpack == nil or normalized_name == nil then
        return nil
    end
    if backpack.GetSize == nil or backpack.GetItem == nil then
        return nil
    end

    local size = tonumber(backpack:GetSize()) or 0
    for index = 1, size do
        local item = backpack:GetItem(index)
        if item ~= nil and _normalize_item_name(_safe_item_name(item)) == normalized_name then
            return item
        end
    end

    return nil
end

local function _row_padding()
    return lui_scaled_int(BASE_ROW_PADDING)
end

local function _row_height()
    return _G.settings.drops.icon_size + (2 * _row_padding())
end

local function _row_spacing()
    return lui_scaled_int(BASE_SPACING)
end

local DropBackgroundWindow = class(LuiBaseWindow)

function DropBackgroundWindow:Constructor()
    LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetZOrder(0)
    _set_alpha_backdrop(self)
end

function DropBackgroundWindow:apply_settings()
    local s = _G.settings.drops
    self:SetBackColor(_with_alpha(s.hud.background_color, s.hud.background_opacity))
end

function DropBackgroundWindow:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

DropsWindow = class(LuiHUD)

function DropsWindow:Constructor()
    LuiHUD.Constructor(self, {
        hud_key = "drops",
        title = TR["Drops"],
        mouse_visible = false,
    })

    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = nil
    self.player_name = nil
    self.last_update_at = 0
    self.update_every = 1.0 / _G.settings.global.refresh_rate

    self._callbacks = {}
    self._pending_kills = {}
    self._pending_chat_drops = {}
    self._pending_item_events = {}
    self._active_drops = {}
    self._entry_pool = {}

    if self.player ~= nil and self.player.GetName ~= nil then
        self.player_name = self.player:GetName()
    end

    self:SetWantsUpdates(true)
    self:SetVisible(false)
    self:SetZOrder(0)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    self.background:SetVisible(false)
    _set_alpha_backdrop(self.background)

    self.content_background = DropBackgroundWindow()

    self:_bind_events()
    self:apply_settings()
end

function DropsWindow:destroy()
    self:_detach_callbacks()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil then
            self:_recycle_entry(record)
        end
    end
    self._active_drops = {}
    self._pending_chat_drops = {}
    self._pending_item_events = {}
    self._pending_kills = {}
    for i = 1, #self._entry_pool do
        local entry = self._entry_pool[i]
        if entry ~= nil then
            entry:destroy()
        end
    end
    self._entry_pool = {}
    self:_destroy_content_background()
    self:_detach_background()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:SetParent(nil)
end

function DropsWindow:set_move_mode(enabled)
    local changed = (enabled == true) ~= self:is_move_mode()
    LuiHUD.set_move_mode(self, enabled)
    if changed and enabled == true then
        self:_hide_entries()
    elseif changed then
        self.last_update_at = -(self.update_every or 0)
        self:_show_entries()
        self:Update()
    end
    self:_refresh_background(enabled == true)
    self:refresh_visibility()
end

function DropsWindow:apply_settings()
    self:apply_native_scaling()
    self.update_every = 1.0 / _G.settings.global.refresh_rate

    local s = _G.settings.drops
    local width = s.width
    if width < MIN_WIDTH then
        width = MIN_WIDTH
    end
    local rows = math.max(1, math.floor((tonumber(s.rows) or 1) + 0.5))
    local row_h = _row_height()
    local spacing = _row_spacing()
    local height = (rows * row_h) + ((rows - 1) * spacing)

    self:SetSize(width, height)
    self.background:SetSize(width, height)
    self.background:SetBackColor(_with_alpha(s.hud.background_color, s.hud.background_opacity))
    self.content_background:apply_settings()
    self:layout_move_chrome()
    self:apply_hud_position()
    self:_bind_events()

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil then
            local entry = record.entry
            if entry ~= nil then
                entry:apply_settings()
            end
        end
    end

    self:_layout_active_drops(Turbine.Engine.GetGameTime(), false)
    self:refresh_visibility()
end

function DropsWindow:refresh_visibility()
    local any_visible = #self._active_drops > 0
    self:SetVisible(any_visible or self:is_move_mode())
end

function DropsWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if self:is_move_mode() == true then
        self:_refresh_background(true)
        self:refresh_visibility()
        return
    end

    self:_expire_pending_kills(now)
    self:_expire_pending_item_events(now)
    self:_promote_pending_chat_drops(now)
    self:_expire_active_drops(now)
    self:_update_entry_positions(now)
    self:_refresh_background(false)
    self:refresh_visibility()
end

function DropsWindow:_detach_background()
    if self.background ~= nil then
        self.background:SetVisible(false)
        self.background:SetParent(nil)
        self.background = nil
    end
end

function DropsWindow:_destroy_content_background()
    if self.content_background ~= nil then
        self.content_background:destroy()
        self.content_background = nil
    end
end

function DropsWindow:_bind_events()
    local next_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    local next_backpack = nil
    if next_player ~= nil and next_player.GetBackpack ~= nil then
        next_backpack = next_player:GetBackpack()
    end

    if self.player == next_player and self.backpack == next_backpack and #self._callbacks > 0 then
        return
    end

    self.player = next_player
    self.backpack = next_backpack
    self:_detach_callbacks()

    self:_attach(Turbine.Chat, "Received", function(_, args)
        self:_on_chat_received(args)
    end)

    if self.backpack ~= nil then
        self:_attach(self.backpack, "ItemAdded", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemAdded")
        end)
        self:_attach(self.backpack, "ItemChanged", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemChanged")
        end)
        self:_attach(self.backpack, "ItemMoved", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemMoved")
        end)
        self:_attach(self.backpack, "ItemRemoved", function(sender, args)
            self:_on_backpack_item_event(sender, args, "ItemRemoved")
        end)
    end
end

function DropsWindow:_attach(object, event_name, callback)
    local handle = add_callback(object, event_name, callback)
    if handle ~= nil then
        self._callbacks[#self._callbacks + 1] = {
            object = object,
            event_name = event_name,
            handle = handle,
        }
    end
end

function DropsWindow:_detach_callbacks()
    for i = 1, #self._callbacks do
        local callback = self._callbacks[i]
        if callback ~= nil then
            remove_callback(callback.object, callback.event_name, callback.handle)
        end
    end
    self._callbacks = {}
end

function DropsWindow:_on_chat_received(args)
    if args == nil then
        return
    end

    local chat_type = args.ChatType
    if chat_type ~= Turbine.ChatType.Death and chat_type ~= Turbine.ChatType.SelfLoot then
        return
    end

    local message = _strip_timestamp(args.Message)
    if message == "" then
        return
    end

    local now = Turbine.Engine.GetGameTime()

    if chat_type == Turbine.ChatType.Death then
        self:_expire_pending_kills(now)
        if _parse_kill_name(message) ~= nil then
            self._pending_kills[#self._pending_kills + 1] = {
                at = now,
            }
        end
        return
    end

    self:_expire_pending_kills(now)
    if #self._pending_kills == 0 then
        return
    end

    local item_name, quantity = _parse_drop_message(message)
    if item_name == nil then
        return
    end

    self:_queue_chat_drop(item_name, quantity, now)
end

function DropsWindow:_queue_chat_drop(name, quantity, now)
    local normalized_name = _normalize_item_name(name)
    if normalized_name == nil then
        return
    end

    local record = {
        name = name,
        normalized_name = normalized_name,
        quantity = tonumber(quantity) or 1,
        chat_at = now,
        display_after = now + CHAT_DISPLAY_DELAY,
        upgrade_until = now + ITEM_MATCH_WINDOW,
        shown_at = nil,
        expire_at = nil,
        removing = false,
        fade_end_at = nil,
        opacity = 1,
        current_y = nil,
        move_start_at = nil,
        move_end_at = nil,
        move_from_y = nil,
        move_to_y = nil,
        entry = nil,
        live_item = nil,
    }

    local pending_item = self:_take_pending_item_event(normalized_name, now)
    if pending_item ~= nil then
        record.live_item = pending_item.item
    elseif self.backpack ~= nil then
        record.live_item = _find_backpack_item_by_name(self.backpack, normalized_name)
    end

    self._pending_chat_drops[#self._pending_chat_drops + 1] = record
end

function DropsWindow:_on_backpack_item_event(sender, args, event_name)
    if sender == nil or args == nil then
        return
    end

    local item = nil
    if event_name == "ItemAdded" or event_name == "ItemChanged" then
        local index = args.Index
        if index ~= nil and sender.GetItem ~= nil then
            item = sender:GetItem(index)
        end
    elseif event_name == "ItemMoved" then
        local index = args.NewIndex
        if index ~= nil and sender.GetItem ~= nil then
            item = sender:GetItem(index)
        end
    else
        return
    end

    if item == nil then
        return
    end

    local item_name = _safe_item_name(item)
    local normalized_name = _normalize_item_name(item_name)
    if normalized_name == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    local record = self:_find_oldest_unresolved_drop(normalized_name, now)
    if record ~= nil then
        self:_assign_live_item(record, item)
        return
    end

    self._pending_item_events[#self._pending_item_events + 1] = {
        normalized_name = normalized_name,
        item = item,
        at = now,
        expires_at = now + ITEM_MATCH_WINDOW,
    }
end

function DropsWindow:_find_oldest_unresolved_drop(normalized_name, now)
    local best = nil

    local function consider(record)
        if record == nil then
            return
        end
        if record.normalized_name ~= normalized_name then
            return
        end
        if record.live_item ~= nil then
            return
        end
        if record.removing == true then
            return
        end
        if now > (record.upgrade_until or 0) then
            return
        end
        if best == nil or (record.chat_at or 0) < (best.chat_at or 0) then
            best = record
        end
    end

    for i = 1, #self._pending_chat_drops do
        consider(self._pending_chat_drops[i])
    end
    for i = 1, #self._active_drops do
        consider(self._active_drops[i])
    end

    return best
end

function DropsWindow:_assign_live_item(record, item)
    if record == nil then
        return
    end
    record.live_item = item
    if record.entry ~= nil then
        record.entry:set_live_item(item)
    end
end

function DropsWindow:_take_pending_item_event(normalized_name, now)
    local best_index = nil
    local best_event = nil

    for i = 1, #self._pending_item_events do
        local event = self._pending_item_events[i]
        if event ~= nil then
            if now > (event.expires_at or 0) then
                table.remove(self._pending_item_events, i)
                return self:_take_pending_item_event(normalized_name, now)
            end
            if event.normalized_name == normalized_name then
                if best_event == nil or (event.at or 0) < (best_event.at or 0) then
                    best_index = i
                    best_event = event
                end
            end
        end
    end

    if best_index ~= nil then
        table.remove(self._pending_item_events, best_index)
    end

    return best_event
end

function DropsWindow:_expire_pending_kills(now)
    while #self._pending_kills > 0 do
        local record = self._pending_kills[1]
        if record ~= nil and (now - (record.at or now)) < KILL_ATTRIBUTION_WINDOW then
            break
        end
        table.remove(self._pending_kills, 1)
    end
end

function DropsWindow:_expire_pending_item_events(now)
    for i = #self._pending_item_events, 1, -1 do
        local event = self._pending_item_events[i]
        if event == nil or now > (event.expires_at or 0) then
            table.remove(self._pending_item_events, i)
        end
    end
end

function DropsWindow:_promote_pending_chat_drops(now)
    local duration = tonumber(_G.settings.drops.visible_duration) or 4
    if duration <= 0 then
        duration = 4
    end

    for i = #self._pending_chat_drops, 1, -1 do
        local record = self._pending_chat_drops[i]
        if record ~= nil and now >= (record.display_after or 0) then
            table.remove(self._pending_chat_drops, i)
            if #self._active_drops >= self:_rows_capacity() then
                self:_force_remove_oldest_active()
            end

            record.shown_at = now
            record.expire_at = now + duration
            if record.live_item == nil and self.backpack ~= nil then
                record.live_item = _find_backpack_item_by_name(self.backpack, record.normalized_name)
            end
            record.entry = self:_acquire_entry()
            record.entry:apply_settings()
            record.entry:set_record(record)
            record.entry:SetVisible(true)
            self._active_drops[#self._active_drops + 1] = record
            self:_layout_active_drops(now, false)
        end
    end
end

function DropsWindow:_rows_capacity()
    local rows = tonumber(_G.settings.drops.rows)
    if rows == nil then
        return 1
    end
    rows = math.floor(rows + 0.5)
    if rows < 1 then
        rows = 1
    end
    return rows
end

function DropsWindow:_acquire_entry()
    local entry = self._entry_pool[#self._entry_pool]
    if entry ~= nil then
        self._entry_pool[#self._entry_pool] = nil
        return entry
    end
    return DropEntry()
end

function DropsWindow:_recycle_entry(record)
    if record == nil or record.entry == nil then
        return
    end

    local entry = record.entry
    entry:set_record(nil)
    entry:SetVisible(false)
    entry:SetParent(nil)
    self._entry_pool[#self._entry_pool + 1] = entry
    record.entry = nil
end

function DropsWindow:_force_remove_oldest_active()
    if #self._active_drops == 0 then
        return
    end

    local record = table.remove(self._active_drops, 1)
    self:_recycle_entry(record)
end

function DropsWindow:_expire_active_drops(now)
    local animations_enabled = _G.settings.drops.animations_enabled == true
    local removed = false

    for i = #self._active_drops, 1, -1 do
        local record = self._active_drops[i]
        if record ~= nil and record.removing ~= true and now >= (record.expire_at or 0) then
            if animations_enabled == true then
                record.removing = true
                record.fade_end_at = now + EXIT_FADE_DURATION
            else
                table.remove(self._active_drops, i)
                self:_recycle_entry(record)
                removed = true
            end
        end
    end

    if removed == true then
        self:_layout_active_drops(now, false)
    end

    local faded = false
    for i = #self._active_drops, 1, -1 do
        local record = self._active_drops[i]
        if record ~= nil and record.removing == true and now >= (record.fade_end_at or 0) then
            table.remove(self._active_drops, i)
            self:_recycle_entry(record)
            faded = true
        end
    end

    if faded == true then
        self:_layout_active_drops(now, false)
    end
end

function DropsWindow:_layout_active_drops(now, animate)
    local anchor_x, anchor_y = self:GetPosition()
    local width, height = self:GetSize()
    local active_count = #self._active_drops
    local row_h = _row_height()
    local spacing = _row_spacing()
    local step = row_h + spacing
    local block_h = 0
    if active_count > 0 then
        block_h = (active_count * row_h) + ((active_count - 1) * spacing)
    end

    local flow = _G.settings.drops.flow
    local base_y = 0
    if flow == LUI_ENUMS.list_flow.BOTTOM_TO_TOP then
        base_y = height - block_h
        if base_y < 0 then
            base_y = 0
        end
    end

    local ordered = {}
    if flow == LUI_ENUMS.list_flow.TOP_TO_BOTTOM then
        for i = active_count, 1, -1 do
            ordered[#ordered + 1] = self._active_drops[i]
        end
    else
        for i = 1, active_count do
            ordered[#ordered + 1] = self._active_drops[i]
        end
    end

    for i = 1, #ordered do
        local record = ordered[i]
        local target_y = base_y + ((i - 1) * step)
        record.target_y = target_y

        if record.entry ~= nil then
            record.current_y = target_y
            record.move_start_at = nil
            record.move_end_at = nil
            record.move_from_y = nil
            record.move_to_y = nil
            record.entry:SetPosition(anchor_x, anchor_y + target_y)
        end
    end

    self:_refresh_background(self:is_move_mode())
end

function DropsWindow:_update_entry_positions(now)
    local anchor_x, anchor_y = self:GetPosition()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        local entry = record ~= nil and record.entry or nil
        if entry ~= nil then
            local y = record.current_y or record.target_y or 0

            local opacity = 1
            if record.removing == true and record.fade_end_at ~= nil then
                local remaining = record.fade_end_at - now
                if remaining <= 0 then
                    opacity = 0
                else
                    opacity = remaining / EXIT_FADE_DURATION
                end
            end

            entry:set_opacity(opacity)
            entry:SetPosition(anchor_x, anchor_y + math.floor(y + 0.5))
        end
    end
end

function DropsWindow:_refresh_background(move_mode)
    if self.background == nil or self.content_background == nil then
        return
    end

    local width, height = self:GetSize()
    if move_mode == true then
        self.background:SetVisible(true)
        self.background:SetPosition(0, 0)
        self.background:SetSize(width, height)
        self.content_background:SetVisible(false)
        return
    end

    self.background:SetVisible(false)

    local active_count = #self._active_drops
    if active_count <= 0 then
        self.content_background:SetVisible(false)
        return
    end

    local row_h = _row_height()
    local spacing = _row_spacing()
    local block_h = (active_count * row_h) + ((active_count - 1) * spacing)
    local flow = _G.settings.drops.flow
    local base_y = 0
    if flow == LUI_ENUMS.list_flow.BOTTOM_TO_TOP then
        base_y = height - block_h
        if base_y < 0 then
            base_y = 0
        end
    end

    local anchor_x, anchor_y = self:GetPosition()
    self.content_background:SetVisible(true)
    self.content_background:SetPosition(anchor_x, anchor_y + base_y)
    self.content_background:SetSize(width, block_h)
end

function DropsWindow:_hide_entries()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.entry ~= nil then
            record.entry:SetVisible(false)
        end
    end
end

function DropsWindow:_show_entries()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.entry ~= nil then
            record.entry:SetVisible(true)
        end
    end
end
