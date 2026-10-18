-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local measure_text_width = _G.LUI.Utils.measure_text_width
local cached_text_width = _G.LUI.Utils.cached_text_width
local Defaults = _G.LUI.Settings.Defaults
local BestiaryCache = _G.LUI.Runtime.Caches.Bestiary
local Flags = _G.LUI.Runtime.Flags
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Encyclopedia = _G.LUI.Features.Encyclopedia
local Windows = _G.LUI.Runtime.Windows
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Inventory.filter"
import "LUI.src.Utils.font"
import "LUI.src.Utils.text_width"
import "LUI.src.Utils.search_query"

local DATA_ACCESS = Encyclopedia.DataAccess
local Style = UI.Widgets.Style

-- Bestiary icon for shortcut button: 0x410E0435
-- Parchment icon: 0x410E9288
-- Book no background: 0x41003199
-- Book background: 0x41002DC3
-- Book icon pressed: 0x41005F00 25x25
-- Book icon normal: 0x41005F07 25x25
-- Book icon hover: 0x41005F0F 25x25

local BASE_MARGIN_LEFT = 8
local BASE_MARGIN_TOP = 8
local BASE_MARGIN_RIGHT = 8
local BASE_MARGIN_BOTTOM = 8

-- shared with the encyclopedia item tabs so all tab content aligns
Encyclopedia.CONTENT_MARGINS = {
    left = BASE_MARGIN_LEFT,
    top = BASE_MARGIN_TOP,
    right = BASE_MARGIN_RIGHT,
    bottom = BASE_MARGIN_BOTTOM,
}
local BASE_BAR_H = 22
local BASE_FILTER_H = 22
local BASE_GAP = 4
local BASE_LEVEL_INPUT_W = 44
local BASE_NAV_W = 22
local BASE_PAGE_W = 74
local BASE_GENUS_LABEL_W = 40
local BASE_TAXONOMY_VALUE_MAX_W = 200
local BASE_MIN_W = 600
local BASE_MIN_H = 240
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
local BASE_TAXONOMY_PAD_X = 5
local BASE_RESIZE_REFRESH_DELAY = 0.10
local BASE_RESIZE_REFLOW_MIN_INTERVAL = 0.50
-- kill/observation events bump the cache generation many times per second
-- in combat; a full 12k-record rebuild per bump would stutter every kill
local BASE_STORE_REFRESH_MIN_INTERVAL = 2.0
local BASE_COLUMN_W = 600

-- location icon inset inside the /loc quickslot square
local BASE_AREA_ICON_INSET = 3


local FILTER_ALL = "__all"
local FILTER_NONE = "__none"
local BESTIARY_QUERY_TOKENS = {
    loc = true,
    gen = true,
    lvl = true,
}


local COLOR_DROP_CHIP_BORDER = Turbine.UI.Color(1, 0.28, 0.28, 0.28)
local COLOR_DROP_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_DROP_CHIP_TEXT = Turbine.UI.Color(1, 0.76, 0.88, 0.79)
local COLOR_CHEST_CHIP_BORDER = Turbine.UI.Color(1, 0.45, 0.32, 0.12)
local COLOR_CHEST_CHIP_BG = Turbine.UI.Color(1, 0.08, 0.08, 0.08)
local COLOR_CHEST_CHIP_TEXT = Turbine.UI.Color(1, 0.95, 0.83, 0.49)
local COLOR_DROP_MATCH_CHIP_BORDER = Turbine.UI.Color(1, 0.18, 0.66, 0.82)

