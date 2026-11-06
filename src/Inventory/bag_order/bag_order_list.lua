-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Bag Order Guide window, right side: the backpack in slot order, 5 slots
-- per row, grouped under the target bags (read-only: the tiles draw the
-- item images themselves, nothing can be used or dragged). It never
-- scrolls: scaled icons are stretched controls, which draw outside scrolled
-- areas, so the list flows into up to 4 columns sized to the screen, with
-- a separator line between columns.

local TR = _G.LUI.Locale.TR
local UI = _G.LUI.UI
local Inventory = _G.LUI.Features.Inventory
import "Turbine.UI"
import "LUI.src.UI.Widgets"
import "LUI.src.Inventory.bag_order.bag_order_model"
import "LUI.src.Inventory.bag_order.bag_order_common"
import "LUI.src.Inventory.bag_order.bag_order_window"

local Style = UI.Widgets.Style
local Icons = UI.Widgets.Icons
local Model = Inventory.BagOrderModel
local Common = Inventory.BagOrderCommon
local BagOrderWindow = Inventory.BagOrderWindow
local ROW_SIZE = Model.ROW_SIZE
local label = Common.label
local block = Common.block
local place = Common.place

local DONE_OPACITY = 0.4
local MAX_COLUMNS = 4
local SCREEN_HEIGHT_SHARE = 0.8

function BagOrderWindow:_build_list()
    self.list = Turbine.UI.Control()
    self.list:SetParent(self.content)
    self.list:SetMouseVisible(true)

    self.tiles = {}
    self.row_views = {}
    for row = 1, self.row_count do
        self.row_views[row] = self:_build_row(row)
    end
    self.row_bag = {}
    self.header_views = {}
    self.separators = {}
    self._header_count = 0
end

function BagOrderWindow:_build_row(row)
    local view = {}
    view.band = block(self.list, Style.TRANSPARENT_BACKGROUND)
    view.band:SetSize(self.column_w, self.row_h)
    view.band:SetVisible(false)

    local first = Model.first_slot(row)
    view.range = label(view.band, self.small_font, Style.SUBTLE_FOREGROUND, Turbine.UI.ContentAlignment.MiddleRight, false)
    view.range:SetText(string.format("%d-%d", first, Model.last_slot(row, self.slot_count)))
    view.range:SetPosition(0, 0)
    view.range:SetSize(self.range_w, self.row_h)

    view.tiles = {}
    for i = 1, ROW_SIZE do
        local slot = first + i - 1
        if slot <= self.slot_count then
            local tile = self:_build_tile(view.band, slot)
            tile.frame:SetPosition(self.range_w + self.gap + ((i - 1) * (self.tile_size + self.tile_gap)), self.row_pad)
            view.tiles[i] = tile
            self.tiles[slot] = tile
        end
    end

    view.check = UI.Widgets.Image()
    view.check:SetParent(view.band)
    view.check:set_icon(Icons.sized("check"), self.check_size)
    view.check:set_tint(Style.ICON_ACCENT)
    view.check:SetPosition(self.column_w - self.check_size, math.floor((self.row_h - self.check_size) / 2))
    view.check:SetVisible(false)
    return view
end

function BagOrderWindow:_build_tile(parent, slot)
    local tile = {}
    tile.key = nil
    tile.frame = block(parent, Style.CONTROL_BORDER)
    tile.frame:SetMouseVisible(true)
    tile.frame:SetSize(self.tile_size, self.tile_size)
    tile.inner = block(tile.frame, Style.BACKGROUND)
    tile.inner:SetPosition(1, 1)
    tile.inner:SetSize(self.icon_size, self.icon_size)
    tile.back = UI.Widgets.Image()
    tile.back:SetParent(tile.frame)
    tile.back:SetPosition(1, 1)
    tile.icon = UI.Widgets.Image()
    tile.icon:SetParent(tile.frame)
    tile.icon:SetPosition(1, 1)
    tile.qty = label(tile.frame, self.small_font, Style.FOREGROUND, Turbine.UI.ContentAlignment.BottomRight, false)
    tile.qty:SetOutlineColor(Style.TEXT_OUTLINE)
    tile.qty:SetFontStyle(Turbine.UI.FontStyle.Outline)
    tile.qty:SetZOrder(3)
    tile.qty:SetPosition(1, 1)
    tile.qty:SetSize(self.icon_size - 1, self.icon_size - 1)
    tile.frame.MouseClick = function(_, args)
        if args.Button == Turbine.UI.MouseButton.Left and self.phase == Common.PHASE_MARKER then
            self:_pick_slot(slot)
        end
    end
    self.tooltip:Bind(tile.frame, function()
        return self:_slot_tooltip(slot)
    end)
    return tile
end

function BagOrderWindow:_header_view(index)
    local view = self.header_views[index]
    if view == nil then
        view = {}
        view.band = block(self.list, Style.TRANSPARENT_BACKGROUND)
        view.label = label(view.band, self.font, Style.FOREGROUND, Turbine.UI.ContentAlignment.MiddleLeft, false)
        self.header_views[index] = view
    end
    return view
end

function BagOrderWindow:_separator(index)
    local line = self.separators[index]
    if line == nil then
        line = block(self.list, Style.SEPARATOR)
        self.separators[index] = line
    end
    return line
end

