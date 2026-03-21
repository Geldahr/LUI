ExpiringTargetEffects = {
    key = "expiring_target_effects",
    text = TR("Expiring Effects (Target)"),
}

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

function ExpiringTargetEffects.create_controls(window, ui)
    ui.add_checkbox("expiring_target_effects_enabled", TR("Enable expiring effects window"), true)
    ui.add_checkbox("expiring_target_effects_show_buffs", TR("Track buffs"))
    ui.add_checkbox("expiring_target_effects_show_curable_debuffs", TR("Track curable debuffs"))
    ui.add_checkbox("expiring_target_effects_show_noncurable_debuffs", TR("Track non-curable debuffs"))
    ui.add_text("expiring_target_effects_threshold", TR("Show when less than seconds remaining"))
    ui.add_text("expiring_target_effects_columns", TR("Columns"))
    ui.add_text("expiring_target_effects_rows", TR("Rows"))
    ui.add_text("expiring_target_effects_bar_width", TR("Bar Width"))
    ui.add_text("expiring_target_effects_bar_height", TR("Bar Height"))
    ui.add_text("expiring_target_effects_border_width", TR("Border Width"))
    ui.add_text("expiring_target_effects_spacing", TR("Spacing"))

    ui.add_dropdown("expiring_target_effects_icon_side", TR("Icon position"), ui.side_labels, ui.side_values)
    ui.add_dropdown("expiring_target_effects_bar_expire_towards", TR("Bar expires towards"), ui.side_labels,
        ui.side_values)

    ui.add_text("expiring_target_effects_buff_bar_color", TR("Buff Bar Color"), true)
    ui.add_text("expiring_target_effects_bar_color", TR("Curable Debuff Bar Color"), true)
    ui.add_text("expiring_target_effects_debuff_noncurable_bar_color", TR("Non-curable Debuff Bar Color"), true)
    ui.add_text("expiring_target_effects_background_color", TR("Background Color"), true)
    ui.add_text("expiring_target_effects_border_color", TR("Border Color"), true)

    ui.add_text("expiring_target_effects_name_max_chars", TR("Max name characters"))

    local template_help = table.concat({
        TR("Text template tokens:"),
        TR("  %n = effect name"),
        TR("  %t = remaining time"),
        "",
        TR("You can use \\n for a new line."),
        TR("Example: %n  %t"),
    }, "\n")
    ui.add_text("expiring_target_effects_text_template", TR("Text template"), false, template_help, true)
    ui.add_dropdown("expiring_target_effects_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)

    ui.add_dropdown("expiring_target_effects_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("expiring_target_effects_font_size", TR("Font Size"))
    ui.add_text("expiring_target_effects_font_color", TR("Font Color"), true)
    ui.add_dropdown("expiring_target_effects_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("expiring_target_effects_font_outline_color", TR("Outline Color"), true)

    ui.add_custom("expiring_target_effects_preview", 71)
end

function ExpiringTargetEffects.register(window, ui)
    local function is_outline()
        local v = window.controls.expiring_target_effects_font_style:get_value()
        return v == LUI_ENUMS.font_style.OUTLINE
    end

    window.controls.expiring_target_effects_font_outline_color.visible_if = function() return is_outline() end
    -- Keep color options visible even when tracking toggles are off.

    local prev = window.controls.expiring_target_effects_font_style.on_changed
    window.controls.expiring_target_effects_font_style.on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        window:layout()
        if window.update_expiring_target_effects_preview ~= nil then
            window:update_expiring_target_effects_preview()
        end
    end

    return {
        ui.add_title(TR("Expiring Effects (Target)")),
        window.controls.expiring_target_effects_enabled,

        ui.add_hr(),
        ui.add_title(TR("Tracking")),
        window.controls.expiring_target_effects_show_buffs,
        ui.add_break(),
        window.controls.expiring_target_effects_show_curable_debuffs,
        window.controls.expiring_target_effects_show_noncurable_debuffs,
        ui.add_break(),
        ui.add_title(TR("Trigger")),
        window.controls.expiring_target_effects_threshold,

        ui.add_hr(),
        ui.add_title(TR("Layout")),
        window.controls.expiring_target_effects_columns,
        window.controls.expiring_target_effects_rows,
        ui.add_break(),
        window.controls.expiring_target_effects_bar_width,
        window.controls.expiring_target_effects_bar_height,
        window.controls.expiring_target_effects_border_width,
        window.controls.expiring_target_effects_spacing,
        ui.add_break(),
        window.controls.expiring_target_effects_icon_side,
        window.controls.expiring_target_effects_bar_expire_towards,

        ui.add_hr(),
        ui.add_title(TR("Style")),
        window.controls.expiring_target_effects_buff_bar_color,
        window.controls.expiring_target_effects_bar_color,
        window.controls.expiring_target_effects_debuff_noncurable_bar_color,
        window.controls.expiring_target_effects_background_color,
        window.controls.expiring_target_effects_border_color,
        ui.add_break(),
        window.controls.expiring_target_effects_name_max_chars,
        window.controls.expiring_target_effects_text_template,
        window.controls.expiring_target_effects_text_alignment,
        ui.add_break(),
        window.controls.expiring_target_effects_font_name,
        window.controls.expiring_target_effects_font_size,
        window.controls.expiring_target_effects_font_color,
        window.controls.expiring_target_effects_font_style,
        window.controls.expiring_target_effects_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Preview")),
        window.controls.expiring_target_effects_preview,
    }
end

function ExpiringTargetEffects.load(window, s, ui)
    local b = s.target.expiring_effects

    window.controls.expiring_target_effects_enabled.cb:SetChecked(b.enabled == true)
    window.controls.expiring_target_effects_show_buffs.cb:SetChecked(b.show_buffs == true)
    window.controls.expiring_target_effects_show_curable_debuffs.cb:SetChecked(b.show_curable_debuffs ~= false)
    window.controls.expiring_target_effects_show_noncurable_debuffs.cb:SetChecked(b.show_noncurable_debuffs ~= false)
    window.controls.expiring_target_effects_threshold.tb:SetText(tostring(b.threshold))

    window.controls.expiring_target_effects_columns.tb:SetText(tostring(b.columns))
    window.controls.expiring_target_effects_rows.tb:SetText(tostring(b.rows))
    window.controls.expiring_target_effects_bar_width.tb:SetText(tostring(b.bar_width))
    window.controls.expiring_target_effects_bar_height.tb:SetText(tostring(b.bar_height))
    window.controls.expiring_target_effects_border_width.tb:SetText(tostring(b.border_width))
    window.controls.expiring_target_effects_spacing.tb:SetText(tostring(b.spacing))

    window.controls.expiring_target_effects_icon_side:set_value(b.icon_side)
    window.controls.expiring_target_effects_bar_expire_towards:set_value(b.bar_expire_towards)

    window.controls.expiring_target_effects_bar_color.tb:SetText(ui.color_to_hex(b.color.bar_debuff_curable or
        b.color.bar))
    window.controls.expiring_target_effects_debuff_noncurable_bar_color.tb:SetText(ui.color_to_hex(b.color
        .bar_debuff_noncurable or b.color.bar))
    window.controls.expiring_target_effects_buff_bar_color.tb:SetText(ui.color_to_hex(b.color.bar_buff))
    window.controls.expiring_target_effects_background_color.tb:SetText(ui.color_to_hex(b.color.background))
    window.controls.expiring_target_effects_border_color.tb:SetText(ui.color_to_hex(b.color.border))

    window.controls.expiring_target_effects_name_max_chars.tb:SetText(tostring(b.name_max_chars))
    window.controls.expiring_target_effects_text_template.tb:SetText(tostring(b.text_template))
    window.controls.expiring_target_effects_text_alignment:set_value(b.text_alignment)

    window.controls.expiring_target_effects_font_name:set_value(b.font.name)
    window.controls.expiring_target_effects_font_size.tb:SetText(tostring(b.font.size))
    window.controls.expiring_target_effects_font_color.tb:SetText(ui.color_to_hex(b.font.color))
    window.controls.expiring_target_effects_font_style:set_value(b.font.style)
    window.controls.expiring_target_effects_font_outline_color.tb:SetText(ui.color_to_hex(b.font.outline_color))
end

function ExpiringTargetEffects.apply(window, s, ui)
    local b = s.target.expiring_effects

    b.enabled = window.controls.expiring_target_effects_enabled.cb:IsChecked()
    b.show_buffs = window.controls.expiring_target_effects_show_buffs.cb:IsChecked()
    b.show_curable_debuffs = window.controls.expiring_target_effects_show_curable_debuffs.cb:IsChecked()
    b.show_noncurable_debuffs = window.controls.expiring_target_effects_show_noncurable_debuffs.cb:IsChecked()

    local threshold = tonumber(window.controls.expiring_target_effects_threshold.tb:GetText())
    if threshold ~= nil then b.threshold = threshold end

    local cols = tonumber(window.controls.expiring_target_effects_columns.tb:GetText())
    if cols ~= nil then b.columns = cols end

    local rows = tonumber(window.controls.expiring_target_effects_rows.tb:GetText())
    if rows ~= nil then b.rows = rows end

    local bar_width = tonumber(window.controls.expiring_target_effects_bar_width.tb:GetText())
    if bar_width ~= nil then b.bar_width = bar_width end

    local bar_height = tonumber(window.controls.expiring_target_effects_bar_height.tb:GetText())
    if bar_height ~= nil then b.bar_height = bar_height end

    local border_width = tonumber(window.controls.expiring_target_effects_border_width.tb:GetText())
    if border_width ~= nil then b.border_width = border_width end

    local spacing = tonumber(window.controls.expiring_target_effects_spacing.tb:GetText())
    if spacing ~= nil then b.spacing = spacing end

    local icon_side = window.controls.expiring_target_effects_icon_side:get_value()
    if type(icon_side) == "number" then
        b.icon_side = icon_side
    end

    local bar_expire_towards = window.controls.expiring_target_effects_bar_expire_towards:get_value()
    if type(bar_expire_towards) == "number" then
        b.bar_expire_towards = bar_expire_towards
    end

    _apply_color(ui, b.color.bar_debuff_curable, window.controls.expiring_target_effects_bar_color.tb:GetText())
    _apply_color(ui, b.color.bar_debuff_noncurable,
        window.controls.expiring_target_effects_debuff_noncurable_bar_color.tb:GetText())
    -- Back-compat: keep `bar` as a fallback.
    if b.color.bar == nil then
        b.color.bar = b.color.bar_debuff_curable
    end
    _apply_color(ui, b.color.bar_buff, window.controls.expiring_target_effects_buff_bar_color.tb:GetText())
    _apply_color(ui, b.color.background, window.controls.expiring_target_effects_background_color.tb:GetText())
    _apply_color(ui, b.color.border, window.controls.expiring_target_effects_border_color.tb:GetText())

    local name_max_chars = tonumber(window.controls.expiring_target_effects_name_max_chars.tb:GetText())
    if name_max_chars ~= nil then
        b.name_max_chars = name_max_chars
    end

    local text_template = window.controls.expiring_target_effects_text_template.tb:GetText()
    if type(text_template) == "string" then
        b.text_template = text_template
    end
    local text_alignment = window.controls.expiring_target_effects_text_alignment:get_value()
    if type(text_alignment) == "number" then
        b.text_alignment = text_alignment
    end

    local font_name = window.controls.expiring_target_effects_font_name:get_value()
    if type(font_name) == "number" then
        b.font.name = font_name
    end
    local font_size = tonumber(window.controls.expiring_target_effects_font_size.tb:GetText())
    if font_size ~= nil then b.font.size = font_size end
    _apply_color(ui, b.font.color, window.controls.expiring_target_effects_font_color.tb:GetText())
    local font_style = window.controls.expiring_target_effects_font_style:get_value()
    if type(font_style) == "number" then
        b.font.style = font_style
    end
    _apply_color(ui, b.font.outline_color, window.controls.expiring_target_effects_font_outline_color.tb:GetText())
end
