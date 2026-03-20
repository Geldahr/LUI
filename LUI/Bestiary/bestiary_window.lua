import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Geldahr.LUI.UI.Widgets"
import "Geldahr.LUI.Inventory.filter"
import "Geldahr.LUI.Utils.font"

Bestiary = Bestiary or {}

local BUILTIN_BESTIARY = Bestiary.Data or {}

-- Bestiary icon for shortcut button: 0x410E0435
-- Parchment icon: 0x410E9288
-- Book no background: 0x41003199
-- Book background: 0x41002DC3
-- Book icon pressed: 0x41005F00 25x25
-- Book icon normal: 0x41005F07 25x25
-- Book icon hover: 0x41005F0F 25x25

local BASE_MARGIN_LEFT = 15
local BASE_MARGIN_TOP = 33
local BASE_MARGIN_RIGHT = 15
local BASE_MARGIN_BOTTOM = 15
local BASE_BAR_H = 21
local BASE_FILTER_H = 21
local BASE_GAP = 4
local BASE_CLEAR_W = 59
local BASE_ORDER_LABEL_W = 41
local BASE_SORT_W = 68
local BASE_NAV_W = 22
local BASE_PAGE_W = 74
local BASE_GENUS_LABEL_W = 40
local BASE_TAXONOMY_VALUE_MAX_W = 200
local BASE_MIN_W = 600
local BASE_MIN_H = 240
local BASE_NAME_FONT_SIZE = 12
local BASE_TEXT_FONT_SIZE = 10
local BASE_TAXONOMY_FONT_SIZE = 10
local BASE_ROW_PAD_X = 8
local BASE_ROW_PAD_Y = 4
local BASE_ROW_GAP_Y = 2
local BASE_LINE_H = 14
local BASE_ROW_SEPARATOR = 2
local BASE_CHIP_H = 18
local BASE_CHIP_PAD_X = 6
local BASE_CHIP_GAP_X = 4
local BASE_CHIP_GAP_Y = 4
local BASE_CHIP_BORDER = 1
local BASE_CHIP_MIN_W = 52
local BASE_CHIP_CHAR_W = 5.8
local BASE_NAME_CHAR_W = 6.9
local BASE_TAXONOMY_CHAR_W = 5.8
local BASE_TAXONOMY_PAD_X = 5
local BASE_TAXONOMY_ARROW_W = 14
local BASE_TAXONOMY_START_RATIO = 0.40
local BASE_RESIZE_REFRESH_DELAY = 0.10
local BASE_COLUMN_W = 600

local AREA_COMPASS_ICON = "Geldahr/LUI/PluginAssets/ui/compass_64.tga"
local AREA_COMPASS_HOVER_ICON = "Geldahr/LUI/PluginAssets/ui/compass_hover_64.tga"

local SORT_NAME_ASC = "name_asc"
local SORT_NAME_DESC = "name_desc"
local SORT_LEVEL_ASC = "level_asc"
local SORT_LEVEL_DESC = "level_desc"

local FILTER_ALL = "__all"
local FILTER_NONE = "__none"

local COLOR_DROP_CHIP_BORDER = Turbine.UI.Color(1, 0.28, 0.28, 0.28)
local COLOR_DROP_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_DROP_CHIP_TEXT = Turbine.UI.Color(1, 0.76, 0.88, 0.79)
local COLOR_CHEST_CHIP_BORDER = Turbine.UI.Color(1, 0.45, 0.32, 0.12)
local COLOR_CHEST_CHIP_BG = Turbine.UI.Color(1, 0.14, 0.10, 0.04)
local COLOR_CHEST_CHIP_TEXT = Turbine.UI.Color(1, 0.98, 0.86, 0.52)

