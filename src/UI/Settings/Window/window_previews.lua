import "LUI.src.UI.Settings.Preview.common"
import "LUI.src.UI.Settings.Preview.self_expiring_effects"
import "LUI.src.UI.Settings.Preview.cooldowns"
import "LUI.src.UI.Settings.Preview.expiring_target_effects"
import "LUI.src.UI.Settings.Preview.target_boss_vitals"
import "LUI.src.UI.Settings.Preview.target_targets_target"
import "LUI.src.UI.Settings.Preview.party_vitals"
import "LUI.src.UI.Settings.Preview.vitals"

local PREVIEW_INITIALIZERS = {
    "init_expiring_effects_preview",
    "init_expiring_target_effects_preview",
    "init_cooldowns_preview",
    "init_self_vitals_preview",
    "init_target_vitals_preview",
    "init_target_boss_vitals_preview",
    "init_target_targets_target_preview",
    "init_party_vitals_preview",
}

local PREVIEW_REFRESHERS = {
    expiring_effects = "update_expiring_effects_preview",
    expiring_target_effects = "update_expiring_target_effects_preview",
    cooldowns = "update_cooldowns_preview",
    party_vitals = "update_party_vitals_preview",
    self_vitals = "update_self_vitals_preview",
    target_vitals = "update_target_vitals_preview",
    target_boss_vitals = "update_target_boss_vitals_preview",
    target_targets_target = "update_target_targets_target_preview",
}

local function _call_preview_method(window, method_name)
    local method = window[method_name]
    if type(method) ~= "function" then
        error("Missing config window preview method: " .. tostring(method_name))
    end
    method(window)
end

function ConfigWindow:_init_previews()
    for i = 1, #PREVIEW_INITIALIZERS do
        _call_preview_method(self, PREVIEW_INITIALIZERS[i])
    end
end

function ConfigWindow:_refresh_active_preview()
    local method_name = PREVIEW_REFRESHERS[self.active_tab]
    if method_name == nil then
        return
    end

    _call_preview_method(self, method_name)
end
