import "LUI.src.StatusBar.widget_base"
import "LUI.src.StatusBar.Widgets.time_local"
import "LUI.src.StatusBar.Widgets.inventory_space"
import "LUI.src.StatusBar.Widgets.equipment_wear"
import "LUI.src.StatusBar.Widgets.money"
import "LUI.src.StatusBar.Widgets.wallet"
import "LUI.src.StatusBar.Widgets.item_count"
import "LUI.src.StatusBar.Widgets.shortcut_button"
import "LUI.src.StatusBar.Widgets.dummy"

local widgets_pkg = nil

if StatusBar ~= nil and StatusBar.Widgets ~= nil then
    widgets_pkg = StatusBar.Widgets
elseif LUI ~= nil and LUI.src ~= nil and LUI.src.StatusBar ~= nil then
    widgets_pkg = LUI.src.StatusBar.Widgets
end

if widgets_pkg ~= nil then
    widgets_pkg.TimeLocalWidget = _G.TimeLocalWidget
    widgets_pkg.InventorySpaceWidget = _G.InventorySpaceWidget
    widgets_pkg.EquipmentWearWidget = _G.EquipmentWearWidget
    widgets_pkg.MoneyWidget = _G.MoneyWidget
    widgets_pkg.WalletWidget = _G.WalletWidget
    widgets_pkg.ItemCountWidget = _G.ItemCountWidget
    widgets_pkg.ShortcutButtonWidget = _G.ShortcutButtonWidget
    widgets_pkg.DummyWidget = _G.DummyWidget
end
