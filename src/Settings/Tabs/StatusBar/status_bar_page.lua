import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_wallet_selector"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_layout_help"

local CreateStatusBarWalletSelector = LUI.src.Settings.Tabs.StatusBar.CreateStatusBarWalletSelector or
    CreateStatusBarWalletSelector
local BuildStatusBarLayoutHelp = LUI.src.Settings.Tabs.StatusBar.BuildStatusBarLayoutHelp or
    BuildStatusBarLayoutHelp
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local scaled_int = FeatureShell.scaled_int

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _bind_outline_visibility(owner_page, colors_font_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        colors_font_page:layout()
        owner_page:layout()
    end
end

local function _new_colors_section(window, settings_getter)
    local ui = window._ui

    local background = ConfigContent(window, 3)
    background:add_bound_color_picker(TR["Background color"], "sb_bg_color",
        function(value)
            settings_getter().bg.color = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().bg.color))
        end)

    local font = ConfigContent(window, 3)
    font:add_bound_color_picker(TR["Font color"], "sb_font_color",
        function(value)
            settings_getter().font.color = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.color))
        end)
    font:add_bound_color_picker(TR["Outline color"], "sb_font_outline_color",
        function(value)
            settings_getter().font.outline_color = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.outline_color))
        end)

    local inventory = ConfigContent(window, 3)
    inventory:add_bound_color_picker(TR["Warn color (30%)"], "sb_inv_yellow",
        function(value)
            settings_getter().widgets.inventory_space.color.yellow = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.inventory_space.color.yellow))
        end)
    inventory:add_bound_color_picker(TR["Warn color (20%)"], "sb_inv_orange",
        function(value)
            settings_getter().widgets.inventory_space.color.orange = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.inventory_space.color.orange))
        end)
    inventory:add_bound_color_picker(TR["Warn color (10%)"], "sb_inv_red",
        function(value)
            settings_getter().widgets.inventory_space.color.red = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.inventory_space.color.red))
        end)

    local durability = ConfigContent(window, 3)
    durability:add_bound_color_picker(TR["Green color"], "sb_durability_green",
        function(value)
            settings_getter().widgets.equipment_wear.color.green = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.equipment_wear.color.green))
        end)
    durability:add_bound_color_picker(TR["Yellow color"], "sb_durability_yellow",
        function(value)
            settings_getter().widgets.equipment_wear.color.yellow = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.equipment_wear.color.yellow))
        end)
    durability:add_bound_color_picker(TR["Red color"], "sb_durability_red",
        function(value)
            settings_getter().widgets.equipment_wear.color.red = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().widgets.equipment_wear.color.red))
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Background"], "background", background)
    page:add_tab(TR["Font"], "font", font)
    page:add_tab(TR["Inventory"], "inventory", inventory)
    page:add_tab(TR["Equipment Wear"], "durability", durability)

    return page, font
end

