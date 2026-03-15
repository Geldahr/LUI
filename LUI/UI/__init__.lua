import "Geldahr.LUI.UI.moveable"
import "Geldahr.LUI.UI.hidable"
import "Geldahr.LUI.Vitals"
import "Geldahr.LUI.UI.Widgets"
import "Geldahr.LUI.UI.Settings"
import "Geldahr.LUI.Inventory"
import "Geldahr.LUI.Assets"
import "Geldahr.LUI.StatusBar"

-- Re-export into the UI namespace for callers.
local vitals_pkg = Vitals
if vitals_pkg == nil and LUI ~= nil then
    vitals_pkg = LUI.Vitals
end
if vitals_pkg == nil and Geldahr ~= nil and Geldahr.LUI ~= nil then
    vitals_pkg = Geldahr.LUI.Vitals
end

if vitals_pkg ~= nil then
    if vitals_pkg.VitalsBase ~= nil then VitalsBase = vitals_pkg.VitalsBase end
    if vitals_pkg.SelfVitals ~= nil then SelfVitals = vitals_pkg.SelfVitals end
    if vitals_pkg.TargetVitals ~= nil then TargetVitals = vitals_pkg.TargetVitals end
    if vitals_pkg.BossVitals ~= nil then BossVitals = vitals_pkg.BossVitals end
    if vitals_pkg.PartyVitals ~= nil then PartyVitals = vitals_pkg.PartyVitals end
end

if UI ~= nil then
    UI.VitalsBase = VitalsBase
    UI.SelfVitals = SelfVitals
    UI.TargetVitals = TargetVitals
    UI.BossVitals = BossVitals
    UI.PartyVitals = PartyVitals
end

local inv_pkg = Inventory
if inv_pkg == nil and LUI ~= nil then
    inv_pkg = LUI.Inventory
end
if inv_pkg == nil and Geldahr ~= nil and Geldahr.LUI ~= nil then
    inv_pkg = Geldahr.LUI.Inventory
end

if inv_pkg ~= nil then
    InventoryWindow = inv_pkg.InventoryWindow
end
if UI ~= nil then
    UI.InventoryWindow = InventoryWindow
end

local assets_pkg = Assets
if assets_pkg == nil and LUI ~= nil then
    assets_pkg = LUI.Assets
end
if assets_pkg == nil and Geldahr ~= nil and Geldahr.LUI ~= nil then
    assets_pkg = Geldahr.LUI.Assets
end

if assets_pkg ~= nil then
    AssetsWindow = assets_pkg.AssetsWindow
end
if UI ~= nil then
    UI.AssetsWindow = AssetsWindow
end

local status_bar_pkg = StatusBar
if status_bar_pkg == nil and LUI ~= nil then
    status_bar_pkg = LUI.StatusBar
end
if status_bar_pkg == nil and Geldahr ~= nil and Geldahr.LUI ~= nil then
    status_bar_pkg = Geldahr.LUI.StatusBar
end

if status_bar_pkg ~= nil then
    StatusBarWindow = status_bar_pkg.StatusBarWindow
end
if UI ~= nil then
    UI.StatusBarWindow = StatusBarWindow
end
