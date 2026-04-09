import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.ExpiringEffects.expiring_effects_window"
import "LUI.src.ExpiringEffects.target_expiring_effect_entry"

TargetExpiringEffectsWindow = class(ExpiringEffectsWindow)

local function _target_is_local_player()
    if TARGET_VITAL == nil or TARGET_VITAL.entity == nil then
        return false
    end

    local entity = TARGET_VITAL.entity
    local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    if lp == nil or entity.GetName == nil or lp.GetName == nil then
        return false
    end

    return entity:GetName() == lp:GetName()
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:Constructor()
    self._current_target = nil
    self._current_target_key = ""
    self._effects = nil
    self._effect_events = { ea = nil, er = nil, ec = nil }

    ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Target)"] })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:get_settings()
    return _G.settings.target.expiring_effects
end

function TargetExpiringEffectsWindow:get_loaded_settings()
    return _G.loaded_settings.target.expiring_effects
end

function TargetExpiringEffectsWindow:get_border_width()
    return _G.settings.target.expiring_effects.border_width
end

function TargetExpiringEffectsWindow:get_entry_class()
    return TargetExpiringEffectEntry
end

function TargetExpiringEffectsWindow:get_effect_objects()
    if TARGET_VITAL == nil then
        return {}
    end

    local out = {}
    if _target_is_local_player() == true then
        local list = Turbine.Gameplay.LocalPlayer.GetInstance():GetEffects()
        if list == nil or list.GetCount == nil then
            return {}
        end

        local count = list:GetCount() or 0
        for i = 1, count do
            local effect = list:Get(i)
            if effect ~= nil then
                table.insert(out, effect)
            end
        end
    else
        local em = TARGET_VITAL.em
        if em == nil then
            return {}
        end

        for _, o in pairs(em.effects) do
            if o ~= nil then
                table.insert(out, o.effect)
            end
        end
    end


    return out
end

-- NOTE: legacy code, new code is being tested
-- import "Turbine.Gameplay"
-- import "Turbine.UI"
-- import "Turbine.UI.Lotro"

-- import "LUI.src.ExpiringEffects.expiring_effects_window"
-- import "LUI.src.ExpiringEffects.target_expiring_effect_entry"

-- TargetExpiringEffectsWindow = class(ExpiringEffectsWindow)

-- local function _target_key(target)
--     if target == nil then
--         return ""
--     end
--     local id = (target.GetID ~= nil and target:GetID()) or nil
--     if type(id) ~= "number" then
--         id = tonumber(id)
--     end
--     if type(id) == "number" and id > 0 then
--         return "id|" .. tostring(id)
--     end
--     return tostring(target)
-- end

-- function TargetExpiringEffectsWindow:Constructor()
--     self._current_target = nil
--     self._current_target_key = ""
--     self._effects = nil
--     self._effect_events = { ea = nil, er = nil, ec = nil }

--     ExpiringEffectsWindow.Constructor(self, { title = "Expiring Effects" })
-- end

-- function TargetExpiringEffectsWindow:get_settings()
--     return _G.settings.target.expiring_effects
-- end

-- function TargetExpiringEffectsWindow:get_loaded_settings()
--     return _G.loaded_settings.target.expiring_effects
-- end

-- function TargetExpiringEffectsWindow:get_border_width()
--     return _G.settings.target.vitals.frame.border_width or 0
-- end

-- function TargetExpiringEffectsWindow:get_entry_class()
--     return TargetExpiringEffectEntry
-- end

-- function TargetExpiringEffectsWindow:get_effect_objects()
--     local out = {}
--     local seen = {}

--     local effects = self._effects
--     if effects ~= nil and effects.GetCount ~= nil and effects:GetCount() > 0 then
--         for i = 1, effects:GetCount() do
--             local effect = effects:Get(i)
--             if effect ~= nil then
--                 local key = self:get_effect_key(effect)
--                 if seen[key] ~= true then
--                     seen[key] = true
--                     table.insert(out, effect)
--                 end
--             end
--         end
--     end

--     -- Also include the effects currently tracked by target vitals (handles flaky target effects lists).
--     local tv = TARGET_VITAL
--     local tv_key = (tv ~= nil and tv.entity ~= nil) and _target_key(tv.entity) or ""
--     if tv_key ~= "" and tv_key == self._current_target_key and type(tv.effects_objects) == "table" then
--         for _, effect in pairs(tv.effects_objects) do
--             if effect ~= nil then
--                 local key = self:get_effect_key(effect)
--                 if seen[key] ~= true then
--                     seen[key] = true
--                     table.insert(out, effect)
--                 end
--             end
--         end
--     end

--     return out
-- end

-- function TargetExpiringEffectsWindow:refresh_visibility()
--     local s = self:get_settings()
--     if s == nil or s.enabled ~= true then
--         self:SetVisible(false)
--         return
--     end

--     local has_target = self._current_target_key ~= nil and self._current_target_key ~= ""
--     if not has_target then
--         local t = (TARGET_VITAL ~= nil and TARGET_VITAL.entity ~= nil) and TARGET_VITAL.entity or nil
--         if t == nil then
--             local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
--             t = lp ~= nil and lp.GetTarget ~= nil and lp:GetTarget() or nil
--         end
--         has_target = t ~= nil
--     end

--     local cols = tonumber(s.columns) or 2
--     local rows = tonumber(s.rows) or 3
--     if cols < 1 then cols = 1 end
--     if rows < 1 then rows = 1 end
--     local capacity = cols * rows

--     local any_visible = false
--     for i = 1, capacity do
--         local e = self.slots[i]
--         if e ~= nil and e:IsVisible() then
--             any_visible = true
--             break
--         end
--     end

--     self:SetVisible(has_target or any_visible or (self.moveable ~= nil and self.moveable:is_move_mode()))
-- end

-- -- TODO: Needs optimization
-- function TargetExpiringEffectsWindow:Update()
--     local s = self:get_settings()
--     if s == nil or s.enabled ~= true then
--         if self._current_target_key ~= nil and self._current_target_key ~= "" then
--             self._current_target = nil
--             self._current_target_key = ""
--         end
--         self:SetVisible(false)
--         return
--     end

--     -- Prefer the target already tracked by the vitals subsystem (event-driven, stable),
--     -- fallback to polling LocalPlayer target.
--     local target = (TARGET_VITAL ~= nil and TARGET_VITAL.entity ~= nil) and TARGET_VITAL.entity or nil
--     if target == nil then
--         local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
--         target = lp ~= nil and lp.GetTarget ~= nil and lp:GetTarget() or nil
--     end

--     local target_key = _target_key(target)
--     if target_key ~= self._current_target_key then
--         self._current_target = target
--         self._current_target_key = target_key
--         self.last_update_at = 0
--         if self.clear_effect_time_cache ~= nil then
--             self:clear_effect_time_cache()
--         end

--         for i = 1, #self.slots do
--             local e = self.slots[i]
--             if e ~= nil then
--                 if e.set_effect ~= nil then e:set_effect(nil) end
--                 e:SetVisible(false)
--             end
--         end
--     end

--     if target == nil then
--         self:refresh_visibility()
--         return
--     end

--     ExpiringEffectsWindow.Update(self)
-- end
