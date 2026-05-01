import "LUI.src.Settings.enums"
import "LUI.src.Utils.time_format"

local MIN_CHAR_WIDTH = 6
local CHAR_WIDTH_RATIO = 0.78
local TEXT_SIDE_PADDING_RATIO = 0.50
local TEXT_GAP_RATIO = 0.35

local function _normalize_font_size(font_size)
    local size = tonumber(font_size)
    if size == nil or size <= 0 then
        return 12
    end
    return size
end

local function _rough_text_width(text, font_size)
    local size = _normalize_font_size(font_size)
    local count = string.len(tostring(text))
    local char_width = math.max(MIN_CHAR_WIDTH, math.floor((size * CHAR_WIDTH_RATIO) + 0.5))
    local side_padding = math.max(2, math.floor((size * TEXT_SIDE_PADDING_RATIO) + 0.5))
    return (count * char_width) + side_padding
end

local function _normalized_threshold(threshold)
    local value = tonumber(threshold)
    if value == nil or value < 0 then
        return 0
    end
    return value
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

function _G.lui_cooldown_time_label_width(font_size, threshold, time_format)
    local limit = _normalized_threshold(threshold)
    local widest = _rough_text_width(lui_format_cooldown_time(limit, time_format), font_size)

    if limit >= 10 and time_format ~= LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS then
        local tenths_width = _rough_text_width(lui_format_cooldown_time(9.9, time_format), font_size)
        if tenths_width > widest then
            widest = tenths_width
        end
    end

    if limit >= 10 then
        local whole_second_limit = limit
        if whole_second_limit > 59 then
            whole_second_limit = 59
        end
        local whole_seconds_width = _rough_text_width(
            lui_format_cooldown_time(whole_second_limit, time_format),
            font_size
        )
        if whole_seconds_width > widest then
            widest = whole_seconds_width
        end
    end

    return widest
end

function _G.lui_cooldown_min_name_width(font_size)
    local size = _normalize_font_size(font_size)
    local ellipsis_width = _rough_text_width("...", size)
    local short_name_width = math.floor((size * 2.5) + 0.5)
    if short_name_width > ellipsis_width then
        return short_name_width
    end
    return ellipsis_width
end

function _G.lui_cooldown_min_item_width(item_h, border_width, text_margin, font_size, threshold, time_format)
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
    local time_width = lui_cooldown_time_label_width(font_size, threshold, time_format)
    local gap = lui_cooldown_text_gap(font_size)
    local name_width = lui_cooldown_min_name_width(font_size)

    return (2 * border) + inner_h + separator_width + (2 * pad) + time_width + gap + name_width
end
