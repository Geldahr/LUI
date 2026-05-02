import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_wallet_selector"
import "LUI.src.Settings.Tabs.StatusBar.status_bar_layout_help"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local CreateStatusBarWalletSelector = LUI.src.Settings.Tabs.StatusBar.CreateStatusBarWalletSelector or
    CreateStatusBarWalletSelector
local BuildStatusBarLayoutHelp = LUI.src.Settings.Tabs.StatusBar.BuildStatusBarLayoutHelp or
    BuildStatusBarLayoutHelp
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local configure_compact_form = FeatureShell.configure_compact_form
local add_compact_row_break = FeatureShell.add_compact_row_break
local module_for_page = FeatureShell.module_for_page

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

local function _new_general_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_checkbox("sb_enabled", TR["Enabled"], true)
    return page
end

local function _new_background_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_bg_opacity", TR["Background opacity (0..1)"])
    return page
end

local function _new_font_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_dropdown("sb_font_name", TR["Font"], page.font_name_labels, page.font_name_values)
    page:add_text("sb_font_size", TR["Font size"])
    page:add_dropdown("sb_font_style", TR["Font style"], page.font_style_labels, page.font_style_values)
    return page
end

local function _new_layout_page(window)
    local layout_help = BuildStatusBarLayoutHelp()
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_height", TR["Height"])
    add_compact_row_break(page)
    page:add_text("sb_layout_left", TR["Left layout"], false, layout_help, true)
    add_compact_row_break(page)
    page:add_text("sb_layout_center", TR["Center layout"], false, layout_help, true)
    add_compact_row_break(page)
    page:add_text("sb_layout_right", TR["Right layout"], false, layout_help, true)
    return page
end

local function _new_color_background_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 3, nil)
    page:add_text("sb_bg_color", TR["Background color"], true)
    return page
end

local function _new_color_font_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 3, nil)
    page:add_text("sb_font_color", TR["Font color"], true)
    page:add_text("sb_font_outline_color", TR["Outline color"], true)
    return page
end

local function _new_color_inventory_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 3, nil)
    page:add_text("sb_inv_yellow", TR["Warn color (30%)"], true)
    page:add_text("sb_inv_orange", TR["Warn color (20%)"], true)
    page:add_text("sb_inv_red", TR["Warn color (10%)"], true)
    return page
end

local function _new_color_durability_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 3, nil)
    page:add_text("sb_durability_green", TR["Green color"], true)
    page:add_text("sb_durability_yellow", TR["Yellow color"], true)
    page:add_text("sb_durability_red", TR["Red color"], true)
    return page
end

local function _new_colors_section(window)
    local background = _new_color_background_page(window)
    local font = _new_color_font_page(window)
    local inventory = _new_color_inventory_page(window)
    local durability = _new_color_durability_page(window)

    local page = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_sub_page(TR["Background"], module_for_page("background", background))
    page:add_sub_page(TR["Font"], module_for_page("font", font))
    page:add_sub_page(TR["Inventory"], module_for_page("inventory", inventory))
    page:add_sub_page(TR["Equipment Wear"], module_for_page("durability", durability))
    return page, font
end

