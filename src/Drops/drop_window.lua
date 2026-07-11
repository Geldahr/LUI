-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Drops = _G.LUI.Features.Drops
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local Lore = _G.LUI.Data.Lore
local UI = _G.LUI.UI
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.base_window"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local CHAT_DISPLAY_DELAY = 0.25
local ITEM_MATCH_WINDOW = 1.00
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

local function _drops_tr(key, fallback)
    local value = TR[key]
    if value == key then
        return fallback
    end
    return value
end

local function _starts_with(text, prefix)
    if type(text) ~= "string" or type(prefix) ~= "string" then
        return false
    end
    return string.sub(text, 1, string.len(prefix)) == prefix
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

    local bracket_start, bracket_end = string.find(message, "%b[]")
    if bracket_start == nil or bracket_end == nil then
        return nil, nil
    end

    local acquired_prefix = _drops_tr("__drops_chat_acquired_prefix", "You have acquired")
    local gathered_prefix = _drops_tr("__drops_chat_gathered_prefix", "Gathered")
    local quantity_prefix = nil
    local gathered_message = false
    if _starts_with(message, acquired_prefix) == true then
        quantity_prefix = string.sub(message, string.len(acquired_prefix) + 1, bracket_start - 1)
    elseif _starts_with(message, gathered_prefix) == true then
        gathered_message = true
        quantity_prefix = string.sub(message, string.len(gathered_prefix) + 1, bracket_start - 1)
    else
        return nil, nil
    end

    local name = _trim(string.sub(message, bracket_start + 1, bracket_end - 1))
    if name == nil then
        return nil, nil
    end

    quantity_prefix = quantity_prefix:gsub("^%s*[:%-]*%s*", "")
    local quantity = _parse_quantity_prefix(quantity_prefix)
    if gathered_message == true and quantity == 1 then
        local bracket_quantity, bracket_name = name:match("^(%d+)%s+(.+)$")
        if bracket_quantity ~= nil and _trim(bracket_name) ~= nil then
            quantity = tonumber(bracket_quantity) or 1
            name = _trim(bracket_name)
        end
    end
    return name, quantity
end

-- resolve the printed loot name against the Items DB: stacked drops print
-- the plural display name, singles the exact name. Returns the canonical
-- display name, quantity, and the resolved ordinals; on DB-not-loaded or
-- unknown item the inputs pass through unchanged (ordinals nil) - only
-- what the DB confirms is rewritten, so a not-yet-in-DB item named with a
-- leading count ("100 Virtue XP" is one item, not a stack) is never split.
local function _canonicalize_drop(name, quantity)
    if Lore.Items.loaded ~= true then
        return name, quantity, nil
    end

    local ordinals
    if quantity > 1 then
        -- gathered stacks arrive count-stripped with the quantity parsed:
        -- the name is a plural form, so the plural index outranks a
        -- literal name collision ("Bones" the plural vs "Bones" the item)
        ordinals = Lore.Items.find_plural_ordinals(name)
        if ordinals ~= nil then
            return Lore.Items.label(ordinals[1]), quantity, ordinals
        end
        return name, quantity, Lore.Items.find_ordinals(name)
    end

    ordinals = Lore.Items.find_ordinals(name)
    if ordinals ~= nil then
        return name, quantity, ordinals
    end
    -- acquired stacks keep the count in the bracket ("[5 Hides]"): split,
    -- resolve the remainder plural-first, singular for names authored in
    -- plural form ("200 Figments of Splendour"); a full miss keeps the
    -- printed name
    local count, rest = name:match("^(%d+)%s+(.+)$")
    if count ~= nil then
        ordinals = Lore.Items.find_plural_ordinals(rest)
        if ordinals ~= nil then
            return Lore.Items.label(ordinals[1]), tonumber(count), ordinals
        end
        ordinals = Lore.Items.find_ordinals(rest)
        if ordinals ~= nil then
            return rest, tonumber(count), ordinals
        end
        return name, quantity, nil
    end
    return name, quantity, Lore.Items.find_plural_ordinals(name)
end

local function _visible_duration()
    local duration = tonumber(State.settings.drops.visible_duration) or 4
    if duration <= 0 then
        duration = 4
    end
    return duration
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
    return scaled_int(BASE_ROW_PADDING)
end

local function _row_height()
    return State.settings.drops.icon_size + (2 * _row_padding())
end

local function _row_spacing()
    return scaled_int(BASE_SPACING)
end

local function _move_duration()
    local duration_ms = tonumber(State.settings.drops.move_duration)
    if duration_ms == nil or duration_ms <= 0 then
        return 0
    end
    return duration_ms / 1000
