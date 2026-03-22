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
---@field effects table<number, TargetEffectManagerEffectEntry>
TargetEffectManager = class(Turbine.Object)

local _manager_cache = setmetatable({}, { __mode = "v" })

---@return Turbine.Gameplay.EffectList|nil
local function _get_target_effects(player)
    if player == nil or player.GetTarget == nil then
        return nil
    end

    local target = player:GetTarget()
    if target == nil or target.GetEffects == nil then
        return nil
    end

    return target:GetEffects()
end

local function _target_cache_key(target)
    if target == nil then
        return nil
    end

    if target.GetID ~= nil then
        local id = target:GetID()
        if type(id) == "number" and id > 0 then
            return "id|" .. tostring(id)
        end
        if type(id) == "string" and id ~= "" then
            return "id|" .. id
        end
        local n = tonumber(id)
        if type(n) == "number" and n > 0 then
            return "id|" .. tostring(n)
        end
    end

    if target.IsPlayer ~= nil and target:IsPlayer() == true and target.GetName ~= nil then
        local name = tostring(target:GetName() or "")
        if name ~= "" then
            return "player|" .. name
        end
    end

    return tostring(target)
end

function TargetEffectManager.acquire(player, target)
    local key = _target_cache_key(target)
    if key ~= nil then
        local cached = _manager_cache[key]
        if cached ~= nil then
            cached.ref_count = (cached.ref_count or 0) + 1
            return cached
        end
    end

    local manager = TargetEffectManager(player)
    manager.cache_key = key
    manager.ref_count = 1
    if key ~= nil then
        _manager_cache[key] = manager
    end
    return manager
end


---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

---@param player Turbine.Gameplay.Actor
function TargetEffectManager:Constructor(player)
    Turbine.Object.Constructor(self)
    self.effects = {}
    self.player = player
    self.ref_count = 1
    self.cache_key = nil

    self.call_in_s = nil

    -- /!\ IMPORTANT /!\
    -- DO NOT COPY THE INSTANCE OF THAT VARIABLE IN ANOTHER PLACE
    -- THAT WILL BREAK THE WHOLE MANAGER
    self.instance_effects = _get_target_effects(self.player)

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
    if type(count) ~= "number" then
        count = 1
    end
    if count > 1 then
        self.ref_count = count - 1
        return
    end

    self.ref_count = 0
    if self.cache_key ~= nil and _manager_cache[self.cache_key] == self then
        _manager_cache[self.cache_key] = nil
    end

    self.effects = nil
    self.added_event = {}
    self.removed_event = {}
    self.cleared_event = {}
    self:detach_callbacks()
    self.instance_effects = nil
    self.player = nil
    self.cache_key = nil
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
        -- Add events to our own list and fire the event added callback
        -- Turbine.Shell.WriteLine("Added: "..effect:GetName() .. " #"..effect:GetID())
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
        -- Turbine.Shell.WriteLine("Added: "..effect:GetName() .. " #"..effect:GetID())
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
        -- Turbine.Shell.WriteLine("Last Removed: "..effect.effect:GetName() .. " #"..effect.effect:GetID())
        if effect ~= nil then
            for i = 1, #self.removed_event do
                self.removed_event[i](effect.effect)
            end
        end
        self.effects = {}
    end

    -- Cleanup and get fresh effects instance
    self:detach_callbacks()
    self.instance_effects = _get_target_effects(self.player)
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
    self.instance_effects = _get_target_effects(self.player)
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
        self.instance_effects = _get_target_effects(self.player)
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
