StatusBar = {
    key = "status_bar",
    text = TR("Status Bar"),
}

local function _is_outline(control)
    local v = control:get_value()
    return v == LUI_ENUMS.font_style.OUTLINE
end

function StatusBar.create_controls(window, ui)
    ui.add_checkbox("sb_enabled", TR("Enabled"), true)

    ui.add_text("sb_bg_opacity", TR("Background opacity (0..1)"))
    ui.add_text("sb_bg_color", TR("Background color"), true)

    ui.add_dropdown("sb_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("sb_font_size", TR("Font size"))
    ui.add_text("sb_font_color", TR("Font color"), true)
    ui.add_dropdown("sb_font_style", TR("Font style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("sb_font_outline_color", TR("Outline color"), true)

    ui.add_text("sb_height", TR("Height"))

    local layout_help = table.concat({
        TR("Tokens:"),
        TR("  %time% - local time (HH:MM)"),
        TR("  %inventory% - backpack used/total"),
        TR("  %gold% / %money% - money (g/s/c)"),
        "",
        TR("Order matters. Unknown tokens are ignored."),
        TR("Example: %time% %inventory%"),
    }, "\n")

    ui.add_text("sb_layout_left", TR("Left layout"), false, layout_help, true)
    ui.add_text("sb_layout_center", TR("Center layout"), false, layout_help, true)
    ui.add_text("sb_layout_right", TR("Right layout"), false, layout_help, true)

    ui.add_text("sb_time_width", TR("Width"))
    ui.add_checkbox("sb_time_icon", TR("Icon"))
    ui.add_dropdown("sb_time_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)

    ui.add_text("sb_inv_width", TR("Width"))
    ui.add_checkbox("sb_inv_icon", TR("Icon"))
    ui.add_dropdown("sb_inv_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
    ui.add_text("sb_inv_yellow", TR("Warn color (30%)"), true)
    ui.add_text("sb_inv_orange", TR("Warn color (20%)"), true)
    ui.add_text("sb_inv_red", TR("Warn color (10%)"), true)

    ui.add_text("sb_money_width", TR("Width"))
    ui.add_checkbox("sb_money_icon", TR("Icon"))
    ui.add_dropdown("sb_money_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
end

function StatusBar.register(window, ui)
    window.controls.sb_font_outline_color.visible_if = function() return _is_outline(window.controls.sb_font_style) end

    return {
        ui.add_title(TR("Status Bar")),

        ui.add_hr(),
        ui.add_title(TR("General")),
        window.controls.sb_enabled,

        ui.add_hr(),
        ui.add_title(TR("Background")),
        window.controls.sb_bg_opacity,
        window.controls.sb_bg_color,

        ui.add_hr(),
        ui.add_title(TR("Font")),
        window.controls.sb_font_name,
        window.controls.sb_font_size,
        window.controls.sb_font_color,
        window.controls.sb_font_style,
        window.controls.sb_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Layout")),
        window.controls.sb_height,

        ui.add_hr(),
        ui.add_title(TR("Widgets order")),
        window.controls.sb_layout_left,
        window.controls.sb_layout_center,
        window.controls.sb_layout_right,

        ui.add_hr(),
        ui.add_title(TR("Widgets")),

        ui.add_hr(),
        ui.add_title(TR("Time (local)")),
        window.controls.sb_time_width,
        window.controls.sb_time_icon,
        window.controls.sb_time_text_alignment,

        ui.add_hr(),
        ui.add_title(TR("Inventory space")),
        window.controls.sb_inv_width,
        window.controls.sb_inv_icon,
        window.controls.sb_inv_text_alignment,
        window.controls.sb_inv_yellow,
        window.controls.sb_inv_orange,
        window.controls.sb_inv_red,

        ui.add_hr(),
        ui.add_title(TR("Money")),
        window.controls.sb_money_width,
        window.controls.sb_money_icon,
        window.controls.sb_money_text_alignment,
    }
end

function StatusBar.load(window, s, ui)
    local sb = s.status_bar

    window.controls.sb_enabled.cb:SetChecked(sb.enabled == true)
    window.controls.sb_bg_opacity.tb:SetText(tostring(sb.bg.opacity))
    window.controls.sb_bg_color.tb:SetText(ui.color_to_hex(sb.bg.color))

    window.controls.sb_font_name:set_value(sb.font.name)
    window.controls.sb_font_size.tb:SetText(tostring(sb.font.size))
    window.controls.sb_font_color.tb:SetText(ui.color_to_hex(sb.font.color))
    window.controls.sb_font_style:set_value(sb.font.style)
    window.controls.sb_font_outline_color.tb:SetText(ui.color_to_hex(sb.font.outline_color))

    window.controls.sb_height.tb:SetText(tostring(sb.height))

    local widgets = sb.widgets

    window.controls.sb_layout_left.tb:SetText(tostring(sb.layout.left or ""))
    window.controls.sb_layout_center.tb:SetText(tostring(sb.layout.center or ""))
    window.controls.sb_layout_right.tb:SetText(tostring(sb.layout.right or ""))

    local time = widgets.time_local
    window.controls.sb_time_width.tb:SetText(tostring(time.width))
    window.controls.sb_time_icon.cb:SetChecked(time.icon == true)
    window.controls.sb_time_text_alignment:set_value(time.text_alignment)

    local inv = widgets.inventory_space
    window.controls.sb_inv_width.tb:SetText(tostring(inv.width))
    window.controls.sb_inv_icon.cb:SetChecked(inv.icon == true)
    window.controls.sb_inv_text_alignment:set_value(inv.text_alignment)
    window.controls.sb_inv_yellow.tb:SetText(ui.color_to_hex(inv.color.yellow))
    window.controls.sb_inv_orange.tb:SetText(ui.color_to_hex(inv.color.orange))
    window.controls.sb_inv_red.tb:SetText(ui.color_to_hex(inv.color.red))

    local money = widgets.money
    window.controls.sb_money_width.tb:SetText(tostring(money.width))
    window.controls.sb_money_icon.cb:SetChecked(money.icon == true)
    window.controls.sb_money_text_alignment:set_value(money.text_alignment)
end

function StatusBar.apply(window, s, ui)
    local sb = s.status_bar

    sb.enabled = window.controls.sb_enabled.cb:IsChecked() == true

    local bg_opacity = tonumber(window.controls.sb_bg_opacity.tb:GetText())
    if bg_opacity ~= nil then sb.bg.opacity = bg_opacity end
    local bg_color = ui.hex_to_color(window.controls.sb_bg_color.tb:GetText())
    if bg_color ~= nil then sb.bg.color = bg_color end

    sb.font.name = window.controls.sb_font_name:get_value()
    local font_size = tonumber(window.controls.sb_font_size.tb:GetText())
    if font_size ~= nil then sb.font.size = font_size end
    local font_color = ui.hex_to_color(window.controls.sb_font_color.tb:GetText())
    if font_color ~= nil then sb.font.color = font_color end
    sb.font.style = window.controls.sb_font_style:get_value()
    local outline_color = ui.hex_to_color(window.controls.sb_font_outline_color.tb:GetText())
    if outline_color ~= nil then sb.font.outline_color = outline_color end

    local height = tonumber(window.controls.sb_height.tb:GetText())
    if height ~= nil then sb.height = height end

    sb.layout.left = window.controls.sb_layout_left.tb:GetText() or ""
    sb.layout.center = window.controls.sb_layout_center.tb:GetText() or ""
    sb.layout.right = window.controls.sb_layout_right.tb:GetText() or ""

    local widgets = sb.widgets

    local time_w = tonumber(window.controls.sb_time_width.tb:GetText())
    if time_w ~= nil then widgets.time_local.width = time_w end
    widgets.time_local.icon = window.controls.sb_time_icon.cb:IsChecked() == true
    widgets.time_local.text_alignment = window.controls.sb_time_text_alignment:get_value()

    local inv_w = tonumber(window.controls.sb_inv_width.tb:GetText())
    if inv_w ~= nil then widgets.inventory_space.width = inv_w end
    widgets.inventory_space.icon = window.controls.sb_inv_icon.cb:IsChecked() == true
    widgets.inventory_space.text_alignment = window.controls.sb_inv_text_alignment:get_value()
    local inv_y = ui.hex_to_color(window.controls.sb_inv_yellow.tb:GetText())
    if inv_y ~= nil then widgets.inventory_space.color.yellow = inv_y end
    local inv_o = ui.hex_to_color(window.controls.sb_inv_orange.tb:GetText())
    if inv_o ~= nil then widgets.inventory_space.color.orange = inv_o end
    local inv_r = ui.hex_to_color(window.controls.sb_inv_red.tb:GetText())
    if inv_r ~= nil then widgets.inventory_space.color.red = inv_r end

    local money_w = tonumber(window.controls.sb_money_width.tb:GetText())
    if money_w ~= nil then widgets.money.width = money_w end
    widgets.money.icon = window.controls.sb_money_icon.cb:IsChecked() == true
    widgets.money.text_alignment = window.controls.sb_money_text_alignment:get_value()
end
