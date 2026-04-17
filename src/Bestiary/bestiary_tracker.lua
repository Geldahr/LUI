import "Turbine.Gameplay"

import "LUI.src.Utils.callbacks"
import "LUI.src.Utils.coords"

Bestiary = Bestiary or {}
Bestiary.Collector = class()
Bestiary.current_location = Bestiary.current_location or nil

local DATA_ACCESS = Bestiary.DataAccess
-- Loot messages often arrive after the kill line and XP line, so keep a short
-- post-kill attribution window here. Adjust if the client/chat timing shifts.
local LOOT_POST_KILL_WINDOW_SECONDS = 0.10

local function _is_english_client()
    if is_lui_english_language ~= nil then
        return is_lui_english_language() == true
    end

    local lang = Turbine.Engine.GetLanguage()
    local language_enum = Turbine.Language
    if type(lang) == "number" then
        return lang == language_enum.English or lang == language_enum.EnglishGB
    end
    if type(lang) == "string" then
        local code = lang:lower():gsub("_", "-")
        return code == "en" or code:find("^en%-") == 1
    end

    return true
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

local function _is_bestiary_open()
    local window = _G.BESTIARY_WINDOW
    return window ~= nil
        and window.IsVisible ~= nil
        and window:IsVisible() == true
end

local function _quote_filter_term(term)
    if type(term) ~= "string" or term == "" then
        return nil
    end

    return "\"" .. term:gsub("\"", "") .. "\""
end

