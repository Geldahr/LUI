import "LUI.src.UI.native_scaling"
import "LUI.src.UI.hidable"
import "LUI.src.UI.move_ui"
import "LUI.src.Vitals"
import "LUI.src.UI.Widgets"
import "LUI.src.Settings"
import "LUI.src.Inventory"
import "LUI.src.Crafting"
import "LUI.src.Assets"
import "LUI.src.Travel"
import "LUI.src.StatusBar"
import "LUI.src.Launcher"

VitalsBase = Vitals.VitalsBase
SelfVitals = Vitals.SelfVitals
TargetVitals = Vitals.TargetVitals
BossVitals = Vitals.BossVitals
FellowshipVitals = Vitals.FellowshipVitals
RaidVitals = Vitals.RaidVitals

UI.VitalsBase = VitalsBase
UI.SelfVitals = SelfVitals
UI.TargetVitals = TargetVitals
UI.BossVitals = BossVitals
UI.FellowshipVitals = FellowshipVitals
UI.RaidVitals = RaidVitals

InventoryWindow = Inventory.InventoryWindow
UI.InventoryWindow = InventoryWindow

CraftingWindow = Crafting.CraftingWindow
UI.CraftingWindow = CraftingWindow

AssetsWindow = Assets.AssetsWindow
UI.AssetsWindow = AssetsWindow

TravelWindow = Travel.TravelWindow
UI.TravelWindow = TravelWindow

StatusBarWindow = StatusBar.StatusBarWindow
UI.StatusBarWindow = StatusBarWindow

LauncherMenu = Launcher.LauncherMenu
UI.LauncherMenu = LauncherMenu
