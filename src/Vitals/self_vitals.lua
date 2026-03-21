import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Vitals.vitals_base"

---@class SelfVitals : VitalsBase
SelfVitals = class(VitalsBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function SelfVitals:Constructor(entity)
    self.target_vitals = nil
    self.boss_vitals = nil
    VitalsBase.Constructor(self, "self", entity, TR("Self Vitals"))
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SelfVitals:set_target_vitals(target_vitals, boss_vitals)
    self.target_vitals = target_vitals
    self.boss_vitals = boss_vitals
    -- Sync initial target state (plugin can load while a target is already selected).
    self:on_target_changed()
end

function SelfVitals:on_target_changed()
    if self.target_vitals == nil and self.boss_vitals == nil then
        return
    end

    local hud_visible = is_lui_hud_visible() == true
    local boss_vitals_enabled = _G.loaded_settings.target.boss_vitals.enabled == true

    if self.entity == nil or self.entity.GetTarget == nil then
        if self.target_vitals ~= nil then
            self.target_vitals:set_entity(nil)
            self.target_vitals:SetVisible(hud_visible == true and self.target_vitals:is_move_mode())
        end
        if self.boss_vitals ~= nil then
            self.boss_vitals:set_entity(nil)
            self.boss_vitals:SetVisible(hud_visible == true and boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
        return
    end

    local t = self.entity:GetTarget()
    local is_boss = boss_vitals_enabled == true and
        t ~= nil and
        is_boss_target ~= nil and
        is_boss_target(t, self.entity) == true

    if self.target_vitals ~= nil then
        self.target_vitals:set_entity(t)
        if t ~= nil and is_boss ~= true then
            self.target_vitals:SetVisible(hud_visible)
        else
            self.target_vitals:SetVisible(hud_visible == true and self.target_vitals:is_move_mode())
        end
    end

    if self.boss_vitals ~= nil then
        self.boss_vitals:set_entity(is_boss == true and t or nil)
        if is_boss == true then
            self.boss_vitals:SetVisible(hud_visible)
        else
            self.boss_vitals:SetVisible(hud_visible == true and boss_vitals_enabled == true and self.boss_vitals:is_move_mode())
        end
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function SelfVitals:_setup_effect_tracking()
    self:_setup_effect_tracking_default()
end
