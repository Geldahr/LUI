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

function TargetExpiringEffectsWindow:get_hud_key()
    return "target_effects"
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