local function _new_widgets_section(window, settings_getter)
    local time_format_labels = { TR["24-hour"], TR["AM/PM"] }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }

    local time = ConfigContent(window, 4)
    time:add_bound_line_edit(TR["Width"], "sb_time_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.time_local.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.time_local.width))
        end)
    time:break_line()
    time:add_bound_dropdown(TR["Time format"], "sb_time_format", time_format_labels, time_format_values,
        function(value)
            settings_getter().widgets.time_local.time_format = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.time_local.time_format)
        end)
    time:add_bound_dropdown(TR["Text alignment"], "sb_time_text_alignment", time.text_alignment_labels,
        time.text_alignment_values,
        function(value)
            settings_getter().widgets.time_local.text_alignment = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.time_local.text_alignment)
        end)

    local inventory = ConfigContent(window, 4)
    inventory:add_bound_line_edit(TR["Width"], "sb_inv_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.inventory_space.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.inventory_space.width))
        end)
    inventory:break_line()
    inventory:add_bound_checkbox(TR["Icon"], "sb_inv_icon",
        function(value)
            settings_getter().widgets.inventory_space.icon = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().widgets.inventory_space.icon == true)
        end)
    inventory:add_bound_dropdown(TR["Text alignment"], "sb_inv_text_alignment", inventory.text_alignment_labels,
        inventory.text_alignment_values,
        function(value)
            settings_getter().widgets.inventory_space.text_alignment = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.inventory_space.text_alignment)
        end)

    local durability = ConfigContent(window, 4)
    durability:add_bound_line_edit(TR["Width"], "sb_durability_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.equipment_wear.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.equipment_wear.width))
        end)
    durability:break_line()
    durability:add_bound_checkbox(TR["Icon"], "sb_durability_icon",
        function(value)
            settings_getter().widgets.equipment_wear.icon = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().widgets.equipment_wear.icon == true)
        end)
    durability:add_bound_dropdown(TR["Text alignment"], "sb_durability_text_alignment", durability.text_alignment_labels,
        durability.text_alignment_values,
        function(value)
            settings_getter().widgets.equipment_wear.text_alignment = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.equipment_wear.text_alignment)
        end)
    durability:break_line()
    durability:add_bound_checkbox(TR["Enable rich-text coloring"], "sb_durability_coloring",
        function(value)
            settings_getter().widgets.equipment_wear.coloring = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().widgets.equipment_wear.coloring == true)
        end, true)

    local money = ConfigContent(window, 4)
    money:add_bound_line_edit(TR["Width"], "sb_money_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.money.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.money.width))
        end)
    money:break_line()
    money:add_bound_dropdown(TR["Text alignment"], "sb_money_text_alignment", money.text_alignment_labels,
        money.text_alignment_values,
        function(value)
            settings_getter().widgets.money.text_alignment = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.money.text_alignment)
        end)

    local wallet = ConfigContent(window, 4)
    wallet:add_bound_line_edit(TR["Width"], "sb_wallet_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.wallet.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.wallet.width))
        end)
    wallet:break_line()
    wallet:add_bound_dropdown(TR["Text alignment"], "sb_wallet_text_alignment", wallet.text_alignment_labels,
        wallet.text_alignment_values,
        function(value)
            settings_getter().widgets.wallet.text_alignment = value
        end,
        function(entry)
            entry:set_value(settings_getter().widgets.wallet.text_alignment)
        end)
    wallet:break_line()
    CreateStatusBarWalletSelector(wallet, "sb_wallet_items")
    local wallet_items = wallet.controls.sb_wallet_items
    local wallet_load = wallet.load
    local wallet_save = wallet.save
    function wallet:load()
        wallet_load(self)
        wallet_items:set_items(settings_getter().widgets.wallet.items)
    end
    function wallet:save()
        wallet_save(self)
        settings_getter().widgets.wallet.items = wallet_items:get_items()
    end

    local item = ConfigContent(window, 4)
    item:add_bound_line_edit(TR["Width"], "sb_item_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.item.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.item.width))
        end)

    local shortcuts = ConfigContent(window, 4)
    shortcuts:add_bound_line_edit(TR["Width"], "sb_shortcut_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.shortcut.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.shortcut.width))
        end)
    shortcuts:add_bound_line_edit(TR["Height"], "sb_shortcut_height",
        function(value)
            local height = tonumber(value)
            if height ~= nil then
                settings_getter().widgets.shortcut.height = height
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.shortcut.height))
        end)

    local craft_plan = ConfigContent(window, 4)
    craft_plan:add_bound_line_edit(TR["Width"], "sb_craft_plan_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().widgets.craft_plan.width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.craft_plan.width))
        end)
    craft_plan:add_bound_line_edit(TR["Max visible resources"], "sb_craft_plan_max_visible",
        function(value)
            local max_visible = tonumber(value)
            if max_visible ~= nil then
                settings_getter().widgets.craft_plan.max_visible = max_visible
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().widgets.craft_plan.max_visible))
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Time (local)"], "time", time)
    page:add_tab(TR["Inventory"], "inventory", inventory)
    page:add_tab(TR["Equipment Wear"], "durability", durability)
    page:add_tab(TR["Money"], "money", money)
    page:add_tab(TR["Wallet"], "wallet", wallet)
    page:add_tab(TR["Tracked Item"], "item", item)
    page:add_tab(TR["Shortcut Buttons"], "shortcuts", shortcuts)
    page:add_tab(TR["Crafting Plan"], "craft_plan", craft_plan)

    return page
