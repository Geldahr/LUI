-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Manager cache for TargetEffectManager. This holds the shared player/other (pet)
-- manager caches and the acquire/release/sweep entry points. The manager itself
-- (target_effect_manager.lua) owns effect-tracking behavior; this file owns only
-- how those managers are shared and identified.

import "LUI.src.Utils.callbacks"
local Vitals = _G.LUI.Features.Vitals
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
import "Turbine.Gameplay"

local TargetEffectManagerCache = {}
Vitals.TargetEffectManagerCache = TargetEffectManagerCache

local PLAYER_CACHE_KIND = "player"
local OTHER_CACHE_KIND = "other"
local _player_manager_cache = setmetatable({}, { __mode = "v" })
local _other_manager_cache = {}
-- OTHER entries whose entity has no name yet (e.g. a pet during the seconds-long window
-- between summon and its name resolving). Each record is { entry, time }. sweep()
-- buckets them once named and drops any that never get a name within the timeout.
local _pending_other_entries = {}
local PENDING_OTHER_TIMEOUT_S = 5
local OTHER_IDENTITY_METHODS = {
    "GetLevel",
    -- "GetMorale",
    "GetMaxMorale",
    -- "GetPower",
    "GetMaxPower",
    "GetBaseMaxMorale",
    "GetBaseMaxPower",
}

local function _entity_name(entity)
    if entity == nil or entity.GetName == nil then
        return nil
    end

    local name = entity:GetName()
    if name == nil or name == "" then
        return nil
    end

    return name
end

local function _external_entity_value(entity, method_name)
    if entity == nil then
        return nil, false
    end

    local method = entity[method_name]
    if method == nil then
        return nil, false
    end

    return method(entity), true
end

local function _entity_is_player(entity)
    if entity == nil then
        return false
    end

    if entity.IsLinkDead ~= nil then
        return true
    end

    return entity.GetClass ~= nil
end

local function _other_entities_match(left, right)
    if _entity_name(left) ~= _entity_name(right) then
        return false
    end

    for i = 1, #OTHER_IDENTITY_METHODS do
        local method_name = OTHER_IDENTITY_METHODS[i]
        local left_value, left_available = _external_entity_value(left, method_name)
        local right_value, right_available = _external_entity_value(right, method_name)

        if left_available ~= right_available then
            return false
        end
        if left_available == true and left_value ~= right_value then
            return false
        end
    end

    return true
end

