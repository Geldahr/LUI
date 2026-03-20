import "Turbine.Gameplay"

---@class TargetEffectManagerEffectEntry
---@field is_refreshed boolean
---@field effect Turbine.Gameplay.Effect

---@class TargetEffectManager : Turbine.Object
---@field instance_effects Turbine.Gameplay.EffectList|nil
---@field added_event function|nil
---@field removed_event function|nil
---@field cleared_event function|nil
---@field call_in_s number|nil
---@field player Turbine.Gameplay.Actor|nil
---@field effects table<number, TargetEffectManagerEffectEntry>
TargetEffectManager = class(Turbine.Object)

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


---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

---@param player Turbine.Gameplay.Actor
function TargetEffectManager:Constructor(player)
    Turbine.Object.Constructor(self)
    self.effects = {}
    self.player = player

    self.call_in_s = nil

    -- /!\ IMPORTANT /!\
    -- DO NOT COPY THE INSTANCE OF THAT VARIABLE IN ANOTHER PLACE
    -- THAT WILL BREAK THE WHOLE MANAGER
    self.instance_effects = _get_target_effects(self.player)

    self.added_event = nil
    self.removed_event = nil
    self.cleared_event = nil

    self:attach_callbacks()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

-- Function to be called before deleting the TargetEffectManager instance
-- It MUST be called for safety reasons
function TargetEffectManager:delete()
    self.effects = nil
    self.added_event = nil
    self.removed_event = nil
    self.cleared_event = nil
    self:detach_callbacks()
    self.instance_effects = nil
    self.player = nil
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

---@param callback function|nil
function TargetEffectManager:register_added_event(callback)
    local fire_events = (self.added_event == nil)

    self.added_event = callback

    if self.added_event == nil or self.instance_effects == nil then
        return
    end

    if fire_events then
        for i = 1, self.instance_effects:GetCount() do
            local effect = self.instance_effects:Get(i)
            -- Add events to our own list and fire the event added callback
            -- Turbine.Shell.WriteLine("Added: "..effect:GetName() .. " #"..effect:GetID())
            self.effects[effect:GetID()] = { is_refreshed = true, effect = effect }
            self.added_event(effect)
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

    if self.added_event ~= nil then
        -- Turbine.Shell.WriteLine("Added: "..effect:GetName() .. " #"..effect:GetID())
        self.added_event(effect)
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
        if self.removed_event ~= nil and effect ~= nil then
            self.removed_event(effect.effect)
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
    if self.cleared_event ~= nil then
        self.cleared_event()
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
            if self.removed_event ~= nil then
                -- Turbine.Shell.WriteLine("Removed: "..effect.effect:GetName() .. " #"..effect.effect:GetID())
                self.removed_event(effect.effect)
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
            if self.added_event ~= nil then
                for i = 1, self.instance_effects:GetCount() do
                    local effect = self.instance_effects:Get(i)
                    if effect ~= nil then
                        self.effects[effect:GetID()] = { is_refreshed = true, effect = effect }
                        self.added_event(effect)
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
