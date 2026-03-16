import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Geldahr.LUI.UI.Widgets"
import "Geldahr.LUI.Inventory.filter"
import "Geldahr.LUI.Utils.font"

Bestiary = Bestiary or {}

local BUILTIN_BESTIARY = Bestiary.Data or {}

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
local BASE_MIN_W = 360
local BASE_MIN_H = 240
local BASE_NAME_FONT_SIZE = 12
local BASE_TEXT_FONT_SIZE = 10
local BASE_ROW_PAD_X = 8
local BASE_ROW_PAD_Y = 6
local BASE_ROW_GAP_Y = 3
local BASE_LINE_H = 14
local BASE_ROW_SEPARATOR = 2
local BASE_CHIP_H = 18
local BASE_CHIP_PAD_X = 6
local BASE_CHIP_GAP_X = 4
local BASE_CHIP_GAP_Y = 4
local BASE_CHIP_BORDER = 1
local BASE_CHIP_MIN_W = 52
local BASE_CHIP_CHAR_W = 5.8

local SORT_NAME_ASC = "name_asc"
local SORT_NAME_DESC = "name_desc"
local SORT_LEVEL_ASC = "level_asc"
local SORT_LEVEL_DESC = "level_desc"

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

local function _to_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback or 0
    end
    return value
end

local function _copy_levels(levels)
    local out = {}
    if type(levels) ~= "table" then
        return out
    end

    for level, info in pairs(levels) do
        if type(info) == "table" then
            out[level] = {
                m = _to_number(info.m, 0),
                p = _to_number(info.p, 0),
            }
        end
    end

    return out
end

local function _copy_drops(drops)
    local out = {}
    if type(drops) ~= "table" then
        return out
    end

    for name, count in pairs(drops) do
        if type(name) == "string" then
            out[name] = _to_number(count, 0)
        end
    end

    return out
end

