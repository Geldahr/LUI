-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Bag Order Guide window (Settings > Inventory > General): walks the player
-- through putting the game's bag rows back in slot order. Left: the step
-- guide and the marker box (bag_order_panel); right: the backpack in slot
-- order, 5 slots per row, laid out as the target bags (bag_order_list,
-- read-only). The marker item is moved into each row's first slot in turn
-- (bag_order_marker); the player finds it in the game's bags and drags its
-- row. This file: construction, lifecycle, backpack state, navigation.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Inventory = _G.LUI.Features.Inventory
local Windows = _G.LUI.Runtime.Windows
local Utils = _G.LUI.Utils
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.callbacks"
import "LUI.src.Inventory.operations"
import "LUI.src.Inventory.bag_order.bag_order_model"
import "LUI.src.Inventory.bag_order.bag_order_common"

local Operations = Inventory.Operations
local Model = Inventory.BagOrderModel
local Common = Inventory.BagOrderCommon
local ROW_SIZE = Model.ROW_SIZE
local scaled = Common.scaled
local scaled_even = Common.scaled_even
local place = Common.place

---@class BagOrderWindow : UI.Widgets.LuiWindow
local BagOrderWindow = class(UI.Widgets.LuiWindow)
Inventory.BagOrderWindow = BagOrderWindow

local DEFAULT_BAGS = Model.MAX_BAGS
local BACKPACK_EVENTS = { "ItemAdded", "ItemRemoved", "ItemMoved", "ItemChanged" }

function BagOrderWindow:Constructor()
    UI.Widgets.LuiWindow.Constructor(self)

    self:set_title(TR["Bag Order Guide"])
    UI.Shortcuts.apply_window_icon(self, "inventory")
    self:set_resizable(false)
    self:enable_maximize(false)
    self:hide()
    self:SetWantsUpdates(false)
    self:set_close_handler(function()
        UI.Shortcuts.close_bag_order_guide()
    end)
    UI.Widgets.LuiWindow.apply_settings(self, State.settings.global.scale)

    self.backpack = Windows.inventory.backpack
    self.entries = Operations.snapshot(self.backpack)
    self.slot_count = #self.entries
    self.row_count = Model.row_count(self.slot_count)
    self.bag_count = DEFAULT_BAGS
    self.rows = Model.even_rows(self.row_count, self.bag_count)
    self.phase = Common.PHASE_BAGS
    self.steps = nil
    self.step_index = 0
    -- { merge_key, name, icon_id, background_id, slot, home }
    self.marker = nil
    self.marker_error = nil
    self.move_error = nil
    self.size_error = nil
    self.moving = false
    self.moving_to = nil
    self.waiting = false
    self.put_back = false
    -- the marker move running in the inventory window, nil when none
    self._operation = nil
    self._progress = 0
    -- the marker the box shows; false = never drawn (nil is "no marker")
    self._box_marker = false
    self._refresh_due = false
    self._move_wanted = false
    self._retry_at = 0
    self._positioned = false

    self:_build_sizes()

    self.tooltip = UI.Widgets.LuiTooltip()
    self.tooltip:set_scale(State.settings.global.scale)
    -- ShowFor measures the text with this font
    self.tooltip:SetFont(self.font)
    self.tooltip:SetZOrder(2200)

    local central = Turbine.UI.Control()
    central:SetMouseVisible(true)
    self:set_central_widget(central)
    -- the frame around the central widget (title bar, borders) is fixed:
    -- measured once, on a window big enough to hold it
    self:SetSize(400, 300)
    UI.Widgets.LuiWindow._layout(self)
    local central_w, central_h = central:GetSize()
    self._chrome_w = 400 - central_w
    self._chrome_h = 300 - central_h
    self.content = Turbine.UI.Control()
    self.content:SetParent(central)
    self.content:SetMouseVisible(true)

    self:_build_panel()
    self:_build_list()

    self._backpack_callback = function()
        self:_backpack_changed()
    end
    for i = 1, #BACKPACK_EVENTS do
        Utils.add_callback(self.backpack, BACKPACK_EVENTS[i], self._backpack_callback)
    end

    self:_refresh_tiles()
    self:_refresh_view()
