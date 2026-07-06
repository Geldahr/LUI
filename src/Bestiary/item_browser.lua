-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Encyclopedia item browser tab: a paged, searchable, filterable listing
-- over one lore-DB item bucket (equipment / consumable / resource).
-- Search is the packed type-ahead (folded blob, session cache); filters are
-- byte probes over the record tuples; the listing order is the per-language
-- label-sorted permutation baked by the converter.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Style = UI.Widgets.Style
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local scaled_int = UI.NativeScaling.scaled_int
local class = _G.LUI.Core.class
local Lore = _G.LUI.Data.Lore
local SearchQuery = _G.LUI.Utils.SearchQuery
local Bestiary = _G.LUI.Features.Bestiary
local Crafting = _G.LUI.Features.Crafting
local Shortcuts = UI.Shortcuts
import "Turbine.UI"
import "LUI.src.UI.Widgets.item_icon"

-- control metrics match the bestiary filter bar (21px controls, 4px gaps)
local BASE_BAR_H = 21
local BASE_ROW_H = 34
-- native item art is 32px and must never be scaled (stretch mode 0 tiles)
local BASE_ICON_SIDE = 32
local BASE_GAP = 4
-- page bar matches the bestiary tab exactly (22x21 square nav buttons)
local BASE_NAV_W = 22
local BASE_PAGE_BAR_H = 21
local BASE_PAGE_W = 120
local BASE_QUALITY_W = 130
local BASE_CLASS_W = 190
local BASE_LEVEL_W = 44

local FILTER_ALL_CODE = 0

local function _scaled_font(name, size)
    return FONT_TO_LOTRO(name, size * State.settings.global.scale)
end

-- crafting-link action icon: identical treatment to the crafting window's
-- bestiary button on drop resources (16px icon in a 22px square button)
local CRAFT_ACTION_ICON = UI.AssetIds.anvil_silver_glow
local BASE_LINK_BUTTON_W = 22

local function _apply_craft_icon(button)
    -- same treatment as the crafting window's bestiary action button
    local side = math.max(14, scaled_int(16))
    button:set_icon(
        CRAFT_ACTION_ICON,
        CRAFT_ACTION_ICON,
        CRAFT_ACTION_ICON,
        CRAFT_ACTION_ICON,
        side,
        side,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
end

local function _even_int(value)
    local out = math.floor(value + 0.5)
    if out % 2 ~= 0 then
        out = out - 1
    end
    if out < 0 then
        out = 0
    end
    return out
end

local ItemBrowserRow = class(Turbine.UI.Control)

function ItemBrowserRow:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._link_name = nil
    self._link_recipe_id = nil

    self:SetMouseVisible(false)
    self:SetBackColor(Style.PANEL_INNER_BACKGROUND)

    self.icon = UI.Widgets.LuiItemIcon()
    self.icon:SetParent(self)

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.meta_label = UI.Widgets.LuiLabel()
    self.meta_label:SetParent(self)
    self.meta_label:SetMouseVisible(false)
    self.meta_label:SetForeColor(Style.ALTERNATE_FOREGROUND)
    self.meta_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    -- visible crafting link: opens the crafting window searched on this
    -- item, preselecting the producing recipe when the item is craftable
    self.craft_button = UI.Widgets.LuiButton()
    self.craft_button:SetParent(self)
    self.craft_button:set_scale(1)
    _apply_craft_icon(self.craft_button)
    self.craft_button:SetVisible(false)
    self.craft_button.Click = function()
        Shortcuts.open_crafting_item_search(self._link_name, self._link_recipe_id)
    end
end

function ItemBrowserRow:apply_fonts()
    self.name_label:SetFont(_scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE))
    self.meta_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.craft_button:set_scale(1)
    _apply_craft_icon(self.craft_button)
end

function ItemBrowserRow:set_row(ordinal)
    local Items = Lore.Items
    local icon_id, background_id = Items.icon_layers(ordinal)
    self.icon:bind(icon_id, background_id, Items.id_of(ordinal))
    local name = Items.label(ordinal)
    self.name_label:SetText(name)

    local meta = Items.class_name(ordinal)
    local level = Items.level(ordinal)
    if level > 0 then
        local level_text = TR["Level"] .. " " .. tostring(level)
        meta = meta ~= nil and (meta .. "  " .. level_text) or level_text
    end
    self.meta_label:SetText(meta or "")

    -- O(1) name probes decide the crafting-link button; the store is nil
    -- only while the crafting feature is disabled
    local store = Crafting.get_shared_store()
    local producing = nil
    local linkable = false
    if store ~= nil then
        producing = store:first_recipe_producing_name(name)
        linkable = producing ~= nil or store:has_recipes_using_name(name) == true
    end
    self._link_name = name
    self._link_recipe_id = producing ~= nil and producing.id or nil
    self.craft_button:SetVisible(linkable == true)
