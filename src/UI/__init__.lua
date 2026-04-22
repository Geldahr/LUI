import "LUI.src.UI.native_scaling"
import "LUI.src.UI.hidable"
import "LUI.src.UI.move_ui"
import "LUI.src.Vitals"
import "LUI.src.UI.Widgets"
import "LUI.src.Settings"
import "LUI.src.Inventory"
import "LUI.src.Crafting"
import "LUI.src.Assets"
import "LUI.src.StatusBar"

-- Re-export into the UI namespace for callers.
local vitals_pkg = Vitals
if vitals_pkg == nil and LUI ~= nil then
    vitals_pkg = LUI.Vitals
end
if vitals_pkg == nil and Geldahr ~= nil and LUI.src ~= nil then
    vitals_pkg = LUI.src.Vitals
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
if inv_pkg == nil and Geldahr ~= nil and LUI.src ~= nil then
    inv_pkg = LUI.src.Inventory
end

if inv_pkg ~= nil then
    InventoryWindow = inv_pkg.InventoryWindow
end
if UI ~= nil then
    UI.InventoryWindow = InventoryWindow
end

local crafting_window_ctor = CraftingWindow
if crafting_window_ctor == nil and type(Crafting) == "table" then
    crafting_window_ctor = Crafting.CraftingWindow
end
if crafting_window_ctor == nil and LUI ~= nil and type(LUI.Crafting) == "table" then
    crafting_window_ctor = LUI.Crafting.CraftingWindow
end
if crafting_window_ctor == nil and Geldahr ~= nil and LUI.src ~= nil and type(LUI.src.Crafting) == "table" then
    crafting_window_ctor = LUI.src.Crafting.CraftingWindow
end

if crafting_window_ctor ~= nil then
    CraftingWindow = crafting_window_ctor
end
if UI ~= nil then
    UI.CraftingWindow = crafting_window_ctor
end

local assets_window_ctor = AssetsWindow
if assets_window_ctor == nil and type(Assets) == "table" then
    assets_window_ctor = Assets.AssetsWindow
end
if assets_window_ctor == nil and LUI ~= nil and type(LUI.Assets) == "table" then
    assets_window_ctor = LUI.Assets.AssetsWindow
end
if assets_window_ctor == nil and Geldahr ~= nil and LUI.src ~= nil and type(LUI.src.Assets) == "table" then
    assets_window_ctor = LUI.src.Assets.AssetsWindow
end

if assets_window_ctor ~= nil then
    AssetsWindow = assets_window_ctor
end
if UI ~= nil then
    UI.AssetsWindow = assets_window_ctor
end

local status_bar_pkg = StatusBar
if status_bar_pkg == nil and LUI ~= nil then
    status_bar_pkg = LUI.StatusBar
end
if status_bar_pkg == nil and Geldahr ~= nil and LUI.src ~= nil then
    status_bar_pkg = LUI.src.StatusBar
end

if status_bar_pkg ~= nil then
    StatusBarWindow = status_bar_pkg.StatusBarWindow
end
if UI ~= nil then
    UI.StatusBarWindow = StatusBarWindow
end