end

function BagOrderWindow:_build_sizes()
    self.margin = scaled(Common.BASE_MARGIN)
    self.panel_w = scaled(Common.BASE_PANEL_W)
    self.gap = scaled(Common.BASE_GAP)
    self.sep_gap = scaled(Common.BASE_SEP_GAP)
    self.icon_size = scaled_even(Common.BASE_ICON)
    self.tile_size = self.icon_size + 2
    self.tile_gap = scaled(Common.BASE_TILE_GAP)
    self.row_pad = scaled(Common.BASE_ROW_PAD)
    self.row_h = self.tile_size + (2 * self.row_pad)
    self.range_w = scaled(Common.BASE_RANGE_W)
    self.check_size = scaled_even(Common.BASE_CHECK)
    self.header_h = scaled(Common.BASE_HEADER_H)
    self.box_size = scaled_even(Common.BASE_BOX)
    self.progress_h = math.max(2, scaled(Common.BASE_PROGRESS_H))
    self.line_h = scaled(Common.BASE_LINE_H)
    self.small_line_h = scaled(Common.BASE_SMALL_LINE_H)
    self.action_line_h = scaled(Common.BASE_ACTION_LINE_H)
    self.title_h = scaled(Common.BASE_TITLE_H)
    self.column_w = self.range_w + self.gap + (ROW_SIZE * self.tile_size) + ((ROW_SIZE - 1) * self.tile_gap) +
        self.gap + self.check_size
    self.font = Common.font(Common.BASE_FONT)
    self.small_font = Common.font(Common.BASE_SMALL_FONT)
    self.action_font = Common.font(Common.BASE_ACTION_FONT)
    self.title_font = Common.font(Common.BASE_TITLE_FONT)
end

---------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------

function BagOrderWindow:open()
    if self._positioned ~= true then
        self._positioned = true
        local display_w, display_h = Turbine.UI.Display.GetSize()
        local width, height = self:GetSize()
        self:SetPosition(
            math.max(0, math.floor((display_w - width) / 2)),
            math.max(0, math.floor((display_h - height) / 2))
        )
    end
    self:show()
end

-- One-shot window: once closed nothing may keep it alive. A running marker
-- move finishes in the inventory window without calling back.
function BagOrderWindow:destroy()
    if self._operation ~= nil then
        self._operation.on_done = nil
        self._operation = nil
    end
    self:SetWantsUpdates(false)
    for i = 1, #BACKPACK_EVENTS do
        Utils.remove_callback(self.backpack, BACKPACK_EVENTS[i], self._backpack_callback)
    end
    self:unregister_hideable()
    self.tooltip:Hide()
    self:hide()
end

function BagOrderWindow:Update()
    if self._refresh_due == true then
        self._refresh_due = false
        self:_read_entries()
        self:_refresh_tiles()
        self:_refresh_view()
    end
    if self._move_wanted == true and Turbine.Engine.GetGameTime() >= self._retry_at then
        self:_request_marker_move()
    end
    self:_sync_updates()
end

---------------------------------------------------------------------
-- Backpack state
---------------------------------------------------------------------

-- backpack events come in bursts: refresh once, on the next frame
function BagOrderWindow:_backpack_changed()
    self._refresh_due = true
    self:_sync_updates()
end

function BagOrderWindow:_sync_updates()
    self:SetWantsUpdates(self._refresh_due == true or self._move_wanted == true)
end

-- reads the bag and follows the marker (the guide moves it, the player may
-- move it, a second one may arrive)
function BagOrderWindow:_read_entries()
    local entries = Operations.snapshot(self.backpack)
    if #entries ~= self.slot_count then
        self.size_error = TR["Your backpack size changed. Close the guide and open it again."]
        return
    end
    self.entries = entries
    local marker = self.marker
    if marker == nil then
        return
    end
    local slot = Model.find_marker(entries, marker.merge_key)
    if slot == nil then
        slot = Model.first_with_key(entries, marker.merge_key)
    end
    marker.slot = slot
    if slot == nil then
        self.marker_error = TR["The marker left your bags. Drag it back into the box, or pick another item."]
        return
    end
    self.marker_error = self:_problem_text(marker.name, Model.marker_problem(entries, slot))
