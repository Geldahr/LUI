import "LUI.src.Settings.enums"
import "LUI.src.Utils.time_format"

local MIN_SIDE_PADDING = 2
local TEXT_SIDE_PADDING_RATIO = 0.12
local TEXT_GAP_RATIO = 0.35
local FONT_WIDTH_CACHE = {}

local AVAILABLE_FONT_SIZES = {
    verdana = { 10, 12, 14, 16, 18, 20, 22, 23 },
    verdanabold = { 16 },
    bookantiqua = { 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36 },
    bookantiquabold = { 12, 14, 18, 19, 22, 24 },
    trajanpro = { 13, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 28 },
    trajanprobold = { 16, 22, 24, 25, 30, 36 },
    arial = { 12 },
    fixedsys = { 15 },
    lucidaconsole = { 12 },
}

local FONT_WIDTH_FACTORS = {
    verdana = 1.00,
    verdanabold = 1.06,
    bookantiqua = 1.10,
    bookantiquabold = 1.13,
    trajanpro = 1.18,
    trajanprobold = 1.24,
    arial = 0.98,
    fixedsys = 0.92,
    lucidaconsole = 0.94,
}

local MONOSPACE_FONTS = {
    fixedsys = true,
    lucidaconsole = true,
}

local FONT_CHAR_WIDTH_OVERRIDES = {
    verdana = {
        ["1"] = 0.50,
        [":"] = 0.26,
    },
    verdanabold = {
        ["1"] = 0.52,
        [":"] = 0.27,
    },
}

local DIGIT_WIDTH_UNITS = {
    ["0"] = 0.58,
    ["1"] = 0.38,
    ["2"] = 0.56,
    ["3"] = 0.56,
    ["4"] = 0.58,
    ["5"] = 0.58,
    ["6"] = 0.58,
    ["7"] = 0.54,
    ["8"] = 0.60,
    ["9"] = 0.58,
}

local function _normalize_font_size(font_size)
    local size = tonumber(font_size)
    if size == nil or size <= 0 then
        return 12
    end
    return size
end

local function _normalize_font_name(font_name)
    if type(font_name) == "number" then
        font_name = LUI_ENUMS.font_name_to_string[font_name]
    end
    if type(font_name) ~= "string" then
        return "verdana"
    end
    return (font_name:gsub("[%s%-%_]", ""):lower())
end
local function _choose_font_size(size, available_sizes)
    local numeric_size = tonumber(size) or 0
    local count = #available_sizes
    if count == 0 then
        return 12
    end
    if count == 1 then
        return available_sizes[1]
    end
    if numeric_size <= available_sizes[1] then
        return available_sizes[1]
    end
    if numeric_size >= available_sizes[count] then
        return available_sizes[count]
    end

    for i = 1, count - 1 do
        local lower = available_sizes[i]
        local upper = available_sizes[i + 1]
        local midpoint = (lower + upper) / 2
        if numeric_size < midpoint then
            return lower
        elseif numeric_size == midpoint then
            return upper
        elseif numeric_size < upper then
            return upper
        end
    end

    return available_sizes[count]
end

local function _char_width_units(ch, normalized_font_name)
    local font_overrides = FONT_CHAR_WIDTH_OVERRIDES[normalized_font_name]
    if font_overrides ~= nil then
        local override_width = font_overrides[ch]
        if override_width ~= nil then
            return override_width
        end
    end

    local digit_width = DIGIT_WIDTH_UNITS[ch]
    if digit_width ~= nil then
        return digit_width
    end
    if ch == ":" then
        return 0.22
    end
    if ch == "." then
        return 0.20
    end
    if ch == "s" or ch == "S" then
        return 0.46
    end
    if ch == " " then
        return 0.30
    end
    if string.match(ch, "%l") ~= nil then
        return 0.52
    end
    if string.match(ch, "%u") ~= nil then
        return 0.66
    end
    return 0.60
end

local function _text_width_units(text, normalized_font_name)
    local value = tostring(text or "")
    if MONOSPACE_FONTS[normalized_font_name] == true then
        return string.len(value) * 0.60
    end

    local units = 0
    for i = 1, string.len(value) do
        units = units + _char_width_units(string.sub(value, i, i), normalized_font_name)
    end
    return units
end

local function _text_width_safety_padding(normalized_font_name, resolved_size)
    local padding = 1
    if normalized_font_name == "verdana" and resolved_size <= 18 then
        return padding + 1
    end
    return padding
end

local function _normalized_threshold(threshold)
    local value = tonumber(threshold)
    if value == nil or value < 0 then
        return 0
    end
    return value
end

local function _widest_char(chars, normalized_font_name)
    local widest = string.sub(chars, 1, 1)
    local widest_units = _char_width_units(widest, normalized_font_name)

    for i = 2, string.len(chars) do
        local ch = string.sub(chars, i, i)
        local units = _char_width_units(ch, normalized_font_name)
        if units > widest_units then
            widest = ch
            widest_units = units
        end
    end

    return widest
end

local function _integer_digits(value)
    local count = 1
    local whole = math.floor(value)
    while whole >= 10 do
        count = count + 1
        whole = math.floor(whole / 10)
    end
    return count
end

local function _tenths_sample(normalized_font_name)
    local widest_digit = _widest_char("0123456789", normalized_font_name)
    return widest_digit .. "." .. widest_digit .. "s"
end

local function _whole_seconds_sample(normalized_font_name, digit_count)
    if digit_count <= 1 then
        return _widest_char("0123456789", normalized_font_name) .. "s"
    end

    local tens = _widest_char("12345", normalized_font_name)
    local ones = _widest_char("0123456789", normalized_font_name)
    return tens .. ones .. "s"
