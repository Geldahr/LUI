import "LUI.src.Settings.default_layouts"
import "LUI.src.Utils.raid_layout"

local RAID_GROUP_KEYS = { "a", "b", "c", "d" }

local function _ensure_table(t, key)
    if type(t[key]) ~= "table" then
        t[key] = {}
    end
    return t[key]
end

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = _copy_table(child)
    end

    return copy
end

local function _sanitize_with_defaults(source, defaults)
    if type(defaults) ~= "table" then
        if source == nil then
            return defaults
        end
        return source
    end

    local sanitized = _copy_table(defaults)
    if type(source) ~= "table" then
        return sanitized
    end

    for key, default_value in pairs(defaults) do
        local source_value = source[key]
        if type(default_value) == "table" then
            sanitized[key] = _sanitize_with_defaults(source_value, default_value)
        elseif source_value ~= nil then
            sanitized[key] = source_value
        end
    end

    for key, source_value in pairs(source) do
        if defaults[key] == nil and source_value ~= nil then
            sanitized[key] = _copy_table(source_value)
        end
    end

    return sanitized
end

local function _apply_missing_values(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, default_value in pairs(defaults) do
        local current_value = target[key]
        if current_value == nil then
            target[key] = _copy_table(default_value)
        elseif type(current_value) == "table" and type(default_value) == "table" then
            _apply_missing_values(current_value, default_value)
        end
    end
end

local function _ensure_label_layout_defaults(label)
    if type(label) ~= "table" then
        return
    end

    if label.anchor == nil then
        label.anchor = LUI_ENUMS.vitals_label_anchor.CENTER
    end
    if label.width_mode == nil then
        label.width_mode = LUI_ENUMS.vitals_label_width_mode.FILL
    end
    if label.text_alignment == nil then
        label.text_alignment = LUI_ENUMS.text_alignment.CENTER
    end
    if label.x_offset == nil then
        label.x_offset = 0
    end
    if label.y_offset == nil then
        label.y_offset = 0
    end
end

local function _ensure_vital_labels_defaults(vital_settings)
    if type(vital_settings) ~= "table" or type(vital_settings.labels) ~= "table" then
        return
    end

    for _, label in pairs(vital_settings.labels) do
        _ensure_label_layout_defaults(label)
    end
end

local function _ensure_targets_target_labels_defaults(target_settings)
    if type(target_settings) ~= "table" or type(target_settings.targets_target) ~= "table" then
        return
    end

    _ensure_vital_labels_defaults(target_settings.targets_target)
end

local function _ensure_preview_label_defaults(loaded)
    _ensure_vital_labels_defaults(loaded.self and loaded.self.vitals)
    _ensure_vital_labels_defaults(loaded.target and loaded.target.vitals)
    _ensure_targets_target_labels_defaults(loaded.target and loaded.target.vitals)
    _ensure_vital_labels_defaults(loaded.target and loaded.target.boss_vitals)
    _ensure_vital_labels_defaults(loaded.party)
    _ensure_vital_labels_defaults(loaded.fellowship)
    _ensure_vital_labels_defaults(loaded.raid)
end

local function _ensure_raid_layout_defaults(loaded, defaults)
    if type(loaded.raid) ~= "table" then
        return
    end

    local raid_layout = _ensure_table(loaded.raid, "layout")
    local default_layout = defaults.raid.layout
    if raid_layout.mode == nil then
        raid_layout.mode = default_layout.mode
    end
end

local function _hud_position_matches(lhs, rhs)
    if type(lhs) ~= "table" or type(rhs) ~= "table" then
        return false
    end

    return lhs.left == rhs.left and lhs.top == rhs.top
end

local function _raw_group_member_height(vitals_settings)
    local border_width = vitals_settings.frame.border_width
    local member_height = vitals_settings.morale.height + vitals_settings.power.height - border_width
    if vitals_settings.info.enabled == true then
        member_height = member_height + vitals_settings.info.height - border_width
    end
    if member_height < 1 then
        member_height = 1
    end

    return member_height
end

local function _raid_group_color(r, g, b)
    return {
        A = 1,
        R = r,
        G = g,
        B = b,
    }
end

local function _build_raid_group_hud_defaults(raid_hud, raid_settings)
    local out = {}
    local layout = raid_settings.layout
    local member_width = raid_settings.frame.width
    local member_height = _raw_group_member_height(raid_settings)

    for group_index = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[group_index]
        local cell = RaidLayout.group_origin_cell(layout.mode, group_index)
        out["raid_group_" .. group_key .. "_vitals"] = {
            left = raid_hud.left + (cell.column * (member_width + layout.spacing_x)),
            top = raid_hud.top + (cell.row * (member_height + layout.spacing_y)),
        }
    end

    return out
end

local function _seed_raid_group_hud_positions(hud, raid_settings, defaults)
    local default_group_positions = defaults.ui.hud
    local computed_positions = _build_raid_group_hud_defaults(hud.raid_vitals, raid_settings)

    for i = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[i]
        local hud_key = "raid_group_" .. group_key .. "_vitals"
        local current = hud[hud_key]
        local seeded = computed_positions[hud_key]

        if _hud_position_matches(current, default_group_positions[hud_key]) == true then
            current = seeded
        end

        hud[hud_key] = _sanitize_with_defaults(current, seeded)
    end
end

local function _seed_group_vitals_compatibility(loaded, defaults)
    local default_party_source = defaults.party
    local fellowship_source = _sanitize_with_defaults(loaded.party, default_party_source)
    loaded.party = fellowship_source

    local raid_source = defaults.raid

    loaded.fellowship = _sanitize_with_defaults(loaded.fellowship, fellowship_source)
    if loaded.fellowship.show_self_in_fellowship == nil then
        loaded.fellowship.show_self_in_fellowship = true
    end

    loaded.raid = _sanitize_with_defaults(loaded.raid, raid_source)

    local hud = _ensure_table(_ensure_table(loaded, "ui"), "hud")
    local default_party_hud_source = defaults.ui.hud.party_vitals
    local default_fellowship_hud_source = defaults.ui.hud.fellowship_vitals
    local default_raid_hud_source = defaults.ui.hud.raid_vitals
    local fellowship_hud_source = _sanitize_with_defaults(hud.party_vitals, default_fellowship_hud_source)
    hud.party_vitals = fellowship_hud_source

    local raid_hud_source = hud.raid_vitals
    if _hud_position_matches(raid_hud_source, fellowship_hud_source) == true then
        raid_hud_source = default_raid_hud_source
    end

    hud.fellowship_vitals = _sanitize_with_defaults(hud.fellowship_vitals, fellowship_hud_source)
    hud.raid_vitals = _sanitize_with_defaults(raid_hud_source, default_raid_hud_source)
    _seed_raid_group_hud_positions(hud, loaded.raid, defaults)
end

local function _ensure_window_tiles(windows)
    if type(windows) ~= "table" then
        return
    end

    for _, window in pairs(windows) do
        if type(window) == "table" and window.tile ~= "maximized" then
            window.tile = "none"
        end
    end
end

local function _defaults_source()
    local loaded = _G.loaded_settings
    local target_scale = _G.DefaultLayouts.get_resolution_scale()
    if type(loaded) == "table" then
        local global = loaded.global
        if type(global) == "table" then
            local scale = tonumber(global.scale)
            if type(scale) == "number" then
                target_scale = scale
            end
        end
    end

    local defaults = _G.DefaultLayouts.build("top", target_scale)

    if type(defaults.party) ~= "table" then
        error("Missing default party settings")
    end

    if type(defaults.fellowship) ~= "table" then
        defaults.fellowship = _copy_table(defaults.party)
    end
    if defaults.fellowship.show_self_in_fellowship == nil then
        defaults.fellowship.show_self_in_fellowship = true
    end

    if type(defaults.raid) ~= "table" then
        defaults.raid = _copy_table(defaults.party)
    end
    defaults.raid.split_by_group = false
    defaults.raid.group_colors = {
        a = _raid_group_color(0.82, 0.28, 0.28),
        b = _raid_group_color(0.82, 0.67, 0.20),
        c = _raid_group_color(0.25, 0.49, 0.84),
        d = _raid_group_color(0.24, 0.70, 0.37),
    }
    local raid_layout = _ensure_table(defaults.raid, "layout")
    if raid_layout.mode == nil then
        raid_layout.mode = LUI_ENUMS.raid_layout_mode.FOUR_COLUMNS_MODE_1
    end
    local default_raid_group_positions = _build_raid_group_hud_defaults(defaults.ui.hud.raid_vitals, defaults.raid)
    for i = 1, #RAID_GROUP_KEYS do
        local group_key = RAID_GROUP_KEYS[i]
        local hud_key = "raid_group_" .. group_key .. "_vitals"
        defaults.ui.hud[hud_key] = default_raid_group_positions[hud_key]
    end

    return defaults
end

function _G.get_ui_window_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(_G.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    return _ensure_table(windows, key)
end

function _G.get_ui_hud_state(key)
    if type(key) ~= "string" then
        return nil
    end
    if type(_G.loaded_settings) ~= "table" then
        return nil
    end

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local hud = _ensure_table(ui, "hud")
    return _ensure_table(hud, key)
end

function _G.ensure_loaded_settings()
    if type(_G.loaded_settings) ~= "table" then
        _G.loaded_settings = {}
    end

    local defaults = _defaults_source()
    _G.loaded_settings = _sanitize_with_defaults(_G.loaded_settings, defaults)
    _seed_group_vitals_compatibility(_G.loaded_settings, defaults)
    _ensure_preview_label_defaults(_G.loaded_settings)
    _ensure_raid_layout_defaults(_G.loaded_settings, defaults)

    local ui = _ensure_table(_G.loaded_settings, "ui")
    local windows = _ensure_table(ui, "windows")
    _ensure_window_tiles(windows)

    if is_lui_english_language ~= nil and is_lui_english_language() ~= true then
        local global = _ensure_table(_G.loaded_settings, "global")
        global.bestiary_capture = false
    end
end
