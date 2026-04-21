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
import "LUI.src.Crafting"
import "LUI.src.StatusBar.api_chat_bridge"

_G.STYLE = _G.STYLE or {}
_G.STYLE.WINDOW_WORK_AREA = function()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    display_w = tonumber(display_w) or 0
    display_h = tonumber(display_h) or 0

    local reserved_top = 0
    local status_bar = _G.STATUS_BAR

    if status_bar ~= nil and status_bar.IsVisible ~= nil and status_bar:IsVisible() == true then
        reserved_top = math.max(0, tonumber(status_bar:GetHeight()) or 0)
    end

    reserved_top = math.min(display_h, reserved_top)
    return 0, reserved_top, display_w, math.max(0, display_h - reserved_top)
end

if _G.LUI_STATUS_BAR_API_INSTALL_CHAT_CALLBACK ~= nil then
    _G.LUI_STATUS_BAR_API_INSTALL_CHAT_CALLBACK()
end

local function set_backpacks_enabled(enabled)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack1, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack2, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack3, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack4, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack5, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack6, enabled == true)
end

local function _ensure_bestiary_window()
    local window = _G.BESTIARY_WINDOW
    if window == nil and Bestiary ~= nil and Bestiary.BestiaryWindow ~= nil then
        window = Bestiary.BestiaryWindow()
        _G.BESTIARY_WINDOW = window
    end
    return window
end

local function _ensure_crafting_window()
    local window = _G.CRAFTING_WINDOW
    if Crafting ~= nil and Crafting.is_enabled ~= nil and Crafting.is_enabled() ~= true then
        return nil
    end
    if window == nil and Crafting ~= nil and Crafting.CraftingWindow ~= nil then
        window = Crafting.CraftingWindow()
        _G.CRAFTING_WINDOW = window
    end
    return window
end

local function _release_persistent_state()
    _G.account_settings = nil
    _G.server_settings = nil
    _G.loaded_settings = nil
    _G.settings = nil

    _G.assets_cache = nil
    _G.assets_cache_loaded = nil
    _G.assets_cache_loading = nil
    _G.assets_cache_dirty = nil

    _G.bestiary_cache = nil
    _G.bestiary_cache_loaded = nil
    _G.bestiary_cache_loading = nil
    _G.bestiary_cache_dirty = nil
    _G.bestiary_cache_generation = nil

    _G.current_profile_id = nil
    _G.current_character_name = nil
    _G.loaded_settings_was_new = nil
end

function _G.toggle_config_shortcut()
    if CONFIG_WINDOW == nil then
        return
    end

    if CONFIG_WINDOW:IsVisible() == true then
        if CONFIG_WINDOW.cancel ~= nil then
            CONFIG_WINDOW:cancel()
        else
            CONFIG_WINDOW:SetVisible(false)
        end
        return
    end

    if CONFIG_WINDOW.open ~= nil then
        CONFIG_WINDOW:open()
    end
end

function _G.toggle_assets_shortcut()
    if ASSETS_WINDOW == nil then
        return
    end

    if ASSETS_WINDOW:IsVisible() == true then
        ASSETS_WINDOW:SetVisible(false)
        return
    end

    if ASSETS_WINDOW.open ~= nil then
        ASSETS_WINDOW:open()
    else
        ASSETS_WINDOW:SetVisible(true)
    end
end

function _G.toggle_bestiary_shortcut()
    local window = _ensure_bestiary_window()
    if window == nil then
        return
    end

    if window:IsVisible() == true then
        window:SetVisible(false)
        return
    end

    if window.open ~= nil then
        window:open()
    else
        window:SetVisible(true)
    end
end

function _G.toggle_crafting_shortcut()
    local window = _ensure_crafting_window()
    if window == nil then
        return
    end

    if window:IsVisible() == true then
        window:SetVisible(false)
        window:SetWantsUpdates(false)
        return
    end

    if window.clear_material_filter ~= nil then
        window:clear_material_filter()
    end
    if window.open ~= nil then
        window:open()
    else
        window:SetVisible(true)
    end
end

