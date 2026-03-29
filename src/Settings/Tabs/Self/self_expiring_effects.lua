import "LUI.src.Settings.Tabs.Self.self_expiring_effects_page"

SelfExpiringEffects = {
    key = "expiring_effects",
    text = TR("Expiring Effects"),
}

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

function SelfExpiringEffects.create_page(window)
    return SelfExpiringEffectsPage(window)
end

function SelfExpiringEffects.load(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local b = s.self.expiring_effects

    page.loading = true
    controls.expiring_effects_enabled.cb:SetChecked(b.enabled == true)
    controls.expiring_effects_show_buffs.cb:SetChecked(b.show_buffs ~= false)
    controls.expiring_effects_show_curable_debuffs.cb:SetChecked(b.show_curable_debuffs ~= false)
    controls.expiring_effects_show_noncurable_debuffs.cb:SetChecked(b.show_noncurable_debuffs ~= false)
    controls.expiring_effects_threshold.tb:SetText(tostring(b.threshold))

    controls.expiring_effects_columns.tb:SetText(tostring(b.columns))
    controls.expiring_effects_rows.tb:SetText(tostring(b.rows))
    controls.expiring_effects_bar_width.tb:SetText(tostring(b.bar_width))
    controls.expiring_effects_bar_height.tb:SetText(tostring(b.bar_height))
    controls.expiring_effects_border_width.tb:SetText(tostring(b.border_width))
    controls.expiring_effects_spacing.tb:SetText(tostring(b.spacing))

    controls.expiring_effects_icon_side:set_value(b.icon_side)
    controls.expiring_effects_bar_expire_towards:set_value(b.bar_expire_towards)

    controls.expiring_effects_bar_color.tb:SetText(ui.color_to_hex(b.color.bar_buff or b.color.bar))
    controls.expiring_effects_debuff_curable_bar_color.tb:SetText(ui.color_to_hex(b.color.bar_debuff_curable or
        b.color.bar))
    controls.expiring_effects_debuff_noncurable_bar_color.tb:SetText(ui.color_to_hex(b.color.bar_debuff_noncurable or
        b.color.bar))
    controls.expiring_effects_background_color.tb:SetText(ui.color_to_hex(b.color.background))
    controls.expiring_effects_border_color.tb:SetText(ui.color_to_hex(b.color.border))

    controls.expiring_effects_name_max_chars.tb:SetText(tostring(b.name_max_chars))
    controls.expiring_effects_text_template.tb:SetText(tostring(b.text_template))
    controls.expiring_effects_text_alignment:set_value(b.text_alignment)

    controls.expiring_effects_font_name:set_value(b.font.name)
    controls.expiring_effects_font_size.tb:SetText(tostring(b.font.size))
    controls.expiring_effects_font_color.tb:SetText(ui.color_to_hex(b.font.color))
    controls.expiring_effects_font_style:set_value(b.font.style)
    controls.expiring_effects_font_outline_color.tb:SetText(ui.color_to_hex(b.font.outline_color))
    page.loading = false
    page:layout()
end

function SelfExpiringEffects.apply(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local b = s.self.expiring_effects

    b.enabled = controls.expiring_effects_enabled.cb:IsChecked()
    b.show_buffs = controls.expiring_effects_show_buffs.cb:IsChecked()
    b.show_curable_debuffs = controls.expiring_effects_show_curable_debuffs.cb:IsChecked()
    b.show_noncurable_debuffs = controls.expiring_effects_show_noncurable_debuffs.cb:IsChecked()

    local threshold = tonumber(controls.expiring_effects_threshold.tb:GetText())
    if threshold ~= nil then
        b.threshold = threshold
    end

    local cols = tonumber(controls.expiring_effects_columns.tb:GetText())
    if cols ~= nil then
        b.columns = cols
    end

    local rows = tonumber(controls.expiring_effects_rows.tb:GetText())
    if rows ~= nil then
        b.rows = rows
    end

    local bar_width = tonumber(controls.expiring_effects_bar_width.tb:GetText())
    if bar_width ~= nil then
        b.bar_width = bar_width
    end

    local bar_height = tonumber(controls.expiring_effects_bar_height.tb:GetText())
    if bar_height ~= nil then
        b.bar_height = bar_height
    end

    local border_width = tonumber(controls.expiring_effects_border_width.tb:GetText())
    if border_width ~= nil then
        b.border_width = border_width
    end

    local spacing = tonumber(controls.expiring_effects_spacing.tb:GetText())
    if spacing ~= nil then
        b.spacing = spacing
    end

    local icon_side = controls.expiring_effects_icon_side:get_value()
    if type(icon_side) == "number" then
        b.icon_side = icon_side
    end

    local bar_expire_towards = controls.expiring_effects_bar_expire_towards:get_value()
    if type(bar_expire_towards) == "number" then
        b.bar_expire_towards = bar_expire_towards
    end

    _apply_color(ui, b.color.bar_buff, controls.expiring_effects_bar_color.tb:GetText())
    _apply_color(ui, b.color.bar_debuff_curable, controls.expiring_effects_debuff_curable_bar_color.tb:GetText())
    _apply_color(ui, b.color.bar_debuff_noncurable, controls.expiring_effects_debuff_noncurable_bar_color.tb:GetText())
    if b.color.bar == nil then
        b.color.bar = b.color.bar_buff
    end
    _apply_color(ui, b.color.background, controls.expiring_effects_background_color.tb:GetText())
    _apply_color(ui, b.color.border, controls.expiring_effects_border_color.tb:GetText())

    local name_max_chars = tonumber(controls.expiring_effects_name_max_chars.tb:GetText())
    if name_max_chars ~= nil then
        b.name_max_chars = name_max_chars
    end

    local text_template = controls.expiring_effects_text_template.tb:GetText()
    if type(text_template) == "string" then
        b.text_template = text_template
    end
    local text_alignment = controls.expiring_effects_text_alignment:get_value()
    if type(text_alignment) == "number" then
        b.text_alignment = text_alignment
    end

    local font_name = controls.expiring_effects_font_name:get_value()
    if type(font_name) == "number" then
        b.font.name = font_name
    end
    local font_size = tonumber(controls.expiring_effects_font_size.tb:GetText())
    if font_size ~= nil then
        b.font.size = font_size
    end
    _apply_color(ui, b.font.color, controls.expiring_effects_font_color.tb:GetText())
    local font_style = controls.expiring_effects_font_style:get_value()
    if type(font_style) == "number" then
        b.font.style = font_style
    end
    _apply_color(ui, b.font.outline_color, controls.expiring_effects_font_outline_color.tb:GetText())
end