end

---------------------------------------------------------------------
-- Setup values
---------------------------------------------------------------------

function BagOrderWindow:_set_bag_count(count)
    self.bag_count = count
    self.rows = Model.even_rows(self.row_count, count)
    self:_sync_row_spins()
    self:_refresh_view()
end

function BagOrderWindow:_set_bag_rows(bag, count)
    self.rows[bag] = count
    self:_sync_last_bag()
    self:_refresh_view()
end

function BagOrderWindow:_sync_row_spins()
    for bag = 1, self.bag_count - 1 do
        self.bag_spins[bag]:set_value(self.rows[bag], false)
    end
    self:_sync_last_bag()
end

-- the last bag takes the rows the others leave
function BagOrderWindow:_sync_last_bag()
    self.rows[self.bag_count] = Model.remainder(self.rows, self.bag_count, self.row_count)
    self.last_rows_label:SetText(tostring(self.rows[self.bag_count]))
end

-- the layout the list shows: never more rows than the backpack has
function BagOrderWindow:_shown_rows()
    local shown = {}
    local left = self.row_count
    for bag = 1, self.bag_count do
        shown[bag] = math.max(0, math.min(self.rows[bag], left))
        left = left - shown[bag]
    end
    return shown
end

function BagOrderWindow:_setup_valid()
    return self.bag_count >= 2 and self.rows[self.bag_count] >= 0
end

---------------------------------------------------------------------
-- Navigation
---------------------------------------------------------------------

function BagOrderWindow:_next()
    if self.phase == Common.PHASE_BAGS then
        self.phase = Common.PHASE_MARKER
    elseif self.phase == Common.PHASE_MARKER then
        self.steps = Model.build_steps(self.rows, self.bag_count)
        self.step_index = 1
        self.phase = Common.PHASE_STEPS
    elseif self.step_index < #self.steps then
        self.step_index = self.step_index + 1
    else
        self.phase = Common.PHASE_DONE
        self.put_back = false
    end
    self.move_error = nil
    self:_refresh_view()
    self:_request_marker_move()
end

function BagOrderWindow:_back()
    if self.phase == Common.PHASE_MARKER then
        self.phase = Common.PHASE_BAGS
    elseif self.phase == Common.PHASE_DONE then
        self.phase = Common.PHASE_STEPS
        self.step_index = #self.steps
        self.put_back = false
    elseif self.step_index > 1 then
        self.step_index = self.step_index - 1
    else
        self.phase = Common.PHASE_MARKER
    end
    self.move_error = nil
    self:_refresh_view()
    self:_request_marker_move()
end

function BagOrderWindow:_restart()
    self.phase = Common.PHASE_BAGS
    self.steps = nil
    self.step_index = 0
    self.put_back = false
    self.move_error = nil
    self:_refresh_view()
end

---------------------------------------------------------------------
-- View
---------------------------------------------------------------------

function BagOrderWindow:_refresh_view()
    self:_refresh_texts()
    self:_refresh_status()
    self:_layout_content()
    self:_refresh_highlight()
end

-- panel, separator, list; the window sizes itself to them (not named
-- _layout: that is LuiWindow's own chrome layout, run by its constructor)
function BagOrderWindow:_layout_content()
    local panel_h = self:_layout_panel()
    local list_w, list_h = self:_layout_list()

    local sep_x = self.panel_w + self.sep_gap
    local list_x = sep_x + 1 + self.sep_gap
    local content_w = list_x + list_w
    local content_h = math.max(panel_h, list_h)
    place(self.panel, 0, 0, self.panel_w, panel_h)
    place(self.panel_separator, sep_x, 0, 1, content_h)
    place(self.list, list_x, 0, list_w, list_h)

    -- window = content + margins + chrome
    self:SetSize(content_w + (2 * self.margin) + self._chrome_w, content_h + (2 * self.margin) + self._chrome_h)
    UI.Widgets.LuiWindow._layout(self)
    self.content:SetPosition(self.margin, self.margin)
    self.content:SetSize(content_w, content_h)
end
