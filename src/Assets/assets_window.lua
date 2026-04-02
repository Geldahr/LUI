import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Assets.assets_entry"

AssetsWindow = class(Turbine.UI.Lotro.Window)

local BASE_MARGIN_LEFT = 15
local BASE_MARGIN_TOP = 33
local BASE_MARGIN_RIGHT = 15
local BASE_MARGIN_BOTTOM = 15
local BASE_BAR_H = 21
local BASE_FILTER_H = 21
local BASE_SUMMARY_H = 21
local BASE_HINT_H = 19
local BASE_GAP = 4
local BASE_NAV_W = 22
local BASE_PAGE_W = 74
local BASE_MIN_W = 356
local BASE_MIN_H = 262
local BASE_DETAILS_W = 170
local BASE_DETAILS_MIN_H = 46
local BASE_DETAILS_EXTRA_H = 6
local BASE_ORDER_LABEL_W = 41
local BASE_GROUP_LABEL_W = 59
local BASE_SORT_W = 63
local BASE_GROUP_W = 78
local BASE_CLEAR_W = 59
local BASE_STACK_CB_W = 93
local BASE_STACK_BOX_W = 15
local BASE_STORAGE_LABEL_W = 56
local BASE_STORAGE_W = 133
local BASE_OWNER_LABEL_W = 67
local BASE_OWNER_W = 100
local BASE_VIEW_ICON_W = 19
local BASE_STACK_HINT_W = 200
local BASE_STACK_HINT_MAX_H = 178
local BASE_STACK_HINT_MIN_H = 44
local BASE_STACK_HINT_PAD_X = 12
local BASE_STACK_HINT_PAD_Y = 9
local BASE_STACK_HINT_LINE_H = 12
local STACK_HINT_BORDER = 2

local SUMMARY_TRACK_WIDTH_FACTOR = 0.70

local SUMMARY_BORDER_COLOR = Turbine.UI.Color(1, 0.35, 0.40, 0.50)
local SUMMARY_TOTAL_COLOR = Turbine.UI.Color(1, 0.35, 0.35, 0.35)
local SUMMARY_FILTERED_COLOR = Turbine.UI.Color(1, 0.20, 0.45, 0.80)
local SUMMARY_VISIBLE_COLOR = Turbine.UI.Color(1, 0.24, 0.72, 0.28)
local SUMMARY_TEXT_COLOR = Turbine.UI.Color(1, 1, 1, 1)
local SUMMARY_TEXT_OUTLINE = Turbine.UI.Color(1, 0, 0, 0)
local STACK_HINT_BACK_COLOR = Turbine.UI.Color(0.92, 0.05, 0.05, 0.05)

local SORT_NAME_ASC = "name_asc"
local SORT_NAME_DESC = "name_desc"
local SORT_QUANTITY_ASC = "quantity_asc"
local SORT_QUANTITY_DESC = "quantity_desc"

local GROUP_NONE = "none"
local GROUP_PLACE = "place"
local GROUP_CHARACTER = "character"

local STORAGE_ALL = "all"
local OWNER_ALL = "__all__"
local STACK_ITEMS_LABEL = "Stack items"

local VIEW_DETAILS_UP = Turbine.UI.Graphic(0x4110C76F)
local VIEW_DETAILS_DOWN = Turbine.UI.Graphic(0x4110C76D)
local VIEW_ICONS_UP = Turbine.UI.Graphic(0x4110C76C)
local VIEW_ICONS_DOWN = Turbine.UI.Graphic(0x4110C76A)

local SOURCE_ORDER = {
    backpack = 1,
    bank = 2,
    vault = 3,
    shared_storage = 4,
}

local SOURCE_HINT_COLORS = {
    backpack = Turbine.UI.Color(1, 0.43, 0.88, 0.43),
    bank = Turbine.UI.Color(1, 0.94, 0.78, 0.28),
    vault = Turbine.UI.Color(1, 0.42, 0.78, 0.96),
    shared_storage = Turbine.UI.Color(1, 0.98, 0.62, 0.32),
}

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * _G.settings.global.scale)
end

local function _clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function _portion_size(count, total, size)
    if count <= 0 or total <= 0 or size <= 0 then
        return 0
    end
    if count > total then
        count = total
    end
    return math.floor(((size * count) / total) + 0.5)
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end
    return string.lower(text)
end

local function _source_rank(source_key)
    return SOURCE_ORDER[source_key] or 99
end