local function _scaled_int(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end
    return string.lower(text)
end

local function _trim_text(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function _same_text(left, right)
    return _lower_text(_trim_text(left)) == _lower_text(_trim_text(right))
end

local function _is_all_filter_token(value)
    return _same_text(value, "all") == true or _same_text(value, TR["All"]) == true
end

local function _parse_location_token_value(value)
    local parts = SearchQuery.parse_path(value)
    if type(parts) ~= "table" or #parts == 0 or #parts > 3 then
        return nil
    end

    return parts
end

-- loc: value -> list of region > area > instance paths; several places are
-- separated by "|" (overlapping zones: "Bree-land | The Great River");
-- nil when any place is invalid
local function _parse_location_paths(value)
    if type(value) ~= "string" then
        return nil
    end
    local paths = {}
    for place in string.gmatch(value .. "|", "([^|]*)|") do
        local parts = _parse_location_token_value(place)
        if parts == nil then
            return nil
        end
        paths[#paths + 1] = parts
    end
    if #paths == 0 then
        return nil
    end
    return paths
end

local function _format_location_paths(paths)
    local out = {}
    for i = 1, #paths do
        out[i] = SearchQuery.format_path(paths[i])
    end
    return table.concat(out, " | ")
end

local function _parse_genus_token_value(value)
    local parts = SearchQuery.parse_path(value)
    if type(parts) ~= "table" or #parts == 0 or #parts > 2 then
        return FILTER_ALL, FILTER_NONE, false
    end

    local genus = _trim_text(parts[1])
    if genus == "" or _is_all_filter_token(genus) == true then
        return FILTER_ALL, FILTER_NONE, true
    end

    if #parts == 1 then
        return genus, FILTER_ALL, true
    end

    local subcategory = _trim_text(parts[2])
    if subcategory == "" or _is_all_filter_token(subcategory) == true then
        return genus, FILTER_ALL, true
    end

    return genus, subcategory, true
end

-- SearchQuery.match_key of a record field (case / article-insensitive),
-- cached on the record
local function _record_key(record, field)
    local cache = record._match_keys
    if cache == nil then
        cache = {}
        record._match_keys = cache
    end
    local key = cache[field]
    if key == nil then
        key = SearchQuery.match_key(record[field] or "")
        cache[field] = key
    end
    return key
end

-- keys: SearchQuery.match_key of each region > area > instance part; a
-- single part also matches the instance (instance creatures have no region
-- in the data: loc:<instance> finds them)
local function _record_matches_location_keys(record, keys)
    if keys == nil or #keys == 0 then
        return true
    end
    if #keys == 1 and _record_key(record, "instance") == keys[1] then
        return true
    end
    if _record_key(record, "region") ~= keys[1] then
        return false
    end
    if #keys >= 2 and _record_key(record, "area") ~= keys[2] then
        return false
    end
    if #keys >= 3 and _record_key(record, "instance") ~= keys[3] then
        return false
    end

    return true
end

-- several places (keys per path): a record in any of them matches
local function _record_matches_location_paths(record, paths_keys)
    for i = 1, #paths_keys do
        if _record_matches_location_keys(record, paths_keys[i]) == true then
            return true
        end
    end
    return false
end

-- /loc zone path (deepest level first, each level { name, alias... }) ->
-- the Bestiary region and area it names (area nil for a region), from the
-- loc suggestion index (Bestiary paths + captures); nil when no level names
-- a Bestiary region or area. The zone table and the Bestiary disagree on
-- levels ("Wildwood" is a zone, the Bestiary has Bree-land > The Wildwood)
-- and on language (the zone table is English), so each level is tried as
-- an area, then as a region, by localized and English name, case /
-- article-insensitive. An area found under several regions prefers the
-- region an outer level names.
local function _resolve_location(index, levels)
    local keyed = {}
    for i = 1, #levels do
        local keys = {}
        for _, name in ipairs(levels[i]) do
            keys[SearchQuery.match_key(name)] = true
        end
        keyed[i] = keys
    end
    local function named(keys, text, english)
        return (text ~= nil and keys[SearchQuery.match_key(text)] == true)
            or (english ~= nil and keys[SearchQuery.match_key(english)] == true)
    end
    local function outer_region(from)
        for j = from, #keyed do
            for _, entry in ipairs(index) do
                if named(keyed[j], entry.name, entry.en) then
                    return entry
                end
            end
        end
        return nil
    end
    for i = 1, #keyed do
        local preferred = outer_region(i + 1)
        local found_entry, found_area = nil, nil
        for _, entry in ipairs(index) do
            for c = 1, #entry.children do
                local english = entry.children_en ~= nil and entry.children_en[c] or nil
                if named(keyed[i], entry.children[c], english)
                    and (found_entry == nil or entry == preferred) then
                    found_entry, found_area = entry, entry.children[c]
                end
            end
        end
        if found_entry ~= nil then
            return found_entry.name, found_area
        end
        for _, entry in ipairs(index) do
            if named(keyed[i], entry.name, entry.en) then
                return entry.name, nil
            end
        end
    end
    return nil, nil
end

-- tinted location icon centred over the /loc quickslot, hover-aware
local function _sync_area_slot_icon(window)
    local x, y = window.area_slot:GetPosition()
    local inset = _scaled_int(BASE_AREA_ICON_INSET)
    local size = math.max(1, window.area_slot:GetWidth() - (inset * 2))
    window.area_slot_icon:set_icon(UI.Widgets.Icons.path("map_pinned"), size, size)
    if window._area_slot_hovered == true then
        window.area_slot_icon:set_tint(Style.ICON_FOREGROUND_HOVER)
    else
        window.area_slot_icon:set_tint(Style.ICON_FOREGROUND)
    end
    window.area_slot_icon:SetPosition(x + inset, y + inset)
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
    return Encyclopedia.CardWidgets.format_number(_to_number(value, 0))
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
    return Encyclopedia.CardWidgets.format_percent(_to_number(percent, 0))
end

local function _parse_level_filter_value(text)
    local trimmed = _trim_text(text)
    if trimmed == "" then
        return nil
    end

    local value = tonumber(trimmed)
    if value == nil then
        return nil
    end

    value = math.floor(value)
    if value < 1 then
        return nil
    end

    return value
end

local function _read_level_filter_range(window)
    if type(window) ~= "table" then
        return nil, nil
    end

    local filter_min = _parse_level_filter_value(window.level_min_box:GetText())
    local filter_max = _parse_level_filter_value(window.level_max_box:GetText())
    if filter_min ~= nil and filter_max ~= nil and filter_min > filter_max then
        filter_min, filter_max = filter_max, filter_min
    end

    return filter_min, filter_max
end

local function _matches_level_range(record, filter_min, filter_max)
    if filter_min == nil and filter_max == nil then
        return true
    end
    if type(record) ~= "table" then
        return false
    end

    local record_min = _to_number(record.level_min, 0)
    local record_max = _to_number(record.level_max, record_min)
    if record_min <= 0 and record_max <= 0 then
        return false
    end
    if record_min <= 0 then
        record_min = record_max
    end
    if record_max <= 0 then
        record_max = record_min
    end

    if filter_min ~= nil and record_max < filter_min then
        return false
    end
    if filter_max ~= nil and record_min > filter_max then
        return false
    end

    return true
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

-- merged view of a single name: builtin first, session cache on top -
-- the same order _merged_bestiary applies to the whole set. Nil when the
-- name exists in neither source.
local function _merged_entry_for(name)
    local builtin = DATA_ACCESS.builtin_source()[name]
    local cache_entry = DATA_ACCESS.ensure_cache()[name]
    if type(cache_entry) ~= "table" or DATA_ACCESS.is_alias_entry(cache_entry) == true then
        cache_entry = nil
    end
    if type(builtin) ~= "table" and cache_entry == nil then
        return nil
    end

    local merged = DATA_ACCESS.new_merged_entry(name)
    if type(builtin) == "table" then
        DATA_ACCESS.merge_entry(merged, builtin, name)
    end
    if cache_entry ~= nil then
        DATA_ACCESS.merge_entry(merged, cache_entry, name)
    end
    return merged
end

local function _build_record(name, entry)
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
                if power > 0 and (power_min <= 0 or power < power_min) then power_min = power end
                if power > power_max then power_max = power end
            end
        end
    end

    local drop_records = DATA_ACCESS.build_drop_records(entry)
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
        local drop = drop_records[i]
        local drop_name_lower = _lower_text(drop ~= nil and drop.name or nil)
        if type(drop) == "table" then
            drop._name_lower = drop_name_lower
            drop._match_key = drop_name_lower ~= "" and ((drop.chest == true and "c:" or "d:") .. drop_name_lower) or nil
        end
        filter_parts[#filter_parts + 1] = drop_name_lower
    end
    _append_filter_values(filter_parts, entry.combat_effectiveness)
    _append_filter_values(filter_parts, entry.resistances)
    _append_filter_values(filter_parts, entry.mitigation)
    _append_filter_values(filter_parts, entry.abilities)
    -- quest_involvement/deed_involvement are quest/deed game-id lists
    -- (numbers), never search text

    return {
        key = name,
        name = display_name,
        sort_name = _lower_text(DATA_ACCESS.display_name(display_name)),
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

-- Records come out already in display order: the packed DB bakes a
-- per-language A-Z permutation (order_<lang>), so no runtime sort runs.
-- Session-captured mobs missing from the packed DB (few) are the only
-- insertions.
local function _build_records()
    local Lore = _G.LUI.Data.Lore
    local LoreBestiary = Lore.Bestiary
    Lore.load_bestiary()
    local cache = DATA_ACCESS.ensure_cache()

    local out = {}
    local seen = {}
    for i = 1, LoreBestiary.count do
        local ordinal = LoreBestiary.display_ordinal(i)
        local name = LoreBestiary.key_at(ordinal)
        local merged = DATA_ACCESS.new_merged_entry(name)
        DATA_ACCESS.merge_entry(merged, LoreBestiary.decode(ordinal), name)
        local cached = cache[name]
        if type(cached) == "table" and DATA_ACCESS.is_alias_entry(cached) ~= true then
            DATA_ACCESS.merge_entry(merged, cached, name)
        end
        seen[name] = true
        out[#out + 1] = _build_record(name, merged)
    end

    for name, cached in pairs(cache) do
        if seen[name] ~= true and type(name) == "string" and type(cached) == "table"
            and DATA_ACCESS.is_alias_entry(cached) ~= true then
            local merged = DATA_ACCESS.new_merged_entry(name)
            DATA_ACCESS.merge_entry(merged, cached, name)
            local record = _build_record(name, merged)
            local pos = #out + 1
            for k = 1, #out do
                if record.sort_name < out[k].sort_name then
                    pos = k
                    break
                end
            end
            table.insert(out, pos, record)
        end
    end

    return out
end

local function _drop_match_key(drop_name, chest)
    if type(drop_name) ~= "string" or drop_name == "" then
        return nil
    end

    return (chest == true and "c:" or "d:") .. _lower_text(drop_name)
end

local function _build_group_matched_drop_lookup(record, group)
    if type(record) ~= "table" or type(record.drops) ~= "table" or type(group) ~= "table" or #group == 0 then
        return nil
    end

    local full_matches = nil
    local partial_matches = nil
    for di = 1, #record.drops do
        local drop = record.drops[di]
        local drop_name_lower = type(drop) == "table" and drop._name_lower or nil
        local key = type(drop) == "table" and drop._match_key or nil

        if type(drop_name_lower) ~= "string" then
            drop_name_lower = _lower_text(drop ~= nil and drop.name or nil)
            if type(drop) == "table" then
                drop._name_lower = drop_name_lower
            end
        end
        if key == nil and drop_name_lower ~= "" then
            key = _drop_match_key(drop ~= nil and drop.name or nil, drop ~= nil and drop.chest == true)
            if type(drop) == "table" then
                drop._match_key = key
            end
        end

        if drop_name_lower ~= "" and key ~= nil then
            local full_match = true
            local partial_match = false
            for ti = 1, #group do
                local term = group[ti]
                if term ~= "" then
                    if string.find(drop_name_lower, term, 1, true) ~= nil then
                        partial_match = true
                    else
                        full_match = false
                        if full_matches ~= nil or partial_match == true then
                            break
                        end
                    end
                end
            end

            if full_match == true then
                if full_matches == nil then
                    full_matches = {}
                end
                full_matches[key] = true
            elseif full_matches == nil and partial_match == true then
                if partial_matches == nil then
                    partial_matches = {}
                end
                partial_matches[key] = true
            end
        end
    end

    return full_matches or partial_matches
end

local function _match_record_query(record, groups)
    if groups == nil or #groups == 0 then
        return true, nil
    end
    if type(record) ~= "table" or type(record.drops) ~= "table" or type(record.haystack_lower) ~= "string" then
        return false, nil
    end

    local matched = nil
    local query_ok = false
    for gi = 1, #groups do
        local group = groups[gi]
        if SearchQuery.group_matches(group, record.haystack_lower) == true then
            query_ok = true
            local group_matches = _build_group_matched_drop_lookup(record, group)
            if type(group_matches) == "table" then
                if matched == nil then
                    matched = {}
                end
                for key in pairs(group_matches) do
                    matched[key] = true
                end
            end
        end
    end

    return query_ok, matched
end

-- every chip must match (AND across chips, OR inside one); drop highlights
-- merge. Classic search is a single chip.
local function _match_record_chips(record, chip_groups)
    if #chip_groups == 1 then
        return _match_record_query(record, chip_groups[1])
    end
    local matched = nil
    for ci = 1, #chip_groups do
        local ok, chip_matched = _match_record_query(record, chip_groups[ci])
        if ok ~= true then
            return false, nil
        end
        if chip_matched ~= nil then
            if matched == nil then
                matched = {}
            end
            for key in pairs(chip_matched) do
                matched[key] = true
            end
        end
    end
    return true, matched
end

-- Classic search waits for 2 characters, as the item tabs
-- (SearchQuery.evaluate_domain): shorter words are ignored, and while a
-- group has no 2+ character word the text filter is off (still typing)
local MIN_QUERY_TERM_LEN = 2

local function _drop_short_terms(chip_groups)
    local out = {}
    for ci = 1, #chip_groups do
        local groups = {}
        for gi = 1, #chip_groups[ci] do
            local group = {}
            for _, term in ipairs(chip_groups[ci][gi]) do
                if #term >= MIN_QUERY_TERM_LEN then
                    group[#group + 1] = term
                end
            end
            if #group == 0 then
                return {}
            end
            groups[#groups + 1] = group
        end
        out[#out + 1] = groups
    end
    return out
end

-- bestiary results list in fixed name order, matching the item tabs'
-- baked label-sorted permutations (the Order menu was removed: title-bar
-- menus should not exist unless every tab participates)
-- sort by the localized name the row displays, not the English key
local function _compare_records(left, right)
    return left.sort_name < right.sort_name
end

-- the row chips, meta texts and level filter label are all drawn in the
-- small content font
local function _small_font_size()
    return Style.CONTENT_SMALL_FONT_SIZE * State.settings.global.scale
end

local function _estimate_chip_width(text)
    local pad_x = _scaled_int(BASE_CHIP_PAD_X)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    -- memoized: pagination lays out every filtered record's drop chips, and
    -- the same item names repeat across many creatures; +2 for glyph edges
    local text_w = cached_text_width(text or "", Style.CONTENT_SMALL_FONT_NAME, _small_font_size()) + 2
    local min_w = _scaled_int(BASE_CHIP_MIN_W)
    local width = text_w + (2 * (pad_x + border_w))
    if width < min_w then
        width = min_w
    end
    return width
end

local function _small_text_width(text)
    return measure_text_width(text or "", Style.CONTENT_SMALL_FONT_NAME, _small_font_size()) + 2
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
            match_key = type(item) == "table" and item.match_key or nil,
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
    control:SetBackColor(Style.CONTROL_BACKGROUND_READONLY)
end

local function _build_taxonomy_text(record)
    if type(record) ~= "table" then
        return ""
    end

    local genus = type(record.genus) == "string" and record.genus or ""
    local subcategory = type(record.subcategory) == "string" and record.subcategory or ""

    if genus ~= "" and subcategory ~= "" then
        return genus .. " > " .. subcategory
    end
    if genus ~= "" then
        return genus
    end
    if subcategory ~= "" then
        return subcategory
    end

    return ""
end

local function _build_location_text(record)
    if type(record) ~= "table" then
        return ""
    end

    local region = type(record.region) == "string" and record.region or ""
    local area = type(record.area) == "string" and record.area or ""
    local instance = type(record.instance) == "string" and record.instance or ""

    if region ~= "" and area ~= "" then
        return region .. " > " .. area
    end
    if region ~= "" then
        return region
    end
    if instance ~= "" then
        return instance
    end

    return ""
end

local function _ensure_record_drop_texts(record)
    if type(record) ~= "table" then
        return { { text = TR["No drops seen."], chest = false } }
    end

    local chip_texts = record._drop_texts
    if type(chip_texts) == "table" then
        return chip_texts
    end

    chip_texts = {}
    for di = 1, #record.drops do
        local drop = record.drops[di]
        local text
        if type(drop.rate) == "number" then
            text = drop.name .. ": " .. _format_percent(drop.rate)
        else
            text = drop.name
        end
        chip_texts[#chip_texts + 1] = {
            text = text,
            chest = drop.chest == true,
            match_key = drop._match_key or _drop_match_key(drop.name, drop.chest == true),
        }
    end

    if #chip_texts == 0 then
        chip_texts = { { text = TR["No drops seen."], chest = false } }
    end

    record._drop_texts = chip_texts
    return chip_texts
end

local function _ensure_record_display_texts(record)
    if type(record) ~= "table" then
        return
    end

    _ensure_record_drop_texts(record)
    record.level_text = TR["Level"] .. ": " .. _format_range(record.level_min, record.level_max)
    record.taxonomy_text = _build_taxonomy_text(record)
    record.location_text = _build_location_text(record)
    record.morale_text = TR["Morale"] .. ": " .. _format_number_range(record.morale_min, record.morale_max)
    record.power_text = TR["Power"] .. ": " .. _format_number_range(record.power_min, record.power_max)
end

local function _ensure_record_row_layout(record, width)
    if type(record) ~= "table" then
        return
    end

    width = math.max(1, math.floor(_to_number(width, 1) + 0.5))
    _ensure_record_display_texts(record)

    if record._layout_width == width and type(record._chip_layout) == "table"
        and type(record._drop_height) == "number" and type(record._view_height) == "number" then
        return
    end

    local pad_x = _scaled_int(BASE_ROW_PAD_X)
    local pad_y = _scaled_int(BASE_ROW_PAD_Y)
    local row_gap_y = _scaled_int(BASE_ROW_GAP_Y)
    local line_h = _scaled_int(BASE_LINE_H)
    local separator_h = _scaled_int(BASE_ROW_SEPARATOR)
    local inner_w = math.max(1, width - (2 * pad_x))
    local chip_layout, drop_h = _build_chip_layout(_ensure_record_drop_texts(record), inner_w)
    local has_meta_line = record.taxonomy_text ~= "" or record.location_text ~= ""
    local meta_line_extra = has_meta_line == true and (line_h + row_gap_y) or 0

    record._layout_width = width
    record._chip_layout = chip_layout
    record._drop_height = drop_h
    record._view_height = pad_y + line_h + row_gap_y + line_h + row_gap_y + meta_line_extra + drop_h + pad_y + separator_h
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

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetMultiline(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self:apply_settings()
end

function DropChip:apply_settings(chest, matched)
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    self.inner:SetPosition(border_w, border_w)
    self.label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    if matched == true then
        self:SetBackColor(COLOR_DROP_MATCH_CHIP_BORDER)
    elseif chest == true then
        self:SetBackColor(COLOR_CHEST_CHIP_BORDER)
    else
        self:SetBackColor(COLOR_DROP_CHIP_BORDER)
    end
    if chest == true then
        self.inner:SetBackColor(COLOR_CHEST_CHIP_BG)
        self.label:SetForeColor(COLOR_CHEST_CHIP_TEXT)
    else
        self.inner:SetBackColor(COLOR_DROP_CHIP_BG)
        self.label:SetForeColor(COLOR_DROP_CHIP_TEXT)
    end
    self.label:SetOutlineColor(Style.TEXT_OUTLINE)
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
    self:SetMouseVisible(true)
    self.MouseDoubleClick = function(_, args)
        if args == nil or args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self.owner_window:open_card_for_record(self._record, self)
    end

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetMultiline(false)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.taxonomy_label = UI.Widgets.LuiLabel()
    self.taxonomy_label:SetParent(self)
    self.taxonomy_label:SetMouseVisible(false)
    self.taxonomy_label:SetMultiline(false)
    self.taxonomy_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetMultiline(false)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.morale_label = UI.Widgets.LuiLabel()
    self.morale_label:SetParent(self)
    self.morale_label:SetMouseVisible(false)
    self.morale_label:SetMultiline(false)
    self.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.power_label = UI.Widgets.LuiLabel()
    self.power_label:SetParent(self)
    self.power_label:SetMouseVisible(false)
    self.power_label:SetMultiline(false)
    self.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.location_label = UI.Widgets.LuiLabel()
    self.location_label:SetParent(self)
    self.location_label:SetMouseVisible(false)
    self.location_label:SetMultiline(false)
    self.location_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

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
    self.name_label:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    self.name_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.name_label:SetForeColor(Style.FOREGROUND)
    self.name_label:SetOutlineColor(Style.TEXT_OUTLINE)

    local meta_font = _scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE)
    local taxonomy_font = _scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE)

    self.taxonomy_label:SetFont(taxonomy_font)
    self.taxonomy_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.taxonomy_label:SetForeColor(Turbine.UI.Color(1, 0.82, 0.78, 0.55))
    self.taxonomy_label:SetOutlineColor(Style.TEXT_OUTLINE)

    self.level_label:SetFont(meta_font)
    self.level_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.level_label:SetForeColor(Turbine.UI.Color(1, 0.72, 0.58, 0.20))
    self.level_label:SetOutlineColor(Style.TEXT_OUTLINE)

    self.morale_label:SetFont(meta_font)
    self.morale_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.morale_label:SetForeColor(Turbine.UI.Color(1, 0.42, 0.86, 0.44))
    self.morale_label:SetOutlineColor(Style.TEXT_OUTLINE)

    self.power_label:SetFont(meta_font)
    self.power_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.power_label:SetForeColor(Turbine.UI.Color(1, 0.40, 0.68, 0.96))
    self.power_label:SetOutlineColor(Style.TEXT_OUTLINE)

    self.location_label:SetFont(taxonomy_font)
    self.location_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.location_label:SetForeColor(Turbine.UI.Color(1, 0.67, 0.82, 0.93))
    self.location_label:SetOutlineColor(Style.TEXT_OUTLINE)

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
    local column_gap_x = _scaled_int(6)

    if record == nil then
        self._record = nil
        self.taxonomy_label:SetVisible(false)
        self.location_label:SetVisible(false)
        for i = 1, #self.drop_chips do
            self.drop_chips[i]:SetVisible(false)
        end
        self:SetVisible(false)
        return
    end

    _ensure_record_row_layout(record, width)

    local taxonomy_text = record.taxonomy_text or ""
    local location_text = record.location_text or ""
    local has_meta_line = taxonomy_text ~= "" or location_text ~= ""

    local inner_w = math.max(1, width - (2 * pad_x))
    local right_text_w = math.max(
        _small_text_width(record.level_text),
        _small_text_width(record.power_text)
    )
    local right_w = math.min(
        math.max(_scaled_int(72), math.floor((inner_w - column_gap_x) / 2)),
        math.max(_scaled_int(72), right_text_w + (2 * _scaled_int(BASE_TAXONOMY_PAD_X)))
    )
    local left_w = math.max(1, inner_w - right_w - column_gap_x)
    local meta_left_w = inner_w
    local meta_right_w = 0
    local meta_right_x = pad_x
    if taxonomy_text ~= "" and location_text ~= "" then
        meta_left_w = math.max(1, math.floor((inner_w - column_gap_x) / 2))
        meta_right_w = math.max(1, inner_w - meta_left_w - column_gap_x)
        meta_right_x = pad_x + meta_left_w + column_gap_x
    elseif location_text ~= "" then
        meta_left_w = 0
        meta_right_w = inner_w
    end

    local drop_layout = record._chip_layout or {}
    local drop_h = _to_number(record._drop_height, _scaled_int(BASE_CHIP_H))
    local meta_line_extra = has_meta_line == true and (line_h + row_gap_y) or 0
    local height = _to_number(record._view_height, pad_y + line_h + row_gap_y + line_h + row_gap_y + meta_line_extra + drop_h + pad_y + separator_h)

    self._record = record
    self.name_label:SetText(DATA_ACCESS.display_name(record.name))
    self.level_label:SetText(record.level_text)
    self.morale_label:SetText(record.morale_text)
    self.power_label:SetText(record.power_text)

    self:SetSize(width, height)
    self.name_label:SetPosition(pad_x, pad_y)
    self.name_label:SetSize(left_w, line_h)
    self.level_label:SetPosition(pad_x + left_w + column_gap_x, pad_y)
    self.level_label:SetSize(right_w, line_h)
    self.morale_label:SetPosition(pad_x, pad_y + line_h + row_gap_y)
    self.morale_label:SetSize(left_w, line_h)
    self.power_label:SetPosition(pad_x + left_w + column_gap_x, pad_y + line_h + row_gap_y)
    self.power_label:SetSize(right_w, line_h)
    self.taxonomy_label:SetPosition(pad_x, pad_y + (2 * (line_h + row_gap_y)))
    self.taxonomy_label:SetSize(meta_left_w, line_h)
    self.location_label:SetPosition(meta_right_x, pad_y + (2 * (line_h + row_gap_y)))
    self.location_label:SetSize(meta_right_w, line_h)
    self.drop_area:SetPosition(pad_x, pad_y + (2 * line_h) + (2 * row_gap_y) + meta_line_extra)
    self.drop_area:SetSize(inner_w, drop_h)
    self.separator:SetPosition(0, height - separator_h)
    self.separator:SetSize(width, separator_h)

    self.taxonomy_label:SetText(taxonomy_text)
    self.taxonomy_label:SetVisible(taxonomy_text ~= "")

    self.location_label:SetText(location_text)
    self.location_label:SetVisible(location_text ~= "")

    self:_ensure_chip_count(#drop_layout)
    local chip_h = _scaled_int(BASE_CHIP_H)
    for i = 1, #drop_layout do
        local chip_info = drop_layout[i]
        local chip = self.drop_chips[i]
        local matched = type(record._matched_drop_lookup) == "table"
            and chip_info.match_key ~= nil
            and record._matched_drop_lookup[chip_info.match_key] == true
        chip:SetPosition(chip_info.x, chip_info.y)
        chip:apply_settings(chip_info.chest == true, matched)
        chip:bind(chip_info.text, chip_info.w, chip_h)
    end
    for i = #drop_layout + 1, #self.drop_chips do
        self.drop_chips[i]:SetVisible(false)
    end

    self:SetVisible(true)
end

local EncyclopediaWindow = class(UI.Widgets.LuiWindow)

function EncyclopediaWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self:set_title(TR["Encyclopedia"])
    UI.Shortcuts.apply_window_icon(self, "encyclopedia")
    self:set_resizable(true)
    self:hide()
    self:SetWantsUpdates(false)

    self.last_update_at = 0
    -- content only changes on kill events and debounced resizes; this
    -- window has no reason to tick at the vitals refresh rate
    self.update_every = 0.25
    self._last_store_refresh_at = 0
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
    self._suppress_level_text_changed = false

    self.query_state = SearchQuery.parse("", BESTIARY_QUERY_TOKENS)
    self.query_level_min = nil
    self.query_level_max = nil
    self.query_level_filter_active = false
    self.query_level_filter_valid = false
    self.query_genus_filter = FILTER_ALL
    self.query_subcategory_filter = FILTER_NONE
    self.query_genus_filter_active = false
    self.query_genus_filter_valid = false
    self.query_location_filter_active = false
    self.query_location_filter_valid = false
    self.query_location_parts = nil
    self.filter_chip_groups = {}
    self._suggest_index = {}
    self.genus_filter = FILTER_ALL
    self.subcategory_filter = FILTER_NONE
    self._suppress_genus_changed = false
    self._suppress_subcategory_changed = false
    self.all_records = {}
    self.records = {}
    self.pages = {}
    self.entries = {}
    self.column_separators = {}
    local content_host = Turbine.UI.Control()
    content_host:SetMouseVisible(true)
    self:set_central_widget(content_host)

    -- Encyclopedia tabs: the tab bar owns the whole central area and hosts
    -- one content widget per tab -- the bestiary content lives inside
    -- bestiary_host (tab 1), item browsers inside their own hosts
    self._item_panels = {}
    self._item_tab_hosts = {}
    self._active_encyclopedia_tab = 1
    self.bestiary_host = Turbine.UI.Control()
    self.bestiary_host:SetMouseVisible(true)

    self.encyclopedia_tabs = UI.Widgets.LuiTabBar()
    self.encyclopedia_tabs:SetParent(content_host)
    self.encyclopedia_tabs:add_tab(TR["Bestiary"], self.bestiary_host)
    for tab = 2, 7 do
        local host = Turbine.UI.Control()
        host:SetMouseVisible(true)
        self._item_tab_hosts[tab] = host
    end
    self.encyclopedia_tabs:add_tab(TR["Equipment"], self._item_tab_hosts[2])
    self.encyclopedia_tabs:add_tab(TR["Resources"], self._item_tab_hosts[3])
    self.encyclopedia_tabs:add_tab(TR["Consumables"], self._item_tab_hosts[4])
    self.encyclopedia_tabs:add_tab(TR["Housing"], self._item_tab_hosts[5])
    self.encyclopedia_tabs:add_tab(TR["Traceries"], self._item_tab_hosts[6])
    self.encyclopedia_tabs:add_tab(TR["Quests"], self._item_tab_hosts[7])
    self.encyclopedia_tabs.on_tab_changed = function(index)
        self:_set_encyclopedia_tab(index)
    end
    -- same look as the config window tab bars
    self.encyclopedia_tabs:set_content_padding(4)
    self.encyclopedia_tabs:set_show_border_left(false)
    self.encyclopedia_tabs:set_show_border_right(false)
    self.encyclopedia_tabs:set_show_border_bottom(false)
    -- the border setters also drop the tab-button caps; restore them
    self.encyclopedia_tabs:set_show_tab_cap_left(true)
    self.encyclopedia_tabs:set_show_tab_cap_right(true)
    self.encyclopedia_tabs:set_show_tab_cap_bottom(true)
    self.encyclopedia_tabs:set_scale(State.settings.global.scale)
    self.encyclopedia_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 3))
    self.encyclopedia_tabs:set_selected_index(1, false)

    self.nav_bar = Turbine.UI.Control()
    self.nav_bar:SetParent(self.bestiary_host)

    self.page_bar = Turbine.UI.Control()
    self.page_bar:SetParent(self.bestiary_host)

    -- during _sync_pager the caller renders right after, so the callback
    -- skips its own render
    self.pager = UI.Widgets.LuiPager()
    self.pager:SetParent(self.page_bar)
    self.pager.changed = function()
        if self._pager_syncing ~= true then
            self:render_page()
        end
    end

    self.results_label = UI.Widgets.LuiLabel()
    self.results_label:SetParent(self.bestiary_host)
    self.results_label:SetMouseVisible(false)
    self.results_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.results_label:SetForeColor(Style.ALTERNATE_FOREGROUND)

    self.filter_bar = Turbine.UI.Control()
    self.filter_bar:SetParent(self.bestiary_host)

    self.level_bar = Turbine.UI.Control()
    self.level_bar:SetParent(self.bestiary_host)

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self.level_bar)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetSelectable(false)
    self.level_label:SetMultiline(false)
    self.level_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.level_label:SetText(TR["Level"] .. ":")

    self.level_min_box = UI.Widgets.LuiLineEdit()
    self.level_min_box:SetParent(self.level_bar)
    self.level_min_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.level_dash_label = UI.Widgets.LuiLabel()
    self.level_dash_label:SetParent(self.level_bar)
    self.level_dash_label:SetMouseVisible(false)
    self.level_dash_label:SetSelectable(false)
    self.level_dash_label:SetMultiline(false)
    self.level_dash_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.level_dash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_dash_label:SetText("-")

    self.level_max_box = UI.Widgets.LuiLineEdit()
    self.level_max_box:SetParent(self.level_bar)
    self.level_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    local function on_level_filter_changed(box)
        if self._suppress_level_text_changed == true or box == nil then
            return
        end

        local current_text = box:GetText() or ""
        local sanitized_text = string.gsub(current_text, "[^%d]", "")
        if sanitized_text ~= current_text then
            self._suppress_level_text_changed = true
            box:SetText(sanitized_text)
            self._suppress_level_text_changed = false
        end

        self:_sync_pager(1)
        self:apply_view()
    end

    self.level_min_box.TextChanged = function()
        on_level_filter_changed(self.level_min_box)
    end
    self.level_max_box.TextChanged = function()
        on_level_filter_changed(self.level_max_box)
    end

    -- Classic text or Tokens chips (encyclopedia.search_mode)
    self.search_field = UI.Widgets.SearchField()
    self.search_field:SetParent(self.filter_bar)
    self.search_field:set_popup_host(self)
    self.search_field:set_placeholder(TR["Search..."])
    self.search_field:set_keywords({
        {
            key = "loc",
            icon = "map_pinned",
            hint = TR["Location: region or area"],
            aliases = { "location", "area", "region", "zone" },
            values = function()
                return self:_query_suggest_index("loc")
            end,
            child_hint = TR["%d areas"],
        },
        {
            key = "lvl",
            icon = "level",
            hint = TR["Level: 50, >100, 50-60"],
            aliases = { "level", TR["Level"] },
        },
        {
            key = "gen",
            icon = "family",
            hint = TR["Genus: genus or subcategory"],
            aliases = { "genus", "family", "type", TR["Genus"] },
            values = function()
                return self:_query_suggest_index("gen")
            end,
            child_hint = TR["%d subcategories"],
        },
    })
    self.search_field.QueryChanged = function()
        -- a user edit drops the resolved /loc area
        self.current_area = nil
        self.last_applied_area_query = nil
        BestiaryCache.area_filter_query = nil
        BestiaryCache.area_filter_candidates = nil
        self:update_filter()
    end

    self.area_label = UI.Widgets.LuiLabel()
    self.area_label:SetParent(self.filter_bar)
    self.area_label:SetMouseVisible(false)
    self.area_label:SetSelectable(false)
    self.area_label:SetMultiline(false)
    self.area_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.area_label:SetVisible(false)

    self.area_shortcut = Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "")
    self.area_shortcut:SetData(TR["/loc"])

    self.area_slot = Turbine.UI.Lotro.Quickslot()
    self.area_slot:SetParent(self.filter_bar)
    self.area_slot:SetAllowDrop(false)
    self.area_slot:SetZOrder(1)
    self.area_slot:SetShortcut(self.area_shortcut)
    self.area_slot:SetVisible(true)
    self._area_slot_hovered = false
    self.area_slot.MouseEnter = function()
        self._area_slot_hovered = true
        _sync_area_slot_icon(self)
    end
    self.area_slot.MouseLeave = function()
        self._area_slot_hovered = false
        _sync_area_slot_icon(self)
    end

    self.area_slot_cover = Turbine.UI.Control()
    self.area_slot_cover:SetParent(self.filter_bar)
    self.area_slot_cover:SetMouseVisible(false)
    self.area_slot_cover:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.area_slot_cover:SetBackColor(Style.TEXT_OUTLINE)
    self.area_slot_cover:SetZOrder(2)

    self.area_slot_icon = UI.Widgets.Image()
    self.area_slot_icon:SetParent(self.filter_bar)
    self.area_slot_icon:SetMouseVisible(false)
    self.area_slot_icon:SetZOrder(3)

    self.taxonomy_bar = Turbine.UI.Control()
    self.taxonomy_bar:SetParent(self.nav_bar)

    self.genus_label = UI.Widgets.LuiLabel()
    self.genus_label:SetParent(self.taxonomy_bar)
    self.genus_label:SetMouseVisible(false)
    self.genus_label:SetSelectable(false)
    self.genus_label:SetMultiline(false)
    self.genus_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.genus_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.genus_label:SetText(TR["Genus"] .. ":")

    self.genus_dropdown = UI.Widgets.LuiDropdown()
    self.genus_dropdown:SetParent(self.taxonomy_bar)
    self.genus_dropdown:SetPopupHost(self)
    self.genus_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.genus_dropdown:SetMappedOptions({ TR["All"] }, { FILTER_ALL })
    self.genus_dropdown.ValueChanged = function(_, value)
        if self._suppress_genus_changed == true then
            return
        end
        self:set_genus_filter(value)
    end

    self.subcategory_label = UI.Widgets.LuiLabel()
    self.subcategory_label:SetParent(self.taxonomy_bar)
    self.subcategory_label:SetMouseVisible(false)
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
    self.content:SetParent(self.bestiary_host)
    self.content:SetMouseVisible(false)

    self.empty_label = UI.Widgets.LuiLabel()
    self.empty_label:SetParent(self.content)
    self.empty_label:SetMouseVisible(false)
    self.empty_label:SetMultiline(true)
    self.empty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.empty_label:SetText(TR["No bestiary entries yet."])
    self.empty_label:SetZOrder(3)

    self.SizeChanged = function()
        UI.Widgets.LuiWindow._layout(self)
        self:handle_user_resize()
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if visible == true then
            local tracker = Windows.bestiary_tracker
            tracker:flush_pending()
            self.last_update_at = 0
            self:ensure_area_shortcut()
            self:bring_to_front()
            -- generation-gated: flush_pending above bumps the cache
            -- generation when new kills landed, so an unchanged bestiary
            -- reopens without rebuilding 12k records
            self:refresh_from_store(false)
            self:sync_area_filter_query()
            self:apply_current_area_filter(true)
        else
            self.genus_dropdown:Close()
            self.subcategory_dropdown:Close()
        end
    end

    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    self:SetSize(
        _scaled_int(700) + math.max(0, window_w - central_w),
        _scaled_int(520) + math.max(0, window_h - central_h)
    )
    self:apply_settings()
end

function EncyclopediaWindow:bring_to_front()
    if self:IsVisible() == true then
        self:Activate()
    end
end

function EncyclopediaWindow:open()
    self:show()
end

function EncyclopediaWindow:toggle()
    if self:IsVisible() == true then
        self:hide()
    else
        self:show()
    end
end

function EncyclopediaWindow:capture_geometry()
    local window = Defaults.get_ui_window_state("bestiary")
    if type(window) ~= "table" then
        return
    end

    local geometry = self:get_geometry()
    window.left = geometry.left
    window.top = geometry.top
    window.width = geometry.width
    window.height = geometry.height
    window.tile = geometry.tile
end

function EncyclopediaWindow:persist_geometry()
    self:capture_geometry()
end

function EncyclopediaWindow:_minimum_window_size()
    local window_w, window_h = self:GetSize()
    local central_w, central_h = self:central_widget():GetSize()
    return _scaled_int(BASE_MIN_W) + math.max(0, window_w - central_w),
        _scaled_int(BASE_MIN_H) + math.max(0, window_h - central_h)
end

function EncyclopediaWindow:ensure_area_shortcut()
    if self.area_shortcut == nil or self.area_slot == nil then
        return
    end

    self.area_shortcut:SetData(TR["/loc"])
    self.area_slot:SetShortcut(self.area_shortcut)
    self.area_slot:SetAllowDrop(false)
end

function EncyclopediaWindow:apply_settings()
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)
    local min_w, min_h = self:_minimum_window_size()
    self:set_minimum_size(min_w, min_h)

    local button_font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
    self.pager:set_font(button_font)
    self.pager:set_scale(State.settings.global.scale)
    self.results_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.level_label:SetFont(button_font)
    self.level_min_box:SetFont(button_font)
    self.level_dash_label:SetFont(button_font)
    self.level_max_box:SetFont(button_font)
    self.search_field:set_scale(State.settings.global.scale)
    self.search_field:SetFont(button_font)
    local search_mode_switched = self:_apply_search_mode(State.settings.encyclopedia.search_mode)
    self.area_label:SetFont(button_font)
    self.encyclopedia_tabs:set_scale(State.settings.global.scale)
    self.encyclopedia_tabs:set_font(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE + 3))
    for _, panel in pairs(self._item_panels) do
        panel:apply_fonts()
        panel:set_search_mode(State.settings.encyclopedia.search_mode)
    end
    self:ensure_area_shortcut()
    self.genus_label:SetFont(button_font)
    self.genus_dropdown:SetFont(button_font)
    self.genus_dropdown:set_scale(State.settings.global.scale)
    self.subcategory_label:SetFont(button_font)
    self.subcategory_dropdown:SetFont(button_font)
    self.subcategory_dropdown:set_scale(State.settings.global.scale)
    self.empty_label:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    self.empty_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.empty_label:SetOutlineColor(Style.TEXT_OUTLINE)

    for i = 1, #self.entries do
        self.entries[i]:apply_settings()
    end

    local window = Defaults.get_ui_window_state("bestiary")
    if type(window) == "table" then
        local left = _to_number(window.left, self:GetLeft())
        local top = _to_number(window.top, self:GetTop())
        local width = _to_number(window.width, self:GetWidth())
        local height = _to_number(window.height, self:GetHeight())

        self._suppress_size_changed = true
        self:SetPosition(left, top)
        self:SetSize(math.max(min_w, width), math.max(min_h, height))
        self._suppress_size_changed = false
        self:set_geometry(window)
    end

    -- chip/row metrics are scale-dependent: drop every cached row layout
    -- (apply_view alone must not, so typing keystrokes reuse the cache)
    self:_invalidate_row_layouts()
    self:layout()
    if search_mode_switched == true then
        self:update_filter()
    else
        self:apply_view()
    end
end

function EncyclopediaWindow:_invalidate_row_layouts()
    for i = 1, #self.all_records do
        local record = self.all_records[i]
        record._layout_width = nil
        record._chip_layout = nil
        record._drop_height = nil
        record._view_height = nil
    end
    self._prepared_content_w = 0
    self._prepared_content_h = 0
    self._prepared_record_key = 0
end

function EncyclopediaWindow:Update()
    if Flags.is_unloading == true then
        self:SetWantsUpdates(false)
        return
    end

    if self:IsVisible() ~= true then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    self:sync_area_filter_query()
    self:apply_current_area_filter(false)

    local tracker = Windows.bestiary_tracker
    tracker:flush_expired()

    local generation = BestiaryCache.generation or 0
    if self._last_generation ~= generation
        and (now - self._last_store_refresh_at) >= BASE_STORE_REFRESH_MIN_INTERVAL then
        self:refresh_from_store(true)
    elseif self._resize_dirty == true
        and (now - self._last_resize_at) >= BASE_RESIZE_REFRESH_DELAY
        and (now - self._last_resize_reflow_at) >= BASE_RESIZE_REFLOW_MIN_INTERVAL then
        self._resize_dirty = false
        self._last_resize_reflow_at = now
        self:refresh_layout_view(true)
    end
end

function EncyclopediaWindow:handle_user_resize()
    local min_w, min_h = self:_minimum_window_size()
    self:set_minimum_size(min_w, min_h)
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
    self:refresh_visible_page_layout()
    self._resize_dirty = true
    self._last_resize_at = Turbine.Engine.GetGameTime()
end

function EncyclopediaWindow:_tokens_mode()
    return self.search_field:is_tokens()
end

-- shows the widget of the search mode setting. Tokens mode has no genus /
-- level fields (gen: and lvl: chips replace them): the field row is hidden
-- and the search row moves up. A switch carries the query over (Classic
-- text <-> chips; field filters become chips and the fields reset, so a
-- hidden field never filters). Returns true when the mode changed on an
-- existing window.
function EncyclopediaWindow:_apply_search_mode(mode)
    local switched = self.search_field:set_mode(mode)
    local tokens = self:_tokens_mode()
    self.nav_bar:SetVisible(tokens ~= true)
    self.level_bar:SetVisible(tokens ~= true)
    if tokens == true then
        self.genus_dropdown:Close()
        self.subcategory_dropdown:Close()
    end
    if switched ~= true then
        return false
    end

    if tokens == true then
        local genus_chip = self:_genus_chip_value()
        if genus_chip ~= nil and self.search_field:has_keyword("gen") ~= true then
            self.search_field:replace_keyword("gen", genus_chip)
        end
        local level_chip = self:_level_chip_value()
        if level_chip ~= nil and self.search_field:has_keyword("lvl") ~= true then
            self.search_field:replace_keyword("lvl", level_chip)
        end
        self.genus_filter = FILTER_ALL
        self.subcategory_filter = FILTER_NONE
        self:refresh_taxonomy_filters()
        self._suppress_level_text_changed = true
        self.level_min_box:SetText("")
        self.level_max_box:SetText("")
        self._suppress_level_text_changed = false
    end
    return true
end

-- gen: chip value of the taxonomy dropdowns (nil = All)
function EncyclopediaWindow:_genus_chip_value()
    if self.genus_filter == FILTER_ALL then
        return nil
    end
    if self.subcategory_filter == FILTER_ALL or self.subcategory_filter == FILTER_NONE then
        return self.genus_filter
    end
    return self.genus_filter .. " > " .. self.subcategory_filter
end

-- lvl: chip value of the level boxes (nil = both empty)
function EncyclopediaWindow:_level_chip_value()
    return SearchQuery.format_range(self.level_min_box:GetText() or "", self.level_max_box:GetText() or "")
end

-- one chip per keyword: replaces (or with nil removes) the `key:` chip,
-- then searches
function EncyclopediaWindow:_replace_keyword_chip(key, value)
    self.search_field:replace_keyword(key, value)
    self:update_filter()
end

-- record fields behind each keyword's suggestions
local SUGGEST_INDEX_FIELDS = {
    loc = { "region", "area" },
    gen = { "genus", "subcategory" },
}

-- name inserted into a list sorted like the baked one (string.lower)
local function _insert_sorted(list, item, name_of)
    local needle = _lower_text(name_of(item))
    local pos = #list + 1
    for i = 1, #list do
        if needle < _lower_text(name_of(list[i])) then
            pos = i
            break
        end
    end
    table.insert(list, pos, item)
end

local function _entry_name(entry)
    return entry.name
end

local function _same_name(name)
    return name
end

-- suggestion values of one keyword: the baked list (Lore.Bestiary.paths),
-- plus the values of creatures known only from the capture cache (the
-- pack's own values always win the merge, so the baked list is exact for
-- packed creatures); built on first use, cached until the record set
-- changes. The baked tables are shared: merged entries are copies.
function EncyclopediaWindow:_query_suggest_index(key)
    local index = self._suggest_index[key]
    if index ~= nil then
        return index
    end
    local baked = _G.LUI.Data.Lore.Bestiary.paths(key)
    local fields = SUGGEST_INDEX_FIELDS[key]
    index = baked
    local copied = false
    local by_name = nil
    for name in pairs(DATA_ACCESS.ensure_cache()) do
        local position = self._record_index_by_key[name]
        local record = position ~= nil and self.all_records[position] or nil
        local parent = record ~= nil and record[fields[1]] or nil
        -- an instance is a loc entry of its own (as in the bake)
        if key == "loc" and record ~= nil and (parent == nil or parent == "") then
            parent = record.instance
        end
        if parent ~= nil and parent ~= "" then
            if by_name == nil then
                by_name = {}
                for i = 1, #index do
                    by_name[index[i].name] = index[i]
                end
            end
            local child = record[fields[2]]
            local entry = by_name[parent]
            if entry == nil or (child ~= nil and child ~= "" and child ~= parent
                and self:_suggest_has_child(entry, child) ~= true) then
                if copied ~= true then
                    local list = {}
                    for i = 1, #index do
                        list[i] = index[i]
                    end
                    index = list
                    copied = true
                end
                if entry == nil then
                    entry = { name = parent, children = {} }
                    _insert_sorted(index, entry, _entry_name)
                else
                    -- copy the shared baked entry before adding to it
                    local own = { name = entry.name, children = {} }
                    for i = 1, #entry.children do
                        own.children[i] = entry.children[i]
                    end
                    for i = 1, #index do
                        if index[i] == entry then
                            index[i] = own
                        end
                    end
                    entry = own
                end
                by_name[parent] = entry
                if child ~= nil and child ~= "" and child ~= parent
                    and self:_suggest_has_child(entry, child) ~= true then
                    _insert_sorted(entry.children, child, _same_name)
                end
            end
        end
    end
    self._suggest_index[key] = index
    return index
end

function EncyclopediaWindow:_suggest_has_child(entry, child)
    for i = 1, #entry.children do
        if entry.children[i] == child then
            return true
        end
    end
    return false
end

function EncyclopediaWindow:update_filter()
    local state = self.search_field:get_query_state()
    local level_filter = SearchQuery.read_level_filter(state, "lvl")
    local location_paths = _parse_location_paths(state.token_map.loc)
    self.query_state = state
    self.filter_chip_groups = state.chip_groups
    if self:_tokens_mode() ~= true then
        self.filter_chip_groups = _drop_short_terms(state.chip_groups)
    end
    self.query_level_min = level_filter.min
    self.query_level_max = level_filter.max
    self.query_level_filter_active = state.token_map.lvl ~= nil
    self.query_level_filter_valid = level_filter.active == true
    self.query_genus_filter, self.query_subcategory_filter, self.query_genus_filter_valid =
        _parse_genus_token_value(state.token_map.gen)
    self.query_genus_filter_active = state.token_map.gen ~= nil
    self.query_location_filter_active = state.token_map.loc ~= nil
    self.query_location_filter_valid = location_paths ~= nil
    self.query_location_parts = location_paths
    self.query_location_keys = nil
    if location_paths ~= nil then
        self.query_location_keys = {}
        for p = 1, #location_paths do
            local keys = {}
            for i = 1, #location_paths[p] do
                keys[i] = SearchQuery.match_key(location_paths[p][i])
            end
            self.query_location_keys[p] = keys
        end
    end
    self:_sync_pager(1)
    self:apply_view()
end

function EncyclopediaWindow:_set_filter_query_text(query)
    self.search_field:set_query(query)
    self:update_filter()
end

function EncyclopediaWindow:_apply_location_query_value(value)
    local location_paths = _parse_location_paths(value)
    if location_paths == nil then
        error("Invalid bestiary location query value")
    end
    local location_value = _format_location_paths(location_paths)

    if self:_tokens_mode() == true then
        self:_replace_keyword_chip("loc", location_value)
        return
    end
    local tokens = SearchQuery.copy_tokens_except(self.query_state, { loc = true })
    SearchQuery.add_token(tokens, "loc", location_value)
    self:_set_filter_query_text(SearchQuery.serialize(self.query_state.text_groups, tokens, BESTIARY_QUERY_TOKENS))
end

function EncyclopediaWindow:sync_area_filter_query()
    local query = BestiaryCache.area_filter_query
    if type(query) ~= "string" or query == "" then
        self.current_area = nil
        return
    end

    self.current_area = query
end

function EncyclopediaWindow:apply_current_area_filter(force)
    local query = self.current_area
    if type(query) ~= "string" or query == "" then
        return
    end

    -- the periodic Update call is only a safety net: an already-applied
    -- area must not re-parse the query text every tick (user edits clear
    -- current_area via TextChanged, so divergence cannot happen silently)
    if force ~= true and query == self._applied_area_raw then
        return
    end

    local query_paths = _parse_location_paths(query)
    if query_paths == nil then
        error("Invalid bestiary area filter query")
    end
    -- the zone paths of every zone containing the position when the
    -- location button set them (zones overlap: all are searched, better
    -- more than less), else the query's own places; deepest part first
    local candidates = BestiaryCache.area_filter_candidates
    if candidates == nil then
        candidates = {}
        for p = 1, #query_paths do
            local levels = {}
            for i = #query_paths[p], 1, -1 do
                levels[#levels + 1] = { query_paths[p][i] }
            end
            candidates[p] = levels
        end
    end
    local index = self:_query_suggest_index("loc")
    local places = {}
    local whole_regions = {}
    for c = 1, #candidates do
        local region, area = _resolve_location(index, candidates[c])
        if region ~= nil then
            places[#places + 1] = { region, area }
            if area == nil then
                whole_regions[region] = true
            end
        end
    end
    if #places == 0 then
        -- no Bestiary creature lives there: keep the search as it is rather
        -- than filtering everything out
        self._applied_area_raw = query
        return
    end
    -- one entry per place; a whole region already covers its areas
    local location_paths = {}
    local seen = {}
    for i = 1, #places do
        local region, area = places[i][1], places[i][2]
        if area == nil or whole_regions[region] ~= true then
            local parts = { region }
            if area ~= nil and whole_regions[region] ~= true then
                parts[2] = area
            end
            local key = SearchQuery.format_path(parts)
            if seen[key] ~= true then
                seen[key] = true
                location_paths[#location_paths + 1] = parts
            end
        end
    end
    local location_value = _format_location_paths(location_paths)

    local state = self.search_field:get_query_state()
    if force ~= true and self.last_applied_area_query == location_value and state.token_map.loc == location_value then
        self._applied_area_raw = query
        return
    end

    self.query_state = state
    self.last_applied_area_query = location_value
    self._applied_area_raw = query
    self:_apply_location_query_value(location_value)
end

function EncyclopediaWindow:on_location_resolved()
    self:sync_area_filter_query()
    self:apply_current_area_filter(true)
end

function EncyclopediaWindow:set_area_filter_query(query)
    if type(query) ~= "string" or query == "" then
        return
    end

    BestiaryCache.area_filter_query = query
    -- a typed area resolves from the query itself, not stale /loc paths
    BestiaryCache.area_filter_candidates = nil
    self.current_area = query
    self:apply_current_area_filter(true)
end

function EncyclopediaWindow:open_query_search(query)
    query = _trim_text(query)
    if query == "" then
        return
    end

    -- cross-window links must land on the Bestiary tab regardless of which
    -- Encyclopedia tab was left active
    self.encyclopedia_tabs:set_selected_index(1)

    -- window first, text after: the Lotro TextBox does not repaint text
    -- set while its window is hidden until it is interacted with
    self:open()
    self:bring_to_front()

    self.current_area = nil
    self.last_applied_area_query = nil
    BestiaryCache.area_filter_query = nil
    BestiaryCache.area_filter_candidates = nil

    self._suppress_level_text_changed = true
    self.level_min_box:SetText("")
    self.level_max_box:SetText("")
    self._suppress_level_text_changed = false

    self:set_taxonomy_filters(FILTER_ALL, FILTER_NONE)

    self.search_field:set_query(query)
    self:update_filter()
    self.search_field:Focus()
end

function EncyclopediaWindow:open_item_search(item_name)
    local query = _trim_text(item_name)
    if query == "" then
        return
    end

    if string.find(query, "\"", 1, true) == nil then
        query = "\"" .. query .. "\""
    end

    self:open_query_search(query)
end

-- Cross-window link (card drop chips): open the Encyclopedia on the item
-- tab that shows this item, with an exact-name search. Returns false when
-- the name is not a browsable item.
function EncyclopediaWindow:open_encyclopedia_item_search(item_name)
    local tab_index = Encyclopedia.encyclopedia_tab_for_item(item_name)
    if tab_index == nil then
        return false
    end

    self.encyclopedia_tabs:set_selected_index(tab_index)
    -- window first, text after: the Lotro TextBox does not repaint text
    -- set while its window is hidden until it is interacted with
    self:open()
    self:bring_to_front()
    self._item_panels[tab_index]:open_item_search(item_name)
    return true
end

function EncyclopediaWindow:_refresh_genus_dropdown()
    local labels = { TR["All"] }
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

function EncyclopediaWindow:_refresh_subcategory_dropdown()
    local labels = { "-" }
    local values = { FILTER_NONE }
    local enabled = false
    local selected = FILTER_NONE

    if self.genus_filter ~= FILTER_ALL then
        local subcategories = _collect_unique_record_values(self.all_records, "subcategory", self.genus_filter)
        if #subcategories > 0 then
            labels = { TR["All"] }
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

function EncyclopediaWindow:refresh_taxonomy_filters()
    self:_refresh_genus_dropdown()
    self:_refresh_subcategory_dropdown()
end

function EncyclopediaWindow:set_taxonomy_filters(genus_value, subcategory_value)
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
    self:_sync_pager(1)
    self:apply_view()
end

function EncyclopediaWindow:set_genus_filter(value)
    if type(value) ~= "string" or value == "" then
        value = FILTER_ALL
    end
    if self.genus_filter == value then
        return
    end

    self.genus_filter = value
    self.subcategory_filter = value == FILTER_ALL and FILTER_NONE or FILTER_ALL
    self:refresh_taxonomy_filters()
    self:_sync_pager(1)
    self:apply_view()
end

function EncyclopediaWindow:set_subcategory_filter(value)
    if self.genus_filter == FILTER_ALL then
        value = FILTER_NONE
    elseif type(value) ~= "string" or value == "" then
        value = FILTER_ALL
    end

    if self.subcategory_filter == value then
        return
    end

    self.subcategory_filter = value
    self:_sync_pager(1)
    self:apply_view()
end

function EncyclopediaWindow:open_card_for_record(record, anchor)
    local name = record.key
    if type(name) ~= "string" or name == "" then
        name = record.name
    end

    return Windows.bestiary_card:show_for_name(name, anchor)
end

function EncyclopediaWindow:_ensure_rows(count)
    while #self.entries < count do
        local row = BestiaryRow(self)
        row:SetParent(self.content)
        row:SetZOrder(2)
        row:SetVisible(false)
        self.entries[#self.entries + 1] = row
    end
end

function EncyclopediaWindow:_ensure_column_separators(count)
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

-- the search row sits under the genus / level row, which Tokens mode hides
function EncyclopediaWindow:_filter_row_offset(bar_h, gap)
    if self:_tokens_mode() == true then
        return 0
    end
    return bar_h + gap
end

function EncyclopediaWindow:_content_metrics()
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_top = _scaled_int(BASE_MARGIN_TOP)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local margin_bottom = _scaled_int(BASE_MARGIN_BOTTOM)
    local bar_h = _scaled_int(BASE_BAR_H)
    local level_h = _scaled_int(BASE_BAR_H)
    local filter_h = _scaled_int(BASE_FILTER_H)
    local gap = _scaled_int(BASE_GAP)
    local host_w, host_h = self.bestiary_host:GetSize()
    local inner_w = host_w - margin_left - margin_right
    -- two filter rows: taxonomy + level share the first, search the second
    -- (Tokens mode: the search row only)
    local content_top = margin_top + self:_filter_row_offset(bar_h, gap) + filter_h + gap
    local content_h = host_h - content_top - margin_bottom - gap - bar_h
    return margin_left, margin_top, inner_w, math.max(1, content_top), math.max(1, content_h), bar_h, level_h, filter_h, gap
end

function EncyclopediaWindow:layout()
    -- the tab bar owns the whole central area; sizing it lays out the
    -- selected tab's content host synchronously, so the bestiary metrics
    -- below read a valid bestiary_host size
    local central_w, central_h = self:central_widget():GetSize()
    self.encyclopedia_tabs:SetPosition(0, 0)
    self.encyclopedia_tabs:SetSize(central_w, central_h)

    local active_panel = self._item_panels[self._active_encyclopedia_tab]
    if active_panel ~= nil then
        local host = self._item_tab_hosts[self._active_encyclopedia_tab]
        active_panel:SetPosition(0, 0)
        active_panel:SetSize(host:GetSize())
        active_panel:layout()
    end

    local margin_left, margin_top, inner_w, content_top, content_h, bar_h, level_h, filter_h, gap = self:_content_metrics()

    self.nav_bar:SetPosition(margin_left, margin_top)
    self.nav_bar:SetSize(inner_w, bar_h)

    self.pager:set_metrics(_scaled_int(BASE_NAV_W), gap)
    self.page_bar:SetSize(self.pager:preferred_width(_scaled_int(BASE_PAGE_W)), bar_h)
    local _, host_h = self.bestiary_host:GetSize()
    self.page_bar:SetPosition(
        margin_left + math.max(0, math.floor((inner_w - self.page_bar:GetWidth()) / 2)),
        host_h - _scaled_int(BASE_MARGIN_BOTTOM) - bar_h
    )

    local results_w = _scaled_int(140)
    self.results_label:SetPosition(margin_left + inner_w - results_w,
        host_h - _scaled_int(BASE_MARGIN_BOTTOM) - bar_h)
    self.results_label:SetSize(results_w, bar_h)

    self.pager:SetPosition(0, 0)
    self.pager:SetSize(self.page_bar:GetSize())

    local level_label_w = _small_text_width(TR["Level"] .. ":") + gap
    local level_input_w = _scaled_int(BASE_LEVEL_INPUT_W)
    local level_dash_w = _scaled_int(10)
    local level_block_w = level_label_w + gap + level_input_w + gap + level_dash_w + gap + level_input_w

    local taxonomy_w = math.max(1, inner_w - level_block_w - (2 * gap))
    self.taxonomy_bar:SetPosition(0, 0)
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

    -- level block right-aligned on the taxonomy row
    self.level_bar:SetPosition(margin_left + inner_w - level_block_w, margin_top)
    self.level_bar:SetSize(level_block_w, level_h)

    local level_min_x = level_label_w + gap
    local level_dash_x = level_min_x + level_input_w + gap
    local level_max_x = level_dash_x + level_dash_w + gap

    self.level_label:SetPosition(0, 0)
    self.level_label:SetSize(level_label_w, level_h)
    self.level_min_box:SetPosition(level_min_x, 0)
    self.level_min_box:SetSize(level_input_w, level_h)
    self.level_dash_label:SetPosition(level_dash_x, 0)
    self.level_dash_label:SetSize(level_dash_w, level_h)
    self.level_max_box:SetPosition(level_max_x, 0)
    self.level_max_box:SetSize(level_input_w, level_h)

    self.filter_bar:SetPosition(margin_left, margin_top + self:_filter_row_offset(bar_h, gap))
    self.filter_bar:SetSize(inner_w, filter_h)

    local area_slot_size = filter_h
    local area_slot_x = 0
    local filter_x = area_slot_size + gap
    local filter_w = math.max(1, inner_w - filter_x)
    self.area_slot:SetPosition(area_slot_x, 0)
    self.area_slot:SetSize(area_slot_size, area_slot_size)
    self.area_slot_cover:SetPosition(area_slot_x, 0)
    self.area_slot_cover:SetSize(area_slot_size, area_slot_size)
    _sync_area_slot_icon(self)
    self.area_label:SetPosition(0, 0)
    self.area_label:SetSize(0, 0)
    self.search_field:SetPosition(filter_x, 0)
    self.search_field:SetSize(filter_w, filter_h)

    self.content:SetPosition(margin_left, content_top)
    self.content:SetSize(inner_w, content_h)

    self.empty_label:SetPosition(0, math.max(0, math.floor((content_h - bar_h) / 2)))
    self.empty_label:SetSize(inner_w, bar_h)
end

-- tab 1 = bestiary (this window's own content); tabs 2-4 are item browser
-- panels laid over the content area, created on first activation
local ENCYCLOPEDIA_TAB_BUCKETS = { nil, "equipment", "resource", "consumable", "housing", "tracery" }
local QUESTS_TAB_INDEX = 7

-- converter bucket codes (1=equipment 2=consumable 3=resource, 0=other) to
-- encyclopedia tab index; "other" items have no tab and are not linkable
local BUCKET_TAB_BY_CODE = { [1] = 2, [2] = 4, [3] = 3, [4] = 5, [5] = 6 }

-- Which encyclopedia tab shows this item name; nil when the name is not a
-- browsable item (unknown name or bucket "other"). Shared probe for every
-- surface that decides whether an item link makes sense.
function Encyclopedia.encyclopedia_tab_for_item(item_name)
    local Lore = _G.LUI.Data.Lore
    -- the items DB is staged in the background by the bestiary prewarm
    -- pump; a link probe must never pay the full synchronous import
    -- (bestiary cards bind chips on target double-click, combat-adjacent).
    -- Pre-staging probes report "no link" and callers re-probe later.
    if Lore.Items.loaded ~= true then
        return nil
    end
    local ordinals = Lore.Items.find_ordinals(item_name)
    if ordinals == nil then
        return nil
    end
    for i = 1, #ordinals do
        local tab_index = BUCKET_TAB_BY_CODE[Lore.Items.bucket(ordinals[i])]
        if tab_index ~= nil then
            return tab_index
        end
    end
    return nil
end

function EncyclopediaWindow:_set_encyclopedia_tab(index)
    self._active_encyclopedia_tab = index
    -- the tab bar shows/hides the tab hosts itself; panels are only
    -- created lazily inside their host on first activation
    if index ~= 1 and self._item_panels[index] == nil then
        local panel
        if index == QUESTS_TAB_INDEX then
            panel = Encyclopedia.QuestsTabPanel(self)
            panel.on_quest_open = function(ordinal)
                Windows.quest_card:show_for_ordinal(ordinal, self)
            end
        else
            panel = Encyclopedia.ItemBrowserPanel(ENCYCLOPEDIA_TAB_BUCKETS[index], self)
        end
        panel:SetParent(self._item_tab_hosts[index])
        self._item_panels[index] = panel
    end
    self:layout()
end

function EncyclopediaWindow:refresh_from_store(force)
    local generation = BestiaryCache.generation or 0
    if force ~= true and self._last_generation == generation then
        return
    end

    self._last_store_refresh_at = Turbine.Engine.GetGameTime()
    self._last_generation = generation

    -- consume the tracker's dirty bookkeeping: when every change since the
    -- last rebuild is named, patch those records in place instead of
    -- re-decoding and re-measuring all ~12k packed entries on each kill
    local dirty_names = BestiaryCache.dirty_names
    BestiaryCache.dirty_names = nil
    local dirty_all = BestiaryCache.dirty_all == true
    BestiaryCache.dirty_all = nil

    if dirty_all ~= true and dirty_names ~= nil and self.all_records ~= nil then
        self:_refresh_dirty_records(dirty_names)
        self:apply_view()
        return
    end

    self.all_records = _build_records()
    self:_rebuild_record_index()
    self._prepared_content_w = 0
    self._prepared_content_h = 0
    self._prepared_record_key = 0
    self:refresh_taxonomy_filters()
    self:apply_view()
end

function EncyclopediaWindow:_rebuild_record_index()
    local by_key = {}
    for i = 1, #self.all_records do
        by_key[self.all_records[i].key] = i
    end
    self._record_index_by_key = by_key
    self._suggest_index = {}
end

function EncyclopediaWindow:_refresh_dirty_records(dirty_names)
    local inserted = false
    for name in pairs(dirty_names) do
        local entry = _merged_entry_for(name)
        if entry ~= nil then
            local record = _build_record(name, entry)
            local index = self._record_index_by_key[name]
            if index ~= nil then
                -- kills and drops never change the sort key, so an
                -- in-place swap keeps all_records sorted
                self.all_records[index] = record
            else
                -- first capture of a mob outside the packed DB: insert at
                -- its sorted position
                local pos = #self.all_records + 1
                for i = 1, #self.all_records do
                    if _compare_records(record, self.all_records[i]) == true then
                        pos = i
                        break
                    end
                end
                table.insert(self.all_records, pos, record)
                inserted = true
            end
        end
    end

    if inserted == true then
        self:_rebuild_record_index()
        self:refresh_taxonomy_filters()
    end
end

function EncyclopediaWindow:_prepare_records(records)
    for i = 1, #records do
        local record = records[i]
        _ensure_record_display_texts(record)
        record._layout_width = nil
        record._chip_layout = nil
        record._drop_height = nil
        record._view_height = nil
    end
end

function EncyclopediaWindow:_measure_record_height(record, width)
    _ensure_record_row_layout(record, width)
    if type(record) ~= "table" then
        return 0
    end

    return _to_number(record._view_height, 0)
end

function EncyclopediaWindow:_column_metrics()
    local host_w = self.bestiary_host:GetSize()
    local window_w = math.max(1, math.floor(host_w + 0.5))
    local content_w = math.max(1, math.floor(self.content:GetWidth() + 0.5))
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local column_target_w = math.max(1, BASE_COLUMN_W)
    local column_count = math.max(1, math.floor(window_w / column_target_w))
    local bucket_window_w = math.max(column_target_w, column_count * column_target_w)
    local bucket_content_w = math.max(1, bucket_window_w - margin_left - margin_right)
    return column_count, content_w, bucket_content_w
end

function EncyclopediaWindow:refresh_layout_view(force)
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
    self:_sync_pager(nil, #self.pages)

    self:render_page()
end

-- programmatic pager updates inside a refresh flow: the flow renders once
-- itself, so the pager's changed callback must not render again
function EncyclopediaWindow:_sync_pager(page, page_count)
    self._pager_syncing = true
    if page ~= nil then
        self.pager:set_page(page)
    end
    if page_count ~= nil then
        self.pager:set_page_count(page_count)
    end
    self._pager_syncing = false
end

function EncyclopediaWindow:_build_pages(records)
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

    local function measure_width_for_column(column_slot)
        local column_index = column_slot - 1
        local x = math.floor((column_index * content_w) / column_count)
        local next_x = math.floor(((column_index + 1) * content_w) / column_count)
        return math.max(1, next_x - x)
    end

    for record_index = 1, #records do
        if page == nil then
            begin_page()
        end

        local column_slot = shortest_column_slot()
        local item_w = measure_width_for_column(column_slot)
        local height = self:_measure_record_height(records[record_index], item_w)
        local y = column_heights[column_slot]
        if y > 0 then
            y = y + row_gap
        end

        if #page.items > 0 and (y + height) > content_h then
            pages[#pages + 1] = page
            begin_page()
            column_slot = shortest_column_slot()
            item_w = measure_width_for_column(column_slot)
            height = self:_measure_record_height(records[record_index], item_w)
            y = 0
        end

        page.items[#page.items + 1] = record_index

        column_heights[column_slot] = y + height
    end

    if page ~= nil and #page.items > 0 then
        pages[#pages + 1] = page
    end

    return pages
end

function EncyclopediaWindow:apply_view()
    local filtered = {}
    local chip_groups = self.filter_chip_groups
    local has_query = #chip_groups > 0
    local filter_level_min = self.query_level_min
    local filter_level_max = self.query_level_max
    if self.query_level_filter_active ~= true then
        filter_level_min, filter_level_max = _read_level_filter_range(self)
    end
    local location_keys = self.query_location_keys
    local impossible_level_range = (self.query_level_filter_active == true and self.query_level_filter_valid ~= true) or
        (filter_level_min ~= nil and filter_level_max ~= nil and filter_level_min > filter_level_max)
    local use_query_taxonomy = self.query_genus_filter_active == true
    local genus_filter = use_query_taxonomy == true and self.query_genus_filter or self.genus_filter
    local subcategory_filter = use_query_taxonomy == true and self.query_subcategory_filter or self.subcategory_filter
    -- typed gen: values compare case / article-insensitive
    local genus_key = SearchQuery.match_key(genus_filter)
    local subcategory_key = SearchQuery.match_key(subcategory_filter)
    for i = 1, #self.all_records do
        local record = self.all_records[i]
        local genus_ok = self.query_genus_filter_active ~= true or self.query_genus_filter_valid == true
        if genus_ok == true and genus_filter == FILTER_ALL then
            genus_ok = true
        elseif genus_ok == true and use_query_taxonomy == true then
            genus_ok = _record_key(record, "genus") == genus_key
        elseif genus_ok == true then
            genus_ok = record.genus == genus_filter
        end
        local subcategory_ok = self.query_genus_filter_active ~= true or self.query_genus_filter_valid == true
        if subcategory_ok == true and (subcategory_filter == FILTER_NONE or subcategory_filter == FILTER_ALL) then
            subcategory_ok = true
        elseif subcategory_ok == true and use_query_taxonomy == true then
            subcategory_ok = _record_key(record, "subcategory") == subcategory_key
        elseif subcategory_ok == true then
            subcategory_ok = record.subcategory == subcategory_filter
        end
        local level_ok = impossible_level_range ~= true and _matches_level_range(record, filter_level_min, filter_level_max)
        local location_ok = self.query_location_filter_active ~= true or
            (self.query_location_filter_valid == true and _record_matches_location_paths(record, location_keys))
        record._matched_drop_lookup = nil
        if genus_ok == true and subcategory_ok == true and level_ok == true and location_ok == true then
            local query_ok = true
            local matched_drop_lookup = nil
            if has_query == true then
                query_ok, matched_drop_lookup = _match_record_chips(record, chip_groups)
            end
            record._matched_drop_lookup = matched_drop_lookup
            if query_ok == true then
                filtered[#filtered + 1] = record
            end
        end
    end

    -- all_records is kept sorted (refresh_from_store), and the filter loop
    -- appends in array order, so the filtered view is already sorted
    self.records = filtered
    -- row layouts stay cached (width-keyed): a filter/search keystroke
    -- changes which records show, never how a record lays out
    self:refresh_layout_view(true)
end

function EncyclopediaWindow:_apply_page_layout(page, column_count, content_w)
    local record_indices = type(page) == "table" and page.items or nil
    if type(record_indices) ~= "table" then
        record_indices = {}
    end
    local count = #record_indices
    self:_ensure_rows(count)

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

    local content_h = math.max(1, self.content:GetHeight())
    local column_heights = {}
    for i = 1, column_count do
        column_heights[i] = 0
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

    for i = 1, count do
        local column_slot = shortest_column_slot()
        local column_index = column_slot - 1
        local x = math.floor((column_index * content_w) / column_count)
        local next_x = math.floor(((column_index + 1) * content_w) / column_count)
        local item_w = math.max(1, next_x - x)
        local record = self.records[record_indices[i]]
        local row = self.entries[i]

        row:bind(record, item_w)

        local y = column_heights[column_slot]
        if y > 0 then
            y = y + _scaled_int(BASE_GAP)
        end

        if y < content_h then
            row:SetPosition(x, y)
            row:SetVisible(true)
        else
            row:SetVisible(false)
        end

        column_heights[column_slot] = y + row:GetHeight()
    end

    for i = count + 1, #self.entries do
        self.entries[i]:SetVisible(false)
    end
end

function EncyclopediaWindow:refresh_visible_page_layout()
    if #self.records == 0 then
        self:render_page()
        return
    end

    local page = self.pages[self.pager:get_page()]
    if page == nil then
        self:render_page()
        return
    end

    self.results_label:SetText(tostring(#self.records) .. " " .. TR["results"])
    local column_count, content_w = self:_column_metrics()
    self:_apply_page_layout(page, column_count, content_w)
end

function EncyclopediaWindow:render_page()
    self.results_label:SetText(tostring(#self.records) .. " " .. TR["results"])

    if #self.records == 0 then
        if #self.all_records == 0 then
            self.empty_label:SetText(TR["No bestiary entries yet."])
        else
            self.empty_label:SetText(TR["No matching bestiary entries."])
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

    local page = self.pages[self.pager:get_page()]
    if page == nil then
        for i = 1, #self.column_separators do
            self.column_separators[i]:SetVisible(false)
        end
        for i = 1, #self.entries do
            self.entries[i]:SetVisible(false)
        end
        return
    end

    local column_count, content_w = self:_column_metrics()
    self:_apply_page_layout(page, column_count, content_w)
end

Encyclopedia.EncyclopediaWindow = EncyclopediaWindow
