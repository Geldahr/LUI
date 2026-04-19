import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"

Crafting = Crafting or {}

local FILTER_ALL = "__all"
local AVAILABILITY_ALL = "all"
local AVAILABILITY_READY = "ready"
local AVAILABILITY_MISSING = "missing"
local DISPLAY_PAGES = "pages"
local DISPLAY_SCROLL = "scroll"

local BASE_MARGIN_LEFT = 15
local BASE_MARGIN_TOP = 11
local BASE_MARGIN_RIGHT = 15
local BASE_MARGIN_BOTTOM = 15
local BASE_GAP = 6
local BASE_BAR_H = 21
local BASE_CLEAR_W = 56
local BASE_MIN_W = 940
local BASE_MIN_H = 620
local BASE_RIGHT_W = 340
local BASE_RECIPE_ROW_H = 46
local BASE_INGREDIENT_ROW_H = 38
local BASE_PLAN_ROW_H = 38
local BASE_CRITICAL_RESULT_ROW_H = 34
local BASE_TITLE_FONT = 14
local BASE_BODY_FONT = 11
local BASE_META_FONT = 10
local BASE_BUTTON_FONT = 10
local BASE_ICON_SIDE = 32
local BASE_SCROLL_W = 10
local BASE_PAGE_LABEL_W = 52
local BASE_PANEL_BORDER = 1
local BASE_DETAIL_HEADER_H = 78
local BASE_PLAN_HEADER_H = 24
local BASE_PLAN_CONTROLS_W = 72
local BASE_SMALL_BUTTON_W = 22
local BASE_STATUS_W = 120
local BASE_PLAN_STATUS_W = 48
local BASE_TREE_INDENT_W = 16
local BASE_LEVEL_LABEL_W = 40
local BASE_LEVEL_BOX_W = 44
local BASE_LEVEL_DASH_W = 14
local BASE_LOADING_PANEL_H = 34
local BASE_LOADING_TRACK_H = 10
local BASE_SECTION_SPLIT_H = 2
local BASE_SOURCE_HINT_W = 94
local BASE_SOURCE_TOOLTIP_W = 214
local BASE_SOURCE_TOOLTIP_MIN_H = 44
local BASE_SOURCE_TOOLTIP_MAX_H = 132
local BASE_SOURCE_TOOLTIP_PAD_X = 12
local BASE_SOURCE_TOOLTIP_PAD_Y = 9
local BASE_SOURCE_TOOLTIP_LINE_H = 12
local ITEM_INFO_CONTROL_OFFSET = -3
local ITEM_INFO_CONTROL_EXTRA = 3

local PANEL_BACK = Turbine.UI.Color(1.00, 0.07, 0.08, 0.10)
local PANEL_BORDER = Turbine.UI.Color(1.00, 0.19, 0.22, 0.28)
local SECTION_BACK = Turbine.UI.Color(1.00, 0.09, 0.11, 0.13)
local SECTION_HEADER_BACK = Turbine.UI.Color(1.00, 0.13, 0.16, 0.20)
local SELECTED_BACK = Turbine.UI.Color(1.00, 0.15, 0.22, 0.32)
local HOVER_BACK = Turbine.UI.Color(1.00, 0.12, 0.14, 0.18)
local TEXT_MAIN = Turbine.UI.Color(1.00, 0.92, 0.95, 0.98)
local TEXT_META = Turbine.UI.Color(1.00, 0.64, 0.70, 0.78)
local STATUS_READY = Turbine.UI.Color(1.00, 0.31, 0.78, 0.43)
local STATUS_MISSING = Turbine.UI.Color(1.00, 0.86, 0.30, 0.30)
local STATUS_AUTO = Turbine.UI.Color(1.00, 0.35, 0.75, 0.90)
local SOURCE_BACKPACK_COLOR = Turbine.UI.Color(1.00, 0.43, 0.88, 0.43)
local SOURCE_BANK_COLOR = Turbine.UI.Color(1.00, 0.94, 0.78, 0.28)
local SOURCE_VAULT_COLOR = Turbine.UI.Color(1.00, 0.42, 0.78, 0.96)
local SOURCE_SHARED_COLOR = Turbine.UI.Color(1.00, 0.98, 0.62, 0.32)
local SOURCE_OTHER_COLOR = Turbine.UI.Color(1.00, 0.78, 0.62, 0.98)

local SOURCE_HINT_COLORS = {
    backpack = SOURCE_BACKPACK_COLOR,
    bank = SOURCE_BANK_COLOR,
    vault = SOURCE_VAULT_COLOR,
    shared_storage = SOURCE_SHARED_COLOR,
    other_characters = SOURCE_OTHER_COLOR,
}

local FAVORITE_SCALE_BREAKPOINT = 1.5
local FAVORITE_ICON_SMALL = 24
local FAVORITE_ICON_LARGE = 48
local FAVORITE_STAR_24 = "LUI/assets/ui/star_24.tga"
local FAVORITE_STAR_48 = "LUI/assets/ui/star_48.tga"
local FAVORITE_STAR_GRAY_24 = "LUI/assets/ui/star_gray_24.tga"
local FAVORITE_STAR_GRAY_48 = "LUI/assets/ui/star_gray_48.tga"
local FAVORITE_STAR_HOVER_24 = "LUI/assets/ui/star_hover_24.tga"
local FAVORITE_STAR_HOVER_48 = "LUI/assets/ui/star_hover_48.tga"

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, size * _G.settings.global.scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size))
    end
    return font
end

local function _favorite_icon_size()
    local scale = _G.settings ~= nil and _G.settings.global ~= nil and tonumber(_G.settings.global.scale) or 1
    return scale > FAVORITE_SCALE_BREAKPOINT and FAVORITE_ICON_LARGE or FAVORITE_ICON_SMALL
end

local function _favorite_icon_paths(favorite)
    local side = _favorite_icon_size()
    if side > FAVORITE_ICON_SMALL then
        return favorite == true and FAVORITE_STAR_48 or FAVORITE_STAR_GRAY_48, FAVORITE_STAR_HOVER_48,
            FAVORITE_STAR_GRAY_48, side
    end

    return favorite == true and FAVORITE_STAR_24 or FAVORITE_STAR_GRAY_24, FAVORITE_STAR_HOVER_24,
        FAVORITE_STAR_GRAY_24, side
end