end

local DropBackgroundWindow = class(UI.Widgets.LuiBaseWindow)

function DropBackgroundWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetZOrder(0)
    _set_alpha_backdrop(self)
end

function DropBackgroundWindow:apply_settings()
    local s = State.settings.drops
    self:SetBackColor(_with_alpha(s.hud.background_color, s.hud.background_opacity))
end

function DropBackgroundWindow:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

local DropsWindow = class(UI.Widgets.LuiHUD)
Drops.DropsWindow = DropsWindow

function DropsWindow:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "drops",
        title = TR["Drops"],
        mouse_visible = false,
    })

    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = nil
    self.player_name = nil
    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self._callbacks = {}
    self._pending_chat_drops = {}
    self._pending_item_events = {}
    self._active_drops = {}
    self._entry_pool = {}
    self._lore_import_plan = nil
    self._lore_import_index = 1
    self._db_icon_cache = {}

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
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
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
    self.update_every = 1.0 / State.settings.global.refresh_rate

    local s = State.settings.drops
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

    self:_step_lore_import()

    if self:is_move_mode() == true then
        self:_refresh_background(true)
        self:refresh_visibility()
        return
    end

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

    if args.ChatType ~= Turbine.ChatType.SelfLoot then
        return
    end

    local message = _strip_timestamp(args.Message)
    if message == "" then
        return
    end

    local item_name, quantity = _parse_drop_message(message)
    if item_name == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    self:_queue_chat_drop(item_name, quantity, now)
end

-- fold a new drop into a live row of the same item: quantities add up,
-- fresh loot keeps the row alive, the row never moves. Rows already
-- fading out are left alone - the new drop starts a fresh row.
function DropsWindow:_merge_into_existing(normalized_name, quantity, now)
    for i = 1, #self._pending_chat_drops do
        local record = self._pending_chat_drops[i]
        if record ~= nil and record.normalized_name == normalized_name then
            record.quantity = record.quantity + quantity
            return true
        end
    end

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.removing ~= true
            and record.normalized_name == normalized_name then
            record.quantity = record.quantity + quantity
            record.expire_at = now + _visible_duration()
            record.entry:set_record(record)
            return true
        end
    end

    return false
end

function DropsWindow:_queue_chat_drop(name, quantity, now)
    quantity = tonumber(quantity) or 1
    local ordinals
    name, quantity, ordinals = _canonicalize_drop(name, quantity)

    local normalized_name = _normalize_item_name(name)
    if normalized_name == nil then
        return
    end

    if State.settings.drops.merge_similar == true
        and self:_merge_into_existing(normalized_name, quantity, now) then
        return
    end

    local record = {
        name = name,
        normalized_name = normalized_name,
        quantity = quantity,
        chat_at = now,
        display_after = now + CHAT_DISPLAY_DELAY,
        upgrade_until = now + ITEM_MATCH_WINDOW,
        shown_at = nil,
        expire_at = nil,
        removing = false,
        fade_end_at = nil,
        opacity = 1,
        current_y = nil,
        target_y = nil,
        pinned_y = nil,
        move_start_at = nil,
        move_end_at = nil,
        move_from_y = nil,
        move_to_y = nil,
        layout_excluded = false,
        entry = nil,
        live_item = nil,
    }

    local pending_item = self:_take_pending_item_event(normalized_name, now)
    if pending_item ~= nil then
        record.live_item = pending_item.item
    elseif self.backpack ~= nil then
        record.live_item = _find_backpack_item_by_name(self.backpack, normalized_name)
    end
    if record.live_item == nil then
        -- carry-all loot: no live item ever appears, resolve from the DB;
        -- canonicalization already found the record, so reuse its ordinals
        if ordinals ~= nil then
            record.db_icon_id, record.db_background_id = Lore.Items.icon_layers(ordinals[1])
        else
            record.db_icon_id, record.db_background_id =
                self:_db_icon_for(name, normalized_name, record.quantity)
        end
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

function DropsWindow:_expire_pending_item_events(now)
    for i = #self._pending_item_events, 1, -1 do
        local event = self._pending_item_events[i]
        if event == nil or now > (event.expires_at or 0) then
            table.remove(self._pending_item_events, i)
        end
    end
end

