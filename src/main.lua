-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.namespace"

local LUI = _G.LUI
local UI = LUI.UI
local Settings = LUI.Settings
local State = Settings.State
local Defaults = Settings.Defaults
local DefaultLayouts = Defaults.DefaultLayouts
local Persistence = Settings.Persistence
local Runtime = LUI.Runtime
local Windows = Runtime.Windows
local Stores = Runtime.Stores
local Flags = Runtime.Flags
local Apply = Runtime.Apply
local AssetCache = Runtime.Caches.Assets
local BestiaryCache = Runtime.Caches.Bestiary
local Shortcuts = UI.Shortcuts
local Features = LUI.Features
local Assets = Features.Assets
local Bestiary = Features.Bestiary
local Cooldowns = Features.Cooldowns
local Crafting = Features.Crafting
local Drops = Features.Drops
local ExpiringEffects = Features.ExpiringEffects
local Travel = Features.Travel
local StatusBar = Features.StatusBar

import "LUI.src.Utils"
import "LUI.src.Utils.coords"
import "LUI.src.Settings"
import "LUI.src.Settings.default_layouts"

import "LUI.src.UI"
import "LUI.src.ExpiringEffects"
import "LUI.src.Cooldowns"
import "LUI.src.Drops"
import "LUI.src.Assets"
import "LUI.src.Bestiary"
import "LUI.src.Crafting"
import "LUI.src.Travel"
import "LUI.src.StatusBar.api_chat_bridge"

local function _lui_window_work_area()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    display_w = tonumber(display_w) or 0
    display_h = tonumber(display_h) or 0

    local reserved_top = 0
    local status_bar = Windows.status_bar
    if status_bar ~= nil and status_bar:IsVisible() == true then
        reserved_top = math.max(0, tonumber(status_bar:GetHeight()) or 0)
    end

    reserved_top = math.min(display_h, reserved_top)
    return 0, reserved_top, display_w, math.max(0, display_h - reserved_top)
end

function Apply.saved_global_style()
    local user_style = {}
    for key, value in pairs(State.loaded_settings.global.style) do
        user_style[key] = value
    end
    UI.UserStyle = user_style
    UI.Style.WINDOW_WORK_AREA = _lui_window_work_area
end

UI.Style.WINDOW_WORK_AREA = _lui_window_work_area

StatusBar.APIChat.install_chat_callback()

local function set_backpacks_enabled(enabled)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack1, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack2, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack3, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack4, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack5, enabled == true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Backpack6, enabled == true)
end

local function _current_group_member_count()
    local local_player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if local_player == nil or local_player.GetParty == nil then
        return 0
    end

    local group = local_player:GetParty()
    if group == nil or group.GetMemberCount == nil then
        return 0
    end

    return group:GetMemberCount() or 0
end

function Apply.lotro_vitals_handoff()
    local group_member_count = _current_group_member_count()
    local disable_group_ui = false
    if group_member_count >= 7 then
        disable_group_ui = State.settings.raid.enabled == true
    elseif group_member_count > 0 then
        disable_group_ui = State.settings.fellowship.enabled == true
    end

    Turbine.UI.Lotro.LotroUI.SetEnabled(
        Turbine.UI.Lotro.LotroUIElement.Vitals,
        State.settings.self.vitals.enabled ~= true
    )
    Turbine.UI.Lotro.LotroUI.SetEnabled(
        Turbine.UI.Lotro.LotroUIElement.Target,
        State.settings.target.vitals.enabled ~= true
    )
    Turbine.UI.Lotro.LotroUI.SetEnabled(
        Turbine.UI.Lotro.LotroUIElement.Party,
        disable_group_ui ~= true
    )
end

local function _ensure_bestiary_window()
    local window = Windows.bestiary
    if window == nil then
        window = Bestiary.BestiaryWindow()
        Windows.bestiary = window
    end
    return window
end

local function _ensure_crafting_window()
    local window = Windows.crafting
    if Crafting.is_enabled() ~= true then
        return nil
    end
    if window == nil then
        window = Crafting.CraftingWindow()
        Windows.crafting = window
    end
    return window
end

local function _release_persistent_state()
    State.account_settings = nil
    State.character_settings = nil
    State.loaded_settings = nil
    State.settings = nil

    AssetCache.data = nil
    AssetCache.loaded = nil
    AssetCache.loading = nil
    AssetCache.dirty = nil
    Stores.travel = nil

    BestiaryCache.data = nil
    BestiaryCache.loaded = nil
    BestiaryCache.loading = nil
    BestiaryCache.dirty = nil
    BestiaryCache.generation = nil

    State.current_profile_id = nil
    State.current_character_name = nil
    State.loaded_settings_was_new = nil
end

function Shortcuts.toggle_config()
    if Windows.config == nil then
        return
    end

    if Windows.config:IsVisible() == true then
        Windows.config:cancel()
        return
    end

    Windows.config:open()
end

