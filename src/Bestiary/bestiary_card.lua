import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

Bestiary = Bestiary or {}

local BUILTIN_BESTIARY = Bestiary.Data or {}

local BASE_WIDTH = 550
local BASE_HEIGHT = 570
local BASE_BORDER = 2
local BASE_PADDING = 12
local BASE_SECTION_GAP = 6
local BASE_HEADER_H = 68
local BASE_PANEL_HEADER_H = 20
local BASE_PANEL_BODY_PAD_X = 8
local BASE_PANEL_BODY_PAD_TOP = 4
local BASE_PANEL_BODY_PAD_BOTTOM = 10
local BASE_CLOSE_W = 72
local BASE_STAT_BOX_H = 52
local BASE_PROFILE_H = 78
local BASE_TWO_COL_H = 88
local BASE_MITIGATION_H = 104
local BASE_NOTES_MIN_H = 76
local BASE_DROP_MIN_H = 42
local BASE_DROP_MAX_H = 150
local BASE_TITLE_SIZE = 20
local BASE_SUBTITLE_SIZE = 12
local BASE_SECTION_TITLE_SIZE = 12
local BASE_TEXT_SIZE = 11
local BASE_HINT_SIZE = 10
local BASE_ADVANCED_H = 22
local BASE_OFFSET = 12
local BASE_CHIP_H = 18
local BASE_CHIP_PAD_X = 6
local BASE_CHIP_GAP_X = 4
local BASE_CHIP_GAP_Y = 4
local BASE_CHIP_BORDER = 1
local BASE_CHIP_CHAR_W = 5.8
local BASE_TEXT_CHAR_W = 5.8
local BASE_TEXT_LINE_H = 14
local BASE_SCROLL_W = 10
local BASE_SCROLL_GAP = 3

local COLOR_OUTLINE = Turbine.UI.Color(1, 0, 0, 0)
local COLOR_WINDOW_BG = Turbine.UI.Color(0.98, 0.02, 0.04, 0.08)
local COLOR_BORDER = Turbine.UI.Color(1, 0.22, 0.31, 0.44)
local COLOR_INNER_BG = Turbine.UI.Color(0.98, 0.03, 0.06, 0.10)
local COLOR_HEADER_BG = Turbine.UI.Color(1, 0.05, 0.10, 0.18)
local COLOR_HEADER_RULE = Turbine.UI.Color(1, 0.66, 0.53, 0.28)
local COLOR_PANEL_BORDER = Turbine.UI.Color(1, 0.24, 0.35, 0.49)
local COLOR_PANEL_BG = Turbine.UI.Color(0.98, 0.02, 0.05, 0.09)
local COLOR_PANEL_HEADER = Turbine.UI.Color(1, 0.05, 0.09, 0.16)
local COLOR_PANEL_DIVIDER = Turbine.UI.Color(1, 0.16, 0.24, 0.35)
local COLOR_TITLE = Turbine.UI.Color(1, 0.94, 0.82, 0.55)
local COLOR_SUBTITLE = Turbine.UI.Color(1, 0.83, 0.78, 0.69)
local COLOR_META = Turbine.UI.Color(1, 0.44, 0.88, 0.95)
local COLOR_LABEL = Turbine.UI.Color(1, 0.92, 0.82, 0.56)
local COLOR_VALUE = Turbine.UI.Color(1, 0.93, 0.90, 0.84)
local COLOR_VALUE_CYAN = Turbine.UI.Color(1, 0.30, 0.92, 1.00)
local COLOR_VALUE_GREEN = Turbine.UI.Color(1, 0.34, 0.82, 0.30)
local COLOR_HINT = Turbine.UI.Color(1, 0.55, 0.60, 0.63)
local COLOR_DROP_CHIP_BORDER = Turbine.UI.Color(1, 0.28, 0.28, 0.28)
local COLOR_DROP_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_DROP_CHIP_TEXT = Turbine.UI.Color(1, 0.76, 0.88, 0.79)
local COLOR_CHEST_CHIP_BORDER = Turbine.UI.Color(1, 0.45, 0.32, 0.12)
local COLOR_CHEST_CHIP_BG = Turbine.UI.Color(1, 0.14, 0.10, 0.04)
local COLOR_CHEST_CHIP_TEXT = Turbine.UI.Color(1, 0.98, 0.86, 0.52)

local function _scaled_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end
    return value
end

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function _normalize_bestiary_name(name)
    name = _trim(name)
    if name == nil then
        return nil
    end

    local lowered = string.lower(name)
    if string.sub(lowered, 1, 4) == "the " then
        name = _trim(string.sub(name, 5))
    end

    name = name:gsub("%s*%.+$", "")
    name = _trim(name)
    if name == nil or name == "" then
        return nil
    end

    return name
end

local function _lookup_named_entry(source, normalized)
    if type(source) ~= "table" or type(normalized) ~= "string" then
        return nil, nil
    end

    local direct = source[normalized]
    if type(direct) == "table" then
        return normalized, direct
    end

    local lowered = string.lower(normalized)
    for key, value in pairs(source) do
        if type(key) == "string" and type(value) == "table" and string.lower(key) == lowered then
            return key, value
        end
    end

    return nil, nil
end

local function _copy_range(range_values)
    if type(range_values) ~= "table" then
        return nil
    end

    local min_value = _to_number(range_values[1], 0)
    local max_value = _to_number(range_values[2], 0)
    if min_value <= 0 and max_value <= 0 then
        return nil
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end

    return { min_value, max_value }
end