local function _add_pending_other_entry(entry)
    _pending_other_entries[#_pending_other_entries + 1] = { entry = entry, time = Turbine.Engine.GetGameTime() }
end

local function _remove_pending_other_entry(entry)
    for i = #_pending_other_entries, 1, -1 do
        if _pending_other_entries[i].entry == entry then
            table.remove(_pending_other_entries, i)
            break
        end
    end
end

local function _remove_other_entry(entry)
    if entry.name == nil then
        return
    end

    local bucket = _other_manager_cache[entry.name]

    for i = #bucket, 1, -1 do
        if bucket[i] == entry then
            table.remove(bucket, i)
            break
        end
    end

    if #bucket == 0 then
        _other_manager_cache[entry.name] = nil
    end
end

-- Files the entry into the cache bucket for `name`. This is the single place an entry
-- becomes findable by _find_other_entry; an entry with a nil name lives outside any bucket.
local function _add_other_entry(entry, name)
    -- Getting a name means it is no longer pending; drop it from the unbucketed list
    -- (no-op if it was created already-named).
    _remove_pending_other_entry(entry)

    local bucket = _other_manager_cache[name]
    if bucket == nil then
        bucket = {}
        _other_manager_cache[name] = bucket
    end

    entry.name = name
    bucket[#bucket + 1] = entry
end

-- Runs whenever the tracked entity's name changes. Re-files the entry under its current
-- name. The key case here is a freshly-summoned pet: it was acquired nameless (unbucketed),
-- so when its name first resolves (nil -> "Goose") this adds it to the cache, making it
-- shareable with target vitals.
local function _move_other_entry(entry)
    local old_name = entry.name
    local new_name = _entity_name(entry.identity_entity)
    if old_name == new_name then
        return
    end

    _remove_other_entry(entry)
    if new_name ~= nil then
        _add_other_entry(entry, new_name)
    else
        entry.name = nil
    end
end

-- Wires the entity's NameChanged event to _move_other_entry, so the entry is (re)bucketed
-- the moment a name appears or changes.
local function _attach_other_entry_name_changed(entry)
    entry.name_changed_event = add_callback(entry.identity_entity, "NameChanged", function()
        _move_other_entry(entry)
    end)
end

local function _detach_other_entry_name_changed(entry)
    if entry.name_changed_event == nil then
        error("Missing target effect manager NameChanged callback token")
    end

    remove_callback(entry.identity_entity, "NameChanged", entry.name_changed_event)
    entry.name_changed_event = nil
end

-- Live handles (source_target == nil, reading player:GetTarget()) share one manager per
-- target: target vitals, boss vitals, target expiring effects and upkeep are handlers on
-- the same instance. A second manager on the same entity would hold a second effect list
-- on it.
--
-- The game returns a new entity object on every player:GetTarget() call, so an acquire
-- cannot tell "same target again" from "another mob with the same identity". Acquire
-- therefore always shares, and the one case where the shared manager is stale -- the
-- selection moved to an identity-identical mob while another handler still holds it --
-- is handled when the player's TargetChanged fires (_on_target_changed).

local function _find_other_entry(name, target)
    local bucket = _other_manager_cache[name]
    if bucket == nil then
        return nil
    end

    for i = 1, #bucket do
        local entry = bucket[i]
        if _other_entities_match(entry.identity_entity, target) == true then
            return entry
        end
    end

    return nil
end

-- Live managers, to re-point on TargetChanged. Weak keys: a released manager drops out.
local _live_managers = setmetatable({}, { __mode = "k" })
local _target_changed_hooked = false

-- Runs on the player's TargetChanged, before or after the consumers' own handlers (the
-- order does not matter: consumers only release and re-acquire). A live manager that the
-- NEW target resolves to is about to be shared again by the re-acquiring consumers, but
-- it still tracks the previous entity: re-point it. Managers with a background source
-- (group member, pet) track that one entity and are left alone, as are managers the new
-- target does not resolve to (their handlers are releasing them).
local function _on_target_changed(player)
    local target = player:GetTarget()
    local name = _entity_name(target)

    for manager in pairs(_live_managers) do
        if manager.live_refs == 0 or manager.source_target ~= nil then
            _live_managers[manager] = nil
        elseif name ~= nil
            and manager.cache_kind == OTHER_CACHE_KIND
            and manager.background_source_target == nil then
            local entry = manager.cache_entry
            if entry.name == name and _other_entities_match(entry.identity_entity, target) == true then
                -- keep the identity (and its NameChanged hook) on the entity now tracked
                _detach_other_entry_name_changed(entry)
                entry.identity_entity = target
                _attach_other_entry_name_changed(entry)
                manager:retarget_live()
            end
        end
    end
end

local function _track_live(player, manager)
    _live_managers[manager] = true
    if _target_changed_hooked ~= true then
        _target_changed_hooked = true
        add_callback(player, "TargetChanged", function()
            _on_target_changed(player)
        end)
    end
end

local function _reuse_manager(player, cached, source_target)
    cached.ref_count = cached.ref_count + 1
    -- Group and companion vitals pass a stable source for background tracking.
    if source_target ~= nil then
        cached.background_source_target = source_target
        cached:set_source_target(source_target)
        return cached
    end

    -- Live handle: follows player:GetTarget() while selected. A manager that is already
    -- live is shared as it is; its tracked effects stay.
    cached.live_refs = cached.live_refs + 1
    cached:set_source_target(nil)
    _track_live(player, cached)

    return cached
end

local function _new_manager(player, source_target)
    local manager = Vitals.TargetEffectManager(player, source_target)
    if source_target == nil then
        manager.live_refs = 1
        _track_live(player, manager)
    end
    return manager
end

local function _new_player_manager(player, source_target, name)
    local manager = _new_manager(player, source_target)
    manager.cache_kind = PLAYER_CACHE_KIND
    manager.cache_name = name
    _player_manager_cache[name] = manager
    return manager
end

local function _new_other_manager(player, target, source_target)
    local manager = _new_manager(player, source_target)
    local entry = {
        manager = manager,
        identity_entity = target,
        name = nil,
        name_changed_event = nil,
    }
    manager.cache_kind = OTHER_CACHE_KIND
    manager.cache_entry = entry
    -- A freshly-summoned pet has no name yet. Track it in the floating list and bucket it
    -- (via sweep() or the NameChanged hook) once its name resolves; if it never does, sweep()
    -- drops it after the timeout. _move_other_entry buckets immediately if the name is
    -- already available.
    _add_pending_other_entry(entry)
    _attach_other_entry_name_changed(entry)
    _move_other_entry(entry)
    return manager
end

-- Acquire (creating or sharing) a manager for `target`. `source_target` is nil for a live
-- selected target and the entity itself for background (silent) tracking. A live handle
-- must be given back with manager:release_live(), a silent one with manager:delete().
--
-- Lookup is by NAME across both caches, matching v1.1.0 semantics: the entity object used
-- to probe does not decide whether a cached manager is found. This matters because the
-- entity for a selected target (player:GetTarget()) does not expose the same methods as the
-- fellowship roster entity for the same character; classifying the probe would send it to
-- the wrong cache and build a cold manager instead of reusing the warm shared one.
-- Classification only decides where a NEW manager is filed (players by name; pets/mobs in
-- the identity-matched cache).
function TargetEffectManagerCache.acquire(player, target, source_target)
    local name = _entity_name(target)

    if name ~= nil then
        local cached = _player_manager_cache[name]
        if cached ~= nil then
            return _reuse_manager(player, cached, source_target)
        end

        local entry = _find_other_entry(name, target)
        if entry ~= nil then
            return _reuse_manager(player, entry.manager, source_target)
        end

        if _entity_is_player(target) == true then
            return _new_player_manager(player, source_target, name)
        end
    end

    -- name may be nil here (e.g. freshly-summoned pet); the OTHER cache attaches a
    -- NameChanged hook so the entry is bucketed and shareable once it is named.
    return _new_other_manager(player, target, source_target)
end

-- Drop `manager` from whichever cache holds it. Called from TargetEffectManager:delete()
-- when the last reference is released.
function TargetEffectManagerCache.release(manager)
    if manager.cache_kind == PLAYER_CACHE_KIND then
        if _player_manager_cache[manager.cache_name] == manager then
            _player_manager_cache[manager.cache_name] = nil
        end
    elseif manager.cache_kind == OTHER_CACHE_KIND then
        _detach_other_entry_name_changed(manager.cache_entry)
        _remove_pending_other_entry(manager.cache_entry)
        _remove_other_entry(manager.cache_entry)
        manager.cache_entry.manager = nil
    elseif manager.cache_kind ~= nil then
        error("Unknown target effect manager cache kind: " .. tostring(manager.cache_kind))
    end

    manager.cache_kind = nil
    manager.cache_name = nil
    manager.cache_entry = nil
end

-- Walk the floating (still-nameless) entries: bucket any whose name has resolved, and drop
-- any that never got a name within the timeout so the list cannot grow with dead entries.
-- Driven from TargetEffectManager:poll().
function TargetEffectManagerCache.sweep(now)
    for i = #_pending_other_entries, 1, -1 do
        local record = _pending_other_entries[i]
        if _entity_name(record.entry.identity_entity) ~= nil then
            _move_other_entry(record.entry)
        elseif now - record.time > PENDING_OTHER_TIMEOUT_S then
            table.remove(_pending_other_entries, i)
        end
    end
end
