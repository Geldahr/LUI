-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- LuiTable: a simplified QTableWidget-style list. A header bar with column
-- captions above rows of widget cells. Two modes: "paged" (default, plain
-- body, the caller owns pagination and swaps row contents; no scroll
-- viewport so scaled icons cannot escape clipping) and "scroll" (ListBox +
-- fixed 10px scrollbar). No sorting, no mouse column resize, single
-- uniform row height. All dimensions are final (already scaled) pixels.
--
-- Columns: fixed pixel widths, or nil for the single stretch column that
-- absorbs the remaining width (first nil wins; with none, the last column
-- stretches). Cells are widgets; strings become internal labels.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local Style = Widgets.Style
local State = _G.LUI.Settings.State

local SCROLL_SIZE = 10
local SCROLL_GAP = 2
local CELL_PAD_X = 4

-- border widths may come from the style as fractions (BORDER_WIDTH is
-- 1.5 by default); the table does pixel math, so round - and a positive
-- border must never round to zero
local function _border_px(width)
    if width <= 0 then
        return 0
    end
    return math.max(1, math.floor(width + 0.5))
end

-- the frame (and its header underline) follows the shared widget border
-- exactly like LuiWindow: scaled BORDER_WIDTH, never below 1px
local function _frame_border_px()
    local width = tonumber(Style.BORDER_WIDTH) or 1
    return math.max(1, math.floor((width * State.settings.global.scale) + 0.5))
end

local LuiTable = class(Turbine.UI.Control)
Widgets.LuiTable = LuiTable

function LuiTable:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._mode = "paged"
    self._columns = {}
    self._rows = {}
    self._row_h = 24
    self._header_h = 20
    -- chrome defaults come from the shared style; per-instance setters
    -- below remain as programmatic overrides
    self._border_override = nil
    self._border_color = Style.CONTROL_BORDER
    self._v_border_w = _border_px(Style.TABLE_VERTICAL_BORDER_WIDTH)
    self._h_border_w = _border_px(Style.TABLE_HORIZONTAL_BORDER_WIDTH)
    self._inner_border_color = Style.SEPARATOR
    self._auto_height = false
    self._visible_rows = nil
    self._max_h = 0
    self._row_color_a = Style.PANEL_BACKGROUND
    self._row_color_b = Style.TABLE_ALTERNATE_ROWS == true and Style.ALTERNATE_BACKGROUND or nil
    self._font = nil
    self._header_font = nil
    self._selected_index = nil
    self.on_row_clicked = nil
    self.on_row_double_clicked = nil

    self:SetMouseVisible(true)
    self:SetBackColor(self._border_color)

    self.header = Turbine.UI.Control()
    self.header:SetParent(self)
    self.header:SetMouseVisible(false)
    self.header:SetBackColor(Style.CONTROL_BACKGROUND)

    self.body = Turbine.UI.Control()
    self.body:SetParent(self)
    self.body:SetMouseVisible(true)
    self.body:SetBackColor(self._row_color_a)

    self._header_labels = {}
    self._header_seps = {}
    self._list = nil
    self._scroll = nil
end

-- external sizing entry: the assigned height is the auto-height ceiling
-- (the table may shrink below it, never grow past it). Deliberately an
-- override instead of a SizeChanged handler: Turbine does not reliably
-- fire SizeChanged for programmatic SetSize, and relying on it made the
-- ceiling collapse to the shrunken height (capacity ratcheting to zero).
function LuiTable:SetSize(w, h)
    self._max_h = h
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout()
    self:_sync_auto_height()
end

function LuiTable:destroy()
    self:clear()
    self.on_row_clicked = nil
    self.on_row_double_clicked = nil
end

-- ---------------------------------------------------------------- modes ----