-- item images of the slots whose content changed
function BagOrderWindow:_refresh_tiles()
    for slot = 1, self.slot_count do
        local tile = self.tiles[slot]
        local entry = self.entries[slot]
        if tile.key ~= entry.exact_key then
            tile.key = entry.exact_key
            tile.back:SetVisible(false)
            tile.icon:SetVisible(false)
            tile.qty:SetText("")
            if entry.empty ~= true then
                if entry.background_id ~= 0 then
                    tile.back:set_icon(entry.background_id, self.icon_size, self.icon_size)
                end
                if entry.icon_id ~= 0 then
                    tile.icon:set_icon(entry.icon_id, self.icon_size, self.icon_size)
                end
                if entry.quantity > 1 then
                    tile.qty:SetText(tostring(entry.quantity))
                end
            end
        end
    end
end

function BagOrderWindow:_slot_tooltip(slot)
    local entry = self.entries[slot]
    if entry.empty == true then
        return string.format(TR["Slot %d: empty"], slot)
    end
    if entry.quantity > 1 then
        return string.format(TR["Slot %d: %s (%d)"], slot, entry.name, entry.quantity)
    end
    return string.format(TR["Slot %d: %s"], slot, entry.name)
end

local function _header_text(item)
    if item.cont == true then
        return string.format(TR["Bag %d (continued)"], item.bag)
    end
    if item.empty == true then
        return string.format(TR["Bag %d (empty)"], item.bag)
    end
    return string.format(TR["Bag %d"], item.bag)
end

-- Places the bags in columns that fit the screen; returns the list's size.
function BagOrderWindow:_layout_list()
    local items = Model.list_items(self:_shown_rows(), self.bag_count)
    local _, display_h = Turbine.UI.Display.GetSize()
    local max_h = math.floor(display_h * SCREEN_HEIGHT_SHARE) - self._chrome_h - (2 * self.margin)
    local columns, height = Model.flow_columns(items, self.header_h, self.row_h, max_h, MAX_COLUMNS)

    self.row_bag = {}
    for row = 1, self.row_count do
        self.row_views[row].band:SetVisible(false)
    end
    for i = 1, #self.header_views do
        self.header_views[i].band:SetVisible(false)
    end
    for i = 1, #self.separators do
        self.separators[i]:SetVisible(false)
    end

    local column_step = self.column_w + (2 * self.sep_gap) + 1
    local header_count = 0
    for c = 1, #columns do
        local x = (c - 1) * column_step
        if c > 1 then
            place(self:_separator(c - 1), x - self.sep_gap - 1, 0, 1, height)
        end
        local y = 0
        local column = columns[c]
        for i = 1, #column do
            local item = column[i]
            if item.kind == "header" then
                header_count = header_count + 1
                local view = self:_header_view(header_count)
                view.bag = item.bag
                view.label:SetText(_header_text(item))
                view.label:SetPosition(self.gap, 0)
                view.label:SetSize(self.column_w - self.gap, self.header_h)
                place(view.band, x, y, self.column_w, self.header_h)
                y = y + self.header_h
            else
                self.row_bag[item.row] = item.bag
                local band = self.row_views[item.row].band
                band:SetPosition(x, y)
                band:SetVisible(true)
                y = y + self.row_h
            end
        end
    end
    self._header_count = header_count
    return (#columns * column_step) - (2 * self.sep_gap) - 1, height
end

-- The current row (Add step) or bag (Empty step) is highlighted, finished
-- rows are dimmed with a check, the marker's tile is framed.
function BagOrderWindow:_refresh_highlight()
    local current_row = nil
    local current_bag = nil
    local done_before = 1
    if self.phase == Common.PHASE_STEPS then
        local step = self.steps[self.step_index]
        if step.kind == "add" then
            current_row = step.row
            done_before = step.row
        else
            current_bag = step.bag
            for i = 1, self.step_index - 1 do
                if self.steps[i].kind == "add" then
                    done_before = self.steps[i].row + 1
                end
            end
        end
    elseif self.phase == Common.PHASE_DONE then
        done_before = self.row_count + 1
    end
    local marker_slot = nil
    if self.marker ~= nil then
        marker_slot = self.marker.slot
    end

    for row = 1, self.row_count do
        local view = self.row_views[row]
        if row == current_row or (current_bag ~= nil and self.row_bag[row] == current_bag) then
            view.band:SetBackColor(Style.SELECTION_BACKGROUND)
        else
            view.band:SetBackColor(Style.TRANSPARENT_BACKGROUND)
        end
        local done = row < done_before
        view.check:SetVisible(done)
        local opacity = 1
        if done == true then
            opacity = DONE_OPACITY
        end
        local first = Model.first_slot(row)
        for i = 1, #view.tiles do
            local tile = view.tiles[i]
            tile.back:SetOpacity(opacity)
            tile.icon:SetOpacity(opacity)
            tile.qty:SetOpacity(opacity)
            if first + i - 1 == marker_slot then
                tile.frame:SetBackColor(Style.ACCENT_BACKGROUND)
            else
                tile.frame:SetBackColor(Style.CONTROL_BORDER)
            end
        end
    end
    for i = 1, self._header_count do
        local view = self.header_views[i]
        if current_bag ~= nil and view.bag == current_bag then
            view.band:SetBackColor(Style.SELECTION_BACKGROUND)
        else
            view.band:SetBackColor(Style.TRANSPARENT_BACKGROUND)
        end
    end
end
