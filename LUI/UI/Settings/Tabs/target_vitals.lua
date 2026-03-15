TargetVitals = {
    key = "target_vitals",
    text = TR("Target Vitals"),
}

local function _is_outline(control)
    local v = control:get_value()
    return v == LUI_ENUMS.font_style.OUTLINE
end

local function _hook_layout_on_change(window, control)
    local prev = control.on_changed
    control.on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        window:layout()
    end
end

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

local STEP_COLORS_INFO = TR("Used when gradient colors are disabled. High, Medium, Low and Critical apply by thresholds.")
local GRADIENT_COLORS_INFO = TR("When enabled, this bypasses the step colors and blends between Full, Mid and Low.")

function TargetVitals.create_controls(window, ui)
    ui.add_text("target_width", TR("Frame Width"))
    ui.add_text("target_border_width", TR("Border Width"))
    ui.add_text("target_incombat_opacity", TR("In-combat opacity"))
    ui.add_text("target_outcombat_opacity", TR("Out-of-combat opacity"))
    ui.add_text("target_effects_height", TR("Effects Height"))
    ui.add_dropdown("target_effects_position", TR("Effects Position"), ui.vitals_effects_position_labels,
        ui.vitals_effects_position_values)

    ui.add_text("target_morale_height", TR("Bar Height"))
    ui.add_dropdown("target_morale_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("target_morale_font_size", TR("Font Size"))
    ui.add_text("target_morale_font_color", TR("Font Color"), true)
    ui.add_dropdown("target_morale_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("target_morale_font_outline_color", TR("Outline Color"), true)
    ui.add_text("target_morale_background_color", TR("Background Color"), true)
    ui.add_checkbox("target_ressource_background_matches_missing", TR("Background matches missing ressource"))
    ui.add_text("target_ressource_background_dimming", TR("Dimming"))
    ui.add_text("target_border_color", TR("Border Color"), true)
    ui.add_text("target_morale_bubble_color", TR("Bubble Color"), true)
    ui.add_text("target_morale_color_neutral", TR("Neutral Color"), true)
    ui.add_checkbox("target_morale_gradient", TR("Enable gradient colors"), true)
    ui.add_text("target_morale_gradient_full", TR("Full Color"), true)
    ui.add_text("target_morale_gradient_mid", TR("Mid Color"), true)
    ui.add_text("target_morale_gradient_low", TR("Low Color"), true)
    ui.add_custom("target_morale_gradient_preview", 30)
    ui.add_text("target_morale_color_high", TR("High Color"), true)
    ui.add_text("target_morale_color_medium", TR("Medium Color"), true)
    ui.add_text("target_morale_color_low", TR("Low Color"), true)
    ui.add_text("target_morale_color_critical", TR("Critical Color"), true)
    ui.add_text("target_morale_text", TR("Text"), false, ui.vital_format_help, true)
    ui.add_text("target_morale_bubble_text", TR("Bubble Format (%B)"), false, ui.bubble_format_help, true)
    ui.add_dropdown("target_morale_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)
    ui.add_text("target_morale_text_margin", TR("Text margin"))

    ui.add_text("target_power_height", TR("Bar Height"))
    ui.add_dropdown("target_power_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("target_power_font_size", TR("Font Size"))
    ui.add_text("target_power_font_color", TR("Font Color"), true)
    ui.add_dropdown("target_power_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("target_power_font_outline_color", TR("Outline Color"), true)
    ui.add_text("target_power_color", TR("Power Color"), true)
    ui.add_text("target_wrath_color", TR("Wrath Color"), true)
    ui.add_text("target_power_text", TR("Text"), false, ui.vital_format_help, true)
    ui.add_dropdown("target_power_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)
    ui.add_text("target_power_text_margin", TR("Text margin"))

    ui.add_text("target_buff_size", TR("Icon Size"))
    ui.add_dropdown("target_buff_timer_font_name", TR("Timer Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("target_buff_timer_font_size", TR("Timer Font Size"))
    ui.add_text("target_buff_timer_font_color", TR("Timer Font Color"), true)
    ui.add_dropdown("target_buff_timer_font_style", TR("Timer Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("target_buff_timer_font_outline_color", TR("Timer Outline Color"), true)

    ui.add_text("target_debuff_size", TR("Icon Size"))
    ui.add_checkbox("target_debuff_track_curable", TR("Track curable debuffs"))
    ui.add_checkbox("target_debuff_track_noncurable", TR("Track non-curable debuffs"))
    ui.add_dropdown("target_debuff_timer_font_name", TR("Timer Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("target_debuff_timer_font_size", TR("Timer Font Size"))
    ui.add_text("target_debuff_timer_font_color", TR("Timer Font Color"), true)
    ui.add_dropdown("target_debuff_timer_font_style", TR("Timer Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("target_debuff_timer_font_outline_color", TR("Timer Outline Color"), true)

    ui.add_custom("target_vitals_preview", 222)
end

function TargetVitals.register(window, ui)
    window.controls.target_morale_font_outline_color.visible_if = function()
        return _is_outline(window.controls
            .target_morale_font_style)
    end
    window.controls.target_power_font_outline_color.visible_if = function()
        return _is_outline(window.controls
            .target_power_font_style)
    end
    window.controls.target_buff_timer_font_outline_color.visible_if = function()
        return _is_outline(window.controls
            .target_buff_timer_font_style)
    end
    window.controls.target_debuff_timer_font_outline_color.visible_if = function()
        return _is_outline(window.controls
            .target_debuff_timer_font_style)
    end

    _hook_layout_on_change(window, window.controls.target_morale_font_style)
    _hook_layout_on_change(window, window.controls.target_power_font_style)
    _hook_layout_on_change(window, window.controls.target_buff_timer_font_style)
    _hook_layout_on_change(window, window.controls.target_debuff_timer_font_style)

    return {
        ui.add_title(TR("Target Vitals")),

        ui.add_hr(),
        ui.add_title(TR("Frame")),
        window.controls.target_width,
        window.controls.target_border_width,
        ui.add_break(),
        window.controls.target_incombat_opacity,
        window.controls.target_outcombat_opacity,
        window.controls.target_effects_height,
        window.controls.target_effects_position,
        ui.add_break(),
        window.controls.target_ressource_background_matches_missing,
        window.controls.target_ressource_background_dimming,

        ui.add_hr(),
        ui.add_title(TR("Morale")),
        window.controls.target_morale_height,
        ui.add_break(),
        window.controls.target_morale_font_name,
        window.controls.target_morale_font_size,
        window.controls.target_morale_font_color,
        window.controls.target_morale_font_style,
        window.controls.target_morale_font_outline_color,
        ui.add_break(),
        window.controls.target_morale_background_color,
        ui.add_break(),
        window.controls.target_border_color,
        window.controls.target_morale_bubble_color,
        ui.add_break(),
        window.controls.target_morale_color_neutral,
        ui.add_break(),
        ui.add_title(TR("Step Colors")),
        ui.add_info(STEP_COLORS_INFO),
        ui.add_break(),
        window.controls.target_morale_color_high,
        window.controls.target_morale_color_medium,
        window.controls.target_morale_color_low,
        window.controls.target_morale_color_critical,
        ui.add_break(),
        ui.add_title(TR("Gradient Colors")),
        ui.add_info(GRADIENT_COLORS_INFO),
        window.controls.target_morale_gradient,
        ui.add_break(),
        window.controls.target_morale_gradient_full,
        window.controls.target_morale_gradient_mid,
        window.controls.target_morale_gradient_low,
        window.controls.target_morale_gradient_preview,
        ui.add_break(),
        window.controls.target_morale_text,
        window.controls.target_morale_bubble_text,
        window.controls.target_morale_text_alignment,
        window.controls.target_morale_text_margin,

        ui.add_hr(),
        ui.add_title(TR("Power / Wrath")),
        window.controls.target_power_height,
        ui.add_break(),
        window.controls.target_power_font_name,
        window.controls.target_power_font_size,
        window.controls.target_power_font_color,
        window.controls.target_power_font_style,
        window.controls.target_power_font_outline_color,
        ui.add_break(),
        window.controls.target_power_color,
        window.controls.target_wrath_color,
        ui.add_break(),
        window.controls.target_power_text,
        window.controls.target_power_text_alignment,
        window.controls.target_power_text_margin,

        ui.add_hr(),
        ui.add_title(TR("Buffs")),
        ui.add_break(),
        window.controls.target_buff_size,
        ui.add_break(),
        window.controls.target_buff_timer_font_name,
        window.controls.target_buff_timer_font_size,
        window.controls.target_buff_timer_font_color,
        window.controls.target_buff_timer_font_style,
        window.controls.target_buff_timer_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Debuffs")),
        window.controls.target_debuff_track_curable,
        window.controls.target_debuff_track_noncurable,
        ui.add_break(),
        window.controls.target_debuff_size,
        ui.add_break(),
        window.controls.target_debuff_timer_font_name,
        window.controls.target_debuff_timer_font_size,
        window.controls.target_debuff_timer_font_color,
        window.controls.target_debuff_timer_font_style,
        window.controls.target_debuff_timer_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Preview")),
        window.controls.target_vitals_preview,
    }
end

function TargetVitals.load(window, s, ui)
    local v = s.target.vitals

    window.controls.target_width.tb:SetText(tostring(v.frame.width))
    window.controls.target_border_width.tb:SetText(tostring(v.frame.border_width))
    window.controls.target_incombat_opacity.tb:SetText(tostring(v.frame.incombat_opacity))
    window.controls.target_outcombat_opacity.tb:SetText(tostring(v.frame.outcombat_opacity))
    window.controls.target_effects_position:set_value(v.frame.effects_position)

    window.controls.target_morale_height.tb:SetText(tostring(v.morale.height))
    window.controls.target_morale_font_name:set_value(v.morale.font.name)
    window.controls.target_morale_font_size.tb:SetText(tostring(v.morale.font.size))
    window.controls.target_morale_font_color.tb:SetText(ui.color_to_hex(v.morale.font.color))
    window.controls.target_morale_font_style:set_value(v.morale.font.style)
    window.controls.target_morale_font_outline_color.tb:SetText(ui.color_to_hex(v.morale.font.outline_color))

    window.controls.target_morale_background_color.tb:SetText(ui.color_to_hex(v.morale.color.background))
    window.controls.target_ressource_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    window.controls.target_ressource_background_dimming.tb:SetText(tostring(v.background_dimming))
    window.controls.target_border_color.tb:SetText(ui.color_to_hex(v.frame.border_color))
    window.controls.target_morale_bubble_color.tb:SetText(ui.color_to_hex(v.morale.color.bubble))
    window.controls.target_morale_color_neutral.tb:SetText(ui.color_to_hex(v.morale.color.neutral))
    window.controls.target_morale_gradient.cb:SetChecked(v.morale.color.gradient == true)
    window.controls.target_morale_gradient_full.tb:SetText(ui.color_to_hex(v.morale.color.gradient_full))
    window.controls.target_morale_gradient_mid.tb:SetText(ui.color_to_hex(v.morale.color.gradient_mid))
    window.controls.target_morale_gradient_low.tb:SetText(ui.color_to_hex(v.morale.color.gradient_low))
    window.controls.target_morale_color_high.tb:SetText(ui.color_to_hex(v.morale.color.high))
    window.controls.target_morale_color_medium.tb:SetText(ui.color_to_hex(v.morale.color.medium))
    window.controls.target_morale_color_low.tb:SetText(ui.color_to_hex(v.morale.color.low))
    window.controls.target_morale_color_critical.tb:SetText(ui.color_to_hex(v.morale.color.critical))

    window.controls.target_morale_text.tb:SetText(tostring(v.morale.string_format))
    window.controls.target_morale_text_alignment:set_value(v.morale.text_alignment)
    window.controls.target_morale_bubble_text.tb:SetText(tostring(v.morale.bubble_format))
    window.controls.target_morale_text_margin.tb:SetText(tostring(v.morale.text_margin))

    window.controls.target_power_height.tb:SetText(tostring(v.power.height))
    window.controls.target_power_font_name:set_value(v.power.font.name)
    window.controls.target_power_font_size.tb:SetText(tostring(v.power.font.size))
    window.controls.target_power_font_color.tb:SetText(ui.color_to_hex(v.power.font.color))
    window.controls.target_power_font_style:set_value(v.power.font.style)
    window.controls.target_power_font_outline_color.tb:SetText(ui.color_to_hex(v.power.font.outline_color))

    window.controls.target_power_color.tb:SetText(ui.color_to_hex(v.power.color.power))
    window.controls.target_wrath_color.tb:SetText(ui.color_to_hex(v.power.color.wrath))
    window.controls.target_power_text.tb:SetText(tostring(v.power.string_format))
    window.controls.target_power_text_alignment:set_value(v.power.text_alignment)
    window.controls.target_power_text_margin.tb:SetText(tostring(v.power.text_margin))

    window.controls.target_buff_size.tb:SetText(tostring(v.effects.buffs.icon_size))
    window.controls.target_effects_height.tb:SetText(tostring(v.frame.effects_height))
    window.controls.target_buff_timer_font_name:set_value(v.effects.buffs.timer_font.name)
    window.controls.target_buff_timer_font_size.tb:SetText(tostring(v.effects.buffs.timer_font.size))
    window.controls.target_buff_timer_font_color.tb:SetText(ui.color_to_hex(v.effects.buffs.timer_font.color))
    window.controls.target_buff_timer_font_style:set_value(v.effects.buffs.timer_font.style)
    window.controls.target_buff_timer_font_outline_color.tb:SetText(ui.color_to_hex(v.effects.buffs.timer_font
        .outline_color))

    window.controls.target_debuff_size.tb:SetText(tostring(v.effects.debuffs.icon_size))
    window.controls.target_debuff_track_curable.cb:SetChecked(v.effects.debuffs.track_curable == true)
    window.controls.target_debuff_track_noncurable.cb:SetChecked(v.effects.debuffs.track_noncurable == true)
    window.controls.target_debuff_timer_font_name:set_value(v.effects.debuffs.timer_font.name)
    window.controls.target_debuff_timer_font_size.tb:SetText(tostring(v.effects.debuffs.timer_font.size))
    window.controls.target_debuff_timer_font_color.tb:SetText(ui.color_to_hex(v.effects.debuffs.timer_font.color))
    window.controls.target_debuff_timer_font_style:set_value(v.effects.debuffs.timer_font.style)
    window.controls.target_debuff_timer_font_outline_color.tb:SetText(ui.color_to_hex(v.effects.debuffs.timer_font
        .outline_color))
end

function TargetVitals.apply(window, s, ui)
    local v = s.target.vitals

    local w = tonumber(window.controls.target_width.tb:GetText())
    if w ~= nil then v.frame.width = w end

    local bw = tonumber(window.controls.target_border_width.tb:GetText())
    if bw ~= nil then v.frame.border_width = bw end

    local in_op = tonumber(window.controls.target_incombat_opacity.tb:GetText())
    if in_op ~= nil then v.frame.incombat_opacity = in_op end

    local out_op = tonumber(window.controls.target_outcombat_opacity.tb:GetText())
    if out_op ~= nil then v.frame.outcombat_opacity = out_op end

    local mh = tonumber(window.controls.target_morale_height.tb:GetText())
    if mh ~= nil then v.morale.height = mh end

    local morale_font_name = window.controls.target_morale_font_name:get_value()
    if type(morale_font_name) == "number" then
        v.morale.font.name = morale_font_name
    end
    local morale_font_size = tonumber(window.controls.target_morale_font_size.tb:GetText())
    if morale_font_size ~= nil then v.morale.font.size = morale_font_size end
    _apply_color(ui, v.morale.font.color, window.controls.target_morale_font_color.tb:GetText())
    local morale_font_style = window.controls.target_morale_font_style:get_value()
    if type(morale_font_style) == "number" then
        v.morale.font.style = morale_font_style
    end
    _apply_color(ui, v.morale.font.outline_color, window.controls.target_morale_font_outline_color.tb:GetText())

    _apply_color(ui, v.morale.color.background, window.controls.target_morale_background_color.tb:GetText())
    v.background_matches_missing = window.controls.target_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_background_dimming = tonumber(window.controls.target_ressource_background_dimming.tb:GetText())
    if ressource_background_dimming ~= nil then v.background_dimming = ressource_background_dimming end
    _apply_color(ui, v.frame.border_color, window.controls.target_border_color.tb:GetText())
    _apply_color(ui, v.morale.color.bubble, window.controls.target_morale_bubble_color.tb:GetText())
    _apply_color(ui, v.morale.color.neutral, window.controls.target_morale_color_neutral.tb:GetText())
    v.morale.color.gradient = window.controls.target_morale_gradient.cb:IsChecked() == true
    _apply_color(ui, v.morale.color.gradient_full, window.controls.target_morale_gradient_full.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_mid, window.controls.target_morale_gradient_mid.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_low, window.controls.target_morale_gradient_low.tb:GetText())
    _apply_color(ui, v.morale.color.high, window.controls.target_morale_color_high.tb:GetText())
    _apply_color(ui, v.morale.color.medium, window.controls.target_morale_color_medium.tb:GetText())
    _apply_color(ui, v.morale.color.low, window.controls.target_morale_color_low.tb:GetText())
    _apply_color(ui, v.morale.color.critical, window.controls.target_morale_color_critical.tb:GetText())

    local target_morale_text = window.controls.target_morale_text.tb:GetText()
    if type(target_morale_text) == "string" then v.morale.string_format = target_morale_text end
    local target_morale_text_alignment = window.controls.target_morale_text_alignment:get_value()
    if type(target_morale_text_alignment) == "number" then
        v.morale.text_alignment = target_morale_text_alignment
    end
    local target_morale_text_margin = tonumber(window.controls.target_morale_text_margin.tb:GetText())
    if target_morale_text_margin ~= nil then v.morale.text_margin = target_morale_text_margin end
    local target_bubble_text = window.controls.target_morale_bubble_text.tb:GetText()
    if type(target_bubble_text) == "string" then v.morale.bubble_format = target_bubble_text end

    local ph = tonumber(window.controls.target_power_height.tb:GetText())
    if ph ~= nil then v.power.height = ph end

    local power_font_name = window.controls.target_power_font_name:get_value()
    if type(power_font_name) == "number" then
        v.power.font.name = power_font_name
    end
    local power_font_size = tonumber(window.controls.target_power_font_size.tb:GetText())
    if power_font_size ~= nil then v.power.font.size = power_font_size end
    _apply_color(ui, v.power.font.color, window.controls.target_power_font_color.tb:GetText())
    local power_font_style = window.controls.target_power_font_style:get_value()
    if type(power_font_style) == "number" then
        v.power.font.style = power_font_style
    end
    _apply_color(ui, v.power.font.outline_color, window.controls.target_power_font_outline_color.tb:GetText())

    _apply_color(ui, v.power.color.power, window.controls.target_power_color.tb:GetText())
    _apply_color(ui, v.power.color.wrath, window.controls.target_wrath_color.tb:GetText())

    local target_power_text = window.controls.target_power_text.tb:GetText()
    if type(target_power_text) == "string" then v.power.string_format = target_power_text end
    local target_power_text_alignment = window.controls.target_power_text_alignment:get_value()
    if type(target_power_text_alignment) == "number" then
        v.power.text_alignment = target_power_text_alignment
    end
    local target_power_text_margin = tonumber(window.controls.target_power_text_margin.tb:GetText())
    if target_power_text_margin ~= nil then v.power.text_margin = target_power_text_margin end

    local effects_h = tonumber(window.controls.target_effects_height.tb:GetText())
    if effects_h ~= nil then v.frame.effects_height = effects_h end
    local effects_position = window.controls.target_effects_position:get_value()
    if type(effects_position) == "number" then
        v.frame.effects_position = effects_position
    end

    local buff_size = tonumber(window.controls.target_buff_size.tb:GetText())
    if buff_size ~= nil then v.effects.buffs.icon_size = buff_size end

    local buff_timer_font_name = window.controls.target_buff_timer_font_name:get_value()
    if type(buff_timer_font_name) == "number" then
        v.effects.buffs.timer_font.name = buff_timer_font_name
    end
    local buff_timer_font_size = tonumber(window.controls.target_buff_timer_font_size.tb:GetText())
    if buff_timer_font_size ~= nil then v.effects.buffs.timer_font.size = buff_timer_font_size end
    _apply_color(ui, v.effects.buffs.timer_font.color, window.controls.target_buff_timer_font_color.tb:GetText())
    local buff_timer_font_style = window.controls.target_buff_timer_font_style:get_value()
    if type(buff_timer_font_style) == "number" then
        v.effects.buffs.timer_font.style = buff_timer_font_style
    end
    _apply_color(ui, v.effects.buffs.timer_font.outline_color,
        window.controls.target_buff_timer_font_outline_color.tb:GetText())

    local debuff_size = tonumber(window.controls.target_debuff_size.tb:GetText())
    if debuff_size ~= nil then v.effects.debuffs.icon_size = debuff_size end
    v.effects.debuffs.track_curable = window.controls.target_debuff_track_curable.cb:IsChecked() == true
    v.effects.debuffs.track_noncurable = window.controls.target_debuff_track_noncurable.cb:IsChecked() == true

    local debuff_timer_font_name = window.controls.target_debuff_timer_font_name:get_value()
    if type(debuff_timer_font_name) == "number" then
        v.effects.debuffs.timer_font.name = debuff_timer_font_name
    end
    local debuff_timer_font_size = tonumber(window.controls.target_debuff_timer_font_size.tb:GetText())
    if debuff_timer_font_size ~= nil then v.effects.debuffs.timer_font.size = debuff_timer_font_size end
    _apply_color(ui, v.effects.debuffs.timer_font.color, window.controls.target_debuff_timer_font_color.tb:GetText())
    local debuff_timer_font_style = window.controls.target_debuff_timer_font_style:get_value()
    if type(debuff_timer_font_style) == "number" then
        v.effects.debuffs.timer_font.style = debuff_timer_font_style
    end
    _apply_color(ui, v.effects.debuffs.timer_font.outline_color,
        window.controls.target_debuff_timer_font_outline_color.tb:GetText())
end
