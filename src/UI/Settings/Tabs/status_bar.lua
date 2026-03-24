import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.StatusBar.common"

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

local function _create_wallet_selector(window, ui, key)
    local entry = ui.add_custom(key, WALLET_SELECTOR_HEIGHT)
    entry.window = window
    entry.selected_items = {}
    entry.available_entries = {}
    entry.selected_entries = {}
    entry.available_buttons = {}
    entry.selected_buttons = {}
    entry.filter_text = ""
    entry.active_list = nil
    entry.available_index = nil
    entry.selected_index = nil

    entry.available_label = Turbine.UI.Label()
    entry.available_label:SetParent(entry.control)
    entry.available_label:SetFont(window.field_label_font)
    entry.available_label:SetMultiline(true)
    entry.available_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.available_label:SetText(TR("All wallet items"))
    entry.available_label:SetZOrder(1)

    entry.selected_label = Turbine.UI.Label()
    entry.selected_label:SetParent(entry.control)
    entry.selected_label:SetFont(window.field_label_font)
    entry.selected_label:SetMultiline(true)
    entry.selected_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.selected_label:SetText(TR("Shown in %wallet%"))
    entry.selected_label:SetZOrder(1)

    entry.available_filter = Turbine.UI.Lotro.TextBox()
    entry.available_filter:SetParent(entry.control)
    entry.available_filter:SetFont(window.input_font)
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

    entry.apply_ui_scale = function()
        entry.available_label:SetFont(window.field_label_font)
        entry.selected_label:SetFont(window.field_label_font)
        entry.available_filter:SetFont(window.input_font)
        entry.add_button:SetScale(_G.settings.global.scale)
        entry.add_button:SetFont(window.settings_font)
        entry.remove_button:SetScale(_G.settings.global.scale)
        entry.remove_button:SetFont(window.settings_font)
        entry.up_button:SetScale(_G.settings.global.scale)
        entry.up_button:SetFont(window.settings_font)
        entry.down_button:SetScale(_G.settings.global.scale)
        entry.down_button:SetFont(window.settings_font)

        for i = 1, #entry.available_buttons do
            local button = entry.available_buttons[i]
            if button ~= nil then
                button:SetScale(_G.settings.global.scale)
                button:SetFont(window.input_font)
            end
        end

        for i = 1, #entry.selected_buttons do
            local button = entry.selected_buttons[i]
            if button ~= nil then
                button:SetScale(_G.settings.global.scale)
                button:SetFont(window.input_font)
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

StatusBar = {
    key = "status_bar",
    text = TR("Status Bar"),
}

local function _is_outline(control)
    local v = control:get_value()
    return v == LUI_ENUMS.font_style.OUTLINE
end