end

function ItemBrowserRow:layout_row(width, height)
    local gap = scaled_int(BASE_GAP)
    -- fixed icon side like the crafting rows: native 32px art, clamped to
    -- the row, evened for exact pixel centering
    local icon_side = BASE_ICON_SIDE
    local max_icon_side = height - 2
    if icon_side > max_icon_side then
        icon_side = max_icon_side
    end
    icon_side = _even_int(icon_side)
    self:SetSize(width, height)
    self.icon:set_side(icon_side)
    self.icon:SetPosition(gap, math.max(0, math.floor((height - icon_side) / 2)))

    -- crafting-link slot is always reserved so meta text stays aligned
    -- across rows with and without the button
    local btn_side = math.min(scaled_int(BASE_LINK_BUTTON_W), math.max(0, height - gap))
    self.craft_button:SetPosition(width - gap - btn_side, math.max(0, math.floor((height - btn_side) / 2)))
    self.craft_button:SetSize(btn_side, btn_side)

    local meta_w = scaled_int(220)
    local name_x = gap + icon_side + gap
    local meta_x = width - gap - btn_side - gap - meta_w
    self.name_label:SetPosition(name_x, 0)
    self.name_label:SetSize(math.max(0, meta_x - name_x - gap), height)
    self.meta_label:SetPosition(meta_x, 0)
    self.meta_label:SetSize(meta_w, height)
end

local ItemBrowserPanel = class(Turbine.UI.Control)
Bestiary.ItemBrowserPanel = ItemBrowserPanel

