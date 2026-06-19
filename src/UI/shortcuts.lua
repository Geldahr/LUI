local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
local Crafting = _G.LUI.Features.Crafting
local Bestiary = _G.LUI.Features.Bestiary
import "Turbine.UI"

import "LUI.src.UI.assets"

local Shortcuts = UI.Shortcuts

Shortcuts.CONFIG_ICON = UI.AssetIds.feather
Shortcuts.INVENTORY_ICON = UI.AssetIds.backpack_alt
Shortcuts.CRAFT_ICON = UI.AssetIds.anvil_silver_glow
Shortcuts.TRAVEL_ICON = UI.AssetIds.compass
Shortcuts.ASSETS_ICON = UI.AssetIds.chest
Shortcuts.BESTIARY_ICON = UI.AssetIds.book_orange_cover

local function _window_is_visible(window)
    return window ~= nil and window.IsVisible ~= nil and window:IsVisible() == true
end

local STATIC_SHORTCUTS = {
    {
        key = "config",
        label = TR["Config"],
        icon = Shortcuts.CONFIG_ICON,
        get_state = function()
            return Windows.config ~= nil, _window_is_visible(Windows.config)
        end,
        activate = function()
            Shortcuts.toggle_config()
        end,
    },
    {
        key = "inventory",
        label = TR["Inventory"],
        icon = Shortcuts.INVENTORY_ICON,
        get_state = function()
            return Windows.inventory ~= nil, _window_is_visible(Windows.inventory)
        end,
        activate = function()
            Shortcuts.toggle_inventory()
        end,
    },
    {
        key = "assets",
        label = TR["Assets"],
        icon = Shortcuts.ASSETS_ICON,
        get_state = function()
            return Windows.assets ~= nil, _window_is_visible(Windows.assets)
        end,
        activate = function()
            Shortcuts.toggle_assets()
        end,
    },
    {
        key = "craft",
        label = TR["Craft"],
        icon = Shortcuts.CRAFT_ICON,
        get_state = function()
            local enabled = Crafting.is_enabled() == true
            local can_open = enabled == true and (Windows.crafting ~= nil or Crafting.CraftingWindow ~= nil)
            return can_open, _window_is_visible(Windows.crafting)
        end,
        activate = function()
            Shortcuts.toggle_crafting()
        end,
    },
    {
        key = "travel",
        label = TR["Travel"],
        icon = Shortcuts.TRAVEL_ICON,
        get_state = function()
            return State.settings.travel.enabled == true, _window_is_visible(Windows.travel)
        end,
        activate = function()
            Shortcuts.toggle_travel()
        end,
    },
    {
        key = "bestiary",
        label = TR["Bestiary"],
        icon = Shortcuts.BESTIARY_ICON,
        get_state = function()
            local can_open = Windows.bestiary ~= nil or Bestiary.BestiaryWindow ~= nil
            return can_open, _window_is_visible(Windows.bestiary)
        end,
        activate = function()
            Shortcuts.toggle_bestiary()
        end,
    },
}

local STATIC_BY_KEY = {}
for i = 1, #STATIC_SHORTCUTS do
    STATIC_BY_KEY[STATIC_SHORTCUTS[i].key] = STATIC_SHORTCUTS[i]
end

Shortcuts.Dynamic = Shortcuts.Dynamic or {
    by_key = {},
    order = {},
}

local DYNAMIC_SHORTCUTS = Shortcuts.Dynamic
DYNAMIC_SHORTCUTS.by_key = DYNAMIC_SHORTCUTS.by_key or {}
DYNAMIC_SHORTCUTS.order = DYNAMIC_SHORTCUTS.order or {}

local function _copy_shortcut_definitions()
    local out = {}
    for i = 1, #STATIC_SHORTCUTS do
        local spec = STATIC_SHORTCUTS[i]
        out[#out + 1] = {
            key = spec.key,
            label = spec.label,
        }
    end
    for i = 1, #DYNAMIC_SHORTCUTS.order do
        local key = DYNAMIC_SHORTCUTS.order[i]
        local spec = DYNAMIC_SHORTCUTS.by_key[key]
        if spec ~= nil then
            out[#out + 1] = {
                key = spec.key,
                label = spec.label,
            }
        end
    end
    return out
end

local function _shortcut_spec(shortcut_key)
    local static = STATIC_BY_KEY[shortcut_key]
    if static ~= nil then
        return static
    end
    return DYNAMIC_SHORTCUTS.by_key[shortcut_key]
end

function Shortcuts.register(spec)
    if type(spec) ~= "table" then
        error("Shortcuts.register expects a table")
    end
    if type(spec.key) ~= "string" or spec.key == "" then
        error("Shortcuts.register is missing key")
    end
    if STATIC_BY_KEY[spec.key] ~= nil then
        error("Shortcut key is reserved: " .. spec.key)
    end
    if type(spec.label) ~= "string" or spec.label == "" then
        error("Shortcuts.register is missing label: " .. spec.key)
    end
    if spec.icon == nil then
        error("Shortcuts.register is missing icon: " .. spec.key)
    end
    if type(spec.get_state) ~= "function" then
        error("Shortcuts.register is missing get_state: " .. spec.key)
    end
    if type(spec.activate) ~= "function" then
        error("Shortcuts.register is missing activate: " .. spec.key)
    end

    local entry = DYNAMIC_SHORTCUTS.by_key[spec.key]
    if entry == nil then
        entry = {}
        DYNAMIC_SHORTCUTS.by_key[spec.key] = entry
        DYNAMIC_SHORTCUTS.order[#DYNAMIC_SHORTCUTS.order + 1] = spec.key
    end

    entry.key = spec.key
    entry.label = spec.label
    entry.icon = spec.icon
    entry.get_state = spec.get_state
    entry.activate = spec.activate
    return entry
end

function Shortcuts.is_valid(shortcut_key)
    return _shortcut_spec(shortcut_key) ~= nil
end

function Shortcuts.get_icon(shortcut_key)
    local spec = _shortcut_spec(shortcut_key)
    if spec ~= nil then
        return spec.icon
    end
    return nil
end

function Shortcuts.get_label(shortcut_key)
    local spec = _shortcut_spec(shortcut_key)
    if spec ~= nil then
        return spec.label
    end
    return ""
end

function Shortcuts.get_state(shortcut_key)
    local spec = _shortcut_spec(shortcut_key)
    if spec ~= nil then
        return spec.get_state()
    end
    return false, false
end

function Shortcuts.activate(shortcut_key)
    local spec = _shortcut_spec(shortcut_key)
    if spec ~= nil then
        spec.activate()
    end
end

function Shortcuts.get_launcher_definitions()
    return _copy_shortcut_definitions()
end

function Shortcuts.get_dynamic_status_bar_keys()
    local out = {}
    for i = 1, #DYNAMIC_SHORTCUTS.order do
        out[#out + 1] = DYNAMIC_SHORTCUTS.order[i]
    end
    return out
end