-- "paged" (default): plain body, caller swaps row contents per page.
-- "scroll": ListBox + fixed 10px scrollbar. Only allowed while empty.
function LuiTable:set_mode(mode)
    if mode ~= "paged" and mode ~= "scroll" then
        error("LuiTable: unknown mode " .. tostring(mode))
    end
    if #self._rows > 0 then
        error("LuiTable: set_mode requires an empty table (call clear() first)")
    end

    self._mode = mode
    if mode == "scroll" and self._list == nil then
        self._list = Turbine.UI.ListBox()
        self._list:SetParent(self.body)
        self._list:SetOrientation(Turbine.UI.Orientation.Vertical)
        self._scroll = Turbine.UI.Lotro.ScrollBar()
        self._scroll:SetParent(self.body)
        self._scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
        self._scroll:SetWidth(SCROLL_SIZE)
        self._list:SetVerticalScrollBar(self._scroll)
    end
    if self._list ~= nil then
        self._list:SetVisible(mode == "scroll")
        self._scroll:SetVisible(mode == "scroll")
    end
    self:_layout()
end

function LuiTable:_frame_border()
    return self._border_override or _frame_border_px()
end

-- the body height the auto-height ceiling allows (independent of any
-- current shrunken size)
function LuiTable:_body_max_height()
    local bw = self:_frame_border()
    local ceiling = self._max_h > 0 and self._max_h or self:GetHeight()
    return math.max(0, ceiling - (3 * bw) - self._header_h)
end

-- paged mode: how many rows fit the available body height
function LuiTable:visible_capacity()
    if self._mode ~= "paged" then
        error("LuiTable: visible_capacity is a paged-mode query")
    end
    if self._row_h <= 0 then
        return 0
    end
    return math.max(0, math.floor(self:_body_max_height() / self._row_h))
end

-- paged mode: shrink the table so the external border closes right under
-- the last shown row instead of leaving blank body space
function LuiTable:set_auto_height(enabled)
    self._auto_height = enabled == true
    self:_layout()
    self:_sync_auto_height()
end

-- how many leading rows actually hold content this page; nil = all.
-- Auto height sizes down to this count.
function LuiTable:set_visible_rows(count)
    self._visible_rows = count
    self:_layout()
    self:_sync_auto_height()
end

function LuiTable:scroll_to(index)
    if self._mode ~= "scroll" then
        error("LuiTable: scroll_to is a scroll-mode action (paging is the caller's)")
    end
    self._list:EnsureVisible(index)
end

-- -------------------------------------------------------------- columns ----

function LuiTable:set_columns(columns)
    for i = 1, #self._rows do
        if #self._rows[i].cells ~= #columns then
            error("LuiTable: set_columns with mismatched existing rows")
        end
    end

    self._columns = {}
    for i = 1, #self._header_labels do
        self._header_labels[i]:SetParent(nil)
    end
    self._header_labels = {}
    for i = 1, #self._header_seps do
        self._header_seps[i]:SetParent(nil)
    end
    self._header_seps = {}

    -- the vertical grid lines run through the header too
    for i = 1, #columns - 1 do
        local sep = Turbine.UI.Control()
        sep:SetParent(self.header)
        sep:SetMouseVisible(false)
        sep:SetBackColor(self._inner_border_color)
        sep:SetVisible(self._v_border_w > 0)
        self._header_seps[i] = sep
    end

    for i = 1, #columns do
        self._columns[i] = { title = columns[i].title or "", width = columns[i].width }
        local caption = Widgets.LuiLabel()
        caption:SetParent(self.header)
        caption:SetMouseVisible(false)
        caption:SetSelectable(false)
        caption:SetMultiline(false)
        caption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        caption:SetText(self._columns[i].title)
        if self._header_font ~= nil then
            caption:SetFont(self._header_font)
        end
        caption:SetForeColor(Style.FOREGROUND)
        self._header_labels[i] = caption
    end
    self:_layout()
end

function LuiTable:set_column_width(col, width)
    self._columns[col].width = width
    self:_layout()
end

function LuiTable:column_count()
    return #self._columns
end

function LuiTable:set_header_height(h)
    self._header_h = h
    self:_layout()
    self:_sync_auto_height()
end

-- font for internally created (string) cells
function LuiTable:set_font(font)
    self._font = font
    for i = 1, #self._rows do
        local row = self._rows[i]
        for c = 1, #row.cells do
            if row.owned[c] == true then
                row.cells[c]:SetFont(font)
            end
        end
    end
end

function LuiTable:set_header_font(font)
    self._header_font = font
    for i = 1, #self._header_labels do
        self._header_labels[i]:SetFont(font)
    end
end

-- ----------------------------------------------------------- appearance ----

