-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Windows = _G.LUI.Runtime.Windows
local Crafting = _G.LUI.Features.Crafting
import "Turbine.UI"

import "LUI.src.UI.assets"

local Shortcuts = UI.Shortcuts

-- shortcut icons: tinted Lucide icons (Widgets.Icons names), or the old
-- game art with the ICON_MENU_LEGACY style setting
local LUCIDE_ICONS = {
    config = "settings",
    inventory = "backpack",
    craft = "anvil",
    travel = "compass",
    assets = "briefcase",
    encyclopedia = "book_open_text",
    raid = "users",
}
local LEGACY_ICONS = {
    config = UI.AssetIds.feather,
    inventory = UI.AssetIds.backpack_alt,
    craft = UI.AssetIds.anvil_silver_glow,
    travel = UI.AssetIds.compass,
    assets = UI.AssetIds.chest,
    encyclopedia = UI.AssetIds.book_orange_cover,
    raid = UI.AssetIds.party_leader_banner,
}

local VALID_SHORTCUTS = {
    config = true,
    inventory = true,
    assets = true,
    craft = true,
    travel = true,
    encyclopedia = true,
    raid = true,
}

local function _window_is_visible(window)
    return window ~= nil and window.IsVisible ~= nil and window:IsVisible() == true
end

function Shortcuts.is_valid(shortcut_key)
    return VALID_SHORTCUTS[shortcut_key] == true
end

-- LUI's own status bar API buttons whose image has a Lucide version (the
-- LUIReloader helper registers its button with this image)
local LUCIDE_API_IMAGES = {
    ["LUI/reloader/reload.tga"] = "refresh_cw",
}

-- true when the shortcut icons are the tinted Lucide set
function Shortcuts.icons_tinted()
    return UI.Widgets.Style.ICON_MENU_LEGACY ~= true
end

function Shortcuts.get_icon(shortcut_key)
    return Shortcuts.get_style_icon(shortcut_key, Shortcuts.icons_tinted() ~= true)
end

-- a shortcut's icon in a given style, whatever the setting (quick setup
-- preview): the old game art when `legacy`, else the Lucide icon (tint it
-- with ICON_MENU)
function Shortcuts.get_style_icon(shortcut_key, legacy)
    if legacy == true then
        return LEGACY_ICONS[shortcut_key]
    end
    return UI.Widgets.Icons.path(LUCIDE_ICONS[shortcut_key])
end

-- a shortcut's icon on a LuiButton: the Menu icons color (shared hover /
-- pressed / disabled icon colors), the legacy art untinted
function Shortcuts.apply_button_icon(button, shortcut_key, width, height, position)
    local icon = Shortcuts.get_icon(shortcut_key)
    if Shortcuts.icons_tinted() == true then
        local Style = UI.Widgets.Style
        button:set_tinted_icon(icon, width, height, position)
        button:set_icon_tint(Style.ICON_MENU, Style.ICON_FOREGROUND_HOVER, Style.ICON_FOREGROUND_PRESSED,
            Style.ICON_FOREGROUND_DISABLED)
    else
        button:set_icon(icon, nil, nil, nil, width, height, position)
        button:set_icon_tint(nil, nil, nil, nil)
    end
end

-- the image a status bar API button shows and its tint (nil: as given);
-- LUI's own buttons follow the menu icon set
function Shortcuts.api_button_icon(image)
    local name = LUCIDE_API_IMAGES[image]
    if name ~= nil and Shortcuts.icons_tinted() == true then
        return UI.Widgets.Icons.path(name), UI.Widgets.Style.ICON_MENU
    end
    return image, nil
end

-- a shortcut's icon in a LuiWindow title bar
function Shortcuts.apply_window_icon(window, shortcut_key)
    window:set_icon(Shortcuts.get_icon(shortcut_key))
    if Shortcuts.icons_tinted() == true then
        window:set_icon_tint(UI.Widgets.Style.ICON_MENU)
    else
        window:set_icon_tint(nil)
    end
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
    elseif shortcut_key == "encyclopedia" then
        return TR["Encyclopedia"]
    elseif shortcut_key == "raid" then
        return TR["Raid Manager"]
    end
    return ""
end

function Shortcuts.get_state(shortcut_key)
    if shortcut_key == "config" then
        return Windows.config ~= nil, _window_is_visible(Windows.config)
    elseif shortcut_key == "inventory" then
        return Windows.inventory ~= nil, _window_is_visible(Windows.inventory)
    elseif shortcut_key == "craft" then
        -- the window is created on demand from the imported constructor,
        -- so the toggle can always open it while crafting is enabled
        return Crafting.is_enabled() == true, _window_is_visible(Windows.crafting)
    elseif shortcut_key == "travel" then
        return State.settings.travel.enabled == true, _window_is_visible(Windows.travel)
    elseif shortcut_key == "assets" then
        return Windows.assets ~= nil, _window_is_visible(Windows.assets)
    elseif shortcut_key == "encyclopedia" then
        -- created on demand from the imported constructor; always openable
        return true, _window_is_visible(Windows.encyclopedia)
    elseif shortcut_key == "raid" then
        -- created on demand from the imported constructor; always openable
        return true, _window_is_visible(Windows.raid_config)
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
    elseif shortcut_key == "encyclopedia" then
        Shortcuts.toggle_encyclopedia()
    elseif shortcut_key == "raid" then
        Shortcuts.toggle_raid_groups()
    end
end
