import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"

Crafting = Crafting or {}

local FILTER_ALL = "__all"
local AVAILABILITY_ALL = "all"
local AVAILABILITY_READY = "ready"
local AVAILABILITY_MISSING = "missing"
local SCOPE_PERSONAL = "personal"

local BASE_MARGIN_LEFT = 15
local BASE_MARGIN_TOP = 33
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
local BASE_TITLE_FONT = 14
local BASE_BODY_FONT = 11
local BASE_META_FONT = 10
local BASE_BUTTON_FONT = 10
local BASE_ICON_SIDE = 32
local BASE_SCROLL_W = 10
local BASE_PANEL_BORDER = 1
local BASE_DETAIL_HEADER_H = 78
local BASE_PLAN_HEADER_H = 24
local BASE_PLAN_CONTROLS_W = 102
local BASE_PLAN_QTY_W = 28
local BASE_SMALL_BUTTON_W = 22
local BASE_STATUS_W = 120
local BASE_LEVEL_LABEL_W = 40
local BASE_LEVEL_BOX_W = 44
local BASE_LEVEL_DASH_W = 14
local BASE_LOADING_PANEL_H = 34
local BASE_LOADING_TRACK_H = 10
local ITEM_INFO_CONTROL_OFFSET = -3
local ITEM_INFO_CONTROL_EXTRA = 3

local PANEL_BACK = Turbine.UI.Color(1.00, 0.07, 0.08, 0.10)
local PANEL_BORDER = Turbine.UI.Color(1.00, 0.19, 0.22, 0.28)
local SECTION_BACK = Turbine.UI.Color(1.00, 0.09, 0.11, 0.13)
local SELECTED_BACK = Turbine.UI.Color(1.00, 0.15, 0.22, 0.32)
local HOVER_BACK = Turbine.UI.Color(1.00, 0.12, 0.14, 0.18)
local TEXT_MAIN = Turbine.UI.Color(1.00, 0.92, 0.95, 0.98)
local TEXT_META = Turbine.UI.Color(1.00, 0.64, 0.70, 0.78)
local STATUS_READY = Turbine.UI.Color(1.00, 0.31, 0.78, 0.43)
local STATUS_MISSING = Turbine.UI.Color(1.00, 0.86, 0.30, 0.30)
local STATUS_AUTO = Turbine.UI.Color(1.00, 0.35, 0.75, 0.90)

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

local function _fixed_int(value)
    return math.floor(value + 0.5)
end

local function _safe_number(value, fallback)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return fallback
    end
    return value
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

local function _format_count(value)
    local number = math.max(0, math.floor(_safe_number(value, 0) + 0.5))
    return tostring(number)
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
    control.inner:SetPosition(BASE_PANEL_BORDER, BASE_PANEL_BORDER)
    control.inner:SetBackColor(fill)
end

local function _fit_inner_border(control)
    if control == nil or control.inner == nil then
        return
    end
    local width, height = control:GetSize()
    control.inner:SetSize(
        math.max(0, width - (BASE_PANEL_BORDER * 2)),
        math.max(0, height - (BASE_PANEL_BORDER * 2))
    )
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
        for i = list:GetItemCount(), 1, -1 do
            local item = list:GetItem(i)
            if item ~= nil and list.RemoveItemAt ~= nil then
                list:RemoveItemAt(i)
            end
            _destroy_control(item)
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

local CraftingRecipeRow = class(Turbine.UI.Control)

function CraftingRecipeRow:Constructor(on_click)
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._selected = false
    self._hover = false
    self._on_click = on_click
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
end

function CraftingRecipeRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_RECIPE_ROW_H))
    self:_layout()
end

function CraftingRecipeRow:set_selected(selected)
    self._selected = selected == true
    self:_refresh_visual()
end

