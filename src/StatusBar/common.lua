import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.stretch"
import "LUI.src.Settings.enums"

_G.STATUS_BAR_COMMON = _G.STATUS_BAR_COMMON or {}
local S = _G.STATUS_BAR_COMMON

S.ICON_GAP = 4
S.ICON_INSET = 4
S.BACKPACK_ICON_W = 24
S.BACKPACK_ICON_H = 30

S.GOLD_ICON = Turbine.UI.Graphic(0x41007e7b)
S.SILVER_ICON = Turbine.UI.Graphic(0x41007e7c)
S.COPPER_ICON = Turbine.UI.Graphic(0x41007e7d)
S.INVENTORY_SPACE_ICON = Turbine.UI.Graphic(0x41008113)
S.DURABILITY_ICON = Turbine.UI.Graphic(0x41003061)
S.CONFIG_SHORTCUT_ICON = Turbine.UI.Graphic(0x41004D92)
S.ASSETS_SHORTCUT_ICON = Turbine.UI.Graphic(0x41003830)
S.BESTIARY_SHORTCUT_ICON = Turbine.UI.Graphic(0x410031FB)

S.SHORTCUT_BORDER_COLOR = Turbine.UI.Color(0.90, 0.28, 0.35, 0.45)
S.SHORTCUT_BORDER_HOVER_COLOR = Turbine.UI.Color(0.98, 0.38, 0.46, 0.56)

S.ITEM_WEAR_STATE = Turbine.Gameplay.ItemWearState or {}
S.EQUIPMENT_SLOTS = {
    Turbine.Gameplay.Equipment.Head,
    Turbine.Gameplay.Equipment.Chest,
    Turbine.Gameplay.Equipment.Legs,
    Turbine.Gameplay.Equipment.Gloves,
    Turbine.Gameplay.Equipment.Boots,
    Turbine.Gameplay.Equipment.Shoulder,
    Turbine.Gameplay.Equipment.Back,
    Turbine.Gameplay.Equipment.Bracelet1,
    Turbine.Gameplay.Equipment.Bracelet2,
    Turbine.Gameplay.Equipment.Necklace,
    Turbine.Gameplay.Equipment.Ring1,
    Turbine.Gameplay.Equipment.Ring2,
    Turbine.Gameplay.Equipment.Earring1,
    Turbine.Gameplay.Equipment.Earring2,
    Turbine.Gameplay.Equipment.Pocket,
    Turbine.Gameplay.Equipment.PrimaryWeapon,
    Turbine.Gameplay.Equipment.SecondaryWeapon,
    Turbine.Gameplay.Equipment.RangedWeapon,
    Turbine.Gameplay.Equipment.CraftTool,
    Turbine.Gameplay.Equipment.Class,
}
S.WEAR_STATE_TO_PERCENT = {
    [S.ITEM_WEAR_STATE.Pristine or 2] = 100,
    [S.ITEM_WEAR_STATE.Worn or 4] = 75,
    [S.ITEM_WEAR_STATE.Damaged or 1] = 20,
    [S.ITEM_WEAR_STATE.Broken or 3] = 0,
}

function S.format_hhmm(date)
    if date == nil then
        return "--:--"
    end
    local h = date.Hour or 0
    local m = date.Minute or 0
    return string.format("%02d:%02d", h, m)
end

function S.get_centered_icon_y(container_h, icon_h)
    return math.floor((container_h - icon_h) / 2)
end

function S.get_icon_size(bar_h)
    local size = bar_h - S.ICON_INSET
    if size < 0 then
        return 0
    end
    return size
end

function S.get_widget_icon_w(widget_key, icon_h)
    if widget_key == "inventory_space" then
        return math.floor(((icon_h * S.BACKPACK_ICON_W) / S.BACKPACK_ICON_H) + 0.5)
    end
    return icon_h
end

function S.get_widget_icon(widget_key)
    if widget_key == "inventory_space" then
        return S.INVENTORY_SPACE_ICON
    elseif widget_key == "equipment_wear" then
        return S.DURABILITY_ICON
    end
    return nil
end