local function _push_filter_term(cur_group, term)
    if term ~= nil and term ~= "" then
        cur_group[#cur_group + 1] = term
    end
end

local function _end_filter_group(groups, cur_group)
    if #cur_group > 0 then
        groups[#groups + 1] = cur_group
    end
end

local function _parse_query(query)
    if type(query) ~= "string" then
        return {}
    end

    local groups = {}
    local cur_group = {}
    local i = 1
    local n = #query

    while i <= n do
        local c = query:sub(i, i)
        if c == "\"" then
            local j = i + 1
            while j <= n and query:sub(j, j) ~= "\"" do
                j = j + 1
            end
            _push_filter_term(cur_group, query:sub(i + 1, j - 1))
            i = (j <= n) and (j + 1) or (n + 1)
        elseif c == "|" then
            _end_filter_group(groups, cur_group)
            cur_group = {}
            i = i + 1
        elseif c:match("%s") then
            i = i + 1
        else
            local j = i
            while j <= n do
                local cj = query:sub(j, j)
                if cj == "|" or cj == "\"" or cj:match("%s") then
                    break
                end
                j = j + 1
            end
            _push_filter_term(cur_group, query:sub(i, j - 1))
            i = j
        end
    end

    _end_filter_group(groups, cur_group)
    return groups
end

local function _normalize_groups(groups)
    if groups == nil or #groups == 0 then
        return {}
    end

    local out = {}
    for gi = 1, #groups do
        local group = groups[gi]
        if group ~= nil and #group > 0 then
            local normalized = {}
            for ti = 1, #group do
                local term = group[ti]
                if type(term) == "string" then
                    term = string.lower(term)
                    if term ~= "" then
                        normalized[#normalized + 1] = term
                    end
                end
            end
            if #normalized > 0 then
                out[#out + 1] = normalized
            end
        end
    end

    return out
end

local function _matches_groups(groups, haystack_lower)
    if groups == nil or #groups == 0 then
        return true
    end
    if type(haystack_lower) ~= "string" then
        return false
    end

    for gi = 1, #groups do
        local group = groups[gi]
        local ok = true
        for ti = 1, #group do
            local term = group[ti]
            if term ~= "" and string.find(haystack_lower, term, 1, true) == nil then
                ok = false
                break
            end
        end
        if ok then
            return true
        end
    end

    return false
end

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * _G.settings.global.scale)
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end
    return string.lower(text)
end

local function _area_compass_icon(hovered)
    if hovered == true then
        return AREA_COMPASS_HOVER_ICON
    end

    return AREA_COMPASS_ICON
end

local function _set_area_slot_icon_background(window, target_w, target_h)
    if type(window) ~= "table" or window.area_slot_icon == nil then
        return
    end

    local background = _area_compass_icon(window._area_slot_hovered == true)
    if type(target_w) ~= "number" or target_w < 1 or type(target_h) ~= "number" or target_h < 1 then
        if window.area_slot ~= nil and window.area_slot.GetSize ~= nil then
            target_w, target_h = window.area_slot:GetSize()
        end
    end

    if type(target_w) ~= "number" or target_w < 1 then
        target_w = _scaled_int(BASE_FILTER_H)
    end
    if type(target_h) ~= "number" or target_h < 1 then
        target_h = target_w
    end

    if window._area_slot_icon_background ~= background then
        window._area_slot_icon_background = background
    end

    if window.area_slot_icon.SetBackground ~= nil then
        window.area_slot_icon:SetBackground(background)
    end

    _G.refresh_stretch_mode_1_from_current_content(window.area_slot_icon)
    -- if window.area_slot_icon.SetStretchMode ~= nil then
    --     window.area_slot_icon:SetStretchMode(1)
    -- end
    if window.area_slot_icon.SetSize ~= nil then
        window.area_slot_icon:SetSize(target_w, target_h)
    end
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

local function _append_filter_values(filter_parts, values)
    if type(filter_parts) ~= "table" or type(values) ~= "table" then
        return
    end

    for _, value in pairs(values) do
        if type(value) == "string" and value ~= "" then
            filter_parts[#filter_parts + 1] = _lower_text(value)
        end
    end
end

local function _contains_value(list, value)
    if type(list) ~= "table" then
        return false
    end

    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end

    return false
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

local function _merged_bestiary()
    local merged = {}
    local function merge_source(source)
        if type(source) ~= "table" then
            return
        end

        for name, entry in pairs(source) do
            if type(name) == "string" and type(entry) == "table" then
                if type(merged[name]) ~= "table" then
                    merged[name] = {
                        display_name = name,
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
                end

                _merge_entry(merged[name], entry, name)
            end
        end
    end

    merge_source(BUILTIN_BESTIARY)
    merge_source(_G.bestiary_cache)

    return merged
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
    return tostring(min_value) .. "-" .. tostring(max_value)
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

local function _format_percent(percent)
    local value = _to_number(percent, 0)
    local text
    if value >= 10 then
        text = string.format("%.1f", value)
    elseif value >= 1 then
        text = string.format("%.1f", value)
    else
        text = string.format("%.2f", value)
    end

    text = text:gsub("(%..-)0+$", "%1")
    text = text:gsub("%.$", "")
    return text .. "%"
end

local function _collect_unique_record_values(records, field_name, genus_filter)
    local out = {}
    local seen = {}
    if type(records) ~= "table" then
        return out
    end

    for i = 1, #records do
        local record = records[i]
        if type(record) == "table" and (genus_filter == nil or record.genus == genus_filter) then
            local value = record[field_name]
            if type(value) == "string" and value ~= "" and seen[value] ~= true then
                seen[value] = true
                out[#out + 1] = value
            end
        end
    end

    table.sort(out, function(left, right)
        return _lower_text(left) < _lower_text(right)
    end)

    return out
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
        return _lower_text(left.name) < _lower_text(right.name)
    end)

    return drops
end

local function _build_records()
    local merged = _merged_bestiary()
    local out = {}

    for name, entry in pairs(merged) do
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

        local drop_records = _build_drop_records(entry)
        local display_name = type(entry.display_name) == "string" and entry.display_name or name
        local filter_parts = {
            _lower_text(name),
            _lower_text(display_name),
            _lower_text(entry.genus),
            _lower_text(entry.subcategory),
            _lower_text(entry.species),
            _lower_text(entry.region),
            _lower_text(entry.area),
            _lower_text(entry.instance),
            _lower_text(entry.monster_type),
        }
        for i = 1, #drop_records do
            filter_parts[#filter_parts + 1] = _lower_text(drop_records[i].name)
        end
        _append_filter_values(filter_parts, entry.combat_effectiveness)
        _append_filter_values(filter_parts, entry.resistances)
        _append_filter_values(filter_parts, entry.mitigation)
        _append_filter_values(filter_parts, entry.abilities)
        _append_filter_values(filter_parts, entry.quest_involvement)
        _append_filter_values(filter_parts, entry.deed_involvement)

        out[#out + 1] = {
            key = name,
            name = display_name,
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
            combat_effectiveness = entry.combat_effectiveness,
            resistances = entry.resistances,
            mitigation = entry.mitigation,
            abilities = entry.abilities,
            quest_involvement = entry.quest_involvement,
            deed_involvement = entry.deed_involvement,
            kills = _to_number(entry.k, 0),
            drops = drop_records,
            haystack_lower = table.concat(filter_parts, "\n"),
        }
    end

    return out
end

local function _compare_records(sort_mode, left, right)
    if sort_mode == SORT_LEVEL_ASC then
        if left.level_min ~= right.level_min then
            return left.level_min < right.level_min
        end
        if left.level_max ~= right.level_max then
            return left.level_max < right.level_max
        end
    elseif sort_mode == SORT_LEVEL_DESC then
        if left.level_max ~= right.level_max then
            return left.level_max > right.level_max
        end
        if left.level_min ~= right.level_min then
            return left.level_min > right.level_min
        end
    elseif sort_mode == SORT_NAME_DESC then
        local left_name = _lower_text(left.name)
        local right_name = _lower_text(right.name)
        if left_name ~= right_name then
            return left_name > right_name
        end
    else
        local left_name = _lower_text(left.name)
        local right_name = _lower_text(right.name)
        if left_name ~= right_name then
            return left_name < right_name
        end
    end

    return _lower_text(left.name) < _lower_text(right.name)
end

local function _estimate_chip_width(text)
    local char_w = BASE_CHIP_CHAR_W * _G.settings.global.scale
    local pad_x = _scaled_int(BASE_CHIP_PAD_X)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    local text_w = math.floor((string.len(text or "") * char_w) + 0.5)
    local min_w = _scaled_int(BASE_CHIP_MIN_W)
    local width = text_w + (2 * (pad_x + border_w))
    if width < min_w then
        width = min_w
    end
    return width
end

local function _estimate_text_width(text, base_char_w)
    return math.floor((string.len(text or "") * base_char_w * _G.settings.global.scale) + 0.5)
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

local function _apply_separator_style(control)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColor(Turbine.UI.Color(1, 0.20, 0.20, 0.20))
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

    self.label = Turbine.UI.Label()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetMultiline(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self:apply_settings()
end

function DropChip:apply_settings(chest)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    self.inner:SetPosition(border_w, border_w)
    self.label:SetFont(_scaled_font("Verdana", BASE_TEXT_FONT_SIZE))
    self.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    if chest == true then
        self:SetBackColor(COLOR_CHEST_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_CHEST_CHIP_BG)
        self.label:SetForeColor(COLOR_CHEST_CHIP_TEXT)
    else
        self:SetBackColor(COLOR_DROP_CHIP_BORDER)
        self.inner:SetBackColor(COLOR_DROP_CHIP_BG)
        self.label:SetForeColor(COLOR_DROP_CHIP_TEXT)
    end
    self.label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
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

local BestiaryRow = class(Turbine.UI.Control)

function BestiaryRow:Constructor(owner_window)
    Turbine.UI.Control.Constructor(self)

    self.owner_window = owner_window
    self:SetMouseVisible(false)

    self.name_label = Turbine.UI.Label()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetMultiline(false)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.taxonomy_prefix_label = Turbine.UI.TextBox()
    self.taxonomy_prefix_label:SetParent(self)
    self.taxonomy_prefix_label:SetMouseVisible(false)
    self.taxonomy_prefix_label:SetReadOnly(true)
    self.taxonomy_prefix_label:SetSelectable(false)
    self.taxonomy_prefix_label:SetMultiline(false)
    self.taxonomy_prefix_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.genus_link = Turbine.UI.TextBox()
    self.genus_link:SetParent(self)
    self.genus_link:SetMouseVisible(true)
    self.genus_link:SetReadOnly(true)
    self.genus_link:SetSelectable(false)
    self.genus_link:SetMultiline(false)
    self.genus_link:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.genus_link.MouseClick = function(_, args)
        if args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if self.owner_window ~= nil and self._record ~= nil and type(self._record.genus) == "string" and self._record.genus ~= "" then
            self.owner_window:set_taxonomy_filters(self._record.genus, FILTER_ALL)
        end
    end

    self.taxonomy_arrow_label = Turbine.UI.TextBox()
    self.taxonomy_arrow_label:SetParent(self)
    self.taxonomy_arrow_label:SetMouseVisible(false)
    self.taxonomy_arrow_label:SetReadOnly(true)
    self.taxonomy_arrow_label:SetSelectable(false)
    self.taxonomy_arrow_label:SetMultiline(false)
    self.taxonomy_arrow_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.subcategory_link = Turbine.UI.TextBox()
    self.subcategory_link:SetParent(self)
    self.subcategory_link:SetMouseVisible(true)
    self.subcategory_link:SetReadOnly(true)
    self.subcategory_link:SetSelectable(false)
    self.subcategory_link:SetMultiline(false)
    self.subcategory_link:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.subcategory_link.MouseClick = function(_, args)
        if args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if self.owner_window ~= nil and self._record ~= nil and type(self._record.genus) == "string" and self._record.genus ~= ""
            and type(self._record.subcategory) == "string" and self._record.subcategory ~= "" then
            self.owner_window:set_taxonomy_filters(self._record.genus, self._record.subcategory)
        end
    end

    self.level_label = Turbine.UI.Label()
    self.level_label:SetParent(self)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetMultiline(false)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.morale_label = Turbine.UI.Label()
    self.morale_label:SetParent(self)
    self.morale_label:SetMouseVisible(false)
    self.morale_label:SetMultiline(false)
    self.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.power_label = Turbine.UI.Label()
    self.power_label:SetParent(self)
    self.power_label:SetMouseVisible(false)
    self.power_label:SetMultiline(false)
    self.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.drop_area = Turbine.UI.Control()
    self.drop_area:SetParent(self)
    self.drop_area:SetMouseVisible(false)
    self.drop_chips = {}

    self.separator = Turbine.UI.Control()
    self.separator:SetParent(self)
    self.separator:SetMouseVisible(false)
    _apply_separator_style(self.separator)

    self:apply_settings()
end

function BestiaryRow:apply_settings()
    self.name_label:SetFont(_scaled_font("Verdana", BASE_NAME_FONT_SIZE))
    self.name_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.name_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    self.name_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    local meta_font = _scaled_font("Verdana", BASE_TEXT_FONT_SIZE)
    local taxonomy_font = _scaled_font("Verdana", BASE_TAXONOMY_FONT_SIZE)

    self.taxonomy_prefix_label:SetFont(taxonomy_font)
    self.taxonomy_prefix_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.taxonomy_prefix_label:SetForeColor(Turbine.UI.Color(1, 0.62, 0.62, 0.62))
    self.taxonomy_prefix_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.genus_link:SetFont(taxonomy_font)
    self.genus_link:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.genus_link:SetForeColor(Turbine.UI.Color(1, 0.82, 0.78, 0.55))
    self.genus_link:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.taxonomy_arrow_label:SetFont(taxonomy_font)
    self.taxonomy_arrow_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.taxonomy_arrow_label:SetForeColor(Turbine.UI.Color(1, 0.62, 0.62, 0.62))
    self.taxonomy_arrow_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.subcategory_link:SetFont(taxonomy_font)
    self.subcategory_link:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.subcategory_link:SetForeColor(Turbine.UI.Color(1, 0.67, 0.82, 0.93))
    self.subcategory_link:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.level_label:SetFont(meta_font)
    self.level_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.level_label:SetForeColor(Turbine.UI.Color(1, 0.72, 0.58, 0.20))
    self.level_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.morale_label:SetFont(meta_font)
    self.morale_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.morale_label:SetForeColor(Turbine.UI.Color(1, 0.42, 0.86, 0.44))
    self.morale_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.power_label:SetFont(meta_font)
    self.power_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.power_label:SetForeColor(Turbine.UI.Color(1, 0.40, 0.68, 0.96))
    self.power_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    _apply_separator_style(self.separator)

    for i = 1, #self.drop_chips do
        self.drop_chips[i]:apply_settings()
    end
end

function BestiaryRow:_ensure_chip_count(count)
    while #self.drop_chips < count do
        local chip = DropChip()
        chip:SetParent(self.drop_area)
        chip:SetVisible(false)
        self.drop_chips[#self.drop_chips + 1] = chip
    end
end

function BestiaryRow:bind(record, width)
    local pad_x = _scaled_int(BASE_ROW_PAD_X)
    local pad_y = _scaled_int(BASE_ROW_PAD_Y)
    local row_gap_y = _scaled_int(BASE_ROW_GAP_Y)
    local line_h = _scaled_int(BASE_LINE_H)
    local separator_h = _scaled_int(BASE_ROW_SEPARATOR)
    local taxonomy_pad_x = _scaled_int(BASE_TAXONOMY_PAD_X)
    local taxonomy_arrow_w = _scaled_int(BASE_TAXONOMY_ARROW_W)
    local layout_gap_x = _scaled_int(BASE_GAP)
    local column_gap_x = _scaled_int(6)

    local inner_w = math.max(1, width - (2 * pad_x))
    local right_text_w = math.max(
        _estimate_text_width(record ~= nil and record.level_text or "", BASE_TAXONOMY_CHAR_W),
        _estimate_text_width(record ~= nil and record.power_text or "", BASE_TAXONOMY_CHAR_W)
    )
    local right_w = math.min(_scaled_int(120), math.max(_scaled_int(72), right_text_w + (2 * taxonomy_pad_x)))
    local left_w = math.max(1, inner_w - right_w - column_gap_x)

    local drop_layout = {}
    local drop_h = _scaled_int(BASE_CHIP_H)
    local height = pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h

    self:SetSize(width, height)

    self.level_label:SetPosition(pad_x + left_w + column_gap_x, pad_y)
    self.level_label:SetSize(right_w, line_h)

    self.morale_label:SetPosition(pad_x, pad_y + line_h + row_gap_y)
    self.morale_label:SetSize(left_w, line_h)
    self.power_label:SetPosition(pad_x + left_w + column_gap_x, pad_y + line_h + row_gap_y)
    self.power_label:SetSize(right_w, line_h)

    self.drop_area:SetPosition(pad_x, pad_y + (2 * (line_h + row_gap_y)))
    self.drop_area:SetSize(inner_w, drop_h)

    self.separator:SetPosition(0, height - separator_h)
    self.separator:SetSize(width, separator_h)

    if record == nil then
        self._record = nil
        self.taxonomy_prefix_label:SetVisible(false)
        self.genus_link:SetVisible(false)
        self.taxonomy_arrow_label:SetVisible(false)
        self.subcategory_link:SetVisible(false)
        for i = 1, #self.drop_chips do
            self.drop_chips[i]:SetVisible(false)
        end
        self:SetVisible(false)
        return
    end

    self._record = record
    self.name_label:SetText(record.name)
    self.level_label:SetText(record.level_text)
    self.morale_label:SetText(record.morale_text)
    self.power_label:SetText(record.power_text)

    local drop_texts = record._drop_texts
    if type(drop_texts) ~= "table" then
        drop_texts = { { text = TR("No drops seen."), chest = false } }
    end
    drop_layout, drop_h = _build_chip_layout(drop_texts, inner_w)
    height = pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h
    self:SetSize(width, height)
    self.drop_area:SetSize(inner_w, drop_h)
    self.separator:SetPosition(0, height - separator_h)
    self:_ensure_chip_count(#drop_layout)

    local taxonomy_y = pad_y
    local arrow_text = ">"
    local genus_text = record.genus
    local subcategory_text = record.subcategory
    local has_genus = type(genus_text) == "string" and genus_text ~= ""
    local has_subcategory = type(subcategory_text) == "string" and subcategory_text ~= ""
    local genus_w = has_genus == true and (_estimate_text_width(genus_text, BASE_TAXONOMY_CHAR_W) + (2 * taxonomy_pad_x)) or 0
    local subcategory_w = has_subcategory == true and (_estimate_text_width(subcategory_text, BASE_TAXONOMY_CHAR_W) + (2 * taxonomy_pad_x)) or 0
    local arrow_w = (has_genus == true and has_subcategory == true) and taxonomy_arrow_w or 0
    local taxonomy_total_w = genus_w + arrow_w + subcategory_w
    if taxonomy_total_w > left_w then
        if has_genus == true and has_subcategory == true then
            local text_total_w = math.max(1, genus_w + subcategory_w)
            local content_w = math.max(1, left_w - arrow_w)
            genus_w = math.max(1, math.floor((content_w * genus_w) / text_total_w))
            subcategory_w = math.max(1, content_w - genus_w)
        elseif has_genus == true then
            genus_w = left_w
        end
        taxonomy_total_w = math.min(left_w, genus_w + arrow_w + subcategory_w)
    end

    local level_x = pad_x + left_w + column_gap_x
    local taxonomy_x = pad_x + math.max(0, math.floor(inner_w * BASE_TAXONOMY_START_RATIO))
    local max_taxonomy_x = level_x - layout_gap_x - taxonomy_total_w
    if taxonomy_x > max_taxonomy_x then
        taxonomy_x = math.max(pad_x, max_taxonomy_x)
    end
    local name_w = left_w
    if taxonomy_total_w > 0 then
        name_w = math.max(1, math.min(left_w, taxonomy_x - pad_x - layout_gap_x))
    end

    self.name_label:SetPosition(pad_x, pad_y)
    self.name_label:SetSize(name_w, line_h)

    self.taxonomy_prefix_label:SetVisible(false)

    self.genus_link:SetText(genus_text or "")
    self.genus_link:SetPosition(taxonomy_x, taxonomy_y)
    self.genus_link:SetSize(math.max(1, genus_w), line_h)
    self.genus_link:SetVisible(has_genus == true)
    taxonomy_x = taxonomy_x + genus_w

    self.taxonomy_arrow_label:SetText(arrow_text)
    self.taxonomy_arrow_label:SetPosition(taxonomy_x, taxonomy_y)
    self.taxonomy_arrow_label:SetSize(math.max(1, arrow_w), line_h)
    self.taxonomy_arrow_label:SetVisible(arrow_w > 0)
    taxonomy_x = taxonomy_x + arrow_w

    self.subcategory_link:SetText(subcategory_text or "")
    self.subcategory_link:SetPosition(taxonomy_x, taxonomy_y)
    self.subcategory_link:SetSize(math.max(1, subcategory_w), line_h)
    self.subcategory_link:SetVisible(has_subcategory == true)

    local chip_h = _scaled_int(BASE_CHIP_H)
    for i = 1, #drop_layout do
        local chip_info = drop_layout[i]
        local chip = self.drop_chips[i]
        chip:SetPosition(chip_info.x, chip_info.y)
        chip:apply_settings(chip_info.chest == true)
        chip:bind(chip_info.text, chip_info.w, chip_h)
    end
    for i = #drop_layout + 1, #self.drop_chips do
        self.drop_chips[i]:SetVisible(false)
    end

    self:SetVisible(true)
end

local BestiaryWindow = class(Turbine.UI.Lotro.Window)

function BestiaryWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetText(TR("Bestiary"))
    self:SetVisible(false)
    self:SetResizable(true)
    self:SetWantsUpdates(false)

    self.last_update_at = 0
    self.update_every = 0.5
    self._last_generation = nil
    self._suppress_size_changed = false
    self._resize_dirty = false
    self._last_resize_at = 0
    self._last_resize_reflow_at = 0
    self._prepared_content_w = 0
    self._prepared_content_h = 0
    self._prepared_record_key = 0
    self.current_area = nil
    self.last_applied_area_query = nil
    self._suppress_area_text_changed = false

    self.sort_mode = SORT_NAME_ASC
    self.filter_groups = {}
    self.genus_filter = FILTER_ALL
    self.subcategory_filter = FILTER_NONE
    self._suppress_genus_changed = false
    self._suppress_subcategory_changed = false
    self.all_records = {}
    self.records = {}
    self.pages = {}
    self.page_index = 1
    self.entries = {}
    self.column_separators = {}

    self.nav_bar = Turbine.UI.Control()
    self.nav_bar:SetParent(self)

    self.order_label = Turbine.UI.TextBox()
    self.order_label:SetParent(self.nav_bar)
    self.order_label:SetMouseVisible(false)
    self.order_label:SetReadOnly(true)
    self.order_label:SetSelectable(false)
    self.order_label:SetMultiline(false)
    self.order_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.order_label:SetText(TR("Order") .. ":")

    self.sort_dropdown = UI.Widgets.LuiDropdown()
    self.sort_dropdown:SetParent(self.nav_bar)
    self.sort_dropdown:SetPopupHost(self)
    self.sort_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.sort_dropdown:SetMappedOptions(
        { TR("A-Z"), TR("Z-A"), TR("Lvl <"), TR("Lvl >") },
        { SORT_NAME_ASC, SORT_NAME_DESC, SORT_LEVEL_ASC, SORT_LEVEL_DESC }
    )
    self.sort_dropdown.ValueChanged = function(_, value)
        self:set_sort_mode(value)
    end

    self.page_bar = Turbine.UI.Control()
    self.page_bar:SetParent(self)

    self.prev_button = UI.Widgets.LuiButton()
    self.prev_button:SetParent(self.page_bar)
    self.prev_button:SetText("<")
    self.prev_button.Click = function()
        self:set_page(self.page_index - 1)
    end

    self.page_label = Turbine.UI.Label()
    self.page_label:SetParent(self.page_bar)
    self.page_label:SetMouseVisible(false)
    self.page_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.next_button = UI.Widgets.LuiButton()
    self.next_button:SetParent(self.page_bar)
    self.next_button:SetText(">")
    self.next_button.Click = function()
        self:set_page(self.page_index + 1)
    end

    self.filter_bar = Turbine.UI.Control()
    self.filter_bar:SetParent(self)

    self.filter_tb = Turbine.UI.Lotro.TextBox()
    self.filter_tb:SetParent(self.filter_bar)
    self.filter_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.filter_tb.TextChanged = function()
        if self._suppress_area_text_changed ~= true then
            self.current_area = nil
            self.last_applied_area_query = nil
            _G.bestiary_area_filter_query = nil
        end
        self:update_filter()
    end

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.filter_bar)
    self.clear_button:SetText(TR("Clear"))
    self.clear_button.Click = function()
        self.current_area = nil
        self.last_applied_area_query = nil
        _G.bestiary_area_filter_query = nil
        self.filter_tb:SetText("")
        self:update_filter()
        self.filter_tb:Focus()
    end

    self.area_label = Turbine.UI.TextBox()
    self.area_label:SetParent(self.filter_bar)
    self.area_label:SetMouseVisible(false)
    self.area_label:SetReadOnly(true)
    self.area_label:SetSelectable(false)
    self.area_label:SetMultiline(false)
    self.area_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.area_label:SetVisible(false)

    self.area_shortcut = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "")
    self.area_shortcut:SetData(TR("/loc"))

    self.area_slot = Turbine.UI.Lotro.Quickslot()
    self.area_slot:SetParent(self.filter_bar)
    self.area_slot:SetAllowDrop(false)
    self.area_slot:SetZOrder(1)
    self.area_slot:SetShortcut(self.area_shortcut)
    self.area_slot:SetVisible(true)
    self._area_slot_hovered = false
    self.area_slot.MouseEnter = function()
        self._area_slot_hovered = true
        local icon_w, icon_h = self.area_slot:GetSize()
        _set_area_slot_icon_background(self, icon_w, icon_h)
    end
    self.area_slot.MouseLeave = function()
        self._area_slot_hovered = false
        local icon_w, icon_h = self.area_slot:GetSize()
        _set_area_slot_icon_background(self, icon_w, icon_h)
    end

    self.area_slot_cover = Turbine.UI.Control()
    self.area_slot_cover:SetParent(self.filter_bar)
    self.area_slot_cover:SetMouseVisible(false)
    self.area_slot_cover:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.area_slot_cover:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))
    self.area_slot_cover:SetZOrder(2)

    self.area_slot_icon = Turbine.UI.Control()
    self.area_slot_icon:SetParent(self.filter_bar)
    self.area_slot_icon:SetMouseVisible(false)
    self.area_slot_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.area_slot_icon:SetZOrder(3)
    _set_area_slot_icon_background(self, _scaled_int(BASE_FILTER_H), _scaled_int(BASE_FILTER_H))

    self.taxonomy_bar = Turbine.UI.Control()
    self.taxonomy_bar:SetParent(self.nav_bar)

    self.genus_label = Turbine.UI.TextBox()
    self.genus_label:SetParent(self.taxonomy_bar)
    self.genus_label:SetMouseVisible(false)
    self.genus_label:SetReadOnly(true)
    self.genus_label:SetSelectable(false)
    self.genus_label:SetMultiline(false)
    self.genus_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.genus_label:SetText(TR("Genus") .. ":")

    self.genus_dropdown = UI.Widgets.LuiDropdown()
    self.genus_dropdown:SetParent(self.taxonomy_bar)
    self.genus_dropdown:SetPopupHost(self)
    self.genus_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.genus_dropdown:SetMappedOptions({ TR("All") }, { FILTER_ALL })
    self.genus_dropdown.ValueChanged = function(_, value)
        if self._suppress_genus_changed == true then
            return
        end
        self:set_genus_filter(value)
    end

    self.subcategory_label = Turbine.UI.TextBox()
    self.subcategory_label:SetParent(self.taxonomy_bar)
    self.subcategory_label:SetMouseVisible(false)
    self.subcategory_label:SetReadOnly(true)
    self.subcategory_label:SetSelectable(false)
    self.subcategory_label:SetMultiline(false)
    self.subcategory_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.subcategory_label:SetVisible(false)

    self.subcategory_dropdown = UI.Widgets.LuiDropdown()
    self.subcategory_dropdown:SetParent(self.taxonomy_bar)
    self.subcategory_dropdown:SetPopupHost(self)
    self.subcategory_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.subcategory_dropdown:SetMappedOptions({ "-" }, { FILTER_NONE })
    self.subcategory_dropdown:SetEnabled(false)
    self.subcategory_dropdown.ValueChanged = function(_, value)
        if self._suppress_subcategory_changed == true then
            return
        end
        self:set_subcategory_filter(value)
    end

    self.content = Turbine.UI.Control()
    self.content:SetParent(self)
    self.content:SetMouseVisible(false)

    self.empty_label = Turbine.UI.Label()
    self.empty_label:SetParent(self.content)
    self.empty_label:SetMouseVisible(false)
    self.empty_label:SetMultiline(true)
    self.empty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.empty_label:SetText(TR("No bestiary entries yet."))
    self.empty_label:SetZOrder(3)

    self.SizeChanged = function()
        self:handle_user_resize()
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if visible == true then
            self.last_update_at = 0
            self._last_generation = nil
            self:bring_to_front()
            self:refresh_from_store(true)
            self:sync_area_filter_query()
            self:apply_current_area_filter(true)
        else
            if self.sort_dropdown ~= nil and self.sort_dropdown.Close ~= nil then
                self.sort_dropdown:Close()
            end
            if self.genus_dropdown ~= nil and self.genus_dropdown.Close ~= nil then
                self.genus_dropdown:Close()
            end
            if self.subcategory_dropdown ~= nil and self.subcategory_dropdown.Close ~= nil then
                self.subcategory_dropdown:Close()
            end
        end
    end

    self:SetSize(_scaled_int(700), _scaled_int(520))
    self:apply_settings()
end

function BestiaryWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function BestiaryWindow:open()
    self:SetVisible(true)
    self:bring_to_front()
end

function BestiaryWindow:toggle()
    self:SetVisible(not self:IsVisible())
    if self:IsVisible() == true then
        self:bring_to_front()
    end
end

function BestiaryWindow:capture_geometry()
    local raw = _G.loaded_settings ~= nil and _G.loaded_settings.bestiary or nil
    if type(raw) ~= "table" or type(raw.window) ~= "table" then
        return
    end

    local left, top = self:GetPosition()
    local width, height = self:GetSize()
    raw.window.left = left
    raw.window.top = top
    raw.window.width = width
    raw.window.height = height
end

function BestiaryWindow:persist_geometry()
    self:capture_geometry()
end

function BestiaryWindow:ensure_area_shortcut()
    if self.area_shortcut == nil or self.area_slot == nil then
        return
    end

    self.area_shortcut:SetData(TR("/loc"))
    self.area_slot:SetShortcut(self.area_shortcut)
    self.area_slot:SetAllowDrop(false)
end

function BestiaryWindow:apply_settings()
    self.update_every = 1.0 / math.max(1, _to_number(_G.settings.global.refresh_rate, 30))

    local button_font = _scaled_font("Verdana", 10)
    self.order_label:SetFont(button_font)
    self.sort_dropdown:SetFont(button_font)
    self.sort_dropdown:SetScale(_G.settings.global.scale)
    self.sort_dropdown:SetValue(self.sort_mode)
    self.prev_button:SetFont(button_font)
    self.page_label:SetFont(button_font)
    self.next_button:SetFont(button_font)
    self.filter_tb:SetFont(button_font)
    self.clear_button:SetFont(button_font)
    self:ensure_area_shortcut()
    self.genus_label:SetFont(button_font)
    self.genus_dropdown:SetFont(button_font)
    self.genus_dropdown:SetScale(_G.settings.global.scale)
    self.subcategory_dropdown:SetFont(button_font)
    self.subcategory_dropdown:SetScale(_G.settings.global.scale)
    self.empty_label:SetFont(_scaled_font("Verdana", 12))
    self.empty_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.empty_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    for i = 1, #self.entries do
        self.entries[i]:apply_settings()
    end

    local raw = _G.loaded_settings ~= nil and _G.loaded_settings.bestiary or nil
    local window = raw ~= nil and raw.window or nil
    if type(window) == "table" then
        local left = _to_number(window.left, self:GetLeft())
        local top = _to_number(window.top, self:GetTop())
        local width = _to_number(window.width, self:GetWidth())
        local height = _to_number(window.height, self:GetHeight())

        self._suppress_size_changed = true
        self:SetPosition(left, top)
        self:SetSize(math.max(BASE_MIN_W, width), math.max(_scaled_int(BASE_MIN_H), height))
        self._suppress_size_changed = false
    end

    self:layout()
    self:apply_view()
end

function BestiaryWindow:Update()
    if self:IsVisible() ~= true then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    self:ensure_area_shortcut()
    self:sync_area_filter_query()
    self:apply_current_area_filter(false)

    local tracker = _G.BESTIARY_TRACKER
    if tracker ~= nil and tracker.flush_expired ~= nil then
        tracker:flush_expired()
    end

    local generation = _G.bestiary_cache_generation or 0
    if self._last_generation ~= generation then
        self:refresh_from_store(true)
    elseif self._resize_dirty == true and (now - self._last_resize_at) >= BASE_RESIZE_REFRESH_DELAY then
        self._resize_dirty = false
        self._last_resize_reflow_at = now
        self:refresh_layout_view(true)
    end
end

function BestiaryWindow:handle_user_resize()
    local min_w = BASE_MIN_W
    local min_h = _scaled_int(BASE_MIN_H)
    local cur_w, cur_h = self:GetSize()
    local next_w = cur_w
    local next_h = cur_h
    if cur_w < min_w then next_w = min_w end
    if cur_h < min_h then next_h = min_h end

    if (next_w ~= cur_w or next_h ~= cur_h) and self._suppress_size_changed ~= true then
        self._suppress_size_changed = true
        self:SetSize(next_w, next_h)
        self._suppress_size_changed = false
        return
    end

    self:layout()
    self._resize_dirty = true
    self._last_resize_at = Turbine.Engine.GetGameTime()

    if (self._last_resize_at - self._last_resize_reflow_at) >= BASE_RESIZE_REFRESH_DELAY then
        self._resize_dirty = false
        self._last_resize_reflow_at = self._last_resize_at
        self:refresh_layout_view(true)
    end
end

function BestiaryWindow:update_filter()
    local query = self.filter_tb:GetText() or ""
    self.filter_groups = _normalize_groups(_parse_query(query))
    self.page_index = 1
    self:apply_view()
end

function BestiaryWindow:sync_area_filter_query()
    local query = _G.bestiary_area_filter_query
    if type(query) ~= "string" or query == "" then
        self.current_area = nil
        return
    end

    self.current_area = query
end

function BestiaryWindow:apply_current_area_filter(force)
    local query = self.current_area
    if type(query) ~= "string" or query == "" then
        return
    end

    local current = self.filter_tb:GetText() or ""
    if force ~= true and self.last_applied_area_query == query and current == query then
        return
    end

    self._suppress_area_text_changed = true
    self.filter_tb:SetText(query)
    self._suppress_area_text_changed = false
    self.last_applied_area_query = query
    self:update_filter()
end

function BestiaryWindow:on_location_resolved()
    self:sync_area_filter_query()
    self:apply_current_area_filter(true)
end

function BestiaryWindow:set_area_filter_query(query)
    if type(query) ~= "string" or query == "" then
        return
    end

    _G.bestiary_area_filter_query = query
    self.current_area = query
    self:apply_current_area_filter(true)
end

function BestiaryWindow:_refresh_genus_dropdown()
    local labels = { TR("All") }
    local values = { FILTER_ALL }
    local genera = _collect_unique_record_values(self.all_records, "genus", nil)
    for i = 1, #genera do
        labels[#labels + 1] = genera[i]
        values[#values + 1] = genera[i]
    end

    local selected = self.genus_filter
    if selected ~= FILTER_ALL and _contains_value(values, selected) ~= true then
        selected = FILTER_ALL
        self.genus_filter = selected
    end

    self._suppress_genus_changed = true
    self.genus_dropdown:SetMappedOptions(labels, values)
    self.genus_dropdown:SetValue(selected)
    self._suppress_genus_changed = false
end

function BestiaryWindow:_refresh_subcategory_dropdown()
    local labels = { "-" }
    local values = { FILTER_NONE }
    local enabled = false
    local selected = FILTER_NONE

    if self.genus_filter ~= FILTER_ALL then
        local subcategories = _collect_unique_record_values(self.all_records, "subcategory", self.genus_filter)
        if #subcategories > 0 then
            labels = { TR("All") }
            values = { FILTER_ALL }
            for i = 1, #subcategories do
                labels[#labels + 1] = subcategories[i]
                values[#values + 1] = subcategories[i]
            end
            enabled = true
            selected = self.subcategory_filter
            if selected ~= FILTER_ALL and _contains_value(values, selected) ~= true then
                selected = FILTER_ALL
            end
        end
    end

    self.subcategory_filter = selected
    self._suppress_subcategory_changed = true
    self.subcategory_dropdown:SetMappedOptions(labels, values)
    self.subcategory_dropdown:SetValue(selected)
    self.subcategory_dropdown:SetEnabled(enabled)
    self._suppress_subcategory_changed = false
end

function BestiaryWindow:refresh_taxonomy_filters()
    self:_refresh_genus_dropdown()
    self:_refresh_subcategory_dropdown()
end

function BestiaryWindow:set_taxonomy_filters(genus_value, subcategory_value)
    if type(genus_value) ~= "string" or genus_value == "" then
        genus_value = FILTER_ALL
    end

    if genus_value == FILTER_ALL then
        subcategory_value = FILTER_NONE
    elseif type(subcategory_value) ~= "string" or subcategory_value == "" then
        subcategory_value = FILTER_ALL
    end

    if self.genus_filter == genus_value and self.subcategory_filter == subcategory_value then
        return
    end

    self.genus_filter = genus_value
    self.subcategory_filter = subcategory_value
    self:refresh_taxonomy_filters()
    self.page_index = 1
    self:apply_view()
end

function BestiaryWindow:set_genus_filter(value)
    if type(value) ~= "string" or value == "" then
        value = FILTER_ALL
    end
    if self.genus_filter == value then
        return
    end

    self.genus_filter = value
    self.subcategory_filter = value == FILTER_ALL and FILTER_NONE or FILTER_ALL
    self:refresh_taxonomy_filters()
    self.page_index = 1
    self:apply_view()
end

function BestiaryWindow:set_subcategory_filter(value)
    if self.genus_filter == FILTER_ALL then
        value = FILTER_NONE
    elseif type(value) ~= "string" or value == "" then
        value = FILTER_ALL
    end

    if self.subcategory_filter == value then
        return
    end

    self.subcategory_filter = value
    self.page_index = 1
    self:apply_view()
end

function BestiaryWindow:set_sort_mode(mode)
    if mode ~= SORT_NAME_ASC and mode ~= SORT_NAME_DESC and mode ~= SORT_LEVEL_ASC and mode ~= SORT_LEVEL_DESC then
        mode = SORT_NAME_ASC
    end
    if self.sort_mode == mode then
        return
    end

    self.sort_mode = mode
    self.page_index = 1
    self:apply_view()
end

function BestiaryWindow:set_page(index)
    local count = #self.pages
    if count < 1 then
        count = 1
    end
    if index < 1 then index = 1 end
    if index > count then index = count end
    if index == self.page_index then
        return
    end

    self.page_index = index
    self:render_page()
end

function BestiaryWindow:_ensure_rows(count)
    while #self.entries < count do
        local row = BestiaryRow(self)
        row:SetParent(self.content)
        row:SetZOrder(2)
        row:SetVisible(false)
        self.entries[#self.entries + 1] = row
    end
end

function BestiaryWindow:_ensure_column_separators(count)
    while #self.column_separators < count do
        local separator = Turbine.UI.Control()
        separator:SetParent(self.content)
        separator:SetMouseVisible(false)
        separator:SetZOrder(1)
        _apply_separator_style(separator)
        separator:SetVisible(false)
        self.column_separators[#self.column_separators + 1] = separator
    end
end

function BestiaryWindow:_content_metrics()
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_top = _scaled_int(BASE_MARGIN_TOP)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local margin_bottom = _scaled_int(BASE_MARGIN_BOTTOM)
    local bar_h = _scaled_int(BASE_BAR_H)
    local filter_h = _scaled_int(BASE_FILTER_H)
    local gap = _scaled_int(BASE_GAP)
    local inner_w = self:GetWidth() - margin_left - margin_right
    local content_top = margin_top + bar_h + gap + filter_h + gap
    local content_h = self:GetHeight() - content_top - margin_bottom - gap - bar_h
    return margin_left, margin_top, inner_w, math.max(1, content_top), math.max(1, content_h), bar_h, filter_h, gap
end

function BestiaryWindow:layout()
    local margin_left, margin_top, inner_w, content_top, content_h, bar_h, filter_h, gap = self:_content_metrics()

    self.nav_bar:SetPosition(margin_left, margin_top)
    self.nav_bar:SetSize(inner_w, bar_h)

    local order_label_w = _scaled_int(BASE_ORDER_LABEL_W)
    local sort_w = _scaled_int(BASE_SORT_W)
    local nav_w = _scaled_int(BASE_NAV_W)
    local page_w = _scaled_int(BASE_PAGE_W)

    self.order_label:SetPosition(0, 0)
    self.order_label:SetSize(order_label_w, bar_h)

    self.sort_dropdown:SetPosition(order_label_w + gap, 0)
    self.sort_dropdown:SetSize(sort_w, bar_h)

    self.page_bar:SetSize((2 * nav_w) + page_w + (2 * gap), bar_h)
    self.page_bar:SetPosition(
        margin_left + math.max(0, math.floor((inner_w - self.page_bar:GetWidth()) / 2)),
        self:GetHeight() - _scaled_int(BASE_MARGIN_BOTTOM) - bar_h
    )

    self.prev_button:SetPosition(0, 0)
    self.prev_button:SetSize(nav_w, bar_h)
    self.page_label:SetPosition(nav_w + gap, 0)
    self.page_label:SetSize(page_w, bar_h)
    self.next_button:SetPosition(nav_w + gap + page_w + gap, 0)
    self.next_button:SetSize(nav_w, bar_h)

    local taxonomy_left = order_label_w + gap + sort_w + (2 * gap)
    local taxonomy_w = math.max(1, inner_w - taxonomy_left)
    self.taxonomy_bar:SetPosition(taxonomy_left, 0)
    self.taxonomy_bar:SetSize(taxonomy_w, bar_h)

    local genus_label_w = math.min(_scaled_int(BASE_GENUS_LABEL_W), math.max(1, taxonomy_w))
    local taxonomy_value_max_w = _scaled_int(BASE_TAXONOMY_VALUE_MAX_W)
    local cursor_x = 0

    self.genus_label:SetPosition(cursor_x, 0)
    self.genus_label:SetSize(genus_label_w, bar_h)
    cursor_x = cursor_x + genus_label_w + gap

    local dropdown_space = math.max(2, taxonomy_w - cursor_x)
    local dropdown_gap = math.min(gap, math.max(0, dropdown_space - 2))
    local shared_dropdown_space = math.max(2, dropdown_space - dropdown_gap)
    local genus_dropdown_w
    local subcategory_dropdown_w

    if shared_dropdown_space >= (2 * taxonomy_value_max_w) then
        genus_dropdown_w = taxonomy_value_max_w
        subcategory_dropdown_w = taxonomy_value_max_w
    else
        genus_dropdown_w = math.max(1, math.floor(shared_dropdown_space / 2))
        subcategory_dropdown_w = math.max(1, shared_dropdown_space - genus_dropdown_w)
    end

    self.genus_dropdown:SetPosition(cursor_x, 0)
    self.genus_dropdown:SetSize(genus_dropdown_w, bar_h)
    cursor_x = cursor_x + genus_dropdown_w + dropdown_gap

    self.subcategory_label:SetPosition(cursor_x, 0)
    self.subcategory_label:SetSize(0, 0)
    self.subcategory_dropdown:SetPosition(cursor_x, 0)
    self.subcategory_dropdown:SetSize(subcategory_dropdown_w, bar_h)

    self.filter_bar:SetPosition(margin_left, margin_top + bar_h + gap)
    self.filter_bar:SetSize(inner_w, filter_h)

    local area_slot_size = filter_h
    local clear_w = _scaled_int(BASE_CLEAR_W)
    local area_slot_x = 0
    local filter_x = area_slot_size + gap
    local filter_w = math.max(1, inner_w - clear_w - gap - filter_x)
    self.clear_button:SetPosition(inner_w - clear_w, 0)
    self.clear_button:SetSize(clear_w, filter_h)
    self.area_slot:SetPosition(area_slot_x, 0)
    self.area_slot:SetSize(area_slot_size, area_slot_size)
    self.area_slot_cover:SetPosition(area_slot_x, 0)
    self.area_slot_cover:SetSize(area_slot_size, area_slot_size)
    self.area_slot_icon:SetPosition(area_slot_x, 0)
    _set_area_slot_icon_background(self, area_slot_size, area_slot_size)
    self.area_label:SetPosition(0, 0)
    self.area_label:SetSize(0, 0)
    self.filter_tb:SetPosition(filter_x, 0)
    self.filter_tb:SetSize(filter_w, filter_h)

    self.content:SetPosition(margin_left, content_top)
    self.content:SetSize(inner_w, content_h)

    self.empty_label:SetPosition(0, math.max(0, math.floor((content_h - bar_h) / 2)))
    self.empty_label:SetSize(inner_w, bar_h)
end

function BestiaryWindow:refresh_from_store(force)
    local generation = _G.bestiary_cache_generation or 0
    if force ~= true and self._last_generation == generation then
        return
    end

    self._last_generation = generation
    self.all_records = _build_records()
    self._prepared_content_w = 0
    self._prepared_content_h = 0
    self._prepared_record_key = 0
    self:refresh_taxonomy_filters()
    self:apply_view()
end

function BestiaryWindow:_prepare_records(records)
    local column_count, _, bucket_content_w = self:_column_metrics()
    local line_h = _scaled_int(BASE_LINE_H)
    local separator_h = _scaled_int(BASE_ROW_SEPARATOR)
    local pad_y = _scaled_int(BASE_ROW_PAD_Y)
    local row_gap_y = _scaled_int(BASE_ROW_GAP_Y)
    local column_w = math.max(1, math.floor(bucket_content_w / column_count))
    local inner_w = math.max(1, column_w - (2 * _scaled_int(BASE_ROW_PAD_X)))

    for i = 1, #records do
        local record = records[i]
        local chip_texts = record._drop_texts
        if type(chip_texts) ~= "table" then
            chip_texts = {}
            for di = 1, #record.drops do
                local drop = record.drops[di]
                local text
                if type(drop.rate) == "number" then
                    text = drop.name .. ": " .. _format_percent(drop.rate)
                else
                    text = drop.name
                end
                chip_texts[#chip_texts + 1] = { text = text, chest = drop.chest == true }
            end

            if #chip_texts == 0 then
                chip_texts = { { text = TR("No drops seen."), chest = false } }
            end

            record._drop_texts = chip_texts
        end

        local chip_layout, drop_h = _build_chip_layout(chip_texts, inner_w)

        local meta_parts = {}
        if type(record.genus) == "string" and record.genus ~= "" then
            meta_parts[#meta_parts + 1] = record.genus
        end
        if type(record.subcategory) == "string" and record.subcategory ~= "" then
            meta_parts[#meta_parts + 1] = record.subcategory
        end

        record.level_text = TR("Level") .. ": " .. _format_range(record.level_min, record.level_max)
        record.meta_text = #meta_parts > 0 and table.concat(meta_parts, " / ") or "-"
        record.morale_text = TR("Morale") .. ": " .. _format_number_range(record.morale_min, record.morale_max)
        record.power_text = TR("Power") .. ": " .. _format_number_range(record.power_min, record.power_max)
        record._chip_layout = chip_layout
        record._drop_height = drop_h
        record._view_height = pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h
    end
end

function BestiaryWindow:_measure_record_height(record, width)
    local pad_x = _scaled_int(BASE_ROW_PAD_X)
    local pad_y = _scaled_int(BASE_ROW_PAD_Y)
    local row_gap_y = _scaled_int(BASE_ROW_GAP_Y)
    local line_h = _scaled_int(BASE_LINE_H)
    local separator_h = _scaled_int(BASE_ROW_SEPARATOR)
    local inner_w = math.max(1, width - (2 * pad_x))
    local drop_texts = record ~= nil and record._drop_texts or nil

    if type(drop_texts) ~= "table" then
        drop_texts = { TR("No drops seen.") }
    end

    local _, drop_h = _build_chip_layout(drop_texts, inner_w)
    return pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h
end

function BestiaryWindow:_column_metrics()
    local window_w = math.max(1, math.floor(self:GetWidth() + 0.5))
    local content_w = math.max(1, math.floor(self.content:GetWidth() + 0.5))
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local column_target_w = math.max(1, BASE_COLUMN_W)
    local column_count = math.max(1, math.floor(window_w / column_target_w))
    local bucket_window_w = math.max(column_target_w, column_count * column_target_w)
    local bucket_content_w = math.max(1, bucket_window_w - margin_left - margin_right)
    return column_count, content_w, bucket_content_w
end

function BestiaryWindow:refresh_layout_view(force)
    local column_count, content_w, bucket_content_w = self:_column_metrics()
    local content_h = math.max(1, self.content:GetHeight())
    local width_changed = self._prepared_content_w ~= content_w
    local height_changed = self._prepared_content_h ~= content_h
    local record_key = (column_count * 10000) + bucket_content_w

    if force ~= true and width_changed ~= true and height_changed ~= true then
        self:render_page()
        return
    end

    self._prepared_content_w = content_w
    self._prepared_content_h = content_h

    if self._prepared_record_key ~= record_key then
        self._prepared_record_key = record_key
        self:_prepare_records(self.records)
    end
    self.pages = self:_build_pages(self.records)

    if #self.pages == 0 then
        self.page_index = 1
    elseif self.page_index > #self.pages then
        self.page_index = #self.pages
    elseif self.page_index < 1 then
        self.page_index = 1
    end

    self:render_page()
end

function BestiaryWindow:_build_pages(records)
    local pages = {}
    local content_h = math.max(1, self.content:GetHeight())
    local column_count, content_w = self:_column_metrics()
    local row_gap = _scaled_int(BASE_GAP)
    local page = nil
    local column_heights = nil

    local function begin_page()
        page = { items = {} }
        column_heights = {}
        for ci = 1, column_count do
            column_heights[ci] = 0
        end
    end

    local function shortest_column_slot()
        local best_slot = 1
        local best_height = column_heights[1]
        for ci = 2, column_count do
            local height = column_heights[ci]
            if height < best_height then
                best_slot = ci
                best_height = height
            end
        end
        return best_slot
    end

    for record_index = 1, #records do
        if page == nil then
            begin_page()
        end

        local column_slot = shortest_column_slot()
        local column_index = column_slot - 1
        local x = math.floor((column_index * content_w) / column_count)
        local next_x = math.floor(((column_index + 1) * content_w) / column_count)
        local item_w = math.max(1, next_x - x)
        local height = self:_measure_record_height(records[record_index], item_w)
        local y = column_heights[column_slot]
        if y > 0 then
            y = y + row_gap
        end

        if #page.items > 0 and (y + height) > content_h then
            pages[#pages + 1] = page
            begin_page()
            column_index = 0
            column_slot = 1
            x = 0
            next_x = math.floor(content_w / column_count)
            item_w = math.max(1, next_x - x)
            height = self:_measure_record_height(records[record_index], item_w)
            y = 0
        end

        page.items[#page.items + 1] = {
            index = record_index,
            c = column_slot,
            x = x,
            y = y,
            w = item_w,
        }

        column_heights[column_slot] = y + height
    end

    if page ~= nil and #page.items > 0 then
        pages[#pages + 1] = page
    end

    return pages
end

function BestiaryWindow:apply_view()
    local filtered = {}
    for i = 1, #self.all_records do
        local record = self.all_records[i]
        local genus_ok = self.genus_filter == FILTER_ALL or record.genus == self.genus_filter
        local subcategory_ok = self.subcategory_filter == FILTER_NONE or self.subcategory_filter == FILTER_ALL or record.subcategory == self.subcategory_filter
        if genus_ok == true and subcategory_ok == true and _matches_groups(self.filter_groups, record.haystack_lower) == true then
            filtered[#filtered + 1] = record
        end
    end

    table.sort(filtered, function(left, right)
        return _compare_records(self.sort_mode, left, right)
    end)

    self.records = filtered
    self._prepared_content_w = 0
    self._prepared_content_h = 0
    self._prepared_record_key = 0
    self:refresh_layout_view(true)
end

function BestiaryWindow:render_page()
    local page_count = #self.pages
    self.page_label:SetText(tostring(self.page_index) .. " / " .. tostring(math.max(1, page_count)))
    if self.prev_button.SetEnabled ~= nil then
        self.prev_button:SetEnabled(page_count > 0 and self.page_index > 1)
    end
    if self.next_button.SetEnabled ~= nil then
        self.next_button:SetEnabled(page_count > 0 and self.page_index < page_count)
    end

    if #self.records == 0 then
        if #self.all_records == 0 then
            self.empty_label:SetText(TR("No bestiary entries yet."))
        else
            self.empty_label:SetText(TR("No matching bestiary entries."))
        end
        self.empty_label:SetVisible(true)
        for i = 1, #self.column_separators do
            self.column_separators[i]:SetVisible(false)
        end
        for i = 1, #self.entries do
            self.entries[i]:SetVisible(false)
        end
        return
    end

    self.empty_label:SetVisible(false)

    local page = self.pages[self.page_index]
    if page == nil then
        for i = 1, #self.column_separators do
            self.column_separators[i]:SetVisible(false)
        end
        for i = 1, #self.entries do
            self.entries[i]:SetVisible(false)
        end
        return
    end

    local items = page.items or {}
    local count = #items
    self:_ensure_rows(count)

    local column_count, content_w = self:_column_metrics()
    local separator_w = _scaled_int(BASE_ROW_SEPARATOR)
    local separator_count = math.max(0, math.min(column_count, count) - 1)
    self:_ensure_column_separators(separator_count)
    for i = 1, separator_count do
        local boundary_x = math.floor((i * content_w) / column_count)
        local separator = self.column_separators[i]
        separator:SetPosition(math.max(0, boundary_x - math.floor(separator_w / 2)), 0)
        separator:SetSize(separator_w, self.content:GetHeight())
        separator:SetVisible(true)
    end
    for i = separator_count + 1, #self.column_separators do
        self.column_separators[i]:SetVisible(false)
    end

    for i = 1, count do
        local item = items[i]
        local record = self.records[item.index]
        local row = self.entries[i]
        row:bind(record, item.w)
    end

    local column_heights = {}
    for i = 1, column_count do
        column_heights[i] = 0
    end

    for i = 1, count do
        local item = items[i]
        local row = self.entries[i]
        local column_slot = item.c or 1
        local y = column_heights[column_slot]
        if y > 0 then
            y = y + _scaled_int(BASE_GAP)
        end
        row:SetPosition(item.x, y)
        column_heights[column_slot] = y + row:GetHeight()
    end

    for i = count + 1, #self.entries do
        self.entries[i]:SetVisible(false)
    end
end

Bestiary.BestiaryWindow = BestiaryWindow