function ItemBrowserPanel:Constructor(bucket_name, popup_host)
    Turbine.UI.Control.Constructor(self)

    self._bucket = bucket_name
    self._popup_host = popup_host
    self._page = 1
    self._filtered = nil
    self._signature = nil
    self._rows = {}
    self._quality_filter = FILTER_ALL_CODE
    self._class_filter = FILTER_ALL_CODE
    self._level_min = nil
    self._level_max = nil

    self:SetMouseVisible(true)
    self:SetBackColor(Style.PANEL_BACKGROUND)

    Lore.load_items()

    self.search_box = UI.Widgets.LuiLineEdit()
    self.search_box:SetParent(self)
    self.search_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.search_box:set_placeholder_text(TR["Search..."])
    self.search_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.type_label = UI.Widgets.LuiLabel()
    self.type_label:SetParent(self)
    self.type_label:SetMouseVisible(false)
    self.type_label:SetSelectable(false)
    self.type_label:SetMultiline(false)
    self.type_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.type_label:SetText(TR["Type"] .. ":")

    self.rarity_label = UI.Widgets.LuiLabel()
    self.rarity_label:SetParent(self)
    self.rarity_label:SetMouseVisible(false)
    self.rarity_label:SetSelectable(false)
    self.rarity_label:SetMultiline(false)
    self.rarity_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.rarity_label:SetText(TR["Rarity"] .. ":")

    self.quality_dropdown = UI.Widgets.LuiDropdown()
    self.quality_dropdown:SetParent(self)
    self.quality_dropdown:SetPopupHost(popup_host)
    self.quality_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    -- official localized quality names from the game data (LEGENDARY
    -- displays as "Epic" in-game, so no hand-written labels here)
    local quality_labels, quality_values = { TR["All"] }, { FILTER_ALL_CODE }
    for code = 1, #Lore.Items.QUALITY_NAMES do
        local name = Lore.Items.QUALITY_NAMES[code]
        quality_labels[#quality_labels + 1] = Lore.Items.QUALITY_LABELS[name]
        quality_values[#quality_values + 1] = code
    end
    self.quality_dropdown:SetMappedOptions(quality_labels, quality_values)
    self.quality_dropdown.ValueChanged = function(_, value)
        self._quality_filter = tonumber(value) or FILTER_ALL_CODE
        self:_on_filters_changed()
    end

    self.class_dropdown = UI.Widgets.LuiDropdown()
    self.class_dropdown:SetParent(self)
    self.class_dropdown:SetPopupHost(popup_host)
    self.class_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    local class_labels, class_values = self:_class_options()
    self.class_dropdown:SetMappedOptions(class_labels, class_values)
    self.class_dropdown.ValueChanged = function(_, value)
        self._class_filter = tonumber(value) or FILTER_ALL_CODE
        self:_on_filters_changed()
    end

    self.level_label = UI.Widgets.LuiLabel()
    self.level_label:SetParent(self)
    self.level_label:SetMouseVisible(false)
    self.level_label:SetSelectable(false)
    self.level_label:SetMultiline(false)
    self.level_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.level_label:SetText(TR["Level"] .. ":")

    self.level_min_box = UI.Widgets.LuiLineEdit()
    self.level_min_box:SetParent(self)
    self.level_min_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_min_box.TextChanged = function()
        self:_on_filters_changed()
    end

    self.level_dash_label = UI.Widgets.LuiLabel()
    self.level_dash_label:SetParent(self)
    self.level_dash_label:SetMouseVisible(false)
    self.level_dash_label:SetSelectable(false)
    self.level_dash_label:SetMultiline(false)
    self.level_dash_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_dash_label:SetText("-")

    self.level_max_box = UI.Widgets.LuiLineEdit()
    self.level_max_box:SetParent(self)
    self.level_max_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.level_max_box.TextChanged = function()
        self:_on_filters_changed()
    end

    -- same arrow nav buttons as the bestiary page bar
    self.prev_button = UI.Widgets.LuiButton()
    self.prev_button:SetParent(self)
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
        self:_set_page(self._page - 1)
    end

    self.next_button = UI.Widgets.LuiButton()
    self.next_button:SetParent(self)
    self.next_button:set_text("")
    self.next_button:set_padding(2)
    self.next_button:set_icon(
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_white,
        UI.AssetIds.arrow_r_transparent,
        BASE_NAV_W,
        nil,
        UI.Widgets.LuiButton.icon_position.LEFT
    )
    self.next_button.Click = function()
        self:_set_page(self._page + 1)
    end

    self.page_label = UI.Widgets.LuiLabel()
    self.page_label:SetParent(self)
    self.page_label:SetMouseVisible(false)
    self.page_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.results_label = UI.Widgets.LuiLabel()
    self.results_label:SetParent(self)
    self.results_label:SetMouseVisible(false)
    self.results_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.results_label:SetForeColor(Style.ALTERNATE_FOREGROUND)

    self.list_host = Turbine.UI.Control()
    self.list_host:SetParent(self)
    self.list_host:SetMouseVisible(false)
    self.list_host:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self:apply_fonts()
end

function ItemBrowserPanel:_class_options()
    local Items = Lore.Items
    local codes = Items.BUCKET_CLASSES[self._bucket]
    local sortable = {}
    for i = 1, #codes do
        local code = codes[i]
        local label = Items.CLASSES[code]
        if label ~= nil then
            sortable[#sortable + 1] = { code = code, label = label }
        end
    end
    table.sort(sortable, function(left, right)
        return left.label < right.label
    end)
    local labels, values = { TR["All"] }, { FILTER_ALL_CODE }
    for i = 1, #sortable do
        labels[#labels + 1] = sortable[i].label
        values[#values + 1] = sortable[i].code
    end
    return labels, values
end

function ItemBrowserPanel:apply_fonts()
    local font = _scaled_font(Style.CONTROL_FONT_NAME, Style.CONTROL_FONT_SIZE - 2)
    self.search_box:SetFont(font)
    self.type_label:SetFont(font)
    self.rarity_label:SetFont(font)
    self.quality_dropdown:SetFont(font)
    self.quality_dropdown:set_scale(State.settings.global.scale)
    self.class_dropdown:SetFont(font)
    self.class_dropdown:set_scale(State.settings.global.scale)
    self.level_label:SetFont(font)
    self.level_min_box:SetFont(font)
    self.level_dash_label:SetFont(font)
    self.level_max_box:SetFont(font)
    self.page_label:SetFont(font)
    self.results_label:SetFont(_scaled_font(Style.CONTENT_SMALL_FONT_NAME, Style.CONTENT_SMALL_FONT_SIZE))
    self.prev_button:set_font(font)
    self.next_button:set_font(font)
    for i = 1, #self._rows do
        self._rows[i]:apply_fonts()
    end
end

function ItemBrowserPanel:_parse_level(text)
    local value = tonumber(text)
    if value == nil then
        return nil
    end
    value = math.floor(value)
    if value <= 0 then
        return nil
    end
    return value
end

function ItemBrowserPanel:_on_filters_changed()
    self._level_min = self:_parse_level(self.level_min_box:GetText())
    self._level_max = self:_parse_level(self.level_max_box:GetText())
    self._page = 1
    self:_refresh_list()
end

function ItemBrowserPanel:_set_page(page)
    local pages = self:_page_count()
    if page < 1 then
        page = 1
    end
    if page > pages then
        page = pages
    end
    if page == self._page then
        return
    end
    self._page = page
    self:_render_page()
end

-- shared query grammar (space = AND, | = OR, quotes = literal phrase),
-- evaluated over the packed per-term search sets: intersect terms inside a
-- group, union the groups. nil means "no search filter".
local function _search_set_for_query(query)
    local state = SearchQuery.parse(query, {})
    local groups = state.normalized_groups
    if #groups == 0 then
        return nil
    end

    local Items = Lore.Items
    local result, total = {}, 0
    for group_index = 1, #groups do
        local group = groups[group_index]
        local term_sets = {}
        for term_index = 1, #group do
            local set, count = Items.search(group[term_index])
            if set ~= nil then
                term_sets[#term_sets + 1] = { set = set, count = count }
            end
        end

        if #term_sets > 0 then
            table.sort(term_sets, function(left, right)
                return left.count < right.count
            end)
            local smallest = term_sets[1].set
            for ordinal in pairs(smallest) do
                if result[ordinal] == nil then
                    local hit = true
                    for k = 2, #term_sets do
                        if term_sets[k].set[ordinal] ~= true then
                            hit = false
                            break
                        end
                    end
                    if hit == true then
                        result[ordinal] = true
                        total = total + 1
                    end
                end
            end
        end
    end

    return result, total
end

function ItemBrowserPanel:_rebuild_filtered()
    local Items = Lore.Items
    local query = self.search_box:GetText() or ""
    local signature = table.concat({
        query,
        tostring(self._quality_filter),
        tostring(self._class_filter),
        tostring(self._level_min or ""),
        tostring(self._level_max or ""),
    }, "\30")
    if signature == self._signature and self._filtered ~= nil then
        return
    end
    self._signature = signature

    local search_set = _search_set_for_query(query)
    local quality = self._quality_filter
    local class_code = self._class_filter
    local level_min = self._level_min
    local level_max = self._level_max
    local list = Items.bucket_list(self._bucket)
    local filtered, n = {}, 0
    for i = 1, #list do
        local ordinal = list[i]
        if search_set == nil or search_set[ordinal] == true then
            if quality == FILTER_ALL_CODE or Items.quality_code(ordinal) == quality then
                if class_code == FILTER_ALL_CODE or Items.class_code(ordinal) == class_code then
                    local ok = true
                    if level_min ~= nil or level_max ~= nil then
                        local level = Items.level(ordinal)
                        if level_min ~= nil and level < level_min then
                            ok = false
                        end
                        if ok and level_max ~= nil and level > level_max then
                            ok = false
                        end
                    end
                    if ok then
                        n = n + 1
                        filtered[n] = ordinal
                    end
                end
            end
        end
    end
    self._filtered = filtered
end

function ItemBrowserPanel:_page_capacity()
    local row_h = _even_int(scaled_int(BASE_ROW_H))
    local _, host_h = self.list_host:GetSize()
    return math.max(1, math.floor(host_h / (row_h + scaled_int(2)))), row_h
end

function ItemBrowserPanel:_page_count()
    if self._filtered == nil then
        return 1
    end
    local capacity = self:_page_capacity()
    return math.max(1, math.ceil(#self._filtered / capacity))
end

function ItemBrowserPanel:_render_page()
    local capacity, row_h = self:_page_capacity()
    local host_w = self.list_host:GetWidth()
    local pages = self:_page_count()
    if self._page > pages then
        self._page = pages
    end
    local first = (self._page - 1) * capacity

    for slot = 1, capacity do
        local row = self._rows[slot]
        if row == nil then
            row = ItemBrowserRow()
            row:SetParent(self.list_host)
            row:apply_fonts()
            self._rows[slot] = row
        end
        local ordinal = self._filtered[first + slot]
        if ordinal ~= nil then
            row:SetVisible(true)
            row:layout_row(host_w, row_h)
            row:SetPosition(0, (slot - 1) * (row_h + scaled_int(2)))
            row:set_row(ordinal)
        else
            row:SetVisible(false)
        end
    end
    for slot = capacity + 1, #self._rows do
        self._rows[slot]:SetVisible(false)
    end

    self.page_label:SetText(tostring(self._page) .. " / " .. tostring(pages))
    self.results_label:SetText(tostring(#self._filtered) .. " " .. TR["results"])
    self.prev_button:set_enabled(self._page > 1)
    self.next_button:set_enabled(self._page < pages)
end

function ItemBrowserPanel:_refresh_list()
    self:_rebuild_filtered()
    self:_render_page()
end

function ItemBrowserPanel:layout()
    local width, height = self:GetSize()
    local gap = scaled_int(BASE_GAP)
    local bar_h = scaled_int(BASE_BAR_H)
    -- shared margins from the bestiary window: all tabs align
    local margins = Bestiary.CONTENT_MARGINS
    local margin_l = scaled_int(margins.left)
    local margin_t = scaled_int(margins.top)
    local margin_r = scaled_int(margins.right)
    local margin_b = scaled_int(margins.bottom)
    local level_w = scaled_int(BASE_LEVEL_W)
    local quality_w = scaled_int(BASE_QUALITY_W)
    local class_w = scaled_int(BASE_CLASS_W)

    -- row 1: Type / Rarity left, Level block flush right
    local type_label_w = scaled_int(38)
    local rarity_label_w = scaled_int(48)
    local dash_w = scaled_int(10)
    local level_label_w = scaled_int(42)
    local level_block_w = level_label_w + gap + level_w + gap + dash_w + gap + level_w

    local x = margin_l
    self.type_label:SetPosition(x, margin_t)
    self.type_label:SetSize(type_label_w, bar_h)
    x = x + type_label_w + gap
    self.class_dropdown:SetPosition(x, margin_t)
    self.class_dropdown:SetSize(class_w, bar_h)
    x = x + class_w + (2 * gap)
    self.rarity_label:SetPosition(x, margin_t)
    self.rarity_label:SetSize(rarity_label_w, bar_h)
    x = x + rarity_label_w + gap
    self.quality_dropdown:SetPosition(x, margin_t)
    self.quality_dropdown:SetSize(quality_w, bar_h)

    local level_x = width - margin_r - level_block_w
    self.level_label:SetPosition(level_x, margin_t)
    self.level_label:SetSize(level_label_w, bar_h)
    level_x = level_x + level_label_w + gap
    self.level_min_box:SetPosition(level_x, margin_t)
    self.level_min_box:SetSize(level_w, bar_h)
    level_x = level_x + level_w + gap
    self.level_dash_label:SetPosition(level_x, margin_t)
    self.level_dash_label:SetSize(dash_w, bar_h)
    level_x = level_x + dash_w + gap
    self.level_max_box:SetPosition(level_x, margin_t)
    self.level_max_box:SetSize(level_w, bar_h)

    -- row 2: search across the full width
    local search_y = margin_t + bar_h + gap
    self.search_box:SetPosition(margin_l, search_y)
    self.search_box:SetSize(math.max(1, width - margin_l - margin_r), bar_h)

    local nav_w = scaled_int(BASE_NAV_W)
    local page_bar_h = scaled_int(BASE_PAGE_BAR_H)
    local page_w = scaled_int(BASE_PAGE_W)
    local footer_y = height - margin_b - page_bar_h
    local footer_total = (2 * nav_w) + page_w + (2 * gap)
    local footer_x = math.max(0, math.floor((width - footer_total) / 2))
    self.prev_button:SetPosition(footer_x, footer_y)
    self.prev_button:SetSize(nav_w, page_bar_h)
    self.page_label:SetPosition(footer_x + nav_w + gap, footer_y)
    self.page_label:SetSize(page_w, page_bar_h)
    self.next_button:SetPosition(footer_x + nav_w + gap + page_w + gap, footer_y)
    self.next_button:SetSize(nav_w, page_bar_h)

    local results_w = scaled_int(140)
    self.results_label:SetPosition(width - margin_r - results_w, footer_y)
    self.results_label:SetSize(results_w, page_bar_h)

    local list_top = search_y + bar_h + gap
    self.list_host:SetPosition(margin_l, list_top)
    self.list_host:SetSize(math.max(1, width - margin_l - margin_r),
        math.max(1, footer_y - gap - list_top))

    self:_refresh_list()
end
