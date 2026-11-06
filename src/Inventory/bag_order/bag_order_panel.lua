-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Bag Order Guide window, left panel: the marker box (built like the Upkeep
-- slot editor's drop cells), the step header and progress, the bag
-- question (setup 1), the step instructions, the status line, the buttons
-- and the bag-key note.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Inventory = _G.LUI.Features.Inventory
import "Turbine.UI"
import "LUI.src.UI.Widgets"
import "LUI.src.Inventory.bag_order.bag_order_model"
import "LUI.src.Inventory.bag_order.bag_order_common"
import "LUI.src.Inventory.bag_order.bag_order_window"

local Style = UI.Widgets.Style
local Model = Inventory.BagOrderModel
local Common = Inventory.BagOrderCommon
local BagOrderWindow = Inventory.BagOrderWindow
local ROW_SIZE = Model.ROW_SIZE
local label = Common.label
local block = Common.block
local place = Common.place

local ACTION_LINES = 3
local HOW_LINES = 3
local STATUS_LINES = 2
local NOTE_LINES = 2
local INFO_LINES = 3
local MARKER_STATUS_LINES = 3

local LEFT = Turbine.UI.ContentAlignment.MiddleLeft
local TOP_LEFT = Turbine.UI.ContentAlignment.TopLeft
local CENTER = Turbine.UI.ContentAlignment.MiddleCenter

function BagOrderWindow:_button(text, click)
    local button = UI.Widgets.LuiButton()
    button:SetParent(self.panel)
    button:set_scale(State.settings.global.scale)
    button:set_font(self.font)
    button:set_text(text)
    button.Click = click
    return button
end

function BagOrderWindow:_spin(minimum, maximum, on_change)
    local spin = UI.Widgets.LuiSpinBox()
    spin:SetParent(self.panel)
    spin:set_scale(State.settings.global.scale)
    spin:set_minimum(minimum)
    spin:set_maximum(maximum)
    spin:set_on_change(function(_, value)
        on_change(value)
    end)
    return spin
end

function BagOrderWindow:_build_panel()
    self.panel = Turbine.UI.Control()
    self.panel:SetParent(self.content)
    self.panel:SetMouseVisible(true)

    -- marker box
    self.marker_help = label(self.panel, self.font, Style.FOREGROUND, TOP_LEFT, true)
    self.marker_frame = block(self.panel, Style.CONTROL_BORDER)
    self.marker_inner = block(self.marker_frame, Style.BACKGROUND)
    self.marker_inner:SetPosition(1, 1)
    self.marker_inner:SetSize(self.box_size, self.box_size)
    -- a plain drop area, never a quickslot (same reason as Upkeep)
    self.marker_drop = Turbine.UI.Control()
    self.marker_drop:SetParent(self.panel)
    self.marker_drop:SetAllowDrop(true)
    self.marker_drop.DragDrop = function(_, args)
        self:_drop_marker(args.DragDropInfo)
    end
    self.marker_back = UI.Widgets.Image()
    self.marker_back:SetParent(self.marker_drop)
    self.marker_icon = UI.Widgets.Image()
    self.marker_icon:SetParent(self.marker_drop)
    self.marker_name = label(self.panel, self.font, Style.FOREGROUND, CENTER, false)
    self.marker_status = label(self.panel, self.font, Style.INFO_FOREGROUND, Turbine.UI.ContentAlignment.TopCenter, true)
    self.clear_button = self:_button(TR["Clear"], function()
        self:_clear_marker()
    end)
    self.marker_separator = block(self.panel, Style.SEPARATOR)

    -- step header
    self.step_label = label(self.panel, self.small_font, Style.SUBTLE_FOREGROUND, LEFT, false)
    self.progress_back = block(self.panel, Style.CONTROL_BORDER)
    self.progress_fill = block(self.panel, Style.ACCENT_BACKGROUND)
    self.title_label = label(self.panel, self.title_font, Style.FOREGROUND, LEFT, false)

    -- setup 1: the bags
    self.bags_question = label(self.panel, self.font, Style.FOREGROUND, LEFT, false)
    self.bags_question:SetText(TR["How many bags do you have?"])
    self.bags_spin = self:_spin(1, Model.MAX_BAGS, function(value)
        self:_set_bag_count(value)
    end)
    self.rows_info = label(self.panel, self.font, Style.FOREGROUND, TOP_LEFT, true)
    self.bag_labels = {}
    self.bag_spins = {}
    for bag = 1, Model.MAX_BAGS do
        self.bag_labels[bag] = label(self.panel, self.font, Style.FOREGROUND, LEFT, false)
        self.bag_labels[bag]:SetText(string.format(TR["Bag %d rows"], bag))
        self.bag_spins[bag] = self:_spin(0, self.row_count, function(value)
            self:_set_bag_rows(bag, value)
        end)
    end
    self.last_rows_label = label(self.panel, self.font, Style.FOREGROUND, CENTER, false)
    self.bags_spin:set_value(self.bag_count, false)
    self:_sync_row_spins()

    -- steps
    self.action_label = label(self.panel, self.action_font, Style.ACCENT_FOREGROUND, TOP_LEFT, true)
    self.how_label = label(self.panel, self.font, Style.FOREGROUND, TOP_LEFT, true)
    self.done_label = label(self.panel, self.font, Style.SUBTLE_FOREGROUND, LEFT, false)
    self.done_label:SetText(TR["Done? Click Next."])
    self.status_label = label(self.panel, self.font, Style.INFO_FOREGROUND, TOP_LEFT, true)

    self.back_button = self:_button(TR["Back"], function()
        self:_back()
    end)
    self.retry_button = self:_button(TR["Try again"], function()
        self.move_error = nil
        self:_refresh_view()
        self:_request_marker_move()
    end)
    self.next_button = self:_button(TR["Next"], function()
        self:_next()
    end)
    self.restart_button = self:_button(TR["Restart"], function()
        self:_restart()
    end)
    self.put_back_button = self:_button(TR["Put the item back"], function()
        self.put_back = true
        self.move_error = nil
        self:_refresh_view()
        self:_request_marker_move()
    end)
    self.close_button = self:_button(TR["Close"], function()
        UI.Shortcuts.close_bag_order_guide()
    end)

    self.key_note = label(self.panel, self.small_font, Style.SUBTLE_FOREGROUND, TOP_LEFT, true)
    self.key_note:SetText(TR["While this window is open, the bag key opens the game's bags, not the LUI inventory."])

    self.panel_separator = block(self.content, Style.SEPARATOR)
end

---------------------------------------------------------------------
-- Texts
---------------------------------------------------------------------

function BagOrderWindow:_refresh_texts()
    local phase = self.phase
    local steps_count = 0
    if self.steps ~= nil then
        steps_count = #self.steps
    end
    self._progress = 0

    if phase == Common.PHASE_BAGS then
        self.step_label:SetText(TR["Setup 1 of 2"])
        self.title_label:SetText(TR["Your bags"])
        self.rows_info:SetText(string.format(
            TR["Your backpack has %d rows of %d slots. Choose how many rows each bag gets; the list shows the result. The last bag takes the rest."],
            self.row_count, ROW_SIZE))
    elseif phase == Common.PHASE_MARKER then
        self.step_label:SetText(TR["Setup 2 of 2"])
        self.title_label:SetText(TR["Pick a marker item"])
        self.action_label:SetText(TR["Open your game bags and place them next to this window."])
        self.how_label:SetText(TR["The guide moves the marker into each row in turn, so you can spot the row in your bags. Pick an item you have only once and that stands out."])
        self.marker_help:SetText(TR["Drag an item from your bags into the box, or click it in the list."])
    elseif phase == Common.PHASE_STEPS then
        local step = self.steps[self.step_index]
        self._progress = (self.step_index - 1) / steps_count
        self.step_label:SetText(string.format(TR["Step %d of %d"], self.step_index, steps_count))
        if step.kind == "empty" then
            self.title_label:SetText(string.format(TR["Empty Bag %d"], step.bag))
            self.action_label:SetText(string.format(TR["Drag every row of Bag %d to the bottom of Bag %d."], step.bag, step.into))
            self.how_label:SetText(string.format(TR["Bag %d must be completely empty. If it already is, just click Next."], step.bag))
        else
            self.title_label:SetText(string.format(TR["Bag %d - row %d of %d"], step.bag, step.position, step.count))
            self.action_label:SetText(string.format(TR["Find the marker in your bags and drag its whole row to the bottom of Bag %d."], step.bag))
            self.how_label:SetText(string.format(TR["It is the row with slots %d to %d. A row always lands at the bottom of the bag."],
                Model.first_slot(step.row), Model.last_slot(step.row, self.slot_count)))
        end
        self.marker_help:SetText(TR["Look for this item in your bags:"])
    else
        self._progress = 1
        self.step_label:SetText(string.format(TR["Step %d of %d"], steps_count, steps_count))
        self.title_label:SetText(TR["Done"])
        self.action_label:SetText(TR["Your bags now follow the slot order: Bag 1 starts with slot 1."])
        self.how_label:SetText(TR["You can put the marker back where it was, then close this window."])
        self.marker_help:SetText(TR["Marker:"])
    end

    self:_refresh_marker_box()
    self.marker_status:SetText(self.marker_error or "")
end

-- the marker's images and name, set again only when the marker changes
function BagOrderWindow:_refresh_marker_box()
    local marker = self.marker
    if marker == self._box_marker then
        return
    end
    self._box_marker = marker
    self.marker_back:SetVisible(false)
    self.marker_icon:SetVisible(false)
    if marker == nil then
        self.marker_name:SetText("")
        return
    end
    self.marker_name:SetText(marker.name)
    if marker.background_id ~= 0 then
        self.marker_back:set_icon(marker.background_id, self.box_size, self.box_size)
    end
    if marker.icon_id ~= 0 then
        self.marker_icon:set_icon(marker.icon_id, self.box_size, self.box_size)
    end
end

-- the status line (errors first, then the marker's move) and Next
function BagOrderWindow:_refresh_status()
    local text = ""
    local phase = self.phase
    if self.size_error ~= nil then
        text = self.size_error
    elseif phase == Common.PHASE_BAGS then
        if self.bag_count < 2 then
            text = TR["With one bag, rows cannot move to another bag, so their order cannot change: there is nothing to fix."]
        elseif self.rows[self.bag_count] < 0 then
            text = TR["The bags get more rows than your backpack has. Lower a bag's rows."]
        end
    elseif phase ~= Common.PHASE_MARKER then
        local target = self:_wanted_marker_slot()
        if self.marker_error ~= nil then
            text = TR["Fix the marker first (see above)."]
        elseif self.move_error ~= nil then
            text = self.move_error
        elseif self.waiting == true then
            text = TR["Waiting for the running inventory action..."]
        elseif self.moving == true then
            text = string.format(TR["Moving the marker to slot %d..."], self.moving_to)
        elseif target ~= nil and target ~= self.marker.slot then
            text = string.format(TR["Moving the marker to slot %d..."], target)
        elseif phase == Common.PHASE_STEPS and self.steps[self.step_index].kind == "add" then
            text = string.format(TR["The marker is in slot %d."], self.marker.slot)
        elseif phase == Common.PHASE_DONE and self.put_back == true then
            text = string.format(TR["The marker is back in slot %d."], self.marker.slot)
        end
    end
    self.status_label:SetText(text)
    self.next_button:set_enabled(self:_next_enabled())
end

function BagOrderWindow:_next_enabled()
    if self.size_error ~= nil then
        return false
    end
    if self.phase == Common.PHASE_BAGS then
        return self:_setup_valid()
    end
    return self.marker ~= nil and self.marker_error == nil
end

---------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------

-- the marker box (every phase but the bag question); returns the next y
function BagOrderWindow:_layout_marker_box(y)
    local w = self.panel_w
    local gap = self.gap
    local help_lines = 1
    if self.phase == Common.PHASE_MARKER then
        help_lines = 2
    end
    place(self.marker_help, 0, y, w, help_lines * self.line_h)
    y = y + (help_lines * self.line_h) + gap
    local box_x = math.floor((w - self.box_size - 2) / 2)
    place(self.marker_frame, box_x, y, self.box_size + 2, self.box_size + 2)
    place(self.marker_drop, box_x + 1, y + 1, self.box_size, self.box_size)
    y = y + self.box_size + 2 + gap
    place(self.marker_name, 0, y, w, self.line_h)
    y = y + self.line_h
    if self.marker_error ~= nil then
        place(self.marker_status, 0, y, w, MARKER_STATUS_LINES * self.line_h)
        y = y + (MARKER_STATUS_LINES * self.line_h)
    end
    if self.phase == Common.PHASE_MARKER and self.marker ~= nil then
        local button_w, button_h = self.clear_button:GetSize()
        place(self.clear_button, math.floor((w - button_w) / 2), y + gap, button_w, button_h)
        y = y + gap + button_h
    end
    y = y + gap
    place(self.marker_separator, 0, y, w, 1)
    return y + 1 + gap
end

-- setup 1: the bag count and one rows field per bag; returns the next y
function BagOrderWindow:_layout_bags(y)
    local w = self.panel_w
    local gap = self.gap
    local spin_w, spin_h = self.bags_spin:GetSize()
    local row_h = math.max(spin_h, self.line_h)
    place(self.bags_question, 0, y, w - spin_w - gap, row_h)
    place(self.bags_spin, w - spin_w, y, spin_w, spin_h)
    y = y + row_h + gap
    place(self.rows_info, 0, y, w, INFO_LINES * self.line_h)
    y = y + (INFO_LINES * self.line_h) + gap
    for bag = 1, self.bag_count do
        place(self.bag_labels[bag], 0, y, w - spin_w - gap, row_h)
        if bag < self.bag_count then
            place(self.bag_spins[bag], w - spin_w, y, spin_w, spin_h)
        else
            place(self.last_rows_label, w - spin_w, y, spin_w, row_h)
        end
        y = y + row_h + 2
    end
    return y + gap
end

-- the phase's buttons side by side; returns the next y
function BagOrderWindow:_layout_buttons(y)
    local phase = self.phase
    local visible = {}
    if phase ~= Common.PHASE_BAGS then
        visible[#visible + 1] = self.back_button
    end
    if self.move_error ~= nil then
        visible[#visible + 1] = self.retry_button
    end
    if phase == Common.PHASE_DONE then
        visible[#visible + 1] = self.put_back_button
        visible[#visible + 1] = self.close_button
    else
        visible[#visible + 1] = self.next_button
    end
    if phase == Common.PHASE_STEPS then
        visible[#visible + 1] = self.restart_button
    end
    local _, button_h = self.next_button:GetSize()
    local button_w = math.floor((self.panel_w - ((#visible - 1) * self.gap)) / #visible)
    for i = 1, #visible do
        place(visible[i], (i - 1) * (button_w + self.gap), y, button_w, button_h)
    end
    return y + button_h + self.gap
end

local function _hide_all(controls)
    for i = 1, #controls do
        controls[i]:SetVisible(false)
    end
end

-- stacks the panel for the current phase; returns its height
function BagOrderWindow:_layout_panel()
    local phase = self.phase
    local w = self.panel_w
    local gap = self.gap

    _hide_all({
        self.marker_help, self.marker_frame, self.marker_drop, self.marker_name, self.marker_status,
        self.clear_button, self.marker_separator, self.bags_question, self.bags_spin, self.rows_info,
        self.last_rows_label, self.action_label, self.how_label, self.done_label, self.back_button,
        self.retry_button, self.next_button, self.restart_button, self.put_back_button, self.close_button,
    })
    _hide_all(self.bag_labels)
    _hide_all(self.bag_spins)

    local y = 0
    if phase ~= Common.PHASE_BAGS then
        y = self:_layout_marker_box(y)
    end

    place(self.step_label, 0, y, w, self.small_line_h)
    y = y + self.small_line_h + 2
    place(self.progress_back, 0, y, w, self.progress_h)
    place(self.progress_fill, 0, y, math.floor(w * self._progress), self.progress_h)
    self.progress_fill:SetVisible(self._progress > 0)
    y = y + self.progress_h + gap
    place(self.title_label, 0, y, w, self.title_h)
    y = y + self.title_h + gap

    if phase == Common.PHASE_BAGS then
        y = self:_layout_bags(y)
    else
        place(self.action_label, 0, y, w, ACTION_LINES * self.action_line_h)
        y = y + (ACTION_LINES * self.action_line_h) + gap
        place(self.how_label, 0, y, w, HOW_LINES * self.line_h)
        y = y + (HOW_LINES * self.line_h) + gap
        if phase == Common.PHASE_STEPS then
            place(self.done_label, 0, y, w, self.line_h)
            y = y + self.line_h + gap
        end
    end
    place(self.status_label, 0, y, w, STATUS_LINES * self.line_h)
    y = y + (STATUS_LINES * self.line_h) + gap

    y = self:_layout_buttons(y)
    place(self.key_note, 0, y, w, NOTE_LINES * self.small_line_h)
    return y + (NOTE_LINES * self.small_line_h)
end