end

local function _minutes_seconds_sample(normalized_font_name, minute_digits)
    local minutes = string.rep(_widest_char("0123456789", normalized_font_name), minute_digits)
    local seconds_tens = _widest_char("012345", normalized_font_name)
    local seconds_ones = _widest_char("0123456789", normalized_font_name)
    return minutes .. ":" .. seconds_tens .. seconds_ones
end

local function _max_time_width_sample(limit, normalized_font_name, time_format)
    local widest = lui_format_cooldown_time(limit, time_format)

    if time_format ~= LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        local tenths = _tenths_sample(normalized_font_name)
        if _text_width_units(tenths, normalized_font_name) > _text_width_units(widest, normalized_font_name) then
            widest = tenths
        end
    end

    if limit >= 10 then
        local whole_seconds = _whole_seconds_sample(normalized_font_name, _integer_digits(math.min(59, math.floor(limit))))
        if _text_width_units(whole_seconds, normalized_font_name) > _text_width_units(widest, normalized_font_name) then
            widest = whole_seconds
        end
    elseif time_format == LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        local single_digit = _whole_seconds_sample(normalized_font_name, 1)
        if _text_width_units(single_digit, normalized_font_name) > _text_width_units(widest, normalized_font_name) then
            widest = single_digit
        end
    end

    if limit >= 60 then
        local minutes = _integer_digits(math.floor(limit / 60))
        local mm_ss = _minutes_seconds_sample(normalized_font_name, minutes)
        if _text_width_units(mm_ss, normalized_font_name) > _text_width_units(widest, normalized_font_name) then
            widest = mm_ss
        end
    end

    return widest
end

local function _time_width_cache_key(font_name, font_size, threshold, time_format)
    return table.concat({
        tostring(_normalize_font_name(font_name)),
        tostring(_normalize_font_size(font_size)),
        string.format("%.1f", _normalized_threshold(threshold)),
        tostring(time_format),
    }, "|")
end

function _G.lui_cooldown_resolved_font_size(font_name, font_size)
    local normalized = _normalize_font_name(font_name)
    local available = AVAILABLE_FONT_SIZES[normalized]
    if available == nil then
        return 12
    end
    return _choose_font_size(_normalize_font_size(font_size), available)
end

function _G.lui_cooldown_estimate_text_width(text, font_name, font_size)
    local normalized = _normalize_font_name(font_name)
    local resolved_size = lui_cooldown_resolved_font_size(normalized, font_size)
    local family_factor = FONT_WIDTH_FACTORS[normalized] or 1.0
    local units = _text_width_units(text, normalized)

    local side_padding = math.max(MIN_SIDE_PADDING, math.floor((resolved_size * TEXT_SIDE_PADDING_RATIO) + 0.5))
    local width = (units * resolved_size * family_factor) + side_padding + _text_width_safety_padding(normalized, resolved_size)
    return math.max(1, math.floor(width + 0.5))
end

function _G.lui_format_cooldown_time(seconds, time_format)
    if time_format == LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        return lui_format_timeout_seconds(seconds)
    end
    return lui_format_timeout(seconds)
end

function _G.lui_cooldown_text_gap(font_size)
    local size = _normalize_font_size(font_size)
    return math.max(4, math.floor((size * TEXT_GAP_RATIO) + 0.5))
end

function _G.lui_cooldown_time_label_width(font_name, font_size, threshold, time_format)
    local limit = _normalized_threshold(threshold)
    local normalized_font_name = _normalize_font_name(font_name)
    local cache_key = _time_width_cache_key(normalized_font_name, font_size, limit, time_format)
    local cached = FONT_WIDTH_CACHE[cache_key]
    if cached ~= nil then
        return cached
    end

    local sample = _max_time_width_sample(limit, normalized_font_name, time_format)
    local widest = lui_cooldown_estimate_text_width(sample, normalized_font_name, font_size)

    FONT_WIDTH_CACHE[cache_key] = widest
    return widest
end

function _G.lui_cooldown_min_name_width(font_name, font_size)
    local size = _normalize_font_size(font_size)
    local ellipsis_width = lui_cooldown_estimate_text_width("...", font_name, size)
    local short_name_width = math.floor((lui_cooldown_resolved_font_size(font_name, size) * 2.5) + 0.5)
    if short_name_width > ellipsis_width then
        return short_name_width
    end
    return ellipsis_width
end

function _G.lui_cooldown_min_item_width(item_h, border_width, text_margin, font_name, font_size, threshold, time_format)
    local height = tonumber(item_h)
    if height == nil or height < 1 then
        height = 1
    end

    local border = tonumber(border_width)
    if border == nil or border < 0 then
        border = 0
    end
    border = math.floor(border + 0.5)
    if border * 2 >= height then
        border = math.floor((height - 1) / 2)
    end
    if border < 0 then
        border = 0
    end

    local inner_h = height - (2 * border)
    if inner_h < 1 then
        inner_h = 1
    end

    local pad = tonumber(text_margin)
    if pad == nil or pad < 0 then
        pad = 0
    end
    pad = math.floor(pad + 0.5)

    local separator_width = border
    local time_width = lui_cooldown_time_label_width(font_name, font_size, threshold, time_format)
    local gap = lui_cooldown_text_gap(font_size)
    local name_width = lui_cooldown_min_name_width(font_name, font_size)

    return (2 * border) + inner_h + separator_width + (2 * pad) + time_width + gap + name_width
end
