import "LUI.src.Utils.boss_names"

local BOSS_FALLBACK_BASE_MORALE_RATIO = 3
local BOSS_FALLBACK_LEVEL_DELTA_SCALE = 0.02

local function _get_required_morale_ratio(self_level, target_level)
    local up_delta = target_level - self_level
    if up_delta < 0 then
        up_delta = 0
    end

    return BOSS_FALLBACK_BASE_MORALE_RATIO * (1 + (up_delta * up_delta * BOSS_FALLBACK_LEVEL_DELTA_SCALE))
end

local function _should_try_boss_name_fallback(target, self_entity)
    if target == nil or self_entity == nil then
        return false
    end

    if target.GetMaxMorale == nil or target.GetLevel == nil then
        return false
    end

    if self_entity.GetMaxMorale == nil or self_entity.GetLevel == nil then
        return false
    end

    local self_max_morale = self_entity:GetMaxMorale() or 0
    local target_max_morale = target:GetMaxMorale() or 0
    if self_max_morale <= 0 or target_max_morale <= 0 then
        return false
    end

    local self_level = self_entity:GetLevel() or 0
    local target_level = target:GetLevel() or 0
    local required_ratio = _get_required_morale_ratio(self_level, target_level)

    return target_max_morale >= (self_max_morale * required_ratio)
end

function _G.is_boss_name(target_name)
    return BOSS_NAMES[target_name] == true
end

function _G.does_boss_name_match(target_name, target, self_entity)
    if is_boss_name(target_name) then
        return true
    end

    if type(target_name) ~= "string" or target_name == "" then
        return false
    end

    if _should_try_boss_name_fallback(target, self_entity) ~= true then
        return false
    end

    -- for boss_name in pairs(BOSS_NAMES) do
    --     if string.find(target_name, boss_name, 1, true) ~= nil then
    --         return true
    --     end
    -- end

    return false
end

function _G.is_boss_target(target, self_entity)
    if target == nil or target.GetName == nil then
        return false
    end

    return does_boss_name_match(target:GetName(), target, self_entity)
end
