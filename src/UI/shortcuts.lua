-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
local Crafting = _G.LUI.Features.Crafting
local Encyclopedia = _G.LUI.Features.Encyclopedia
import "Turbine.UI"

import "LUI.src.UI.assets"

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
        return Windows.config ~= nil, _window_is_visible(Windows.config)
    elseif shortcut_key == "inventory" then
        return Windows.inventory ~= nil, _window_is_visible(Windows.inventory)
    elseif shortcut_key == "craft" then
        local enabled = Crafting.is_enabled() == true
        local can_open = enabled == true and (Windows.crafting ~= nil or Crafting.CraftingWindow ~= nil)
        return can_open, _window_is_visible(Windows.crafting)
    elseif shortcut_key == "travel" then
        return State.settings.travel.enabled == true, _window_is_visible(Windows.travel)
    elseif shortcut_key == "assets" then
        return Windows.assets ~= nil, _window_is_visible(Windows.assets)
    elseif shortcut_key == "bestiary" then
        local can_open = Windows.encyclopedia ~= nil or Encyclopedia.EncyclopediaWindow ~= nil
        return can_open, _window_is_visible(Windows.encyclopedia)
    end
    return false, false
end

function Shortcuts.activate(shortcut_key)
    if shortcut_key == "config" then
        Shortcuts.toggle_config()
    elseif shortcut_key == "inventory" then
        Shortcuts.toggle_inventory()
    elseif shortcut_key == "craft" then
        Shortcuts.toggle_crafting()
    elseif shortcut_key == "travel" then
        Shortcuts.toggle_travel()
    elseif shortcut_key == "assets" then
        Shortcuts.toggle_assets()
    elseif shortcut_key == "bestiary" then
        Shortcuts.toggle_encyclopedia()
    end
end
