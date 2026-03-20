PartyVitals = {
    key = "party_vitals",
    text = TR("Party Vitals"),
}

local function _is_outline(control)
    local v = control:get_value()
    return v == LUI_ENUMS.font_style.OUTLINE
end

local function _hook_layout_and_preview_on_change(window, control)
    local prev = control.on_changed
    control.on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        window:layout()
        if window.UpdatePartyVitalsPreview ~= nil then
            window:UpdatePartyVitalsPreview()
        end
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

function PartyVitals.create_controls(window, ui)
    ui.add_text("party_width", TR("Frame Width"))
    ui.add_text("party_border_width", TR("Border Width"))
    ui.add_text("party_incombat_opacity", TR("In-combat opacity"))
    ui.add_text("party_outcombat_opacity", TR("Out-of-combat opacity"))
    ui.add_checkbox("party_class_icon_enabled", TR("Show class icon"), true)
    ui.add_text("party_class_icon_size", TR("Icon Size"))
    ui.add_text("party_class_icon_x", TR("Icon X"))
    ui.add_text("party_class_icon_y", TR("Icon Y"))
    ui.add_checkbox("party_leader_icon_enabled", TR("Show leader icon"), true)
    ui.add_text("party_leader_icon_size", TR("Leader Icon Size"))
    ui.add_text("party_leader_icon_x", TR("Leader Icon X"))
    ui.add_text("party_leader_icon_y", TR("Leader Icon Y"))

    ui.add_text("party_morale_height", TR("Bar Height"))
    ui.add_dropdown("party_morale_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("party_morale_font_size", TR("Font Size"))
    ui.add_text("party_morale_font_color", TR("Font Color"), true)
    ui.add_dropdown("party_morale_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("party_morale_font_outline_color", TR("Outline Color"), true)
    ui.add_text("party_morale_background_color", TR("Background Color"), true)
    ui.add_checkbox("party_ressource_background_matches_missing", TR("Background matches missing ressource"))
    ui.add_text("party_ressource_background_dimming", TR("Dimming"))
    ui.add_text("party_border_color", TR("Border Color"), true)
    ui.add_text("party_morale_bubble_color", TR("Bubble Color"), true)
    ui.add_text("party_morale_color_neutral", TR("Neutral Color"), true)
    ui.add_checkbox("party_morale_gradient", TR("Enable gradient colors"), true)
    ui.add_text("party_morale_gradient_full", TR("Full Color"), true)
    ui.add_text("party_morale_gradient_mid", TR("Mid Color"), true)
    ui.add_text("party_morale_gradient_low", TR("Low Color"), true)
    ui.add_custom("party_morale_gradient_preview", 30)
    ui.add_text("party_morale_color_high", TR("High Color"), true)
    ui.add_text("party_morale_color_medium", TR("Medium Color"), true)
    ui.add_text("party_morale_color_low", TR("Low Color"), true)
    ui.add_text("party_morale_color_critical", TR("Critical Color"), true)
    ui.add_text("party_morale_text", TR("Text"), false, ui.vital_format_help, true)
    ui.add_text("party_morale_bubble_text", TR("Bubble Format (%B)"), false, ui.bubble_format_help, true)
    ui.add_dropdown("party_morale_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)
    ui.add_text("party_morale_text_margin", TR("Text margin"))

    ui.add_text("party_power_height", TR("Bar Height"))
    ui.add_dropdown("party_power_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("party_power_font_size", TR("Font Size"))
    ui.add_text("party_power_font_color", TR("Font Color"), true)
    ui.add_dropdown("party_power_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("party_power_font_outline_color", TR("Outline Color"), true)
    ui.add_text("party_power_color", TR("Power Color"), true)
    ui.add_text("party_wrath_color", TR("Wrath Color"), true)
    ui.add_text("party_power_text", TR("Text"), false, ui.vital_format_help, true)
    ui.add_dropdown("party_power_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)
    ui.add_text("party_power_text_margin", TR("Text margin"))

    ui.add_custom("party_vitals_preview", 178)
end

function PartyVitals.register(window, ui)
    window.controls.party_morale_font_outline_color.visible_if = function()
        return _is_outline(window.controls.party_morale_font_style)
    end
    window.controls.party_power_font_outline_color.visible_if = function()
        return _is_outline(window.controls.party_power_font_style)
    end

    _hook_layout_and_preview_on_change(window, window.controls.party_morale_font_style)
    _hook_layout_and_preview_on_change(window, window.controls.party_power_font_style)

    return {
        ui.add_title(TR("Party Vitals")),

        ui.add_hr(),
        ui.add_title(TR("Frame")),
        window.controls.party_width,
        window.controls.party_border_width,
        ui.add_break(),
        window.controls.party_incombat_opacity,
        window.controls.party_outcombat_opacity,
        ui.add_break(),
        window.controls.party_ressource_background_matches_missing,
        window.controls.party_ressource_background_dimming,

        ui.add_hr(),
        ui.add_title(TR("Morale")),
        window.controls.party_morale_height,
        ui.add_break(),
        window.controls.party_morale_font_name,
        window.controls.party_morale_font_size,
        window.controls.party_morale_font_color,
        window.controls.party_morale_font_style,
        window.controls.party_morale_font_outline_color,
        ui.add_break(),
        window.controls.party_morale_background_color,
        ui.add_break(),
        window.controls.party_border_color,
        window.controls.party_morale_bubble_color,
        ui.add_break(),
        window.controls.party_morale_color_neutral,
        ui.add_break(),
        ui.add_title(TR("Step Colors")),
        ui.add_info(STEP_COLORS_INFO),
        ui.add_break(),
        window.controls.party_morale_color_high,
        window.controls.party_morale_color_medium,
        window.controls.party_morale_color_low,
        window.controls.party_morale_color_critical,
        ui.add_break(),
        ui.add_title(TR("Gradient Colors")),
        ui.add_info(GRADIENT_COLORS_INFO),
        window.controls.party_morale_gradient,
        ui.add_break(),
        window.controls.party_morale_gradient_full,
        window.controls.party_morale_gradient_mid,
        window.controls.party_morale_gradient_low,
        window.controls.party_morale_gradient_preview,
        ui.add_break(),
        window.controls.party_morale_text,
        window.controls.party_morale_bubble_text,
        window.controls.party_morale_text_alignment,
        window.controls.party_morale_text_margin,

        ui.add_hr(),
        ui.add_title(TR("Power / Wrath")),
        window.controls.party_power_height,
        ui.add_break(),
        window.controls.party_power_font_name,
        window.controls.party_power_font_size,
        window.controls.party_power_font_color,
        window.controls.party_power_font_style,
        window.controls.party_power_font_outline_color,
        ui.add_break(),
        window.controls.party_power_color,
        window.controls.party_wrath_color,
        ui.add_break(),
        window.controls.party_power_text,
        window.controls.party_power_text_alignment,
        window.controls.party_power_text_margin,

        ui.add_hr(),
        ui.add_title(TR("Icons")),
        window.controls.party_class_icon_enabled,
        window.controls.party_class_icon_size,
        window.controls.party_class_icon_x,
        window.controls.party_class_icon_y,
        ui.add_break(),
        window.controls.party_leader_icon_enabled,
        window.controls.party_leader_icon_size,
        window.controls.party_leader_icon_x,
        window.controls.party_leader_icon_y,

        ui.add_hr(),
        ui.add_title(TR("Preview")),
        window.controls.party_vitals_preview,
    }
end

function PartyVitals.load(window, s, ui)
    local v = s.party

    window.controls.party_width.tb:SetText(tostring(v.frame.width))
    window.controls.party_border_width.tb:SetText(tostring(v.frame.border_width))
    window.controls.party_incombat_opacity.tb:SetText(tostring(v.frame.incombat_opacity))
    window.controls.party_outcombat_opacity.tb:SetText(tostring(v.frame.outcombat_opacity))
    window.controls.party_class_icon_enabled.cb:SetChecked(v.class_icon.enabled == true)
    window.controls.party_class_icon_size.tb:SetText(tostring(v.class_icon.size))
    window.controls.party_class_icon_x.tb:SetText(tostring(v.class_icon.x))
    window.controls.party_class_icon_y.tb:SetText(tostring(v.class_icon.y))
    window.controls.party_leader_icon_enabled.cb:SetChecked(v.leader_icon.enabled == true)
    window.controls.party_leader_icon_size.tb:SetText(tostring(v.leader_icon.size))
    window.controls.party_leader_icon_x.tb:SetText(tostring(v.leader_icon.x))
    window.controls.party_leader_icon_y.tb:SetText(tostring(v.leader_icon.y))

    window.controls.party_morale_height.tb:SetText(tostring(v.morale.height))
    window.controls.party_morale_font_name:set_value(v.morale.font.name)
    window.controls.party_morale_font_size.tb:SetText(tostring(v.morale.font.size))
    window.controls.party_morale_font_color.tb:SetText(ui.color_to_hex(v.morale.font.color))
    window.controls.party_morale_font_style:set_value(v.morale.font.style)
    window.controls.party_morale_font_outline_color.tb:SetText(ui.color_to_hex(v.morale.font.outline_color))

    window.controls.party_morale_background_color.tb:SetText(ui.color_to_hex(v.morale.color.background))
    window.controls.party_ressource_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    window.controls.party_ressource_background_dimming.tb:SetText(tostring(v.background_dimming))
    window.controls.party_border_color.tb:SetText(ui.color_to_hex(v.frame.border_color))
    window.controls.party_morale_bubble_color.tb:SetText(ui.color_to_hex(v.morale.color.bubble))
    window.controls.party_morale_color_neutral.tb:SetText(ui.color_to_hex(v.morale.color.neutral))
    window.controls.party_morale_gradient.cb:SetChecked(v.morale.color.gradient == true)
    window.controls.party_morale_gradient_full.tb:SetText(ui.color_to_hex(v.morale.color.gradient_full))
    window.controls.party_morale_gradient_mid.tb:SetText(ui.color_to_hex(v.morale.color.gradient_mid))
    window.controls.party_morale_gradient_low.tb:SetText(ui.color_to_hex(v.morale.color.gradient_low))
    window.controls.party_morale_color_high.tb:SetText(ui.color_to_hex(v.morale.color.high))
    window.controls.party_morale_color_medium.tb:SetText(ui.color_to_hex(v.morale.color.medium))
    window.controls.party_morale_color_low.tb:SetText(ui.color_to_hex(v.morale.color.low))
    window.controls.party_morale_color_critical.tb:SetText(ui.color_to_hex(v.morale.color.critical))

    window.controls.party_morale_text.tb:SetText(tostring(v.morale.string_format))
    window.controls.party_morale_text_alignment:set_value(v.morale.text_alignment)
    window.controls.party_morale_bubble_text.tb:SetText(tostring(v.morale.bubble_format))
    window.controls.party_morale_text_margin.tb:SetText(tostring(v.morale.text_margin))

    window.controls.party_power_height.tb:SetText(tostring(v.power.height))
    window.controls.party_power_font_name:set_value(v.power.font.name)
    window.controls.party_power_font_size.tb:SetText(tostring(v.power.font.size))
    window.controls.party_power_font_color.tb:SetText(ui.color_to_hex(v.power.font.color))
    window.controls.party_power_font_style:set_value(v.power.font.style)
    window.controls.party_power_font_outline_color.tb:SetText(ui.color_to_hex(v.power.font.outline_color))

    window.controls.party_power_color.tb:SetText(ui.color_to_hex(v.power.color.power))
    window.controls.party_wrath_color.tb:SetText(ui.color_to_hex(v.power.color.wrath))
    window.controls.party_power_text.tb:SetText(tostring(v.power.string_format))
    window.controls.party_power_text_alignment:set_value(v.power.text_alignment)
    window.controls.party_power_text_margin.tb:SetText(tostring(v.power.text_margin))
end

function PartyVitals.apply(window, s, ui)
    local v = s.party

    local w = tonumber(window.controls.party_width.tb:GetText())
    if w ~= nil then v.frame.width = w end

    local bw = tonumber(window.controls.party_border_width.tb:GetText())
    if bw ~= nil then v.frame.border_width = bw end

    local in_op = tonumber(window.controls.party_incombat_opacity.tb:GetText())
    if in_op ~= nil then v.frame.incombat_opacity = in_op end

    local out_op = tonumber(window.controls.party_outcombat_opacity.tb:GetText())
    if out_op ~= nil then v.frame.outcombat_opacity = out_op end

    v.class_icon.enabled = window.controls.party_class_icon_enabled.cb:IsChecked() == true
    local icon_size = tonumber(window.controls.party_class_icon_size.tb:GetText())
    if icon_size ~= nil then v.class_icon.size = icon_size end
    local icon_x = tonumber(window.controls.party_class_icon_x.tb:GetText())
    if icon_x ~= nil then v.class_icon.x = icon_x end
    local icon_y = tonumber(window.controls.party_class_icon_y.tb:GetText())
    if icon_y ~= nil then v.class_icon.y = icon_y end

    v.leader_icon.enabled = window.controls.party_leader_icon_enabled.cb:IsChecked() == true
    local leader_size = tonumber(window.controls.party_leader_icon_size.tb:GetText())
    if leader_size ~= nil then v.leader_icon.size = leader_size end
    local leader_x = tonumber(window.controls.party_leader_icon_x.tb:GetText())
    if leader_x ~= nil then v.leader_icon.x = leader_x end
    local leader_y = tonumber(window.controls.party_leader_icon_y.tb:GetText())
    if leader_y ~= nil then v.leader_icon.y = leader_y end

    local mh = tonumber(window.controls.party_morale_height.tb:GetText())
    if mh ~= nil then v.morale.height = mh end

    local morale_font_name = window.controls.party_morale_font_name:get_value()
    if type(morale_font_name) == "number" then
        v.morale.font.name = morale_font_name
    end
    local morale_font_size = tonumber(window.controls.party_morale_font_size.tb:GetText())
    if morale_font_size ~= nil then v.morale.font.size = morale_font_size end
    _apply_color(ui, v.morale.font.color, window.controls.party_morale_font_color.tb:GetText())
    local morale_font_style = window.controls.party_morale_font_style:get_value()
    if type(morale_font_style) == "number" then
        v.morale.font.style = morale_font_style
    end
    _apply_color(ui, v.morale.font.outline_color, window.controls.party_morale_font_outline_color.tb:GetText())

    _apply_color(ui, v.morale.color.background, window.controls.party_morale_background_color.tb:GetText())
    v.background_matches_missing = window.controls.party_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_background_dimming = tonumber(window.controls.party_ressource_background_dimming.tb:GetText())
    if ressource_background_dimming ~= nil then v.background_dimming = ressource_background_dimming end
    _apply_color(ui, v.frame.border_color, window.controls.party_border_color.tb:GetText())
    _apply_color(ui, v.morale.color.bubble, window.controls.party_morale_bubble_color.tb:GetText())
    _apply_color(ui, v.morale.color.neutral, window.controls.party_morale_color_neutral.tb:GetText())
    v.morale.color.gradient = window.controls.party_morale_gradient.cb:IsChecked() == true
    _apply_color(ui, v.morale.color.gradient_full, window.controls.party_morale_gradient_full.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_mid, window.controls.party_morale_gradient_mid.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_low, window.controls.party_morale_gradient_low.tb:GetText())
    _apply_color(ui, v.morale.color.high, window.controls.party_morale_color_high.tb:GetText())
    _apply_color(ui, v.morale.color.medium, window.controls.party_morale_color_medium.tb:GetText())
    _apply_color(ui, v.morale.color.low, window.controls.party_morale_color_low.tb:GetText())
    _apply_color(ui, v.morale.color.critical, window.controls.party_morale_color_critical.tb:GetText())

    local morale_text = window.controls.party_morale_text.tb:GetText()
    if type(morale_text) == "string" then v.morale.string_format = morale_text end
    local morale_text_alignment = window.controls.party_morale_text_alignment:get_value()
    if type(morale_text_alignment) == "number" then
        v.morale.text_alignment = morale_text_alignment
    end
    local morale_text_margin = tonumber(window.controls.party_morale_text_margin.tb:GetText())
    if morale_text_margin ~= nil then v.morale.text_margin = morale_text_margin end
    local bubble_text = window.controls.party_morale_bubble_text.tb:GetText()
    if type(bubble_text) == "string" then v.morale.bubble_format = bubble_text end

    local ph = tonumber(window.controls.party_power_height.tb:GetText())
    if ph ~= nil then v.power.height = ph end

    local power_font_name = window.controls.party_power_font_name:get_value()
    if type(power_font_name) == "number" then
        v.power.font.name = power_font_name
    end
    local power_font_size = tonumber(window.controls.party_power_font_size.tb:GetText())
    if power_font_size ~= nil then v.power.font.size = power_font_size end
    _apply_color(ui, v.power.font.color, window.controls.party_power_font_color.tb:GetText())
    local power_font_style = window.controls.party_power_font_style:get_value()
    if type(power_font_style) == "number" then
        v.power.font.style = power_font_style
    end
    _apply_color(ui, v.power.font.outline_color, window.controls.party_power_font_outline_color.tb:GetText())

    _apply_color(ui, v.power.color.power, window.controls.party_power_color.tb:GetText())
    _apply_color(ui, v.power.color.wrath, window.controls.party_wrath_color.tb:GetText())

    local power_text = window.controls.party_power_text.tb:GetText()
    if type(power_text) == "string" then v.power.string_format = power_text end
    local power_text_alignment = window.controls.party_power_text_alignment:get_value()
    if type(power_text_alignment) == "number" then
        v.power.text_alignment = power_text_alignment
    end
    local power_text_margin = tonumber(window.controls.party_power_text_margin.tb:GetText())
    if power_text_margin ~= nil then v.power.text_margin = power_text_margin end
end