local function _append_unique_name(list, value)
    if type(list) ~= "table" or type(value) ~= "string" or value == "" then
        return
    end

    for i = 1, #list do
        if list[i] == value then
            return
        end
    end

    list[#list + 1] = value
end

local function _merge_text_values(current, next_value)
    if type(next_value) ~= "string" or next_value == "" then
        return current
    end
    if type(current) ~= "string" or current == "" then
        return next_value
    end
    if string.lower(current) == string.lower(next_value) then
        return current
    end

    local parts = {}
    local seen = {}

    local function push_parts(source)
        if type(source) ~= "string" then
            return
        end

        for part in string.gmatch(source, "([^/]+)") do
            local candidate = part:gsub("^%s+", ""):gsub("%s+$", "")
            if candidate ~= "" then
                local key = string.lower(candidate)
                if seen[key] ~= true then
                    seen[key] = true
                    parts[#parts + 1] = candidate
                end
            end
        end
    end

    push_parts(current)
    push_parts(next_value)
    return table.concat(parts, " / ")
end

local function _merge_range(dst, field_name, src_value)
    local src_range = _copy_range(src_value)
    if src_range == nil then
        return
    end

    local dst_range = dst[field_name]
    if type(dst_range) ~= "table" then
        dst[field_name] = src_range
        return
    end

    if src_range[1] < dst_range[1] then
        dst_range[1] = src_range[1]
    end
    if src_range[2] > dst_range[2] then
        dst_range[2] = src_range[2]
    end
end

local function _merge_string_map(dst, field_name, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end

    if type(dst[field_name]) ~= "table" then
        dst[field_name] = {}
    end

    local dst_map = dst[field_name]
    for key, value in pairs(src) do
        if type(key) == "string" and type(value) == "string" and value ~= "" and dst_map[key] == nil then
            dst_map[key] = value
        end
    end
end

local function _merge_entry(dst, src, name)
    if type(dst) ~= "table" or type(src) ~= "table" or type(name) ~= "string" then
        return
    end

    if type(src.n) == "string" and src.n ~= "" then
        dst.display_name = src.n
    elseif type(dst.display_name) ~= "string" or dst.display_name == "" then
        dst.display_name = name
    end

    if type(dst.genus) ~= "string" and type(src.g) == "string" and src.g ~= "" then
        dst.genus = src.g
    end
    if type(dst.subcategory) ~= "string" and type(src.s) == "string" and src.s ~= "" then
        dst.subcategory = src.s
    end
    if type(src.sp) == "string" and src.sp ~= "" then
        dst.species = _merge_text_values(dst.species, src.sp)
    elseif type(dst.species) ~= "string" and type(src.s) == "string" and src.s ~= "" then
        dst.species = src.s
    end
    if type(dst.region) ~= "string" and type(src.r) == "string" and src.r ~= "" then
        dst.region = src.r
    end
    if type(dst.area) ~= "string" and type(src.a) == "string" and src.a ~= "" then
        dst.area = src.a
    end
    if type(dst.instance) ~= "string" and type(src.i) == "string" and src.i ~= "" then
        dst.instance = src.i
    end
    if type(src.t) == "string" and src.t ~= "" then
        dst.monster_type = _merge_text_values(dst.monster_type, src.t)
    end

    _merge_range(dst, "static_levels", src.l)
    _merge_range(dst, "static_morale", src.m)
    _merge_range(dst, "static_power", src.p)
    _merge_string_map(dst, "combat_effectiveness", src.ce)
    _merge_string_map(dst, "resistances", src.rs)
    _merge_string_map(dst, "mitigation", src.mi)

    if type(src.w) == "table" then
        for i = 1, #src.w do
            _append_unique_name(dst.w, src.w[i])
        end
    end
    if type(src.cw) == "table" then
        for i = 1, #src.cw do
            _append_unique_name(dst.cw, src.cw[i])
        end
    end
    if type(src.ab) == "table" then
        for i = 1, #src.ab do
            _append_unique_name(dst.abilities, src.ab[i])
        end
    end
    if type(src.qi) == "table" then
        for i = 1, #src.qi do
            _append_unique_name(dst.quest_involvement, src.qi[i])
        end
    end
    if type(src.di) == "table" then
        for i = 1, #src.di do
            _append_unique_name(dst.deed_involvement, src.di[i])
        end
    end

    dst.k = _to_number(dst.k, 0) + _to_number(src.k, 0)

    if type(src.levels) == "table" then
        for level, info in pairs(src.levels) do
            if type(info) == "table" then
                if type(dst.levels[level]) ~= "table" then
                    dst.levels[level] = {
                        m = _to_number(info.m, 0),
                        p = _to_number(info.p, 0),
                    }
                else
                    local level_entry = dst.levels[level]
                    local morale = _to_number(info.m, 0)
                    local power = _to_number(info.p, 0)
                    if morale > _to_number(level_entry.m, 0) then
                        level_entry.m = morale
                    end
                    if power > _to_number(level_entry.p, 0) then
                        level_entry.p = power
                    end
                end
            end
        end
    end

    if type(src.d) == "table" then
        for item_name, count in pairs(src.d) do
            if type(item_name) == "string" then
                dst.d[item_name] = _to_number(dst.d[item_name], 0) + _to_number(count, 0)
            end
        end
    end
end

local function _merged_entry_for_name(name)
    local normalized = _normalize_bestiary_name(name)
    if normalized == nil then
        return nil
    end

    local merged = {
        display_name = normalized,
        genus = nil,
        subcategory = nil,
        species = nil,
        region = nil,
        area = nil,
        instance = nil,
        monster_type = nil,
        static_levels = nil,
        static_morale = nil,
        static_power = nil,
        combat_effectiveness = {},
        resistances = {},
        mitigation = {},
        abilities = {},
        quest_involvement = {},
        deed_involvement = {},
        w = {},
        cw = {},
        levels = {},
        k = 0,
        d = {},
    }

    local resolved_name = normalized
    local builtin_name, builtin = _lookup_named_entry(BUILTIN_BESTIARY, normalized)
    if type(builtin) ~= "table" then
        return nil
    end

    resolved_name = builtin_name or resolved_name
    _merge_entry(merged, builtin, resolved_name)

    local cache = _G.bestiary_cache
    if type(cache) == "table" then
        local cached_name, cached = _lookup_named_entry(cache, normalized)
        if type(cached) == "table" then
            resolved_name = cached_name or resolved_name
            _merge_entry(merged, cached, resolved_name)
        end
    end

    return resolved_name, merged
end

local function _format_number(value)
    local n = math.floor(_to_number(value, 0) + 0.5)
    local text = tostring(math.abs(n))
    local out = {}
    local count = 0
    for i = #text, 1, -1 do
        count = count + 1
        out[#out + 1] = string.sub(text, i, i)
        if count == 3 and i > 1 then
            out[#out + 1] = " "
            count = 0
        end
    end

    local reversed = {}
    for i = #out, 1, -1 do
        reversed[#reversed + 1] = out[i]
    end

    local joined = table.concat(reversed)
    if n < 0 then
        return "-" .. joined
    end
    return joined
end

local function _format_range(min_value, max_value)
    if min_value <= 0 and max_value <= 0 then
        return "-"
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    if min_value == max_value then
        return tostring(min_value)
    end
    return tostring(min_value) .. " - " .. tostring(max_value)
end

local function _format_number_range(min_value, max_value)
    if min_value <= 0 and max_value <= 0 then
        return "-"
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    if min_value == max_value then
        return _format_number(min_value)
    end
    return _format_number(min_value) .. " - " .. _format_number(max_value)
end

local function _build_drop_records(entry)
    local drops = {}
    local kills = _to_number(entry.k, 0)

    local by_name = {}
    local function drop_key(item_name, chest)
        return (chest == true and "c:" or "d:") .. item_name
    end
    if type(entry.w) == "table" then
        for i = 1, #entry.w do
            local item_name = entry.w[i]
            local key = type(item_name) == "string" and drop_key(item_name, false) or nil
            if key ~= nil and item_name ~= "" and by_name[key] == nil then
                by_name[key] = { name = item_name, count = 0, rate = nil, chest = false }
            end
        end
    end
    if type(entry.cw) == "table" then
        for i = 1, #entry.cw do
            local item_name = entry.cw[i]
            local key = type(item_name) == "string" and drop_key(item_name, true) or nil
            if key ~= nil and item_name ~= "" and by_name[key] == nil then
                by_name[key] = { name = item_name, count = 0, rate = nil, chest = true }
            end
        end
    end

    if type(entry.d) == "table" then
        for item_name, count in pairs(entry.d) do
            if type(item_name) == "string" then
                local drop = by_name[drop_key(item_name, false)]
                if type(drop) ~= "table" then
                    drop = { name = item_name, count = 0, rate = nil, chest = false }
                    by_name[drop_key(item_name, false)] = drop
                end

                local n = _to_number(count, 0)
                drop.count = n
                if kills > 0 and n > 0 then
                    drop.rate = (n / kills) * 100
                end
            end
        end
    end

    for _, drop in pairs(by_name) do
        drops[#drops + 1] = drop
    end

    table.sort(drops, function(left, right)
        if (left.chest == true) ~= (right.chest == true) then
            return left.chest ~= true
        end
        local left_has_rate = type(left.rate) == "number"
        local right_has_rate = type(right.rate) == "number"
        if left_has_rate ~= right_has_rate then
            return left_has_rate == true
        end
        if left_has_rate == true and right_has_rate == true and left.rate ~= right.rate then
            return left.rate > right.rate
        end
        return string.lower(left.name) < string.lower(right.name)
    end)

    return drops
end

local function _build_record_for_target(target)
    if target == nil or target.GetName == nil then
        return nil
    end

    local normalized_name, entry = _merged_entry_for_name(target:GetName())
    if normalized_name == nil or type(entry) ~= "table" then
        return nil
    end

    local morale_min = 0
    local morale_max = 0
    local power_min = 0
    local power_max = 0
    local level_min = 0
    local level_max = 0

    if type(entry.static_levels) == "table" then
        level_min = _to_number(entry.static_levels[1], 0)
        level_max = _to_number(entry.static_levels[2], level_min)
    end
    if type(entry.static_morale) == "table" then
        morale_min = _to_number(entry.static_morale[1], 0)
        morale_max = _to_number(entry.static_morale[2], morale_min)
    end
    if type(entry.static_power) == "table" then
        power_min = _to_number(entry.static_power[1], 0)
        power_max = _to_number(entry.static_power[2], power_min)
    end

    if type(entry.levels) == "table" then
        for level, info in pairs(entry.levels) do
            local level_n = _to_number(level, 0)
            if level_n > 0 then
                if level_min <= 0 or level_n < level_min then level_min = level_n end
                if level_n > level_max then level_max = level_n end
            end

            if type(info) == "table" then
                local morale = _to_number(info.m, 0)
                local power = _to_number(info.p, 0)
                if morale > 0 and (morale_min <= 0 or morale < morale_min) then morale_min = morale end
                if morale > morale_max then morale_max = morale end
                if power >= 0 and (power_min <= 0 or power < power_min) then power_min = power end
                if power > power_max then power_max = power end
            end
        end
    end

    local exact_level = target.GetLevel ~= nil and _to_number(target:GetLevel(), 0) or 0
    local exact_morale = target.GetMaxMorale ~= nil and _to_number(target:GetMaxMorale(), 0) or 0
    local exact_power = target.GetMaxPower ~= nil and _to_number(target:GetMaxPower(), 0) or 0

    return {
        key = normalized_name,
        name = type(entry.display_name) == "string" and entry.display_name or normalized_name,
        genus = entry.genus,
        subcategory = entry.subcategory,
        species = entry.species,
        region = entry.region,
        area = entry.area,
        instance = entry.instance,
        type = entry.monster_type,
        level_min = level_min,
        level_max = level_max,
        morale_min = morale_min,
        morale_max = morale_max,
        power_min = power_min,
        power_max = power_max,
        current_level = exact_level,
        current_morale = exact_morale,
        current_power = exact_power,
        combat_effectiveness = entry.combat_effectiveness,
        resistances = entry.resistances,
        mitigation = entry.mitigation,
        abilities = entry.abilities,
        quest_involvement = entry.quest_involvement,
        deed_involvement = entry.deed_involvement,
        drops = _build_drop_records(entry),
    }
end

local function _build_record_for_name(name)
    local normalized_name, entry = _merged_entry_for_name(name)
    if normalized_name == nil or type(entry) ~= "table" then
        return nil
    end

    local morale_min = 0
    local morale_max = 0
    local power_min = 0
    local power_max = 0
    local level_min = 0
    local level_max = 0

    if type(entry.static_levels) == "table" then
        level_min = _to_number(entry.static_levels[1], 0)
        level_max = _to_number(entry.static_levels[2], level_min)
    end
    if type(entry.static_morale) == "table" then
        morale_min = _to_number(entry.static_morale[1], 0)
        morale_max = _to_number(entry.static_morale[2], morale_min)
    end
    if type(entry.static_power) == "table" then
        power_min = _to_number(entry.static_power[1], 0)
        power_max = _to_number(entry.static_power[2], power_min)
    end

    if type(entry.levels) == "table" then
        for level, info in pairs(entry.levels) do
            local level_n = _to_number(level, 0)
            if level_n > 0 then
                if level_min <= 0 or level_n < level_min then level_min = level_n end
                if level_n > level_max then level_max = level_n end
            end

            if type(info) == "table" then
                local morale = _to_number(info.m, 0)
                local power = _to_number(info.p, 0)
                if morale > 0 and (morale_min <= 0 or morale < morale_min) then morale_min = morale end
                if morale > morale_max then morale_max = morale end
                if power >= 0 and (power_min <= 0 or power < power_min) then power_min = power end
                if power > power_max then power_max = power end
            end
        end
    end

    return {
        key = normalized_name,
        name = type(entry.display_name) == "string" and entry.display_name or normalized_name,
        genus = entry.genus,
        subcategory = entry.subcategory,
        species = entry.species,
        region = entry.region,
        area = entry.area,
        instance = entry.instance,
        type = entry.monster_type,
        level_min = level_min,
        level_max = level_max,
        morale_min = morale_min,
        morale_max = morale_max,
        power_min = power_min,
        power_max = power_max,
        current_level = 0,
        current_morale = 0,
        current_power = 0,
        combat_effectiveness = entry.combat_effectiveness,
        resistances = entry.resistances,
        mitigation = entry.mitigation,
        abilities = entry.abilities,
        quest_involvement = entry.quest_involvement,
        deed_involvement = entry.deed_involvement,
        drops = _build_drop_records(entry),
    }
end

local function _append_value(lines, label, value)
    if type(lines) ~= "table" then
        return
    end
    if type(value) ~= "string" or value == "" then
        value = "-"
    end
    lines[#lines + 1] = label .. ": " .. value
end

local function _append_section(lines, heading, values)
    if type(lines) ~= "table" or type(values) ~= "table" or #values == 0 then
        return
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = heading .. ":"
    for i = 1, #values do
        lines[#lines + 1] = "- " .. values[i]
    end
end

local function _append_named_section(lines, heading, values, field_order)
    if type(lines) ~= "table" or type(values) ~= "table" or type(field_order) ~= "table" then
        return
    end

    local has_any = false
    for i = 1, #field_order do
        local info = field_order[i]
        if type(values[info.key]) == "string" and values[info.key] ~= "" then
            has_any = true
            break
        end
    end
    if has_any ~= true then
        return
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = heading .. ":"
    for i = 1, #field_order do
        local info = field_order[i]
        _append_value(lines, info.label, values[info.key])
    end
end

local function _display_text(value)
    if type(value) ~= "string" or value == "" then
        return "-"
    end
    return value
end

local function _format_percent(percent)
    local value = _to_number(percent, 0)
    local text
    if value >= 1 then
        text = string.format("%.1f", value)
    else
        text = string.format("%.2f", value)
    end

    text = text:gsub("(%..-)0+$", "%1")
    text = text:gsub("%.$", "")
    return text .. "%"
end

local function _has_visible_range(min_value, max_value)
    min_value = _to_number(min_value, 0)
    max_value = _to_number(max_value, 0)
    if min_value <= 0 and max_value <= 0 then
        return false
    end
    if min_value <= 0 then
        min_value = max_value
    end
    if max_value <= 0 then
        max_value = min_value
    end
    return min_value ~= max_value
end

local function _format_level_text(record)
    if _has_visible_range(record.level_min, record.level_max) == true then
        return _format_range(record.level_min, record.level_max)
    end
    if _to_number(record.current_level, 0) > 0 then
        return tostring(record.current_level)
    end
    return _format_range(record.level_min, record.level_max)
end

local function _format_morale_text(record)
    if _has_visible_range(record.morale_min, record.morale_max) == true then
        return _format_number_range(record.morale_min, record.morale_max)
    end
    if _to_number(record.current_morale, 0) > 0 then
        return _format_number(record.current_morale)
    end
    return _format_number_range(record.morale_min, record.morale_max)
end

local function _format_power_text(record)
    if _has_visible_range(record.power_min, record.power_max) == true then
        return _format_number_range(record.power_min, record.power_max)
    end
    if _to_number(record.current_power, 0) > 0 then
        return _format_number(record.current_power)
    end
    return _format_number_range(record.power_min, record.power_max)
end

local LOCATION_FIELDS = {
    { key = "region", label = TR("Region") },
    { key = "area", label = TR("Area") },
    { key = "instance", label = TR("Instance") },
}

local CREATURE_FIELDS = {
    { key = "type", label = TR("Type") },
    { key = "genus", label = TR("Genus") },
    { key = "species", label = TR("Species") },
}

local COMBAT_FIELDS = {
    { key = "f", label = TR("Finesse") },
    { key = "fm", label = TR("F.M. Immune") },
    { key = "sm", label = TR("Stun/Mez Imm.") },
    { key = "rt", label = TR("Root Immune") },
}

local RESISTANCE_FIELDS = {
    { key = "cr", label = TR("Cry") },
    { key = "so", label = TR("Song") },
    { key = "ta", label = TR("Tactical") },
    { key = "ph", label = TR("Physical") },
}

local MITIGATION_LEFT_FIELDS = {
    { key = "co", label = TR("Common") },
    { key = "fi", label = TR("Fire") },
    { key = "li", label = TR("Light") },
    { key = "sh", label = TR("Shadow") },
    { key = "lt", label = TR("Lightning") },
}

local MITIGATION_RIGHT_FIELDS = {
    { key = "ad", label = TR("Ancient Dwarf") },
    { key = "be", label = TR("Beleriand") },
    { key = "we", label = TR("Westernesse") },
    { key = "fr", label = TR("Frost") },
}

local function _build_list_text(values)
    if type(values) ~= "table" or #values == 0 then
        return "-"
    end

    local lines = {}
    for i = 1, #values do
        lines[#lines + 1] = "- " .. values[i]
    end
    return table.concat(lines, "\n")
end

local function _build_drop_texts(record)
    local texts = {}

    if type(record) == "table" and type(record.drops) == "table" then
        for i = 1, #record.drops do
            local drop = record.drops[i]
            if type(drop) == "table" and type(drop.name) == "string" and drop.name ~= "" then
                local text
                if type(drop.rate) == "number" then
                    text = drop.name .. ": " .. _format_percent(drop.rate)
                else
                    text = drop.name
                end
                texts[#texts + 1] = { text = text, chest = drop.chest == true }
            end
        end
    end

    if #texts == 0 then
        texts[1] = { text = TR("No drops seen."), chest = false }
    end

    return texts
end

local function _estimate_text_width(text, base_char_w)
    return math.floor((string.len(text or "") * base_char_w * _G.settings.global.scale) + 0.5)
end

local function _estimate_font_text_width(text, font_size)
    local scaled_char_w = BASE_TEXT_CHAR_W * (font_size / BASE_TEXT_SIZE)
    return _estimate_text_width(text, scaled_char_w)
end

local function _choose_stat_font_size(text, max_width)
    local sizes = { BASE_TITLE_SIZE, 18, 16, 14, 13 }
    local usable_w = math.max(1, max_width)

    for i = 1, #sizes do
        if _estimate_font_text_width(text, sizes[i]) <= usable_w then
            return sizes[i]
        end
    end

    return sizes[#sizes]
end

local function _estimate_wrapped_line_count(text, max_width)
    if type(text) ~= "string" or text == "" then
        return 1
    end

    max_width = math.max(1, max_width)
    local line_count = 0

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        if line == "" then
            line_count = line_count + 1
        else
            local width = _estimate_text_width(line, BASE_TEXT_CHAR_W)
            line_count = line_count + math.max(1, math.ceil(width / max_width))
        end
    end

    return math.max(1, line_count)
end

local function _estimate_chip_width(text)
    local pad_x = _scaled_int(BASE_CHIP_PAD_X)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    return _estimate_text_width(text or "", BASE_CHIP_CHAR_W) + (2 * pad_x) + (2 * border_w)
end

local function _build_chip_layout(texts, max_width)
    local layout = {}
    local chip_h = _scaled_int(BASE_CHIP_H)
    local gap_x = _scaled_int(BASE_CHIP_GAP_X)
    local gap_y = _scaled_int(BASE_CHIP_GAP_Y)
    local x = 0
    local y = 0

    for i = 1, #texts do
        local item = texts[i]
        local text = type(item) == "table" and item.text or item
        local width = _estimate_chip_width(text)
        if width > max_width then
            width = max_width
        end

        if x > 0 and (x + width) > max_width then
            x = 0
            y = y + chip_h + gap_y
        end

        layout[#layout + 1] = {
            text = text,
            chest = type(item) == "table" and item.chest == true,
            x = x,
            y = y,
            w = width,
        }

        x = x + width + gap_x
    end

    if #layout == 0 then
        return layout, chip_h
    end

    return layout, y + chip_h
end

local function _create_text(parent, multiline, alignment)
    local text = Turbine.UI.TextBox()
    text:SetParent(parent)
    text:SetMouseVisible(false)
    text:SetReadOnly(true)
    text:SetSelectable(false)
    text:SetMultiline(multiline == true)
    text:SetTextAlignment(alignment or Turbine.UI.ContentAlignment.TopLeft)
    return text
end

local function _apply_scroll_label_style(area)
    if area == nil or area.label == nil then
        return
    end

    if type(area.font_name) ~= "string" or type(area.font_size) ~= "number" or area.color == nil then
        return
    end

    area.label:SetFont(_scaled_font(area.font_name, area.font_size))
    area.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    area.label:SetOutlineColor(COLOR_OUTLINE)
    area.label:SetForeColor(area.color)
end

local function _create_scroll_label_area(parent)
    local area = {
        text = "-",
        uses_scroll = false,
        font_name = nil,
        font_size = nil,
        color = nil,
    }

    if parent ~= nil and parent.SetMouseVisible ~= nil then
        parent:SetMouseVisible(true)
    end

    area.label = Turbine.UI.Label()
    area.label:SetParent(parent)
    area.label:SetMouseVisible(true)
    area.label:SetSelectable(false)
    area.label:SetMultiline(true)
    area.label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    area.label:SetSelectable(true)

    area.scroll = Turbine.UI.Lotro.ScrollBar()
    area.scroll:SetParent(area.label)
    area.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    area.scroll:SetWidth(BASE_SCROLL_W)
    area.scroll:SetPosition(area.scroll:GetWidth() - BASE_SCROLL_W, 0);
	area.scroll:SetHeight(area.scroll:GetHeight() - 2);
    area.scroll:SetMouseVisible(true)
    area.label:SetVerticalScrollBar(area.scroll)
    area.scroll:SetVisible(false)

    area.label.FocusGained = function(s, a)
        parent:Focus()
    end

    _apply_scroll_label_style(area)
    area.label:SetText(area.text or "-")

    return area
end

local function _style_scroll_label_area(area, font_name, font_size, color)
    if area == nil then
        return
    end

    area.font_name = font_name
    area.font_size = font_size
    area.color = color
    _apply_scroll_label_style(area)
end

local function _bind_scroll_label_area(area, values)
    if area == nil or area.label == nil then
        return
    end

    area.label:SetVerticalScrollBar(nil)
    area.text = _build_list_text(values)
    area.label:SetText(area.text)
    area.label:SetVerticalScrollBar(area.scroll)
end

local function _measure_scroll_label_panel(panel_w, text)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local header_h = _scaled_int(BASE_PANEL_HEADER_H)
    local min_h = _scaled_int(BASE_NOTES_MIN_H)
    local max_h = _scaled_int(BASE_DROP_MAX_H)
    local scroll_gap = _scaled_int(BASE_SCROLL_GAP)
    local line_h = _scaled_int(BASE_TEXT_LINE_H)

    local function build(use_scroll)
        local reserved_w = use_scroll == true and (BASE_SCROLL_W + scroll_gap) or 0
        local usable_w = math.max(1, panel_w - 2 - (2 * body_pad_x) - reserved_w)
        local line_count = _estimate_wrapped_line_count(text, usable_w)
        local text_h = math.max(line_h, line_count * line_h)
        local frame_h = header_h + 2 + body_pad_t + body_pad_b + text_h
        local panel_h = math.max(min_h, math.min(max_h, frame_h))
        local viewport_h = math.max(1, panel_h - header_h - 2 - body_pad_t - body_pad_b)
        return panel_h, text_h > viewport_h
    end

    local panel_h, uses_scroll = build(false)
    if uses_scroll == true then
        panel_h, uses_scroll = build(true)
    end

    return panel_h, uses_scroll
end

local function _style_text(text, font_name, font_size, color)
    text:SetFont(_scaled_font(font_name, font_size))
    text:SetFontStyle(Turbine.UI.FontStyle.Outline)
    text:SetOutlineColor(COLOR_OUTLINE)
    text:SetForeColor(color)
end

local function _create_panel(parent, title_text)
    local panel = {}
    panel.frame = Turbine.UI.Control()
    panel.frame:SetParent(parent)
    panel.frame:SetMouseVisible(false)
    panel.header = Turbine.UI.Control()
    panel.header:SetParent(panel.frame)
    panel.header:SetMouseVisible(false)
    panel.body = Turbine.UI.Control()
    panel.body:SetParent(panel.frame)
    panel.body:SetMouseVisible(false)
    panel.title = _create_text(panel.header, false, Turbine.UI.ContentAlignment.MiddleLeft)
    panel.title:SetText(title_text or "")
    return panel
end

local function _style_panel(panel)
    panel.frame:SetBackColor(COLOR_PANEL_BORDER)
    panel.header:SetBackColor(COLOR_PANEL_HEADER)
    panel.body:SetBackColor(COLOR_PANEL_BG)
    _style_text(panel.title, "Verdana", BASE_SECTION_TITLE_SIZE, COLOR_TITLE)
end

local function _create_row_set(parent, field_order)
    local rows = {}
    for i = 1, #field_order do
        local row = {
            key = field_order[i].key,
            label = _create_text(parent, false, Turbine.UI.ContentAlignment.MiddleLeft),
            value = _create_text(parent, false, Turbine.UI.ContentAlignment.MiddleRight),
        }
        row.label:SetText(field_order[i].label .. ":")
        rows[#rows + 1] = row
    end
    return rows
end

local function _style_row_set(rows, value_color)
    for i = 1, #rows do
        _style_text(rows[i].label, "Verdana", BASE_TEXT_SIZE, COLOR_LABEL)
        _style_text(rows[i].value, "Verdana", BASE_TEXT_SIZE, value_color or COLOR_VALUE)
    end
end

local function _layout_row_set(rows, x, y, w, h, label_ratio)
    if type(rows) ~= "table" or #rows == 0 then
        return
    end

    local gap = _scaled_int(6)
    local row_h = math.max(_scaled_int(14), math.floor(h / #rows))
    local label_w = math.max(1, math.floor(w * label_ratio))
    local value_w = math.max(1, w - label_w - gap)

    for i = 1, #rows do
        local ry = y + ((i - 1) * row_h)
        rows[i].label:SetPosition(x, ry)
        rows[i].label:SetSize(label_w, row_h)
        rows[i].value:SetPosition(x + label_w + gap, ry)
        rows[i].value:SetSize(value_w, row_h)
    end
end

local function _layout_parallel_row_sets(left_rows, right_rows, x_left, x_right, y, w_left, w_right, h,
    left_label_ratio, right_label_ratio)
    local left_count = type(left_rows) == "table" and #left_rows or 0
    local right_count = type(right_rows) == "table" and #right_rows or 0
    local row_count = math.max(left_count, right_count)

    if row_count <= 0 then
        return
    end

    local gap = _scaled_int(6)
    local row_h = math.max(_scaled_int(14), math.floor(h / row_count))

    local function layout_rows(rows, x, w, label_ratio)
        if type(rows) ~= "table" or #rows == 0 then
            return
        end

        local label_w = math.max(1, math.floor(w * label_ratio))
        local value_w = math.max(1, w - label_w - gap)

        for i = 1, #rows do
            local ry = y + ((i - 1) * row_h)
            rows[i].label:SetPosition(x, ry)
            rows[i].label:SetSize(label_w, row_h)
            rows[i].value:SetPosition(x + label_w + gap, ry)
            rows[i].value:SetSize(value_w, row_h)
        end
    end

    layout_rows(left_rows, x_left, w_left, left_label_ratio)
    layout_rows(right_rows, x_right, w_right, right_label_ratio)
end

local function _bind_row_set(rows, values)
    for i = 1, #rows do
        local value = "-"
        if type(values) == "table" then
            value = _display_text(values[rows[i].key])
        end
        rows[i].value:SetText(value)
    end
end

local DropChip = class(Turbine.UI.Control)

function DropChip:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBackColor(COLOR_DROP_CHIP_BORDER)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(COLOR_DROP_CHIP_BG)

    self.label = Turbine.UI.TextBox()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetReadOnly(true)
    self.label:SetSelectable(false)
    self.label:SetMultiline(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
end

function DropChip:apply_settings(chest)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    self.inner:SetPosition(border_w, border_w)
    if chest == true then
        self:SetBackColor(COLOR_CHEST_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_CHEST_CHIP_BG)
        _style_text(self.label, "Verdana", BASE_TEXT_SIZE, COLOR_CHEST_CHIP_TEXT)
    else
        self:SetBackColor(COLOR_DROP_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_DROP_CHIP_BG)
        _style_text(self.label, "Verdana", BASE_TEXT_SIZE, COLOR_DROP_CHIP_TEXT)
    end
end

function DropChip:bind(text, width, height)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    local pad_x = _scaled_int(BASE_CHIP_PAD_X)

    self:SetSize(width, height)
    self.inner:SetSize(math.max(1, width - (2 * border_w)), math.max(1, height - (2 * border_w)))
    self.label:SetPosition(pad_x, 0)
    self.label:SetSize(math.max(1, self.inner:GetWidth() - (2 * pad_x)), self.inner:GetHeight())
    self.label:SetText(text or "")
    self:SetVisible(true)
end

BestiaryCard = class(Turbine.UI.Lotro.Window)
Bestiary.BestiaryCard = BestiaryCard

local function _card_window_settings(create)
    local root = _G.loaded_settings
    if type(root) ~= "table" then
        return nil
    end

    if type(root.bestiary) ~= "table" then
        if create ~= true then
            return nil
        end
        root.bestiary = {}
    end

    if type(root.bestiary.card_window) ~= "table" then
        if create ~= true then
            return nil
        end
        root.bestiary.card_window = {}
    end

    return root.bestiary.card_window
end

function BestiaryCard:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self.current_key = nil
    self.current_record = nil
    self.drop_chips = {}
    self.drop_panel_h = _scaled_int(BASE_DROP_MIN_H)
    self.drop_layout = {}
    self.drop_content_h = _scaled_int(BASE_CHIP_H)
    self.drop_uses_scroll = false
    self.abilities_area = nil
    self.quests_area = nil
    self.deeds_area = nil
    self.sticky_position = false
    self._suppress_position_persist = false

    self:SetText(TR("Bestiary"))
    self:SetVisible(false)
    self:SetResizable(false)
    self:SetMouseVisible(true)
    self:SetWantsKeyEvents(true)
    -- self.KeyDown = function(_, args)
    --     if args.Action == Turbine.UI.Lotro.Action.Escape then
    --         self:close()
    --     end
    -- end

    self.content = Turbine.UI.Control()
    self.content:SetParent(self)
    self.content:SetMouseVisible(false)

    self.level_panel = _create_panel(self.content, TR("Level"))
    self.level_value = _create_text(self.level_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.morale_panel = _create_panel(self.content, TR("Morale"))
    self.morale_value = _create_text(self.morale_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.power_panel = _create_panel(self.content, TR("Power"))
    self.power_value = _create_text(self.power_panel.body, false, Turbine.UI.ContentAlignment.MiddleCenter)

    self.location_panel = _create_panel(self.content, TR("Location"))
    self.location_rows = _create_row_set(self.location_panel.body, LOCATION_FIELDS)

    self.creature_panel = _create_panel(self.content, TR("Creature"))
    self.creature_rows = _create_row_set(self.creature_panel.body, CREATURE_FIELDS)

    self.drop_panel = _create_panel(self.content, TR("Drops"))
    self.drop_list = Turbine.UI.ListBox()
    self.drop_list:SetParent(self.drop_panel.body)
    self.drop_list:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.drop_scroll = Turbine.UI.Lotro.ScrollBar()
    self.drop_scroll:SetParent(self.drop_panel.body)
    self.drop_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.drop_scroll:SetWidth(BASE_SCROLL_W)
    self.drop_list:SetVerticalScrollBar(self.drop_scroll)
    self.drop_scroll:SetVisible(false)
    self.drop_content = Turbine.UI.Control()
    self.drop_content:SetMouseVisible(false)
    self.drop_list:AddItem(self.drop_content)

    self.combat_panel = _create_panel(self.content, TR("Combat Effectiveness"))
    self.combat_rows = _create_row_set(self.combat_panel.body, COMBAT_FIELDS)

    self.resistances_panel = _create_panel(self.content, TR("Resistances"))
    self.resistance_rows = _create_row_set(self.resistances_panel.body, RESISTANCE_FIELDS)

    self.mitigation_panel = _create_panel(self.content, TR("Mitigation"))
    self.mitigation_left_rows = _create_row_set(self.mitigation_panel.body, MITIGATION_LEFT_FIELDS)
    self.mitigation_right_rows = _create_row_set(self.mitigation_panel.body, MITIGATION_RIGHT_FIELDS)
    self.mitigation_divider = Turbine.UI.Control()
    self.mitigation_divider:SetParent(self.mitigation_panel.body)
    self.mitigation_divider:SetMouseVisible(false)

    self.abilities_panel = _create_panel(self.content, TR("Abilities"))
    self.abilities_area = _create_scroll_label_area(self.abilities_panel.body)

    self.quests_panel = _create_panel(self.content, TR("Quests"))
    self.quests_area = _create_scroll_label_area(self.quests_panel.body)

    self.deeds_panel = _create_panel(self.content, TR("Deeds"))
    self.deeds_area = _create_scroll_label_area(self.deeds_panel.body)

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:_clamp_to_display()
            self:_persist_current_position()
        else
            self.current_key = nil
        end
    end
    self.PositionChanged = function()
        if self._suppress_position_persist == true or self:IsVisible() ~= true then
            return
        end
        self.sticky_position = true
        self:_persist_current_position()
    end

    self:apply_settings()
end

function BestiaryCard:_ensure_drop_chip_count(count)
    while #self.drop_chips < count do
        local chip = DropChip()
        chip:SetParent(self.drop_content)
        chip:SetVisible(false)
        self.drop_chips[#self.drop_chips + 1] = chip
    end
end

function BestiaryCard:_layout_panel(panel, x, y, w, h)
    local header_h = _scaled_int(BASE_PANEL_HEADER_H)

    panel.frame:SetPosition(x, y)
    panel.frame:SetSize(w, h)
    panel.header:SetPosition(1, 1)
    panel.header:SetSize(math.max(1, w - 2), header_h)
    panel.body:SetPosition(1, header_h + 1)
    panel.body:SetSize(math.max(1, w - 2), math.max(1, h - header_h - 2))
    panel.title:SetPosition(_scaled_int(9), 0)
    panel.title:SetSize(math.max(1, panel.header:GetWidth() - _scaled_int(18)), header_h)
end

function BestiaryCard:_measure_viewport_width()
    local margin_l = _scaled_int(12)
    local margin_r = _scaled_int(12)

    return math.max(1, self:GetWidth() - margin_l - margin_r)
end

function BestiaryCard:_measure_bottom_height()
    local content_w = self:_measure_viewport_width()
    local gap = _scaled_int(BASE_SECTION_GAP)
    local col_w = math.max(1, math.floor((content_w - (2 * gap)) / 3))
    local col_x3 = (col_w * 2) + (gap * 2)
    local last_w = math.max(1, content_w - col_x3)

    local abilities_h, abilities_scroll = _measure_scroll_label_panel(
        col_w,
        self.abilities_area ~= nil and self.abilities_area.text or "-"
    )
    local quests_h, quests_scroll = _measure_scroll_label_panel(
        col_w,
        self.quests_area ~= nil and self.quests_area.text or "-"
    )
    local deeds_h, deeds_scroll = _measure_scroll_label_panel(
        last_w,
        self.deeds_area ~= nil and self.deeds_area.text or "-"
    )

    if self.abilities_area ~= nil then
        self.abilities_area.uses_scroll = abilities_scroll == true
    end
    if self.quests_area ~= nil then
        self.quests_area.uses_scroll = quests_scroll == true
    end
    if self.deeds_area ~= nil then
        self.deeds_area.uses_scroll = deeds_scroll == true
    end

    return math.max(_scaled_int(BASE_NOTES_MIN_H), abilities_h, quests_h, deeds_h)
end

function BestiaryCard:_layout_scroll_label_panel(panel, area)
    if panel == nil or area == nil then
        return
    end

    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local label_w = math.max(1, panel.body:GetWidth() - (2 * body_pad_x))
    local label_h = math.max(1, panel.body:GetHeight() - body_pad_t - body_pad_b)

    area.label:SetPosition(body_pad_x, body_pad_t)
    area.label:SetSize(label_w, label_h)

    area.scroll:SetPosition(math.max(0, label_w - BASE_SCROLL_W), 0)
    area.scroll:SetWidth(BASE_SCROLL_W)
    area.scroll:SetHeight(math.max(1, label_h - 2))
    area.scroll:SetVisible(area.uses_scroll == true)
end

function BestiaryCard:_measure_content_height()
    local gap = _scaled_int(BASE_SECTION_GAP)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)
    local profile_h = _scaled_int(BASE_PROFILE_H)
    local pair_h = _scaled_int(BASE_TWO_COL_H)
    local mitigation_h = _scaled_int(BASE_MITIGATION_H)
    local bottom_h = self:_measure_bottom_height()

    return stat_h + gap + profile_h + gap + self.drop_panel_h + gap + pair_h + gap + mitigation_h + gap + bottom_h
end

function BestiaryCard:_measure_drop_layout(drop_texts)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local header_h = _scaled_int(BASE_PANEL_HEADER_H)
    local min_h = _scaled_int(BASE_DROP_MIN_H)
    local max_h = _scaled_int(BASE_DROP_MAX_H)
    local scroll_gap = _scaled_int(BASE_SCROLL_GAP)
    local scroll_w = BASE_SCROLL_W
    local panel_body_w = math.max(1, self:_measure_viewport_width() - 2 - (2 * body_pad_x))

    local function build(use_scroll)
        local reserved_w = use_scroll == true and (scroll_w + scroll_gap) or 0
        local usable_w = math.max(1, panel_body_w - reserved_w)
        local layout, chip_content_h = _build_chip_layout(drop_texts, usable_w)
        local frame_h = header_h + 2 + body_pad_t + body_pad_b + chip_content_h
        local panel_h = math.max(min_h, math.min(max_h, frame_h))
        local viewport_h = math.max(1, panel_h - header_h - 2 - body_pad_t - body_pad_b)
        return layout, chip_content_h, panel_h, viewport_h
    end

    local layout, chip_content_h, panel_h, viewport_h = build(false)
    local use_scroll = chip_content_h > viewport_h
    if use_scroll == true then
        layout, chip_content_h, panel_h, viewport_h = build(true)
    end

    return layout, chip_content_h, panel_h, viewport_h, use_scroll
end

function BestiaryCard:_clamp_to_display()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left, top = self:GetPosition()
    local width = self:GetWidth()
    local height = self:GetHeight()

    if width > display_w then
        width = math.max(1, display_w)
    end
    if height > display_h then
        height = math.max(1, display_h)
    end

    if left + width > display_w then
        left = display_w - width
    end
    if top + height > display_h then
        top = display_h - height
    end
    if left < 0 then
        left = 0
    end
    if top < 0 then
        top = 0
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
end

function BestiaryCard:_persist_current_position()
    local window = _card_window_settings(true)
    if type(window) ~= "table" then
        return
    end

    local left, top = self:GetPosition()
    window.left = left
    window.top = top
end

function BestiaryCard:_restore_saved_position()
    local window = _card_window_settings(false)
    if type(window) ~= "table" then
        return false
    end

    local left = window.left
    local top = window.top
    if type(left) ~= "number" or type(top) ~= "number" then
        return false
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
    return true
end

function BestiaryCard:_fit_window_height()
    local margin_t = _scaled_int(36)
    local margin_b = _scaled_int(12)
    local min_h = _scaled_int(BASE_HEIGHT)
    local offset = _scaled_int(BASE_OFFSET)
    local _, display_h = Turbine.UI.Display.GetSize()
    local max_h = math.max(min_h, display_h - (2 * offset))
    local desired_h = margin_t + margin_b + self:_measure_content_height()
    local target_h = math.max(min_h, math.min(max_h, desired_h))

    self:SetSize(_scaled_int(BASE_WIDTH), target_h)
    self:_clamp_to_display()
end

function BestiaryCard:_layout_content()
    local margin_l = _scaled_int(12)
    local margin_t = _scaled_int(36)
    local margin_r = _scaled_int(12)
    local margin_b = _scaled_int(12)
    local gap = _scaled_int(BASE_SECTION_GAP)
    local body_pad_x = _scaled_int(BASE_PANEL_BODY_PAD_X)
    local body_pad_t = _scaled_int(BASE_PANEL_BODY_PAD_TOP)
    local body_pad_b = _scaled_int(BASE_PANEL_BODY_PAD_BOTTOM)
    local stat_h = _scaled_int(BASE_STAT_BOX_H)
    local profile_h = _scaled_int(BASE_PROFILE_H)
    local pair_h = _scaled_int(BASE_TWO_COL_H)
    local mitigation_h = _scaled_int(BASE_MITIGATION_H)
    local bottom_h = self:_measure_bottom_height()

    local content_w = math.max(1, self:GetWidth() - margin_l - margin_r)
    local content_h = math.max(1, self:GetHeight() - margin_t - margin_b)

    self.content:SetPosition(margin_l, margin_t)
    self.content:SetSize(content_w, content_h)

    local y = 0
    local stat_total_w = math.max(1, content_w - (2 * gap))
    local level_w = math.max(1, math.floor(stat_total_w * 0.28))
    local morale_w = math.max(1, math.floor(stat_total_w * 0.36))
    local power_w = math.max(1, stat_total_w - level_w - morale_w)
    local morale_x = level_w + gap
    local power_x = morale_x + morale_w + gap

    local bottom_col_w = math.max(1, math.floor((content_w - (2 * gap)) / 3))
    local bottom_x2 = bottom_col_w + gap
    local bottom_x3 = (bottom_col_w * 2) + (gap * 2)
    local bottom_last_w = math.max(1, content_w - bottom_x3)

    self:_layout_panel(self.level_panel, 0, y, level_w, stat_h)
    self:_layout_panel(self.morale_panel, morale_x, y, morale_w, stat_h)
    self:_layout_panel(self.power_panel, power_x, y, power_w, stat_h)

    y = y + stat_h + gap
    local half_w = math.max(1, math.floor((content_w - gap) / 2))
    local right_x = half_w + gap
    local right_w = math.max(1, content_w - right_x)
    self:_layout_panel(self.location_panel, 0, y, half_w, profile_h)
    self:_layout_panel(self.creature_panel, right_x, y, right_w, profile_h)

    y = y + profile_h + gap
    self:_layout_panel(self.drop_panel, 0, y, content_w, self.drop_panel_h)

    local drop_scroll_gap = self.drop_uses_scroll == true and _scaled_int(BASE_SCROLL_GAP) or 0
    local drop_scroll_w = self.drop_uses_scroll == true and BASE_SCROLL_W or 0
    local drop_list_w = math.max(1, self.drop_panel.body:GetWidth() - (2 * body_pad_x) - drop_scroll_gap - drop_scroll_w)
    local drop_list_h = math.max(1, self.drop_panel.body:GetHeight() - body_pad_t - body_pad_b)

    self.drop_list:SetPosition(body_pad_x, body_pad_t)
    self.drop_list:SetSize(drop_list_w, drop_list_h)

    self.drop_scroll:SetPosition(body_pad_x + drop_list_w + drop_scroll_gap, body_pad_t)
    self.drop_scroll:SetWidth(BASE_SCROLL_W)
    self.drop_scroll:SetHeight(drop_list_h)
    self.drop_scroll:SetVisible(self.drop_uses_scroll == true)

    y = y + self.drop_panel_h + gap
    self:_layout_panel(self.combat_panel, 0, y, half_w, pair_h)
    self:_layout_panel(self.resistances_panel, right_x, y, right_w, pair_h)

    y = y + pair_h + gap
    self:_layout_panel(self.mitigation_panel, 0, y, content_w, mitigation_h)

    y = y + mitigation_h + gap
    self:_layout_panel(self.abilities_panel, 0, y, bottom_col_w, bottom_h)
    self:_layout_panel(self.quests_panel, bottom_x2, y, bottom_col_w, bottom_h)
    self:_layout_panel(self.deeds_panel, bottom_x3, y, bottom_last_w, bottom_h)

    self.level_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.level_value:SetSize(math.max(1, self.level_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.level_panel.body:GetHeight() - _scaled_int(6)))
    self.morale_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.morale_value:SetSize(math.max(1, self.morale_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.morale_panel.body:GetHeight() - _scaled_int(6)))
    self.power_value:SetPosition(_scaled_int(8), _scaled_int(3))
    self.power_value:SetSize(math.max(1, self.power_panel.body:GetWidth() - _scaled_int(16)),
        math.max(1, self.power_panel.body:GetHeight() - _scaled_int(6)))

    _style_text(
        self.level_value,
        "Verdana",
        _choose_stat_font_size(self.level_value:GetText(), self.level_value:GetWidth()),
        Turbine.UI.Color(1, 0.72, 0.58, 0.20)
    )
    _style_text(
        self.morale_value,
        "Verdana",
        _choose_stat_font_size(self.morale_value:GetText(), self.morale_value:GetWidth()),
        Turbine.UI.Color(1, 0.42, 0.86, 0.44)
    )
    _style_text(
        self.power_value,
        "Verdana",
        _choose_stat_font_size(self.power_value:GetText(), self.power_value:GetWidth()),
        Turbine.UI.Color(1, 0.40, 0.68, 0.96)
    )

    _layout_parallel_row_sets(
        self.location_rows,
        self.creature_rows,
        body_pad_x,
        body_pad_x,
        body_pad_t,
        math.max(1, self.location_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, self.creature_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, math.min(
            self.location_panel.body:GetHeight() - body_pad_t - body_pad_b,
            self.creature_panel.body:GetHeight() - body_pad_t - body_pad_b
        )),
        0.38,
        0.38
    )
    _layout_parallel_row_sets(
        self.combat_rows,
        self.resistance_rows,
        body_pad_x,
        body_pad_x,
        body_pad_t,
        math.max(1, self.combat_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, self.resistances_panel.body:GetWidth() - (2 * body_pad_x)),
        math.max(1, math.min(
            self.combat_panel.body:GetHeight() - body_pad_t - body_pad_b,
            self.resistances_panel.body:GetHeight() - body_pad_t - body_pad_b
        )),
        0.56,
        0.48
    )

    local mitigation_gap = gap + _scaled_int(8)
    local mitigation_body_w = math.max(1, self.mitigation_panel.body:GetWidth() - (2 * body_pad_x))
    local mitigation_col_w = math.max(1, math.floor((mitigation_body_w - mitigation_gap) / 2))
    local mitigation_right_x = body_pad_x + mitigation_col_w + mitigation_gap
    local mitigation_right_w = math.max(1, mitigation_body_w - mitigation_col_w - mitigation_gap)
    local mitigation_body_h = math.max(1, self.mitigation_panel.body:GetHeight() - body_pad_t - body_pad_b)
    local mitigation_divider_w = 1
    local mitigation_divider_x = body_pad_x + mitigation_col_w + math.floor((mitigation_gap - mitigation_divider_w) / 2)
    self.mitigation_divider:SetPosition(mitigation_divider_x, body_pad_t)
    self.mitigation_divider:SetSize(mitigation_divider_w, mitigation_body_h)
    _layout_parallel_row_sets(
        self.mitigation_left_rows,
        self.mitigation_right_rows,
        body_pad_x,
        mitigation_right_x,
        body_pad_t,
        mitigation_col_w,
        mitigation_right_w,
        mitigation_body_h,
        0.52,
        0.56
    )

    self:_layout_scroll_label_panel(self.abilities_panel, self.abilities_area)
    self:_layout_scroll_label_panel(self.quests_panel, self.quests_area)
    self:_layout_scroll_label_panel(self.deeds_panel, self.deeds_area)
end

function BestiaryCard:_apply_drop_layout(drop_texts)
    local layout, chip_content_h, panel_h, _, use_scroll = self:_measure_drop_layout(drop_texts)
    self.drop_panel_h = panel_h
    self.drop_layout = layout
    self.drop_content_h = chip_content_h
    self.drop_uses_scroll = use_scroll == true

    self:_fit_window_height()
    self:_layout_content()
    self:_ensure_drop_chip_count(#layout)

    local chip_h = _scaled_int(BASE_CHIP_H)
    self.drop_content:SetSize(self.drop_list:GetWidth(), math.max(self.drop_list:GetHeight(), chip_content_h))
    if self.drop_list ~= nil and self.drop_list.ClearItems ~= nil and self.drop_list.AddItem ~= nil then
        self.drop_list:ClearItems()
        self.drop_list:AddItem(self.drop_content)
    end

    for i = 1, #layout do
        local chip_info = layout[i]
        local chip = self.drop_chips[i]
        chip:apply_settings(chip_info.chest == true)
        chip:SetPosition(chip_info.x, chip_info.y)
        chip:bind(chip_info.text, chip_info.w, chip_h)
    end
    for i = #layout + 1, #self.drop_chips do
        self.drop_chips[i]:SetVisible(false)
    end
end

function BestiaryCard:_apply_record(record)
    self.current_record = record

    self.level_value:SetText(_format_level_text(record))
    self.morale_value:SetText(_format_morale_text(record))
    self.power_value:SetText(_format_power_text(record))

    _bind_row_set(self.location_rows, record)
    _bind_row_set(self.creature_rows, {
        type = record.type,
        genus = record.genus,
        species = record.species or record.subcategory,
    })
    _bind_row_set(self.combat_rows, record.combat_effectiveness)
    _bind_row_set(self.resistance_rows, record.resistances)
    _bind_row_set(self.mitigation_left_rows, record.mitigation)
    _bind_row_set(self.mitigation_right_rows, record.mitigation)

    _bind_scroll_label_area(self.abilities_area, record.abilities)
    _bind_scroll_label_area(self.quests_area, record.quest_involvement)
    _bind_scroll_label_area(self.deeds_area, record.deed_involvement)

    self:_apply_drop_layout(_build_drop_texts(record))
end

function BestiaryCard:apply_settings()
    local w = _scaled_int(BASE_WIDTH)
    local h = _scaled_int(BASE_HEIGHT)

    self:SetSize(w, h)

    _style_panel(self.level_panel)
    _style_panel(self.morale_panel)
    _style_panel(self.power_panel)
    _style_panel(self.location_panel)
    _style_panel(self.creature_panel)
    _style_panel(self.drop_panel)
    _style_panel(self.combat_panel)
    _style_panel(self.resistances_panel)
    _style_panel(self.mitigation_panel)
    self.mitigation_divider:SetBackColor(COLOR_PANEL_DIVIDER)
    _style_panel(self.abilities_panel)
    _style_panel(self.quests_panel)
    _style_panel(self.deeds_panel)

    _style_row_set(self.location_rows, COLOR_VALUE)
    _style_row_set(self.creature_rows, COLOR_VALUE)
    _style_row_set(self.combat_rows, COLOR_VALUE)
    _style_row_set(self.resistance_rows, COLOR_VALUE_GREEN)
    _style_row_set(self.mitigation_left_rows, COLOR_VALUE_CYAN)
    _style_row_set(self.mitigation_right_rows, COLOR_VALUE_CYAN)

    _style_scroll_label_area(self.abilities_area, "Verdana", BASE_TEXT_SIZE, COLOR_VALUE)
    _style_scroll_label_area(self.quests_area, "Verdana", BASE_TEXT_SIZE, COLOR_VALUE)
    _style_scroll_label_area(self.deeds_area, "Verdana", BASE_TEXT_SIZE, COLOR_VALUE)

    _bind_scroll_label_area(self.abilities_area, self.current_record ~= nil and self.current_record.abilities or nil)
    _bind_scroll_label_area(self.quests_area, self.current_record ~= nil and self.current_record.quest_involvement or nil)
    _bind_scroll_label_area(self.deeds_area, self.current_record ~= nil and self.current_record.deed_involvement or nil)

    self:_layout_content()

    if self.current_record ~= nil then
        self:_apply_record(self.current_record)
    else
        self:_apply_drop_layout({ TR("No drops seen.") })
    end
end

function BestiaryCard:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function BestiaryCard:close()
    self.current_key = nil
    self:SetVisible(false)
end

function BestiaryCard:on_target_changed()
end

function BestiaryCard:_position_near_anchor(anchor)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local left = math.floor((display_w - self:GetWidth()) / 2)
    local top = math.floor((display_h - self:GetHeight()) / 2)

    if anchor ~= nil and anchor.GetPosition ~= nil and anchor.GetSize ~= nil then
        local ax, ay = anchor:GetPosition()
        local aw, _ = anchor:GetSize()
        left = ax + aw + _scaled_int(BASE_OFFSET)
        top = ay
    end

    if left + self:GetWidth() > display_w then
        left = display_w - self:GetWidth() - _scaled_int(BASE_OFFSET)
    end
    if top + self:GetHeight() > display_h then
        top = display_h - self:GetHeight() - _scaled_int(BASE_OFFSET)
    end
    if left < _scaled_int(BASE_OFFSET) then
        left = _scaled_int(BASE_OFFSET)
    end
    if top < _scaled_int(BASE_OFFSET) then
        top = _scaled_int(BASE_OFFSET)
    end

    self._suppress_position_persist = true
    self:SetPosition(left, top)
    self._suppress_position_persist = false
end

function BestiaryCard:_prepare_position(anchor)
    if self:_restore_saved_position() ~= true and self.sticky_position ~= true then
        self:_position_near_anchor(anchor)
    end

    self:_clamp_to_display()
    self:_persist_current_position()
    self.sticky_position = true
end

function BestiaryCard:toggle_for_target(target, anchor)
    local record = _build_record_for_target(target)
    if type(record) ~= "table" then
        return false
    end

    if self:IsVisible() == true and self.current_key == record.key then
        self:close()
        return true
    end

    self.current_key = record.key
    self:SetText(record.name or record.key or TR("Bestiary"))
    self:_apply_record(record)
    self:_prepare_position(anchor)
    self:SetVisible(true)
    self:bring_to_front()
    return true
end

function BestiaryCard:show_for_name(name, anchor)
    local record = _build_record_for_name(name)
    if type(record) ~= "table" then
        return false
    end

    self.current_key = record.key
    self:SetText(record.name or record.key or TR("Bestiary"))
    self:_apply_record(record)
    self:_prepare_position(anchor)
    self:SetVisible(true)
    self:bring_to_front()
    return true
end