local function _build_location_filter_query(location)
    if type(location) ~= "table" then
        return ""
    end

    local terms = {}
    local quoted_region = _quote_filter_term(location.region)
    local quoted_area = _quote_filter_term(location.area)

    if quoted_region ~= nil then
        terms[#terms + 1] = quoted_region
    end
    if quoted_area ~= nil and location.area ~= location.region then
        terms[#terms + 1] = quoted_area
    end

    return table.concat(terms, " ")
end

function Bestiary.get_current_location()
    return Bestiary.current_location
end

function Bestiary.set_current_location(location)
    if type(location) ~= "table" then
        return
    end

    local region = _trim(location.region)
    if region == nil then
        return
    end

    local area = _trim(location.area)
    if area == region then
        area = nil
    end

    local current_location = {
        region = region,
        area = area,
        player_coords = location.player_coords,
        region_id = location.region_id,
    }
    local query = _build_location_filter_query(current_location)
    if query == "" then
        return
    end

    Bestiary.current_location = current_location
    _G.bestiary_area_filter_query = query

    local window = _G.BESTIARY_WINDOW
    if window ~= nil and window.on_location_resolved ~= nil then
        window:on_location_resolved()
    end
end

local function _apply_location_filter(location)
    Bestiary.set_current_location(location)
end

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end

    return value
end

local function _normalize_bestiary_name(name)
    if DATA_ACCESS ~= nil and DATA_ACCESS.normalize_name ~= nil then
        return DATA_ACCESS.normalize_name(name)
    end

    return _trim(name)
end

local function _ensure_bestiary_cache()
    if DATA_ACCESS ~= nil and DATA_ACCESS.ensure_cache ~= nil then
        return DATA_ACCESS.ensure_cache()
    end

    if ensure_bestiary_cache ~= nil then
        return ensure_bestiary_cache()
    end

    if type(_G.bestiary_cache) ~= "table" then
        _G.bestiary_cache = {}
    end

    return _G.bestiary_cache
end

local function _touch_generation()
    _G.bestiary_cache_generation = (_G.bestiary_cache_generation or 0) + 1
    _G.bestiary_cache_dirty = true
end

local function _ensure_entry(name)
    name = _normalize_bestiary_name(name) or name
    if DATA_ACCESS ~= nil and DATA_ACCESS.resolve_builtin_name ~= nil then
        name = DATA_ACCESS.resolve_builtin_name(name) or name
    end
    local cache = _ensure_bestiary_cache()
    if type(cache[name]) ~= "table" then
        cache[name] = {
            levels = {},
            k = 0,
            d = {},
        }
    end

    local entry = cache[name]
    if type(entry.levels) ~= "table" then
        entry.levels = {}
    end
    if type(entry.d) ~= "table" then
        entry.d = {}
    end
    entry.k = _to_number(entry.k, 0)
    entry.lmin = nil
    entry.lmax = nil

    return entry
end

local function _strip_timestamp(message)
    if type(message) ~= "string" then
        return ""
    end

    return message:gsub("^%[%d%d/%d%d .-%]%s*", "")
end

local function _normalize_kill_name(name)
    return _normalize_bestiary_name(name)
end

local function _parse_kill_name(message)
    if type(message) ~= "string" or string.find(message, " defeated ", 1, true) == nil then
        return nil
    end

    local victim = message:match("^.- defeated the (.+)%.?$")
    if victim == nil then
        victim = message:match("^.- defeated (.+)%.?$")
    end

    return _normalize_kill_name(victim)
end

local function _parse_drop_name(message)
    local bracketed = nil
    if string.find(message, "You have acquired:", 1, true) == 1 then
        bracketed = message:match("%b[]")
    elseif string.find(message, "Gathered ", 1, true) == 1
        and string.find(message, " into the ", 1, true) ~= nil then
        bracketed = message:match("%b[]")
    end

    if bracketed == nil then
        return nil
    end

    return _trim(string.sub(bracketed, 2, -2))
end

function Bestiary.Collector:Constructor()
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.player_name = nil
    self.enabled = false
    self._cb_target = nil
    self._cb_chat = nil
    self._tracked_target = nil
    self._tracked_target_attrs = nil
    self._cb_target_morale = nil
    self._cb_target_max_morale = nil
    self._cb_target_power = nil
    self._cb_target_max_power = nil
    self._cb_target_wrath = nil
    self._pending_kills = {}

    if self.player ~= nil and self.player.GetName ~= nil then
        self.player_name = self.player:GetName()
    end
end

function Bestiary.Collector:is_enabled()
    local settings = _G.settings
    if type(settings) ~= "table" or type(settings.global) ~= "table" then
        return false
    end

    return settings.global.bestiary_capture == true and _is_english_client() == true
end

function Bestiary.Collector:apply_settings()
    local should_enable = self:is_enabled()
    self.enabled = should_enable

    self:_bind()

    if should_enable == true then
        self:_track_current_target()
    else
        self:_flush_pending_kills(true)
        self:_unbind_target_events()
        self:_unbind_player_events()
    end
end

function Bestiary.Collector:save()
    self:_flush_pending_kills(true)
    if save_bestiary_cache ~= nil then
        save_bestiary_cache()
    end
end

function Bestiary.Collector:flush_expired()
    self:_flush_pending_kills(false)
end

function Bestiary.Collector:flush_pending()
    self:_flush_pending_kills(true)
end

function Bestiary.Collector:destroy()
    self:_flush_pending_kills(true)
    self:_unbind()
end

function Bestiary.Collector:_bind()
    if self.player == nil then
        self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if self.player ~= nil and self.player.GetName ~= nil then
            self.player_name = self.player:GetName()
        end
    end

    if self.enabled == true and self._cb_target == nil and self.player ~= nil then
        self._cb_target = add_callback(self.player, "TargetChanged", function()
            self:_on_target_changed()
        end)
    elseif self.enabled ~= true and self._cb_target ~= nil then
        self:_unbind_player_events()
    end

    if self._cb_chat == nil then
        self._cb_chat = add_callback(Turbine.Chat, "Received", function(_, args)
            self:_on_chat_received(args)
        end)
    end
end

function Bestiary.Collector:_unbind_player_events()
    if self._cb_target ~= nil and self.player ~= nil then
        remove_callback(self.player, "TargetChanged", self._cb_target)
    end
    self._cb_target = nil
end

function Bestiary.Collector:_unbind_target_events()
    if self._tracked_target ~= nil then
        if self._cb_target_morale ~= nil then
            remove_callback(self._tracked_target, "MoraleChanged", self._cb_target_morale)
            self._cb_target_morale = nil
        end
        if self._cb_target_max_morale ~= nil then
            remove_callback(self._tracked_target, "MaxMoraleChanged", self._cb_target_max_morale)
            self._cb_target_max_morale = nil
        end
        if self._cb_target_power ~= nil then
            remove_callback(self._tracked_target, "PowerChanged", self._cb_target_power)
            self._cb_target_power = nil
        end
        if self._cb_target_max_power ~= nil then
            remove_callback(self._tracked_target, "MaxPowerChanged", self._cb_target_max_power)
            self._cb_target_max_power = nil
        end
    end

    if self._tracked_target_attrs ~= nil and self._cb_target_wrath ~= nil then
        remove_callback(self._tracked_target_attrs, "WrathChanged", self._cb_target_wrath)
        self._cb_target_wrath = nil
    end

    self._tracked_target = nil
    self._tracked_target_attrs = nil
end

function Bestiary.Collector:_unbind()
    self:_unbind_target_events()
    self:_unbind_player_events()

    if self._cb_chat ~= nil then
        remove_callback(Turbine.Chat, "Received", self._cb_chat)
        self._cb_chat = nil
    end
end

function Bestiary.Collector:_track_current_target()
    if self.player == nil or self.player.GetTarget == nil then
        self:_unbind_target_events()
        return
    end

    self:_track_target(self.player:GetTarget())
end

function Bestiary.Collector:_track_target(target)
    if target == self._tracked_target then
        return
    end

    self:_unbind_target_events()

    if self.enabled ~= true or target == nil then
        return
    end
    if target.GetName == nil or target.GetLevel == nil or target.GetMaxMorale == nil then
        return
    end
    if target.IsLocalPlayer ~= nil and target:IsLocalPlayer() == true then
        return
    end

    self._tracked_target = target
    self._cb_target_morale = add_callback(target, "MoraleChanged", function()
        self:_record_target(target)
    end)
    self._cb_target_max_morale = add_callback(target, "MaxMoraleChanged", function()
        self:_record_target(target)
    end)

    if target.GetMaxPower ~= nil then
        self._cb_target_power = add_callback(target, "PowerChanged", function()
            self:_record_target(target)
        end)
        self._cb_target_max_power = add_callback(target, "MaxPowerChanged", function()
            self:_record_target(target)
        end)
    end

    if target.GetClassAttributes ~= nil then
        local attrs = target:GetClassAttributes()
        if attrs ~= nil and attrs.GetWrath ~= nil then
            self._tracked_target_attrs = attrs
            self._cb_target_wrath = add_callback(attrs, "WrathChanged", function()
                self:_record_target(target)
            end)
        end
    end
end

function Bestiary.Collector:_record_target(target)
    if self.enabled ~= true or target == nil then
        return
    end
    if target.GetName == nil or target.GetLevel == nil or target.GetMaxMorale == nil then
        return
    end
    if target.IsLocalPlayer ~= nil and target:IsLocalPlayer() == true then
        return
    end

    local name = _normalize_kill_name(target:GetName())
    local level = _to_number(target:GetLevel(), 0)
    local max_morale = _to_number(target:GetMaxMorale(), 0)
    if name == nil or level <= 0 or max_morale <= 0 then
        return
    end

    local max_power = 0
    if target.GetMaxPower ~= nil then
        max_power = _to_number(target:GetMaxPower(), 0)
    end

    local entry = _ensure_entry(name)
    local changed = false

    local level_entry = entry.levels[level]
    if type(level_entry) ~= "table" then
        entry.levels[level] = { m = max_morale, p = max_power }
        changed = true
    else
        if max_morale > _to_number(level_entry.m, 0) then
            level_entry.m = max_morale
            changed = true
        end
        if max_power > _to_number(level_entry.p, 0) then
            level_entry.p = max_power
            changed = true
        end
    end

    if changed then
        _touch_generation()
    end
end

function Bestiary.Collector:_commit_kill(record)
    if type(record) ~= "table" then
        return
    end

    local name = _normalize_bestiary_name(record.name)
    if name == nil then
        return
    end

    local entry = _ensure_entry(name)
    entry.k = _to_number(entry.k, 0) + 1

    for item_name, count in pairs(record.drops or {}) do
        if type(item_name) == "string" then
            entry.d[item_name] = _to_number(entry.d[item_name], 0) + _to_number(count, 0)
        end
    end

    _touch_generation()
end

function Bestiary.Collector:_flush_pending_kills(flush_all)
    local now = Turbine.Engine.GetGameTime()
    while #self._pending_kills > 0 do
        local record = self._pending_kills[1]
        if flush_all ~= true and record ~= nil and (now - _to_number(record.at, now)) < LOOT_POST_KILL_WINDOW_SECONDS then
            break
        end

        table.remove(self._pending_kills, 1)
        self:_commit_kill(record)
    end
end

function Bestiary.Collector:_on_target_changed()
    if self.enabled ~= true then
        return
    end

    self:_track_current_target()
end

function Bestiary.Collector:_on_chat_received(args)
    if args.ChatType ~= Turbine.ChatType.Standard and
        args.ChatType ~= Turbine.ChatType.Death and
        args.ChatType ~= Turbine.ChatType.SelfLoot then
        return
    end

    local message = _strip_timestamp(args.Message)
    if message == "" then
        return
    end

    if args.ChatType == Turbine.ChatType.Standard then
        if _is_bestiary_open() == true then
            local location = Coords.resolve_location_from_chat(message)
            if location ~= nil then
                _apply_location_filter(location)
            end
        end
    end

    if self.enabled ~= true then
        return
    end

    if args.ChatType == Turbine.ChatType.Death then
        self:_flush_pending_kills(false)
        local kill_name = _parse_kill_name(message)
        if kill_name ~= nil then
            self._pending_kills[#self._pending_kills + 1] = {
                at = Turbine.Engine.GetGameTime(),
                name = kill_name,
                drops = {},
            }
            return
        end
    end

    if args.ChatType == Turbine.ChatType.SelfLoot then
        local item_name = _parse_drop_name(message)
        if item_name ~= nil and #self._pending_kills > 0 then
            self:_flush_pending_kills(false)
            local record = self._pending_kills[#self._pending_kills]
            if type(record) == "table" then
                record.drops[item_name] = _to_number(record.drops[item_name], 0) + 1
            end
        end
    end
end