function StatusBar.create_controls(window, ui)
    local time_format_labels = { TR("24-hour"), TR("AM/PM") }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }

    ui.add_checkbox("sb_enabled", TR("Enabled"), true)

    ui.add_text("sb_bg_opacity", TR("Background opacity (0..1)"))
    ui.add_text("sb_bg_color", TR("Background color"), true)

    ui.add_dropdown("sb_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("sb_font_size", TR("Font size"))
    ui.add_text("sb_font_color", TR("Font color"), true)
    ui.add_dropdown("sb_font_style", TR("Font style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("sb_font_outline_color", TR("Outline color"), true)

    ui.add_text("sb_height", TR("Height"))

    local layout_help = table.concat({
        TR("Tokens:"),
        TR("  %time% - local time (HH:MM)"),
        TR("  %inventory% - backpack used/total"),
        TR("  %durability% - equipped wear average% (weakest%)"),
        TR("  %gold% / %money% - money (g/s/c)"),
        TR("  %wallet% - selected wallet items"),
        TR("  %item:[Simple Fish]% - tracked total for one inventory item"),
        TR("  %config:icon% / %config:text% - toggle configuration window"),
        TR("  %bestiary:icon% / %bestiary:text% - toggle bestiary window"),
        TR("  %assets:icon% / %assets:text% - toggle assets window"),
        "",
        TR("Drag an item from the inventory window onto the status bar to add it."),
        TR("Closing config via shortcut acts like Cancel."),
        TR("Order matters. Unknown tokens are ignored."),
        TR("Example: %config:icon% %time% %item:[Simple Fish]% %assets:text%"),
    }, "\n")

    ui.add_text("sb_layout_left", TR("Left layout"), false, layout_help, true)
    ui.add_text("sb_layout_center", TR("Center layout"), false, layout_help, true)
    ui.add_text("sb_layout_right", TR("Right layout"), false, layout_help, true)

    ui.add_text("sb_time_width", TR("Width"))
    ui.add_dropdown("sb_time_format", TR("Time format"), time_format_labels, time_format_values)
    ui.add_dropdown("sb_time_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)

    ui.add_text("sb_inv_width", TR("Width"))
    ui.add_checkbox("sb_inv_icon", TR("Icon"))
    ui.add_dropdown("sb_inv_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
    ui.add_text("sb_inv_yellow", TR("Warn color (30%)"), true)
    ui.add_text("sb_inv_orange", TR("Warn color (20%)"), true)
    ui.add_text("sb_inv_red", TR("Warn color (10%)"), true)

    ui.add_text("sb_durability_width", TR("Width"))
    ui.add_checkbox("sb_durability_icon", TR("Icon"))
    ui.add_dropdown("sb_durability_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
    ui.add_checkbox("sb_durability_coloring", TR("Enable rich-text coloring"), true)
    ui.add_text("sb_durability_pristine", TR("Pristine color"), true)
    ui.add_text("sb_durability_worn", TR("Worn color"), true)
    ui.add_text("sb_durability_damaged", TR("Damaged color"), true)
    ui.add_text("sb_durability_broken", TR("Broken color"), true)

    ui.add_text("sb_money_width", TR("Width"))
    ui.add_checkbox("sb_money_icon", TR("Icon"))
    ui.add_dropdown("sb_money_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)

    ui.add_text("sb_wallet_width", TR("Width"))
    ui.add_dropdown("sb_wallet_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
    _create_wallet_selector(window, ui, "sb_wallet_items")

    ui.add_text("sb_item_width", TR("Width"))

    ui.add_text("sb_shortcut_icon_width", TR("Icon width"))
    ui.add_text("sb_shortcut_icon_height", TR("Icon height"))
    ui.add_text("sb_shortcut_text_width", TR("Text width"))
    ui.add_text("sb_shortcut_text_height", TR("Text height"))
end

function StatusBar.register(window, ui)
    window.controls.sb_font_outline_color.visible_if = function() return _is_outline(window.controls.sb_font_style) end

    return {
        ui.add_title(TR("Status Bar")),

        ui.add_hr(),
        ui.add_title(TR("General")),
        window.controls.sb_enabled,

        ui.add_hr(),
        ui.add_title(TR("Background")),
        window.controls.sb_bg_opacity,
        window.controls.sb_bg_color,

        ui.add_hr(),
        ui.add_title(TR("Font")),
        window.controls.sb_font_name,
        window.controls.sb_font_size,
        window.controls.sb_font_color,
        window.controls.sb_font_style,
        window.controls.sb_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Layout")),
        window.controls.sb_height,

        ui.add_hr(),
        ui.add_title(TR("Widgets order")),
        window.controls.sb_layout_left,
        window.controls.sb_layout_center,
        window.controls.sb_layout_right,

        ui.add_hr(),
        ui.add_title(TR("Widgets")),

        ui.add_hr(),
        ui.add_title(TR("Time (local)")),
        window.controls.sb_time_width,
        window.controls.sb_time_format,
        window.controls.sb_time_text_alignment,

        ui.add_hr(),
        ui.add_title(TR("Inventory space")),
        window.controls.sb_inv_width,
        window.controls.sb_inv_icon,
        window.controls.sb_inv_text_alignment,
        window.controls.sb_inv_yellow,
        window.controls.sb_inv_orange,
        window.controls.sb_inv_red,

        ui.add_hr(),
        ui.add_title(TR("Equipment wear")),
        window.controls.sb_durability_width,
        window.controls.sb_durability_icon,
        window.controls.sb_durability_text_alignment,
        window.controls.sb_durability_coloring,
        window.controls.sb_durability_pristine,
        window.controls.sb_durability_worn,
        window.controls.sb_durability_damaged,
        window.controls.sb_durability_broken,

        ui.add_hr(),
        ui.add_title(TR("Money")),
        window.controls.sb_money_width,
        window.controls.sb_money_icon,
        window.controls.sb_money_text_alignment,

        ui.add_hr(),
        ui.add_title(TR("Wallet")),
        window.controls.sb_wallet_width,
        window.controls.sb_wallet_text_alignment,
        window.controls.sb_wallet_items,

        ui.add_hr(),
        ui.add_title(TR("Tracked item")),
        window.controls.sb_item_width,

        ui.add_hr(),
        ui.add_title(TR("Shortcut buttons")),
        window.controls.sb_shortcut_icon_width,
        window.controls.sb_shortcut_icon_height,
        window.controls.sb_shortcut_text_width,
        window.controls.sb_shortcut_text_height,
    }
end

function StatusBar.load(window, s, ui)
    local sb = s.status_bar

    window.controls.sb_enabled.cb:SetChecked(sb.enabled == true)
    window.controls.sb_bg_opacity.tb:SetText(tostring(sb.bg.opacity))
    window.controls.sb_bg_color.tb:SetText(ui.color_to_hex(sb.bg.color))

    window.controls.sb_font_name:set_value(sb.font.name)
    window.controls.sb_font_size.tb:SetText(tostring(sb.font.size))
    window.controls.sb_font_color.tb:SetText(ui.color_to_hex(sb.font.color))
    window.controls.sb_font_style:set_value(sb.font.style)
    window.controls.sb_font_outline_color.tb:SetText(ui.color_to_hex(sb.font.outline_color))

    window.controls.sb_height.tb:SetText(tostring(sb.height))

    local widgets = sb.widgets

    window.controls.sb_layout_left.tb:SetText(tostring(sb.layout.left or ""))
    window.controls.sb_layout_center.tb:SetText(tostring(sb.layout.center or ""))
    window.controls.sb_layout_right.tb:SetText(tostring(sb.layout.right or ""))

    local time = widgets.time_local
    window.controls.sb_time_width.tb:SetText(tostring(time.width))
    window.controls.sb_time_format:set_value(time.time_format)
    window.controls.sb_time_text_alignment:set_value(time.text_alignment)

    local inv = widgets.inventory_space
    window.controls.sb_inv_width.tb:SetText(tostring(inv.width))
    window.controls.sb_inv_icon.cb:SetChecked(inv.icon == true)
    window.controls.sb_inv_text_alignment:set_value(inv.text_alignment)
    window.controls.sb_inv_yellow.tb:SetText(ui.color_to_hex(inv.color.yellow))
    window.controls.sb_inv_orange.tb:SetText(ui.color_to_hex(inv.color.orange))
    window.controls.sb_inv_red.tb:SetText(ui.color_to_hex(inv.color.red))

    local wear = widgets.equipment_wear
    window.controls.sb_durability_width.tb:SetText(tostring(wear.width))
    window.controls.sb_durability_icon.cb:SetChecked(wear.icon == true)
    window.controls.sb_durability_text_alignment:set_value(wear.text_alignment)
    window.controls.sb_durability_coloring.cb:SetChecked(wear.coloring == true)
    window.controls.sb_durability_pristine.tb:SetText(ui.color_to_hex(wear.color.pristine))
    window.controls.sb_durability_worn.tb:SetText(ui.color_to_hex(wear.color.worn))
    window.controls.sb_durability_damaged.tb:SetText(ui.color_to_hex(wear.color.damaged))
    window.controls.sb_durability_broken.tb:SetText(ui.color_to_hex(wear.color.broken))

    local money = widgets.money
    window.controls.sb_money_width.tb:SetText(tostring(money.width))
    window.controls.sb_money_icon.cb:SetChecked(money.icon == true)
    window.controls.sb_money_text_alignment:set_value(money.text_alignment)

    local wallet = widgets.wallet
    window.controls.sb_wallet_width.tb:SetText(tostring(wallet.width))
    window.controls.sb_wallet_text_alignment:set_value(wallet.text_alignment)
    window.controls.sb_wallet_items:set_items(wallet.items)

    window.controls.sb_item_width.tb:SetText(tostring(widgets.item.width))

    window.controls.sb_shortcut_icon_width.tb:SetText(tostring(widgets.shortcut_icon.width))
    window.controls.sb_shortcut_icon_height.tb:SetText(tostring(widgets.shortcut_icon.height))
    window.controls.sb_shortcut_text_width.tb:SetText(tostring(widgets.shortcut_text.width))
    window.controls.sb_shortcut_text_height.tb:SetText(tostring(widgets.shortcut_text.height))
end

function StatusBar.apply(window, s, ui)
    local sb = s.status_bar

    sb.enabled = window.controls.sb_enabled.cb:IsChecked() == true

    local bg_opacity = tonumber(window.controls.sb_bg_opacity.tb:GetText())
    if bg_opacity ~= nil then sb.bg.opacity = bg_opacity end
    local bg_color = ui.hex_to_color(window.controls.sb_bg_color.tb:GetText())
    if bg_color ~= nil then sb.bg.color = bg_color end

    sb.font.name = window.controls.sb_font_name:get_value()
    local font_size = tonumber(window.controls.sb_font_size.tb:GetText())
    if font_size ~= nil then sb.font.size = font_size end
    local font_color = ui.hex_to_color(window.controls.sb_font_color.tb:GetText())
    if font_color ~= nil then sb.font.color = font_color end
    sb.font.style = window.controls.sb_font_style:get_value()
    local outline_color = ui.hex_to_color(window.controls.sb_font_outline_color.tb:GetText())
    if outline_color ~= nil then sb.font.outline_color = outline_color end

    local height = tonumber(window.controls.sb_height.tb:GetText())
    if height ~= nil then sb.height = height end

    sb.layout.left = window.controls.sb_layout_left.tb:GetText() or ""
    sb.layout.center = window.controls.sb_layout_center.tb:GetText() or ""
    sb.layout.right = window.controls.sb_layout_right.tb:GetText() or ""

    local widgets = sb.widgets

    local time_w = tonumber(window.controls.sb_time_width.tb:GetText())
    if time_w ~= nil then widgets.time_local.width = time_w end
    widgets.time_local.time_format = window.controls.sb_time_format:get_value()
    widgets.time_local.text_alignment = window.controls.sb_time_text_alignment:get_value()

    local inv_w = tonumber(window.controls.sb_inv_width.tb:GetText())
    if inv_w ~= nil then widgets.inventory_space.width = inv_w end
    widgets.inventory_space.icon = window.controls.sb_inv_icon.cb:IsChecked() == true
    widgets.inventory_space.text_alignment = window.controls.sb_inv_text_alignment:get_value()
    local inv_y = ui.hex_to_color(window.controls.sb_inv_yellow.tb:GetText())
    if inv_y ~= nil then widgets.inventory_space.color.yellow = inv_y end
    local inv_o = ui.hex_to_color(window.controls.sb_inv_orange.tb:GetText())
    if inv_o ~= nil then widgets.inventory_space.color.orange = inv_o end
    local inv_r = ui.hex_to_color(window.controls.sb_inv_red.tb:GetText())
    if inv_r ~= nil then widgets.inventory_space.color.red = inv_r end

    local wear_w = tonumber(window.controls.sb_durability_width.tb:GetText())
    if wear_w ~= nil then widgets.equipment_wear.width = wear_w end
    widgets.equipment_wear.icon = window.controls.sb_durability_icon.cb:IsChecked() == true
    widgets.equipment_wear.text_alignment = window.controls.sb_durability_text_alignment:get_value()
    widgets.equipment_wear.coloring = window.controls.sb_durability_coloring.cb:IsChecked() == true
    local wear_pristine = ui.hex_to_color(window.controls.sb_durability_pristine.tb:GetText())
    if wear_pristine ~= nil then widgets.equipment_wear.color.pristine = wear_pristine end
    local wear_worn = ui.hex_to_color(window.controls.sb_durability_worn.tb:GetText())
    if wear_worn ~= nil then widgets.equipment_wear.color.worn = wear_worn end
    local wear_damaged = ui.hex_to_color(window.controls.sb_durability_damaged.tb:GetText())
    if wear_damaged ~= nil then widgets.equipment_wear.color.damaged = wear_damaged end
    local wear_broken = ui.hex_to_color(window.controls.sb_durability_broken.tb:GetText())
    if wear_broken ~= nil then widgets.equipment_wear.color.broken = wear_broken end

    local money_w = tonumber(window.controls.sb_money_width.tb:GetText())
    if money_w ~= nil then widgets.money.width = money_w end
    widgets.money.icon = window.controls.sb_money_icon.cb:IsChecked() == true
    widgets.money.text_alignment = window.controls.sb_money_text_alignment:get_value()

    local wallet_w = tonumber(window.controls.sb_wallet_width.tb:GetText())
    if wallet_w ~= nil then widgets.wallet.width = wallet_w end
    widgets.wallet.text_alignment = window.controls.sb_wallet_text_alignment:get_value()
    widgets.wallet.items = window.controls.sb_wallet_items:get_items()

    local item_w = tonumber(window.controls.sb_item_width.tb:GetText())
    if item_w ~= nil then widgets.item.width = item_w end

    local shortcut_icon_w = tonumber(window.controls.sb_shortcut_icon_width.tb:GetText())
    if shortcut_icon_w ~= nil then widgets.shortcut_icon.width = shortcut_icon_w end
    local shortcut_icon_h = tonumber(window.controls.sb_shortcut_icon_height.tb:GetText())
    if shortcut_icon_h ~= nil then widgets.shortcut_icon.height = shortcut_icon_h end
    local shortcut_text_w = tonumber(window.controls.sb_shortcut_text_width.tb:GetText())
    if shortcut_text_w ~= nil then widgets.shortcut_text.width = shortcut_text_w end
    local shortcut_text_h = tonumber(window.controls.sb_shortcut_text_height.tb:GetText())
    if shortcut_text_h ~= nil then widgets.shortcut_text.height = shortcut_text_h end
end