end

StatusBarPage = class(ConfigTabs)

function StatusBarPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local settings_getter = function()
        return self._settings.status_bar
    end

    local general = ConfigContent(window, 4)
    general:add_bound_checkbox(TR["Enabled"], "sb_enabled",
        function(value)
            settings_getter().enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().enabled == true)
        end, true)
    self:add_tab(TR["General"], "general", general)

    local background = ConfigContent(window, 4)
    background:add_bound_line_edit(TR["Background opacity (0..1)"], "sb_bg_opacity",
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().bg.opacity = opacity
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().bg.opacity))
        end)
    self:add_tab(TR["Background"], "background", background)

    local font = ConfigContent(window, 4)
    font:add_bound_dropdown(TR["Font"], "sb_font_name", font.font_name_labels, font.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function(entry)
            entry:set_value(settings_getter().font.name)
        end)
    font:add_bound_line_edit(TR["Font size"], "sb_font_size",
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().font.size))
        end)
    font:add_bound_dropdown(TR["Font style"], "sb_font_style", font.font_style_labels, font.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function(entry)
            entry:set_value(settings_getter().font.style)
        end)
    self:add_tab(TR["Font"], "font", font)

    local layout_help = BuildStatusBarLayoutHelp()
    local layout = ConfigContent(window, 4)
    layout:add_bound_line_edit(TR["Height"], "sb_height",
        function(value)
            local height = tonumber(value)
            if height ~= nil then
                settings_getter().height = height
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().height))
        end)
    layout:break_line()
    layout:add_bound_line_edit(TR["Left layout"], "sb_layout_left",
        function(value)
            settings_getter().layout.left = value
        end,
        function(entry)
            entry.tb:SetText(settings_getter().layout.left)
        end, layout_help, true)
    layout:break_line()
    layout:add_bound_line_edit(TR["Center layout"], "sb_layout_center",
        function(value)
            settings_getter().layout.center = value
        end,
        function(entry)
            entry.tb:SetText(settings_getter().layout.center)
        end, layout_help, true)
    layout:break_line()
    layout:add_bound_line_edit(TR["Right layout"], "sb_layout_right",
        function(value)
            settings_getter().layout.right = value
        end,
        function(entry)
            entry.tb:SetText(settings_getter().layout.right)
        end, layout_help, true)
    self:add_tab(TR["Layout"], "layout", layout)

    local colors, colors_font = _new_colors_section(window, settings_getter)
    self:add_tab(TR["Colors"], "colors", colors)
    self:add_tab(TR["Widgets"], "widgets", _new_widgets_section(window, settings_getter))

    _bind_outline_visibility(self, colors_font, "sb_font_style", "sb_font_outline_color")
    self:refresh_layout_help()
end

function StatusBarPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function StatusBarPage:refresh_layout_help()
    local help_text = BuildStatusBarLayoutHelp()
    local keys = { "sb_layout_left", "sb_layout_center", "sb_layout_right" }
    for i = 1, #keys do
        self.controls[keys[i]].help_text = help_text
    end
end

function StatusBarPage:load()
    self:refresh_layout_help()
    ConfigTabs.load(self)
end

_G.LUI_STATUS_BAR_REFRESH_LAYOUT_HELP = function()
    local window = _G.CONFIG_WINDOW
    if window == nil then
        return
    end
    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    page:refresh_layout_help()
end
