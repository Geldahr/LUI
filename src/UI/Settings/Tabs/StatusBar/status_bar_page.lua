import "LUI.src.UI.Settings.Tabs.form_page"
import "LUI.src.UI.Settings.Tabs.StatusBar.status_bar_wallet_selector"
import "LUI.src.UI.Settings.Tabs.StatusBar.status_bar_layout_help"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local CreateStatusBarWalletSelector = LUI.src.UI.Settings.Tabs.StatusBar.CreateStatusBarWalletSelector or
    CreateStatusBarWalletSelector
local BuildStatusBarLayoutHelp = LUI.src.UI.Settings.Tabs.StatusBar.BuildStatusBarLayoutHelp or
    BuildStatusBarLayoutHelp

StatusBarPage = class(SettingsFormPage)

function StatusBarPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    local time_format_labels = { TR("24-hour"), TR("AM/PM") }
    local time_format_values = { LUI_ENUMS.time_format.H24, LUI_ENUMS.time_format.AMPM }
    local layout_help = BuildStatusBarLayoutHelp()

    self:add_title(TR("Status Bar"))

    self:add_hr()
    self:add_title(TR("General"))
    self:add_checkbox("sb_enabled", TR("Enabled"), true)

    self:add_hr()
    self:add_title(TR("Background"))
    self:add_text("sb_bg_opacity", TR("Background opacity (0..1)"))
    self:add_text("sb_bg_color", TR("Background color"), true)

    self:add_hr()
    self:add_title(TR("Font"))
    self:add_dropdown("sb_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("sb_font_size", TR("Font size"))
    self:add_text("sb_font_color", TR("Font color"), true)
    self:add_dropdown("sb_font_style", TR("Font style"), self.font_style_labels, self.font_style_values)
    self:add_text("sb_font_outline_color", TR("Outline color"), true)

    self:add_hr()
    self:add_title(TR("Layout"))
    self:add_text("sb_height", TR("Height"))

    self:add_hr()
    self:add_title(TR("Widgets order"))
    self:add_text("sb_layout_left", TR("Left layout"), false, layout_help, true)
    self:add_text("sb_layout_center", TR("Center layout"), false, layout_help, true)
    self:add_text("sb_layout_right", TR("Right layout"), false, layout_help, true)

    self:add_hr()
    self:add_title(TR("Widgets"))

    self:add_hr()
    self:add_title(TR("Time (local)"))
    self:add_text("sb_time_width", TR("Width"))
    self:add_dropdown("sb_time_format", TR("Time format"), time_format_labels, time_format_values)
    self:add_dropdown("sb_time_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)

    self:add_hr()
    self:add_title(TR("Inventory space"))
    self:add_text("sb_inv_width", TR("Width"))
    self:add_checkbox("sb_inv_icon", TR("Icon"))
    self:add_dropdown("sb_inv_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    self:add_text("sb_inv_yellow", TR("Warn color (30%)"), true)
    self:add_text("sb_inv_orange", TR("Warn color (20%)"), true)
    self:add_text("sb_inv_red", TR("Warn color (10%)"), true)

    self:add_hr()
    self:add_title(TR("Equipment wear"))
    self:add_text("sb_durability_width", TR("Width"))
    self:add_checkbox("sb_durability_icon", TR("Icon"))
    self:add_dropdown("sb_durability_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    self:add_checkbox("sb_durability_coloring", TR("Enable rich-text coloring"), true)
    self:add_text("sb_durability_green", TR("Green color"), true)
    self:add_text("sb_durability_yellow", TR("Yellow color"), true)
    self:add_text("sb_durability_red", TR("Red color"), true)

    self:add_hr()
    self:add_title(TR("Money"))
    self:add_text("sb_money_width", TR("Width"))
    self:add_checkbox("sb_money_icon", TR("Icon"))
    self:add_dropdown("sb_money_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)

    self:add_hr()
    self:add_title(TR("Wallet"))
    self:add_text("sb_wallet_width", TR("Width"))
    self:add_dropdown("sb_wallet_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    CreateStatusBarWalletSelector(self, "sb_wallet_items")

    self:add_hr()
    self:add_title(TR("Tracked item"))
    self:add_text("sb_item_width", TR("Width"))

    self:add_hr()
    self:add_title(TR("Shortcut buttons"))
    self:add_text("sb_shortcut_width", TR("Width"))
    self:add_text("sb_shortcut_height", TR("Height"))

    self.controls.sb_font_outline_color.visible_if = function()
        return self.controls.sb_font_style:get_value() == LUI_ENUMS.font_style.OUTLINE
    end

    self:refresh_layout_help()
end

function StatusBarPage:refresh_layout_help()
    local help_text = BuildStatusBarLayoutHelp()
    local keys = { "sb_layout_left", "sb_layout_center", "sb_layout_right" }
    for i = 1, #keys do
        local entry = self.controls[keys[i]]
        if entry ~= nil then
            entry.help_text = help_text
        end
    end
end

function StatusBarPage:load(sb)
    if sb == nil then
        return
    end

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
    self.controls.sb_money_icon.cb:SetChecked(money.icon == true)
    self.controls.sb_money_text_alignment:set_value(money.text_alignment)

    local wallet = widgets.wallet
    self.controls.sb_wallet_width.tb:SetText(tostring(wallet.width))
    self.controls.sb_wallet_text_alignment:set_value(wallet.text_alignment)
    self.controls.sb_wallet_items:set_items(wallet.items)

    self.controls.sb_item_width.tb:SetText(tostring(widgets.item.width))

    self.controls.sb_shortcut_width.tb:SetText(tostring(widgets.shortcut.width))
    self.controls.sb_shortcut_height.tb:SetText(tostring(widgets.shortcut.height))

    self:update_all_swatches()
    self.loading = false
end

function StatusBarPage:apply(sb)
    if sb == nil then
        return
    end

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
    widgets.money.icon = self.controls.sb_money_icon.cb:IsChecked() == true
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