-- external frame; also closes under the header row so the title bar reads
-- as distinct from the items (the underline uses the same width)
function LuiTable:set_border(width, color)
    self._border_override = _border_px(width)
    self._border_color = color
    self:SetBackColor(color)
    self:_layout()
    self:_sync_auto_height()
end

-- grid lines: vertical between columns (also through the header),
-- horizontal between rows; 0 disables a direction
function LuiTable:set_inner_border(vertical_w, horizontal_w, color)
    self._v_border_w = _border_px(vertical_w)
    self._h_border_w = _border_px(horizontal_w)
    self._inner_border_color = color
    for i = 1, #self._rows do
        self:_style_row_separators(self._rows[i])
    end
    for i = 1, #self._header_seps do
        self._header_seps[i]:SetBackColor(color)
        self._header_seps[i]:SetVisible(vertical_w > 0)
    end
    self:_layout()
end

-- one color = uniform rows; two colors = alternating
function LuiTable:set_row_colors(color_a, color_b)
    self._row_color_a = color_a
    self._row_color_b = color_b
    self.body:SetBackColor(color_a)
    for i = 1, #self._rows do
        self:_apply_row_background(self._rows[i])
    end
end

function LuiTable:set_header_color(color)
    self.header:SetBackColor(color)
end

-- ----------------------------------------------------------------- rows ----

function LuiTable:_create_row()
    local table_widget = self
    local row = { cells = {}, owned = {}, seps = {}, data = nil, index = 0 }
    row.control = Turbine.UI.Control()
    row.control:SetMouseVisible(true)
    row.control.MouseClick = function(_, args)
        if type(table_widget.on_row_clicked) == "function" then
            table_widget.on_row_clicked(row.index, args)
        end
    end
    row.control.MouseDoubleClick = function(_, args)
        if type(table_widget.on_row_double_clicked) == "function" then
            table_widget.on_row_double_clicked(row.index, args)
        end
    end

    -- one vertical separator per inner column boundary + a bottom line;
    -- created once, repositioned on layout, shown only with inner borders
    for c = 1, #self._columns - 1 do
        local sep = Turbine.UI.Control()
        sep:SetParent(row.control)
        sep:SetMouseVisible(false)
        row.seps[c] = sep
    end
    row.bottom_sep = Turbine.UI.Control()
    row.bottom_sep:SetParent(row.control)
    row.bottom_sep:SetMouseVisible(false)
    self:_style_row_separators(row)
    return row
end

function LuiTable:_style_row_separators(row)
    for c = 1, #row.seps do
        row.seps[c]:SetBackColor(self._inner_border_color)
        row.seps[c]:SetVisible(self._v_border_w > 0)
    end
    row.bottom_sep:SetBackColor(self._inner_border_color)
    row.bottom_sep:SetVisible(self._h_border_w > 0)
end

function LuiTable:_apply_row_background(row)
    if row.index == self._selected_index then
        row.control:SetBackColor(Style.SELECTION_BACKGROUND)
    elseif self._row_color_b ~= nil and row.index % 2 == 0 then
        row.control:SetBackColor(self._row_color_b)
    else
        row.control:SetBackColor(self._row_color_a)
    end
end

function LuiTable:_assign_cell(row, col, value)
    local old = row.cells[col]
    if old ~= nil then
        old:SetParent(nil)
    end

    local widget = value
    local owned = false
    if type(value) == "string" then
        widget = Widgets.LuiLabel()
        widget:SetMouseVisible(false)
        widget:SetSelectable(false)
        widget:SetMultiline(false)
        widget:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        widget:SetText(value)
        if self._font ~= nil then
            widget:SetFont(self._font)
        end
        widget:SetForeColor(Style.FOREGROUND)
        owned = true
    end
    widget:SetParent(row.control)
    row.cells[col] = widget
    row.owned[col] = owned
end

function LuiTable:_reindex(from)
    for i = from, #self._rows do
        self._rows[i].index = i
        self:_apply_row_background(self._rows[i])
    end
end