function Shortcuts.toggle_assets()
    if Windows.assets == nil then
        return
    end

    if Windows.assets:IsVisible() == true then
        Windows.assets:SetVisible(false)
        return
    end

    Windows.assets:open()
end

function Shortcuts.toggle_inventory()
    if Windows.inventory == nil then
        return
    end

    Windows.inventory:toggle()
end

function Shortcuts.toggle_bestiary()
    local window = _ensure_bestiary_window()
    if window == nil then
        return
    end

    if window:IsVisible() == true then
        window:SetVisible(false)
        return
    end

    window:open()
end

function Shortcuts.open_bestiary_item_search(item_name)
    local window = _ensure_bestiary_window()
    window:open_item_search(item_name)

    return true
end

function Shortcuts.open_bestiary_query_search(query)
    local window = _ensure_bestiary_window()
    window:open_query_search(query)

    return true
end

function Shortcuts.open_crafting_item_search(item_name, select_recipe_id)
    local window = _ensure_crafting_window()
    if window == nil then
        return false
    end

    window:open_item_search(item_name, select_recipe_id)
    return true
end

function Shortcuts.toggle_crafting()
    local window = _ensure_crafting_window()
    if window == nil then
        return
    end

    if window:IsVisible() == true then
        window:SetVisible(false)
        window:SetWantsUpdates(false)
        return
    end

    window:clear_material_filter()
    window:open()
end

function Shortcuts.toggle_travel()
    if Travel.is_enabled() ~= true then
        return
    end

    local window = Windows.travel
    if window == nil then
        window = Travel.TravelWindow()
        Windows.travel = window
    end
    if window == nil then
        return
    end

    if window:IsVisible() == true then
        window:SetVisible(false)
        window:SetWantsUpdates(false)
        return
    end

    window:open()
end

function Shortcuts.open_crafting_plan()
    local window = _ensure_crafting_window()
    if window == nil then
        return
    end

    window:clear_material_filter()
    window:open_plan()
end

function Apply.inventory_settings()
    local enabled = State.settings.inventory.enabled == true
    local replace = enabled and State.settings.inventory.replace == true

    if enabled then
        if Windows.inventory == nil then
            Windows.inventory = UI.InventoryWindow()
        else
            Windows.inventory:apply_settings()
        end
    else
        if Windows.inventory ~= nil then
            Windows.inventory:SetVisible(false)
        end
        Windows.inventory = nil
    end

    if replace then
        set_backpacks_enabled(false)
    else
        set_backpacks_enabled(true)
    end
end

function Apply.assets_settings()
    local enabled = State.settings.assets.enabled == true

    if enabled then
        if Stores.assets == nil then
            Stores.assets = Assets.AssetsStore()
        else
            Stores.assets:refresh_bindings()
        end

        if Windows.assets == nil then
            Windows.assets = UI.AssetsWindow()
        else
            Windows.assets:apply_settings()
        end
    else
        if Windows.assets ~= nil then
            Windows.assets:SetVisible(false)
        end
        Windows.assets = nil

        if Stores.assets ~= nil then
            Stores.assets:destroy()
        end
        Stores.assets = nil
    end
end

function Apply.status_bar_settings()
    local sb = State.settings.status_bar
    if Windows.status_bar ~= nil then
        Windows.status_bar:destroy()
        Windows.status_bar = nil
    end

    if sb.enabled == true then
        Windows.status_bar = UI.StatusBarWindow()
        StatusBar.APIChat.flush_pending_items()
    end
end

function Apply.cooldowns_settings()
    local cd = State.settings.self.cooldowns
    if cd.enabled == true then
        if Windows.cooldowns == nil then
            Windows.cooldowns = Cooldowns.CooldownsWindow()
        end
    else
        if Windows.cooldowns ~= nil then
            Windows.cooldowns:destroy()
        end
        Windows.cooldowns = nil
    end
end

function Apply.drops_settings()
    local drops = State.settings.drops
    if drops.enabled == true then
        if Windows.drops == nil then
            Windows.drops = Drops.DropsWindow()
        end
    else
        if Windows.drops ~= nil then
            Windows.drops:destroy()
        end
        Windows.drops = nil
    end
end

function Apply.crafting_settings()
    local enabled = State.settings.crafting.enabled == true

    if enabled ~= true then
        if Windows.crafting ~= nil then
            Windows.crafting:SetVisible(false)
            Windows.crafting.store = nil
            Windows.crafting = nil
        end
        Crafting.destroy_shared_store()
        return
    end

    local store = Crafting.get_shared_store()
    if store ~= nil then
        store:refresh(false, 1)
    end

    if Windows.crafting ~= nil then
        Windows.crafting:apply_settings()
    end
end

function Apply.travel_settings()
    local enabled = State.settings.travel.enabled == true

    if enabled ~= true then
        if Windows.travel ~= nil then
            Windows.travel:SetVisible(false)
            Windows.travel.store = nil
            Windows.travel = nil
        end
        Travel.destroy_shared_store()
        return
    end

    if Windows.travel ~= nil then
        Windows.travel:apply_settings()
    end
