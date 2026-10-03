-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.callbacks"
import "LUI.src.Vitals.target_effect_manager_cache"
local Vitals = _G.LUI.Features.Vitals
local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback
local class = _G.LUI.Core.class
import "Turbine.Gameplay"

---@class TargetEffectManagerEffectEntry
---@field is_refreshed boolean
---@field effect Turbine.Gameplay.Effect

---@class TargetEffectManager : Turbine.Object
---@field instance_effects Turbine.Gameplay.EffectList|nil
---@field added_event table<function>
---@field removed_event table<function>
---@field cleared_event table<function>
---@field call_in_s number|nil
---@field player Turbine.Gameplay.Actor|nil
---@field source_target Turbine.Gameplay.Actor|nil
---@field background_source_target Turbine.Gameplay.Actor|nil
---@field live_refs number
---@field live_entity Turbine.Gameplay.Actor|nil
---@field cache_kind string|nil
---@field cache_name string|nil
---@field cache_entry table|nil
---@field effects table<number, TargetEffectManagerEffectEntry>
local TargetEffectManager = class(Turbine.Object)
Vitals.TargetEffectManager = TargetEffectManager

---@return Turbine.Gameplay.EffectList|nil
local function _get_target_effects(player, source_target)
    if source_target ~= nil then
        if source_target.GetEffects == nil then
            return nil
        end

        return source_target:GetEffects()
    end

    if player == nil or player.GetTarget == nil then
        return nil
    end

    local target = player:GetTarget()
    if target == nil or target.GetEffects == nil then
        return nil
    end

    return target:GetEffects()
end

function TargetEffectManager.acquire(player, target)
    return Vitals.TargetEffectManagerCache.acquire(player, target, nil)
end

function TargetEffectManager.acquire_silent(player, target)
    return Vitals.TargetEffectManagerCache.acquire(player, target, target)
end


---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

---@param player Turbine.Gameplay.Actor
---@param source_target Turbine.Gameplay.Actor|nil
function TargetEffectManager:Constructor(player, source_target)
    Turbine.Object.Constructor(self)
    self.effects = {}
    self.player = player
    self.source_target = source_target
    self.background_source_target = source_target
    self.ref_count = 1
    -- Live handles (source nil, following player:GetTarget()) and the entity
    -- the live effect list was fetched for. Maintained by the cache.
    self.live_refs = 0
    self.live_entity = nil
    self.cache_kind = nil
    self.cache_name = nil
    self.cache_entry = nil

    self.call_in_s = nil

    -- /!\ IMPORTANT /!\
    -- DO NOT COPY THE INSTANCE OF THAT VARIABLE IN ANOTHER PLACE
    -- THAT WILL BREAK THE WHOLE MANAGER
    self.instance_effects = _get_target_effects(self.player, self.source_target)

    self.added_event = {}
    self.removed_event = {}
    self.cleared_event = {}

    self:attach_callbacks()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

-- Function to be called before deleting the TargetEffectManager instance
-- It MUST be called for safety reasons
function TargetEffectManager:delete()
    local count = self.ref_count
    if count > 1 then
        self.ref_count = count - 1
        return
    end

    self.ref_count = 0
    Vitals.TargetEffectManagerCache.release(self)

    self.effects = nil
    self.added_event = {}
    self.removed_event = {}
    self.cleared_event = {}
    self:detach_callbacks()
    self.instance_effects = nil
    self.player = nil
    self.source_target = nil
    self.background_source_target = nil
    self.live_entity = nil
end

-- Release a handle taken with TargetEffectManager.acquire (live). When the
-- last live handle goes while silent holders remain, the manager returns to
-- its background source.
function TargetEffectManager:release_live()
    self.live_refs = self.live_refs - 1
    if self.live_refs == 0 then
        self.live_entity = nil
        if self.ref_count > 1 then
            self:restore_background_source_target()
        end
    end
    self:delete()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

---@param callback function|nil
function TargetEffectManager:register_added_event(callback)
    if callback == nil then
        return
    end

    table.insert(self.added_event, callback)

    if self.instance_effects == nil then
        return
    end

    for i = 1, self.instance_effects:GetCount() do
        local effect = self.instance_effects:Get(i)
        self.effects[effect:GetID()] = { is_refreshed = true, effect = effect }
    end
    for _, e in pairs(self.effects) do
        if callback ~= nil then
            callback(e.effect)
        end
    end

    return callback
end

function TargetEffectManager:register_removed_event(callback)
    if callback == nil then
        return
    end

    table.insert(self.removed_event, callback)

    return callback
end

function TargetEffectManager:register_cleared_event(callback)
    if callback == nil then
        return
    end

    table.insert(self.cleared_event, callback)

    return callback
end

function TargetEffectManager:unregister_added_event(callback)
    if callback == nil then
        return
    end

    for i = 1, #self.added_event do
        if self.added_event[i] == callback then
            table.remove(self.added_event, i)
            return
        end
    end
end

function TargetEffectManager:unregister_removed_event(callback)
    if callback == nil then
        return
    end

    for i = 1, #self.removed_event do
        if self.removed_event[i] == callback then
            table.remove(self.removed_event, i)
            return
        end
    end
end

function TargetEffectManager:unregister_cleared_event(callback)
    if callback == nil then
        return
    end

    for i = 1, #self.cleared_event do
        if self.cleared_event[i] == callback then
            table.remove(self.cleared_event, i)
            return
        end
    end
end

function TargetEffectManager:set_source_target(source_target)
    if self.source_target == source_target then
        return
    end

    self:detach_callbacks()
    self.source_target = source_target
    self.instance_effects = _get_target_effects(self.player, self.source_target)
    self:attach_callbacks()
end

