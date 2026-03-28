import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Settings.Tabs.form_page"
import "LUI.src.UI.Widgets"
import "LUI.src.StatusBar.common"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local S = _G.STATUS_BAR_COMMON

local WALLET_SELECTOR_HEIGHT = 209
local WALLET_SELECTOR_GAP = 6
local WALLET_SELECTOR_BUTTON_W = 58
local WALLET_SELECTOR_BUTTON_H = 22
local WALLET_SELECTOR_SCROLL_W = 10
local WALLET_SELECTOR_MIN_LIST_W = 90
local WALLET_SELECTOR_BOX_PAD = 1
local WALLET_SELECTOR_BOX_BORDER = Turbine.UI.Color(1, 0.35, 0.40, 0.50)
local WALLET_SELECTOR_BOX_FILL = Turbine.UI.Color(1, 0.08, 0.08, 0.08)

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _copy_list(items)
    local out = {}
    if type(items) ~= "table" then
        return out
    end
    for i = 1, #items do
        out[i] = items[i]
    end
    return out
end

local function _wallet_selector_normalize_items(items)
    return _copy_list(S.parse_wallet_item_list(items))
end

local function _wallet_selector_compare_entries(a, b)
    local an = string.lower(tostring(a or ""))
    local bn = string.lower(tostring(b or ""))
    if an == bn then
        return tostring(a or "") < tostring(b or "")
    end
    return an < bn
end

local function _wallet_selector_normalize_filter(value)
    local v = tostring(value or ""):lower()
    v = v:gsub("[’']", "")
    v = v:gsub("[^%w]+", " ")
    v = v:gsub("%s+", " ")
    v = v:gsub("^%s+", "")
    v = v:gsub("%s+$", "")
    return v
end

local function _wallet_selector_matches_filter(spec, filter_text)
    local filter = _wallet_selector_normalize_filter(filter_text)
    if spec == nil or filter == "" then
        return true
    end

    local function matches(value)
        local candidate = _wallet_selector_normalize_filter(value)
        return candidate ~= "" and string.find(candidate, filter, 1, true) ~= nil
    end

    return matches(spec)
end

local function _wallet_selector_current_token(entry)
    if entry == nil then
        return nil, nil
    end

    if entry.active_list == "available" and type(entry.available_index) == "number" then
        local selected = entry.available_entries[entry.available_index]
        return entry.active_list, selected
    end

    if entry.active_list == "selected" and type(entry.selected_index) == "number" then
        return entry.active_list, entry.selected_items[entry.selected_index]
    end

    return nil, nil
end