function S.get_shortcut_icon(shortcut_key)
    if shortcut_key == "config" then
        return S.CONFIG_SHORTCUT_ICON
    elseif shortcut_key == "assets" then
        return S.ASSETS_SHORTCUT_ICON
    elseif shortcut_key == "bestiary" then
        return S.BESTIARY_SHORTCUT_ICON
    end
    return nil
end

function S.get_shortcut_icon_w(icon_background, icon_h)
    if icon_background == nil or icon_h <= 0 then
        return 0
    end

    local base_w, base_h = get_background_base_size(icon_background)
    if type(base_w) ~= "number" or type(base_h) ~= "number" or base_w <= 0 or base_h <= 0 then
        return icon_h
    end

    return math.floor(((icon_h * base_w) / base_h) + 0.5)
end

function S.window_is_visible(window)
    return window ~= nil and window.IsVisible ~= nil and window:IsVisible() == true
end

function S.with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

function S.get_shortcut_label(shortcut_key)
    if shortcut_key == "config" then
        return TR("Config")
    elseif shortcut_key == "assets" then
        return TR("Assets")
    elseif shortcut_key == "bestiary" then
        return TR("Bestiary")
    end
    return ""
end

function S.get_shortcut_state(shortcut_key)
    if shortcut_key == "config" then
        return CONFIG_WINDOW ~= nil, S.window_is_visible(CONFIG_WINDOW)
    elseif shortcut_key == "assets" then
        return ASSETS_WINDOW ~= nil, S.window_is_visible(ASSETS_WINDOW)
    elseif shortcut_key == "bestiary" then
        local can_open = _G.BESTIARY_WINDOW ~= nil or (Bestiary ~= nil and Bestiary.BestiaryWindow ~= nil)
        return can_open, S.window_is_visible(_G.BESTIARY_WINDOW)
    end
    return false, false
end

function S.activate_shortcut(shortcut_key)
    if shortcut_key == "config" then
        if _G.toggle_config_shortcut ~= nil then
            _G.toggle_config_shortcut()
        end
    elseif shortcut_key == "assets" then
        if _G.toggle_assets_shortcut ~= nil then
            _G.toggle_assets_shortcut()
        end
    elseif shortcut_key == "bestiary" then
        if _G.toggle_bestiary_shortcut ~= nil then
            _G.toggle_bestiary_shortcut()
        end
    end
end

function S.clamp_shortcut_height(widget_h, bar_h)
    local h = widget_h
    if type(h) ~= "number" then
        h = tonumber(h)
    end
    if h == nil then
        h = bar_h
    end
    h = math.floor(h + 0.5)
    if h < 1 then
        h = 1
    end
    if h > bar_h then
        h = bar_h
    end
    return h
end

function S.sum_widget_width(widgets, gap)
    if widgets == nil then
        return 0
    end
    local w = 0
    for i = 1, #widgets do
        local c = widgets[i]
        if c ~= nil and c.GetWidth ~= nil then
            w = w + c:GetWidth()
        end
    end
    if #widgets > 1 then
        w = w + (gap * (#widgets - 1))
    end
    return w
end

function S.split_money_copper(total_copper)
    local v = total_copper
    if type(v) ~= "number" then
        v = tonumber(v)
    end
    if v == nil then
        return nil
    end

    local gold = math.floor(v / 100000)
    local silver = math.floor(v / 100) - gold * 1000
    local copper = v - gold * 100000 - silver * 100
    return gold, silver, copper
end

function S.format_money_copper(total_copper)
    local gold, silver, copper = S.split_money_copper(total_copper)
    if gold == nil then
        return "--"
    end
    return string.format("%dg %ds %dc", gold, silver, copper)
end

function S.format_gold_compact(gold)
    return lui_abbrev_gold(gold)
end

function S.round_nearest(value)
    return math.floor((value or 0) + 0.5)
end

function S.wear_state_to_percent(wear_state)
    return S.WEAR_STATE_TO_PERCENT[wear_state]
end

function S.wear_percent_to_color_key(percent)
    if percent == nil or percent <= 0 then
        return "broken"
    end
    if percent < 50 then
        return "damaged"
    end
    if percent < 90 then
        return "worn"
    end
    return "pristine"
end

function S.color_markup(text, color)
    if color == nil then
        return tostring(text or "")
    end
    return "<rgb=" .. lui_color_to_hex(color) .. ">" .. tostring(text or "") .. "</rgb>"
end
