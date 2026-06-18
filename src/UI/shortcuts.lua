local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local is_boss_target = _G.LUI.Utils.is_boss_target
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_format_timeout_seconds = _G.LUI.Utils.lui_format_timeout_seconds
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_timed_row_resolved_font_size = _G.LUI.Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_timed_row_min_item_width = _G.LUI.Utils.lui_timed_row_min_item_width
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_resolved_font_size = _G.LUI.Utils.lui_cooldown_resolved_font_size
local lui_cooldown_estimate_text_width = _G.LUI.Utils.lui_cooldown_estimate_text_width
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_cooldown_min_name_width = _G.LUI.Utils.lui_cooldown_min_name_width
local lui_cooldown_min_timed_bar_width = _G.LUI.Utils.lui_cooldown_min_timed_bar_width
local lui_cooldown_min_item_width = _G.LUI.Utils.lui_cooldown_min_item_width
local lui_clamp_ratio = _G.LUI.Utils.lui_clamp_ratio
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_lerp_number = _G.LUI.Utils.lui_lerp_number
local lui_lerp_color = _G.LUI.Utils.lui_lerp_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
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
        local can_open = Windows.bestiary ~= nil or Bestiary.BestiaryWindow ~= nil
        return can_open, _window_is_visible(Windows.bestiary)
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
        Shortcuts.toggle_bestiary()
    end
end
