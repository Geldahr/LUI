-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local ExpiringEffects = _G.LUI.Features.ExpiringEffects
local Vitals = _G.LUI.Features.Vitals
local State = _G.LUI.Settings.State
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Utils.callbacks"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.ExpiringEffects.expiring_effects_window"
import "LUI.src.ExpiringEffects.target_expiring_effect_entry"

local add_callback = _G.LUI.Utils.add_callback

local TargetExpiringEffectsWindow = class(ExpiringEffects.ExpiringEffectsWindow)
ExpiringEffects.TargetExpiringEffectsWindow = TargetExpiringEffectsWindow

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:Constructor()
    self._target_hold = nil
    self._target_is_self = false

    -- the base constructor runs apply_settings, which syncs the manager
    ExpiringEffects.ExpiringEffectsWindow.Constructor(self, { title = TR["Expiring Effects (Target)"] })

    self._lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    self._cb_target_changed = add_callback(self._lp, "TargetChanged", function()
        self:_sync_target_manager()
    end)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:get_settings()
    return State.settings.target.expiring_effects
end

function TargetExpiringEffectsWindow:get_hud_key()
    return "target_effects"
end

function TargetExpiringEffectsWindow:get_entry_class()
    return ExpiringEffects.TargetExpiringEffectEntry
end

function TargetExpiringEffectsWindow:apply_settings()
    ExpiringEffects.ExpiringEffectsWindow.apply_settings(self)
    self:_sync_target_manager()
end

function TargetExpiringEffectsWindow:Update()
    -- drives the manager's refetch-after-remove (a no-op when another
    -- handler of the shared manager already polled this frame)
    if self._target_hold ~= nil then
        self._target_hold.manager:poll()
    end

    ExpiringEffects.ExpiringEffectsWindow.Update(self)
end

function TargetExpiringEffectsWindow:get_effect_objects()
    local out = {}
    if self._target_is_self == true then
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
        if self._target_hold == nil then
            return {}
        end

        for _, o in pairs(self._target_hold.manager.effects) do
            if o ~= nil then
                table.insert(out, o.effect)
            end
        end
    end
    return out
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:_release_target_manager()
    if self._target_hold == nil then
        return
    end
    Vitals.TargetEffectManagerCache.release_selected(self._target_hold)
    self._target_hold = nil
end

-- Holds a handle on the shared target manager only while this window is
-- enabled, independently of target vitals; get_effect_objects reads its map.
-- With yourself selected, the player's own list is read instead. Re-synced on
-- TargetChanged and on settings apply.
function TargetExpiringEffectsWindow:_sync_target_manager()
    self:_release_target_manager()
    self._target_is_self = false

    if self:get_settings().enabled ~= true then
        return
    end

    self._target_hold, self._target_is_self =
        Vitals.TargetEffectManagerCache.hold_selected(Turbine.Gameplay.LocalPlayer.GetInstance())
end
