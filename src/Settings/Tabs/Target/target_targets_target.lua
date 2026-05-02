TargetTargetsTarget = {
    key = "target_targets_target",
    text = TR["Target's Target"],
}

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

local function _load_targets_target_label(controls, label_index, label, ui)
    local key = "target_targets_target_label" .. tostring(label_index)
    controls[key .. "_enabled"].cb:SetChecked(label.enabled == true)
    controls[key .. "_text"].tb:SetText(tostring(label.text))
    controls[key .. "_anchor"]:set_value(label.anchor)
    controls[key .. "_width_mode"]:set_value(label.width_mode)
    controls[key .. "_text_alignment"]:set_value(label.text_alignment)
    controls[key .. "_x_offset"].tb:SetText(tostring(label.x_offset))
    controls[key .. "_y_offset"].tb:SetText(tostring(label.y_offset))
    controls[key .. "_font_name"]:set_value(label.font.name)
    controls[key .. "_font_size"].tb:SetText(tostring(label.font.size))
    controls[key .. "_font_color"].tb:SetText(ui.color_to_hex(label.font.color))
    controls[key .. "_font_style"]:set_value(label.font.style)
    controls[key .. "_font_outline_color"].tb:SetText(ui.color_to_hex(label.font.outline_color))
end

local function _apply_targets_target_label(controls, label_index, label, ui)
    local key = "target_targets_target_label" .. tostring(label_index)

    label.enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    label.text = controls[key .. "_text"].tb:GetText()
    label.anchor = controls[key .. "_anchor"]:get_value()
    label.width_mode = controls[key .. "_width_mode"]:get_value()
    label.text_alignment = controls[key .. "_text_alignment"]:get_value()

    local x_offset = tonumber(controls[key .. "_x_offset"].tb:GetText())
    if x_offset ~= nil then
        label.x_offset = x_offset
    end

    local y_offset = tonumber(controls[key .. "_y_offset"].tb:GetText())
    if y_offset ~= nil then
        label.y_offset = y_offset
    end

    label.font.name = controls[key .. "_font_name"]:get_value()

    local font_size = tonumber(controls[key .. "_font_size"].tb:GetText())
    if font_size ~= nil then
        label.font.size = font_size
    end

    _apply_color(ui, label.font.color, controls[key .. "_font_color"].tb:GetText())
    label.font.style = controls[key .. "_font_style"]:get_value()
    _apply_color(ui, label.font.outline_color, controls[key .. "_font_outline_color"].tb:GetText())
end

function TargetTargetsTarget.load(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.target.vitals.targets_target

    page.loading = true
    controls.target_targets_target_width.tb:SetText(tostring(v.width))
    controls.target_targets_target_height.tb:SetText(tostring(v.height))
    controls.target_targets_target_border_width.tb:SetText(tostring(v.border_width))
    controls.target_targets_target_bubble_text.tb:SetText(tostring(v.bubble_format))
    _load_targets_target_label(controls, 1, v.labels[1], ui)
    _load_targets_target_label(controls, 2, v.labels[2], ui)

    controls.target_targets_target_background_color.tb:SetText(ui.color_to_hex(v.color.background))
    controls.target_targets_target_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    controls.target_targets_target_background_dimming.tb:SetText(tostring(v.background_dimming))
    controls.target_targets_target_border_color.tb:SetText(ui.color_to_hex(v.color.border))
    controls.target_targets_target_bubble_color.tb:SetText(ui.color_to_hex(v.color.bubble))
    controls.target_targets_target_color_neutral.tb:SetText(ui.color_to_hex(v.color.neutral))
    controls.target_targets_target_color_gradient.cb:SetChecked(v.color.gradient == true)
    controls.target_targets_target_color_gradient_full.tb:SetText(ui.color_to_hex(v.color.gradient_full))
    controls.target_targets_target_color_gradient_mid.tb:SetText(ui.color_to_hex(v.color.gradient_mid))
    controls.target_targets_target_color_gradient_low.tb:SetText(ui.color_to_hex(v.color.gradient_low))
    controls.target_targets_target_color_high.tb:SetText(ui.color_to_hex(v.color.high))
    controls.target_targets_target_color_medium.tb:SetText(ui.color_to_hex(v.color.medium))
    controls.target_targets_target_color_low.tb:SetText(ui.color_to_hex(v.color.low))
    controls.target_targets_target_color_critical.tb:SetText(ui.color_to_hex(v.color.critical))
    page.loading = false
    page:layout()
end

function TargetTargetsTarget.apply(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.target.vitals.targets_target

    local tt_width = tonumber(controls.target_targets_target_width.tb:GetText())
    if tt_width ~= nil then
        v.width = tt_width
    end

    local tt_height = tonumber(controls.target_targets_target_height.tb:GetText())
    if tt_height ~= nil then
        v.height = tt_height
    end

    local tt_border_width = tonumber(controls.target_targets_target_border_width.tb:GetText())
    if tt_border_width ~= nil then
        v.border_width = tt_border_width
    end

    v.bubble_format = controls.target_targets_target_bubble_text.tb:GetText()
    _apply_targets_target_label(controls, 1, v.labels[1], ui)
    _apply_targets_target_label(controls, 2, v.labels[2], ui)

    _apply_color(ui, v.color.background, controls.target_targets_target_background_color.tb:GetText())
    v.background_matches_missing = controls.target_targets_target_background_matches_missing.cb:IsChecked() == true
    local background_dimming = tonumber(controls.target_targets_target_background_dimming.tb:GetText())
    if background_dimming ~= nil then
        v.background_dimming = background_dimming
    end
    _apply_color(ui, v.color.border, controls.target_targets_target_border_color.tb:GetText())
    _apply_color(ui, v.color.bubble, controls.target_targets_target_bubble_color.tb:GetText())
    _apply_color(ui, v.color.neutral, controls.target_targets_target_color_neutral.tb:GetText())
    v.color.gradient = controls.target_targets_target_color_gradient.cb:IsChecked() == true
    _apply_color(ui, v.color.gradient_full, controls.target_targets_target_color_gradient_full.tb:GetText())
    _apply_color(ui, v.color.gradient_mid, controls.target_targets_target_color_gradient_mid.tb:GetText())
    _apply_color(ui, v.color.gradient_low, controls.target_targets_target_color_gradient_low.tb:GetText())
    _apply_color(ui, v.color.high, controls.target_targets_target_color_high.tb:GetText())
    _apply_color(ui, v.color.medium, controls.target_targets_target_color_medium.tb:GetText())
    _apply_color(ui, v.color.low, controls.target_targets_target_color_low.tb:GetText())
    _apply_color(ui, v.color.critical, controls.target_targets_target_color_critical.tb:GetText())
end