local function _merge_entry(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
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
                        levels = _copy_levels(entry.levels),
                        k = _to_number(entry.k, 0),
                        d = _copy_drops(entry.d),
                    }
                else
                    _merge_entry(merged[name], entry)
                end
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
            out[#out + 1] = ","
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

    return _format_number(min_value) .. "-" .. _format_number(max_value)
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

local function _build_drop_records(entry)
    local drops = {}
    local kills = _to_number(entry.k, 0)
    if type(entry.d) ~= "table" then
        return drops
    end

    for item_name, count in pairs(entry.d) do
        if type(item_name) == "string" then
            local n = _to_number(count, 0)
            local rate = kills > 0 and ((n / kills) * 100) or 0
            drops[#drops + 1] = {
                name = item_name,
                count = n,
                rate = rate,
            }
        end
    end

    table.sort(drops, function(left, right)
        if left.rate ~= right.rate then
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
        local filter_parts = { _lower_text(name) }
        for i = 1, #drop_records do
            filter_parts[#filter_parts + 1] = _lower_text(drop_records[i].name)
        end

        out[#out + 1] = {
            name = name,
            level_min = level_min,
            level_max = level_max,
            morale_min = morale_min,
            morale_max = morale_max,
            power_min = power_min,
            power_max = power_max,
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

local function _build_chip_layout(texts, max_width)
    local layout = {}
    local chip_h = _scaled_int(BASE_CHIP_H)
    local gap_x = _scaled_int(BASE_CHIP_GAP_X)
    local gap_y = _scaled_int(BASE_CHIP_GAP_Y)
    local x = 0
    local y = 0

    for i = 1, #texts do
        local text = texts[i]
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

local DropChip = class(Turbine.UI.Control)

function DropChip:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(1, 0.28, 0.28, 0.28))

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(Turbine.UI.Color(1, 0.08, 0.08, 0.08))

    self.label = Turbine.UI.Label()
    self.label:SetParent(self.inner)
    self.label:SetMouseVisible(false)
    self.label:SetMultiline(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self:apply_settings()
end

function DropChip:apply_settings()
    local border_w = _scaled_int(BASE_CHIP_BORDER)
    self.inner:SetPosition(border_w, border_w)
    self.label:SetFont(_scaled_font("Verdana", BASE_TEXT_FONT_SIZE))
    self.label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.label:SetForeColor(Turbine.UI.Color(1, 0.76, 0.88, 0.79))
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

function BestiaryRow:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)

    self.name_label = Turbine.UI.Label()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetMultiline(false)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

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
    self.separator:SetBackColor(Turbine.UI.Color(1, 0.12, 0.12, 0.12))

    self:apply_settings()
end

function BestiaryRow:apply_settings()
    self.name_label:SetFont(_scaled_font("Verdana", BASE_NAME_FONT_SIZE))
    self.name_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.name_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    self.name_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    local meta_font = _scaled_font("Verdana", BASE_TEXT_FONT_SIZE)
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

    self.separator:SetBackColor(Turbine.UI.Color(0.85, 0.32, 0.32, 0.32))

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

    local inner_w = math.max(1, width - (2 * pad_x))
    local right_w = math.min(_scaled_int(120), math.max(_scaled_int(72), math.floor(inner_w * 0.28)))
    local left_w = math.max(1, inner_w - right_w - _scaled_int(6))

    local drop_layout = record ~= nil and record._chip_layout or {}
    local drop_h = record ~= nil and _to_number(record._drop_height, _scaled_int(BASE_CHIP_H)) or _scaled_int(BASE_CHIP_H)
    local height = pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h

    self:SetSize(width, height)

    self.name_label:SetPosition(pad_x, pad_y)
    self.name_label:SetSize(left_w, line_h)
    self.level_label:SetPosition(pad_x + left_w + _scaled_int(6), pad_y)
    self.level_label:SetSize(right_w, line_h)

    self.morale_label:SetPosition(pad_x, pad_y + line_h + row_gap_y)
    self.morale_label:SetSize(left_w, line_h)
    self.power_label:SetPosition(pad_x + left_w + _scaled_int(6), pad_y + line_h + row_gap_y)
    self.power_label:SetSize(right_w, line_h)

    self.drop_area:SetPosition(pad_x, pad_y + (2 * (line_h + row_gap_y)))
    self.drop_area:SetSize(inner_w, drop_h)

    self.separator:SetPosition(0, height - separator_h)
    self.separator:SetSize(width, separator_h)

    if record == nil then
        for i = 1, #self.drop_chips do
            self.drop_chips[i]:SetVisible(false)
        end
        self:SetVisible(false)
        return
    end

    self:_ensure_chip_count(#drop_layout)
    self.name_label:SetText(record.name)
    self.level_label:SetText(record.level_text)
    self.morale_label:SetText(record.morale_text)
    self.power_label:SetText(record.power_text)

    local chip_h = _scaled_int(BASE_CHIP_H)
    for i = 1, #drop_layout do
        local chip_info = drop_layout[i]
        local chip = self.drop_chips[i]
        chip:SetPosition(chip_info.x, chip_info.y)
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

    self.sort_mode = SORT_NAME_ASC
    self.filter_groups = {}
    self.all_records = {}
    self.records = {}
    self.pages = {}
    self.page_index = 1
    self.entries = {}

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
    self.page_bar:SetParent(self.nav_bar)

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
        self:update_filter()
    end

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.filter_bar)
    self.clear_button:SetText(TR("Clear"))
    self.clear_button.Click = function()
        self.filter_tb:SetText("")
        self:update_filter()
        self.filter_tb:Focus()
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
        else
            if self.sort_dropdown ~= nil and self.sort_dropdown.Close ~= nil then
                self.sort_dropdown:Close()
            end
        end
    end

    self:SetSize(_scaled_int(700), _scaled_int(520))
    self:apply_settings()
end

function BestiaryWindow:bring_to_front()
    self:SetZOrder(210)
end

function BestiaryWindow:open()
    self:SetVisible(true)
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
        self:SetSize(math.max(_scaled_int(BASE_MIN_W), width), math.max(_scaled_int(BASE_MIN_H), height))
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

    if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.flush_expired ~= nil then
        BESTIARY_TRACKER:flush_expired()
    end

    local generation = _G.bestiary_cache_generation or 0
    if self._last_generation ~= generation then
        self:refresh_from_store(true)
    end
end

function BestiaryWindow:handle_user_resize()
    local min_w = _scaled_int(BASE_MIN_W)
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
    self:apply_view()
end

function BestiaryWindow:update_filter()
    local query = self.filter_tb:GetText() or ""
    self.filter_groups = _normalize_groups(_parse_query(query))
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
        local row = BestiaryRow()
        row:SetParent(self.content)
        row:SetVisible(false)
        self.entries[#self.entries + 1] = row
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
    local content_h = self:GetHeight() - content_top - margin_bottom
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
    self.page_bar:SetPosition(math.max(0, inner_w - self.page_bar:GetWidth()), 0)

    self.prev_button:SetPosition(0, 0)
    self.prev_button:SetSize(nav_w, bar_h)
    self.page_label:SetPosition(nav_w + gap, 0)
    self.page_label:SetSize(page_w, bar_h)
    self.next_button:SetPosition(nav_w + gap + page_w + gap, 0)
    self.next_button:SetSize(nav_w, bar_h)

    self.filter_bar:SetPosition(margin_left, margin_top + bar_h + gap)
    self.filter_bar:SetSize(inner_w, filter_h)

    local clear_w = _scaled_int(BASE_CLEAR_W)
    self.clear_button:SetPosition(inner_w - clear_w, 0)
    self.clear_button:SetSize(clear_w, filter_h)
    self.filter_tb:SetPosition(0, 0)
    self.filter_tb:SetSize(math.max(1, inner_w - clear_w - gap), filter_h)

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
    self:apply_view()
end

function BestiaryWindow:_prepare_records(records)
    local content_w = math.max(1, self.content:GetWidth())
    local line_h = _scaled_int(BASE_LINE_H)
    local separator_h = _scaled_int(BASE_ROW_SEPARATOR)
    local pad_y = _scaled_int(BASE_ROW_PAD_Y)
    local row_gap_y = _scaled_int(BASE_ROW_GAP_Y)
    local inner_w = math.max(1, content_w - (2 * _scaled_int(BASE_ROW_PAD_X)))

    for i = 1, #records do
        local record = records[i]
        local chip_texts = {}
        for di = 1, #record.drops do
            local drop = record.drops[di]
            chip_texts[#chip_texts + 1] = drop.name .. ": " .. _format_percent(drop.rate)
        end

        if #chip_texts == 0 then
            chip_texts = { TR("No drops seen.") }
        end

        local chip_layout, drop_h = _build_chip_layout(chip_texts, inner_w)

        record.level_text = TR("Level") .. ": " .. _format_range(record.level_min, record.level_max)
        record.morale_text = TR("Morale") .. ": " .. _format_number_range(record.morale_min, record.morale_max)
        record.power_text = TR("Power") .. ": " .. _format_number_range(record.power_min, record.power_max)
        record._chip_layout = chip_layout
        record._drop_height = drop_h
        record._view_height = pad_y + line_h + row_gap_y + line_h + row_gap_y + drop_h + pad_y + separator_h
    end
end

function BestiaryWindow:_build_pages(records)
    local pages = {}
    local content_h = math.max(1, self.content:GetHeight())
    local gap = _scaled_int(BASE_GAP)
    local start_index = 1
    local used = 0

    for i = 1, #records do
        local height = math.max(1, _to_number(records[i]._view_height, 1))
        local needed = used
        if used > 0 then
            needed = needed + gap
        end
        needed = needed + height

        if used > 0 and needed > content_h then
            pages[#pages + 1] = { first = start_index, last = i - 1 }
            start_index = i
            used = height
        else
            used = needed
        end
    end

    if #records > 0 then
        pages[#pages + 1] = { first = start_index, last = #records }
    end

    return pages
end

function BestiaryWindow:apply_view()
    local filtered = {}
    for i = 1, #self.all_records do
        local record = self.all_records[i]
        if _matches_groups(self.filter_groups, record.haystack_lower) == true then
            filtered[#filtered + 1] = record
        end
    end

    table.sort(filtered, function(left, right)
        return _compare_records(self.sort_mode, left, right)
    end)

    self.records = filtered
    self:_prepare_records(self.records)
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
        for i = 1, #self.entries do
            self.entries[i]:SetVisible(false)
        end
        return
    end

    self.empty_label:SetVisible(false)

    local page = self.pages[self.page_index]
    if page == nil then
        for i = 1, #self.entries do
            self.entries[i]:SetVisible(false)
        end
        return
    end

    local count = page.last - page.first + 1
    self:_ensure_rows(count)

    local y = 0
    local width = math.max(1, self.content:GetWidth())
    local gap = _scaled_int(BASE_GAP)

    for i = 1, count do
        local record = self.records[page.first + i - 1]
        local row = self.entries[i]
        row:SetPosition(0, y)
        row:bind(record, width)
        y = y + row:GetHeight() + gap
    end

    for i = count + 1, #self.entries do
        self.entries[i]:SetVisible(false)
    end
end

Bestiary.BestiaryWindow = BestiaryWindow