local function _apply_favorite_icon(button, favorite)
    if button == nil then
        return
    end

    local normal, hover, disabled, side = _favorite_icon_paths(favorite)
    button:set_text("")
    button:set_icon(
        normal,
        hover,
        hover,
        disabled,
        side,
        side,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
    button:set_icon_stretch_mode(0)
    button:set_active(false)
end

local function _fixed_int(value)
    return math.floor(value + 0.5)
end

local function _safe_string(value, fallback)
    if value == nil then
        return fallback or ""
    end
    return tostring(value)
end

local function _trim(text)
    local value = _safe_string(text, "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function _lower(text)
    return string.lower(_safe_string(text, ""))
end

local function _push_query_term(group, term)
    if type(term) ~= "string" then
        return
    end
    local trimmed = _trim(term)
    if trimmed == "" then
        return
    end
    group[#group + 1] = trimmed
end

local function _end_query_group(groups, group)
    if type(group) ~= "table" or #group == 0 then
        return
    end
    groups[#groups + 1] = group
end

local function _parse_query(text)
    local query = _safe_string(text, "")
    local groups = {}
    local current_group = {}
    local index = 1
    local length = #query

    while index <= length do
        local char = query:sub(index, index)
        if char == "\"" then
            local end_index = index + 1
            while end_index <= length and query:sub(end_index, end_index) ~= "\"" do
                end_index = end_index + 1
            end
            _push_query_term(current_group, query:sub(index + 1, end_index - 1))
            index = (end_index <= length) and (end_index + 1) or (length + 1)
        elseif char == "|" then
            _end_query_group(groups, current_group)
            current_group = {}
            index = index + 1
        elseif char:match("%s") then
            index = index + 1
        else
            local end_index = index
            while end_index <= length do
                local next_char = query:sub(end_index, end_index)
                if next_char == "|" or next_char == "\"" or next_char:match("%s") then
                    break
                end
                end_index = end_index + 1
            end
            _push_query_term(current_group, query:sub(index, end_index - 1))
            index = end_index
        end
    end

    _end_query_group(groups, current_group)
    return groups
end

local function _normalize_query_groups(groups)
    if type(groups) ~= "table" or #groups == 0 then
        return {}
    end

    local normalized_groups = {}
    for group_index = 1, #groups do
        local group = groups[group_index]
        if type(group) == "table" and #group > 0 then
            local normalized_terms = {}
            for term_index = 1, #group do
                local term = group[term_index]
                if type(term) == "string" then
                    term = _lower(term)
                    if term ~= "" then
                        normalized_terms[#normalized_terms + 1] = term
                    end
                end
            end
            if #normalized_terms > 0 then
                normalized_groups[#normalized_groups + 1] = normalized_terms
            end
        end
    end

    return normalized_groups
end

local function _matches_query_groups(groups, haystack)
    if type(groups) ~= "table" or #groups == 0 then
        return true
    end

    local text = _lower(haystack)
    for group_index = 1, #groups do
        local group = groups[group_index]
        local matched = true
        for term_index = 1, #group do
            if string.find(text, group[term_index], 1, true) == nil then
                matched = false
                break
            end
        end
        if matched == true then
            return true
        end
    end

    return false
end

local function _saved_plan_entry_signature(entry)
    if type(entry) ~= "table" then
        return ""
    end
    return table.concat({
        tostring(entry.i or ""),
        tostring(entry.p or ""),
        tostring(entry.r or ""),
        tostring(entry.n or ""),
        tostring(entry.c or ""),
        tostring(entry.q or ""),
    }, "\31")
end

local function _option_list_signature(labels, values)
    local parts = {}
    local label_count = type(labels) == "table" and #labels or 0
    local value_count = type(values) == "table" and #values or 0
    local count = math.max(label_count, value_count)
    for i = 1, count do
        parts[#parts + 1] = table.concat({
            tostring(type(labels) == "table" and labels[i] or ""),
            tostring(type(values) == "table" and values[i] or ""),
        }, "\31")
    end
    return table.concat(parts, "\30")
end

local function _saved_plan_entries_equal(left, right)
    if type(left) ~= "table" then
        left = {}
    end
    if type(right) ~= "table" then
        right = {}
    end
    if #left ~= #right then
        return false
    end
    for i = 1, #left do
        if _saved_plan_entry_signature(left[i]) ~= _saved_plan_entry_signature(right[i]) then
            return false
        end
    end
    return true
end

local function _favorite_entry_key(entry)
    if type(entry) ~= "table" then
        return ""
    end

    local result_key = entry.r
    return table.concat({
        tostring(entry.p or ""),
        tostring(result_key or ""),
        tostring(entry.n or result_key or ""),
        tostring(entry.c or ""),
    }, "\31")
end

local function _display_name_from_saved_entry(saved_entry)
    if type(saved_entry) ~= "table" then
        return ""
    end

    local key = _trim(saved_entry.r or "")
    if key == "" then
        return ""
    end

    local out = {}
    for token in string.gmatch(key, "[^%s]+") do
        local lower = string.lower(token)
        out[#out + 1] = string.upper(string.sub(lower, 1, 1)) .. string.sub(lower, 2)
    end
    return table.concat(out, " ")
end

local function _format_count(value)
    local number = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
    return tostring(number)
end

local function _ratio_text(current, total)
    return _format_count(current) .. "/" .. _format_count(total)
end

local function _source_hint_color(source_key)
    return SOURCE_HINT_COLORS[source_key] or TEXT_META
end

local function _format_percent(value)
    local percent = tonumber(value)
    if percent == nil then
        return nil
    end
    if percent > 0 and percent <= 1 then
        percent = percent * 100
    end
    return _format_count(percent) .. "%"
end

local function _normalize_availability_filter(value)
    if value == AVAILABILITY_READY then
        return AVAILABILITY_READY
    end
    return AVAILABILITY_ALL
end

local function _normalize_display_mode(value)
    if value == DISPLAY_SCROLL then
        return DISPLAY_SCROLL
    end
    return DISPLAY_PAGES
end

local function _top_level_progress(evaluation)
    if type(evaluation) ~= "table" or type(evaluation.ingredients) ~= "table" then
        return 0, 0
    end

    local ready = 0
    local total = #evaluation.ingredients
    for index = 1, total do
        local ingredient = evaluation.ingredients[index]
        if type(ingredient) == "table" and ingredient.satisfied == true then
            ready = ready + 1
        end
    end

    return ready, total
end

local function _parse_level_value(text)
    local value = tonumber(_trim(text))
    if value == nil then
        return nil
    end
    value = math.floor(value)
    if value < 1 then
        return nil
    end
    return value
end

local function _set_control_border(control, border, fill)
    if control == nil then
        return
    end
    control:SetBackColor(border)
    control.inner = control.inner or Turbine.UI.Control()
    control.inner:SetParent(control)
    control._inner_inset = BASE_PANEL_BORDER
    control.inner:SetPosition(control._inner_inset, control._inner_inset)
    control.inner:SetBackColor(fill)
end

local function _fit_inner_border(control)
    if control == nil or control.inner == nil then
        return
    end
    local width, height = control:GetSize()
    local inset = math.max(0, math.floor((tonumber(control._inner_inset) or BASE_PANEL_BORDER) + 0.5))
    control.inner:SetSize(
        math.max(0, width - (inset * 2)),
        math.max(0, height - (inset * 2))
    )
end

local function _set_control_fill(control, fill)
    if control == nil then
        return
    end
    control:SetBackColor(fill)
    control.inner = control.inner or Turbine.UI.Control()
    control.inner:SetParent(control)
    control._inner_inset = 0
    control.inner:SetPosition(0, 0)
    control.inner:SetBackColor(fill)
end

local function _destroy_control(control)
    if control == nil then
        return
    end
    if control.destroy ~= nil then
        control:destroy()
        return
    end
    if control.SetVisible ~= nil then
        control:SetVisible(false)
    end
    if control.SetParent ~= nil then
        control:SetParent(nil)
    end
end

local function _clear_list_box(list)
    if list == nil then
        return
    end
    if list.GetItemCount ~= nil and list.GetItem ~= nil then
        for i = 1, list:GetItemCount() do
            local item = list:GetItem(i)
            if item ~= nil and item.prepare_for_list_clear ~= nil then
                item:prepare_for_list_clear()
            elseif item ~= nil and item.SetVisible ~= nil then
                item:SetVisible(false)
            end
        end
    end
    list:ClearItems()
end

local function _set_stretch_mode_zero(control)
    if control ~= nil and control.SetStretchMode ~= nil then
        control:SetStretchMode(0)
    end
end

local CraftingItemIcon = class(Turbine.UI.Control)

function CraftingItemIcon:Constructor(on_click, on_hover_change)
    Turbine.UI.Control.Constructor(self)

    self._on_click = on_click
    self._on_hover_change = on_hover_change
    self._side = _fixed_int(BASE_ICON_SIDE)

    self:SetMouseVisible(true)

    self.background = Image()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    _set_stretch_mode_zero(self.background)

    self.foreground = Image()
    self.foreground:SetParent(self)
    self.foreground:SetMouseVisible(false)
    _set_stretch_mode_zero(self.foreground)

    self.item_info_control = Turbine.UI.Lotro.ItemInfoControl()
    self.item_info_control:SetParent(self)
    self.item_info_control:SetMouseVisible(false)
    self.item_info_control:SetVisible(false)
    if self.item_info_control.SetBlendMode ~= nil then
        self.item_info_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    if self.item_info_control.SetStretchMode ~= nil then
        self.item_info_control:SetStretchMode(0)
    end

    local function forward_hover(hovering)
        if type(self._on_hover_change) == "function" then
            self._on_hover_change(hovering == true)
        end
    end

    local function forward_click(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        if type(self._on_click) == "function" then
            self._on_click()
        end
    end

    self.MouseEnter = function()
        forward_hover(true)
    end
    self.MouseClick = forward_click
    self.item_info_control.MouseEnter = function()
        forward_hover(true)
    end
    self.item_info_control.MouseClick = forward_click

    self:set_side(self._side)
    self:bind_item(nil, nil, nil)
end

function CraftingItemIcon:set_side(side)
    side = math.max(0, _fixed_int(side or BASE_ICON_SIDE))
    self._side = side

    self:SetSize(side, side)
    self.background:SetPosition(0, 0)
    self.background:set_size(side, side)
    self.foreground:SetPosition(0, 0)
    self.foreground:set_size(side, side)
    self.item_info_control:SetPosition(ITEM_INFO_CONTROL_OFFSET, ITEM_INFO_CONTROL_OFFSET)
    self.item_info_control:SetSize(side + ITEM_INFO_CONTROL_EXTRA, side + ITEM_INFO_CONTROL_EXTRA)
end

function CraftingItemIcon:bind_item(item_info, icon_id, background_image_id)
    local has_visual = item_info ~= nil or icon_id ~= nil or background_image_id ~= nil
    local use_item_info = item_info ~= nil and self.item_info_control.SetItemInfo ~= nil
    self:SetVisible(has_visual)

    if use_item_info == true then
        self.background:set_icon(nil, self._side)
    else
        self.background:set_icon(background_image_id, self._side)
    end
    self.background:SetVisible(use_item_info ~= true and background_image_id ~= nil)
    _set_stretch_mode_zero(self.background)

    if use_item_info == true then
        self.foreground:set_icon(nil, self._side)
    else
        self.foreground:set_icon(icon_id, self._side)
    end
    self.foreground:SetVisible(use_item_info ~= true and icon_id ~= nil)
    _set_stretch_mode_zero(self.foreground)

    if self.item_info_control.SetItemInfo ~= nil then
        self.item_info_control:SetItemInfo(item_info)
    end
    self.item_info_control:SetVisible(use_item_info == true)
    self.item_info_control:SetMouseVisible(use_item_info == true)
    _set_stretch_mode_zero(self.item_info_control)
end

function CraftingItemIcon:destroy()
    self:bind_item(nil, nil, nil)
    self:SetVisible(false)
end

function CraftingItemIcon:prepare_for_list_clear()
    self:bind_item(nil, nil, nil)
    self:SetVisible(false)
end

local CraftingRecipeRow = class(Turbine.UI.Control)

function CraftingRecipeRow:Constructor(on_click, on_favorite_toggle)
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._selected = false
    self._hover = false
    self._favorite = false
    self._on_click = on_click
    self._on_favorite_toggle = on_favorite_toggle
    self.recipe = nil
    self.status = nil

    self:SetMouseVisible(true)
    self:SetBackColor(SECTION_BACK)

    self.status_strip = Turbine.UI.Control()
    self.status_strip:SetParent(self)
    self.status_strip:SetMouseVisible(false)

    local function select_recipe()
        if type(self._on_click) == "function" and self.recipe ~= nil then
            self._on_click(self.recipe)
        end
    end

    self.icon = CraftingItemIcon(
        function()
            select_recipe()
        end,
        function(hovering)
            self._hover = hovering == true
            self:_refresh_visual()
        end
    )
    self.icon:SetParent(self)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self)
    self.title:SetMouseVisible(false)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.title:SetForeColor(TEXT_MAIN)

    self.subtitle = UI.Widgets.LuiLabel()
    self.subtitle:SetParent(self)
    self.subtitle:SetMouseVisible(false)
    self.subtitle:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.subtitle:SetForeColor(TEXT_META)

    self.status_label = UI.Widgets.LuiLabel()
    self.status_label:SetParent(self)
    self.status_label:SetMouseVisible(false)
    self.status_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.favorite_button = UI.Widgets.LuiButton()
    self.favorite_button:SetParent(self)
    self.favorite_button:set_padding(0)
    self.favorite_button:set_scale(1)
    UI.Widgets.Style.apply_transparent_button(self.favorite_button)
    _apply_favorite_icon(self.favorite_button, false)
    self.favorite_button.Click = function()
        if self.recipe ~= nil and type(self._on_favorite_toggle) == "function" then
            self._on_favorite_toggle(self.recipe)
        end
    end

    self.MouseEnter = function()
        self._hover = true
        self:_refresh_visual()
    end
    self.MouseLeave = function()
        self._hover = false
        self:_refresh_visual()
    end
    self.MouseClick = function(_, args)
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
            return
        end
        select_recipe()
    end
end

function CraftingRecipeRow:set_scale(scale)
    self._scale = scale
    self.title:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.subtitle:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.status_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.favorite_button:set_scale(1)
    _apply_favorite_icon(self.favorite_button, self._favorite)
end

function CraftingRecipeRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_RECIPE_ROW_H))
    self:_layout()
end

function CraftingRecipeRow:set_selected(selected)
    self._selected = selected == true
    self:_refresh_visual()
end

function CraftingRecipeRow:set_favorite(favorite)
    self._favorite = favorite == true
    _apply_favorite_icon(self.favorite_button, self._favorite)
end

function CraftingRecipeRow:set_data(recipe, status, result_item, required_level, favorite)
    self.recipe = recipe
    self.status = status

    local title = result_item ~= nil and result_item.name or ""
    local subtitle_parts = {}
    if recipe ~= nil and recipe.profession_name ~= "" then
        subtitle_parts[#subtitle_parts + 1] = recipe.profession_name
    end
    if required_level ~= nil then
        subtitle_parts[#subtitle_parts + 1] = TR["Level"] .. " " .. _format_count(required_level)
    end
    if recipe ~= nil and recipe.category_name ~= "" then
        subtitle_parts[#subtitle_parts + 1] = recipe.category_name
    end
    if recipe ~= nil and _trim(recipe.recipe_name or "") ~= "" and _lower(recipe.recipe_name) ~= _lower(title) then
        subtitle_parts[#subtitle_parts + 1] = recipe.recipe_name
    end

    self.title:SetText(title)
    self.subtitle:SetText(table.concat(subtitle_parts, " - "))
    self.status_label:SetText(CraftingWindow._recipe_status_text(nil, status))
    self.status_label:SetForeColor(CraftingWindow._status_color(nil, status))

    if result_item ~= nil then
        self.icon:bind_item(result_item.item_info, result_item.icon_id, result_item.background_image_id)
    else
        self.icon:bind_item(nil, nil, nil)
    end

    self:set_favorite(favorite)
    self:_refresh_visual()
end

function CraftingRecipeRow:_refresh_visual()
    if self._selected == true then
        self:SetBackColor(SELECTED_BACK)
    elseif self._hover == true then
        self:SetBackColor(HOVER_BACK)
    else
        self:SetBackColor(SECTION_BACK)
    end

    self.status_strip:SetBackColor(CraftingWindow._status_color(nil, self.status))
end

function CraftingRecipeRow:_layout()
    local width, height = self:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local strip_w = _scaled_int(4)
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local max_icon_side = height - (gap * 2)
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    if icon_side < 0 then
        icon_side = 0
    end
    local status_w = _scaled_int(BASE_STATUS_W)
    local favorite_w = _favorite_icon_size()
    local text_left = strip_w + gap + icon_side + gap
    local status_x = width - status_w - gap
    local favorite_x = status_x - gap - favorite_w
    local text_w = favorite_x - text_left - gap
    local title_h = math.floor(height * 0.55)
    local subtitle_h = height - title_h

    self.status_strip:SetPosition(0, 0)
    self.status_strip:SetSize(strip_w, height)

    self.icon:SetPosition(strip_w + gap, math.max(0, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)

    self.title:SetPosition(text_left, 0)
    self.title:SetSize(math.max(0, text_w), title_h)
    self.subtitle:SetPosition(text_left, title_h)
    self.subtitle:SetSize(math.max(0, text_w), subtitle_h)

    self.favorite_button:SetPosition(favorite_x, math.max(0, math.floor((height - favorite_w) / 2)))
    self.favorite_button:SetSize(favorite_w, favorite_w)

    self.status_label:SetPosition(status_x, 0)
    self.status_label:SetSize(status_w, height)
end

function CraftingRecipeRow:destroy()
    _destroy_control(self.icon)
    _destroy_control(self.favorite_button)
    self:SetVisible(false)
end

function CraftingRecipeRow:prepare_for_list_clear()
    if self.icon ~= nil and self.icon.prepare_for_list_clear ~= nil then
        self.icon:prepare_for_list_clear()
    end
    self:SetVisible(false)
end

local CraftingIngredientRow = class(Turbine.UI.Control)

function CraftingIngredientRow:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(true)
    self._scale = 1
    self._indent_level = 0
    self._detail_text = ""
    self._source_hint_text = ""
    self._source_hint_color = TEXT_META
    self._source_breakdown = nil
    self._show_source_breakdown = nil
    self._hide_source_breakdown = nil

    self.status_strip = Turbine.UI.Control()
    self.status_strip:SetParent(self)
    self.status_strip:SetMouseVisible(false)

    self.icon = CraftingItemIcon()
    self.icon:SetParent(self)

    self.name = UI.Widgets.LuiLabel()
    self.name:SetParent(self)
    self.name:SetMouseVisible(false)
    self.name:SetForeColor(TEXT_MAIN)
    self.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.detail = UI.Widgets.LuiLabel()
    self.detail:SetParent(self)
    self.detail:SetMouseVisible(false)
    self.detail:SetForeColor(TEXT_META)
    self.detail:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.source_hint = UI.Widgets.LuiLabel()
    self.source_hint:SetParent(self)
    self.source_hint:SetMouseVisible(true)
    self.source_hint:SetForeColor(TEXT_META)
    self.source_hint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.source_hint:SetMultiline(false)
    self.source_hint:SetVisible(false)

    self.amount = UI.Widgets.LuiLabel()
    self.amount:SetParent(self)
    self.amount:SetMouseVisible(true)
    self.amount:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    local function show_source_breakdown(anchor_control)
        if self._source_breakdown ~= nil and type(self._show_source_breakdown) == "function" then
            self._show_source_breakdown(anchor_control, self._source_breakdown)
        end
    end

    local function hide_source_breakdown()
        if type(self._hide_source_breakdown) == "function" then
            self._hide_source_breakdown()
        end
    end

    self.source_hint.MouseEnter = function()
        show_source_breakdown(self.source_hint)
    end
    self.source_hint.MouseLeave = hide_source_breakdown
    self.amount.MouseEnter = function()
        show_source_breakdown(self.amount)
    end
    self.amount.MouseLeave = hide_source_breakdown
end

function CraftingIngredientRow:set_scale(scale)
    self._scale = scale
    self.name:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.detail:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.source_hint:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.amount:SetFont(_scaled_font("Verdana", BASE_META_FONT))
end

function CraftingIngredientRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_INGREDIENT_ROW_H))
    self:_layout()
end

function CraftingIngredientRow:set_data(item_info, icon_id, background_image_id, label_text, detail_text, amount_text, color, indent_level, source_hint_text, source_hint_color)
    self._indent_level = math.max(0, math.floor((tonumber(indent_level) or 0) + 0.5))
    self._detail_text = detail_text or ""
    self._source_hint_text = source_hint_text or ""
    self._source_hint_color = source_hint_color or TEXT_META
    self.icon:bind_item(item_info, icon_id, background_image_id)
    self.name:SetText(label_text or "")
    self.detail:SetText(self._detail_text)
    self.source_hint:SetText(self._source_hint_text)
    self.source_hint:SetForeColor(self._source_hint_color)
    self.amount:SetText(amount_text or "")
    self.amount:SetForeColor(color or TEXT_META)
    self.status_strip:SetBackColor(color or TEXT_META)
    self:SetBackColor(SECTION_BACK)
    self:_layout()
end

function CraftingIngredientRow:set_source_breakdown(breakdown, show_callback, hide_callback)
    self._source_breakdown = breakdown
    self._show_source_breakdown = show_callback
    self._hide_source_breakdown = hide_callback
end

function CraftingIngredientRow:_layout()
    local width, height = self:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local strip_w = _scaled_int(3)
    local amount_w = _scaled_int(86)
    local indent_w = _scaled_int(BASE_TREE_INDENT_W) * self._indent_level
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local icon_pad = _scaled_int(1)
    local max_icon_side = height - (icon_pad * 2)
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    if icon_side < 0 then
        icon_side = 0
    end
    local left = strip_w + gap + indent_w + icon_side + gap
    local text_w = width - left - gap - amount_w
    local title_h = math.floor(height * 0.55)
    local source_hint_visible = type(self._source_hint_text) == "string" and string.len(self._source_hint_text) > 0 and
        text_w >= _scaled_int(128)
    local source_hint_w = 0
    local detail_w = text_w
    local has_detail_text = type(self._detail_text) == "string" and string.len(self._detail_text) > 0
    if source_hint_visible == true then
        if has_detail_text == true then
            source_hint_w = math.min(_scaled_int(BASE_SOURCE_HINT_W), math.floor(text_w * 0.42))
            detail_w = math.max(0, text_w - source_hint_w - gap)
        else
            source_hint_w = text_w
            detail_w = 0
        end
    end

    self.status_strip:SetPosition(0, 0)
    self.status_strip:SetSize(strip_w, height)

    self.icon:SetPosition(strip_w + gap + indent_w, math.max(icon_pad, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)

    self.name:SetPosition(left, 0)
    self.name:SetSize(math.max(0, text_w), title_h)
    self.detail:SetPosition(left, title_h)
    self.detail:SetSize(math.max(0, detail_w), height - title_h)

    self.source_hint:SetVisible(source_hint_visible)
    if has_detail_text == true then
        self.source_hint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        self.source_hint:SetPosition(left + detail_w + gap, title_h)
    else
        self.source_hint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        self.source_hint:SetPosition(left, title_h)
    end
    self.source_hint:SetSize(math.max(0, source_hint_w), height - title_h)

    self.amount:SetPosition(width - amount_w - gap, 0)
    self.amount:SetSize(amount_w, height)
end

function CraftingIngredientRow:destroy()
    _destroy_control(self.icon)
    self._source_breakdown = nil
    self._show_source_breakdown = nil
    self._hide_source_breakdown = nil
    self:SetVisible(false)
end

function CraftingIngredientRow:prepare_for_list_clear()
    if self.icon ~= nil and self.icon.prepare_for_list_clear ~= nil then
        self.icon:prepare_for_list_clear()
    end
    self._source_breakdown = nil
    self._show_source_breakdown = nil
    self._hide_source_breakdown = nil
    self:SetVisible(false)
end

local CraftingResultInfoRow = class(Turbine.UI.Control)

function CraftingResultInfoRow:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._scale = 1

    self:SetBackColor(SECTION_BACK)
    self:SetMouseVisible(false)

    self.status_strip = Turbine.UI.Control()
    self.status_strip:SetParent(self)
    self.status_strip:SetMouseVisible(false)

    self.icon = CraftingItemIcon()
    self.icon:SetParent(self)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self)
    self.title:SetMouseVisible(false)
    self.title:SetForeColor(TEXT_MAIN)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.detail = UI.Widgets.LuiLabel()
    self.detail:SetParent(self)
    self.detail:SetMouseVisible(false)
    self.detail:SetForeColor(TEXT_META)
    self.detail:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
end

function CraftingResultInfoRow:set_scale(scale)
    self._scale = scale
    self.title:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.detail:SetFont(_scaled_font("Verdana", BASE_META_FONT))
end

function CraftingResultInfoRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_CRITICAL_RESULT_ROW_H))
    self:_layout()
end

function CraftingResultInfoRow:set_data(item_info, icon_id, background_image_id, title, detail, color)
    self.icon:bind_item(item_info, icon_id, background_image_id)
    self.title:SetText(title or "")
    self.detail:SetText(detail or "")
    self.status_strip:SetBackColor(color or TEXT_META)
    self:SetBackColor(SECTION_BACK)
    self:_layout()
end

function CraftingResultInfoRow:_layout()
    local width, height = self:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local strip_w = _scaled_int(3)
    local icon_pad = _scaled_int(1)
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local max_icon_side = height - (icon_pad * 2)
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    if icon_side < 0 then
        icon_side = 0
    end

    local text_left = strip_w + gap + icon_side + gap
    local text_w = width - text_left - gap
    local title_h = math.floor(height * 0.55)

    self.status_strip:SetPosition(0, 0)
    self.status_strip:SetSize(strip_w, height)
    self.icon:SetPosition(strip_w + gap, math.max(icon_pad, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)
    self.title:SetPosition(text_left, 0)
    self.title:SetSize(math.max(0, text_w), title_h)
    self.detail:SetPosition(text_left, title_h)
    self.detail:SetSize(math.max(0, text_w), height - title_h)
end

function CraftingResultInfoRow:destroy()
    _destroy_control(self.icon)
    self:SetVisible(false)
end

function CraftingResultInfoRow:prepare_for_list_clear()
    if self.icon ~= nil and self.icon.prepare_for_list_clear ~= nil then
        self.icon:prepare_for_list_clear()
    end
    self:SetVisible(false)
end

local CraftingPlanRow = class(Turbine.UI.Control)

function CraftingPlanRow:Constructor(on_count_changed, on_remove)
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._on_count_changed = on_count_changed
    self._on_remove = on_remove
    self.recipe = nil
    self._read_only = false

    self:SetBackColor(SECTION_BACK)

    self.icon = CraftingItemIcon()
    self.icon:SetParent(self)

    self.name = UI.Widgets.LuiLabel()
    self.name:SetParent(self)
    self.name:SetMouseVisible(false)
    self.name:SetForeColor(TEXT_MAIN)
    self.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.status_label = UI.Widgets.LuiLabel()
    self.status_label:SetParent(self)
    self.status_label:SetMouseVisible(false)
    self.status_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self.count_box = UI.Widgets.LuiSpinBox()
    self.count_box:SetParent(self)
    self.count_box:set_render(UI.Widgets.LuiSpinBox.render.PLUS_MINUS)
    self.count_box:set_minimum(0)
    self.count_box:set_step(1)
    self.count_box:set_decimals(0)
    self.count_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.count_box.ValueChanged = function(_, value)
        if self.recipe ~= nil and type(self._on_count_changed) == "function" then
            self._on_count_changed(self.recipe, value)
        end
    end

    self.remove_button = UI.Widgets.LuiButton()
    self.remove_button:SetParent(self)
    self.remove_button:set_text("x")
    self.remove_button.Click = function()
        if self.recipe ~= nil and type(self._on_remove) == "function" then
            self._on_remove(self.recipe)
        end
    end
end

function CraftingPlanRow:set_scale(scale)
    self._scale = scale
    self.name:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.status_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.count_box:set_scale(scale)
    self.count_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.remove_button:set_scale(scale)
    self.remove_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
end

function CraftingPlanRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_PLAN_ROW_H))
    self:_layout()
end

function CraftingPlanRow:set_read_only(read_only)
    self._read_only = read_only == true
    self:_layout()
end

function CraftingPlanRow:set_data(recipe, result_item, result_name, plan_count, evaluation, craftable_count)
    self.recipe = recipe
    if result_item ~= nil then
        self.icon:bind_item(result_item.item_info, result_item.icon_id, result_item.background_image_id)
    else
        self.icon:bind_item(nil, nil, nil)
    end
    self.name:SetText(result_name or "")
    self.count_box:set_value(plan_count, false)
    self.count_box:set_enabled(recipe ~= nil and self._read_only ~= true)
    self.count_box:SetVisible(self._read_only ~= true)
    self.remove_button:SetVisible(self._read_only ~= true)
    craftable_count = tonumber(craftable_count) or plan_count
    local plan_total = tonumber(plan_count) or 0
    local all_ready = craftable_count >= plan_total and plan_total > 0
    self.status_label:SetText(_ratio_text(craftable_count, plan_count))
    self.status_label:SetForeColor(all_ready == true and CraftingWindow._status_color(nil, evaluation) or STATUS_MISSING)
    self:SetBackColor(all_ready == true and Turbine.UI.Color(1.00, 0.09, 0.15, 0.11) or
        Turbine.UI.Color(1.00, 0.16, 0.09, 0.09))
end

function CraftingPlanRow:set_placeholder_data(label_text, plan_count, loading)
    self.recipe = nil
    self.icon:bind_item(nil, nil, nil)
    self.name:SetText(label_text or "")
    self.count_box:set_value(plan_count, false)
    self.count_box:set_enabled(false)
    self.count_box:SetVisible(false)
    self.remove_button:SetVisible(false)
    self.status_label:SetText(loading == true and "..." or "?")
    self.status_label:SetForeColor(TEXT_META)
    self:SetBackColor(Turbine.UI.Color(1.00, 0.12, 0.12, 0.12))
end

function CraftingPlanRow:_layout()
    local width, height = self:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local icon_pad = _scaled_int(1)
    local max_icon_side = height - (icon_pad * 2)
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    if icon_side < 0 then
        icon_side = 0
    end
    local button_w = _scaled_int(BASE_SMALL_BUTTON_W)
    local count_w = _scaled_int(BASE_PLAN_CONTROLS_W)
    local control_h = _scaled_int(BASE_BAR_H)
    local status_w = _scaled_int(BASE_PLAN_STATUS_W)
    local remove_w = button_w
    local right = width - gap
    local control_y = math.max(0, math.floor((height - control_h) / 2))

    if self._read_only == true then
        self.remove_button:SetVisible(false)
        self.count_box:SetVisible(false)
    else
        self.remove_button:SetVisible(true)
        self.remove_button:SetSize(remove_w, control_h)
        right = right - remove_w
        self.remove_button:SetPosition(right, control_y)

        right = right - gap
        self.count_box:SetVisible(true)
        self.count_box:SetPosition(right - count_w, control_y)
        self.count_box:SetSize(count_w, control_h)
        right = right - count_w
    end

    right = right - gap
    self.status_label:SetPosition(right - status_w, 0)
    self.status_label:SetSize(status_w, height)
    right = right - status_w

    self.icon:SetPosition(gap, math.max(icon_pad, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)

    local name_left = gap + icon_side + gap
    self.name:SetPosition(name_left, 0)
    self.name:SetSize(math.max(0, right - name_left - gap), height)
end

function CraftingPlanRow:destroy()
    _destroy_control(self.icon)
    _destroy_control(self.count_box)
    self:SetVisible(false)
end

function CraftingPlanRow:prepare_for_list_clear()
    if self.icon ~= nil and self.icon.prepare_for_list_clear ~= nil then
        self.icon:prepare_for_list_clear()
    end
    if self.count_box ~= nil and self.count_box.SetVisible ~= nil then
        self.count_box:SetVisible(false)
    end
    if self.remove_button ~= nil and self.remove_button.SetVisible ~= nil then
        self.remove_button:SetVisible(false)
    end
    self:SetVisible(false)
end

CraftingWindow = class(LuiWindow)
Crafting.CraftingWindow = CraftingWindow

function CraftingWindow:Constructor()
    LuiWindow.Constructor(self)

    self:set_title(TR["Crafting"])
    self:set_icon(UI.AssetIds.anvil_gold)
    self:set_resizable(true)
    self:hide()
    self:SetWantsUpdates(false)
    self:set_minimum_size(self:_minimum_window_size())

    self._suppress_size_changed = false
    self._last_update_at = 0
    self.update_every = 0.75
    self._loading_visible = false
    self.store = Crafting.get_shared_store()
    if self.store == nil then
        error("Crafting window requires enabled crafting store")
    end
    self._last_store_version = tonumber(self.store ~= nil and self.store.version or nil) or 0
    self.search_groups = {}
    self.scope_source_keys = self.store:get_default_source_keys()
    self.scope_key = self.store:scope_key_from_sources(self.scope_source_keys)
    self.profession_filter = FILTER_ALL
    self.availability_filter = AVAILABILITY_ALL
    self.favorite_filter_active = false
    self.favorite_entries = {}
    self.favorite_keys = {}
    self.display_mode = _normalize_display_mode(_G.LUI_CRAFTING_DISPLAY_MODE_ACTIVE)
    self.level_min_filter = nil
    self.level_max_filter = nil
    self.selected_recipe_id = nil
    self.visible_recipes = {}
    self.recipe_page_index = 1
    self.recipe_page_size = 1
    self.recipe_page_count = 1
    self.plan_order = {}
    self.plan_counts = {}
    self._plan_dirty = false
    self._plan_user_changed = false
    self._suppress_search_text_changed = false
    self._recipe_list_signature = nil
    self._recipe_list_loaded_count = 0
    self._recipe_list_loading = false
    self._recipe_list_row_width = 0
    self._recipe_list_page_size = 0
    self._recipe_page_rendered_start = 1
    self._recipe_page_rendered_end = 0
    self._profession_options_signature = nil
    self._store_loading = self.store:is_loading() == true
    self._selected_recipe_watch_keys = {}
    self._plan_recipe_watch_keys = {}
    self._critical_result_visible = false
    local content_host = self:get_content_host()

    self.top_bar = Turbine.UI.Control()
    self.top_bar:SetParent(content_host)

    self.search_box = UI.Widgets.LineEdit()
    self.search_box:SetParent(self.top_bar)
    self.search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.search_box:set_placeholder_text(TR["Search..."])
    self.search_box.TextChanged = function()
        if self._suppress_search_text_changed == true then
            return
        end
        self.search_groups = _normalize_query_groups(_parse_query(self.search_box:GetText()))
        self.recipe_page_index = 1
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
    end

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.top_bar)
    self.clear_button:set_text(TR["Clear"])
    self.clear_button.Click = function()
        self:_apply_search_query("")
        self.recipe_page_index = 1
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self.search_box:Focus()
    end

    self.favorite_filter_button = UI.Widgets.LuiButton()
    self.favorite_filter_button:SetParent(self.top_bar)
    self.favorite_filter_button:set_padding(0)
    self.favorite_filter_button:set_scale(1)
    UI.Widgets.Style.apply_transparent_button(self.favorite_filter_button)
    _apply_favorite_icon(self.favorite_filter_button, false)
    self.favorite_filter_button.Click = function()
        self:set_favorite_filter(self.favorite_filter_active ~= true)
    end

    self.scope_label = UI.Widgets.LuiLabel()
    self.scope_label:SetParent(self.top_bar)
    self.scope_label:SetMouseVisible(false)
    self.scope_label:SetForeColor(TEXT_META)
    self.scope_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.scope_label:SetText(TR["Materials"])

    self.scope_dropdown = UI.Widgets.LuiCheckDropdown()
    self.scope_dropdown:SetParent(self.top_bar)
    self.scope_dropdown:SetPopupHost(self)
    self.scope_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.scope_dropdown:SetSummaryFormatter(function(selected_values)
        return self:_scope_source_summary(selected_values)
    end)
    self.scope_dropdown.SelectedValuesChanged = function(_, values)
        self:set_scope_sources(values, true)
    end

    self.profession_label = UI.Widgets.LuiLabel()
    self.profession_label:SetParent(self.top_bar)
    self.profession_label:SetMouseVisible(false)
    self.profession_label:SetForeColor(TEXT_META)
    self.profession_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.profession_label:SetText(TR["Profession"])

    self.profession_dropdown = UI.Widgets.LuiDropdown()
    self.profession_dropdown:SetParent(self.top_bar)
    self.profession_dropdown:SetPopupHost(self)
    self.profession_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.profession_dropdown.ValueChanged = function(_, value)
        self.profession_filter = value or FILTER_ALL
        self.recipe_page_index = 1
        self:refresh_recipe_list()
    end

    self.availability_label = UI.Widgets.LuiLabel()
    self.availability_label:SetParent(self.top_bar)
    self.availability_label:SetMouseVisible(false)
    self.availability_label:SetForeColor(TEXT_META)
    self.availability_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.availability_label:SetText(TR["Show"])

    self.availability_dropdown = UI.Widgets.LuiDropdown()
    self.availability_dropdown:SetParent(self.top_bar)
    self.availability_dropdown:SetPopupHost(self)
    self.availability_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.availability_dropdown:SetMappedOptions(
        { TR["All"], TR["Craftable"] },
        { AVAILABILITY_ALL, AVAILABILITY_READY }
    )
    self.availability_dropdown.ValueChanged = function(_, value)
        self.availability_filter = _normalize_availability_filter(value)
        self.recipe_page_index = 1
        self:refresh_recipe_list()
    end

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self.top_bar)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetForeColor(TEXT_META)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.level_label:SetText(TR["Equip lvl"])

    self.level_min_box = UI.Widgets.LuiLineEdit()
    self.level_min_box:SetParent(self.top_bar)
    self.level_min_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_min_box.TextChanged = function()
        self:update_level_filter()
    end

    self.level_dash_label = UI.Widgets.LuiLabel()
    self.level_dash_label:SetParent(self.top_bar)
    self.level_dash_label:SetMouseVisible(false)
    self.level_dash_label:SetForeColor(TEXT_META)
    self.level_dash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_dash_label:SetText("-")

    self.level_max_box = UI.Widgets.LuiLineEdit()
    self.level_max_box:SetParent(self.top_bar)
    self.level_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_max_box.TextChanged = function()
        self:update_level_filter()
    end

    self.left_panel = Turbine.UI.Control()
    self.left_panel:SetParent(content_host)
    _set_control_border(self.left_panel, PANEL_BORDER, PANEL_BACK)

    self.recipe_list = Turbine.UI.ListBox()
    self.recipe_list:SetParent(self.left_panel.inner)
    self.recipe_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.recipe_scroll = Turbine.UI.Lotro.ScrollBar()
    self.recipe_scroll:SetParent(self.left_panel.inner)
    self.recipe_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.recipe_list:SetVerticalScrollBar(self.recipe_scroll)

    self.recipe_page_bar = Turbine.UI.Control()
    self.recipe_page_bar:SetParent(self.left_panel.inner)

    self.recipe_prev_button = UI.Widgets.LuiButton()
    self.recipe_prev_button:SetParent(self.recipe_page_bar)
    self.recipe_prev_button:set_text("")
    self.recipe_prev_button:set_padding(2)
    self.recipe_prev_button:set_icon(
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_white,
        UI.AssetIds.arrow_l_transparent,
        BASE_SMALL_BUTTON_W,
        nil,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
    self.recipe_prev_button.Click = function()
        self:set_recipe_page(self.recipe_page_index - 1)
    end

    self.recipe_page_label = UI.Widgets.LuiLabel()
    self.recipe_page_label:SetParent(self.recipe_page_bar)
    self.recipe_page_label:SetMouseVisible(false)
    self.recipe_page_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.recipe_next_button = UI.Widgets.LuiButton()
    self.recipe_next_button:SetParent(self.recipe_page_bar)
    self.recipe_next_button:set_text("")
    self.recipe_next_button:set_padding(2)
    self.recipe_next_button:set_icon(
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_transparent,
        BASE_SMALL_BUTTON_W,
        nil,
        UI.Widgets.LuiButton.icon_position.RIGHT
    )
    self.recipe_next_button.Click = function()
        self:set_recipe_page(self.recipe_page_index + 1)
    end

    self.recipe_empty = UI.Widgets.LuiLabel()
    self.recipe_empty:SetParent(self.left_panel.inner)
    self.recipe_empty:SetMouseVisible(false)
    self.recipe_empty:SetMultiline(true)
    self.recipe_empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.recipe_empty:SetForeColor(TEXT_META)
    self.recipe_empty:SetText(TR["No matching recipes."])

    self.right_panel = Turbine.UI.Control()
    self.right_panel:SetParent(content_host)
    self.right_panel:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.right_tab_bar = UI.Widgets.LuiTabBar()
    self.right_tab_bar:SetParent(self.right_panel)
    self.right_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.right_tab_bar:set_content_padding(0)
    self.right_tab_bar:set_show_content_border(true)
    self.right_tab_bar:set_fill_tabs(false)

    self.recipe_page = Turbine.UI.Control()

    self.plan_page = Turbine.UI.Control()

    self.right_tab_bar:add_tab(TR["Recipe"], self.recipe_page)
    self.right_tab_bar:add_tab(TR["Plan"], self.plan_page)
    self.right_tab_bar:select_tab(1)

    self.detail_panel = Turbine.UI.Control()
    self.detail_panel:SetParent(self.recipe_page)
    _set_control_fill(self.detail_panel, PANEL_BACK)

    self.recipe_split_border = Turbine.UI.Control()
    self.recipe_split_border:SetParent(self.recipe_page)
    self.recipe_split_border:SetMouseVisible(false)
    self.recipe_split_border:SetBackColor(PANEL_BORDER)

    self.detail_icon = CraftingItemIcon()
    self.detail_icon:SetParent(self.detail_panel.inner)

    self.detail_title = UI.Widgets.LuiLabel()
    self.detail_title:SetParent(self.detail_panel.inner)
    self.detail_title:SetMouseVisible(false)
    self.detail_title:SetForeColor(TEXT_MAIN)
    self.detail_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.detail_meta = UI.Widgets.LuiLabel()
    self.detail_meta:SetParent(self.detail_panel.inner)
    self.detail_meta:SetMouseVisible(false)
    self.detail_meta:SetForeColor(TEXT_META)
    self.detail_meta:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.detail_status = UI.Widgets.LuiLabel()
    self.detail_status:SetParent(self.detail_panel.inner)
    self.detail_status:SetMouseVisible(false)
    self.detail_status:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.critical_result_row = CraftingResultInfoRow()
    self.critical_result_row:SetParent(self.detail_panel.inner)
    self.critical_result_row:SetVisible(false)

    self.plan_label = UI.Widgets.LuiLabel()
    self.plan_label:SetParent(self.detail_panel.inner)
    self.plan_label:SetMouseVisible(false)
    self.plan_label:SetForeColor(TEXT_META)
    self.plan_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.plan_label:SetText(TR["Build plan"])

    self.plan_spin_box = UI.Widgets.LuiSpinBox()
    self.plan_spin_box:SetParent(self.detail_panel.inner)
    self.plan_spin_box:set_render(UI.Widgets.LuiSpinBox.render.PLUS_MINUS)
    self.plan_spin_box:set_minimum(0)
    self.plan_spin_box:set_step(1)
    self.plan_spin_box:set_decimals(0)
    self.plan_spin_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.plan_spin_box.ValueChanged = function(_, value)
        local recipe = self:_selected_recipe()
        if recipe ~= nil then
            self:set_plan_count(recipe.id, value)
        end
    end

    self.ingredients_title = UI.Widgets.LuiLabel()
    self.ingredients_title:SetParent(self.detail_panel.inner)
    self.ingredients_title:SetMouseVisible(false)
    self.ingredients_title:SetForeColor(TEXT_META)
    self.ingredients_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.ingredients_title:SetText(TR["Ingredients"])

    self.ingredients_header_bar = Turbine.UI.Control()
    self.ingredients_header_bar:SetParent(self.detail_panel.inner)
    self.ingredients_header_bar:SetMouseVisible(false)
    self.ingredients_header_bar:SetBackColor(SECTION_HEADER_BACK)
    self.ingredients_header_bar:SetZOrder(1)
    self.ingredients_title:SetZOrder(2)

    self.ingredients_list = Turbine.UI.ListBox()
    self.ingredients_list:SetParent(self.detail_panel.inner)
    self.ingredients_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.ingredients_scroll = Turbine.UI.Lotro.ScrollBar()
    self.ingredients_scroll:SetParent(self.detail_panel.inner)
    self.ingredients_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.ingredients_list:SetVerticalScrollBar(self.ingredients_scroll)

    self.detail_empty = UI.Widgets.LuiLabel()
    self.detail_empty:SetParent(self.detail_panel.inner)
    self.detail_empty:SetMouseVisible(false)
    self.detail_empty:SetMultiline(true)
    self.detail_empty:SetForeColor(TEXT_META)
    self.detail_empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.detail_empty:SetText(TR["Select a recipe to see the breakdown."])

    self.queue_panel = Turbine.UI.Control()
    self.queue_panel:SetParent(self.recipe_page)
    _set_control_fill(self.queue_panel, PANEL_BACK)

    self.queue_header_bar = Turbine.UI.Control()
    self.queue_header_bar:SetParent(self.queue_panel.inner)
    self.queue_header_bar:SetMouseVisible(false)
    self.queue_header_bar:SetBackColor(SECTION_HEADER_BACK)
    self.queue_header_bar:SetZOrder(1)

    self.queue_title = UI.Widgets.LuiLabel()
    self.queue_title:SetParent(self.queue_panel.inner)
    self.queue_title:SetMouseVisible(false)
    self.queue_title:SetForeColor(TEXT_META)
    self.queue_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.queue_title:SetText(TR["Plan queue"])

    self.queue_summary = UI.Widgets.LuiLabel()
    self.queue_summary:SetParent(self.queue_panel.inner)
    self.queue_summary:SetMouseVisible(false)
    self.queue_summary:SetForeColor(TEXT_MAIN)
    self.queue_summary:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.queue_title:SetZOrder(2)
    self.queue_summary:SetZOrder(2)

    self.queue_list = Turbine.UI.ListBox()
    self.queue_list:SetParent(self.queue_panel.inner)
    self.queue_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.queue_scroll = Turbine.UI.Lotro.ScrollBar()
    self.queue_scroll:SetParent(self.queue_panel.inner)
    self.queue_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.queue_list:SetVerticalScrollBar(self.queue_scroll)

    self.queue_empty = UI.Widgets.LuiLabel()
    self.queue_empty:SetParent(self.queue_panel.inner)
    self.queue_empty:SetMouseVisible(false)
    self.queue_empty:SetMultiline(true)
    self.queue_empty:SetForeColor(TEXT_META)
    self.queue_empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.queue_empty:SetText(TR["Add recipes to the plan to keep a short queue here."])

    self.plan_panel = Turbine.UI.Control()
    self.plan_panel:SetParent(self.plan_page)
    _set_control_fill(self.plan_panel, PANEL_BACK)

    self.plan_header_bar = Turbine.UI.Control()
    self.plan_header_bar:SetParent(self.plan_panel.inner)
    self.plan_header_bar:SetMouseVisible(false)
    self.plan_header_bar:SetBackColor(SECTION_HEADER_BACK)
    self.plan_header_bar:SetZOrder(1)

    self.plan_title = UI.Widgets.LuiLabel()
    self.plan_title:SetParent(self.plan_panel.inner)
    self.plan_title:SetMouseVisible(false)
    self.plan_title:SetForeColor(TEXT_META)
    self.plan_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.plan_title:SetText(TR["Build plan"])

    self.plan_track_button = UI.Widgets.LuiButton()
    self.plan_track_button:SetParent(self.plan_panel.inner)
    self.plan_track_button:set_text(TR["Track Plan"])
    self.plan_track_button.Click = function()
        self:track_plan()
    end

    self.plan_revert_button = UI.Widgets.LuiButton()
    self.plan_revert_button:SetParent(self.plan_panel.inner)
    self.plan_revert_button:set_text(TR["Revert"])
    self.plan_revert_button.Click = function()
        self:revert_plan()
    end

    self.plan_clear_button = UI.Widgets.LuiButton()
    self.plan_clear_button:SetParent(self.plan_panel.inner)
    self.plan_clear_button:set_text(TR["Clear"])
    self.plan_clear_button.Click = function()
        self:clear_plan()
    end
    self.plan_title:SetZOrder(2)
    self.plan_track_button:SetZOrder(2)
    self.plan_revert_button:SetZOrder(2)
    self.plan_clear_button:SetZOrder(2)

    self.plan_list = Turbine.UI.ListBox()
    self.plan_list:SetParent(self.plan_panel.inner)
    self.plan_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.plan_scroll = Turbine.UI.Lotro.ScrollBar()
    self.plan_scroll:SetParent(self.plan_panel.inner)
    self.plan_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.plan_list:SetVerticalScrollBar(self.plan_scroll)

    self.missing_title = UI.Widgets.LuiLabel()
    self.missing_title:SetParent(self.plan_panel.inner)
    self.missing_title:SetMouseVisible(false)
    self.missing_title:SetForeColor(TEXT_META)
    self.missing_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.missing_title:SetText(TR["Resources"])

    self.missing_header_bar = Turbine.UI.Control()
    self.missing_header_bar:SetParent(self.plan_panel.inner)
    self.missing_header_bar:SetMouseVisible(false)
    self.missing_header_bar:SetBackColor(SECTION_HEADER_BACK)
    self.missing_header_bar:SetZOrder(1)
    self.missing_title:SetZOrder(2)

    self.plan_resources_border = Turbine.UI.Control()
    self.plan_resources_border:SetParent(self.plan_panel.inner)
    self.plan_resources_border:SetMouseVisible(false)
    self.plan_resources_border:SetBackColor(PANEL_BORDER)

    self.missing_list = Turbine.UI.ListBox()
    self.missing_list:SetParent(self.plan_panel.inner)
    self.missing_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.missing_scroll = Turbine.UI.Lotro.ScrollBar()
    self.missing_scroll:SetParent(self.plan_panel.inner)
    self.missing_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.missing_list:SetVerticalScrollBar(self.missing_scroll)

    self.plan_empty = UI.Widgets.LuiLabel()
    self.plan_empty:SetParent(self.plan_panel.inner)
    self.plan_empty:SetMouseVisible(false)
    self.plan_empty:SetMultiline(true)
    self.plan_empty:SetForeColor(TEXT_META)
    self.plan_empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.plan_empty:SetText(TR["Add recipes to the plan to see total shortages."])

    self.loading_panel = Turbine.UI.Control()
    self.loading_panel:SetParent(content_host)
    _set_control_border(self.loading_panel, PANEL_BORDER, PANEL_BACK)
    self.loading_panel:SetVisible(false)

    self.loading_text = UI.Widgets.LuiLabel()
    self.loading_text:SetParent(self.loading_panel.inner)
    self.loading_text:SetMouseVisible(false)
    self.loading_text:SetForeColor(TEXT_META)
    self.loading_text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.loading_track = Turbine.UI.Control()
    self.loading_track:SetParent(self.loading_panel.inner)
    self.loading_track:SetMouseVisible(false)
    self.loading_track:SetBackColor(PANEL_BORDER)

    self.loading_track_inner = Turbine.UI.Control()
    self.loading_track_inner:SetParent(self.loading_track)
    self.loading_track_inner:SetMouseVisible(false)
    self.loading_track_inner:SetBackColor(SECTION_BACK)

    self.loading_fill = Turbine.UI.Control()
    self.loading_fill:SetParent(self.loading_track_inner)
    self.loading_fill:SetMouseVisible(false)
    self.loading_fill:SetBackColor(STATUS_AUTO)

    self.source_breakdown_hint = UI.Widgets.LuiTooltip()
    self.source_breakdown_hint:SetScale(_G.settings.global.scale)
    self.source_breakdown_hint:SetZOrder(2300)

    self.source_breakdown_hint_inner = Turbine.UI.Control()
    self.source_breakdown_hint_inner:SetParent(self.source_breakdown_hint:GetContentHost())
    self.source_breakdown_hint_inner:SetMouseVisible(false)
    self.source_breakdown_hint_rows = {}

    self.SizeChanged = function()
        LuiWindow._layout(self)
        if self._suppress_size_changed == true then
            return
        end
        self:_hide_source_breakdown_hint()
        self:_enforce_min_size()
        self:layout()
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self:refresh_selected_recipe()
        self:refresh_plan()
    end
    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if self.store ~= nil then
            self.store:set_loading_priority(visible)
        end
        if visible == true then
            self._last_update_at = 0
            self._last_store_version = nil
            self:refresh_from_store(true)
            self:bring_to_front()
        else
            self:_hide_source_breakdown_hint()
        end
    end

    self:SetSize(self:get_window_size_for_content(_scaled_int(1100), _scaled_int(700)))
    self:apply_settings()
end

function CraftingWindow._status_color(_, evaluation)
    if evaluation ~= nil and evaluation.craftable == true then
        if evaluation.used_expansion == true then
            return STATUS_AUTO
        end
        return STATUS_READY
    end
    return STATUS_MISSING
end

function CraftingWindow:_item(item_key)
    if self.store == nil then
        return nil
    end
    return self.store:get_item(item_key)
end

function CraftingWindow:_source_breakdown_for_item(item_key, required)
    if self.store == nil then
        return nil
    end

    local needed = tonumber(required) or 0
    if item_key == nil or item_key == "" or needed <= 0 then
        return nil
    end

    return self.store:get_source_breakdown(item_key, needed, self.scope_key)
end

function CraftingWindow:_source_breakdown_hint_text(breakdown)
    if type(breakdown) ~= "table" or type(breakdown.entries) ~= "table" then
        return "", TEXT_META
    end

    local positive = {}
    for i = 1, #breakdown.entries do
        local entry = breakdown.entries[i]
        if type(entry) == "table" and (tonumber(entry.owned) or 0) > 0 then
            positive[#positive + 1] = entry
        end
    end

    if #positive == 0 then
        return "", TEXT_META
    end
    if #positive == 1 then
        local entry = positive[1]
        local label = entry.label or ""
        if entry.key == "shared_storage" then
            label = TR["Shared"]
        elseif entry.key == "other_characters" then
            label = TR["Other"]
        end
        return label, _source_hint_color(entry.key)
    end
    return _format_count(#positive) .. " " .. TR["locations"], TEXT_META
end

function CraftingWindow:_ensure_source_breakdown_hint_rows(count)
    if self.source_breakdown_hint_rows == nil then
        self.source_breakdown_hint_rows = {}
    end

    while #self.source_breakdown_hint_rows < count do
        local row = {}
        row.holder = Turbine.UI.Control()
        row.holder:SetParent(self.source_breakdown_hint_inner)
        row.holder:SetMouseVisible(false)

        row.source = UI.Widgets.LuiLabel()
        row.source:SetParent(row.holder)
        row.source:SetMouseVisible(false)
        row.source:SetMultiline(false)
        row.source:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        row.source:SetFont(_scaled_font("Verdana", 10))

        row.quantity = UI.Widgets.LuiLabel()
        row.quantity:SetParent(row.holder)
        row.quantity:SetMouseVisible(false)
        row.quantity:SetMultiline(false)
        row.quantity:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        row.quantity:SetFont(_scaled_font("Verdana", 10))

        self.source_breakdown_hint_rows[#self.source_breakdown_hint_rows + 1] = row
    end
end

function CraftingWindow:_hide_source_breakdown_hint()
    if self.source_breakdown_hint ~= nil then
        self.source_breakdown_hint:Hide()
    end
end

function CraftingWindow:_show_source_breakdown_hint(anchor_control, breakdown)
    if anchor_control == nil or type(breakdown) ~= "table" then
        self:_hide_source_breakdown_hint()
        return
    end

    local lines = {}
    local entries = type(breakdown.entries) == "table" and breakdown.entries or {}
    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            lines[#lines + 1] = {
                label = entry.label or "",
                quantity = _format_count(entry.owned),
                color = _source_hint_color(entry.key),
            }
        end
    end

    local total_owned = tonumber(breakdown.total_owned) or 0
    local required = tonumber(breakdown.required) or 0
    local missing = tonumber(breakdown.missing) or math.max(0, required - total_owned)
    local complete = missing <= 0
    if required > 0 then
        lines[#lines + 1] = {
            label = TR["Total"],
            quantity = _ratio_text(total_owned, required),
            color = complete == true and STATUS_READY or STATUS_MISSING,
        }
    end
    if missing > 0 then
        lines[#lines + 1] = {
            label = TR["Missing"],
            quantity = _format_count(missing),
            color = STATUS_MISSING,
        }
    end

    if #lines == 0 then
        self:_hide_source_breakdown_hint()
        return
    end

    local max_width = _scaled_int(BASE_SOURCE_TOOLTIP_W)
    local padding_x = _scaled_int(BASE_SOURCE_TOOLTIP_PAD_X)
    local padding_y = _scaled_int(BASE_SOURCE_TOOLTIP_PAD_Y)
    local line_height = _scaled_int(BASE_SOURCE_TOOLTIP_LINE_H)
    local tooltip_border = math.max(0, _scaled_int(tonumber(UI.Widgets.Style.BORDER_WIDTH_THIN) or 1))
    local content_height = math.min(
        _scaled_int(BASE_SOURCE_TOOLTIP_MAX_H),
        math.max(_scaled_int(BASE_SOURCE_TOOLTIP_MIN_H), (#lines * line_height) + padding_y + _scaled_int(7))
    )
    local desired_height = content_height + (tooltip_border * 2)
    local inner_w = max_width - (tooltip_border * 2)
    local inner_h = desired_height - (tooltip_border * 2)
    local row_x = math.floor(padding_x / 2)
    local row_w = math.max(0, inner_w - padding_x)
    local col_gap = _scaled_int(4)
    local quantity_w = math.max(_scaled_int(36), math.floor(row_w * 0.24))
    local source_w = math.max(0, row_w - quantity_w - col_gap)

    self:_ensure_source_breakdown_hint_rows(#lines)
    for i = 1, #self.source_breakdown_hint_rows do
        local row = self.source_breakdown_hint_rows[i]
        if i <= #lines then
            local line = lines[i]
            local row_y = _scaled_int(4) + ((i - 1) * line_height)
            local color = line.color or TEXT_META

            row.holder:SetPosition(row_x, row_y)
            row.holder:SetSize(row_w, line_height)

            row.source:SetPosition(0, 0)
            row.source:SetSize(source_w, line_height)
            row.source:SetFont(_scaled_font("Verdana", 10))
            row.source:SetForeColor(color)
            row.source:SetText(line.label or "")
            row.source:SetVisible(true)

            row.quantity:SetPosition(source_w + col_gap, 0)
            row.quantity:SetSize(quantity_w, line_height)
            row.quantity:SetFont(_scaled_font("Verdana", 10))
            row.quantity:SetForeColor(color)
            row.quantity:SetText(line.quantity or "")
            row.quantity:SetVisible(true)
            row.holder:SetVisible(true)
        else
            row.source:SetVisible(false)
            row.quantity:SetVisible(false)
            row.holder:SetVisible(false)
        end
    end

    self.source_breakdown_hint:ShowContentFor(anchor_control, max_width, desired_height)
    self.source_breakdown_hint_inner:SetPosition(0, 0)
    self.source_breakdown_hint_inner:SetSize(inner_w, inner_h)
end

function CraftingWindow:_recipe_result_item(recipe)
    if self.store == nil then
        return nil
    end
    return self.store:get_recipe_result_item(recipe)
end

function CraftingWindow:_recipe_result_name(recipe)
    if self.store == nil then
        return ""
    end
    return self.store:get_recipe_result_name(recipe)
end

function CraftingWindow:_recipe_critical_result_item(recipe)
    return self:_item(recipe ~= nil and recipe.critical_result_key or nil)
end

function CraftingWindow:_recipe_required_level(recipe)
    if self.store == nil then
        return nil
    end
    return self.store:get_recipe_required_level(recipe)
end

function CraftingWindow:_critical_result_detail(recipe)
    local parts = { TR["Critical result"] }
    if recipe ~= nil and (tonumber(recipe.critical_result_quantity) or 0) > 1 then
        parts[#parts + 1] = TR["Makes x"] .. _format_count(recipe.critical_result_quantity)
    end
    local critical_chance = _format_percent(recipe ~= nil and recipe.critical_chance or nil)
    if critical_chance ~= nil then
        parts[#parts + 1] = TR["Base crit"] .. " " .. critical_chance
    end
    return table.concat(parts, " - ")
end

function CraftingWindow._status_text(_, evaluation)
    if evaluation == nil then
        return ""
    end

    local ready, total = _top_level_progress(evaluation)
    if total <= 0 then
        return ""
    end

    return _ratio_text(ready, total)
end

function CraftingWindow._recipe_status_text(_, status)
    if type(status) == "table" then
        local craftable_count = tonumber(status.craftable_count) or 0
        if craftable_count > 0 then
            local text = _format_count(craftable_count)
            if status.craftable_count_limited == true then
                text = text .. "+"
            end
            return text
        end
    end

    return "0"
end

function CraftingWindow._node_status_color(_, node)
    if type(node) ~= "table" then
        return TEXT_META
    end
    if node.satisfied == true then
        if node.expanded == true then
            return STATUS_AUTO
        end
        return STATUS_READY
    end
    return STATUS_MISSING
end

function CraftingWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function CraftingWindow:show_recipe_tab()
    if self.right_tab_bar ~= nil and self.right_tab_bar.select_tab ~= nil then
        self.right_tab_bar:select_tab(1)
    end
end

function CraftingWindow:show_plan_tab()
    if self.right_tab_bar ~= nil and self.right_tab_bar.select_tab ~= nil then
        self.right_tab_bar:select_tab(2)
    end
end

function CraftingWindow:_saved_plan_entries()
    return Crafting.get_tracked_plan_entries()
end

function CraftingWindow:_favorite_key_for_entry(entry)
    return _favorite_entry_key(entry)
end

function CraftingWindow:_favorite_entry_for_recipe(recipe)
    if self.store == nil then
        return nil
    end
    return self.store:serialize_recipe_identity(recipe)
end

function CraftingWindow:_favorite_key_for_recipe(recipe)
    return self:_favorite_key_for_entry(self:_favorite_entry_for_recipe(recipe))
end

function CraftingWindow:_rebuild_favorite_keys()
    self.favorite_keys = {}
    if type(self.favorite_entries) ~= "table" then
        self.favorite_entries = {}
        return
    end

    for i = 1, #self.favorite_entries do
        local key = self:_favorite_key_for_entry(self.favorite_entries[i])
        if key ~= "" then
            self.favorite_keys[key] = true
        end
    end
end

function CraftingWindow:_load_favorites()
    self.favorite_entries = Crafting.get_favorite_recipe_entries()
    self:_rebuild_favorite_keys()
end

function CraftingWindow:_save_favorites()
    Crafting.set_favorite_recipe_entries(self.favorite_entries, true)
end

function CraftingWindow:_is_recipe_favorite(recipe)
    local key = self:_favorite_key_for_recipe(recipe)
    return key ~= "" and type(self.favorite_keys) == "table" and self.favorite_keys[key] == true
end

function CraftingWindow:_set_recipe_favorite(recipe, favorite)
    local entry = self:_favorite_entry_for_recipe(recipe)
    local key = self:_favorite_key_for_entry(entry)
    if key == "" then
        return
    end

    local next_entries = {}
    for i = 1, #self.favorite_entries do
        local saved_entry = self.favorite_entries[i]
        local saved_key = self:_favorite_key_for_entry(saved_entry)
        if saved_key ~= key then
            next_entries[#next_entries + 1] = saved_entry
        end
    end

    if favorite == true then
        next_entries[#next_entries + 1] = entry
    end

    self.favorite_entries = next_entries
    self:_rebuild_favorite_keys()
    self:_save_favorites()
    self:_invalidate_recipe_list()
    self:refresh_recipe_list()
    self:refresh_selected_recipe()
end

function CraftingWindow:toggle_recipe_favorite(recipe)
    self:_set_recipe_favorite(recipe, self:_is_recipe_favorite(recipe) ~= true)
end

function CraftingWindow:_refresh_favorite_filter_button()
    if self.favorite_filter_button == nil then
        return
    end
    _apply_favorite_icon(self.favorite_filter_button, self.favorite_filter_active == true)
end

function CraftingWindow:set_favorite_filter(active)
    self.favorite_filter_active = active == true
    self:_refresh_favorite_filter_button()
    self.recipe_page_index = 1
    self:_invalidate_recipe_list()
    self:refresh_recipe_list()
    self:refresh_selected_recipe()
end

function CraftingWindow:_set_runtime_plan_entries(plan_entries)
    self.plan_order = {}
    self.plan_counts = {}

    if type(plan_entries) ~= "table" then
        return
    end

    for i = 1, #plan_entries do
        local entry = plan_entries[i]
        local recipe_id = entry ~= nil and entry.recipe_id or nil
        local count = entry ~= nil and (tonumber(entry.count) or 0) or 0
        count = math.floor(count + 0.5)
        if recipe_id ~= nil and count > 0 then
            self.plan_order[#self.plan_order + 1] = recipe_id
            self.plan_counts[recipe_id] = count
        end
    end
end

function CraftingWindow:_sync_draft_plan_from_tracked()
    if self.store == nil then
        return false
    end

    local resolved = Crafting.resolve_tracked_plan_entries(self.store)
    local next_entries = resolved ~= nil and resolved.entries or nil
    local current_entries = self:_build_plan_entries()

    local same = true
    if type(next_entries) ~= "table" or #next_entries ~= #current_entries then
        same = false
    else
        for i = 1, #current_entries do
            local left = current_entries[i]
            local right = next_entries[i]
            if left == nil or right == nil or left.recipe_id ~= right.recipe_id or
                (tonumber(left.count) or 0) ~= (tonumber(right.count) or 0) then
                same = false
                break
            end
        end
    end

    if same == true then
        return false
    end

    self:_set_runtime_plan_entries(next_entries)
    return true
end

function CraftingWindow:_refresh_plan_dirty_state()
    if self.store == nil then
        self._plan_dirty = false
        self._plan_user_changed = false
        return
    end

    if self._plan_user_changed ~= true then
        self._plan_dirty = false
        return
    end

    local current_saved_entries = self.store:serialize_plan_entries(self:_build_plan_entries())
    self._plan_dirty = _saved_plan_entries_equal(current_saved_entries, self:_saved_plan_entries()) ~= true
    if self._plan_dirty ~= true then
        self._plan_user_changed = false
    end
end

function CraftingWindow:_apply_search_query(text)
    local query_text = _safe_string(text, "")
    self._suppress_search_text_changed = true
    self.search_box:SetText(query_text)
    self._suppress_search_text_changed = false
    self.search_groups = _normalize_query_groups(_parse_query(query_text))
end

function CraftingWindow:_scope_source_summary(selected_values)
    local labels, values = self.store:get_source_options()
    local selected = {}
    for i = 1, #selected_values do
        selected[selected_values[i]] = true
    end

    local selected_labels = {}
    for i = 1, #values do
        if selected[values[i]] == true then
            selected_labels[#selected_labels + 1] = labels[i]
        end
    end

    if #selected_labels == 0 then
        return TR["None"]
    end
    if #selected_labels == #values then
        return TR["All"]
    end
    if #selected_labels == 1 then
        return selected_labels[1]
    end
    return _format_count(#selected_labels) .. " " .. TR["locations"]
end

function CraftingWindow:_set_scope_dropdown_options()
    if self.scope_dropdown == nil then
        return
    end

    local labels, values = self.store:get_source_options()
    self.scope_dropdown:SetMappedOptions(labels, values)
    self:set_scope_sources(self.scope_source_keys, false)
end

function CraftingWindow:_refresh_profession_options()
    local profession_labels, profession_values = self.store:get_profession_options()
    local options_signature = _option_list_signature(profession_labels, profession_values)
    if options_signature ~= self._profession_options_signature then
        self.profession_dropdown:SetMappedOptions(profession_labels, profession_values)
        self._profession_options_signature = options_signature
    end

    local profession_found = false
    for i = 1, #profession_values do
        if profession_values[i] == self.profession_filter then
            profession_found = true
            break
        end
    end
    if profession_found ~= true then
        self.profession_filter = FILTER_ALL
    end

    if self.profession_dropdown:GetValue() ~= self.profession_filter then
        self.profession_dropdown:SetValue(self.profession_filter)
    end
end

function CraftingWindow:_loaded_recipe_matches_watch(watch_keys, loaded_result_keys)
    if type(watch_keys) ~= "table" or type(loaded_result_keys) ~= "table" then
        return false
    end
    for key in pairs(loaded_result_keys) do
        if watch_keys[key] == true then
            return true
        end
    end
    return false
end

function CraftingWindow:set_scope_sources(source_keys, refresh)
    local normalized = self.store:normalize_source_keys(source_keys)
    local next_scope_key = self.store:scope_key_from_sources(normalized)
    local changed = next_scope_key ~= self.scope_key

    self:_hide_source_breakdown_hint()
    self.scope_source_keys = normalized
    self.scope_key = next_scope_key
    if self.scope_dropdown ~= nil then
        self.scope_dropdown:SetSelectedValues(self.scope_source_keys, false)
    end

    if refresh ~= true or changed ~= true then
        return
    end

    self.recipe_page_index = 1
    self:_invalidate_recipe_list()
    self:refresh_recipe_list()
    self:refresh_selected_recipe()
    self:refresh_plan()
end

function CraftingWindow:open()
    self:show()
    self:SetWantsUpdates(true)
    if self.store ~= nil then
        self.store:refresh_if_due()
    end
    self._plan_user_changed = false
    self:_sync_draft_plan_from_tracked()
    self._plan_dirty = false
    self:refresh_from_store(true)
end

function CraftingWindow:open_from_asset_materials(_)
    self.profession_filter = FILTER_ALL
    self:set_scope_sources(self.store:get_all_source_keys(), false)
    self.availability_filter = AVAILABILITY_READY
    self.level_min_filter = nil
    self.level_max_filter = nil
    self.recipe_page_index = 1
    self:_apply_search_query("")
    self:_invalidate_recipe_list()

    if self.profession_dropdown ~= nil then
        self.profession_dropdown:SetValue(self.profession_filter)
    end
    if self.scope_dropdown ~= nil then
        self.scope_dropdown:SetSelectedValues(self.scope_source_keys, false)
    end
    if self.availability_dropdown ~= nil then
        self.availability_dropdown:SetValue(self.availability_filter)
    end
    if self.level_min_box ~= nil then
        self.level_min_box:SetText("")
    end
    if self.level_max_box ~= nil then
        self.level_max_box:SetText("")
    end

    self:open()
    self:show_recipe_tab()
end

function CraftingWindow:open_plan()
    self:open()
    self:show_plan_tab()
end

function CraftingWindow:toggle()
    if self:IsVisible() == true then
        self:hide()
        self:SetWantsUpdates(false)
        return
    end

    self:open()
end

function CraftingWindow:destroy()
    self:SetWantsUpdates(false)
    self:hide()
    self:_hide_source_breakdown_hint()
    self.store = nil
end

function CraftingWindow:capture_geometry()
    local raw = _G.loaded_settings ~= nil and _G.loaded_settings.crafting or nil
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

function CraftingWindow:persist_geometry()
    self:capture_geometry()
end

function CraftingWindow:_minimum_window_size()
    return self:get_window_size_for_content(_scaled_int(BASE_MIN_W), _scaled_int(BASE_MIN_H))
end

function CraftingWindow:apply_settings()
    LuiWindow.apply_settings(self)
    self.update_every = math.max(0.20, 1.0 / math.max(1, tonumber(_G.settings.global.refresh_rate) or 30))
    self:set_minimum_size(self:_minimum_window_size())
    self:_enforce_min_size()

    self.search_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.clear_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.favorite_filter_button:set_scale(1)
    self.scope_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.scope_dropdown:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.scope_dropdown:SetScale(_G.settings.global.scale)
    self.profession_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.profession_dropdown:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.profession_dropdown:SetScale(_G.settings.global.scale)
    self.availability_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.availability_dropdown:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.availability_dropdown:SetScale(_G.settings.global.scale)
    self.level_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.level_min_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.level_dash_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.level_max_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.recipe_page_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))

    self.recipe_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.right_tab_bar:set_font(_scaled_font("Verdana", BASE_META_FONT))
    self.right_tab_bar:set_scale(_G.settings.global.scale)
    self.detail_title:SetFont(_scaled_font("Verdana", BASE_TITLE_FONT))
    self.detail_meta:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.detail_status:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.critical_result_row:set_scale(_G.settings.global.scale)
    self.plan_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_spin_box:set_scale(_G.settings.global.scale)
    self.plan_spin_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.ingredients_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.detail_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.queue_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.queue_summary:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.queue_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))

    self.plan_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_track_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.plan_revert_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.plan_clear_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.missing_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.loading_text:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    if self.source_breakdown_hint ~= nil then
        self.source_breakdown_hint:SetScale(_G.settings.global.scale)
    end

    self:_set_scope_dropdown_options()
    self:_load_favorites()
    self:_refresh_favorite_filter_button()
    self.availability_filter = _normalize_availability_filter(self.availability_filter)
    self.availability_dropdown:SetValue(self.availability_filter)

    self:_load_geometry()
    self:refresh_from_store(true)
end

function CraftingWindow:_load_geometry()
    local raw = _G.loaded_settings ~= nil and _G.loaded_settings.crafting or nil
    local window = raw ~= nil and raw.window or nil
    if type(window) ~= "table" then
        return
    end

    local left = tonumber(window.left) or self:GetLeft()
    local top = tonumber(window.top) or self:GetTop()
    local width = tonumber(window.width) or self:GetWidth()
    local height = tonumber(window.height) or self:GetHeight()
    local min_w, min_h = self:_minimum_window_size()

    self._suppress_size_changed = true
    self:SetPosition(left, top)
    self:SetSize(math.max(min_w, width), math.max(min_h, height))
    self._suppress_size_changed = false
    self:_enforce_min_size()
    self:layout()
end

function CraftingWindow:_enforce_min_size()
    local width, height = self:GetSize()
    local min_w, min_h = self:_minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    if width >= min_w and height >= min_h then
        return
    end

    self._suppress_size_changed = true
    self:SetSize(math.max(width, min_w), math.max(height, min_h))
    self._suppress_size_changed = false
end

function CraftingWindow:Update()
    if self:IsVisible() ~= true then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - (self._last_update_at or 0)) < self.update_every then
        return
    end
    self._last_update_at = now

    local store_changed = false
    if self.store ~= nil then
        store_changed = self.store:refresh_if_due() == true
    end
    local store_version = tonumber(self.store ~= nil and self.store.version or nil) or 0
    if store_changed == true or store_version ~= self._last_store_version then
        self._last_store_version = store_version
        self:refresh_from_store(false)
    end
end

function CraftingWindow:refresh_from_store(reset_filters)
    local was_loading = self._store_loading == true
    local loading = self.store:is_loading() == true
    self._store_loading = loading
    self:refresh_loading_state()
    self:_refresh_profession_options()

    if reset_filters == true then
        self.search_groups = _normalize_query_groups(_parse_query(self.search_box:GetText()))
    end

    local loaded_result_keys = self.store:consume_loaded_recipe_result_keys()
    local selected_recipe_discovered =
        self:_loaded_recipe_matches_watch(self._selected_recipe_watch_keys, loaded_result_keys)
    local plan_recipe_discovered =
        self:_loaded_recipe_matches_watch(self._plan_recipe_watch_keys, loaded_result_keys)

    local plan_synced = false
    if self._plan_user_changed ~= true then
        plan_synced = self:_sync_draft_plan_from_tracked()
    end

    local has_saved_tracked_plan = #self:_saved_plan_entries() > 0
    local completed_loading = was_loading == true and loading ~= true
    local recipe_list_state = self:refresh_recipe_list({ refresh_selected = false })

    if reset_filters == true or completed_loading == true or
        selected_recipe_discovered == true or
        (recipe_list_state ~= nil and recipe_list_state.selection_changed == true) then
        self:refresh_selected_recipe()
    end

    if reset_filters == true or plan_synced == true or completed_loading == true or
        plan_recipe_discovered == true or
        (loading ~= true and (#self.plan_order > 0 or has_saved_tracked_plan == true)) then
        self:refresh_plan()
    end
    self._last_store_version = tonumber(self.store ~= nil and self.store.version or nil) or 0
end

function CraftingWindow:set_material_filter_keys(material_keys)
    return material_keys
end

function CraftingWindow:clear_material_filter()
    return
end

function CraftingWindow:update_level_filter()
    local filter_min = _parse_level_value(self.level_min_box:GetText())
    local filter_max = _parse_level_value(self.level_max_box:GetText())
    if filter_min ~= nil and filter_max ~= nil and filter_min > filter_max then
        filter_min, filter_max = filter_max, filter_min
    end

    self.level_min_filter = filter_min
    self.level_max_filter = filter_max
    self.recipe_page_index = 1
    self:_invalidate_recipe_list()
    self:refresh_recipe_list()
    self:refresh_selected_recipe()
end

function CraftingWindow:_selected_recipe()
    return self.store.recipe_by_id[self.selected_recipe_id]
end

function CraftingWindow:_current_recipe_list_width()
    return math.max(0, self.recipe_list:GetWidth() - _scaled_int(2))
end

function CraftingWindow:set_recipe_page(index)
    local page = math.max(1, math.min(self.recipe_page_count, tonumber(index) or 1))
    if page == self.recipe_page_index then
        return
    end

    self.recipe_page_index = page
    if self.display_mode == DISPLAY_PAGES then
        self:_refresh_recipe_page_rows(self:_current_recipe_list_width())
    end
end

function CraftingWindow:_current_detail_list_width()
    return math.max(0, self.ingredients_list:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_queue_list_width()
    return math.max(0, self.queue_list:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_plan_list_width()
    return math.max(0, self.plan_list:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_missing_list_width()
    return math.max(0, self.missing_list:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_ensure_selected_visible_recipe()
    local selected = self.selected_recipe_id
    if selected ~= nil then
        for i = 1, #self.visible_recipes do
            if self.visible_recipes[i].id == selected then
                return
            end
        end
    end

    self.selected_recipe_id = self.visible_recipes[1] ~= nil and self.visible_recipes[1].id or nil
end

function CraftingWindow:_recipe_matches_filters(recipe, status)
    if recipe == nil then
        return false
    end

    if self.profession_filter ~= FILTER_ALL and recipe.profession_key ~= self.profession_filter then
        return false
    end
    if self.store:recipe_matches_query(recipe, self.search_groups) ~= true then
        return false
    end
    if self.favorite_filter_active == true and self:_is_recipe_favorite(recipe) ~= true then
        return false
    end
    if self.level_min_filter ~= nil or self.level_max_filter ~= nil then
        local required_level = tonumber(self:_recipe_required_level(recipe))
        if required_level == nil then
            return false
        end
        if self.level_min_filter ~= nil and required_level < self.level_min_filter then
            return false
        end
        if self.level_max_filter ~= nil and required_level > self.level_max_filter then
            return false
        end
    end

    if self.availability_filter == AVAILABILITY_READY then
        return status ~= nil and status.craftable == true
    elseif self.availability_filter == AVAILABILITY_MISSING then
        return status ~= nil and status.craftable ~= true
    end

    return true
end

function CraftingWindow:_invalidate_recipe_list()
    self._recipe_list_signature = nil
    self._recipe_list_loaded_count = 0
    self._recipe_list_loading = false
    self._recipe_list_row_width = 0
    self._recipe_list_page_size = 0
    self._recipe_page_rendered_start = 1
    self._recipe_page_rendered_end = 0
end

function CraftingWindow:_recipe_filter_signature()
    return table.concat({
        _safe_string(self.scope_key, ""),
        _safe_string(self.profession_filter, ""),
        _safe_string(self.availability_filter, ""),
        self.favorite_filter_active == true and "favorites" or "",
        _safe_string(self.level_min_filter, ""),
        _safe_string(self.level_max_filter, ""),
        _safe_string(self.search_box ~= nil and self.search_box:GetText() or "", ""),
    }, "\30")
end

function CraftingWindow:_append_recipe_row(recipe, row_w)
    if recipe == nil then
        return
    end

    local status = self.store:get_recipe_status(recipe, self.scope_key)
    local result_item = self:_recipe_result_item(recipe)
    local required_level = self:_recipe_required_level(recipe)
    local row = CraftingRecipeRow(
        function(selected_recipe)
            self.selected_recipe_id = selected_recipe.id
            self:_invalidate_recipe_list()
            self:refresh_recipe_list()
            self:refresh_selected_recipe()
        end,
        function(selected_recipe)
            self:toggle_recipe_favorite(selected_recipe)
        end
    )
    row:set_scale(_G.settings.global.scale)
    row:set_width(row_w)
    row:set_data(recipe, status, result_item, required_level, self:_is_recipe_favorite(recipe))
    row:set_selected(recipe.id == self.selected_recipe_id)
    self.recipe_list:AddItem(row)
end

function CraftingWindow:_recipe_page_capacity()
    local row_h = math.max(1, _scaled_int(BASE_RECIPE_ROW_H))
    local list_h = math.max(0, self.recipe_list:GetHeight())
    return math.max(1, math.floor(list_h / row_h))
end

function CraftingWindow:_recipe_filter_needs_status()
    return self.availability_filter == AVAILABILITY_READY or self.availability_filter == AVAILABILITY_MISSING
end

function CraftingWindow:_refresh_recipe_page_controls()
    self.recipe_page_size = self:_recipe_page_capacity()
    self.recipe_page_count = math.max(1, math.ceil(#self.visible_recipes / self.recipe_page_size))
    if self.recipe_page_index > self.recipe_page_count then
        self.recipe_page_index = self.recipe_page_count
    end
    if self.recipe_page_index < 1 then
        self.recipe_page_index = 1
    end

    self.recipe_page_label:SetText(tostring(self.recipe_page_index) .. " / " .. tostring(self.recipe_page_count))
    self.recipe_prev_button:set_enabled(self.recipe_page_index > 1)
    self.recipe_next_button:set_enabled(self.recipe_page_index < self.recipe_page_count)
end

function CraftingWindow:_refresh_recipe_page_rows(row_w)
    self:_refresh_recipe_page_controls()
    _clear_list_box(self.recipe_list)

    local start_index = ((self.recipe_page_index - 1) * self.recipe_page_size) + 1
    local end_index = math.min(#self.visible_recipes, start_index + self.recipe_page_size - 1)
    for i = start_index, end_index do
        self:_append_recipe_row(self.visible_recipes[i], row_w)
    end

    self._recipe_page_rendered_start = start_index
    self._recipe_page_rendered_end = end_index
    self._recipe_list_page_size = self.recipe_page_size
end

function CraftingWindow:_append_recipe_page_rows_until_full(row_w)
    self:_refresh_recipe_page_controls()

    local start_index = ((self.recipe_page_index - 1) * self.recipe_page_size) + 1
    local end_index = math.min(#self.visible_recipes, start_index + self.recipe_page_size - 1)
    if self._recipe_page_rendered_start ~= start_index then
        self:_refresh_recipe_page_rows(row_w)
        return true
    end

    local rendered_end = tonumber(self._recipe_page_rendered_end) or (start_index - 1)
    if rendered_end < start_index - 1 then
        rendered_end = start_index - 1
    end
    if rendered_end >= end_index then
        self._recipe_list_page_size = self.recipe_page_size
        return false
    end

    for i = rendered_end + 1, end_index do
        self:_append_recipe_row(self.visible_recipes[i], row_w)
    end
    self._recipe_page_rendered_end = end_index
    self._recipe_list_page_size = self.recipe_page_size
    return true
end

function CraftingWindow:refresh_recipe_list(options)
    local should_refresh_selected = type(options) ~= "table" or options.refresh_selected ~= false
    local previous_selected = self.selected_recipe_id
    local row_w = self:_current_recipe_list_width()
    local loading = self.store:is_loading() == true
    local signature = self:_recipe_filter_signature()
    local loaded_count = #self.store.recipes
    local pages_mode = self.display_mode == DISPLAY_PAGES
    local page_size = pages_mode == true and self:_recipe_page_capacity() or 0
    local needs_status = self:_recipe_filter_needs_status()
    local state = {
        selection_changed = false,
        rows_changed = false,
        full_refresh = false,
    }
    local can_incremental = loading == true and
        self._recipe_list_loading == true and
        self._recipe_list_signature == signature and
        self._recipe_list_row_width == row_w and
        (pages_mode ~= true or self._recipe_list_page_size == page_size) and
        loaded_count >= self._recipe_list_loaded_count

    if can_incremental ~= true then
        self.visible_recipes = {}
        for i = 1, loaded_count do
            local recipe = self.store.recipes[i]
            local status = needs_status == true and self.store:get_recipe_status(recipe, self.scope_key) or nil
            if self:_recipe_matches_filters(recipe, status) == true then
                self.visible_recipes[#self.visible_recipes + 1] = recipe
            end
        end

        self:_ensure_selected_visible_recipe()
        if pages_mode == true then
            self:_refresh_recipe_page_rows(row_w)
        else
            _clear_list_box(self.recipe_list)
            for i = 1, #self.visible_recipes do
                self:_append_recipe_row(self.visible_recipes[i], row_w)
            end
        end
        state.rows_changed = true
        state.full_refresh = true
    elseif loaded_count > self._recipe_list_loaded_count then
        local visible_count_before = #self.visible_recipes
        for i = self._recipe_list_loaded_count + 1, loaded_count do
            local recipe = self.store.recipes[i]
            local status = needs_status == true and self.store:get_recipe_status(recipe, self.scope_key) or nil
            if self:_recipe_matches_filters(recipe, status) == true then
                self.visible_recipes[#self.visible_recipes + 1] = recipe
                if self.selected_recipe_id == nil then
                    self.selected_recipe_id = recipe.id
                end
                if pages_mode ~= true then
                    self:_append_recipe_row(recipe, row_w)
                    state.rows_changed = true
                end
            end
        end
        if pages_mode == true then
            if #self.visible_recipes > visible_count_before then
                state.rows_changed = self:_append_recipe_page_rows_until_full(row_w) == true or state.rows_changed
            else
                self:_refresh_recipe_page_controls()
                self._recipe_list_page_size = self.recipe_page_size
            end
        end
    end

    local selection_changed = previous_selected ~= self.selected_recipe_id
    state.selection_changed = selection_changed
    self._recipe_list_signature = signature
    self._recipe_list_loaded_count = loaded_count
    self._recipe_list_loading = loading
    self._recipe_list_row_width = row_w
    if pages_mode ~= true then
        self._recipe_list_page_size = 0
        self._recipe_page_rendered_start = 1
        self._recipe_page_rendered_end = 0
    end

    local has_items = #self.visible_recipes > 0
    self.recipe_list:SetVisible(has_items)
    self.recipe_scroll:SetVisible(has_items and pages_mode ~= true)
    self.recipe_page_bar:SetVisible(pages_mode == true)
    self.recipe_empty:SetVisible(has_items ~= true)
    if has_items ~= true then
        local progress = self.store:get_loading_progress()
        if progress.loading == true then
            self.recipe_empty:SetText(
                TR["Loading recipes"] .. " " ..
                _format_count(progress.loaded) .. " / " .. _format_count(progress.total)
            )
        else
            self.recipe_empty:SetText(TR["No matching recipes."])
        end
        if pages_mode == true then
            self.recipe_page_label:SetText("1 / 1")
            self.recipe_prev_button:set_enabled(false)
            self.recipe_next_button:set_enabled(false)
        end
    end

    if selection_changed == true and should_refresh_selected == true then
        self:refresh_selected_recipe()
    end

    return state
end

function CraftingWindow:_ingredient_detail_text(node)
    if node == nil then
        return ""
    end

    if node.ambiguous == true then
        return TR["Multiple known sub-recipes; auto-breakdown skipped"]
    end

    return ""
end

function CraftingWindow:_source_amount_text(breakdown, fallback_owned, required)
    local total = tonumber(required) or 0
    local owned = tonumber(fallback_owned) or 0
    if type(breakdown) == "table" then
        owned = tonumber(breakdown.total_owned) or owned
        total = tonumber(breakdown.required) or total
    end
    return _ratio_text(owned, total)
end

function CraftingWindow:_node_amount_text(node, source_breakdown)
    if type(node) ~= "table" then
        return ""
    end

    local owned_quantity = tonumber(node.from_stock)
    if owned_quantity == nil then
        owned_quantity = tonumber(node.owned_in_scope) or 0
    end
    return self:_source_amount_text(source_breakdown, owned_quantity, tonumber(node.required) or 0)
end

function CraftingWindow:_append_node_rows(list_box, row_w, node, indent_level, options)
    if list_box == nil or type(node) ~= "table" then
        return
    end

    local path_keys = type(options) == "table" and options.path_keys or nil
    if type(path_keys) == "table" and node.key ~= nil and path_keys[node.key] == true then
        return
    end

    local watch_keys = type(options) == "table" and options.watch_keys or nil
    if type(watch_keys) == "table" and node.key ~= nil then
        watch_keys[node.key] = true
    end

    local item = self:_item(node.key)
    local source_breakdown = self:_source_breakdown_for_item(node.key, node.required)
    local source_hint_text, source_hint_color = self:_source_breakdown_hint_text(source_breakdown)
    local row = CraftingIngredientRow()
    row:set_scale(_G.settings.global.scale)
    row:set_width(row_w)
    row:set_data(
        item ~= nil and item.item_info or nil,
        item ~= nil and item.icon_id or nil,
        item ~= nil and item.background_image_id or nil,
        item ~= nil and item.name or node.key,
        self:_ingredient_detail_text(node),
        self:_node_amount_text(node, source_breakdown),
        self:_node_status_color(node),
        indent_level,
        source_hint_text,
        source_hint_color
    )
    row:set_source_breakdown(
        source_breakdown,
        function(anchor_control, breakdown)
            self:_show_source_breakdown_hint(anchor_control, breakdown)
        end,
        function()
            self:_hide_source_breakdown_hint()
        end
    )
    list_box:AddItem(row)

    if type(node.children) ~= "table" then
        return
    end

    local child_options = options
    if node.key ~= nil then
        local next_path_keys = {}
        if type(path_keys) == "table" then
            for key, value in pairs(path_keys) do
                if value == true then
                    next_path_keys[key] = true
                end
            end
        end
        next_path_keys[node.key] = true

        child_options = {}
        if type(options) == "table" then
            for key, value in pairs(options) do
                child_options[key] = value
            end
        end
        child_options.path_keys = next_path_keys
    end

    for index = 1, #node.children do
        self:_append_node_rows(list_box, row_w, node.children[index], indent_level + 1, child_options)
    end
end

function CraftingWindow:_clear_critical_result_detail()
    self._critical_result_visible = false
    if self.critical_result_row ~= nil then
        self.critical_result_row:set_data(nil, nil, nil, "", "", TEXT_META)
        self.critical_result_row:SetVisible(false)
    end
end

function CraftingWindow:_refresh_critical_result_detail(recipe)
    self:_clear_critical_result_detail()
    if type(recipe) ~= "table" then
        return
    end

    local row_w = math.max(0, self.detail_panel.inner:GetWidth())
    local critical_item = self:_recipe_critical_result_item(recipe)
    if critical_item ~= nil then
        self._critical_result_visible = true
        self.critical_result_row:set_scale(_G.settings.global.scale)
        self.critical_result_row:set_width(row_w)
        self.critical_result_row:set_data(
            critical_item.item_info,
            critical_item.icon_id,
            critical_item.background_image_id,
            critical_item.name,
            self:_critical_result_detail(recipe),
            STATUS_AUTO
        )
        self.critical_result_row:SetVisible(true)
    end
end

function CraftingWindow:refresh_selected_recipe()
    self:_hide_source_breakdown_hint()
    _clear_list_box(self.ingredients_list)
    self._selected_recipe_watch_keys = {}

    local recipe = self:_selected_recipe()
    if recipe == nil then
        self:_clear_critical_result_detail()
        self:layout()
        self.detail_empty:SetVisible(true)
        self.detail_icon:bind_item(nil, nil, nil)
        self.detail_title:SetText("")
        self.detail_meta:SetText("")
        self.detail_status:SetText("")
        self.plan_spin_box:set_enabled(false)
        self.plan_spin_box:set_value(0, false)
        self.ingredients_list:SetVisible(false)
        self.ingredients_scroll:SetVisible(false)
        return
    end

    local evaluation = self.store:evaluate_recipe(recipe, self.scope_key, 1)
    local result_item = self:_recipe_result_item(recipe)
    local result_name = self:_recipe_result_name(recipe)
    local required_level = self:_recipe_required_level(recipe)
    self.detail_empty:SetVisible(false)
    self:_refresh_critical_result_detail(recipe)
    self:layout()

    self.detail_icon:bind_item(
        result_item ~= nil and result_item.item_info or nil,
        result_item ~= nil and result_item.icon_id or nil,
        result_item ~= nil and result_item.background_image_id or nil
    )

    self.detail_title:SetText(result_name)
    local meta_parts = {}
    if recipe.profession_name ~= "" then
        meta_parts[#meta_parts + 1] = recipe.profession_name
    end
    if required_level ~= nil then
        meta_parts[#meta_parts + 1] = TR["Level"] .. " " .. _format_count(required_level)
    end
    if recipe.category_name ~= "" then
        meta_parts[#meta_parts + 1] = recipe.category_name
    end
    if recipe.tier > 0 then
        meta_parts[#meta_parts + 1] = TR["Tier "] .. _format_count(recipe.tier)
    end
    if recipe.result_quantity > 1 then
        meta_parts[#meta_parts + 1] = TR["Makes x"] .. _format_count(recipe.result_quantity)
    end
    self.detail_meta:SetText(table.concat(meta_parts, " - "))
    self.detail_status:SetText(self:_status_text(evaluation))
    self.detail_status:SetForeColor(self:_status_color(evaluation))
    self.plan_spin_box:set_enabled(true)
    self.plan_spin_box:set_value(self.plan_counts[recipe.id] or 0, false)

    local row_w = self:_current_detail_list_width()
    local detail_node_options = {
        path_keys = {},
        watch_keys = self._selected_recipe_watch_keys,
    }
    if type(recipe.result_key) == "string" and recipe.result_key ~= "" then
        detail_node_options.path_keys[recipe.result_key] = true
    end
    if type(recipe.critical_result_key) == "string" and recipe.critical_result_key ~= "" then
        detail_node_options.path_keys[recipe.critical_result_key] = true
    end
    for i = 1, #evaluation.ingredients do
        self:_append_node_rows(self.ingredients_list, row_w, evaluation.ingredients[i], 0, detail_node_options)
    end

    self.ingredients_list:SetVisible(true)
    self.ingredients_scroll:SetVisible(true)
end

function CraftingWindow:_build_plan_entries()
    local entries = {}
    for i = 1, #self.plan_order do
        local recipe_id = self.plan_order[i]
        local count = tonumber(self.plan_counts[recipe_id]) or 0
        if count > 0 then
            entries[#entries + 1] = {
                recipe_id = recipe_id,
                count = count,
            }
        end
    end
    return entries
end

function CraftingWindow:refresh_plan()
    self:_hide_source_breakdown_hint()
    _clear_list_box(self.queue_list)
    _clear_list_box(self.plan_list)
    _clear_list_box(self.missing_list)
    self._plan_recipe_watch_keys = {}

    local draft_plan_entries = self:_build_plan_entries()
    local draft_resource_state = self.store:evaluate_plan_resources(draft_plan_entries, self.scope_key)
    local draft_evaluation = draft_resource_state.evaluation

    local tracked_resolved = Crafting.resolve_tracked_plan_entries(self.store)
    local tracked_plan_entries = tracked_resolved.entries or {}
    local tracked_unresolved_entries = tracked_resolved.unresolved_entries or {}

    local has_draft_plan = #draft_plan_entries > 0
    self:_refresh_plan_dirty_state()
    local has_saved_plan = (#tracked_plan_entries > 0) or (#tracked_unresolved_entries > 0)
    local show_saved_unresolved = #tracked_unresolved_entries > 0 and (self._plan_dirty ~= true or has_draft_plan ~= true)
    local has_queue_rows = has_draft_plan == true or show_saved_unresolved == true
    local has_plan_rows = has_draft_plan == true or show_saved_unresolved == true
    self.queue_empty:SetVisible(has_queue_rows ~= true)
    self.plan_empty:SetVisible(has_plan_rows ~= true)

    if has_draft_plan == true then
        local queue_summary_text =
            _format_count(#draft_plan_entries) .. " " .. TR["recipes"] ..
            " - " .. _ratio_text(draft_evaluation.craftable_count_total, draft_evaluation.planned_recipe_count)
        self.queue_summary:SetText(queue_summary_text)
    elseif show_saved_unresolved == true then
        self.queue_summary:SetText(_format_count(#tracked_unresolved_entries) .. " " .. TR["recipes"])
    else
        self.queue_summary:SetText(TR["No recipes planned"])
    end

    self.plan_track_button:set_enabled(self._plan_dirty == true)
    self.plan_revert_button:set_enabled(self._plan_dirty == true)
    self.plan_clear_button:set_enabled(has_draft_plan == true or has_saved_plan == true)

    local queue_w = self:_current_queue_list_width()
    local row_w = self:_current_plan_list_width()
    local loading_tracked = self.store:is_loading() == true
    for i = 1, #draft_evaluation.entries do
        local entry = draft_evaluation.entries[i]
        local queue_row = CraftingPlanRow(
            function(recipe, value)
                self:set_plan_count(recipe.id, value)
            end,
            function(recipe)
                self:set_plan_count(recipe.id, 0)
            end
        )
        queue_row:set_scale(_G.settings.global.scale)
        queue_row:set_width(queue_w)
        queue_row:set_data(
            entry.recipe,
            self:_recipe_result_item(entry.recipe),
            self:_recipe_result_name(entry.recipe),
            entry.count,
            entry.evaluation,
            entry.craftable_count
        )
        self.queue_list:AddItem(queue_row)
    end

    if show_saved_unresolved == true then
        for i = 1, #tracked_unresolved_entries do
            local unresolved_entry = tracked_unresolved_entries[i]
            local saved_entry = unresolved_entry ~= nil and unresolved_entry.saved_entry or nil
            local count = unresolved_entry ~= nil and (tonumber(unresolved_entry.count) or 0) or 0
            local queue_row = CraftingPlanRow(nil, nil)
            queue_row:set_scale(_G.settings.global.scale)
            queue_row:set_width(queue_w)
            queue_row:set_read_only(true)
            queue_row:set_placeholder_data(_display_name_from_saved_entry(saved_entry), count, loading_tracked)
            self.queue_list:AddItem(queue_row)
        end
    end

    for i = 1, #draft_evaluation.entries do
        local entry = draft_evaluation.entries[i]
        local plan_row = CraftingPlanRow(
            function(recipe, value)
                self:set_plan_count(recipe.id, value)
            end,
            function(recipe)
                self:set_plan_count(recipe.id, 0)
            end
        )
        plan_row:set_scale(_G.settings.global.scale)
        plan_row:set_width(row_w)
        plan_row:set_read_only(true)
        plan_row:set_data(
            entry.recipe,
            self:_recipe_result_item(entry.recipe),
            self:_recipe_result_name(entry.recipe),
            entry.count,
            entry.evaluation,
            entry.craftable_count
        )
        self.plan_list:AddItem(plan_row)

        local ingredients = entry.evaluation ~= nil and entry.evaluation.ingredients or nil
        if type(ingredients) == "table" then
            local plan_node_options = {
                path_keys = {},
                watch_keys = self._plan_recipe_watch_keys,
            }
            if type(entry.recipe.result_key) == "string" and entry.recipe.result_key ~= "" then
                plan_node_options.path_keys[entry.recipe.result_key] = true
            end
            if type(entry.recipe.critical_result_key) == "string" and entry.recipe.critical_result_key ~= "" then
                plan_node_options.path_keys[entry.recipe.critical_result_key] = true
            end
            for ingredient_index = 1, #ingredients do
                self:_append_node_rows(self.plan_list, row_w, ingredients[ingredient_index], 1, plan_node_options)
            end
        end
    end

    if show_saved_unresolved == true then
        for i = 1, #tracked_unresolved_entries do
            local unresolved_entry = tracked_unresolved_entries[i]
            local saved_entry = unresolved_entry ~= nil and unresolved_entry.saved_entry or nil
            local count = unresolved_entry ~= nil and (tonumber(unresolved_entry.count) or 0) or 0
            local plan_row = CraftingPlanRow(nil, nil)
            plan_row:set_scale(_G.settings.global.scale)
            plan_row:set_width(row_w)
            plan_row:set_read_only(true)
            plan_row:set_placeholder_data(_display_name_from_saved_entry(saved_entry), count, loading_tracked)
            self.plan_list:AddItem(plan_row)
        end
    end

    local missing_w = self:_current_missing_list_width()
    for i = 1, #draft_resource_state.resources do
        local entry = draft_resource_state.resources[i]
        local source_breakdown = entry.source_breakdown or self:_source_breakdown_for_item(entry.key, entry.required)
        local source_hint_text, source_hint_color = self:_source_breakdown_hint_text(source_breakdown)
        local row = CraftingIngredientRow()
        row:set_scale(_G.settings.global.scale)
        row:set_width(missing_w)
        row:set_data(
            entry.item_info,
            entry.icon_id,
            entry.background_image_id,
            entry.name,
            "",
            self:_source_amount_text(source_breakdown, entry.owned, entry.required),
            entry.complete == true and STATUS_READY or STATUS_MISSING,
            0,
            source_hint_text,
            source_hint_color
        )
        row:set_source_breakdown(
            source_breakdown,
            function(anchor_control, breakdown)
                self:_show_source_breakdown_hint(anchor_control, breakdown)
            end,
            function()
                self:_hide_source_breakdown_hint()
            end
        )
        self.missing_list:AddItem(row)
    end

    self.queue_list:SetVisible(has_queue_rows == true)
    self.queue_scroll:SetVisible(has_queue_rows == true)
    self.plan_list:SetVisible(has_plan_rows == true)
    self.plan_scroll:SetVisible(has_plan_rows == true)
    self.missing_list:SetVisible(#draft_resource_state.resources > 0)
    self.missing_scroll:SetVisible(#draft_resource_state.resources > 0)

    local selected_recipe = self:_selected_recipe()
    if selected_recipe ~= nil then
        self.plan_spin_box:set_enabled(true)
        self.plan_spin_box:set_value(self.plan_counts[selected_recipe.id] or 0, false)
    else
        self.plan_spin_box:set_enabled(false)
        self.plan_spin_box:set_value(0, false)
    end
end

function CraftingWindow:adjust_plan_count(recipe_id, delta)
    local next_count = (tonumber(self.plan_counts[recipe_id]) or 0) + (tonumber(delta) or 0)
    self:set_plan_count(recipe_id, next_count)
end

function CraftingWindow:set_plan_count(recipe_id, count)
    if recipe_id == nil then
        return
    end

    local next_count = math.floor((tonumber(count) or 0) + 0.5)
    if next_count < 0 then
        next_count = 0
    end

    local previous_count = math.floor((tonumber(self.plan_counts[recipe_id]) or 0) + 0.5)
    if previous_count < 0 then
        previous_count = 0
    end
    if previous_count == next_count then
        return
    end

    if next_count == 0 then
        self.plan_counts[recipe_id] = nil
        for i = #self.plan_order, 1, -1 do
            if self.plan_order[i] == recipe_id then
                table.remove(self.plan_order, i)
            end
        end
    else
        if self.plan_counts[recipe_id] == nil then
            self.plan_order[#self.plan_order + 1] = recipe_id
        end
        self.plan_counts[recipe_id] = next_count
    end

    self._plan_user_changed = true
    self:_refresh_plan_dirty_state()
    self:refresh_selected_recipe()
    self:refresh_plan()
end

function CraftingWindow:track_plan()
    if self.store == nil then
        return
    end

    local saved_entries = self.store:serialize_plan_entries(self:_build_plan_entries())
    Crafting.set_tracked_plan_entries(saved_entries, true)
    self._plan_user_changed = false
    self._plan_dirty = false
    self:refresh_plan()
end

function CraftingWindow:revert_plan()
    self._plan_user_changed = false
    self:_sync_draft_plan_from_tracked()
    self._plan_dirty = false
    self:refresh_selected_recipe()
    self:refresh_plan()
end

function CraftingWindow:clear_plan()
    self.plan_order = {}
    self.plan_counts = {}
    Crafting.set_tracked_plan_entries({}, true)
    self._plan_user_changed = false
    self._plan_dirty = false
    self:refresh_selected_recipe()
    self:refresh_plan()
end

function CraftingWindow:refresh_loading_state()
    local progress = self.store:get_loading_progress()
    local should_show = progress.loading == true
    local visibility_changed = self._loading_visible ~= should_show
    self._loading_visible = should_show

    self.loading_panel:SetVisible(should_show)
    if should_show == true then
        self.loading_text:SetText(
            TR["Loading recipes"] .. " " ..
            _format_count(progress.loaded) .. " / " .. _format_count(progress.total)
        )

        local inner_w = self.loading_track_inner:GetWidth()
        local inner_h = self.loading_track_inner:GetHeight()
        local fill_w = 0
        if progress.total > 0 and inner_w > 0 then
            fill_w = math.floor((inner_w * progress.loaded) / progress.total)
            if fill_w < 0 then
                fill_w = 0
            elseif fill_w > inner_w then
                fill_w = inner_w
            end
        end
        self.loading_fill:SetPosition(0, 0)
        self.loading_fill:SetSize(fill_w, inner_h)
        self.loading_fill:SetVisible(fill_w > 0 and inner_h > 0)
    end

    if visibility_changed == true then
        self:layout()
    end
    return visibility_changed
end

function CraftingWindow:layout()
    local width, height = self:get_content_size()
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_top = _scaled_int(BASE_MARGIN_TOP)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local margin_bottom = _scaled_int(BASE_MARGIN_BOTTOM)
    local gap = _scaled_int(BASE_GAP)
    local bar_h = _scaled_int(BASE_BAR_H)
    local clear_w = _scaled_int(BASE_CLEAR_W)
    local favorite_filter_w = _favorite_icon_size()
    local revert_w = _scaled_int(62)
    local track_w = _scaled_int(78)
    local loading_panel_h = self._loading_visible == true and _scaled_int(BASE_LOADING_PANEL_H) or 0
    local right_w = math.max(_scaled_int(BASE_RIGHT_W), math.floor((width - margin_left - margin_right) * 0.38))
    local left_w = width - margin_left - margin_right - gap - right_w
    if left_w < _scaled_int(280) then
        left_w = _scaled_int(280)
        right_w = width - margin_left - margin_right - gap - left_w
    end
    local top_row_h = math.max(bar_h, favorite_filter_w)
    local top_bar_h = top_row_h + gap + bar_h
    local content_top = margin_top + top_bar_h + gap
    local content_bottom_gap = loading_panel_h > 0 and gap or 0
    local content_h = height - content_top - margin_bottom - loading_panel_h - content_bottom_gap
    if content_h < 0 then
        content_h = 0
    end
    local scroll_w = _fixed_int(BASE_SCROLL_W)
    local plan_header_h = _scaled_int(BASE_PLAN_HEADER_H)
    local section_bar_h = plan_header_h
    local detail_top_h = math.max(0, _scaled_int(BASE_DETAIL_HEADER_H) - section_bar_h)
    local critical_result_h = self._critical_result_visible == true and _scaled_int(BASE_CRITICAL_RESULT_ROW_H) or 0
    local detail_header_h = detail_top_h + critical_result_h + section_bar_h
    local plan_controls_w = _scaled_int(BASE_PLAN_CONTROLS_W)
    local loading_track_h = _scaled_int(BASE_LOADING_TRACK_H)
    local pages_mode = self.display_mode == DISPLAY_PAGES

    self.top_bar:SetPosition(margin_left, margin_top)
    self.top_bar:SetSize(width - margin_left - margin_right, top_bar_h)

    local top_control_y = math.max(0, math.floor((top_row_h - bar_h) / 2))
    local favorite_filter_y = math.max(0, math.floor((top_row_h - favorite_filter_w) / 2))
    self.search_box:SetPosition(0, top_control_y)
    self.search_box:SetSize(self.top_bar:GetWidth() - clear_w - favorite_filter_w - (gap * 2), bar_h)
    self.favorite_filter_button:SetPosition(self.top_bar:GetWidth() - clear_w - gap - favorite_filter_w, favorite_filter_y)
    self.favorite_filter_button:SetSize(favorite_filter_w, favorite_filter_w)
    self.clear_button:SetPosition(self.top_bar:GetWidth() - clear_w, top_control_y)
    self.clear_button:SetSize(clear_w, bar_h)

    local row2_y = top_row_h + gap
    local label_gap = _scaled_int(4)
    local group_gap = _scaled_int(18)
    local scope_label_w = _scaled_int(56)
    local scope_w = _scaled_int(152)
    local profession_label_w = _scaled_int(54)
    local profession_w = _scaled_int(140)
    local availability_label_w = _scaled_int(34)
    local availability_w = _scaled_int(78)
    local level_label_w = _scaled_int(54)
    local level_box_w = _scaled_int(BASE_LEVEL_BOX_W)
    local level_dash_w = _scaled_int(BASE_LEVEL_DASH_W)
    local row2_right = self.top_bar:GetWidth()
    self.level_max_box:SetPosition(row2_right - level_box_w, row2_y)
    self.level_max_box:SetSize(level_box_w, bar_h)
    self.level_dash_label:SetPosition(row2_right - level_box_w - gap - level_dash_w, row2_y)
    self.level_dash_label:SetSize(level_dash_w, bar_h)
    self.level_min_box:SetPosition(row2_right - (level_box_w * 2) - (gap * 2) - level_dash_w, row2_y)
    self.level_min_box:SetSize(level_box_w, bar_h)
    self.level_label:SetPosition(row2_right - (level_box_w * 2) - (gap * 2) - label_gap - level_dash_w - level_label_w, row2_y)
    self.level_label:SetSize(level_label_w, bar_h)

    local row2_left = 0
    self.profession_label:SetPosition(row2_left, row2_y)
    self.profession_label:SetSize(profession_label_w, bar_h)
    row2_left = row2_left + profession_label_w + label_gap
    self.profession_dropdown:SetPosition(row2_left, row2_y)
    self.profession_dropdown:SetSize(profession_w, bar_h)
    row2_left = row2_left + profession_w + group_gap

    self.scope_label:SetPosition(row2_left, row2_y)
    self.scope_label:SetSize(scope_label_w, bar_h)
    row2_left = row2_left + scope_label_w + label_gap
    self.scope_dropdown:SetPosition(row2_left, row2_y)
    self.scope_dropdown:SetSize(scope_w, bar_h)
    row2_left = row2_left + scope_w + group_gap

    self.availability_label:SetPosition(row2_left, row2_y)
    self.availability_label:SetSize(availability_label_w, bar_h)
    row2_left = row2_left + availability_label_w + label_gap
    self.availability_dropdown:SetPosition(row2_left, row2_y)
    self.availability_dropdown:SetSize(availability_w, bar_h)

    self.left_panel:SetPosition(margin_left, content_top)
    self.left_panel:SetSize(left_w, content_h)
    _fit_inner_border(self.left_panel)

    local recipe_inner_w = self.left_panel.inner:GetWidth()
    local recipe_inner_h = self.left_panel.inner:GetHeight()
    local page_h = pages_mode == true and bar_h or 0
    local page_gap = pages_mode == true and gap or 0
    local recipe_list_h = recipe_inner_h - page_h - page_gap
    if recipe_list_h < 0 then
        recipe_list_h = 0
    end

    if pages_mode == true then
        self.recipe_scroll:SetPosition(recipe_inner_w, 0)
        self.recipe_scroll:SetSize(0, 0)
        self.recipe_list:SetPosition(0, 0)
        self.recipe_list:SetSize(recipe_inner_w, recipe_list_h)
    else
        self.recipe_scroll:SetPosition(recipe_inner_w - scroll_w, 0)
        self.recipe_scroll:SetSize(scroll_w, recipe_inner_h)
        self.recipe_list:SetPosition(0, 0)
        self.recipe_list:SetSize(recipe_inner_w - scroll_w, recipe_inner_h)
    end

    self.recipe_page_bar:SetPosition(0, recipe_list_h + page_gap)
    self.recipe_page_bar:SetSize(recipe_inner_w, page_h)
    self.recipe_page_bar:SetVisible(pages_mode == true)
    if pages_mode == true then
        local page_label_w = _scaled_int(BASE_PAGE_LABEL_W)
        local nav_w = bar_h
        local pager_w = (nav_w * 2) + page_label_w + (gap * 2)
        local pager_x = math.floor((recipe_inner_w - pager_w) / 2)
        if pager_x < 0 then
            pager_x = 0
        end
        self.recipe_prev_button:SetPosition(pager_x, 0)
        self.recipe_prev_button:SetSize(nav_w, page_h)
        self.recipe_page_label:SetPosition(pager_x + nav_w + gap, 0)
        self.recipe_page_label:SetSize(page_label_w, page_h)
        self.recipe_next_button:SetPosition(pager_x + nav_w + gap + page_label_w + gap, 0)
        self.recipe_next_button:SetSize(nav_w, page_h)
    end
    self.recipe_empty:SetPosition(_scaled_int(8), _scaled_int(8))
    self.recipe_empty:SetSize(
        math.max(0, recipe_inner_w - _scaled_int(16)),
        math.max(0, recipe_list_h - _scaled_int(16))
    )

    self.right_panel:SetPosition(margin_left + left_w + gap, content_top)
    self.right_panel:SetSize(right_w, content_h)

    self.right_tab_bar:SetPosition(0, 0)
    self.right_tab_bar:SetSize(right_w, content_h)
    if self.right_tab_bar._layout ~= nil then
        self.right_tab_bar:_layout()
    end

    local recipe_page_w = 0
    local recipe_page_h = 0
    if self.right_tab_bar._content_inner ~= nil then
        recipe_page_w, recipe_page_h = self.right_tab_bar._content_inner:GetSize()
    end
    if recipe_page_w <= 0 or recipe_page_h <= 0 then
        recipe_page_w, recipe_page_h = self.recipe_page:GetSize()
    end
    self.recipe_page:SetPosition(0, 0)
    self.recipe_page:SetSize(recipe_page_w, recipe_page_h)
    self.plan_page:SetPosition(0, 0)
    self.plan_page:SetSize(recipe_page_w, recipe_page_h)

    local split_gap = _fixed_int(BASE_SECTION_SPLIT_H)
    local recipe_detail_h = math.max(0, math.floor((recipe_page_h - split_gap) * 0.5))
    local queue_h = math.max(0, recipe_page_h - recipe_detail_h - split_gap)

    self.detail_panel:SetPosition(0, 0)
    self.detail_panel:SetSize(recipe_page_w, recipe_detail_h)
    _fit_inner_border(self.detail_panel)
    self.recipe_split_border:SetPosition(0, recipe_detail_h)
    self.recipe_split_border:SetSize(recipe_page_w, split_gap)

    local detail_inner = self.detail_panel.inner
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local detail_icon_y = math.max(0, math.floor((detail_top_h - icon_side) / 2))
    self.detail_icon:SetPosition(_scaled_int(8), detail_icon_y)
    self.detail_icon:set_side(icon_side)
    self.detail_title:SetPosition(_scaled_int(8) + icon_side + gap, _scaled_int(6))
    self.detail_title:SetSize(detail_inner:GetWidth() - icon_side - _scaled_int(16) - gap, _scaled_int(24))
    self.detail_meta:SetPosition(_scaled_int(8) + icon_side + gap, _scaled_int(28))
    self.detail_meta:SetSize(detail_inner:GetWidth() - icon_side - _scaled_int(16) - gap, _scaled_int(20))
    self.detail_status:SetPosition(_scaled_int(8), _scaled_int(48))
    self.detail_status:SetSize(detail_inner:GetWidth() - _scaled_int(16) - plan_controls_w, _scaled_int(22))

    local plan_controls_x = detail_inner:GetWidth() - plan_controls_w
    self.plan_label:SetPosition(plan_controls_x, _scaled_int(6))
    self.plan_label:SetSize(plan_controls_w, _scaled_int(16))
    self.plan_spin_box:SetPosition(plan_controls_x, _scaled_int(24))
    self.plan_spin_box:SetSize(plan_controls_w, bar_h)

    if self.critical_result_row ~= nil then
        self.critical_result_row:SetPosition(0, detail_top_h)
        self.critical_result_row:set_width(detail_inner:GetWidth())
        self.critical_result_row:SetVisible(self._critical_result_visible == true)
    end

    local ingredients_header_y = detail_top_h + critical_result_h
    if ingredients_header_y < 0 then
        ingredients_header_y = 0
    end
    self.ingredients_header_bar:SetPosition(0, ingredients_header_y)
    self.ingredients_header_bar:SetSize(detail_inner:GetWidth(), section_bar_h)
    self.ingredients_title:SetPosition(_scaled_int(8), ingredients_header_y)
    self.ingredients_title:SetSize(detail_inner:GetWidth() - _scaled_int(16), section_bar_h)

    local ingredient_list_top = detail_header_h
    local ingredient_list_h = detail_inner:GetHeight() - ingredient_list_top
    if ingredient_list_h < 0 then
        ingredient_list_h = 0
    end
    self.ingredients_scroll:SetPosition(detail_inner:GetWidth() - scroll_w, ingredient_list_top)
    self.ingredients_scroll:SetSize(scroll_w, ingredient_list_h)
    self.ingredients_list:SetPosition(0, ingredient_list_top)
    self.ingredients_list:SetSize(detail_inner:GetWidth() - scroll_w, ingredient_list_h)
    self.detail_empty:SetPosition(_scaled_int(8), ingredient_list_top)
    self.detail_empty:SetSize(detail_inner:GetWidth() - _scaled_int(16), ingredient_list_h)

    self.queue_panel:SetPosition(0, recipe_detail_h + split_gap)
    self.queue_panel:SetSize(recipe_page_w, queue_h)
    _fit_inner_border(self.queue_panel)

    local queue_inner = self.queue_panel.inner
    self.queue_header_bar:SetPosition(0, 0)
    self.queue_header_bar:SetSize(queue_inner:GetWidth(), section_bar_h)
    self.queue_title:SetPosition(_scaled_int(8), 0)
    self.queue_title:SetSize(_scaled_int(90), section_bar_h)
    self.queue_summary:SetPosition(_scaled_int(104), 0)
    self.queue_summary:SetSize(queue_inner:GetWidth() - _scaled_int(112), section_bar_h)
    local queue_list_top = section_bar_h
    local queue_list_h = queue_inner:GetHeight() - queue_list_top
    if queue_list_h < 0 then
        queue_list_h = 0
    end
    self.queue_scroll:SetPosition(queue_inner:GetWidth() - scroll_w, queue_list_top)
    self.queue_scroll:SetSize(scroll_w, queue_list_h)
    self.queue_list:SetPosition(0, queue_list_top)
    self.queue_list:SetSize(queue_inner:GetWidth() - scroll_w, queue_list_h)
    self.queue_empty:SetPosition(_scaled_int(8), queue_list_top)
    self.queue_empty:SetSize(queue_inner:GetWidth() - _scaled_int(16), queue_list_h)

    self.plan_panel:SetPosition(0, 0)
    self.plan_panel:SetSize(self.plan_page:GetWidth(), self.plan_page:GetHeight())
    _fit_inner_border(self.plan_panel)

    local plan_inner = self.plan_panel.inner
    self.plan_header_bar:SetPosition(0, 0)
    self.plan_header_bar:SetSize(plan_inner:GetWidth(), section_bar_h)
    self.plan_title:SetPosition(_scaled_int(8), 0)
    self.plan_title:SetSize(_scaled_int(90), section_bar_h)
    self.plan_track_button:SetPosition(
        plan_inner:GetWidth() - clear_w - revert_w - track_w - _scaled_int(12),
        _scaled_int(2)
    )
    self.plan_track_button:SetSize(track_w, bar_h)
    self.plan_revert_button:SetPosition(plan_inner:GetWidth() - clear_w - revert_w - _scaled_int(10), _scaled_int(2))
    self.plan_revert_button:SetSize(revert_w, bar_h)
    self.plan_clear_button:SetPosition(plan_inner:GetWidth() - clear_w - _scaled_int(8), _scaled_int(2))
    self.plan_clear_button:SetSize(clear_w, bar_h)

    local plan_list_top = section_bar_h
    local plan_list_h = math.max(_scaled_int(90), math.floor((plan_inner:GetHeight() - plan_list_top - section_bar_h - gap) * 0.56))
    self.plan_scroll:SetPosition(plan_inner:GetWidth() - scroll_w, plan_list_top)
    self.plan_scroll:SetSize(scroll_w, plan_list_h)
    self.plan_list:SetPosition(0, plan_list_top)
    self.plan_list:SetSize(plan_inner:GetWidth() - scroll_w, plan_list_h)

    local missing_split_y = plan_list_top + plan_list_h
    self.plan_resources_border:SetPosition(0, missing_split_y)
    self.plan_resources_border:SetSize(plan_inner:GetWidth(), split_gap)

    local missing_top = missing_split_y + split_gap
    self.missing_header_bar:SetPosition(0, missing_top)
    self.missing_header_bar:SetSize(plan_inner:GetWidth(), section_bar_h)
    self.missing_title:SetPosition(_scaled_int(8), missing_top)
    self.missing_title:SetSize(plan_inner:GetWidth() - _scaled_int(16), section_bar_h)
    local missing_list_top = missing_top + section_bar_h
    local missing_list_h = plan_inner:GetHeight() - missing_list_top
    if missing_list_h < 0 then
        missing_list_h = 0
    end
    self.missing_scroll:SetPosition(plan_inner:GetWidth() - scroll_w, missing_list_top)
    self.missing_scroll:SetSize(scroll_w, missing_list_h)
    self.missing_list:SetPosition(0, missing_list_top)
    self.missing_list:SetSize(plan_inner:GetWidth() - scroll_w, missing_list_h)

    self.plan_empty:SetPosition(_scaled_int(8), plan_list_top)
    self.plan_empty:SetSize(plan_inner:GetWidth() - _scaled_int(16), plan_list_h)

    self.loading_panel:SetPosition(margin_left, height - margin_bottom - loading_panel_h)
    self.loading_panel:SetSize(width - margin_left - margin_right, loading_panel_h)
    if self._loading_visible == true then
        _fit_inner_border(self.loading_panel)
        local loading_inner = self.loading_panel.inner
        self.loading_text:SetPosition(_scaled_int(8), _scaled_int(4))
        self.loading_text:SetSize(loading_inner:GetWidth() - _scaled_int(16), _scaled_int(16))

        local track_y = loading_inner:GetHeight() - loading_track_h - _scaled_int(6)
        if track_y < 0 then
            track_y = 0
        end
        self.loading_track:SetPosition(_scaled_int(8), track_y)
        self.loading_track:SetSize(loading_inner:GetWidth() - _scaled_int(16), loading_track_h)
        self.loading_track_inner:SetPosition(1, 1)
        self.loading_track_inner:SetSize(
            math.max(0, self.loading_track:GetWidth() - 2),
            math.max(0, self.loading_track:GetHeight() - 2)
        )
    end
    self:refresh_loading_state()
end
