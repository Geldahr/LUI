import "Turbine.UI"

import "LUI.src.UI.assets"

UI = UI or {}
UI.Shortcuts = UI.Shortcuts or {}

local Shortcuts = UI.Shortcuts

Shortcuts.CONFIG_ICON = UI.AssetIds.feather
Shortcuts.INVENTORY_ICON = UI.AssetIds.backpack_alt
Shortcuts.CRAFT_ICON = UI.AssetIds.anvil_silver_glow
Shortcuts.TRAVEL_ICON = UI.AssetIds.compass
Shortcuts.ASSETS_ICON = UI.AssetIds.chest
Shortcuts.BESTIARY_ICON = UI.AssetIds.book_orange_cover

local VALID_SHORTCUTS = {
    config = true,
    inventory = true,
    assets = true,
    craft = true,
    travel = true,
    bestiary = true,
}

local function _window_is_visible(window)
    return window ~= nil and window.IsVisible ~= nil and window:IsVisible() == true
end

function Shortcuts.is_valid(shortcut_key)
    return VALID_SHORTCUTS[shortcut_key] == true
end

function Shortcuts.get_icon(shortcut_key)
    if shortcut_key == "config" then
        return Shortcuts.CONFIG_ICON
    elseif shortcut_key == "inventory" then
        return Shortcuts.INVENTORY_ICON
    elseif shortcut_key == "craft" then
        return Shortcuts.CRAFT_ICON
    elseif shortcut_key == "travel" then
        return Shortcuts.TRAVEL_ICON
    elseif shortcut_key == "assets" then
        return Shortcuts.ASSETS_ICON
    elseif shortcut_key == "bestiary" then
        return Shortcuts.BESTIARY_ICON
    end
    return nil
end

function Shortcuts.get_label(shortcut_key)
    if shortcut_key == "config" then
        return TR["Config"]
    elseif shortcut_key == "inventory" then
        return TR["Inventory"]
    elseif shortcut_key == "craft" then
        return TR["Craft"]
    elseif shortcut_key == "travel" then
        return TR["Travel"]
    elseif shortcut_key == "assets" then
        return TR["Assets"]
    elseif shortcut_key == "bestiary" then
        return TR["Bestiary"]
    end
    return ""
end

function Shortcuts.get_state(shortcut_key)
    if shortcut_key == "config" then
        return CONFIG_WINDOW ~= nil, _window_is_visible(CONFIG_WINDOW)
    elseif shortcut_key == "inventory" then
        return INVENTORY_WINDOW ~= nil, _window_is_visible(INVENTORY_WINDOW)
    elseif shortcut_key == "craft" then
        local enabled = Crafting.is_enabled() == true
        local can_open = enabled == true and (_G.CRAFTING_WINDOW ~= nil or Crafting.CraftingWindow ~= nil)
        return can_open, _window_is_visible(_G.CRAFTING_WINDOW)
    elseif shortcut_key == "travel" then
        return _G.settings.travel.enabled == true, _window_is_visible(_G.TRAVEL_WINDOW)
    elseif shortcut_key == "assets" then
        return ASSETS_WINDOW ~= nil, _window_is_visible(ASSETS_WINDOW)
    elseif shortcut_key == "bestiary" then
        local can_open = _G.BESTIARY_WINDOW ~= nil or Bestiary.BestiaryWindow ~= nil
        return can_open, _window_is_visible(_G.BESTIARY_WINDOW)
    end
    return false, false
end

function Shortcuts.activate(shortcut_key)
    if shortcut_key == "config" then
        _G.toggle_config_shortcut()
    elseif shortcut_key == "inventory" then
        _G.toggle_inventory_shortcut()
    elseif shortcut_key == "craft" then
        _G.toggle_crafting_shortcut()
    elseif shortcut_key == "travel" then
        _G.toggle_travel_shortcut()
    elseif shortcut_key == "assets" then
        _G.toggle_assets_shortcut()
    elseif shortcut_key == "bestiary" then
        _G.toggle_bestiary_shortcut()
    end
end
