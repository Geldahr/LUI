import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.ExpiringEffects.expiring_effects_window"
import "LUI.src.ExpiringEffects.self_expiring_effect_entry"

SelfExpiringEffectsWindow = class(ExpiringEffectsWindow)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfExpiringEffectsWindow:Constructor()
    ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Self)"] })
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfExpiringEffectsWindow:get_settings()
    return _G.settings.self.expiring_effects
end

function SelfExpiringEffectsWindow:get_loaded_settings()
    return _G.loaded_settings.self.expiring_effects
end

function SelfExpiringEffectsWindow:get_border_width()
    return _G.settings.self.expiring_effects.border_width
end

function SelfExpiringEffectsWindow:get_entry_class()
    return SelfExpiringEffectEntry
end

function SelfExpiringEffectsWindow:get_effect_objects()
    local list = Turbine.Gameplay.LocalPlayer.GetInstance():GetEffects()
    if list == nil or list.GetCount == nil then
        return {}
    end

    local out = {}
    local count = list:GetCount() or 0
    for i = 1, count do
        local effect = list:Get(i)
        if effect ~= nil then
            table.insert(out, effect)
        end
    end

    return out
end