end

function Apply.launcher_settings()
    local enabled = State.settings.launcher.enabled == true

    if enabled ~= true then
        if Windows.launcher ~= nil then
            Windows.launcher:destroy()
        end
        Windows.launcher = nil
        return
    end

    if Windows.launcher == nil then
        Windows.launcher = UI.LauncherMenu()
    else
        Windows.launcher:apply_settings()
    end
end

Flags.is_unloading = false

Persistence.load_settings()
if State.loaded_settings_was_new == true then
    State.loaded_settings = DefaultLayouts.build("bottom", DefaultLayouts.get_resolution_scale())
    Defaults.ensure_loaded_settings()
    Settings.Colors.fix_colors()
    Settings.rebuild()
end
Apply.saved_global_style()
Flags.crafting_display_mode_active = State.settings.crafting.display_mode

Windows.bestiary_card = Bestiary.BestiaryCard()

-- Initialize target vitals first: self vitals depend on them for current target state.
Windows.target_vital = UI.TargetVitals(nil)
Windows.boss_vital = UI.BossVitals(nil)
Windows.player_vital = UI.SelfVitals(Turbine.Gameplay.LocalPlayer.GetInstance())
Windows.player_vital:set_target_vitals(Windows.target_vital, Windows.boss_vital)
Windows.companion_vital = UI.CompanionVitals(Turbine.Gameplay.LocalPlayer.GetInstance())
Windows.fellowship_vitals = UI.FellowshipVitals()
Windows.raid_vitals = UI.RaidVitals()
Windows.expiring_self_effects = ExpiringEffects.SelfExpiringEffectsWindow()
Windows.expiring_target_effects = ExpiringEffects.TargetExpiringEffectsWindow()
Windows.inventory = nil
Stores.assets = nil
Windows.assets = nil
Windows.status_bar = nil
Windows.cooldowns = nil
Windows.drops = nil
Windows.bestiary = nil
Windows.crafting = nil
Windows.travel = nil
Windows.launcher = nil
Windows.bestiary_tracker = Bestiary.Collector()

Apply.inventory_settings()
Apply.assets_settings()
Apply.status_bar_settings()
Apply.cooldowns_settings()
Apply.drops_settings()
Apply.crafting_settings()
Apply.travel_settings()
Windows.bestiary_tracker:apply_settings()

Apply.lotro_vitals_handoff()

Windows.config = Settings.ConfigWindow()
Apply.launcher_settings()
Windows.first_run_quick_setup = nil
if State.loaded_settings_was_new == true then
    Windows.first_run_quick_setup = Settings.FirstRunQuickSetup()
    Windows.first_run_quick_setup:open()
end

Turbine.Shell.WriteLine(string.format(
    "<rgb=#3399FA>LUI</rgb> v%s by <rgb=#008080>Geldahr</rgb>",
    Plugins["LUI"]:GetVersion()
))

Plugins["LUI"].Unload = function()
    Flags.is_unloading = true
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Vitals, true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Target, true)
    Turbine.UI.Lotro.LotroUI.SetEnabled(Turbine.UI.Lotro.LotroUIElement.Party, true)

    if Windows.crafting ~= nil then
        Windows.crafting:SetVisible(false)
        Windows.crafting.store = nil
        Windows.crafting = nil
    end
    Crafting.destroy_shared_store()

    if Windows.travel ~= nil then
        Windows.travel:SetVisible(false)
        Windows.travel.store = nil
        Windows.travel = nil
    end
    Travel.destroy_shared_store()

    Flags.crafting_display_mode_active = nil
    Persistence.save_settings()

    StatusBar.APIChat.uninstall_chat_callback()

    Windows.status_bar = nil

    if Windows.launcher ~= nil then
        Windows.launcher:destroy()
        Windows.launcher = nil
    end

    if Windows.assets ~= nil then
        Windows.assets:SetVisible(false)
        Windows.assets._crafting_store = nil
        Windows.assets._last_crafting_store_version = nil
        Windows.assets = nil
    end

    if Windows.bestiary ~= nil then
        Windows.bestiary:SetWantsUpdates(false)
        Windows.bestiary:SetVisible(false)
        Windows.bestiary = nil
    end

    if Windows.bestiary_card ~= nil then
        Windows.bestiary_card:SetVisible(false)
        Windows.bestiary_card = nil
    end

    if Windows.companion_vital ~= nil then
        Windows.companion_vital:destroy()
        Windows.companion_vital = nil
    end

    if Windows.bestiary_tracker ~= nil then
        Windows.bestiary_tracker:save()
        Windows.bestiary_tracker:destroy()
        Windows.bestiary_tracker = nil
    end

    if Windows.drops ~= nil then
        Windows.drops:destroy()
        Windows.drops = nil
    end

    if Stores.assets ~= nil then
        Stores.assets:destroy()
        Stores.assets = nil
    end

    Persistence.save_assets_cache()
    _release_persistent_state()
end
