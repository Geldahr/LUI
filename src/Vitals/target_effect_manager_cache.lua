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
-- selection moved to an identity-identical entity while handlers still hold it -- is
-- handled when the player's TargetChanged fires (_on_target_changed).
--
-- Cache-maintained fields on a manager: live_refs (live handles), live_fetched_at (game
-- time its list was last fetched from the selection), live_acquired_at (game time of its
-- last live acquire) and live_stale (still on the previous selection, re-pointed by the
-- next live acquire).

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

-- The cached manager `target` resolves to, or nil.
local function _find_manager(target)
    local name = _entity_name(target)
    if name == nil then
        return nil
    end

    local cached = _player_manager_cache[name]
    if cached ~= nil then
        return cached
    end

    local entry = _find_other_entry(name, target)
    if entry ~= nil then
        return entry.manager
    end

    return nil
end

-- The selection moved to another entity that resolves to this live manager. A live-only
-- manager drops what it tracked and follows the new entity. A manager with a background
-- source (pet, group member) goes back to that entity, then follows the selection again,
-- as a full release and re-acquire would: its silent handlers keep their effects.
local function _repoint_live(manager, target, now)
    if manager.background_source_target == nil then
        if manager.cache_kind == OTHER_CACHE_KIND then
            -- keep the identity (and its NameChanged hook) on the entity now tracked
            local entry = manager.cache_entry
            _detach_other_entry_name_changed(entry)
            entry.identity_entity = target
            _attach_other_entry_name_changed(entry)
        end
        manager:retarget_live()
    else
        manager:set_source_target(manager.background_source_target)
        manager:set_source_target(nil)
    end
    manager.live_fetched_at = now
    manager.live_stale = false
end

local _target_changed_hooked = false

-- Runs on the player's TargetChanged, where every live handler also releases and
-- re-acquires. Only the manager the new target resolves to matters: the handlers end up
-- sharing it, and it is still on the previous entity. This handler goes first, so it marks
-- the manager and the first re-acquire re-points it (none happens if the handlers all
-- release it). Should handlers run before it anyway: a list they fetched this frame is
-- already the new selection's, and a manager they re-acquired this frame is re-pointed here.
local function _on_target_changed(player)
    local target = player:GetTarget()
    local manager = _find_manager(target)
    if manager == nil or manager.live_refs == 0 then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if manager.live_fetched_at == now then
        return
    end

    if manager.live_acquired_at == now then
        _repoint_live(manager, target, now)
    else
        manager.live_stale = true
    end
end

local function _hook_target_changed(player)
    if _target_changed_hooked == true then
        return
    end
    _target_changed_hooked = true
    local handler = add_callback(player, "TargetChanged", function()
        _on_target_changed(player)
    end)
    -- ahead of the handlers that release and re-acquire (add_callback appends)
    local handlers = player.TargetChanged
    table.remove(handlers)
    table.insert(handlers, 1, handler)
end

local function _reuse_manager(player, cached, target, source_target)
    cached.ref_count = cached.ref_count + 1
    -- Group and companion vitals pass a stable source for background tracking.
    if source_target ~= nil then
        cached.background_source_target = source_target
        cached:set_source_target(source_target)
        return cached
    end

    -- Live handle: follows player:GetTarget() while selected. A manager that is already
    -- live is shared as it is; its tracked effects stay.
    local now = Turbine.Engine.GetGameTime()
    if cached.source_target ~= nil then
        -- reading a background entity's list (no live handle yet, or a silent acquire
        -- since): switch to the selection's
        cached:set_source_target(nil)
        cached.live_fetched_at = now
        cached.live_stale = false
    elseif cached.live_stale == true then
        _repoint_live(cached, target, now)
    end
    cached.live_refs = cached.live_refs + 1
    cached.live_acquired_at = now
    _hook_target_changed(player)

    return cached
end

local function _new_manager(player, source_target)
    local manager = Vitals.TargetEffectManager(player, source_target)
    if source_target == nil then
        local now = Turbine.Engine.GetGameTime()
        manager.live_refs = 1
        manager.live_fetched_at = now
        manager.live_acquired_at = now
        _hook_target_changed(player)
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
    local cached = _find_manager(target)
    if cached ~= nil then
        return _reuse_manager(player, cached, target, source_target)
    end

    local name = _entity_name(target)
    if name ~= nil and _entity_is_player(target) == true then
        return _new_player_manager(player, source_target, name)
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

local _swept_at = nil

-- Walk the floating (still-nameless) entries: bucket any whose name has resolved, and drop
-- any that never got a name within the timeout so the list cannot grow with dead entries.
-- Driven from TargetEffectManager:poll(), which every manager runs: once per frame is enough.
function TargetEffectManagerCache.sweep(now)
    if now == _swept_at then
        return
    end
    _swept_at = now

    for i = #_pending_other_entries, 1, -1 do
        local record = _pending_other_entries[i]
        if _entity_name(record.entry.identity_entity) ~= nil then
            _move_other_entry(record.entry)
        elseif now - record.time > PENDING_OTHER_TIMEOUT_S then
            table.remove(_pending_other_entries, i)
        end
    end
end

-- The managers are for entities other than the player: with yourself selected, the
-- player's own effect list is read instead.
function TargetEffectManagerCache.is_local_player(player, entity)
    if entity.GetName == nil or player.GetName == nil then
        return false
    end
    return entity:GetName() == player:GetName()
end

-- A live handle for a window that reads the selected target's effects from the manager's
-- map instead of through callbacks (Target Expiring Effects, Upkeep). Registering the no-op
-- added callback snapshots the target's current effects into the map. Returns the handle,
-- or nil when nothing with effects is selected; the second value is true when the player
-- selected themselves. Give it back with release_selected.
function TargetEffectManagerCache.hold_selected(player)
    if player == nil or player.GetTarget == nil then
        return nil, false
    end
    local target = player:GetTarget()
    -- capability probe only: the manager is the sole reader of the target's list
    if target == nil or target.GetEffects == nil then
        return nil, false
    end
    if TargetEffectManagerCache.is_local_player(player, target) == true then
        return nil, true
    end

    local manager = TargetEffectManagerCache.acquire(player, target, nil)
    local added = function() end
    manager:register_added_event(added)
    return { manager = manager, added = added }, false
end

function TargetEffectManagerCache.release_selected(hold)
    hold.manager:unregister_added_event(hold.added)
    hold.manager:release_live()
end
