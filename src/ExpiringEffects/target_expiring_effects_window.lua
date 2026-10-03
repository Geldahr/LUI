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
    self._target_em = nil
    self._target_em_added = nil
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
    if self._target_em ~= nil then
        self._target_em:poll()
    end

    ExpiringEffects.ExpiringEffectsWindow.Update(self)
end

function TargetExpiringEffectsWindow:get_effect_objects()
    local em = self._target_em

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

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function TargetExpiringEffectsWindow:_release_target_manager()
    if self._target_em == nil then
        return
    end
    self._target_em:unregister_added_event(self._target_em_added)
    self._target_em_added = nil
    self._target_em:release_live()
    self._target_em = nil
end

-- Holds a handle on the shared target manager only while this window is
-- enabled, independently of target vitals. Target effects are never read with a
-- raw GetEffects() on the target; the method check below is a capability
-- probe only. Re-synced on TargetChanged and on settings apply.
function TargetExpiringEffectsWindow:_sync_target_manager()
    self:_release_target_manager()
    self._target_is_self = false

    if self:get_settings().enabled ~= true then
        return
    end

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetTarget == nil then
        return
    end
    local target = player:GetTarget()
    if target == nil or target.GetEffects == nil then
        return
    end
    -- targeting yourself: the manager is for OTHER entities only, the
    -- player's own list is read directly in get_effect_objects
    if target.GetName ~= nil and player.GetName ~= nil and
        target:GetName() == player:GetName() then
        self._target_is_self = true
        return
    end

    self._target_em = Vitals.TargetEffectManager.acquire(player, target)
    -- registering the added event snapshots the target's current effects
    -- into the manager's map, which get_effect_objects reads; the callback
    -- itself has nothing to do
    local added = function() end
    self._target_em:register_added_event(added)
    self._target_em_added = added
end