function LuiTable:append_row(cells)
    return self:insert_row(#self._rows + 1, cells)
end

function LuiTable:insert_row(index, cells)
    if #cells ~= #self._columns then
        error("LuiTable: row has " .. #cells .. " cells for " .. #self._columns .. " columns")
    end

    local row = self:_create_row()
    for c = 1, #cells do
        self:_assign_cell(row, c, cells[c])
    end
    table.insert(self._rows, index, row)
    if self._mode == "scroll" then
        -- ListBox owns stacking; mid-list inserts rebuild the item list
        if index == #self._rows then
            self._list:AddItem(row.control)
        else
            self:_rebuild_list_items()
        end
    else
        row.control:SetParent(self.body)
    end
    self:_reindex(index)
    self:_layout()
    -- auto height must grow with the row count
    self:_sync_auto_height()
    return index
end

function LuiTable:set_row(index, cells)
    local row = self._rows[index]
    if #cells ~= #self._columns then
        error("LuiTable: row has " .. #cells .. " cells for " .. #self._columns .. " columns")
    end
    for c = 1, #cells do
        self:_assign_cell(row, c, cells[c])
    end
    self:_layout_row(row)
end

function LuiTable:get_row(index)
    local row = self._rows[index]
    local cells = {}
    for c = 1, #row.cells do
        cells[c] = row.cells[c]
    end
    return cells
end

function LuiTable:set_cell(row_index, col, value)
    local row = self._rows[row_index]
    self:_assign_cell(row, col, value)
    self:_layout_row(row)
end

function LuiTable:get_cell(row_index, col)
    return self._rows[row_index].cells[col]
end

function LuiTable:remove_row(index)
    local row = table.remove(self._rows, index)
    for c = 1, #row.cells do
        row.cells[c]:SetParent(nil)
    end
    row.control:SetParent(nil)
    if self._mode == "scroll" then
        self:_rebuild_list_items()
    end
    if self._selected_index == index then
        self._selected_index = nil
    elseif self._selected_index ~= nil and self._selected_index > index then
        self._selected_index = self._selected_index - 1
    end
    self:_reindex(index)
    self:_layout()
    self:_sync_auto_height()
end

function LuiTable:clear()
    for i = 1, #self._rows do
        local row = self._rows[i]
        for c = 1, #row.cells do
            row.cells[c]:SetParent(nil)
        end
        row.control:SetParent(nil)
    end
    self._rows = {}
    self._selected_index = nil
    if self._list ~= nil then
        self._list:ClearItems()
    end
    self:_layout()
    self:_sync_auto_height()
end

function LuiTable:row_count()
    return #self._rows
end

function LuiTable:set_row_height(h)
    self._row_h = h
    self:_layout()
    self:_sync_auto_height()
end

function LuiTable:set_row_data(index, value)
    self._rows[index].data = value
end

function LuiTable:row_data(index)
    return self._rows[index].data
end

-- ------------------------------------------------------------ selection ----

function LuiTable:set_selected_index(index)
    local previous = self._selected_index
    self._selected_index = index
    if previous ~= nil and self._rows[previous] ~= nil then
        self:_apply_row_background(self._rows[previous])
    end
    if index ~= nil then
        self:_apply_row_background(self._rows[index])
    end
end

function LuiTable:selected_index()
    return self._selected_index
end

-- --------------------------------------------------------------- layout ----

function LuiTable:_rebuild_list_items()
    self._list:ClearItems()
    for i = 1, #self._rows do
        self._list:AddItem(self._rows[i].control)
    end
end

-- per-column x/width over the row content width; one stretch column
function LuiTable:_resolve_widths(content_w)
    local ib = self._v_border_w
    local fixed = 0
    local stretch = nil
    for i = 1, #self._columns do
        if self._columns[i].width == nil then
            if stretch == nil then
                stretch = i
            else
                fixed = fixed + 1
            end
        else
            fixed = fixed + self._columns[i].width
        end
    end
    if stretch == nil and #self._columns > 0 then
        stretch = #self._columns
        fixed = fixed - (self._columns[stretch].width or 0)
    end

    local borders = math.max(0, #self._columns - 1) * ib
    local stretch_w = math.max(1, content_w - fixed - borders)
    local resolved = {}
    local x = 0
    for i = 1, #self._columns do
        local w = i == stretch and stretch_w or math.max(1, self._columns[i].width or 1)
        resolved[i] = { x = x, w = w }
        x = x + w + ib
    end
    return resolved
end

function LuiTable:_row_content_width()
    local bw = self:_frame_border()
    local inner_w = math.max(1, self:GetWidth() - (2 * bw))
    if self._mode == "scroll" then
        return math.max(1, inner_w - SCROLL_SIZE - SCROLL_GAP)
    end
    return inner_w
end

function LuiTable:_layout_row(row)
    local resolved = self._resolved
    if resolved == nil then
        return
    end
    row.control:SetSize(self:_row_content_width(), self._row_h)
    for c = 1, #row.cells do
        local col = resolved[c]
        row.cells[c]:SetPosition(col.x + CELL_PAD_X, 0)
        row.cells[c]:SetSize(math.max(1, col.w - (2 * CELL_PAD_X)), self._row_h)
    end
    for c = 1, #row.seps do
        row.seps[c]:SetPosition(resolved[c].x + resolved[c].w, 0)
        row.seps[c]:SetSize(self._v_border_w, self._row_h)
    end
    row.bottom_sep:SetPosition(0, self._row_h - self._h_border_w)
    row.bottom_sep:SetSize(row.control:GetWidth(), self._h_border_w)
end

-- rows shown right now: capacity-capped and, when the caller told us how
-- many leading rows hold content, content-capped too
function LuiTable:_shown_rows()
    local shown = #self._rows
    if self._mode == "paged" then
        shown = math.min(shown, self:visible_capacity())
    end
    if self._visible_rows ~= nil then
        shown = math.min(shown, self._visible_rows)
    end
    return shown
end

function LuiTable:_layout_rows()
    if self._resolved == nil then
        return
    end
    local shown = self:_shown_rows()
    for i = 1, #self._rows do
        local row = self._rows[i]
        self:_layout_row(row)
        if self._mode == "paged" then
            -- rows pack edge to edge; the horizontal line overlays the
            -- row's bottom pixel band
            row.control:SetPosition(0, (i - 1) * self._row_h)
            row.control:SetVisible(i <= shown)
        end
        -- the last shown row has no line: the external border closes it
        row.bottom_sep:SetVisible(self._h_border_w > 0
            and (self._mode ~= "paged" or i < shown))
    end
end

function LuiTable:_layout()
    local bw = self:_frame_border()
    local w, h = self:GetSize()
    local inner_w = math.max(1, w - (2 * bw))

    self.header:SetPosition(bw, bw)
    self.header:SetSize(inner_w, self._header_h)

    -- the header underline separates the title bar from the body
    local body_y = bw + self._header_h + bw
    self.body:SetPosition(bw, body_y)
    self.body:SetSize(inner_w, math.max(1, h - body_y - bw))

    if self._mode == "scroll" and self._list ~= nil then
        local list_w = math.max(1, inner_w - SCROLL_SIZE - SCROLL_GAP)
        local body_h = self.body:GetHeight()
        self._list:SetPosition(0, 0)
        self._list:SetSize(list_w, body_h)
        self._scroll:SetPosition(list_w + SCROLL_GAP, 0)
        self._scroll:SetSize(SCROLL_SIZE, body_h)
    end

    self._resolved = self:_resolve_widths(self:_row_content_width())
    for i = 1, #self._columns do
        local col = self._resolved[i]
        self._header_labels[i]:SetPosition(col.x + CELL_PAD_X, 0)
        self._header_labels[i]:SetSize(math.max(1, col.w - (2 * CELL_PAD_X)), self._header_h)
    end
    for i = 1, #self._header_seps do
        self._header_seps[i]:SetPosition(self._resolved[i].x + self._resolved[i].w, 0)
        self._header_seps[i]:SetSize(self._v_border_w, self._header_h)
    end

    self:_layout_rows()
end

-- auto height: close the external border right under the last shown row
-- (paged mode; scroll mode needs its fixed viewport). Resizes through the
-- base-class SetSize so the ceiling recorded by our override stays intact.
function LuiTable:_sync_auto_height()
    if self._auto_height ~= true or self._mode ~= "paged" then
        return
    end
    local target_h = (3 * self:_frame_border())
        + self._header_h + (self:_shown_rows() * self._row_h)
    if target_h ~= self:GetHeight() then
        Turbine.UI.Control.SetSize(self, self:GetWidth(), target_h)
        self:_layout()
    end
end