function CraftingRecipeRow:set_data(recipe, status)
    self.recipe = recipe
    self.status = status

    local title = recipe ~= nil and recipe.result_name or ""
    local subtitle_parts = {}
    if recipe ~= nil and recipe.profession_name ~= "" then
        subtitle_parts[#subtitle_parts + 1] = recipe.profession_name
    end
    if recipe ~= nil and recipe.required_level ~= nil then
        subtitle_parts[#subtitle_parts + 1] = TR["Level"] .. " " .. _format_count(recipe.required_level)
    end
    if recipe ~= nil and recipe.category_name ~= "" then
        subtitle_parts[#subtitle_parts + 1] = recipe.category_name
    end
    if recipe ~= nil and recipe.name ~= "" and _lower(recipe.name) ~= _lower(recipe.result_name) then
        subtitle_parts[#subtitle_parts + 1] = recipe.name
    end

    self.title:SetText(title)
    self.subtitle:SetText(table.concat(subtitle_parts, " - "))
    self.status_label:SetText(CraftingWindow._status_text(nil, status))
    self.status_label:SetForeColor(CraftingWindow._status_color(nil, status))

    if recipe ~= nil then
        self.icon:bind_item(recipe.result_item_info, recipe.icon_id, recipe.background_image_id)
    else
        self.icon:bind_item(nil, nil, nil)
    end

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
    local text_left = strip_w + gap + icon_side + gap
    local text_w = width - text_left - gap - status_w
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

    self.status_label:SetPosition(width - status_w - gap, 0)
    self.status_label:SetSize(status_w, height)
end

function CraftingRecipeRow:destroy()
    _destroy_control(self.icon)
    self:SetVisible(false)
end

local CraftingIngredientRow = class(Turbine.UI.Control)

function CraftingIngredientRow:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self._scale = 1

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

    self.amount = UI.Widgets.LuiLabel()
    self.amount:SetParent(self)
    self.amount:SetMouseVisible(false)
    self.amount:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
end

function CraftingIngredientRow:set_scale(scale)
    self._scale = scale
    self.name:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.detail:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.amount:SetFont(_scaled_font("Verdana", BASE_META_FONT))
end

function CraftingIngredientRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_INGREDIENT_ROW_H))
    self:_layout()
end

function CraftingIngredientRow:set_data(item_info, icon_id, background_image_id, label_text, detail_text, amount_text, color)
    self.icon:bind_item(item_info, icon_id, background_image_id)
    self.name:SetText(label_text or "")
    self.detail:SetText(detail_text or "")
    self.amount:SetText(amount_text or "")
    self.amount:SetForeColor(color or TEXT_META)
    self.status_strip:SetBackColor(color or TEXT_META)
    self:SetBackColor(SECTION_BACK)
end

function CraftingIngredientRow:_layout()
    local width, height = self:GetSize()
    local gap = _scaled_int(BASE_GAP)
    local strip_w = _scaled_int(3)
    local amount_w = _scaled_int(86)
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    local icon_pad = _scaled_int(1)
    local max_icon_side = height - (icon_pad * 2)
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    if icon_side < 0 then
        icon_side = 0
    end
    local left = strip_w + gap + icon_side + gap
    local text_w = width - left - gap - amount_w
    local title_h = math.floor(height * 0.55)

    self.status_strip:SetPosition(0, 0)
    self.status_strip:SetSize(strip_w, height)

    self.icon:SetPosition(strip_w + gap, math.max(icon_pad, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)

    self.name:SetPosition(left, 0)
    self.name:SetSize(math.max(0, text_w), title_h)
    self.detail:SetPosition(left, title_h)
    self.detail:SetSize(math.max(0, text_w), height - title_h)

    self.amount:SetPosition(width - amount_w - gap, 0)
    self.amount:SetSize(amount_w, height)
end

function CraftingIngredientRow:destroy()
    _destroy_control(self.icon)
    self:SetVisible(false)
end

local CraftingPlanRow = class(Turbine.UI.Control)

function CraftingPlanRow:Constructor(on_minus, on_plus, on_remove)
    Turbine.UI.Control.Constructor(self)

    self._scale = 1
    self._on_minus = on_minus
    self._on_plus = on_plus
    self._on_remove = on_remove
    self.recipe = nil

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

    self.minus_button = UI.Widgets.LuiButton()
    self.minus_button:SetParent(self)
    self.minus_button:set_text("-")
    self.minus_button.Click = function()
        if self.recipe ~= nil and type(self._on_minus) == "function" then
            self._on_minus(self.recipe)
        end
    end

    self.count_label = UI.Widgets.LuiLabel()
    self.count_label:SetParent(self)
    self.count_label:SetMouseVisible(false)
    self.count_label:SetForeColor(TEXT_MAIN)
    self.count_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.plus_button = UI.Widgets.LuiButton()
    self.plus_button:SetParent(self)
    self.plus_button:set_text("+")
    self.plus_button.Click = function()
        if self.recipe ~= nil and type(self._on_plus) == "function" then
            self._on_plus(self.recipe)
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
    self.count_label:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.minus_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.plus_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.remove_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
end

function CraftingPlanRow:set_width(width)
    self:SetSize(width, _scaled_int(BASE_PLAN_ROW_H))
    self:_layout()
end

function CraftingPlanRow:set_data(recipe, plan_count, evaluation)
    self.recipe = recipe
    if recipe ~= nil then
        self.icon:bind_item(recipe.result_item_info, recipe.icon_id, recipe.background_image_id)
    else
        self.icon:bind_item(nil, nil, nil)
    end
    self.name:SetText(recipe ~= nil and recipe.result_name or "")
    self.count_label:SetText(_format_count(plan_count))
    self.status_label:SetText(CraftingWindow._status_text(nil, evaluation))
    self.status_label:SetForeColor(CraftingWindow._status_color(nil, evaluation))
    self:SetBackColor(evaluation ~= nil and evaluation.craftable == true and Turbine.UI.Color(1.00, 0.09, 0.15, 0.11) or
        Turbine.UI.Color(1.00, 0.16, 0.09, 0.09))
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
    local count_w = _scaled_int(BASE_PLAN_QTY_W)
    local status_w = _scaled_int(BASE_STATUS_W)
    local remove_w = button_w
    local right = width - gap

    self.remove_button:SetSize(remove_w, height - _scaled_int(2))
    right = right - remove_w
    self.remove_button:SetPosition(right, _scaled_int(1))

    right = right - gap
    self.plus_button:SetSize(button_w, height - _scaled_int(2))
    right = right - button_w
    self.plus_button:SetPosition(right, _scaled_int(1))

    right = right - gap
    self.count_label:SetPosition(right - count_w, 0)
    self.count_label:SetSize(count_w, height)
    right = right - count_w

    right = right - gap
    self.minus_button:SetSize(button_w, height - _scaled_int(2))
    right = right - button_w
    self.minus_button:SetPosition(right, _scaled_int(1))

    right = right - gap
    self.status_label:SetPosition(right - status_w, 0)
    self.status_label:SetSize(status_w, height)
    right = right - status_w

    self.icon:SetPosition(gap, math.max(icon_pad, math.floor((height - icon_side) / 2)))
    self.icon:set_side(icon_side)

    self.name:SetPosition(gap + icon_side + gap, 0)
    self.name:SetSize(math.max(0, right - ((gap * 3) + icon_side)), height)
end

function CraftingPlanRow:destroy()
    _destroy_control(self.icon)
    self:SetVisible(false)
end

CraftingWindow = class(Turbine.UI.Lotro.Window)
Crafting.CraftingWindow = CraftingWindow

function CraftingWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetText(TR["Crafting"])
    self:SetVisible(false)
    self:SetResizable(true)
    self:SetWantsUpdates(false)

    self._suppress_size_changed = false
    self._last_update_at = 0
    self.update_every = 0.75
    self._loading_visible = false
    self.store = Crafting.get_shared_store ~= nil and Crafting.get_shared_store() or Crafting.CraftingStore()
    self._last_store_version = _safe_number(self.store ~= nil and self.store.version or nil, 0)
    self.search_groups = {}
    self.scope_key = SCOPE_PERSONAL
    self.profession_filter = FILTER_ALL
    self.availability_filter = AVAILABILITY_ALL
    self.level_min_filter = nil
    self.level_max_filter = nil
    self.selected_recipe_id = nil
    self.visible_recipes = {}
    self.plan_order = {}
    self.plan_counts = {}
    self.material_filter_keys = nil
    self._recipe_list_signature = nil
    self._recipe_list_loaded_count = 0
    self._recipe_list_loading = false
    self._recipe_list_row_width = 0

    self.top_bar = Turbine.UI.Control()
    self.top_bar:SetParent(self)

    self.search_box = Turbine.UI.Lotro.TextBox()
    self.search_box:SetParent(self.top_bar)
    self.search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.search_box.TextChanged = function()
        self.search_groups = _normalize_query_groups(_parse_query(self.search_box:GetText()))
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
    end

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.top_bar)
    self.clear_button:set_text(TR["Clear"])
    self.clear_button.Click = function()
        self.search_box:SetText("")
        self.search_groups = {}
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self.search_box:Focus()
    end

    self.scope_label = UI.Widgets.LuiLabel()
    self.scope_label:SetParent(self.top_bar)
    self.scope_label:SetMouseVisible(false)
    self.scope_label:SetForeColor(TEXT_META)
    self.scope_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.scope_label:SetText(TR["Check craftability with:"])

    self.scope_dropdown = UI.Widgets.LuiDropdown()
    self.scope_dropdown:SetParent(self.top_bar)
    self.scope_dropdown:SetPopupHost(self)
    self.scope_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.scope_dropdown.ValueChanged = function(_, value)
        self.scope_key = value or SCOPE_PERSONAL
        self:refresh_recipe_list()
        self:refresh_selected_recipe()
        self:refresh_plan()
    end

    self.profession_label = UI.Widgets.LuiLabel()
    self.profession_label:SetParent(self.top_bar)
    self.profession_label:SetMouseVisible(false)
    self.profession_label:SetForeColor(TEXT_META)
    self.profession_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.profession_label:SetText(TR["Profession:"])

    self.profession_dropdown = UI.Widgets.LuiDropdown()
    self.profession_dropdown:SetParent(self.top_bar)
    self.profession_dropdown:SetPopupHost(self)
    self.profession_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.profession_dropdown.ValueChanged = function(_, value)
        self.profession_filter = value or FILTER_ALL
        self:refresh_recipe_list()
    end

    self.availability_label = UI.Widgets.LuiLabel()
    self.availability_label:SetParent(self.top_bar)
    self.availability_label:SetMouseVisible(false)
    self.availability_label:SetForeColor(TEXT_META)
    self.availability_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.availability_label:SetText(TR["Show:"])

    self.availability_dropdown = UI.Widgets.LuiDropdown()
    self.availability_dropdown:SetParent(self.top_bar)
    self.availability_dropdown:SetPopupHost(self)
    self.availability_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.availability_dropdown:SetMappedOptions(
        { TR["All recipes"], TR["Craftable now"], TR["Missing resources"] },
        { AVAILABILITY_ALL, AVAILABILITY_READY, AVAILABILITY_MISSING }
    )
    self.availability_dropdown.ValueChanged = function(_, value)
        self.availability_filter = value or AVAILABILITY_ALL
        self:refresh_recipe_list()
    end

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self.top_bar)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetForeColor(TEXT_META)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.level_label:SetText(TR["Level"] .. ":")

    self.level_min_box = Turbine.UI.Lotro.TextBox()
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

    self.level_max_box = Turbine.UI.Lotro.TextBox()
    self.level_max_box:SetParent(self.top_bar)
    self.level_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_max_box.TextChanged = function()
        self:update_level_filter()
    end

    self.left_panel = Turbine.UI.Control()
    self.left_panel:SetParent(self)
    _set_control_border(self.left_panel, PANEL_BORDER, PANEL_BACK)

    self.recipe_list = Turbine.UI.ListBox()
    self.recipe_list:SetParent(self.left_panel.inner)
    self.recipe_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.recipe_scroll = Turbine.UI.Lotro.ScrollBar()
    self.recipe_scroll:SetParent(self.left_panel.inner)
    self.recipe_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.recipe_list:SetVerticalScrollBar(self.recipe_scroll)

    self.recipe_empty = UI.Widgets.LuiLabel()
    self.recipe_empty:SetParent(self.left_panel.inner)
    self.recipe_empty:SetMouseVisible(false)
    self.recipe_empty:SetMultiline(true)
    self.recipe_empty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.recipe_empty:SetForeColor(TEXT_META)
    self.recipe_empty:SetText(TR["No matching recipes."])

    self.right_panel = Turbine.UI.Control()
    self.right_panel:SetParent(self)
    self.right_panel:SetBackColor(PANEL_BORDER)

    self.detail_panel = Turbine.UI.Control()
    self.detail_panel:SetParent(self.right_panel)
    _set_control_border(self.detail_panel, PANEL_BORDER, PANEL_BACK)

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

    self.plan_label = UI.Widgets.LuiLabel()
    self.plan_label:SetParent(self.detail_panel.inner)
    self.plan_label:SetMouseVisible(false)
    self.plan_label:SetForeColor(TEXT_META)
    self.plan_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.plan_label:SetText(TR["Build plan"])

    self.plan_minus_button = UI.Widgets.LuiButton()
    self.plan_minus_button:SetParent(self.detail_panel.inner)
    self.plan_minus_button:set_text("-")
    self.plan_minus_button.Click = function()
        local recipe = self:_selected_recipe()
        if recipe ~= nil then
            self:adjust_plan_count(recipe.id, -1)
        end
    end

    self.plan_count_label = UI.Widgets.LuiLabel()
    self.plan_count_label:SetParent(self.detail_panel.inner)
    self.plan_count_label:SetMouseVisible(false)
    self.plan_count_label:SetForeColor(TEXT_MAIN)
    self.plan_count_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.plan_plus_button = UI.Widgets.LuiButton()
    self.plan_plus_button:SetParent(self.detail_panel.inner)
    self.plan_plus_button:set_text("+")
    self.plan_plus_button.Click = function()
        local recipe = self:_selected_recipe()
        if recipe ~= nil then
            self:adjust_plan_count(recipe.id, 1)
        end
    end

    self.ingredients_title = UI.Widgets.LuiLabel()
    self.ingredients_title:SetParent(self.detail_panel.inner)
    self.ingredients_title:SetMouseVisible(false)
    self.ingredients_title:SetForeColor(TEXT_META)
    self.ingredients_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.ingredients_title:SetText(TR["Ingredients"])

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

    self.plan_panel = Turbine.UI.Control()
    self.plan_panel:SetParent(self.right_panel)
    _set_control_border(self.plan_panel, PANEL_BORDER, PANEL_BACK)

    self.plan_title = UI.Widgets.LuiLabel()
    self.plan_title:SetParent(self.plan_panel.inner)
    self.plan_title:SetMouseVisible(false)
    self.plan_title:SetForeColor(TEXT_META)
    self.plan_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.plan_title:SetText(TR["Build plan"])

    self.plan_summary = UI.Widgets.LuiLabel()
    self.plan_summary:SetParent(self.plan_panel.inner)
    self.plan_summary:SetMouseVisible(false)
    self.plan_summary:SetForeColor(TEXT_MAIN)
    self.plan_summary:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.plan_clear_button = UI.Widgets.LuiButton()
    self.plan_clear_button:SetParent(self.plan_panel.inner)
    self.plan_clear_button:set_text(TR["Clear"])
    self.plan_clear_button.Click = function()
        self:clear_plan()
    end

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
    self.missing_title:SetText(TR["Missing resources"])

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
    self.loading_panel:SetParent(self)
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

    self.SizeChanged = function()
        if self._suppress_size_changed == true then
            return
        end
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
        if self.store ~= nil and self.store.set_loading_priority ~= nil then
            self.store:set_loading_priority(visible)
        end
        if visible == true then
            self._last_update_at = 0
            self._last_store_version = nil
            self:refresh_from_store(true)
            self:bring_to_front()
        end
    end

    self:SetSize(_scaled_int(1100), _scaled_int(700))
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

function CraftingWindow._status_text(_, evaluation)
    if evaluation == nil then
        return ""
    end
    if evaluation.craftable == true then
        if evaluation.used_expansion == true then
            return TR["Ready via sub-craft"]
        end
        return TR["Ready"]
    end
    return TR["Missing "] .. _format_count(evaluation.missing_total)
end

function CraftingWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function CraftingWindow:open()
    self:SetVisible(true)
    self:SetWantsUpdates(true)
    self:bring_to_front()
    if self.store ~= nil and self.store.refresh ~= nil then
        self.store:refresh(false, 2)
    end
    self:refresh_from_store(true)
end

function CraftingWindow:open_from_asset_materials(material_keys)
    self:set_material_filter_keys(material_keys)
    self:open()
end

function CraftingWindow:toggle()
    if self:IsVisible() == true then
        self:SetVisible(false)
        self:SetWantsUpdates(false)
        return
    end

    self:open()
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

function CraftingWindow:apply_settings()
    self.update_every = math.max(0.20, 1.0 / math.max(1, _safe_number(_G.settings.global.refresh_rate, 30)))

    self.search_box:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.clear_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
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

    self.recipe_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.detail_title:SetFont(_scaled_font("Verdana", BASE_TITLE_FONT))
    self.detail_meta:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.detail_status:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.plan_label:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_minus_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.plan_count_label:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.plan_plus_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.ingredients_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.detail_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))

    self.plan_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_summary:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.plan_clear_button:set_font(_scaled_font("Verdana", BASE_BUTTON_FONT))
    self.missing_title:SetFont(_scaled_font("Verdana", BASE_META_FONT))
    self.plan_empty:SetFont(_scaled_font("Verdana", BASE_BODY_FONT))
    self.loading_text:SetFont(_scaled_font("Verdana", BASE_META_FONT))

    local scope_labels, scope_values = self.store:get_scope_options()
    self.scope_dropdown:SetMappedOptions(scope_labels, scope_values)
    self.scope_dropdown:SetValue(self.scope_key)
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

    local left = _safe_number(window.left, self:GetLeft())
    local top = _safe_number(window.top, self:GetTop())
    local width = _safe_number(window.width, self:GetWidth())
    local height = _safe_number(window.height, self:GetHeight())

    self._suppress_size_changed = true
    self:SetPosition(left, top)
    self:SetSize(width, height)
    self._suppress_size_changed = false
    self:_enforce_min_size()
    self:layout()