local function _new_widget_time_page(window)
    local time_format_labels = { TR["24-hour"], TR["AM/PM"] }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }

    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_time_width", TR["Width"])
    page:add_dropdown("sb_time_format", TR["Time format"], time_format_labels, time_format_values)
    page:add_dropdown("sb_time_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    return page
end

local function _new_widget_inventory_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_inv_width", TR["Width"])
    page:add_checkbox("sb_inv_icon", TR["Icon"])
    page:add_dropdown("sb_inv_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    return page
end

local function _new_widget_durability_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_durability_width", TR["Width"])
    page:add_checkbox("sb_durability_icon", TR["Icon"])
    page:add_dropdown("sb_durability_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    add_compact_row_break(page)
    page:add_checkbox("sb_durability_coloring", TR["Enable rich-text coloring"], true)
    return page
end

local function _new_widget_money_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_money_width", TR["Width"])
    page:add_dropdown("sb_money_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    return page
end

local function _new_widget_wallet_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_wallet_width", TR["Width"])
    page:add_dropdown("sb_wallet_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    add_compact_row_break(page)
    CreateStatusBarWalletSelector(page, "sb_wallet_items")
    return page
end

local function _new_widget_item_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_item_width", TR["Width"])
    return page
end

local function _new_widget_shortcuts_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_shortcut_width", TR["Width"])
    page:add_text("sb_shortcut_height", TR["Height"])
    return page
end

local function _new_widget_crafting_plan_page(window)
    local page = configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_text("sb_craft_plan_width", TR["Width"])
    page:add_text("sb_craft_plan_max_visible", TR["Max visible resources"])
    return page
end

local function _new_widgets_section(window)
    local page = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_sub_page(TR["Time (local)"], module_for_page("time", _new_widget_time_page(window)))
    page:add_sub_page(TR["Inventory"], module_for_page("inventory", _new_widget_inventory_page(window)))
    page:add_sub_page(TR["Equipment Wear"], module_for_page("durability", _new_widget_durability_page(window)))
    page:add_sub_page(TR["Money"], module_for_page("money", _new_widget_money_page(window)))
    page:add_sub_page(TR["Wallet"], module_for_page("wallet", _new_widget_wallet_page(window)))
    page:add_sub_page(TR["Tracked Item"], module_for_page("item", _new_widget_item_page(window)))
    page:add_sub_page(TR["Shortcut Buttons"], module_for_page("shortcuts", _new_widget_shortcuts_page(window)))
    page:add_sub_page(TR["Crafting Plan"], module_for_page("craft_plan", _new_widget_crafting_plan_page(window)))
    return page
end

StatusBarPage = class(SettingsFeatureSectionPage)

function StatusBarPage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window)

    self:add_section(TR["General"], "general", _new_general_page(window))
    self:add_section(TR["Background"], "background", _new_background_page(window))
    self:add_section(TR["Font"], "font", _new_font_page(window))
    self:add_section(TR["Layout"], "layout", _new_layout_page(window))
    local colors, colors_font = _new_colors_section(window)
    self:add_section(TR["Colors"], "colors", colors)
    self:add_section(TR["Widgets"], "widgets", _new_widgets_section(window))
    _bind_outline_visibility(self, colors_font, "sb_font_style", "sb_font_outline_color")
    self:refresh_layout_help()
end

function StatusBarPage:refresh_layout_help()
    local help_text = BuildStatusBarLayoutHelp()
    local keys = { "sb_layout_left", "sb_layout_center", "sb_layout_right" }
    for i = 1, #keys do
        self.controls[keys[i]].help_text = help_text
    end
end

function StatusBarPage:load(sb)
    self.loading = true
    self:refresh_layout_help()

    self.controls.sb_enabled.cb:SetChecked(sb.enabled == true)
    self.controls.sb_bg_opacity.tb:SetText(tostring(sb.bg.opacity))
    self.controls.sb_bg_color.tb:SetText(self.color_to_hex(sb.bg.color))

    self.controls.sb_font_name:set_value(sb.font.name)
    self.controls.sb_font_size.tb:SetText(tostring(sb.font.size))
    self.controls.sb_font_color.tb:SetText(self.color_to_hex(sb.font.color))
    self.controls.sb_font_style:set_value(sb.font.style)
    self.controls.sb_font_outline_color.tb:SetText(self.color_to_hex(sb.font.outline_color))

    self.controls.sb_height.tb:SetText(tostring(sb.height))

    local widgets = sb.widgets

    self.controls.sb_layout_left.tb:SetText(tostring(sb.layout.left or ""))
    self.controls.sb_layout_center.tb:SetText(tostring(sb.layout.center or ""))
    self.controls.sb_layout_right.tb:SetText(tostring(sb.layout.right or ""))

    local time = widgets.time_local
    self.controls.sb_time_width.tb:SetText(tostring(time.width))
    self.controls.sb_time_format:set_value(time.time_format)
    self.controls.sb_time_text_alignment:set_value(time.text_alignment)

    local inv = widgets.inventory_space
    self.controls.sb_inv_width.tb:SetText(tostring(inv.width))
    self.controls.sb_inv_icon.cb:SetChecked(inv.icon == true)
    self.controls.sb_inv_text_alignment:set_value(inv.text_alignment)
    self.controls.sb_inv_yellow.tb:SetText(self.color_to_hex(inv.color.yellow))
    self.controls.sb_inv_orange.tb:SetText(self.color_to_hex(inv.color.orange))
    self.controls.sb_inv_red.tb:SetText(self.color_to_hex(inv.color.red))

    local wear = widgets.equipment_wear
    self.controls.sb_durability_width.tb:SetText(tostring(wear.width))
    self.controls.sb_durability_icon.cb:SetChecked(wear.icon == true)
    self.controls.sb_durability_text_alignment:set_value(wear.text_alignment)
    self.controls.sb_durability_coloring.cb:SetChecked(wear.coloring == true)
    self.controls.sb_durability_green.tb:SetText(self.color_to_hex(wear.color.green))
    self.controls.sb_durability_yellow.tb:SetText(self.color_to_hex(wear.color.yellow))
    self.controls.sb_durability_red.tb:SetText(self.color_to_hex(wear.color.red))

    local money = widgets.money
    self.controls.sb_money_width.tb:SetText(tostring(money.width))
    self.controls.sb_money_text_alignment:set_value(money.text_alignment)

    local wallet = widgets.wallet
    self.controls.sb_wallet_width.tb:SetText(tostring(wallet.width))
    self.controls.sb_wallet_text_alignment:set_value(wallet.text_alignment)
    self.controls.sb_wallet_items:set_items(wallet.items)

    self.controls.sb_item_width.tb:SetText(tostring(widgets.item.width))

    self.controls.sb_shortcut_width.tb:SetText(tostring(widgets.shortcut.width))
    self.controls.sb_shortcut_height.tb:SetText(tostring(widgets.shortcut.height))
    self.controls.sb_craft_plan_width.tb:SetText(tostring(widgets.craft_plan.width))
    self.controls.sb_craft_plan_max_visible.tb:SetText(tostring(widgets.craft_plan.max_visible))

    self:update_all_swatches()
    self.loading = false
    self:layout()
end

function StatusBarPage:apply(sb)
    sb.enabled = self.controls.sb_enabled.cb:IsChecked() == true

    local bg_opacity = tonumber(self.controls.sb_bg_opacity.tb:GetText())
    if bg_opacity ~= nil then sb.bg.opacity = bg_opacity end
    local bg_color = self.hex_to_color(self.controls.sb_bg_color.tb:GetText())
    if bg_color ~= nil then sb.bg.color = bg_color end

    sb.font.name = self.controls.sb_font_name:get_value()
    local font_size = tonumber(self.controls.sb_font_size.tb:GetText())
    if font_size ~= nil then sb.font.size = font_size end
    local font_color = self.hex_to_color(self.controls.sb_font_color.tb:GetText())
    if font_color ~= nil then sb.font.color = font_color end
    sb.font.style = self.controls.sb_font_style:get_value()
    local outline_color = self.hex_to_color(self.controls.sb_font_outline_color.tb:GetText())
    if outline_color ~= nil then sb.font.outline_color = outline_color end

    local height = tonumber(self.controls.sb_height.tb:GetText())
    if height ~= nil then sb.height = height end

    sb.layout.left = self.controls.sb_layout_left.tb:GetText() or ""
    sb.layout.center = self.controls.sb_layout_center.tb:GetText() or ""
    sb.layout.right = self.controls.sb_layout_right.tb:GetText() or ""

    local widgets = sb.widgets

    local time_w = tonumber(self.controls.sb_time_width.tb:GetText())
    if time_w ~= nil then widgets.time_local.width = time_w end
    widgets.time_local.time_format = self.controls.sb_time_format:get_value()
    widgets.time_local.text_alignment = self.controls.sb_time_text_alignment:get_value()

    local inv_w = tonumber(self.controls.sb_inv_width.tb:GetText())
    if inv_w ~= nil then widgets.inventory_space.width = inv_w end
    widgets.inventory_space.icon = self.controls.sb_inv_icon.cb:IsChecked() == true
    widgets.inventory_space.text_alignment = self.controls.sb_inv_text_alignment:get_value()
    local inv_y = self.hex_to_color(self.controls.sb_inv_yellow.tb:GetText())
    if inv_y ~= nil then widgets.inventory_space.color.yellow = inv_y end
    local inv_o = self.hex_to_color(self.controls.sb_inv_orange.tb:GetText())
    if inv_o ~= nil then widgets.inventory_space.color.orange = inv_o end
    local inv_r = self.hex_to_color(self.controls.sb_inv_red.tb:GetText())
    if inv_r ~= nil then widgets.inventory_space.color.red = inv_r end

    local wear_w = tonumber(self.controls.sb_durability_width.tb:GetText())
    if wear_w ~= nil then widgets.equipment_wear.width = wear_w end
    widgets.equipment_wear.icon = self.controls.sb_durability_icon.cb:IsChecked() == true
    widgets.equipment_wear.text_alignment = self.controls.sb_durability_text_alignment:get_value()
    widgets.equipment_wear.coloring = self.controls.sb_durability_coloring.cb:IsChecked() == true
    local wear_green = self.hex_to_color(self.controls.sb_durability_green.tb:GetText())
    if wear_green ~= nil then widgets.equipment_wear.color.green = wear_green end
    local wear_yellow = self.hex_to_color(self.controls.sb_durability_yellow.tb:GetText())
    if wear_yellow ~= nil then widgets.equipment_wear.color.yellow = wear_yellow end
    local wear_red = self.hex_to_color(self.controls.sb_durability_red.tb:GetText())
    if wear_red ~= nil then widgets.equipment_wear.color.red = wear_red end

    local money_w = tonumber(self.controls.sb_money_width.tb:GetText())
    if money_w ~= nil then widgets.money.width = money_w end
    widgets.money.text_alignment = self.controls.sb_money_text_alignment:get_value()

    local wallet_w = tonumber(self.controls.sb_wallet_width.tb:GetText())
    if wallet_w ~= nil then widgets.wallet.width = wallet_w end
    widgets.wallet.text_alignment = self.controls.sb_wallet_text_alignment:get_value()
    widgets.wallet.items = self.controls.sb_wallet_items:get_items()

    local item_w = tonumber(self.controls.sb_item_width.tb:GetText())
    if item_w ~= nil then widgets.item.width = item_w end

    local shortcut_w = tonumber(self.controls.sb_shortcut_width.tb:GetText())
    if shortcut_w ~= nil then widgets.shortcut.width = shortcut_w end
    local shortcut_h = tonumber(self.controls.sb_shortcut_height.tb:GetText())
    if shortcut_h ~= nil then widgets.shortcut.height = shortcut_h end

    local craft_plan_w = tonumber(self.controls.sb_craft_plan_width.tb:GetText())
    if craft_plan_w ~= nil then widgets.craft_plan.width = craft_plan_w end
    local craft_plan_max_visible = tonumber(self.controls.sb_craft_plan_max_visible.tb:GetText())
    if craft_plan_max_visible ~= nil then widgets.craft_plan.max_visible = craft_plan_max_visible end
end

function StatusBarPage:load_from_settings(s)
    self:load(s.status_bar)
end

function StatusBarPage:apply_to_settings(s)
    self:apply(s.status_bar)
end

_G.LUI_STATUS_BAR_REFRESH_LAYOUT_HELP = function()
    local window = _G.CONFIG_WINDOW
    if window == nil or window.main_tab_bar == nil then
        return
    end
    local _, page = window.main_tab_bar:find_index(function(_, candidate)
        return candidate ~= nil and candidate._tab_key == "status_bar"
    end)
    if page ~= nil and page.refresh_layout_help ~= nil then
        page:refresh_layout_help()
    end
end