local function _add_filter_part(parts, value)
    if type(value) ~= "string" or string.len(value) == 0 then
        return
    end
    parts[#parts + 1] = _lower_text(value)
end

local function _build_filter_text(record)
    local parts = {}
    _add_filter_part(parts, record ~= nil and record.name or nil)
    _add_filter_part(parts, record ~= nil and record.owner or nil)
    _add_filter_part(parts, record ~= nil and record.source_name or nil)
    if record ~= nil and type(record.source_key) == "string" then
        _add_filter_part(parts, string.gsub(record.source_key, "_", " "))
    end
    return table.concat(parts, " ")
end

local function _build_owner_options(records)
    local labels = { TR("All") }
    local values = { OWNER_ALL }
    local owners = {}
    local seen = {}

    for i = 1, #records do
        local owner = records[i].owner
        if type(owner) == "string" and string.len(owner) > 0 and seen[owner] ~= true then
            seen[owner] = true
            owners[#owners + 1] = owner
        end
    end

    table.sort(owners, function(left, right)
        return _lower_text(left) < _lower_text(right)
    end)

    for i = 1, #owners do
        labels[#labels + 1] = owners[i]
        values[#values + 1] = owners[i]
    end

    return labels, values
end

local function _source_hint_color(source_key)
    return SOURCE_HINT_COLORS[source_key] or SUMMARY_TEXT_COLOR
end

local function _color_luminance(red, green, blue)
    return (red * 0.2126) + (green * 0.7152) + (blue * 0.0722)
end

local function _color_spread(red, green, blue)
    return math.max(red, green, blue) - math.min(red, green, blue)
end

local function _owner_hint_color(owner)
    if type(owner) ~= "string" or string.len(owner) == 0 then
        return SUMMARY_TEXT_COLOR
    end

    local hash = 0
    for i = 1, string.len(owner) do
        hash = ((hash * 131) + string.byte(owner, i)) % 360
    end

    local hue = hash / 60
    local chroma = 0.42
    local x = chroma * (1 - math.abs((hue % 2) - 1))
    local m = 0.50
    local red = 0
    local green = 0
    local blue = 0

    if hue < 1 then
        red, green, blue = chroma, x, 0
    elseif hue < 2 then
        red, green, blue = x, chroma, 0
    elseif hue < 3 then
        red, green, blue = 0, chroma, x
    elseif hue < 4 then
        red, green, blue = 0, x, chroma
    elseif hue < 5 then
        red, green, blue = x, 0, chroma
    else
        red, green, blue = chroma, 0, x
    end

    red = red + m
    green = green + m
    blue = blue + m

    local luminance = _color_luminance(red, green, blue)
    if luminance < 0.72 then
        local boost = (0.72 - luminance) / 0.72
        red = red + ((1 - red) * boost)
        green = green + ((1 - green) * boost)
        blue = blue + ((1 - blue) * boost)
    end

    local spread = _color_spread(red, green, blue)
    if spread < 0.22 then
        local avg = (red + green + blue) / 3
        local boost = 1 + ((0.22 - spread) / 0.22)
        red = _clamp(avg + ((red - avg) * boost), 0, 1)
        green = _clamp(avg + ((green - avg) * boost), 0, 1)
        blue = _clamp(avg + ((blue - avg) * boost), 0, 1)
    end

    return Turbine.UI.Color(1, red, green, blue)
end

local function _stack_owner_sort_key(owner)
    if type(owner) ~= "string" or string.len(owner) == 0 then
        return "\255"
    end
    return _lower_text(owner)
end

local function _compare_stack_parts(left, right)
    local left_owner = _stack_owner_sort_key(left ~= nil and left.owner or nil)
    local right_owner = _stack_owner_sort_key(right ~= nil and right.owner or nil)
    if left_owner ~= right_owner then
        return left_owner < right_owner
    end

    local left_source = _lower_text(left ~= nil and left.source_name or nil)
    local right_source = _lower_text(right ~= nil and right.source_name or nil)
    if left_source ~= right_source then
        return left_source < right_source
    end

    return (left ~= nil and (left.quantity or 0) or 0) < (right ~= nil and (right.quantity or 0) or 0)
end

local function _stack_key_part(value)
    if type(value) ~= "string" then
        return tostring(value or "")
    end
    return value
end

local function _build_stack_key(record, keep_owner, keep_source)
    local parts = {
        _stack_key_part(record ~= nil and record.name or nil),
        tostring(record ~= nil and record.icon_id or 0),
        tostring(record ~= nil and record.background_image_id or 0),
        tostring(record ~= nil and record.quality or 0),
    }

    if keep_owner == true then
        parts[#parts + 1] = _stack_key_part(record ~= nil and record.owner or nil)
    end
    if keep_source == true then
        parts[#parts + 1] = _stack_key_part(record ~= nil and record.source_key or nil)
    end

    return table.concat(parts, "\30")
end

local function _set_view_button_background(control, up_texture, down_texture, active)
    if control == nil then
        return
    end
    local texture = up_texture
    if active == true then
        texture = down_texture
    end

    local w, h = control:GetSize()
    if type(w) == "number" and w > 0 and type(h) == "number" and h > 0 then
        control:set_icon(texture, w, h)
    else
        control:set_icon(texture)
    end
end

local function _compare_text(left, right, descending)
    if left == right then
        return nil
    end
    if descending == true then
        return left > right
    end
    return left < right
end

local function _compare_display_fallback(left, right)
    local by_owner = _compare_text(_lower_text(left.owner), _lower_text(right.owner), false)
    if by_owner ~= nil then
        return by_owner
    end

    local left_rank = _source_rank(left.source_key)
    local right_rank = _source_rank(right.source_key)
    if left_rank ~= right_rank then
        return left_rank < right_rank
    end

    local by_source = _compare_text(_lower_text(left.source_name), _lower_text(right.source_name), false)
    if by_source ~= nil then
        return by_source
    end

    local by_name = _compare_text(_lower_text(left.name), _lower_text(right.name), false)
    if by_name ~= nil then
        return by_name
    end

    local left_slot = left.slot or 0
    local right_slot = right.slot or 0
    if left_slot ~= right_slot then
        return left_slot < right_slot
    end

    return (left.quantity or 1) < (right.quantity or 1)
end

local function _compare_display_records(left, right, sort_mode, grouping_mode)
    if grouping_mode == GROUP_PLACE then
        local left_rank = _source_rank(left.source_key)
        local right_rank = _source_rank(right.source_key)
        if left_rank ~= right_rank then
            return left_rank < right_rank
        end
    elseif grouping_mode == GROUP_CHARACTER then
        local by_owner = _compare_text(_lower_text(left.owner), _lower_text(right.owner), false)
        if by_owner ~= nil then
            return by_owner
        end
    end

    local left_name = _lower_text(left.name)
    local right_name = _lower_text(right.name)
    local left_quantity = left.quantity or 1
    local right_quantity = right.quantity or 1

    if sort_mode == SORT_NAME_DESC then
        local by_name = _compare_text(left_name, right_name, true)
        if by_name ~= nil then
            return by_name
        end
    elseif sort_mode == SORT_QUANTITY_ASC then
        if left_quantity ~= right_quantity then
            return left_quantity < right_quantity
        end
        local by_name = _compare_text(left_name, right_name, false)
        if by_name ~= nil then
            return by_name
        end
    elseif sort_mode == SORT_QUANTITY_DESC then
        if left_quantity ~= right_quantity then
            return left_quantity > right_quantity
        end
        local by_name = _compare_text(left_name, right_name, false)
        if by_name ~= nil then
            return by_name
        end
    else
        local by_name = _compare_text(left_name, right_name, false)
        if by_name ~= nil then
            return by_name
        end
    end

    return _compare_display_fallback(left, right)
end

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

local function _parse_filter_query(query)
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

local function _normalize_filter_groups(groups)
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

local function _matches_filter_groups(groups, haystack_lower)
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
        if ok == true then
            return true
        end
    end

    return false
end

local function _mode_key(mode)
    if mode == LUI_ENUMS.assets_view_mode.ICONS then
        return "icons"
    end
    return "details"
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function AssetsWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetText(TR("Assets"))
    self:SetVisible(false)
    self:SetResizable(true)
    self:SetWantsUpdates(false)

    self.update_every = 1.0 / _G.settings.global.refresh_rate
    self.last_update_at = 0

    self._suppress_size_changed = false
    self._last_generation = nil

    self.tile_sizes = {
        icons = 40,
        details = 40,
    }
    self.tile_size = 40
    self.view_mode = LUI_ENUMS.assets_view_mode.DETAILS
    self.page_index = 1
    self.page_size = 1
    self.page_count = 1
    self.all_records = {}
    self.records = {}
    self.filter_groups = {}
    self.sort_mode = SORT_NAME_ASC
    self.grouping_mode = GROUP_NONE
    self.storage_filter = STORAGE_ALL
    self.owner_filter = OWNER_ALL
    self.stack_items = false
    self.total_record_count = 0

    self.entries = {}

    self.nav_bar = Turbine.UI.Control()
    self.nav_bar:SetParent(self)

    self.page_bar = Turbine.UI.Control()
    self.page_bar:SetParent(self)

    self.prev_button = UI.Widgets.LuiButton()
    self.prev_button:SetParent(self.page_bar)
    self.prev_button:set_text("")
    self.prev_button:set_padding(2)
    self.prev_button:set_icon(
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_transparent,
        BASE_NAV_W,
        nil,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
    self.prev_button.Click = function()
        self:set_page(self.page_index - 1)
    end

    self.page_label = UI.Widgets.LuiLabel()
    self.page_label:SetParent(self.page_bar)
    self.page_label:SetMouseVisible(false)
    self.page_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.next_button = UI.Widgets.LuiButton()
    self.next_button:SetParent(self.page_bar)
    self.next_button:set_text("")
    self.next_button:set_padding(2)
    self.next_button:set_icon(
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_transparent,
        BASE_NAV_W,
        nil,
        UI.Widgets.LuiButton.icon_position.RIGHT
    )
    self.next_button.Click = function()
        self:set_page(self.page_index + 1)
    end

    self.view_icons_button = Image()
    self.view_icons_button:SetParent(self.nav_bar)
    self.view_icons_button:SetMouseVisible(true)
    self.view_icons_button.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self:set_view_mode(LUI_ENUMS.assets_view_mode.ICONS, true)
    end

    self.view_details_button = Image()
    self.view_details_button:SetParent(self.nav_bar)
    self.view_details_button:SetMouseVisible(true)
    self.view_details_button.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self:set_view_mode(LUI_ENUMS.assets_view_mode.DETAILS, true)
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
    self.clear_button:set_text(TR("Clear"))
    self.clear_button.Click = function()
        self.filter_tb:SetText("")
        self:update_filter()
        self.filter_tb:Focus()
    end

    self._suppress_stack_changed = false
    self.stack_items_toggle = Turbine.UI.Control()
    self.stack_items_toggle:SetParent(self)

    self.stack_items_cb = UI.Widgets.LuiCheckBox()
    self.stack_items_cb:SetParent(self.stack_items_toggle)
    self.stack_items_cb:SetText("")
    self.stack_items_cb.CheckedChanged = function()
        if self._suppress_stack_changed == true then
            return
        end
        self:set_stack_items(self.stack_items_cb:IsChecked() == true)
    end

    self.stack_items_label = UI.Widgets.LuiLabel()
    self.stack_items_label:SetParent(self.stack_items_toggle)
    self.stack_items_label:SetMouseVisible(true)
    self.stack_items_label:SetSelectable(false)
    self.stack_items_label:SetMultiline(false)
    self.stack_items_label:SetFont(_scaled_font("Verdana", 11))
    self.stack_items_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.stack_items_label:SetText(TR(STACK_ITEMS_LABEL))
    self.stack_items_label.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        self.stack_items_cb:SetChecked(self.stack_items_cb:IsChecked() ~= true)
    end

    self.owner_label = UI.Widgets.LuiLabel()
    self.owner_label:SetParent(self.nav_bar)
    self.owner_label:SetMouseVisible(false)
    self.owner_label:SetSelectable(false)
    self.owner_label:SetMultiline(false)
    self.owner_label:SetFont(_scaled_font("Verdana", 11))
    self.owner_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.owner_label:SetText(TR("Character") .. ":")

    self._suppress_owner_changed = false
    self.owner_dropdown = UI.Widgets.LuiDropdown()
    self.owner_dropdown:SetParent(self.nav_bar)
    self.owner_dropdown:SetPopupHost(self)
    self.owner_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.owner_dropdown:SetMappedOptions({ TR("All") }, { OWNER_ALL })
    self.owner_dropdown.ValueChanged = function(_, value)
        if self._suppress_owner_changed == true then
            return
        end
        self:set_owner_filter(value)
    end

    self.storage_label = UI.Widgets.LuiLabel()
    self.storage_label:SetParent(self.nav_bar)
    self.storage_label:SetMouseVisible(false)
    self.storage_label:SetSelectable(false)
    self.storage_label:SetMultiline(false)
    self.storage_label:SetFont(_scaled_font("Verdana", 11))
    self.storage_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.storage_label:SetText(TR("Storage") .. ":")

    self.storage_dropdown = UI.Widgets.LuiDropdown()
    self.storage_dropdown:SetParent(self.nav_bar)
    self.storage_dropdown:SetPopupHost(self)
    self.storage_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.storage_dropdown:SetMappedOptions(
        { TR("All"), TR("Backpack"), TR("Bank"), TR("Shared Storage"), TR("Vault") },
        { STORAGE_ALL, "backpack", "bank", "shared_storage", "vault" }
    )
    self.storage_dropdown.ValueChanged = function(_, value)
        self:set_storage_filter(value)
    end

    self.summary_bar = Turbine.UI.Control()
    self.summary_bar:SetParent(self)

    self.summary_track = Turbine.UI.Control()
    self.summary_track:SetParent(self.summary_bar)
    self.summary_track:SetMouseVisible(false)
    self.summary_track:SetBackColor(SUMMARY_BORDER_COLOR)

    self.summary_track_inner = Turbine.UI.Control()
    self.summary_track_inner:SetParent(self.summary_track)
    self.summary_track_inner:SetMouseVisible(false)
    self.summary_track_inner:SetBackColor(SUMMARY_TOTAL_COLOR)

    self.summary_filtered_fill = Turbine.UI.Control()
    self.summary_filtered_fill:SetParent(self.summary_track_inner)
    self.summary_filtered_fill:SetMouseVisible(false)
    self.summary_filtered_fill:SetBackColor(SUMMARY_FILTERED_COLOR)

    self.summary_visible_fill = Turbine.UI.Control()
    self.summary_visible_fill:SetParent(self.summary_track_inner)
    self.summary_visible_fill:SetMouseVisible(false)
    self.summary_visible_fill:SetBackColor(SUMMARY_VISIBLE_COLOR)

    self.summary_text = UI.Widgets.LuiLabel()
    self.summary_text:SetParent(self.summary_track)
    self.summary_text:SetMouseVisible(false)
    self.summary_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.summary_text:SetForeColor(SUMMARY_TEXT_COLOR)
    self.summary_text:SetOutlineColor(SUMMARY_TEXT_OUTLINE)
    self.summary_text:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.summary_text:SetZOrder(2)

    self.order_label = UI.Widgets.LuiLabel()
    self.order_label:SetParent(self.nav_bar)
    self.order_label:SetMouseVisible(false)
    self.order_label:SetSelectable(false)
    self.order_label:SetMultiline(false)
    self.order_label:SetFont(_scaled_font("Verdana", 11))
    self.order_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.order_label:SetText(TR("Order") .. ":")

    self.sort_dropdown = UI.Widgets.LuiDropdown()
    self.sort_dropdown:SetParent(self.nav_bar)
    self.sort_dropdown:SetPopupHost(self)
    self.sort_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.sort_dropdown:SetMappedOptions(
        { TR("A-Z"), TR("Z-A"), TR("Qty <"), TR("Qty >") },
        { SORT_NAME_ASC, SORT_NAME_DESC, SORT_QUANTITY_ASC, SORT_QUANTITY_DESC }
    )
    self.sort_dropdown.ValueChanged = function(_, value)
        self:set_sort_mode(value)
    end

    self.group_label = UI.Widgets.LuiLabel()
    self.group_label:SetParent(self.nav_bar)
    self.group_label:SetMouseVisible(false)
    self.group_label:SetSelectable(false)
    self.group_label:SetMultiline(false)
    self.group_label:SetFont(_scaled_font("Verdana", 11))
    self.group_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.group_label:SetText(TR("Group by") .. ":")

    self.group_dropdown = UI.Widgets.LuiDropdown()
    self.group_dropdown:SetParent(self.nav_bar)
    self.group_dropdown:SetPopupHost(self)
    self.group_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.group_dropdown:SetMappedOptions(
        { TR("None"), TR("Place"), TR("Character") },
        { GROUP_NONE, GROUP_PLACE, GROUP_CHARACTER }
    )
    self.group_dropdown.ValueChanged = function(_, value)
        self:set_grouping_mode(value)
    end

    self.content = Turbine.UI.Control()
    self.content:SetParent(self)
    self.content:SetMouseVisible(false)

    self.empty_label = UI.Widgets.LuiLabel()
    self.empty_label:SetParent(self.content)
    self.empty_label:SetMouseVisible(false)
    self.empty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.empty_label:SetText(TR("No cached items yet."))

    self.hint_label = UI.Widgets.LuiLabel()
    self.hint_label:SetParent(self)
    self.hint_label:SetMouseVisible(false)
    self.hint_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.hint_label:SetVisible(false)

    self.stack_hint = Turbine.UI.Window()
    self.stack_hint:SetVisible(false)
    self.stack_hint:SetMouseVisible(false)
    self.stack_hint:SetZOrder(2200)
    self.stack_hint:SetBackColor(SUMMARY_BORDER_COLOR)

    self.stack_hint_inner = Turbine.UI.Control()
    self.stack_hint_inner:SetParent(self.stack_hint)
    self.stack_hint_inner:SetMouseVisible(false)
    self.stack_hint_inner:SetBackColor(STACK_HINT_BACK_COLOR)
    self.stack_hint_rows = {}

    self.SizeChanged = function()
        if self._suppress_size_changed == true then
            return
        end
        self:handle_user_resize()
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if visible == true then
            self.last_update_at = 0
            self._last_generation = nil
            self:bring_to_front()
            if ASSETS_STORE ~= nil and ASSETS_STORE.refresh_now ~= nil then
                ASSETS_STORE:refresh_now(nil, true)
            end
            self:refresh_from_store(true)
        else
            self:_hide_stack_hint()
        end
    end

    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function AssetsWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function AssetsWindow:open()
    self:SetVisible(true)
    self:bring_to_front()
end

function AssetsWindow:toggle()
    self:SetVisible(not self:IsVisible())
    if self:IsVisible() == true then
        self:bring_to_front()
        self._last_generation = nil
    end
end

function AssetsWindow:capture_geometry()
    local raw = _G.loaded_settings.assets
    self:_save_current_layout()
    raw.view_mode = self.view_mode
    raw.stack_items = self.stack_items
end

function AssetsWindow:persist_geometry()
    self:capture_geometry()
end

function AssetsWindow:set_view_mode(mode, persist)
    if mode ~= LUI_ENUMS.assets_view_mode.ICONS and mode ~= LUI_ENUMS.assets_view_mode.DETAILS then
        mode = LUI_ENUMS.assets_view_mode.DETAILS
    end
    if mode == self.view_mode then
        return
    end

    self:_save_current_layout()
    self.view_mode = mode
    self.tile_size = self:_get_mode_tile_size(mode)
    _G.settings.assets.view_mode = mode
    _G.loaded_settings.assets.view_mode = mode

    self.page_index = 1
    self:_apply_layout_for_mode(mode)
    self:snap_window_size()
    self:_update_view_buttons()
    self:layout()
    self:refresh_from_store(true)
end

function AssetsWindow:set_page(index)
    local page = _clamp(index, 1, self.page_count)
    if page == self.page_index then
        return
    end

    self.page_index = page
    self:refresh_page()
end

function AssetsWindow:update_filter()
    local query = self.filter_tb:GetText() or ""
    self.filter_groups = _normalize_filter_groups(_parse_filter_query(query))
    self:_apply_record_view(true)
end

function AssetsWindow:set_storage_filter(value)
    if value ~= "vault" and value ~= "bank" and value ~= "backpack" and value ~= "shared_storage" then
        value = STORAGE_ALL
    end
    if value == self.storage_filter then
        return
    end

    self.storage_filter = value
    self:_apply_record_view(true)
end

function AssetsWindow:set_owner_filter(value)
    if type(value) ~= "string" or string.len(value) == 0 then
        value = OWNER_ALL
    end
    if value == self.owner_filter then
        return
    end

    self.owner_filter = value
    self:_apply_record_view(true)
end

function AssetsWindow:set_stack_items(enabled)
    enabled = enabled == true
    if enabled == self.stack_items then
        return
    end

    self.stack_items = enabled
    _G.settings.assets.stack_items = enabled
    _G.loaded_settings.assets.stack_items = enabled
    self:_hide_stack_hint()
    self:_apply_record_view(true)
end

function AssetsWindow:set_sort_mode(mode)
    if mode ~= SORT_NAME_ASC and mode ~= SORT_NAME_DESC and
        mode ~= SORT_QUANTITY_ASC and mode ~= SORT_QUANTITY_DESC then
        mode = SORT_NAME_ASC
    end
    if mode == self.sort_mode then
        return
    end

    self.sort_mode = mode
    self:_apply_record_view(true)
end

function AssetsWindow:set_grouping_mode(mode)
    if mode ~= GROUP_PLACE and mode ~= GROUP_CHARACTER then
        mode = GROUP_NONE
    end
    if mode == self.grouping_mode then
        return
    end

    self.grouping_mode = mode
    self:_apply_record_view(true)
end

function AssetsWindow:apply_settings()
    local s = _G.settings.assets

    self.update_every = 1.0 / _G.settings.global.refresh_rate
    self.tile_sizes.icons = s.tile.icons
    self.tile_sizes.details = s.tile.details
    self.view_mode = s.view_mode
    self.stack_items = s.stack_items == true
    self.tile_size = self:_get_mode_tile_size(self.view_mode)

    local button_font = _scaled_font("Verdana", 11)
    self.prev_button:set_font(button_font)
    self.next_button:set_font(button_font)
    self.clear_button:set_font(button_font)
    self.filter_tb:SetFont(button_font)
    self.stack_items_cb:SetScale(_G.settings.global.scale)
    self.stack_items_cb:SetFont(button_font)
    self.stack_items_label:SetFont(button_font)
    self.owner_label:SetFont(_scaled_font("Verdana", 11))
    self.owner_dropdown:SetFont(button_font)
    self.storage_label:SetFont(_scaled_font("Verdana", 11))
    self.storage_dropdown:SetFont(button_font)
    self.sort_dropdown:SetFont(button_font)
    self.group_dropdown:SetFont(button_font)
    self.owner_dropdown:SetScale(_G.settings.global.scale)
    self.storage_dropdown:SetScale(_G.settings.global.scale)
    self.sort_dropdown:SetScale(_G.settings.global.scale)
    self.group_dropdown:SetScale(_G.settings.global.scale)
    self._suppress_stack_changed = true
    self.stack_items_cb:SetChecked(self.stack_items == true)
    self._suppress_stack_changed = false
    self.owner_dropdown:SetValue(self.owner_filter)
    self.storage_dropdown:SetValue(self.storage_filter)
    self.sort_dropdown:SetValue(self.sort_mode)
    self.group_dropdown:SetValue(self.grouping_mode)

    self.page_label:SetFont(button_font)
    self.summary_text:SetFont(button_font)
    self.order_label:SetFont(_scaled_font("Verdana", 11))
    self.group_label:SetFont(_scaled_font("Verdana", 11))
    self.hint_label:SetFont(_scaled_font("Verdana", 10))
    self.empty_label:SetFont(_scaled_font("Verdana", 12))

    self:_apply_layout_for_mode(self.view_mode)
    self:snap_window_size()
    self:_update_view_buttons()
    self:layout()
    self:refresh_from_store(true)
end

function AssetsWindow:handle_user_resize()
    self:snap_window_size()
    self:layout()
    self:refresh_from_store(true)
end

function AssetsWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - (self.last_update_at or 0)) < self.update_every then
        return
    end
    self.last_update_at = now

    self:refresh_from_store(false)
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function AssetsWindow:_enforce_min_size()
    local width, height = self:GetSize()
    local min_w = _scaled_int(BASE_MIN_W)
    local min_h = _scaled_int(BASE_MIN_H)

    if width < min_w or height < min_h then
        self._suppress_size_changed = true
        self:SetSize(math.max(width, min_w), math.max(height, min_h))
        self._suppress_size_changed = false
    end
end

function AssetsWindow:_get_layout_store(mode)
    local raw = _G.loaded_settings.assets
    local key = _mode_key(mode)
    return raw.layouts[key]
end

function AssetsWindow:_get_mode_tile_size(mode)
    local key = _mode_key(mode)
    local tile_size = self.tile_sizes[key]
    if tile_size == nil then
        tile_size = self.tile_size
    end
    return tile_size
end

function AssetsWindow:_sync_window_layout(layout)
    local raw = _G.loaded_settings.assets
    raw.window.left = layout.left
    raw.window.top = layout.top
    raw.window.cols = layout.cols
    raw.window.rows = layout.rows
end

function AssetsWindow:_save_current_layout()
    local layout = self:_get_layout_store(self.view_mode)
    local left, top = self:GetPosition()
    local width, height = self:GetSize()
    local content_w, content_h = self:_get_content_size_from_window(width, height)
    local cols, rows = self:_get_layout_grid_from_content_size(self.view_mode, self.tile_size, content_w, content_h)

    layout.left = left
    layout.top = top
    layout.cols = cols
    layout.rows = rows
    self:_sync_window_layout(layout)
end

function AssetsWindow:_apply_layout_for_mode(mode)
    local layout = self:_get_layout_store(mode)
    local tile_size = self:_get_mode_tile_size(mode)
    local width, height = self:_get_window_size_for_layout_grid(mode, tile_size, layout.cols, layout.rows)
    self:_sync_window_layout(layout)

    self._suppress_size_changed = true
    self:SetPosition(layout.left, layout.top)
    self:SetSize(width, height)
    self._suppress_size_changed = false
end

function AssetsWindow:_get_layout_numbers()
    return {
        margin_left = _scaled_int(BASE_MARGIN_LEFT),
        margin_top = _scaled_int(BASE_MARGIN_TOP),
        margin_right = _scaled_int(BASE_MARGIN_RIGHT),
        margin_bottom = _scaled_int(BASE_MARGIN_BOTTOM),
        bar_h = _scaled_int(BASE_BAR_H),
        filter_h = _scaled_int(BASE_FILTER_H),
        summary_h = _scaled_int(BASE_SUMMARY_H),
        page_h = _scaled_int(BASE_BAR_H),
        hint_h = _scaled_int(BASE_HINT_H),
        gap = _scaled_int(BASE_GAP),
    }
end

function AssetsWindow:_get_cell_size_for(mode, tile_size)
    if mode == LUI_ENUMS.assets_view_mode.ICONS then
        return tile_size, tile_size
    end
    return tile_size + _scaled_int(BASE_DETAILS_W),
        math.max(tile_size + _scaled_int(BASE_DETAILS_EXTRA_H), _scaled_int(BASE_DETAILS_MIN_H))
end

function AssetsWindow:_get_cell_size()
    return self:_get_cell_size_for(self.view_mode, self.tile_size)
end

function AssetsWindow:_get_content_size_from_window(width, height)
    local layout = self:_get_layout_numbers()
    local content_w = width - layout.margin_left - layout.margin_right
    local content_h = height - layout.margin_top - layout.margin_bottom - layout.bar_h - layout.filter_h -
        layout.summary_h - layout.page_h - layout.hint_h - (layout.gap * 5)

    if content_w < 0 then content_w = 0 end
    if content_h < 0 then content_h = 0 end

    return content_w, content_h, layout
end

function AssetsWindow:_get_layout_grid_from_content_size(mode, tile_size, content_w, content_h)
    local gap = _scaled_int(BASE_GAP)
    local cell_w, cell_h = self:_get_cell_size_for(mode, tile_size)
    local cols = math.floor((content_w + gap) / (cell_w + gap))
    local rows = math.floor((content_h + gap) / (cell_h + gap))

    if cols < 1 then cols = 1 end
    if rows < 1 then rows = 1 end

    return cols, rows
end

function AssetsWindow:_get_content_size_for_layout_grid(mode, tile_size, cols, rows)
    local gap = _scaled_int(BASE_GAP)
    local cell_w, cell_h = self:_get_cell_size_for(mode, tile_size)

    if cols == nil or cols < 1 then cols = 1 end
    if rows == nil or rows < 1 then rows = 1 end

    local content_w = (cols * cell_w) + ((cols - 1) * gap)
    local content_h = (rows * cell_h) + ((rows - 1) * gap)
    return content_w, content_h
end

function AssetsWindow:_get_window_size_for_layout_grid(mode, tile_size, cols, rows)
    local layout = self:_get_layout_numbers()
    local content_w, content_h = self:_get_content_size_for_layout_grid(mode, tile_size, cols, rows)

    local width = layout.margin_left + layout.margin_right + content_w
    local height = layout.margin_top + layout.margin_bottom + layout.bar_h + layout.filter_h + layout.summary_h +
        layout.page_h + layout.hint_h + (layout.gap * 5) + content_h

    return width, height
end

function AssetsWindow:get_snap_dimensions(width, height)
    local content_w, content_h, layout = self:_get_content_size_from_window(width, height)
    local cols, rows = self:_get_layout_grid_from_content_size(self.view_mode, self.tile_size, content_w, content_h)

    local min_w = _scaled_int(BASE_MIN_W)
    local min_h = _scaled_int(BASE_MIN_H)
    local min_content_w, min_content_h = self:_get_content_size_from_window(min_w, min_h)
    local min_cols, min_rows = self:_get_layout_grid_from_content_size(self.view_mode, self.tile_size, min_content_w,
        min_content_h)
    if cols < min_cols then cols = min_cols end
    if rows < min_rows then rows = min_rows end

    local snapped_content_w, snapped_content_h = self:_get_content_size_for_layout_grid(self.view_mode, self.tile_size,
        cols, rows)
    local snapped_w = layout.margin_left + layout.margin_right + snapped_content_w
    local snapped_h = layout.margin_top + layout.margin_bottom + layout.bar_h + layout.filter_h + layout.summary_h +
        layout.page_h + layout.hint_h + (layout.gap * 5) + snapped_content_h

    if snapped_w < min_w then snapped_w = min_w end
    if snapped_h < min_h then snapped_h = min_h end

    return snapped_w, snapped_h
end

function AssetsWindow:snap_window_size()
    local width, height = self:GetSize()
    local snapped_w, snapped_h = self:get_snap_dimensions(width, height)
    if snapped_w == width and snapped_h == height then
        return
    end

    self._suppress_size_changed = true
    self:SetSize(snapped_w, snapped_h)
    self._suppress_size_changed = false
end

function AssetsWindow:_get_content_metrics()
    local width, height = self.content:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local cell_w, cell_h = self:_get_cell_size()
    local cols = math.floor((width + gap) / (cell_w + gap))
    local rows = math.floor((height + gap) / (cell_h + gap))

    if cols < 1 then cols = 1 end
    if rows < 1 then rows = 1 end

    return {
        gap = gap,
        cell_w = cell_w,
        cell_h = cell_h,
        cols = cols,
        rows = rows,
        page_size = cols * rows,
    }
end

function AssetsWindow:_ensure_entries(count)
    while #self.entries < count do
        local entry = AssetsEntry(function(record, control, icon_hover)
            self:_set_hint(record, control, icon_hover)
        end)
        entry:SetParent(self.content)
        entry:SetVisible(false)
        self.entries[#self.entries + 1] = entry
    end
end

function AssetsWindow:_update_view_buttons()
    _set_view_button_background(
        self.view_icons_button,
        VIEW_ICONS_UP,
        VIEW_ICONS_DOWN,
        self.view_mode == LUI_ENUMS.assets_view_mode.ICONS
    )
    _set_view_button_background(
        self.view_details_button,
        VIEW_DETAILS_UP,
        VIEW_DETAILS_DOWN,
        self.view_mode == LUI_ENUMS.assets_view_mode.DETAILS
    )
end

function AssetsWindow:_refresh_empty_state()
    if #self.all_records == 0 then
        self.empty_label:SetText(TR("No cached items yet."))
        return
    end

    self.empty_label:SetText(TR("No matching items."))
end

function AssetsWindow:_refresh_owner_options()
    local labels, values = _build_owner_options(self.all_records)
    local selected = self.owner_filter
    local found = false

    for i = 1, #values do
        if values[i] == selected then
            found = true
            break
        end
    end

    if found ~= true then
        selected = OWNER_ALL
    end

    self._suppress_owner_changed = true
    self.owner_dropdown:SetMappedOptions(labels, values)
    self.owner_dropdown:SetValue(selected)
    self._suppress_owner_changed = false
    self.owner_filter = selected
end

function AssetsWindow:_stack_records(records)
    local keep_owner = self.grouping_mode == GROUP_CHARACTER
    local keep_source = self.grouping_mode == GROUP_PLACE
    local by_key = {}
    local out = {}

    for i = 1, #records do
        local record = records[i]
        local key = _build_stack_key(record, keep_owner, keep_source)
        local stacked = by_key[key]

        if stacked == nil then
            stacked = {
                name = record.name,
                quantity = 0,
                icon_id = record.icon_id,
                background_image_id = record.background_image_id,
                quality = record.quality,
                item = record.item,
                item_info = record.item_info,
                owner = keep_owner == true and (record.owner or "") or "",
                has_multiple_owners = false,
                slot = record.slot or 0,
                source_key = keep_source == true and (record.source_key or "") or "",
                source_name = keep_source == true and (record.source_name or "") or "",
                has_multiple_sources = false,
                stack_parts = {},
                _part_lookup = {},
                _owner_lookup = {},
                _source_lookup = {},
                _owner_first = record.owner or "",
                _source_key_first = record.source_key or "",
                _source_name_first = record.source_name or "",
            }
            by_key[key] = stacked
            out[#out + 1] = stacked
        end

        local quantity = record.quantity or 1
        stacked.quantity = stacked.quantity + quantity
        if (record.slot or 0) < (stacked.slot or 0) then
            stacked.slot = record.slot or 0
        end
        if record.icon_id ~= nil and stacked.icon_id == nil then
            stacked.icon_id = record.icon_id
        end
        if record.background_image_id ~= nil and stacked.background_image_id == nil then
            stacked.background_image_id = record.background_image_id
        end
        if record.quality ~= nil and stacked.quality == nil then
            stacked.quality = record.quality
        end
        if record.item ~= nil and stacked.item == nil then
            stacked.item = record.item
        end
        if record.item_info ~= nil and stacked.item_info == nil then
            stacked.item_info = record.item_info
        end

        stacked._owner_lookup[record.owner or ""] = true
        stacked._source_lookup[record.source_key or ""] = {
            source_key = record.source_key or "",
            source_name = record.source_name or "",
        }

        local part_key = table.concat({
            _stack_key_part(record.owner or ""),
            _stack_key_part(record.source_key or ""),
        }, "\30")
        local part = stacked._part_lookup[part_key]
        if part == nil then
            part = {
                owner = record.owner or "",
                source_key = record.source_key or "",
                source_name = record.source_name or "",
                quantity = 0,
            }
            stacked._part_lookup[part_key] = part
            stacked.stack_parts[#stacked.stack_parts + 1] = part
        end
        part.quantity = part.quantity + quantity
    end

    for i = 1, #out do
        local stacked = out[i]
        if keep_owner ~= true then
            local owner_count = 0
            for owner_value in pairs(stacked._owner_lookup) do
                if owner_value ~= "" then
                    owner_count = owner_count + 1
                    stacked.owner = owner_value
                    if owner_count > 1 then
                        stacked.has_multiple_owners = true
                        stacked.owner = ""
                        break
                    end
                end
            end
        end

        if keep_source ~= true then
            local source_count = 0
            for _, source_value in pairs(stacked._source_lookup) do
                if source_value.source_key ~= "" then
                    source_count = source_count + 1
                    stacked.source_key = source_value.source_key
                    stacked.source_name = source_value.source_name
                    if source_count > 1 then
                        stacked.has_multiple_sources = true
                        stacked.source_key = ""
                        stacked.source_name = ""
                        break
                    end
                end
            end
        end

        table.sort(stacked.stack_parts, _compare_stack_parts)
        stacked._part_lookup = nil
        stacked._owner_lookup = nil
        stacked._source_lookup = nil
        stacked._owner_first = nil
        stacked._source_key_first = nil
        stacked._source_name_first = nil
    end

    return out
end

function AssetsWindow:_ensure_stack_hint_rows(count)
    while #self.stack_hint_rows < count do
        local row = {}
        row.holder = Turbine.UI.Control()
        row.holder:SetParent(self.stack_hint_inner)
        row.holder:SetMouseVisible(false)

        row.owner = UI.Widgets.LuiLabel()
        row.owner:SetParent(row.holder)
        row.owner:SetMouseVisible(false)
        row.owner:SetMultiline(false)
        row.owner:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        row.owner:SetFont(_scaled_font("Verdana", 10))

        row.detail = UI.Widgets.LuiLabel()
        row.detail:SetParent(row.holder)
        row.detail:SetMouseVisible(false)
        row.detail:SetMultiline(false)
        row.detail:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        row.detail:SetFont(_scaled_font("Verdana", 10))

        row.quantity = UI.Widgets.LuiLabel()
        row.quantity:SetParent(row.holder)
        row.quantity:SetMouseVisible(false)
        row.quantity:SetMultiline(false)
        row.quantity:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        row.quantity:SetFont(_scaled_font("Verdana", 10))

        self.stack_hint_rows[#self.stack_hint_rows + 1] = row
    end
end

function AssetsWindow:_hide_stack_hint()
    if self.stack_hint ~= nil then
        self.stack_hint:SetVisible(false)
    end
end

function AssetsWindow:_show_stack_hint(anchor_control, record)
    if anchor_control == nil or record == nil or type(record.stack_parts) ~= "table" or #record.stack_parts == 0 then
        self:_hide_stack_hint()
        return
    end

    local max_width = _scaled_int(BASE_STACK_HINT_W)
    local padding_x = _scaled_int(BASE_STACK_HINT_PAD_X)
    local padding_y = _scaled_int(BASE_STACK_HINT_PAD_Y)
    local line_height = _scaled_int(BASE_STACK_HINT_LINE_H)
    local line_count = #record.stack_parts
    local content_height = math.min(
        _scaled_int(BASE_STACK_HINT_MAX_H),
        math.max(_scaled_int(BASE_STACK_HINT_MIN_H), (line_count * line_height) + padding_y + _scaled_int(7))
    )
    local desired_height = content_height + (STACK_HINT_BORDER * 2)
    local inner_w = max_width - (STACK_HINT_BORDER * 2)
    local inner_h = desired_height - (STACK_HINT_BORDER * 2)

    self:_ensure_stack_hint_rows(line_count)
    for i = 1, #self.stack_hint_rows do
        local row = self.stack_hint_rows[i]
        if i <= line_count then
            local part = record.stack_parts[i]
            local row_x = math.floor(padding_x / 2)
            local row_y = _scaled_int(4) + ((i - 1) * line_height)
            local row_w = inner_w - padding_x
            local detail_text = part.source_name or ""
            local quantity_text = lui_abbrev_number(part.quantity)
            local owner_text = part.owner or ""
            local col_gap = _scaled_int(4)
            local quantity_w = math.max(_scaled_int(24), math.floor(row_w * 0.16))
            local quantity_x = math.max(0, row_w - quantity_w)

            row.holder:SetPosition(row_x, row_y)
            row.holder:SetSize(row_w, line_height)

            if string.len(owner_text) > 0 then
                local detail_x = math.floor(row_w / 2)
                local owner_w = math.max(0, detail_x - col_gap)
                row.owner:SetPosition(0, 0)
                row.owner:SetSize(owner_w, line_height)
                row.owner:SetFont(_scaled_font("Verdana", 10))
                row.owner:SetForeColor(_owner_hint_color(owner_text))
                row.owner:SetText(owner_text)
                row.owner:SetVisible(true)

                row.detail:SetPosition(detail_x, 0)
                row.detail:SetSize(math.max(0, quantity_x - detail_x - col_gap), line_height)
            else
                row.owner:SetVisible(false)
                row.detail:SetPosition(0, 0)
                row.detail:SetSize(math.max(0, quantity_x - col_gap), line_height)
            end

            row.detail:SetFont(_scaled_font("Verdana", 10))
            row.detail:SetForeColor(_source_hint_color(part.source_key))
            row.detail:SetText(detail_text)
            row.detail:SetVisible(true)

            row.quantity:SetPosition(quantity_x, 0)
            row.quantity:SetSize(quantity_w, line_height)
            row.quantity:SetFont(_scaled_font("Verdana", 10))
            row.quantity:SetForeColor(_source_hint_color(part.source_key))
            row.quantity:SetText(quantity_text)
            row.quantity:SetVisible(true)
            row.holder:SetVisible(true)
        else
            row.owner:SetVisible(false)
            row.detail:SetVisible(false)
            row.quantity:SetVisible(false)
            row.holder:SetVisible(false)
        end
    end

    self.stack_hint:SetSize(max_width, desired_height)
    self.stack_hint_inner:SetPosition(STACK_HINT_BORDER, STACK_HINT_BORDER)
    self.stack_hint_inner:SetSize(inner_w, inner_h)

    local x, y = anchor_control:PointToScreen(0, anchor_control:GetHeight() + _scaled_int(1))
    local display_width, display_height = Turbine.UI.Display.GetSize()
    if x + max_width > display_width then
        x = display_width - max_width - _scaled_int(4)
    end
    if y + desired_height > display_height then
        y = y - desired_height - anchor_control:GetHeight() - _scaled_int(4)
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    self.stack_hint:SetPosition(x, y)
    self.stack_hint:SetVisible(true)
end

function AssetsWindow:_apply_record_view(reset_page)
    local filtered = {}
    local total_record_count = #self.all_records

    for i = 1, #self.all_records do
        local record = self.all_records[i]
        if (self.storage_filter == STORAGE_ALL or record.source_key == self.storage_filter) and
            (self.owner_filter == OWNER_ALL or record.owner == self.owner_filter) and
            _matches_filter_groups(self.filter_groups, record.haystack_lower or "") == true then
            filtered[#filtered + 1] = record
        end
    end

    if self.stack_items == true then
        total_record_count = #self:_stack_records(self.all_records)
        filtered = self:_stack_records(filtered)
    end

    table.sort(filtered, function(left, right)
        return _compare_display_records(left, right, self.sort_mode, self.grouping_mode)
    end)

    self.total_record_count = total_record_count
    self.records = filtered
    if reset_page == true then
        self.page_index = 1
    end

    self:_refresh_empty_state()
    self:refresh_page()
end

function AssetsWindow:_refresh_summary(visible_count, page_start_index)
    local total_count = self.total_record_count or 0
    local filtered_count = #self.records
    local visible_items = visible_count or 0
    local filtered_offset = page_start_index or 0
    local track_w, track_h = self.summary_track_inner:GetSize()

    if filtered_offset < 0 then
        filtered_offset = 0
    end
    if filtered_offset > filtered_count then
        filtered_offset = filtered_count
    end

    local filtered_w = _portion_size(filtered_count, total_count, track_w)
    local visible_w = _portion_size(visible_items, total_count, track_w)
    local visible_x = _portion_size(filtered_offset, total_count, track_w)

    if filtered_w > track_w then
        filtered_w = track_w
    end
    if visible_w > filtered_w then
        visible_w = filtered_w
    end
    if visible_x > filtered_w then
        visible_x = filtered_w
    end
    if (visible_x + visible_w) > filtered_w then
        visible_x = math.max(0, filtered_w - visible_w)
    end

    self.summary_filtered_fill:SetPosition(0, 0)
    self.summary_filtered_fill:SetSize(filtered_w, track_h)
    self.summary_filtered_fill:SetVisible(filtered_w > 0 and track_h > 0)

    self.summary_visible_fill:SetPosition(visible_x, 0)
    self.summary_visible_fill:SetSize(visible_w, track_h)
    self.summary_visible_fill:SetVisible(visible_w > 0 and track_h > 0)

    self.summary_text:SetText(
        tostring(visible_items) .. " / " .. tostring(filtered_count) .. " / " .. tostring(total_count)
    )
end

function AssetsWindow:_set_hint(record, anchor_control, icon_hover)
    if record == nil then
        self:_hide_stack_hint()
        return
    end

    local stack_part_count = 0
    if self.stack_items == true and type(record.stack_parts) == "table" then
        stack_part_count = #record.stack_parts
    end

    if stack_part_count > 1 then
        if icon_hover == true then
            self:_hide_stack_hint()
            return
        end
        self:_show_stack_hint(anchor_control, record)
        return
    end

    self:_hide_stack_hint()
end

function AssetsWindow:layout()
    local width, height = self:GetSize()
    local layout = self:_get_layout_numbers()
    local margin_left = layout.margin_left
    local margin_top = layout.margin_top
    local margin_right = layout.margin_right
    local margin_bottom = layout.margin_bottom
    local bar_h = layout.bar_h
    local filter_h = layout.filter_h
    local summary_h = layout.summary_h
    local page_h = layout.page_h
    local hint_h = layout.hint_h
    local gap = layout.gap
    local nav_w = _scaled_int(BASE_NAV_W)
    local page_w = _scaled_int(BASE_PAGE_W)
    local order_label_w = _scaled_int(BASE_ORDER_LABEL_W)
    local group_label_w = _scaled_int(BASE_GROUP_LABEL_W)
    local sort_w = _scaled_int(BASE_SORT_W)
    local group_w = _scaled_int(BASE_GROUP_W)
    local clear_w = _scaled_int(BASE_CLEAR_W)
    local stack_cb_w = _scaled_int(BASE_STACK_CB_W)
    local stack_box_w = math.max(_scaled_int(BASE_STACK_BOX_W), hint_h)
    local owner_label_w = _scaled_int(BASE_OWNER_LABEL_W)
    local owner_w = _scaled_int(BASE_OWNER_W)
    local storage_label_w = _scaled_int(BASE_STORAGE_LABEL_W)
    local storage_w = _scaled_int(BASE_STORAGE_W)
    local view_icon_w = _scaled_int(BASE_VIEW_ICON_W)

    local inner_w = width - margin_left - margin_right
    if inner_w < 0 then inner_w = 0 end

    self.nav_bar:SetPosition(margin_left, margin_top)
    self.nav_bar:SetSize(inner_w, bar_h)

    local nav_full_w = owner_label_w + owner_w + storage_label_w + storage_w + order_label_w + sort_w +
        group_label_w + group_w + (view_icon_w * 2) + (gap * 9)
    local show_nav_labels = inner_w >= nav_full_w

    self.owner_label:SetVisible(show_nav_labels)
    self.storage_label:SetVisible(show_nav_labels)
    self.order_label:SetVisible(show_nav_labels)
    self.group_label:SetVisible(show_nav_labels)

    local owner_left_x = 0
    if show_nav_labels == true then
        self.owner_label:SetPosition(0, 0)
        self.owner_label:SetSize(owner_label_w, bar_h)
        owner_left_x = owner_label_w + gap
    else
        self.owner_label:SetPosition(0, 0)
        self.owner_label:SetSize(0, bar_h)
    end

    local nav_right_x = inner_w

    local view_icon_y = math.floor((bar_h - view_icon_w) / 2)
    if view_icon_y < 0 then
        view_icon_y = 0
    end

    self.view_details_button:SetSize(view_icon_w, view_icon_w)
    nav_right_x = nav_right_x - view_icon_w
    self.view_details_button:SetPosition(nav_right_x, view_icon_y)
    nav_right_x = nav_right_x - gap

    self.view_icons_button:SetSize(view_icon_w, view_icon_w)
    nav_right_x = nav_right_x - view_icon_w
    self.view_icons_button:SetPosition(nav_right_x, view_icon_y)
    nav_right_x = nav_right_x - gap

    self.group_dropdown:SetSize(group_w, bar_h)
    nav_right_x = nav_right_x - group_w
    self.group_dropdown:SetPosition(nav_right_x, 0)
    if show_nav_labels == true then
        nav_right_x = nav_right_x - gap
        self.group_label:SetPosition(nav_right_x - group_label_w, 0)
        self.group_label:SetSize(group_label_w, bar_h)
        nav_right_x = nav_right_x - group_label_w
    else
        self.group_label:SetPosition(nav_right_x, 0)
        self.group_label:SetSize(0, bar_h)
    end

    nav_right_x = nav_right_x - gap
    self.sort_dropdown:SetSize(sort_w, bar_h)
    nav_right_x = nav_right_x - sort_w
    self.sort_dropdown:SetPosition(nav_right_x, 0)
    if show_nav_labels == true then
        nav_right_x = nav_right_x - gap
        self.order_label:SetPosition(nav_right_x - order_label_w, 0)
        self.order_label:SetSize(order_label_w, bar_h)
        nav_right_x = nav_right_x - order_label_w
    else
        self.order_label:SetPosition(nav_right_x, 0)
        self.order_label:SetSize(0, bar_h)
    end

    nav_right_x = nav_right_x - gap
    self.storage_dropdown:SetSize(storage_w, bar_h)
    nav_right_x = nav_right_x - storage_w
    self.storage_dropdown:SetPosition(nav_right_x, 0)
    if show_nav_labels == true then
        nav_right_x = nav_right_x - gap
        self.storage_label:SetPosition(nav_right_x - storage_label_w, 0)
        self.storage_label:SetSize(storage_label_w, bar_h)
        nav_right_x = nav_right_x - storage_label_w
    else
        self.storage_label:SetPosition(nav_right_x, 0)
        self.storage_label:SetSize(0, bar_h)
    end

    local owner_dropdown_w = owner_w
    local owner_max_w = nav_right_x - gap - owner_left_x
    if owner_max_w < owner_dropdown_w then
        owner_dropdown_w = owner_max_w
    end
    if owner_dropdown_w < 0 then
        owner_dropdown_w = 0
    end
    self.owner_dropdown:SetPosition(owner_left_x, 0)
    self.owner_dropdown:SetSize(owner_dropdown_w, bar_h)

    local filter_top = margin_top + bar_h + gap
    self.filter_bar:SetPosition(margin_left, filter_top)
    self.filter_bar:SetSize(inner_w, filter_h)

    self.clear_button:SetPosition(math.max(0, inner_w - clear_w), 0)
    self.clear_button:SetSize(math.min(clear_w, inner_w), filter_h)
    local filter_w = inner_w - clear_w - gap
    if filter_w < 0 then
        filter_w = 0
    end
    self.filter_tb:SetPosition(0, 0)
    self.filter_tb:SetSize(filter_w, filter_h)

    local summary_top = filter_top + filter_h + gap
    self.summary_bar:SetPosition(margin_left, summary_top)
    self.summary_bar:SetSize(inner_w, summary_h)

    local summary_track_w = math.floor((width * SUMMARY_TRACK_WIDTH_FACTOR) + 0.5)
    if summary_track_w > inner_w then
        summary_track_w = inner_w
    end
    if summary_track_w < 0 then
        summary_track_w = 0
    end

    local summary_track_h = summary_h - 2
    if summary_track_h < 1 then
        summary_track_h = 1
    end

    local summary_track_x = math.floor((inner_w - summary_track_w) / 2)
    if summary_track_x < 0 then
        summary_track_x = 0
    end
    local summary_track_y = math.floor((summary_h - summary_track_h) / 2)
    self.summary_track:SetPosition(summary_track_x, summary_track_y)
    self.summary_track:SetSize(summary_track_w, summary_track_h)
    self.summary_text:SetPosition(0, 0)
    self.summary_text:SetSize(summary_track_w, summary_track_h)

    local summary_inner_w = summary_track_w - 2
    local summary_inner_h = summary_track_h - 2
    if summary_inner_w < 0 then
        summary_inner_w = 0
    end
    if summary_inner_h < 0 then
        summary_inner_h = 0
    end
    self.summary_track_inner:SetPosition(summary_track_w > 1 and 1 or 0, summary_track_h > 1 and 1 or 0)
    self.summary_track_inner:SetSize(summary_inner_w, summary_inner_h)

    local hint_top = height - margin_bottom - hint_h
    local stack_toggle_w = stack_cb_w
    if stack_toggle_w > inner_w then
        stack_toggle_w = inner_w
    end
    if stack_toggle_w < 0 then
        stack_toggle_w = 0
    end
    local stack_toggle_x = margin_left + inner_w - stack_toggle_w
    if stack_toggle_x < margin_left then
        stack_toggle_x = margin_left
    end
    self.stack_items_toggle:SetPosition(stack_toggle_x, hint_top)
    self.stack_items_toggle:SetSize(stack_toggle_w, hint_h)

    local stack_box_h = hint_h
    local stack_box_x = stack_toggle_w - stack_box_w
    if stack_box_x < 0 then
        stack_box_x = 0
    end
    self.stack_items_cb:SetPosition(stack_box_x, 0)
    self.stack_items_cb:SetSize(math.min(stack_box_w, stack_toggle_w), stack_box_h)

    local stack_label_w = stack_box_x - gap
    if stack_label_w < 0 then
        stack_label_w = 0
    end
    self.stack_items_label:SetPosition(0, 0)
    self.stack_items_label:SetSize(stack_label_w, hint_h)

    local hint_w = inner_w - stack_toggle_w - gap
    if hint_w < 0 then
        hint_w = 0
    end
    self.hint_label:SetPosition(margin_left, hint_top)
    self.hint_label:SetSize(hint_w, hint_h)

    local page_top = hint_top - gap - page_h
    self.page_bar:SetPosition(margin_left, page_top)
    self.page_bar:SetSize(inner_w, page_h)

    local pager_w = (nav_w * 2) + page_w + (gap * 2)
    local pager_x = math.floor((inner_w - pager_w) / 2)
    if pager_x < 0 then
        pager_x = 0
    end

    self.prev_button:SetPosition(pager_x, 0)
    self.prev_button:SetSize(nav_w, page_h)

    self.page_label:SetPosition(pager_x + nav_w + gap, 0)
    self.page_label:SetSize(page_w, page_h)

    self.next_button:SetPosition(pager_x + nav_w + gap + page_w + gap, 0)
    self.next_button:SetSize(nav_w, page_h)

    local content_top = summary_top + summary_h + gap
    local content_h = page_top - gap - content_top
    if content_h < 0 then content_h = 0 end

    self.content:SetPosition(margin_left, content_top)
    self.content:SetSize(inner_w, content_h)

    self.empty_label:SetPosition(0, math.max(0, math.floor((content_h - bar_h) / 2)))
    self.empty_label:SetSize(inner_w, bar_h)

    self:refresh_page()
end

function AssetsWindow:refresh_from_store(force)
    local generation = ASSETS_STORE ~= nil and ASSETS_STORE.generation or 0
    if force ~= true and generation == self._last_generation then
        return
    end

    self._last_generation = generation
    if ASSETS_STORE ~= nil and ASSETS_STORE.get_entries ~= nil then
        self.all_records = ASSETS_STORE:get_entries()
    else
        self.all_records = {}
    end

    for i = 1, #self.all_records do
        local record = self.all_records[i]
        record.haystack_lower = _build_filter_text(record)
    end

    self:_refresh_owner_options()
    self:_apply_record_view(force == true and #self.records == 0)
end

function AssetsWindow:refresh_page()
    local metrics = self:_get_content_metrics()
    self.page_size = metrics.page_size
    self.page_count = math.max(1, math.ceil(#self.records / self.page_size))
    if self.page_index > self.page_count then
        self.page_index = self.page_count
    end
    if self.page_index < 1 then
        self.page_index = 1
    end

    self:_ensure_entries(self.page_size)

    local start_index = ((self.page_index - 1) * self.page_size) + 1
    local page_start_index = start_index - 1
    local visible_count = #self.records - start_index + 1
    if visible_count < 0 then
        visible_count = 0
    end
    if visible_count > self.page_size then
        visible_count = self.page_size
    end

    for i = 1, #self.entries do
        local entry = self.entries[i]
        if i <= self.page_size then
            local row = math.floor((i - 1) / metrics.cols)
            local col = (i - 1) % metrics.cols
            entry:SetPosition(col * (metrics.cell_w + metrics.gap), row * (metrics.cell_h + metrics.gap))
            entry:SetSize(metrics.cell_w, metrics.cell_h)
            entry:apply_view(self.view_mode, self.tile_size)
            entry:bind(self.records[start_index + i - 1])
        else
            entry:bind(nil)
        end
    end

    self.empty_label:SetVisible(#self.records == 0)
    self.page_label:SetText(tostring(self.page_index) .. " / " .. tostring(self.page_count))
    self.prev_button:set_enabled(self.page_index > 1)
    self.next_button:set_enabled(self.page_index < self.page_count)
    self:_refresh_summary(visible_count, page_start_index)

    self:_set_hint(nil)
end