end

function CraftingWindow:_enforce_min_size()
    local width, height = self:GetSize()
    local min_w = _scaled_int(BASE_MIN_W)
    local min_h = _scaled_int(BASE_MIN_H)
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
    if self.store ~= nil and self.store.refresh ~= nil then
        store_changed = self.store:refresh(false, 2) == true
    end
    local store_version = _safe_number(self.store ~= nil and self.store.version or nil, 0)
    if store_changed == true or store_version ~= self._last_store_version then
        self._last_store_version = store_version
        self:refresh_from_store(false)
    end
end

function CraftingWindow:refresh_from_store(reset_filters)
    local profession_labels, profession_values = self.store:get_profession_options()
    self.profession_dropdown:SetMappedOptions(profession_labels, profession_values)

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
    self.profession_dropdown:SetValue(self.profession_filter)

    if reset_filters == true then
        self.search_groups = _normalize_query_groups(_parse_query(self.search_box:GetText()))
    end

    self:refresh_recipe_list()
    if reset_filters == true or self.selected_recipe_id ~= nil then
        self:refresh_selected_recipe()
    end
    if reset_filters == true or #self.plan_order > 0 then
        self:refresh_plan()
    end
    self:refresh_loading_state()
    self._last_store_version = _safe_number(self.store ~= nil and self.store.version or nil, 0)
