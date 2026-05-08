import "LUI.src.Settings.Preview.group_vitals"

local _raid_preview_spec = {
    state_key = "raid_vitals_preview",
    holder_key = "raid_vitals_preview",
    prefix = "raid",
    max_members = 24,
    leader_slot = 1,
    get_preview_count = function()
        return 24
    end,
    is_self_slot = function(index)
        return index == 1
    end,
}

function ConfigWindow:init_raid_vitals_preview()
    SettingsGroupVitalsPreview.init(self, _raid_preview_spec)
    self:update_raid_vitals_preview()
end

function ConfigWindow:update_raid_vitals_preview()
    SettingsGroupVitalsPreview.update(self, _raid_preview_spec)
end
