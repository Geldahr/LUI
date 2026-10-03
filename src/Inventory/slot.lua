-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local Inventory = _G.LUI.Features.Inventory
local class = _G.LUI.Core.class
import "Turbine.UI"
import "Turbine.UI.Lotro"

local InventorySlot = class(Turbine.UI.Control)
Inventory.InventorySlot = InventorySlot

local GRID_COLOR = Turbine.UI.Color(1, 0.40, 0.40, 0.40)
local TILE_BACK = Turbine.UI.Color(1, 0, 0, 0)
local BORDER_THICKNESS = 2
local EDGE_PROPORTIONAL = Turbine.UI.EdgeAttachmentType.Proportional
local ITEM_ICON_SIZE = 32
local ITEM_MARGIN_RATIO = 0.06

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function InventorySlot:Constructor(index, on_drop)
    Turbine.UI.Control.Constructor(self)

    self.index = index
    self.on_drop = on_drop

    self.tile_size = 40
    self._first_row = false
    self._first_col = false

    -- Must be mouse-visible so ItemControl can handle drag/drop.
    self:SetMouseVisible(true)
    -- if self.SetAllowDrop ~= nil then
    --     self:SetAllowDrop(true)
    -- end

    self.item = nil
    self.matched = true

    self.edge_top = Turbine.UI.Control()
    self.edge_top:SetParent(self)
    self.edge_top:SetMouseVisible(false)
    self.edge_top:SetBackColor(GRID_COLOR)
    self.edge_top:SetZOrder(10)
    self.edge_top:SetVisible(false)

    self.edge_left = Turbine.UI.Control()
    self.edge_left:SetParent(self)
    self.edge_left:SetMouseVisible(false)
    self.edge_left:SetBackColor(GRID_COLOR)
    self.edge_left:SetZOrder(10)
    self.edge_left:SetVisible(false)

    self.edge_right = Turbine.UI.Control()
    self.edge_right:SetParent(self)
    self.edge_right:SetMouseVisible(false)
    self.edge_right:SetBackColor(GRID_COLOR)
    self.edge_right:SetZOrder(10)
    self.edge_right:SetVisible(true)

    self.edge_bottom = Turbine.UI.Control()
    self.edge_bottom:SetParent(self)
    self.edge_bottom:SetMouseVisible(false)
    self.edge_bottom:SetBackColor(GRID_COLOR)
    self.edge_bottom:SetZOrder(10)
    self.edge_bottom:SetVisible(true)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(TILE_BACK)
    self.inner:SetZOrder(1)

    -- Since U49.6 a stretched control ignores SetSize and only rescales when
    -- its parent resizes: the item control fills a holder at its natural
    -- size, and the holder is what gets sized to the slot.
    self.item_control = Turbine.UI.Lotro.ItemControl()
    self.item_holder = Turbine.UI.Control()
    self.item_holder:SetParent(self)
    self.item_holder:SetPosition(0, 0)
    self._item_natural = self.item_control:GetWidth()
    self.item_holder:SetSize(self._item_natural, self._item_natural)
    self.item_holder:SetMouseVisible(false)
    self.item_holder:SetZOrder(2)

    self.item_control:SetParent(self.item_holder)
    self.item_control:SetPosition(0, 0)
    self.item_control:SetMouseVisible(true)
    self.item_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.item_control:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.item_control:SetStretchMode(1)
    self.item_control:AttachEdges(EDGE_PROPORTIONAL, EDGE_PROPORTIONAL, EDGE_PROPORTIONAL, EDGE_PROPORTIONAL)
    if self.item_control.SetAllowDrop ~= nil then
        self.item_control:SetAllowDrop(true)
    end
    self.item_control.DragDrop = function(_, args)
        if args == nil or args.DragDropInfo == nil then
            return
        end
        if type(self.on_drop) == "function" then
            self.on_drop(self.index, args.DragDropInfo, args)
        end
    end
    self:_layout()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function InventorySlot:set_grid_edges(is_first_row, is_first_col)
    if self.edge_top ~= nil then
        self.edge_top:SetVisible(is_first_row == true)
    end
    if self.edge_left ~= nil then
        self.edge_left:SetVisible(is_first_col == true)
    end
    if self._first_row ~= is_first_row or self._first_col ~= is_first_col then
        self._first_row = is_first_row
        self._first_col = is_first_col
        self:_layout()
    end
end

function InventorySlot:set_tile(tile_size)
    self.tile_size = tile_size
    self:_layout()
end

function InventorySlot:set_matched(matched)
    self.matched = matched == true
end

function InventorySlot:set_quantity(qty)
    -- Quantity is already rendered by the game icon; no custom overlay needed.
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function InventorySlot:_layout()
    local sz = self.tile_size
    self:SetSize(sz, sz)

    if self.edge_top ~= nil then
        self.edge_top:SetPosition(0, 0)
        self.edge_top:SetSize(sz, BORDER_THICKNESS)
    end
    if self.edge_left ~= nil then
        self.edge_left:SetPosition(0, 0)
        self.edge_left:SetSize(BORDER_THICKNESS, sz)
    end
    if self.edge_right ~= nil then
        self.edge_right:SetPosition(sz - BORDER_THICKNESS, 0)
        self.edge_right:SetSize(BORDER_THICKNESS, sz)
    end
    if self.edge_bottom ~= nil then
        self.edge_bottom:SetPosition(0, sz - BORDER_THICKNESS)
        self.edge_bottom:SetSize(sz, BORDER_THICKNESS)
    end

    -- The black area runs from line to line: every slot has a right/bottom
    -- grid line, only the first row/column also have a top/left one.
    local inner_x = self._first_col == true and BORDER_THICKNESS or 0
    local inner_y = self._first_row == true and BORDER_THICKNESS or 0
    local inner_w = math.max(0, sz - BORDER_THICKNESS - inner_x)
    local inner_h = math.max(0, sz - BORDER_THICKNESS - inner_y)
    if self.inner ~= nil then
        self.inner:SetPosition(inner_x, inner_y)
        self.inner:SetSize(inner_w, inner_h)
    end

    if self.item_holder ~= nil then
        -- The item control draws its 32px icon after a 3px top/left pad
        -- (35px natural size), and the client floors both when scaling.
        -- Pick the holder size whose drawn icon leaves `margin` around it in
        -- the smallest black area, then center the drawn icon (not the
        -- holder) in this slot's black area.
        local natural = self._item_natural
        local inner_sz = math.max(0, sz - (2 * BORDER_THICKNESS))
        local margin = math.floor((inner_sz * ITEM_MARGIN_RATIO) + 0.5)
        local target = inner_sz - (2 * margin)
        local holder_side = math.ceil((target + 1) * natural / ITEM_ICON_SIZE)
        while math.floor(holder_side * ITEM_ICON_SIZE / natural) > target do
            holder_side = holder_side - 1
        end
        local pad = math.floor(holder_side * (natural - ITEM_ICON_SIZE) / natural)
        self.item_holder:SetPosition(
            inner_x + ((inner_w - target) / 2) - pad,
            inner_y + ((inner_h - target) / 2) - pad
        )
        self.item_holder:SetSize(holder_side, holder_side)
    end
end