end

function CraftingWindow:set_material_filter_keys(material_keys)
    if type(material_keys) ~= "table" then
        self.material_filter_keys = nil
    else
        local copy = {}
        for key, value in pairs(material_keys) do
            if value == true then
                copy[key] = true
            end
        end
        self.material_filter_keys = next(copy) ~= nil and copy or nil
    end

    if self:IsVisible() == true then
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self:refresh_selected_recipe()
    end
end

function CraftingWindow:clear_material_filter()
    self.material_filter_keys = nil
    if self:IsVisible() == true then
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self:refresh_selected_recipe()
    end
end

function CraftingWindow:update_level_filter()
    local filter_min = _parse_level_value(self.level_min_box:GetText())
    local filter_max = _parse_level_value(self.level_max_box:GetText())
    if filter_min ~= nil and filter_max ~= nil and filter_min > filter_max then
        filter_min, filter_max = filter_max, filter_min
    end

    self.level_min_filter = filter_min
    self.level_max_filter = filter_max
    self:_invalidate_recipe_list()
    self:refresh_recipe_list()
end

function CraftingWindow:_selected_recipe()
    return self.store.recipe_by_id[self.selected_recipe_id]
end

function CraftingWindow:_current_recipe_list_width()
    return math.max(0, self.recipe_list:GetWidth() - self.recipe_scroll:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_detail_list_width()
    return math.max(0, self.ingredients_list:GetWidth() - self.ingredients_scroll:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_plan_list_width()
    return math.max(0, self.plan_list:GetWidth() - self.plan_scroll:GetWidth() - _scaled_int(2))
end

function CraftingWindow:_current_missing_list_width()
    return math.max(0, self.missing_list:GetWidth() - self.missing_scroll:GetWidth() - _scaled_int(2))
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
    if _matches_query_groups(self.search_groups, recipe.haystack_lower) ~= true then
        return false
    end
    if type(self.material_filter_keys) == "table" and self.store:recipe_uses_item_key(recipe, self.material_filter_keys) ~= true then
        return false
    end
    if self.level_min_filter ~= nil or self.level_max_filter ~= nil then
        local required_level = _safe_number(recipe.required_level, nil)
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
end

function CraftingWindow:_recipe_filter_signature()
    return table.concat({
        _safe_string(self.scope_key, ""),
        _safe_string(self.profession_filter, ""),
        _safe_string(self.availability_filter, ""),
        _safe_string(self.level_min_filter, ""),
        _safe_string(self.level_max_filter, ""),
        _safe_string(self.search_box ~= nil and self.search_box:GetText() or "", ""),
        _safe_string(self.material_filter_keys ~= nil and next(self.material_filter_keys) ~= nil and "material_filter" or "", ""),
    }, "\30")
end

function CraftingWindow:_append_recipe_row(recipe, row_w)
    if recipe == nil then
        return
    end

    local status = self.store:get_recipe_status(recipe, self.scope_key)
    local row = CraftingRecipeRow(function(selected_recipe)
        self.selected_recipe_id = selected_recipe.id
        self:_invalidate_recipe_list()
        self:refresh_recipe_list()
        self:refresh_selected_recipe()
    end)
    row:set_scale(_G.settings.global.scale)
    row:set_width(row_w)
    row:set_data(recipe, status)
    row:set_selected(recipe.id == self.selected_recipe_id)
    self.recipe_list:AddItem(row)
end

function CraftingWindow:refresh_recipe_list()
    local row_w = self:_current_recipe_list_width()
    local loading = self.store:is_loading() == true
    local signature = self:_recipe_filter_signature()
    local loaded_count = #self.store.recipes
    local can_incremental = loading == true and
        self._recipe_list_loading == true and
        self._recipe_list_signature == signature and
        self._recipe_list_row_width == row_w and
        loaded_count >= self._recipe_list_loaded_count

    if can_incremental ~= true then
        self.visible_recipes = {}
        _clear_list_box(self.recipe_list)
        for i = 1, loaded_count do
            local recipe = self.store.recipes[i]
            local status = self.store:get_recipe_status(recipe, self.scope_key)
            if self:_recipe_matches_filters(recipe, status) == true then
                self.visible_recipes[#self.visible_recipes + 1] = recipe
            end
        end

        self:_ensure_selected_visible_recipe()
        for i = 1, #self.visible_recipes do
            self:_append_recipe_row(self.visible_recipes[i], row_w)
        end
    elseif loaded_count > self._recipe_list_loaded_count then
        for i = self._recipe_list_loaded_count + 1, loaded_count do
            local recipe = self.store.recipes[i]
            local status = self.store:get_recipe_status(recipe, self.scope_key)
            if self:_recipe_matches_filters(recipe, status) == true then
                self.visible_recipes[#self.visible_recipes + 1] = recipe
                if self.selected_recipe_id == nil then
                    self.selected_recipe_id = recipe.id
                end
                self:_append_recipe_row(recipe, row_w)
            end
        end
    end

    self._recipe_list_signature = signature
    self._recipe_list_loaded_count = loaded_count
    self._recipe_list_loading = loading
    self._recipe_list_row_width = row_w

    local has_items = #self.visible_recipes > 0
    self.recipe_list:SetVisible(has_items)
    self.recipe_scroll:SetVisible(has_items)
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
    end
end

function CraftingWindow:_collect_leaf_requirements(node, out)
    if type(node) ~= "table" then
        return
    end

    if type(node.children) ~= "table" or #node.children == 0 then
        local key = node.key or node.name or ""
        if key ~= "" then
            if type(out[key]) ~= "table" then
                out[key] = {
                    key = key,
                    name = node.name or key,
                    quantity = 0,
                }
            end
            out[key].quantity = _safe_number(out[key].quantity, 0) + _safe_number(node.required, 0)
        end
        return
    end

    for i = 1, #node.children do
        self:_collect_leaf_requirements(node.children[i], out)
    end
end

function CraftingWindow:_leaf_summary_text(node)
    local leaf_map = {}
    self:_collect_leaf_requirements(node, leaf_map)

    local leaves = {}
    for _, entry in pairs(leaf_map) do
        leaves[#leaves + 1] = entry
    end
    table.sort(leaves, function(left, right)
        return _lower(left.name) < _lower(right.name)
    end)

    if #leaves == 0 then
        return ""
    end

    local parts = {}
    local limit = math.min(3, #leaves)
    for i = 1, limit do
        parts[#parts + 1] = leaves[i].name .. " x" .. _format_count(leaves[i].quantity)
    end
    if #leaves > limit then
        parts[#parts + 1] = "+"
    end

    return table.concat(parts, ", ")
end

function CraftingWindow:_ingredient_detail_text(node)
    if node == nil then
        return ""
    end

    if node.expanded == true then
        local summary = self:_leaf_summary_text(node)
        if summary ~= "" then
            if node.satisfied == true then
                return TR["Auto-crafted from "] .. summary
            end
            return TR["Needs "] .. summary
        end
    end

    if node.ambiguous == true then
        return TR["Multiple known sub-recipes; auto-breakdown skipped"]
    end

    if node.satisfied == true then
        return TR["Directly available"]
    end

    return TR["Missing resource"]
end

function CraftingWindow:refresh_selected_recipe()
    _clear_list_box(self.ingredients_list)

    local recipe = self:_selected_recipe()
    if recipe == nil then
        self.detail_empty:SetVisible(true)
        self.detail_icon:bind_item(nil, nil, nil)
        self.detail_title:SetText("")
        self.detail_meta:SetText("")
        self.detail_status:SetText("")
        self.plan_count_label:SetText("0")
        self.ingredients_list:SetVisible(false)
        self.ingredients_scroll:SetVisible(false)
        return
    end

    local evaluation = self.store:evaluate_recipe(recipe, self.scope_key, 1)
    self.detail_empty:SetVisible(false)

    self.detail_icon:bind_item(recipe.result_item_info, recipe.icon_id, recipe.background_image_id)

    self.detail_title:SetText(recipe.result_name)
    local meta_parts = {}
    if recipe.profession_name ~= "" then
        meta_parts[#meta_parts + 1] = recipe.profession_name
    end
    if recipe.required_level ~= nil then
        meta_parts[#meta_parts + 1] = TR["Level"] .. " " .. _format_count(recipe.required_level)
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
    self.plan_count_label:SetText(_format_count(self.plan_counts[recipe.id] or 0))

    local row_w = self:_current_detail_list_width()
    for i = 1, #evaluation.ingredients do
        local node = evaluation.ingredients[i]
        local color = node.satisfied == true and (node.expanded == true and STATUS_AUTO or STATUS_READY) or STATUS_MISSING
        local row = CraftingIngredientRow()
        row:set_scale(_G.settings.global.scale)
        row:set_width(row_w)
        row:set_data(
            node.item_info,
            node.icon_id,
            node.background_image_id,
            node.name,
            self:_ingredient_detail_text(node),
            _format_count(node.owned_in_scope) .. " / " .. _format_count(node.required),
            color
        )
        self.ingredients_list:AddItem(row)
    end

    self.ingredients_list:SetVisible(true)
    self.ingredients_scroll:SetVisible(true)
end

function CraftingWindow:_build_plan_entries()
    local entries = {}
    for i = 1, #self.plan_order do
        local recipe_id = self.plan_order[i]
        local count = _safe_number(self.plan_counts[recipe_id], 0)
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
    _clear_list_box(self.plan_list)
    _clear_list_box(self.missing_list)

    local plan_entries = self:_build_plan_entries()
    local evaluation = self.store:evaluate_plan(plan_entries, self.scope_key)

    local has_plan = #plan_entries > 0
    self.plan_empty:SetVisible(has_plan ~= true)

    if has_plan == true then
        self.plan_summary:SetText(
            _format_count(#plan_entries) .. " " .. TR["recipes"] ..
            " - " .. _format_count(evaluation.missing_total) .. " " .. TR["missing"]
        )
    else
        self.plan_summary:SetText(TR["No recipes planned"])
    end

    local row_w = self:_current_plan_list_width()
    for i = 1, #evaluation.entries do
        local entry = evaluation.entries[i]
        local row = CraftingPlanRow(
            function(recipe)
                self:adjust_plan_count(recipe.id, -1)
            end,
            function(recipe)
                self:adjust_plan_count(recipe.id, 1)
            end,
            function(recipe)
                self:set_plan_count(recipe.id, 0)
            end
        )
        row:set_scale(_G.settings.global.scale)
        row:set_width(row_w)
        row:set_data(entry.recipe, entry.count, entry.evaluation)
        self.plan_list:AddItem(row)
    end

    local missing_w = self:_current_missing_list_width()
    for i = 1, #evaluation.missing_list do
        local entry = evaluation.missing_list[i]
        local row = CraftingIngredientRow()
        row:set_scale(_G.settings.global.scale)
        row:set_width(missing_w)
        row:set_data(
            entry.item_info,
            entry.icon_id,
            entry.background_image_id,
            entry.name,
            TR["Still needed for the full build plan"],
            TR["Missing x"] .. _format_count(entry.quantity),
            STATUS_MISSING
        )
        self.missing_list:AddItem(row)
    end

    self.plan_list:SetVisible(has_plan == true)
    self.plan_scroll:SetVisible(has_plan == true)
    self.missing_list:SetVisible(#evaluation.missing_list > 0)
    self.missing_scroll:SetVisible(#evaluation.missing_list > 0)

    local selected_recipe = self:_selected_recipe()
    if selected_recipe ~= nil then
        self.plan_count_label:SetText(_format_count(self.plan_counts[selected_recipe.id] or 0))
    else
        self.plan_count_label:SetText("0")
    end
end

function CraftingWindow:adjust_plan_count(recipe_id, delta)
    local next_count = _safe_number(self.plan_counts[recipe_id], 0) + _safe_number(delta, 0)
    self:set_plan_count(recipe_id, next_count)
end

function CraftingWindow:set_plan_count(recipe_id, count)
    if recipe_id == nil then
        return
    end

    local next_count = math.floor(_safe_number(count, 0) + 0.5)
    if next_count < 0 then
        next_count = 0
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

    self:refresh_selected_recipe()
    self:refresh_plan()
end

function CraftingWindow:clear_plan()
    self.plan_order = {}
    self.plan_counts = {}
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
end

function CraftingWindow:layout()
    local width, height = self:GetSize()
    local margin_left = _scaled_int(BASE_MARGIN_LEFT)
    local margin_top = _scaled_int(BASE_MARGIN_TOP)
    local margin_right = _scaled_int(BASE_MARGIN_RIGHT)
    local margin_bottom = _scaled_int(BASE_MARGIN_BOTTOM)
    local gap = _scaled_int(BASE_GAP)
    local bar_h = _scaled_int(BASE_BAR_H)
    local clear_w = _scaled_int(BASE_CLEAR_W)
    local loading_panel_h = self._loading_visible == true and _scaled_int(BASE_LOADING_PANEL_H) or 0
    local right_w = math.max(_scaled_int(BASE_RIGHT_W), math.floor((width - margin_left - margin_right) * 0.38))
    local left_w = width - margin_left - margin_right - gap - right_w
    if left_w < _scaled_int(280) then
        left_w = _scaled_int(280)
        right_w = width - margin_left - margin_right - gap - left_w
    end
    local top_bar_h = (bar_h * 3) + (gap * 2)
    local content_top = margin_top + top_bar_h + gap
    local content_bottom_gap = loading_panel_h > 0 and gap or 0
    local content_h = height - content_top - margin_bottom - loading_panel_h - content_bottom_gap
    if content_h < 0 then
        content_h = 0
    end
    local right_detail_h = math.max(_scaled_int(250), math.floor((content_h - gap) * 0.52))
    local right_plan_h = content_h - gap - right_detail_h
    if right_plan_h < 0 then
        right_plan_h = 0
    end
    local scroll_w = _fixed_int(BASE_SCROLL_W)
    local detail_header_h = _scaled_int(BASE_DETAIL_HEADER_H)
    local plan_header_h = _scaled_int(BASE_PLAN_HEADER_H)
    local small_button_w = _scaled_int(BASE_SMALL_BUTTON_W)
    local plan_qty_w = _scaled_int(BASE_PLAN_QTY_W)
    local plan_controls_w = _scaled_int(BASE_PLAN_CONTROLS_W)
    local loading_track_h = _scaled_int(BASE_LOADING_TRACK_H)

    self.top_bar:SetPosition(margin_left, margin_top)
    self.top_bar:SetSize(width - margin_left - margin_right, top_bar_h)

    self.search_box:SetPosition(0, 0)
    self.search_box:SetSize(self.top_bar:GetWidth() - clear_w - gap, bar_h)
    self.clear_button:SetPosition(self.top_bar:GetWidth() - clear_w, 0)
    self.clear_button:SetSize(clear_w, bar_h)

    local row2_y = bar_h + gap
    local row3_y = row2_y + bar_h + gap
    local scope_label_w = _scaled_int(142)
    local profession_label_w = _scaled_int(62)
    local profession_w = _scaled_int(172)
    local availability_label_w = _scaled_int(36)
    local availability_w = _scaled_int(152)
    local level_label_w = _scaled_int(BASE_LEVEL_LABEL_W)
    local level_box_w = _scaled_int(BASE_LEVEL_BOX_W)
    local level_dash_w = _scaled_int(BASE_LEVEL_DASH_W)
    local scope_w = self.top_bar:GetWidth() - scope_label_w - gap
    if scope_w < _scaled_int(260) then
        scope_w = _scaled_int(260)
    end

    self.scope_label:SetPosition(0, row2_y)
    self.scope_label:SetSize(scope_label_w, bar_h)
    self.scope_dropdown:SetPosition(scope_label_w + gap, row2_y)
    self.scope_dropdown:SetSize(scope_w, bar_h)

    local row3_right = self.top_bar:GetWidth()
    self.level_max_box:SetPosition(row3_right - level_box_w, row3_y)
    self.level_max_box:SetSize(level_box_w, bar_h)
    self.level_dash_label:SetPosition(row3_right - level_box_w - gap - level_dash_w, row3_y)
    self.level_dash_label:SetSize(level_dash_w, bar_h)
    self.level_min_box:SetPosition(row3_right - (level_box_w * 2) - (gap * 2) - level_dash_w, row3_y)
    self.level_min_box:SetSize(level_box_w, bar_h)
    self.level_label:SetPosition(row3_right - (level_box_w * 2) - (gap * 3) - level_dash_w - level_label_w, row3_y)
    self.level_label:SetSize(level_label_w, bar_h)

    row3_right = self.level_label:GetLeft() - gap
    self.availability_dropdown:SetPosition(row3_right - availability_w, row3_y)
    self.availability_dropdown:SetSize(availability_w, bar_h)
    self.availability_label:SetPosition(row3_right - availability_w - gap - availability_label_w, row3_y)
    self.availability_label:SetSize(availability_label_w, bar_h)

    self.profession_dropdown:SetPosition(
        row3_right - availability_w - gap - availability_label_w - gap - profession_w,
        row3_y
    )
    self.profession_dropdown:SetSize(profession_w, bar_h)
    self.profession_label:SetPosition(
        row3_right - availability_w - gap - availability_label_w - gap - profession_w - gap - profession_label_w,
        row3_y
    )
    self.profession_label:SetSize(profession_label_w, bar_h)

    self.left_panel:SetPosition(margin_left, content_top)
    self.left_panel:SetSize(left_w, content_h)
    _fit_inner_border(self.left_panel)

    self.recipe_scroll:SetPosition(self.left_panel.inner:GetWidth() - scroll_w, 0)
    self.recipe_scroll:SetSize(scroll_w, self.left_panel.inner:GetHeight())
    self.recipe_list:SetPosition(0, 0)
    self.recipe_list:SetSize(self.left_panel.inner:GetWidth() - scroll_w, self.left_panel.inner:GetHeight())
    self.recipe_empty:SetPosition(_scaled_int(8), _scaled_int(8))
    self.recipe_empty:SetSize(self.left_panel.inner:GetWidth() - _scaled_int(16), self.left_panel.inner:GetHeight() - _scaled_int(16))

    self.right_panel:SetPosition(margin_left + left_w + gap, content_top)
    self.right_panel:SetSize(right_w, content_h)

    self.detail_panel:SetPosition(0, 0)
    self.detail_panel:SetSize(right_w, right_detail_h)
    _fit_inner_border(self.detail_panel)

    local detail_inner = self.detail_panel.inner
    local icon_side = _fixed_int(BASE_ICON_SIDE)
    self.detail_icon:SetPosition(_scaled_int(8), _scaled_int(8))
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
    self.plan_minus_button:SetPosition(plan_controls_x, _scaled_int(26))
    self.plan_minus_button:SetSize(small_button_w, bar_h)
    self.plan_count_label:SetPosition(plan_controls_x + small_button_w + gap, _scaled_int(26))
    self.plan_count_label:SetSize(plan_qty_w, bar_h)
    self.plan_plus_button:SetPosition(plan_controls_x + small_button_w + gap + plan_qty_w + gap, _scaled_int(26))
    self.plan_plus_button:SetSize(small_button_w, bar_h)

    self.ingredients_title:SetPosition(_scaled_int(8), detail_header_h - _scaled_int(18))
    self.ingredients_title:SetSize(detail_inner:GetWidth() - _scaled_int(16), _scaled_int(18))

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

    self.plan_panel:SetPosition(0, right_detail_h + gap)
    self.plan_panel:SetSize(right_w, right_plan_h)
    _fit_inner_border(self.plan_panel)

    local plan_inner = self.plan_panel.inner
    self.plan_title:SetPosition(_scaled_int(8), 0)
    self.plan_title:SetSize(_scaled_int(90), plan_header_h)
    self.plan_summary:SetPosition(_scaled_int(8), plan_header_h)
    self.plan_summary:SetSize(plan_inner:GetWidth() - clear_w - _scaled_int(16) - gap, _scaled_int(20))
    self.plan_clear_button:SetPosition(plan_inner:GetWidth() - clear_w - _scaled_int(8), _scaled_int(2))
    self.plan_clear_button:SetSize(clear_w, bar_h)

    local plan_list_top = plan_header_h + _scaled_int(22)
    local plan_list_h = math.max(_scaled_int(90), math.floor((plan_inner:GetHeight() - plan_list_top - _scaled_int(26) - gap) * 0.56))
    self.plan_scroll:SetPosition(plan_inner:GetWidth() - scroll_w, plan_list_top)
    self.plan_scroll:SetSize(scroll_w, plan_list_h)
    self.plan_list:SetPosition(0, plan_list_top)
    self.plan_list:SetSize(plan_inner:GetWidth() - scroll_w, plan_list_h)

    local missing_top = plan_list_top + plan_list_h + gap
    self.missing_title:SetPosition(_scaled_int(8), missing_top)
    self.missing_title:SetSize(plan_inner:GetWidth() - _scaled_int(16), _scaled_int(18))
    local missing_list_top = missing_top + _scaled_int(18)
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
