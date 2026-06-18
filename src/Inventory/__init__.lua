if Inventory == nil then
    Inventory = {}
end

import "LUI.src.Inventory.filter"
import "LUI.src.Inventory.slot"
import "LUI.src.Inventory.operations"
import "LUI.src.Inventory.inventory_window"

Inventory.InventorySlot = InventorySlot
Inventory.InventoryWindow = InventoryWindow
