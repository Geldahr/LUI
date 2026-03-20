import "Turbine.UI"
import "Turbine.UI.Lotro"

InventorySlot = class(Turbine.UI.Control)

local GRID_COLOR = Turbine.UI.Color(1, 0.40, 0.40, 0.40)
local TILE_BACK = Turbine.UI.Color(1, 0, 0, 0)
local BORDER_THICKNESS = 2

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function InventorySlot:Constructor(index, on_click, on_drop)
    Turbine.UI.Control.Constructor(self)

    self.index = index
    self.on_click = on_click
    self.on_drop = on_drop

    self.tile_size = 40

    -- Must be mouse-visible so ItemControl can handle drag/drop.
    self:SetMouseVisible(true)
    -- if self.SetAllowDrop ~= nil then
    --     self:SetAllowDrop(true)
    -- end

    self.item = nil
    self.matched = true
    self.lock_mode = false

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

    self.item_control = Turbine.UI.Lotro.ItemControl()
    self.item_control:SetParent(self)
    self.item_control:SetPosition(0, 0)
    self.item_control:SetSize(self.tile_size, self.tile_size)
    self.item_control:SetMouseVisible(true)
    self.item_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.item_control:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.item_control:SetZOrder(2)
    if self.item_control.SetStretchMode ~= nil then
        self.item_control:SetStretchMode(1)
    end
    if self.item_control.SetAllowDrop ~= nil then
        self.item_control:SetAllowDrop(true)
    end
    self.item_control.DragDrop = function(_, args)
        if self.lock_mode == true then
            return
        end
        if args == nil or args.DragDropInfo == nil then
            return
        end
        if type(self.on_drop) == "function" then
            self.on_drop(self.index, args.DragDropInfo, args)
        end
    end
    -- self.DragDrop = function(_, args)
    --     if self.lock_mode == true then
    --         return
    --     end
    --     if args == nil or args.DragDropInfo == nil then
    --         return
    --     end
    --     if type(self.on_drop) == "function" then
    --         self.on_drop(self.index, args.DragDropInfo)
    --     end
    -- end

    -- Lock indicator + lock-mode click overlay are intentionally disabled for now.
    -- Keep the old code commented for future re-enable.
    --
    -- self.lock_marker = Turbine.UI.Control()
    -- self.lock_marker:SetParent(self)
    -- self.lock_marker:SetMouseVisible(false)
    -- self.lock_marker:SetBackColor(Turbine.UI.Color(0.90, 0.90, 0.15, 0.15))
    -- self.lock_marker:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    -- self.lock_marker:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    -- self.lock_marker:SetVisible(false)
    -- self.lock_marker:SetZOrder(15)
    -- self.lock_marker:SetPosition(BORDER_THICKNESS, BORDER_THICKNESS)
    -- self.lock_marker:SetSize(8, 8)
    --
    -- self.click_overlay = Turbine.UI.Control()
    -- self.click_overlay:SetParent(self)
    -- self.click_overlay:SetMouseVisible(false)
    -- self.click_overlay:SetVisible(true)
    -- self.click_overlay:SetZOrder(20)
    -- self.click_overlay:SetPosition(0, 0)
    -- self.click_overlay:SetSize(self.tile_size, self.tile_size)
    -- self.click_overlay.MouseClick = function(_, args)
    --     if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
    --         return
    --     end
    --     if type(self.on_click) == "function" then
    --         self.on_click(self.index)
    --     end
    -- end
    --
    -- self:set_lock_mode(false)
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
end

function InventorySlot:set_tile(tile_size)
    self.tile_size = tile_size
    self:_layout()
end

function InventorySlot:set_lock_mode(enabled)
    -- Lock mode is intentionally disabled for now.
    -- self.lock_mode = enabled == true
    -- if self.click_overlay ~= nil then
    --     self.click_overlay:SetMouseVisible(self.lock_mode == true)
    -- end
    -- if self.item_control ~= nil then
    --     self.item_control:SetMouseVisible(self.lock_mode ~= true)
    -- end
    self.lock_mode = false
    if self.item_control ~= nil then
        self.item_control:SetMouseVisible(true)
    end
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

    local inner_inset = BORDER_THICKNESS
    local inner_sz = sz - (2 * inner_inset)
    if inner_sz < 0 then inner_sz = 0 end
    if self.inner ~= nil then
        self.inner:SetPosition(inner_inset, inner_inset)
        self.inner:SetSize(inner_sz, inner_sz)
    end

    if self.item_control ~= nil then
        self.item_control:SetPosition(0, 0)
        self.item_control:SetSize(sz + 1, sz + 1)
    end
    -- if self.click_overlay ~= nil then
    --     self.click_overlay:SetSize(sz, sz)
    -- end
end