-- Return a shared group manager to its background source after target vitals releases it.
function TargetEffectManager:restore_background_source_target()
    if self.background_source_target ~= nil then
        self:set_source_target(self.background_source_target)
    end
end

-- Point a shared live manager at the player's CURRENT target. Used when the
-- selected target changed to another entity that resolves to this manager
-- (identity-identical mobs): the held effect list belongs to the previous
-- entity. Refetch it and reconcile the tracked effects against the new list,
-- telling every handler what left and what is there.
function TargetEffectManager:retarget_live(target)
    self.live_entity = target

    self:detach_callbacks()
    self.instance_effects = _get_target_effects(self.player, nil)
    self:attach_callbacks()

    local present = {}
    local list = self.instance_effects
    if list ~= nil then
        for i = 1, list:GetCount() do
            local effect = list:Get(i)
            if effect ~= nil then
                present[effect:GetID()] = effect
            end
        end
    end

    local gone = {}
    for id, _ in pairs(self.effects) do
        if present[id] == nil then
            gone[#gone + 1] = id
        end
    end
    for i = 1, #gone do
        local entry = self.effects[gone[i]]
        self.effects[gone[i]] = nil
        for j = 1, #self.removed_event do
            self.removed_event[j](entry.effect)
        end
    end

    for id, effect in pairs(present) do
        self.effects[id] = { is_refreshed = true, effect = effect }
        for j = 1, #self.added_event do
            self.added_event[j](effect)
        end
    end
end

function TargetEffectManager:attach_callbacks()
    if self.instance_effects == nil then
        return
    end

    self.add_event = add_callback(self.instance_effects, "EffectAdded", function(sender, args)
        self:effect_added(sender, args)
    end)

    self.rm_event = add_callback(self.instance_effects, "EffectRemoved", function(sender, args)
        self:effect_removed(sender, args)
    end)

    self.clear_event = add_callback(self.instance_effects, "EffectsCleared", function(sender, args)
        self:effect_cleared(sender, args)
    end)
end

function TargetEffectManager:detach_callbacks()
    if self.instance_effects == nil then
        return
    end
    remove_callback(self.instance_effects, "EffectAdded", self.add_event)
    remove_callback(self.instance_effects, "EffectRemoved", self.rm_event)
    remove_callback(self.instance_effects, "EffectsCleared", self.clear_event)
    self.add_event = nil
    self.rm_event = nil
    self.clear_event = nil
end

---@param sender Turbine.Gameplay.EffectList
---@param args table
function TargetEffectManager:effect_added(sender, args)
    local effect = sender:Get(args.Index)

    local id = effect:GetID()
    if self.effects[id] ~= nil then
        self.effects[id].is_refreshed = true
        self.effects[id].effect = effect
    else
        self.effects[id] = { is_refreshed = true, effect = effect }
    end

    for i = 1, #self.added_event do
        self.added_event[i](effect)
    end

    self.call_in_s = Turbine.Engine.GetGameTime() + 0.001 -- call in 1ms
end

---@param sender Turbine.Gameplay.EffectList
---@param args table
function TargetEffectManager:effect_removed(sender, args)
    local count = 0
    for id, _ in pairs(self.effects) do
        count = count + 1
        self.effects[id].is_refreshed = false
    end

    -- If it is the last event in the list, the event is usually right for that
    -- as it removes more than it adds. Worst case the event is added back.
    if count == 1 then
        local _, effect = next(self.effects)
        if effect ~= nil then
            for i = 1, #self.removed_event do
                self.removed_event[i](effect.effect)
            end
        end
        self.effects = {}
    end

    -- Cleanup and get fresh effects instance
    self:detach_callbacks()
    self.instance_effects = _get_target_effects(self.player, self.source_target)
    self:attach_callbacks()
end

---@param sender Turbine.Gameplay.EffectList
---@param args table
function TargetEffectManager:effect_cleared(sender, args)
    -- Keep it for safety
    for id, _ in pairs(self.effects) do
        self.effects[id].is_refreshed = false
    end
    for i = 1, #self.cleared_event do
        self.cleared_event[i]()
    end
    self:detach_callbacks()
    self.instance_effects = _get_target_effects(self.player, self.source_target)
    self:attach_callbacks()
    self.call_in_s = Turbine.Engine.GetGameTime() + 0.001 -- call in 1ms
end

function TargetEffectManager:refresh()
    local to_remove = {}
    for id, event in pairs(self.effects) do
        if event.is_refreshed == false then
            table.insert(to_remove, id)
        end
    end

    for i = 1, #to_remove do
        local id = to_remove[i]
        local effect = self.effects[id]
        if effect ~= nil then
            effect.is_refreshed = true
            for j = 1, #self.removed_event do
                self.removed_event[j](effect.effect)
            end
            self.effects[id] = nil
        end
    end
end

-- Call in a loop the faster the loop the quicker the remove events will trigger
-- If no refresh is scheduled then this function does nothing.
function TargetEffectManager:poll()
    -- Bucket freshly-summoned pets once their name resolves (pet cache maintenance).
    Vitals.TargetEffectManagerCache.sweep(Turbine.Engine.GetGameTime())

    if self.instance_effects == nil then
        self.instance_effects = _get_target_effects(self.player, self.source_target)
        if self.instance_effects ~= nil then
            self:attach_callbacks()
            if #self.added_event > 0 then
                for i = 1, self.instance_effects:GetCount() do
                    local effect = self.instance_effects:Get(i)
                    if effect ~= nil then
                        self.effects[effect:GetID()] = { is_refreshed = true, effect = effect }
                        for j = 1, #self.added_event do
                            self.added_event[j](effect)
                        end
                    end
                end
            end
        end
    end

    if self.call_in_s and Turbine.Engine.GetGameTime() >= self.call_in_s then
        self.call_in_s = nil
        self:refresh()
    end
end