local function _wallet_selector_sync_active(entry)
    local available_index = nil
    if entry.active_list == "available" then
        available_index = entry.available_index
    end

    local selected_index = nil
    if entry.active_list == "selected" then
        selected_index = entry.selected_index
    end

    for i = 1, #(entry.available_buttons or {}) do
        local button = entry.available_buttons[i]
        if button ~= nil then
            button:set_active(i == available_index)
        end
    end

    for i = 1, #(entry.selected_buttons or {}) do
        local button = entry.selected_buttons[i]
        if button ~= nil then
            button:set_active(i == selected_index)
        end
    end

    if entry.add_button ~= nil then
        entry.add_button:SetEnabled(type(available_index) == "number")
    end
    if entry.remove_button ~= nil then
        entry.remove_button:SetEnabled(type(selected_index) == "number")
    end
    if entry.up_button ~= nil then
        entry.up_button:SetEnabled(type(selected_index) == "number" and selected_index > 1)
    end
    if entry.down_button ~= nil then
        entry.down_button:SetEnabled(type(selected_index) == "number" and selected_index < #entry.selected_items)
    end
end

local function _wallet_selector_select(entry, list_name, index)
    if list_name == "available" then
        entry.active_list = "available"
        entry.available_index = index
        entry.selected_index = nil
    else
        entry.active_list = "selected"
        entry.selected_index = index
        entry.available_index = nil
    end
    _wallet_selector_sync_active(entry)
end

local function _wallet_selector_layout(entry)
    if entry == nil or entry.control == nil then
        return
    end

    local w, h = entry.control:GetSize()
    local gap = _scaled_int(WALLET_SELECTOR_GAP)
    local label_h = entry.window ~= nil and entry.window.field_label_height or _scaled_int(31)
    local filter_h = entry.window ~= nil and entry.window.input_height or _scaled_int(21)
    local button_w = _scaled_int(WALLET_SELECTOR_BUTTON_W)
    local button_h = _scaled_int(WALLET_SELECTOR_BUTTON_H)
    local scroll_w = WALLET_SELECTOR_SCROLL_W
    local item_h = entry.window ~= nil and entry.window.input_height or _scaled_int(21)
    local min_list_w = _scaled_int(WALLET_SELECTOR_MIN_LIST_W)
    local box_pad = _scaled_int(WALLET_SELECTOR_BOX_PAD)

    local action_w = button_w
    local reorder_w = button_w
    local remaining = w - action_w - reorder_w - (gap * 3)
    if remaining < (min_list_w * 2) then
        local shrink = (min_list_w * 2) - remaining
        local reduce_each = math.floor((shrink + 1) / 2)
        action_w = math.max(_scaled_int(34), action_w - reduce_each)
        reorder_w = math.max(_scaled_int(34), reorder_w - reduce_each)
        remaining = w - action_w - reorder_w - (gap * 3)
    end
    if remaining < 2 then
        remaining = 2
    end

    local available_w = math.floor(remaining / 2)
    local selected_w = remaining - available_w
    if available_w < 1 then available_w = 1 end
    if selected_w < 1 then selected_w = 1 end

    local available_x = 0
    local actions_x = available_x + available_w + gap
    local selected_x = actions_x + action_w + gap
    local reorder_x = selected_x + selected_w + gap

    local filter_y = label_h + gap
    local box_top = filter_y + filter_h + gap
    local box_h = h - box_top
    if box_h < item_h + (box_pad * 2) then
        box_h = item_h + (box_pad * 2)
    end
    local list_h = math.max(0, box_h - (box_pad * 2))

    entry.available_label:SetPosition(available_x, 0)
    entry.available_label:SetSize(available_w, label_h)
    entry.selected_label:SetPosition(selected_x, 0)
    entry.selected_label:SetSize(selected_w, label_h)

    entry.available_filter:SetPosition(available_x, filter_y)
    entry.available_filter:SetSize(available_w, filter_h)

    entry.available_box:SetPosition(available_x, box_top)
    entry.available_box:SetSize(available_w, box_h)
    entry.available_fill:SetPosition(box_pad, box_pad)
    entry.available_fill:SetSize(math.max(0, available_w - (box_pad * 2)), list_h)
    entry.available_list:SetPosition(0, 0)
    entry.available_list:SetSize(math.max(0, entry.available_fill:GetWidth() - scroll_w), list_h)
    entry.available_scroll:SetPosition(entry.available_fill:GetWidth() - scroll_w, 0)
    entry.available_scroll:SetSize(scroll_w, list_h)

    entry.selected_box:SetPosition(selected_x, box_top)
    entry.selected_box:SetSize(selected_w, box_h)
    entry.selected_fill:SetPosition(box_pad, box_pad)
    entry.selected_fill:SetSize(math.max(0, selected_w - (box_pad * 2)), list_h)
    entry.selected_list:SetPosition(0, 0)
    entry.selected_list:SetSize(math.max(0, entry.selected_fill:GetWidth() - scroll_w), list_h)
    entry.selected_scroll:SetPosition(entry.selected_fill:GetWidth() - scroll_w, 0)
    entry.selected_scroll:SetSize(scroll_w, list_h)

    local action_block_h = (button_h * 2) + gap
    local action_y = box_top + math.max(0, math.floor((box_h - action_block_h) / 2))
    entry.add_button:SetPosition(actions_x, action_y)
    entry.add_button:SetSize(action_w, button_h)
    entry.remove_button:SetPosition(actions_x, action_y + button_h + gap)
    entry.remove_button:SetSize(action_w, button_h)

    local reorder_block_h = (button_h * 2) + gap
    local reorder_y = box_top + math.max(0, math.floor((box_h - reorder_block_h) / 2))
    entry.up_button:SetPosition(reorder_x, reorder_y)
    entry.up_button:SetSize(reorder_w, button_h)
    entry.down_button:SetPosition(reorder_x, reorder_y + button_h + gap)
    entry.down_button:SetSize(reorder_w, button_h)

    for i = 1, #(entry.available_buttons or {}) do
        local button = entry.available_buttons[i]
        if button ~= nil then
            button:SetSize(entry.available_list:GetWidth(), item_h)
        end
    end

    for i = 1, #(entry.selected_buttons or {}) do
        local button = entry.selected_buttons[i]
        if button ~= nil then
            button:SetSize(entry.selected_list:GetWidth(), item_h)
        end
    end
end

local function _wallet_selector_rebuild_lists(entry)
    local active_list, active_token = _wallet_selector_current_token(entry)
    local selected_known = {}

    entry.selected_entries = {}
    for i = 1, #entry.selected_items do
        local value = entry.selected_items[i]
        local resolved = S.resolve_wallet_item_selection(value)
        if resolved ~= nil then
            entry.selected_entries[#entry.selected_entries + 1] = resolved
            selected_known[resolved] = true
        end
    end

    entry.available_entries = {}
    for i = 1, #S.WALLET_ITEMS do
        local spec = S.WALLET_ITEMS[i]
        if selected_known[spec] ~= true and _wallet_selector_matches_filter(spec, entry.filter_text) == true then
            entry.available_entries[#entry.available_entries + 1] = spec
        end
    end
    table.sort(entry.available_entries, _wallet_selector_compare_entries)

    entry.available_list:ClearItems()
    entry.available_buttons = {}
    for i = 1, #entry.available_entries do
        local spec = entry.available_entries[i]
        local button = UI.Widgets.LuiButton()
        button:SetScale(_G.settings.global.scale)
        button:SetFont(entry.window.input_font)
        button:SetBorderThickness(0)
        button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:SetText(spec)
        button.Click = function()
            _wallet_selector_select(entry, "available", i)
        end
        entry.available_buttons[i] = button
        entry.available_list:AddItem(button)
    end

    entry.selected_list:ClearItems()
    entry.selected_buttons = {}
    for i = 1, #entry.selected_entries do
        local resolved = entry.selected_entries[i]
        local button = UI.Widgets.LuiButton()
        button:SetScale(_G.settings.global.scale)
        button:SetFont(entry.window.input_font)
        button:SetBorderThickness(0)
        button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        button:SetText(resolved)
        button.Click = function()
            _wallet_selector_select(entry, "selected", i)
        end
        entry.selected_buttons[i] = button
        entry.selected_list:AddItem(button)
    end

    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    if active_list == "available" and active_token ~= nil then
        for i = 1, #entry.available_entries do
            if entry.available_entries[i] == active_token then
                entry.active_list = "available"
                entry.available_index = i
                break
            end
        end
    elseif active_list == "selected" and active_token ~= nil then
        for i = 1, #entry.selected_items do
            if entry.selected_items[i] == active_token then
                entry.active_list = "selected"
                entry.selected_index = i
                break
            end
        end
    end

    _wallet_selector_layout(entry)
    _wallet_selector_sync_active(entry)
end

local function _wallet_selector_add(entry)
    local index = entry.available_index
    if entry.active_list ~= "available" or type(index) ~= "number" then
        return
    end

    local spec = entry.available_entries[index]
    if spec == nil then
        return
    end

    entry.selected_items[#entry.selected_items + 1] = spec
    entry.active_list = "selected"
    entry.selected_index = #entry.selected_items
    entry.available_index = nil
    _wallet_selector_rebuild_lists(entry)
end

local function _wallet_selector_remove(entry)
    local index = entry.selected_index
    if entry.active_list ~= "selected" or type(index) ~= "number" then
        return
    end

    table.remove(entry.selected_items, index)
    if #entry.selected_items == 0 then
        entry.active_list = nil
        entry.selected_index = nil
    else
        entry.active_list = "selected"
        if index > #entry.selected_items then
            index = #entry.selected_items
        end
        entry.selected_index = index
    end
    entry.available_index = nil
    _wallet_selector_rebuild_lists(entry)
end

local function _wallet_selector_move(entry, direction)
    local index = entry.selected_index
    if entry.active_list ~= "selected" or type(index) ~= "number" then
        return
    end

    local target = index + direction
    if target < 1 or target > #entry.selected_items then
        return
    end

    local value = entry.selected_items[index]
    entry.selected_items[index] = entry.selected_items[target]
    entry.selected_items[target] = value
    entry.selected_index = target
    _wallet_selector_rebuild_lists(entry)
end

local function _create_wallet_selector(page, key)
    local entry = page:add_custom(key, WALLET_SELECTOR_HEIGHT)
    entry.window = page.window
    entry.selected_items = {}
    entry.available_entries = {}
    entry.selected_entries = {}
    entry.available_buttons = {}
    entry.selected_buttons = {}
    entry.filter_text = ""
    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    entry.available_label = UI.Widgets.LuiLabel()
    entry.available_label:SetParent(entry.control)
    entry.available_label:SetFont(page.window.field_label_font)
    entry.available_label:SetMultiline(true)
    entry.available_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_label:SetText(TR("All wallet items"))
    entry.available_label:SetZOrder(1)

    entry.selected_label = UI.Widgets.LuiLabel()
    entry.selected_label:SetParent(entry.control)
    entry.selected_label:SetFont(page.window.field_label_font)
    entry.selected_label:SetMultiline(true)
    entry.selected_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.selected_label:SetText(TR("Shown in %wallet%"))
    entry.selected_label:SetZOrder(1)

    entry.available_filter = Turbine.UI.Lotro.TextBox()
    entry.available_filter:SetParent(entry.control)
    entry.available_filter:SetFont(page.window.input_font)
    entry.available_filter:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_filter:SetZOrder(2)
    entry.available_filter:SetText("")
    entry.available_filter.TextChanged = function()
        entry.filter_text = entry.available_filter:GetText() or ""
        _wallet_selector_rebuild_lists(entry)
    end

    entry.available_box = Turbine.UI.Control()
    entry.available_box:SetParent(entry.control)
    entry.available_box:SetBackColor(WALLET_SELECTOR_BOX_BORDER)
    entry.available_box:SetMouseVisible(false)

    entry.available_fill = Turbine.UI.Control()
    entry.available_fill:SetParent(entry.available_box)
    entry.available_fill:SetBackColor(WALLET_SELECTOR_BOX_FILL)
    entry.available_fill:SetMouseVisible(false)

    entry.available_list = Turbine.UI.ListBox()
    entry.available_list:SetParent(entry.available_fill)
    entry.available_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    entry.available_scroll = Turbine.UI.Lotro.ScrollBar()
    entry.available_scroll:SetParent(entry.available_fill)
    entry.available_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    entry.available_scroll:SetWidth(WALLET_SELECTOR_SCROLL_W)
    entry.available_list:SetVerticalScrollBar(entry.available_scroll)

    entry.selected_box = Turbine.UI.Control()
    entry.selected_box:SetParent(entry.control)
    entry.selected_box:SetBackColor(WALLET_SELECTOR_BOX_BORDER)
    entry.selected_box:SetMouseVisible(false)

    entry.selected_fill = Turbine.UI.Control()
    entry.selected_fill:SetParent(entry.selected_box)
    entry.selected_fill:SetBackColor(WALLET_SELECTOR_BOX_FILL)
    entry.selected_fill:SetMouseVisible(false)

    entry.selected_list = Turbine.UI.ListBox()
    entry.selected_list:SetParent(entry.selected_fill)
    entry.selected_list:SetOrientation(Turbine.UI.Orientation.Vertical)

    entry.selected_scroll = Turbine.UI.Lotro.ScrollBar()
    entry.selected_scroll:SetParent(entry.selected_fill)
    entry.selected_scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    entry.selected_scroll:SetWidth(WALLET_SELECTOR_SCROLL_W)
    entry.selected_list:SetVerticalScrollBar(entry.selected_scroll)

    entry.add_button = UI.Widgets.LuiButton()
    entry.add_button:SetParent(entry.control)
    entry.add_button:SetText(TR("Add"))
    entry.add_button.Click = function()
        _wallet_selector_add(entry)
    end

    entry.remove_button = UI.Widgets.LuiButton()
    entry.remove_button:SetParent(entry.control)
    entry.remove_button:SetText(TR("Remove"))
    entry.remove_button.Click = function()
        _wallet_selector_remove(entry)
    end

    entry.up_button = UI.Widgets.LuiButton()
    entry.up_button:SetParent(entry.control)
    entry.up_button:SetText(TR("Up"))
    entry.up_button.Click = function()
        _wallet_selector_move(entry, -1)
    end

    entry.down_button = UI.Widgets.LuiButton()
    entry.down_button:SetParent(entry.control)
    entry.down_button:SetText(TR("Down"))
    entry.down_button.Click = function()
        _wallet_selector_move(entry, 1)
    end

    entry.control.SizeChanged = function()
        _wallet_selector_layout(entry)
    end

    function entry:refresh_text()
        entry.available_filter:SetText(entry.available_filter:GetText() or "")
    end

    entry.apply_ui_scale = function()
        entry.available_label:SetFont(page.window.field_label_font)
        entry.selected_label:SetFont(page.window.field_label_font)
        entry.available_filter:SetFont(page.window.input_font)
        entry.add_button:SetScale(_G.settings.global.scale)
        entry.add_button:SetFont(page.window.settings_font)
        entry.remove_button:SetScale(_G.settings.global.scale)
        entry.remove_button:SetFont(page.window.settings_font)
        entry.up_button:SetScale(_G.settings.global.scale)
        entry.up_button:SetFont(page.window.settings_font)
        entry.down_button:SetScale(_G.settings.global.scale)
        entry.down_button:SetFont(page.window.settings_font)

        for i = 1, #entry.available_buttons do
            local button = entry.available_buttons[i]
            if button ~= nil then
                button:SetScale(_G.settings.global.scale)
                button:SetFont(page.window.input_font)
            end
        end

        for i = 1, #entry.selected_buttons do
            local button = entry.selected_buttons[i]
            if button ~= nil then
                button:SetScale(_G.settings.global.scale)
                button:SetFont(page.window.input_font)
            end
        end

        _wallet_selector_layout(entry)
    end

    function entry:set_items(items)
        self.selected_items = _wallet_selector_normalize_items(items)
        self.active_list = nil
        self.available_index = nil
        self.selected_index = nil
        _wallet_selector_rebuild_lists(self)
    end

    function entry:get_items()
        return _copy_list(self.selected_items)
    end

    entry:apply_ui_scale()
    entry:set_items({})
    return entry
end

local function _is_outline(control)
    local v = control:get_value()
    return v == LUI_ENUMS.font_style.OUTLINE
end

local function _build_layout_help()
    local lines = {
        TR("Tokens:"),
        TR("  %time% - local time (HH:MM)"),
        TR("  %inventory% - backpack used/total"),
        TR("  %durability% - equipped wear average% (weakest%)"),
        TR("  %gold% / %money% - money (g/s/c)"),
        TR("  %wallet% - selected wallet items"),
        TR("  %item:[Simple Fish]% - tracked total for one inventory item"),
        TR("  %config% - toggle configuration window"),
        TR("  %bestiary% - toggle bestiary window"),
        TR("  %assets% - toggle assets window"),
    }

    local external_lines = S.get_status_bar_api_hint_lines()
    for i = 1, #external_lines do
        lines[#lines + 1] = external_lines[i]
    end

    return table.concat(lines, "\n")
end

StatusBarPage = class(SettingsFormPage)

function StatusBarPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    local time_format_labels = { TR("24-hour"), TR("AM/PM") }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }
    local layout_help = _build_layout_help()

    self:add_title(TR("Status Bar"))

    self:add_hr()
    self:add_title(TR("General"))
    self:add_checkbox("sb_enabled", TR("Enabled"), true)

    self:add_hr()
    self:add_title(TR("Background"))
    self:add_text("sb_bg_opacity", TR("Background opacity (0..1)"))
    self:add_text("sb_bg_color", TR("Background color"), true)

    self:add_hr()
    self:add_title(TR("Font"))
    self:add_dropdown("sb_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("sb_font_size", TR("Font size"))
    self:add_text("sb_font_color", TR("Font color"), true)
    self:add_dropdown("sb_font_style", TR("Font style"), self.font_style_labels, self.font_style_values)
    self:add_text("sb_font_outline_color", TR("Outline color"), true)

    self:add_hr()
    self:add_title(TR("Layout"))
    self:add_text("sb_height", TR("Height"))

    self:add_hr()
    self:add_title(TR("Widgets order"))
    self:add_text("sb_layout_left", TR("Left layout"), false, layout_help, true)
    self:add_text("sb_layout_center", TR("Center layout"), false, layout_help, true)
    self:add_text("sb_layout_right", TR("Right layout"), false, layout_help, true)

    self:add_hr()
    self:add_title(TR("Widgets"))

    self:add_hr()
    self:add_title(TR("Time (local)"))
    self:add_text("sb_time_width", TR("Width"))
    self:add_dropdown("sb_time_format", TR("Time format"), time_format_labels, time_format_values)
    self:add_dropdown("sb_time_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)

    self:add_hr()
    self:add_title(TR("Inventory space"))
    self:add_text("sb_inv_width", TR("Width"))
    self:add_checkbox("sb_inv_icon", TR("Icon"))
    self:add_dropdown("sb_inv_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    self:add_text("sb_inv_yellow", TR("Warn color (30%)"), true)
    self:add_text("sb_inv_orange", TR("Warn color (20%)"), true)
    self:add_text("sb_inv_red", TR("Warn color (10%)"), true)

    self:add_hr()
    self:add_title(TR("Equipment wear"))
    self:add_text("sb_durability_width", TR("Width"))
    self:add_checkbox("sb_durability_icon", TR("Icon"))
    self:add_dropdown("sb_durability_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    self:add_checkbox("sb_durability_coloring", TR("Enable rich-text coloring"), true)
    self:add_text("sb_durability_green", TR("Green color"), true)
    self:add_text("sb_durability_yellow", TR("Yellow color"), true)
    self:add_text("sb_durability_red", TR("Red color"), true)

    self:add_hr()
    self:add_title(TR("Money"))
    self:add_text("sb_money_width", TR("Width"))
    self:add_checkbox("sb_money_icon", TR("Icon"))
    self:add_dropdown("sb_money_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)

    self:add_hr()
    self:add_title(TR("Wallet"))
    self:add_text("sb_wallet_width", TR("Width"))
    self:add_dropdown("sb_wallet_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    _create_wallet_selector(self, "sb_wallet_items")

    self:add_hr()
    self:add_title(TR("Tracked item"))
    self:add_text("sb_item_width", TR("Width"))

    self:add_hr()
    self:add_title(TR("Shortcut buttons"))
    self:add_text("sb_shortcut_width", TR("Width"))
    self:add_text("sb_shortcut_height", TR("Height"))

    self.controls.sb_font_outline_color.visible_if = function()
        return _is_outline(self.controls.sb_font_style)
    end

    self:refresh_layout_help()
end

function StatusBarPage:refresh_layout_help()
    local help_text = _build_layout_help()
    local keys = { "sb_layout_left", "sb_layout_center", "sb_layout_right" }
    for i = 1, #keys do
        local entry = self.controls[keys[i]]
        if entry ~= nil then
            entry.help_text = help_text
        end
    end
end

function StatusBarPage:load(sb)
    if sb == nil then
        return
    end

    self.loading = true
    self:refresh_layout_help()

    self.controls.sb_enabled.cb:SetChecked(sb.enabled == true)
    self.controls.sb_bg_opacity.tb:SetText(tostring(sb.bg.opacity))
    self.controls.sb_bg_color.tb:SetText(self.color_to_hex(sb.bg.color))

    self.controls.sb_font_name:set_value(sb.font.name)
    self.controls.sb_font_size.tb:SetText(tostring(sb.font.size))
    self.controls.sb_font_color.tb:SetText(self.color_to_hex(sb.font.color))
    self.controls.sb_font_style:set_value(sb.font.style)
    self.controls.sb_font_outline_color.tb:SetText(self.color_to_hex(sb.font.outline_color))

    self.controls.sb_height.tb:SetText(tostring(sb.height))

    local widgets = sb.widgets

    self.controls.sb_layout_left.tb:SetText(tostring(sb.layout.left or ""))
    self.controls.sb_layout_center.tb:SetText(tostring(sb.layout.center or ""))
    self.controls.sb_layout_right.tb:SetText(tostring(sb.layout.right or ""))

    local time = widgets.time_local
    self.controls.sb_time_width.tb:SetText(tostring(time.width))
    self.controls.sb_time_format:set_value(time.time_format)
    self.controls.sb_time_text_alignment:set_value(time.text_alignment)

    local inv = widgets.inventory_space
    self.controls.sb_inv_width.tb:SetText(tostring(inv.width))
    self.controls.sb_inv_icon.cb:SetChecked(inv.icon == true)
    self.controls.sb_inv_text_alignment:set_value(inv.text_alignment)
    self.controls.sb_inv_yellow.tb:SetText(self.color_to_hex(inv.color.yellow))
    self.controls.sb_inv_orange.tb:SetText(self.color_to_hex(inv.color.orange))
    self.controls.sb_inv_red.tb:SetText(self.color_to_hex(inv.color.red))

    local wear = widgets.equipment_wear
    self.controls.sb_durability_width.tb:SetText(tostring(wear.width))
    self.controls.sb_durability_icon.cb:SetChecked(wear.icon == true)
    self.controls.sb_durability_text_alignment:set_value(wear.text_alignment)
    self.controls.sb_durability_coloring.cb:SetChecked(wear.coloring == true)
    self.controls.sb_durability_green.tb:SetText(self.color_to_hex(wear.color.green))
    self.controls.sb_durability_yellow.tb:SetText(self.color_to_hex(wear.color.yellow))
    self.controls.sb_durability_red.tb:SetText(self.color_to_hex(wear.color.red))

    local money = widgets.money
    self.controls.sb_money_width.tb:SetText(tostring(money.width))
    self.controls.sb_money_icon.cb:SetChecked(money.icon == true)
    self.controls.sb_money_text_alignment:set_value(money.text_alignment)

    local wallet = widgets.wallet
    self.controls.sb_wallet_width.tb:SetText(tostring(wallet.width))
    self.controls.sb_wallet_text_alignment:set_value(wallet.text_alignment)
    self.controls.sb_wallet_items:set_items(wallet.items)

    self.controls.sb_item_width.tb:SetText(tostring(widgets.item.width))

    self.controls.sb_shortcut_width.tb:SetText(tostring(widgets.shortcut.width))
    self.controls.sb_shortcut_height.tb:SetText(tostring(widgets.shortcut.height))

    self:update_all_swatches()
    self.loading = false
end

function StatusBarPage:apply(sb)
    if sb == nil then
        return
    end

    sb.enabled = self.controls.sb_enabled.cb:IsChecked() == true

    local bg_opacity = tonumber(self.controls.sb_bg_opacity.tb:GetText())
    if bg_opacity ~= nil then sb.bg.opacity = bg_opacity end
    local bg_color = self.hex_to_color(self.controls.sb_bg_color.tb:GetText())
    if bg_color ~= nil then sb.bg.color = bg_color end

    sb.font.name = self.controls.sb_font_name:get_value()
    local font_size = tonumber(self.controls.sb_font_size.tb:GetText())
    if font_size ~= nil then sb.font.size = font_size end
    local font_color = self.hex_to_color(self.controls.sb_font_color.tb:GetText())
    if font_color ~= nil then sb.font.color = font_color end
    sb.font.style = self.controls.sb_font_style:get_value()
    local outline_color = self.hex_to_color(self.controls.sb_font_outline_color.tb:GetText())
    if outline_color ~= nil then sb.font.outline_color = outline_color end

    local height = tonumber(self.controls.sb_height.tb:GetText())
    if height ~= nil then sb.height = height end

    sb.layout.left = self.controls.sb_layout_left.tb:GetText() or ""
    sb.layout.center = self.controls.sb_layout_center.tb:GetText() or ""
    sb.layout.right = self.controls.sb_layout_right.tb:GetText() or ""

    local widgets = sb.widgets

    local time_w = tonumber(self.controls.sb_time_width.tb:GetText())
    if time_w ~= nil then widgets.time_local.width = time_w end
    widgets.time_local.time_format = self.controls.sb_time_format:get_value()
    widgets.time_local.text_alignment = self.controls.sb_time_text_alignment:get_value()

    local inv_w = tonumber(self.controls.sb_inv_width.tb:GetText())
    if inv_w ~= nil then widgets.inventory_space.width = inv_w end
    widgets.inventory_space.icon = self.controls.sb_inv_icon.cb:IsChecked() == true
    widgets.inventory_space.text_alignment = self.controls.sb_inv_text_alignment:get_value()
    local inv_y = self.hex_to_color(self.controls.sb_inv_yellow.tb:GetText())
    if inv_y ~= nil then widgets.inventory_space.color.yellow = inv_y end
    local inv_o = self.hex_to_color(self.controls.sb_inv_orange.tb:GetText())
    if inv_o ~= nil then widgets.inventory_space.color.orange = inv_o end
    local inv_r = self.hex_to_color(self.controls.sb_inv_red.tb:GetText())
    if inv_r ~= nil then widgets.inventory_space.color.red = inv_r end

    local wear_w = tonumber(self.controls.sb_durability_width.tb:GetText())
    if wear_w ~= nil then widgets.equipment_wear.width = wear_w end
    widgets.equipment_wear.icon = self.controls.sb_durability_icon.cb:IsChecked() == true
    widgets.equipment_wear.text_alignment = self.controls.sb_durability_text_alignment:get_value()
    widgets.equipment_wear.coloring = self.controls.sb_durability_coloring.cb:IsChecked() == true
    local wear_green = self.hex_to_color(self.controls.sb_durability_green.tb:GetText())
    if wear_green ~= nil then widgets.equipment_wear.color.green = wear_green end
    local wear_yellow = self.hex_to_color(self.controls.sb_durability_yellow.tb:GetText())
    if wear_yellow ~= nil then widgets.equipment_wear.color.yellow = wear_yellow end
    local wear_red = self.hex_to_color(self.controls.sb_durability_red.tb:GetText())
    if wear_red ~= nil then widgets.equipment_wear.color.red = wear_red end

    local money_w = tonumber(self.controls.sb_money_width.tb:GetText())
    if money_w ~= nil then widgets.money.width = money_w end
    widgets.money.icon = self.controls.sb_money_icon.cb:IsChecked() == true
    widgets.money.text_alignment = self.controls.sb_money_text_alignment:get_value()

    local wallet_w = tonumber(self.controls.sb_wallet_width.tb:GetText())
    if wallet_w ~= nil then widgets.wallet.width = wallet_w end
    widgets.wallet.text_alignment = self.controls.sb_wallet_text_alignment:get_value()
    widgets.wallet.items = self.controls.sb_wallet_items:get_items()

    local item_w = tonumber(self.controls.sb_item_width.tb:GetText())
    if item_w ~= nil then widgets.item.width = item_w end

    local shortcut_w = tonumber(self.controls.sb_shortcut_width.tb:GetText())
    if shortcut_w ~= nil then widgets.shortcut.width = shortcut_w end
    local shortcut_h = tonumber(self.controls.sb_shortcut_height.tb:GetText())
    if shortcut_h ~= nil then widgets.shortcut.height = shortcut_h end
end

function StatusBarPage:load_from_settings(s)
    self:load(s.status_bar)
end

function StatusBarPage:apply_to_settings(s)
    self:apply(s.status_bar)
end