function DropsWindow:_promote_pending_chat_drops(now)
    local duration = _visible_duration()

    local matured = {}
    for i = #self._pending_chat_drops, 1, -1 do
        local record = self._pending_chat_drops[i]
        if record ~= nil and now >= (record.display_after or 0) then
            table.remove(self._pending_chat_drops, i)
            matured[#matured + 1] = record
        end
    end

    for i = #matured, 1, -1 do
        local record = matured[i]
        while self:_layout_record_count() >= self:_rows_capacity() do
            self:_remove_oldest_visible_for_overflow(now)
        end

        record.shown_at = now
        record.expire_at = now + duration
        if record.live_item == nil and self.backpack ~= nil then
            record.live_item = _find_backpack_item_by_name(self.backpack, record.normalized_name)
        end
        if record.live_item == nil and record.db_icon_id == nil then
            record.db_icon_id, record.db_background_id =
                self:_db_icon_for(record.name, record.normalized_name, record.quantity)
        end
        record.entry = self:_acquire_entry()
        record.entry:apply_settings()
        record.entry:set_record(record)
        record.entry:SetVisible(true)
        self._active_drops[#self._active_drops + 1] = record
        self:_layout_active_drops(now, false)
    end
end

-- stage the lore Items DB one file per tick so carry-all loot (which never
-- surfaces a live backpack item) can resolve icons by name; a no-op once
-- another feature (crafting) has already loaded the domain
function DropsWindow:_step_lore_import()
    if Lore.Items.loaded == true then
        return
    end
    if self._lore_import_plan == nil then
        self._lore_import_plan = Lore.items_import_plan()
        self._lore_import_index = 1
    end
    if self._lore_import_index <= #self._lore_import_plan then
        Lore.import_step(self._lore_import_plan[self._lore_import_index])
        self._lore_import_index = self._lore_import_index + 1
        return
    end
    Lore.load_items()
end

-- lore-DB icon fallback, cached per item name; false = known miss (item
-- newer than the data drop, or a chat string that is not an item name)
function DropsWindow:_db_icon_for(name, normalized_name, quantity)
    if Lore.Items.loaded ~= true then
        return nil, nil
    end

    -- a parsed quantity > 1 means the bracket carried a count, so the
    -- printed name is the plural form (gathered lines: "[5 Bones]" arrives
    -- count-stripped as "Bones"); resolution depends on this bit, so it is
    -- part of the cache key ("\t" cannot appear in item names)
    local plural_likely = quantity ~= nil and quantity > 1
    local cache_key = normalized_name
    if plural_likely then
        cache_key = "#p\t" .. normalized_name
    end

    local cached = self._db_icon_cache[cache_key]
    if cached == false then
        return nil, nil
    end
    if cached ~= nil then
        return cached[1], cached[2]
    end

    -- resolution order: for known stacks the plural index wins over a
    -- literal name collision ("Bones" the plural of "Bone" vs "Bones" the
    -- item); otherwise exact display name first (also covers items whose
    -- name starts with a number, "100 Virtue XP"). Then the in-bracket
    -- stacked form of acquired lines ("[5 Hides]") with the count removed -
    -- plural first, and singular for plurals equal to the display name
    local ordinals
    if plural_likely then
        ordinals = Lore.Items.find_plural_ordinals(name)
        if ordinals == nil then
            ordinals = Lore.Items.find_ordinals(name)
        end
    else
        ordinals = Lore.Items.find_ordinals(name)
        if ordinals == nil then
            ordinals = Lore.Items.find_plural_ordinals(name)
        end
    end
    if ordinals == nil then
        local stacked_name = name:match("^%d+%s+(.+)$")
        if stacked_name ~= nil then
            ordinals = Lore.Items.find_plural_ordinals(stacked_name)
            if ordinals == nil then
                ordinals = Lore.Items.find_ordinals(stacked_name)
            end
        end
    end
    if ordinals == nil then
        self._db_icon_cache[cache_key] = false
        return nil, nil
    end
    local icon_id, background_id = Lore.Items.icon_layers(ordinals[1])
    if icon_id == nil then
        self._db_icon_cache[cache_key] = false
        return nil, nil
    end
    self._db_icon_cache[cache_key] = { icon_id, background_id }
    return icon_id, background_id
end

function DropsWindow:_rows_capacity()
    local rows = tonumber(State.settings.drops.rows)
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
    return Drops.DropEntry()
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

function DropsWindow:_layout_record_count()
    local count = 0
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded ~= true then
            count = count + 1
        end
    end
    return count
end

function DropsWindow:_layout_block_height(count)
    if count <= 0 then
        return 0
    end

    local row_h = _row_height()
    local spacing = _row_spacing()
    return (count * row_h) + ((count - 1) * spacing)
end

function DropsWindow:_layout_base_y(count)
    local _, height = self:GetSize()
    local base_y = 0
    if State.settings.drops.align == LUI_ENUMS.vertical_align.BOTTOM then
        base_y = height - self:_layout_block_height(count)
        if base_y < 0 then
            base_y = 0
        end
    end
    return base_y
end

function DropsWindow:_ordered_layout_records()
    local ordered = {}
    local flow = State.settings.drops.flow

    if flow == LUI_ENUMS.list_flow.TOP_TO_BOTTOM then
        for i = #self._active_drops, 1, -1 do
            local record = self._active_drops[i]
            if record ~= nil and record.layout_excluded ~= true then
                ordered[#ordered + 1] = record
            end
        end
    else
        for i = 1, #self._active_drops do
            local record = self._active_drops[i]
            if record ~= nil and record.layout_excluded ~= true then
                ordered[#ordered + 1] = record
            end
        end
    end

    return ordered
end

function DropsWindow:_clear_move_state(record)
    record.move_start_at = nil
    record.move_end_at = nil
    record.move_from_y = nil
    record.move_to_y = nil
end

function DropsWindow:_set_entry_y(record, anchor_x, anchor_y, y)
    record.current_y = y
    if record.entry ~= nil then
        record.entry:SetPosition(anchor_x, anchor_y + math.floor(y + 0.5))
    end
end

function DropsWindow:_find_oldest_visible_record_index()
    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded ~= true then
            return i
        end
    end
    return nil
end

function DropsWindow:_remove_oldest_visible_for_overflow(now)
    local index = self:_find_oldest_visible_record_index()
    if index == nil then
        return
    end

    local record = self._active_drops[index]
    if State.settings.drops.animations_enabled == true then
        record.removing = true
        if record.fade_end_at == nil or now > record.fade_end_at then
            record.fade_end_at = now + EXIT_FADE_DURATION
        end
        record.layout_excluded = true
        record.pinned_y = record.current_y or record.target_y or 0
        record.target_y = record.pinned_y
        self:_clear_move_state(record)
    else
        table.remove(self._active_drops, index)
        self:_recycle_entry(record)
    end
end

function DropsWindow:_expire_active_drops(now)
    local animations_enabled = State.settings.drops.animations_enabled == true
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
        self:_layout_active_drops(now, animations_enabled)
    end
end

function DropsWindow:_layout_active_drops(now, animate)
    local anchor_x, anchor_y = self:GetPosition()
    local active_count = self:_layout_record_count()
    local row_h = _row_height()
    local spacing = _row_spacing()
    local step = row_h + spacing
    local base_y = self:_layout_base_y(active_count)
    local ordered = self:_ordered_layout_records()
    local move_duration = _move_duration()

    for i = 1, #ordered do
        local record = ordered[i]
        local target_y = base_y + ((i - 1) * step)
        record.target_y = target_y
        record.layout_excluded = false
        record.pinned_y = nil

        if record.entry ~= nil then
            if animate == true and move_duration > 0 and record.current_y ~= nil and math.abs(record.current_y - target_y) > 0.01 then
                record.move_start_at = now
                record.move_end_at = now + move_duration
                record.move_from_y = record.current_y
                record.move_to_y = target_y
            else
                self:_clear_move_state(record)
                self:_set_entry_y(record, anchor_x, anchor_y, target_y)
            end
        else
            record.current_y = target_y
        end
    end

    for i = 1, #self._active_drops do
        local record = self._active_drops[i]
        if record ~= nil and record.layout_excluded == true then
            local pinned_y = record.pinned_y or record.current_y or record.target_y or 0
            record.pinned_y = pinned_y
            record.target_y = pinned_y
            self:_clear_move_state(record)
            self:_set_entry_y(record, anchor_x, anchor_y, pinned_y)
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

            if record.move_end_at ~= nil and record.move_start_at ~= nil and record.move_from_y ~= nil and record.move_to_y ~= nil then
                if now >= record.move_end_at then
                    y = record.move_to_y
                    self:_clear_move_state(record)
                else
                    local duration = record.move_end_at - record.move_start_at
                    local progress = 1
                    if duration > 0 then
                        progress = (now - record.move_start_at) / duration
                    end
                    if progress < 0 then
                        progress = 0
                    elseif progress > 1 then
                        progress = 1
                    end
                    y = record.move_from_y + ((record.move_to_y - record.move_from_y) * progress)
                end
                record.current_y = y
            end

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

    local active_count = self:_layout_record_count()
    if active_count <= 0 then
        self.content_background:SetVisible(false)
        return
    end

    local block_h = self:_layout_block_height(active_count)
    local base_y = self:_layout_base_y(active_count)

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
