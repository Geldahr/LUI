import "LUI.src.Utils.callbacks"
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
---@field cache_kind string|nil
---@field cache_name string|nil
---@field cache_entry table|nil
---@field effects table<number, TargetEffectManagerEffectEntry>
local TargetEffectManager = class(Turbine.Object)
Vitals.TargetEffectManager = TargetEffectManager

local PLAYER_CACHE_KIND = "player"
local OTHER_CACHE_KIND = "other"
local _player_manager_cache = setmetatable({}, { __mode = "v" })
local _other_manager_cache = {}
local OTHER_IDENTITY_METHODS = {
    "GetLevel",
    -- "GetMorale",
    "GetMaxMorale",
    -- "GetPower",
    "GetMaxPower",
    "GetBaseMaxMorale",
    "GetBaseMaxPower",
}

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

local function _add_other_entry(entry, name)
    local bucket = _other_manager_cache[name]
    if bucket == nil then
        bucket = {}
        _other_manager_cache[name] = bucket
    end

    entry.name = name
    bucket[#bucket + 1] = entry
end

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

local function _reuse_manager(cached, source_target)
    cached.ref_count = cached.ref_count + 1
    -- Group and companion vitals pass a stable source for background tracking.
    -- Target vitals passes nil to use player:GetTarget() while selected.
    if source_target ~= nil then
        cached.background_source_target = source_target
    end
    if cached.source_target ~= nil or source_target == nil then
        cached:set_source_target(source_target)
    end

    return cached
end

local function _new_manager(player, source_target)
    return TargetEffectManager(player, source_target)
end

local function _acquire_player_manager(player, target, source_target, name)
    local cached = _player_manager_cache[name]
    if cached ~= nil then
        return _reuse_manager(cached, source_target)
    end

    local manager = _new_manager(player, source_target)
    manager.cache_kind = PLAYER_CACHE_KIND
    manager.cache_name = name
    _player_manager_cache[name] = manager
    return manager
end

local function _acquire_other_manager(player, target, source_target, name)
    local entry = _find_other_entry(name, target)
    if entry ~= nil then
        return _reuse_manager(entry.manager, source_target)
    end

    local manager = _new_manager(player, source_target)
    entry = {
        manager = manager,
        identity_entity = target,
        name = nil,
        name_changed_event = nil,
    }
    manager.cache_kind = OTHER_CACHE_KIND
    manager.cache_entry = entry
    _add_other_entry(entry, name)
    _attach_other_entry_name_changed(entry)
    return manager
end

local function _acquire_manager(player, target, source_target)
    local name = _entity_name(target)
    if name == nil then
        return _new_manager(player, source_target)
    end

    if _entity_is_player(target) == true then
        return _acquire_player_manager(player, target, source_target, name)
    end

    return _acquire_other_manager(player, target, source_target, name)
end

local function _delete_from_cache(manager)
    if manager.cache_kind == PLAYER_CACHE_KIND then
        if _player_manager_cache[manager.cache_name] == manager then
            _player_manager_cache[manager.cache_name] = nil
        end
    elseif manager.cache_kind == OTHER_CACHE_KIND then
        _detach_other_entry_name_changed(manager.cache_entry)
        _remove_other_entry(manager.cache_entry)
        manager.cache_entry.manager = nil
    elseif manager.cache_kind ~= nil then
        error("Unknown target effect manager cache kind: " .. tostring(manager.cache_kind))
    end

    manager.cache_kind = nil
    manager.cache_name = nil
    manager.cache_entry = nil
end

function TargetEffectManager.acquire(player, target)
    return _acquire_manager(player, target, nil)
end

function TargetEffectManager.acquire_silent(player, target)
    return _acquire_manager(player, target, target)
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
    _delete_from_cache(self)

    self.effects = nil
    self.added_event = {}
    self.removed_event = {}
    self.cleared_event = {}
    self:detach_callbacks()
    self.instance_effects = nil
    self.player = nil
    self.source_target = nil
    self.background_source_target = nil
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
