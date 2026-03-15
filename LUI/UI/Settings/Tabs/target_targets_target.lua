TargetTargetsTarget = {
    key = "target_targets_target",
    text = TR("Target's Target"),
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

function TargetTargetsTarget.create_controls(window, ui)
    ui.add_text("target_targets_target_width", TR("Frame Width"))
    ui.add_text("target_targets_target_height", TR("Bar Height"))
    ui.add_text("target_targets_target_border_width", TR("Border Width"))
    ui.add_break()

    ui.add_dropdown("target_targets_target_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("target_targets_target_font_size", TR("Font Size"))
    ui.add_text("target_targets_target_font_color", TR("Font Color"), true)
    ui.add_dropdown("target_targets_target_font_style", TR("Font Style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("target_targets_target_font_outline_color", TR("Outline Color"), true)
    ui.add_break()

    ui.add_text("target_targets_target_text", TR("Text"), false, ui.vital_format_help, true)
    ui.add_text("target_targets_target_bubble_text", TR("Bubble Format (%B)"), false, ui.bubble_format_help, true)
    ui.add_dropdown("target_targets_target_text_alignment", TR("Text alignment"), ui.text_alignment_labels,
        ui.text_alignment_values)
    ui.add_text("target_targets_target_text_margin", TR("Text margin"))

    ui.add_text("target_targets_target_background_color", TR("Background Color"), true)
    ui.add_checkbox("target_targets_target_background_matches_missing", TR("Background matches missing ressource"))
    ui.add_text("target_targets_target_background_dimming", TR("Dimming"))
    ui.add_text("target_targets_target_border_color", TR("Border Color"), true)
    ui.add_text("target_targets_target_bubble_color", TR("Bubble Color"), true)
    ui.add_text("target_targets_target_color_neutral", TR("Neutral Color"), true)
    ui.add_checkbox("target_targets_target_color_gradient", TR("Enable gradient colors"), true)
    ui.add_text("target_targets_target_color_gradient_full", TR("Full Color"), true)
    ui.add_text("target_targets_target_color_gradient_mid", TR("Mid Color"), true)
    ui.add_text("target_targets_target_color_gradient_low", TR("Low Color"), true)
    ui.add_custom("target_targets_target_color_gradient_preview", 30)
    ui.add_text("target_targets_target_color_high", TR("High Color"), true)
    ui.add_text("target_targets_target_color_medium", TR("Medium Color"), true)
    ui.add_text("target_targets_target_color_low", TR("Low Color"), true)
    ui.add_text("target_targets_target_color_critical", TR("Critical Color"), true)

    ui.add_custom("target_targets_target_preview", 133)
end

function TargetTargetsTarget.register(window, ui)
    window.controls.target_targets_target_font_outline_color.visible_if = function()
        return _is_outline(window.controls.target_targets_target_font_style)
    end

    _hook_layout_on_change(window, window.controls.target_targets_target_font_style)

    return {
        ui.add_title(TR("Target's Target")),

        ui.add_hr(),
        ui.add_title(TR("Frame")),
        window.controls.target_targets_target_width,
        window.controls.target_targets_target_height,
        window.controls.target_targets_target_border_width,
        ui.add_hr(),
        ui.add_title(TR("Font")),
        window.controls.target_targets_target_font_name,
        window.controls.target_targets_target_font_size,
        window.controls.target_targets_target_font_color,
        window.controls.target_targets_target_font_style,
        window.controls.target_targets_target_font_outline_color,
        ui.add_hr(),
        ui.add_title(TR("Text")),
        window.controls.target_targets_target_text,
        window.controls.target_targets_target_bubble_text,
        window.controls.target_targets_target_text_alignment,
        window.controls.target_targets_target_text_margin,
        ui.add_hr(),
        ui.add_title(TR("Colors")),
        window.controls.target_targets_target_background_color,
        ui.add_break(),
        window.controls.target_targets_target_background_matches_missing,
        window.controls.target_targets_target_background_dimming,
        ui.add_break(),
        window.controls.target_targets_target_border_color,
        window.controls.target_targets_target_bubble_color,
        window.controls.target_targets_target_color_neutral,
        ui.add_break(),
        ui.add_title(TR("Step Colors")),
        ui.add_info(STEP_COLORS_INFO),
        ui.add_break(),
        window.controls.target_targets_target_color_high,
        window.controls.target_targets_target_color_medium,
        window.controls.target_targets_target_color_low,
        window.controls.target_targets_target_color_critical,
        ui.add_break(),
        ui.add_title(TR("Gradient Colors")),
        ui.add_info(GRADIENT_COLORS_INFO),
        window.controls.target_targets_target_color_gradient,
        ui.add_break(),
        window.controls.target_targets_target_color_gradient_full,
        window.controls.target_targets_target_color_gradient_mid,
        window.controls.target_targets_target_color_gradient_low,
        window.controls.target_targets_target_color_gradient_preview,

        ui.add_hr(),
        ui.add_title(TR("Preview")),
        window.controls.target_targets_target_preview,
    }
end

function TargetTargetsTarget.load(window, s, ui)
    local v = s.target.vitals.targets_target

    window.controls.target_targets_target_width.tb:SetText(tostring(v.width))
    window.controls.target_targets_target_height.tb:SetText(tostring(v.height))
    window.controls.target_targets_target_border_width.tb:SetText(tostring(v.border_width))
    window.controls.target_targets_target_font_name:set_value(v.font.name)
    window.controls.target_targets_target_font_size.tb:SetText(tostring(v.font.size))
    window.controls.target_targets_target_font_color.tb:SetText(ui.color_to_hex(v.font.color))
    window.controls.target_targets_target_font_style:set_value(v.font.style)
    window.controls.target_targets_target_font_outline_color.tb:SetText(ui.color_to_hex(v.font.outline_color))

    window.controls.target_targets_target_text.tb:SetText(tostring(v.text))
    window.controls.target_targets_target_bubble_text.tb:SetText(tostring(v.bubble_format))
    window.controls.target_targets_target_text_alignment:set_value(v.text_alignment)
    window.controls.target_targets_target_text_margin.tb:SetText(tostring(v.text_margin))

    window.controls.target_targets_target_background_color.tb:SetText(ui.color_to_hex(v.color.background))
    window.controls.target_targets_target_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    window.controls.target_targets_target_background_dimming.tb:SetText(tostring(v.background_dimming))
    window.controls.target_targets_target_border_color.tb:SetText(ui.color_to_hex(v.color.border))
    window.controls.target_targets_target_bubble_color.tb:SetText(ui.color_to_hex(v.color.bubble))
    window.controls.target_targets_target_color_neutral.tb:SetText(ui.color_to_hex(v.color.neutral))
    window.controls.target_targets_target_color_gradient.cb:SetChecked(v.color.gradient == true)
    window.controls.target_targets_target_color_gradient_full.tb:SetText(ui.color_to_hex(v.color.gradient_full))
    window.controls.target_targets_target_color_gradient_mid.tb:SetText(ui.color_to_hex(v.color.gradient_mid))
    window.controls.target_targets_target_color_gradient_low.tb:SetText(ui.color_to_hex(v.color.gradient_low))
    window.controls.target_targets_target_color_high.tb:SetText(ui.color_to_hex(v.color.high))
    window.controls.target_targets_target_color_medium.tb:SetText(ui.color_to_hex(v.color.medium))
    window.controls.target_targets_target_color_low.tb:SetText(ui.color_to_hex(v.color.low))
    window.controls.target_targets_target_color_critical.tb:SetText(ui.color_to_hex(v.color.critical))
end

function TargetTargetsTarget.apply(window, s, ui)
    local v = s.target.vitals.targets_target

    local tt_width = tonumber(window.controls.target_targets_target_width.tb:GetText())
    if tt_width ~= nil then v.width = tt_width end

    local tt_height = tonumber(window.controls.target_targets_target_height.tb:GetText())
    if tt_height ~= nil then v.height = tt_height end

    local tt_border_width = tonumber(window.controls.target_targets_target_border_width.tb:GetText())
    if tt_border_width ~= nil then v.border_width = tt_border_width end

    v.font.name = window.controls.target_targets_target_font_name:get_value()
    local tt_font_size = tonumber(window.controls.target_targets_target_font_size.tb:GetText())
    if tt_font_size ~= nil then v.font.size = tt_font_size end
    _apply_color(ui, v.font.color, window.controls.target_targets_target_font_color.tb:GetText())
    v.font.style = window.controls.target_targets_target_font_style:get_value()
    _apply_color(ui, v.font.outline_color, window.controls.target_targets_target_font_outline_color.tb:GetText())

    v.text = window.controls.target_targets_target_text.tb:GetText()
    v.bubble_format = window.controls.target_targets_target_bubble_text.tb:GetText()
    v.text_alignment = window.controls.target_targets_target_text_alignment:get_value()
    local tt_text_margin = tonumber(window.controls.target_targets_target_text_margin.tb:GetText())
    if tt_text_margin ~= nil then v.text_margin = tt_text_margin end

    _apply_color(ui, v.color.background, window.controls.target_targets_target_background_color.tb:GetText())
    v.background_matches_missing = window.controls.target_targets_target_background_matches_missing.cb:IsChecked() ==
        true
    local background_dimming = tonumber(window.controls.target_targets_target_background_dimming.tb:GetText())
    if background_dimming ~= nil then v.background_dimming = background_dimming end
    _apply_color(ui, v.color.border, window.controls.target_targets_target_border_color.tb:GetText())
    _apply_color(ui, v.color.bubble, window.controls.target_targets_target_bubble_color.tb:GetText())
    _apply_color(ui, v.color.neutral, window.controls.target_targets_target_color_neutral.tb:GetText())
    v.color.gradient = window.controls.target_targets_target_color_gradient.cb:IsChecked() == true
    _apply_color(ui, v.color.gradient_full, window.controls.target_targets_target_color_gradient_full.tb:GetText())
    _apply_color(ui, v.color.gradient_mid, window.controls.target_targets_target_color_gradient_mid.tb:GetText())
    _apply_color(ui, v.color.gradient_low, window.controls.target_targets_target_color_gradient_low.tb:GetText())
    _apply_color(ui, v.color.high, window.controls.target_targets_target_color_high.tb:GetText())
    _apply_color(ui, v.color.medium, window.controls.target_targets_target_color_medium.tb:GetText())
    _apply_color(ui, v.color.low, window.controls.target_targets_target_color_low.tb:GetText())
    _apply_color(ui, v.color.critical, window.controls.target_targets_target_color_critical.tb:GetText())
end
