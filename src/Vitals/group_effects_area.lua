-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Vitals = _G.LUI.Features.Vitals
local class = _G.LUI.Core.class

import "LUI.src.Vitals.effects_area"

local CURABILITY_UNKNOWN = 0
local CURABILITY_CURABLE = 1
local CURABILITY_NONCURABLE = 2

local function _curability_state(effect)
    if effect == nil or effect.IsCurable == nil then
        return CURABILITY_UNKNOWN
    end

    local is_curable = effect:IsCurable()
    if is_curable == true then
        return CURABILITY_CURABLE
    end
    if is_curable == false then
        return CURABILITY_NONCURABLE
    end

    return CURABILITY_UNKNOWN
end

-- A merged buff/debuff area for group members. Unlike the standard
-- buff/debuff split, this renders both kinds in a single grid sized to the
-- member bar, filtered by the three group_effects toggles.
---@class GroupEffectsArea : EffectsArea
local GroupEffectsArea = class(Vitals.EffectsArea)
Vitals.GroupEffectsArea = GroupEffectsArea

-- bar_height is the member bar height; the base derives max_height as
-- effects_height / 2, so we pass bar_height * 2 to keep the box exactly the
-- bar height. group_effects is the runtime State.settings.<root>.group_effects.
function GroupEffectsArea:Constructor(bar_width, group_effects, bar_height)
    Vitals.EffectsArea.Constructor(self, bar_width, group_effects, bar_height * 2)
end

-- Re-apply settings from the owner. We pass bar_height * 2 because the base
-- derives max_height as effects_height / 2; this keeps the box exactly the bar
-- height. The base re-calls plain apply_settings internally (compaction), which
-- reuses the stored effects_height, so we must not override apply_settings.
function GroupEffectsArea:apply_bar_settings(bar_width, group_effects, bar_height)
    self:apply_settings(bar_width, group_effects, bar_height * 2)
end

-- group_effects fields live directly on the settings table (no sub-group).
function GroupEffectsArea:_area_settings()
    return self.effects_settings
end

function GroupEffectsArea:_default_icon_size()
    return 22
end

function GroupEffectsArea:_default_dynamic_height()
    return false
end

-- Keep the box pinned to the bar height across rescales.
function GroupEffectsArea:_reset_max_height_on_apply_settings()
    return true
end

function GroupEffectsArea:_should_track_effect(effect)
    local settings = self.effects_settings
    if settings == nil or effect == nil or effect.IsDebuff == nil then
        return false
    end

    if effect:IsDebuff() ~= true then
        return settings.show_buffs == true
    end

    local curability = _curability_state(effect)
    if curability == CURABILITY_CURABLE then
        return settings.show_curable_debuffs == true
    end
    if curability == CURABILITY_NONCURABLE then
        return settings.show_noncurable_debuffs == true
    end

    -- Unknown curability is its own state: only show it when both known debuff
    -- kinds are enabled, so a transient nil does not leak into a filtered view.
    return settings.show_curable_debuffs == true and settings.show_noncurable_debuffs == true
end
