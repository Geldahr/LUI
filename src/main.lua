import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Utils"
import "LUI.src.Utils.coords"
import "LUI.src.Settings"
import "LUI.src.Settings.default_layouts"

import "LUI.src.UI"
import "LUI.src.ExpiringEffects"
import "LUI.src.Cooldowns"
import "LUI.src.Assets"
import "LUI.src.Bestiary"

local function set_backpacks_enabled(enabled)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack1, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack2, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack3, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack4, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack5, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack6, enabled == true)
end

function apply_inventory_settings()
    local enabled = _G.settings.inventory.enabled == true
    local replace = enabled and _G.settings.inventory.replace == true

    if enabled then
        if INVENTORY_WINDOW == nil then
            INVENTORY_WINDOW = UI.InventoryWindow()
        elseif INVENTORY_WINDOW ~= nil and INVENTORY_WINDOW.apply_settings ~= nil then
            INVENTORY_WINDOW:apply_settings()
        end
    else
        if INVENTORY_WINDOW ~= nil then
            INVENTORY_WINDOW:SetVisible(false)
        end
        INVENTORY_WINDOW = nil
    end

    if replace then
        set_backpacks_enabled(false)
    else
        set_backpacks_enabled(true)
    end
end

function apply_assets_settings()
    local enabled = _G.settings.assets.enabled == true

    if enabled then
        if ASSETS_STORE == nil then
            ASSETS_STORE = Assets.AssetsStore()
        elseif ASSETS_STORE.refresh_bindings ~= nil then
            ASSETS_STORE:refresh_bindings()
        end

        if ASSETS_WINDOW == nil then
            ASSETS_WINDOW = UI.AssetsWindow()
        elseif ASSETS_WINDOW.apply_settings ~= nil then
            ASSETS_WINDOW:apply_settings()
        end
    else
        if ASSETS_WINDOW ~= nil then
            if ASSETS_WINDOW.SetVisible ~= nil then
                ASSETS_WINDOW:SetVisible(false)
            end
        end
        ASSETS_WINDOW = nil

        if ASSETS_STORE ~= nil and ASSETS_STORE.destroy ~= nil then
            ASSETS_STORE:destroy()
        end
        ASSETS_STORE = nil
    end
end

function apply_status_bar_settings()
    local sb = _G.settings.status_bar
    if STATUS_BAR ~= nil then
        if STATUS_BAR.destroy ~= nil then
            STATUS_BAR:destroy()
        else
            STATUS_BAR:SetVisible(false)
        end
        STATUS_BAR = nil
    end

    if sb.enabled == true then
        STATUS_BAR = UI.StatusBarWindow()
    end
end

function apply_cooldowns_settings()
    local cd = _G.settings.self.cooldowns
    if cd.enabled == true then
        if COOLDOWNS_WINDOW == nil then
            COOLDOWNS_WINDOW = Cooldowns.CooldownsWindow()
        end
    else
        if COOLDOWNS_WINDOW ~= nil then
            if COOLDOWNS_WINDOW.destroy ~= nil then
                COOLDOWNS_WINDOW:destroy()
            else
                COOLDOWNS_WINDOW:SetVisible(false)
            end
        end
        COOLDOWNS_WINDOW = nil
    end
end

load_settings()
if _G.loaded_settings_was_new == true then
    _G.loaded_settings = _G.DefaultLayouts.build("bottom", _G.DefaultLayouts.get_resolution_scale())
    _G.ensure_loaded_settings()
    _G.fix_colors()
    _G.rebuild_settings()
end

BESTIARY_CARD = Bestiary.BestiaryCard()
_G.BESTIARY_CARD = BESTIARY_CARD

-- Initializing TARGET_VITAL first: self vitals will drive its visibility based on current target.
TARGET_VITAL = UI.TargetVitals(nil)
BOSS_VITAL = UI.BossVitals(nil)
PLAYER_VITAL = UI.SelfVitals(Turbine.Gameplay.LocalPlayer.GetInstance())
PLAYER_VITAL:set_target_vitals(TARGET_VITAL, BOSS_VITAL)
PARTY_VITALS = UI.PartyVitals()
EXPIRING_SELF_EFFECTS_WINDOW = ExpiringEffects.SelfExpiringEffectsWindow()
EXPIRING_TARGET_EFFECTS_WINDOW = ExpiringEffects.TargetExpiringEffectsWindow()
INVENTORY_WINDOW = nil
ASSETS_STORE = nil
ASSETS_WINDOW = nil
STATUS_BAR = nil
COOLDOWNS_WINDOW = nil
BESTIARY_WINDOW = nil
BESTIARY_TRACKER = Bestiary.Collector()
apply_inventory_settings()
apply_assets_settings()
apply_status_bar_settings()
apply_cooldowns_settings()
if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.apply_settings ~= nil then
    BESTIARY_TRACKER:apply_settings()
end

Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Vitals, false)
Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Target, false)
Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Party, false)

CONFIG_WINDOW = UI.Settings.ConfigWindow()
FIRST_RUN_QUICK_SETUP_WINDOW = nil
if _G.loaded_settings_was_new == true then
    FIRST_RUN_QUICK_SETUP_WINDOW = UI.Settings.FirstRunQuickSetup()
    FIRST_RUN_QUICK_SETUP_WINDOW:open()
end

Turbine.Shell.WriteLine(string.format(
    "<rgb=#3399FA>LUI</rgb> v%s by <rgb=#008080>Geldahr</rgb>",
    Plugins["LUI"]:GetVersion()
))

Plugins["LUI"].Unload = function()
    save_settings()
    if BESTIARY_WINDOW ~= nil then
        if BESTIARY_WINDOW.SetVisible ~= nil then
            BESTIARY_WINDOW:SetVisible(false)
        end
        BESTIARY_WINDOW = nil
    end
    if BESTIARY_CARD ~= nil then
        if BESTIARY_CARD.SetVisible ~= nil then
            BESTIARY_CARD:SetVisible(false)
        end
        BESTIARY_CARD = nil
        _G.BESTIARY_CARD = nil
    end
    if BESTIARY_TRACKER ~= nil then
        if BESTIARY_TRACKER.save ~= nil then
            BESTIARY_TRACKER:save()
        end
        if BESTIARY_TRACKER.destroy ~= nil then
            BESTIARY_TRACKER:destroy()
        end
        BESTIARY_TRACKER = nil
    end
    if ASSETS_STORE ~= nil then
        ASSETS_STORE:destroy()
        ASSETS_STORE = nil
    end

    save_assets_cache()
end