function _G.open_crafting_plan_shortcut()
    local window = _ensure_crafting_window()
    if window == nil then
        return
    end

    if window.clear_material_filter ~= nil then
        window:clear_material_filter()
    end
    if window.open_plan ~= nil then
        window:open_plan()
    elseif window.open ~= nil then
        window:open()
    else
        window:SetVisible(true)
    end
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
        _G.STATUS_BAR = nil
    end

    if sb.enabled == true then
        STATUS_BAR = UI.StatusBarWindow()
        _G.STATUS_BAR = STATUS_BAR
        if _G.LUI_STATUS_BAR_API_FLUSH_PENDING_ITEMS ~= nil then
            _G.LUI_STATUS_BAR_API_FLUSH_PENDING_ITEMS()
        end
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

function apply_crafting_settings()
    local enabled = _G.settings ~= nil and _G.settings.crafting ~= nil and _G.settings.crafting.enabled == true

    if enabled ~= true then
        if CRAFTING_WINDOW ~= nil then
            if CRAFTING_WINDOW.SetVisible ~= nil then
                CRAFTING_WINDOW:SetVisible(false)
            end
            CRAFTING_WINDOW.store = nil
            CRAFTING_WINDOW = nil
            _G.CRAFTING_WINDOW = nil
        end
        if Crafting ~= nil and Crafting.destroy_shared_store ~= nil then
            Crafting.destroy_shared_store()
        end
        return
    end

    if Crafting ~= nil and Crafting.get_shared_store ~= nil then
        local store = Crafting.get_shared_store()
        if store ~= nil and store.refresh ~= nil then
            store:refresh(false, 1)
        end
    end

    if CRAFTING_WINDOW ~= nil and CRAFTING_WINDOW.apply_settings ~= nil then
        CRAFTING_WINDOW:apply_settings()
    end
end

_G.LUI_IS_UNLOADING = false

load_settings()
if _G.loaded_settings_was_new == true then
    _G.loaded_settings = _G.DefaultLayouts.build("bottom", _G.DefaultLayouts.get_resolution_scale())
    _G.ensure_loaded_settings()
    _G.fix_colors()
    _G.rebuild_settings()
end
_G.LUI_CRAFTING_DISPLAY_MODE_ACTIVE = (
    _G.settings ~= nil and _G.settings.crafting ~= nil and _G.settings.crafting.display_mode
) or "pages"

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
_G.STATUS_BAR = nil
COOLDOWNS_WINDOW = nil
BESTIARY_WINDOW = nil
CRAFTING_WINDOW = nil
BESTIARY_TRACKER = Bestiary.Collector()
apply_inventory_settings()
apply_assets_settings()
apply_status_bar_settings()
apply_cooldowns_settings()
apply_crafting_settings()
if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.apply_settings ~= nil then
    BESTIARY_TRACKER:apply_settings()
end

Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Vitals, false)
Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Target, false)
Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Party, false)

CONFIG_WINDOW = Settings.ConfigWindow()
FIRST_RUN_QUICK_SETUP_WINDOW = nil
if _G.loaded_settings_was_new == true then
    FIRST_RUN_QUICK_SETUP_WINDOW = Settings.FirstRunQuickSetup()
    FIRST_RUN_QUICK_SETUP_WINDOW:open()
end

Turbine.Shell.WriteLine(string.format(
    "<rgb=#3399FA>LUI</rgb> v%s by <rgb=#008080>Geldahr</rgb>",
    Plugins["LUI"]:GetVersion()
))

Plugins["LUI"].Unload = function()
    _G.LUI_IS_UNLOADING = true
    if CRAFTING_WINDOW ~= nil then
        if CRAFTING_WINDOW.SetVisible ~= nil then
            CRAFTING_WINDOW:SetVisible(false)
        end
        CRAFTING_WINDOW.store = nil
        CRAFTING_WINDOW = nil
        _G.CRAFTING_WINDOW = nil
    end
    if Crafting ~= nil and Crafting.destroy_shared_store ~= nil then
        Crafting.destroy_shared_store()
    end
    _G.LUI_CRAFTING_DISPLAY_MODE_ACTIVE = nil
    save_settings()
    if _G.LUI_STATUS_BAR_API_UNINSTALL_CHAT_CALLBACK ~= nil then
        _G.LUI_STATUS_BAR_API_UNINSTALL_CHAT_CALLBACK()
    end
    _G.STATUS_BAR = nil
    if ASSETS_WINDOW ~= nil then
        if ASSETS_WINDOW.SetVisible ~= nil then
            ASSETS_WINDOW:SetVisible(false)
        end
        ASSETS_WINDOW._crafting_store = nil
        ASSETS_WINDOW._last_crafting_store_version = nil
        ASSETS_WINDOW = nil
    end
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
    _release_persistent_state()
end
