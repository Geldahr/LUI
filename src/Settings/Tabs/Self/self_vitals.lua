SelfVitals = {
    key = "self_vitals",
    text = TR["Self Vitals"],
}

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

local function _load_vital_label(controls, prefix, bar_key, label_index, label, ui)
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)
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

local function _apply_vital_label(controls, prefix, bar_key, label_index, label, ui)
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)

    label.enabled = controls[key .. "_enabled"].cb:IsChecked() == true

    local text = controls[key .. "_text"].tb:GetText()
    if type(text) == "string" then
        label.text = text
    end

    local text_alignment = controls[key .. "_text_alignment"]:get_value()
    if type(text_alignment) == "number" then
        label.text_alignment = text_alignment
    end

    local anchor = controls[key .. "_anchor"]:get_value()
    if type(anchor) == "number" then
        label.anchor = anchor
    end

    local width_mode = controls[key .. "_width_mode"]:get_value()
    if type(width_mode) == "number" then
        label.width_mode = width_mode
    end

    local x_offset = tonumber(controls[key .. "_x_offset"].tb:GetText())
    if x_offset ~= nil then
        label.x_offset = x_offset
    end

    local y_offset = tonumber(controls[key .. "_y_offset"].tb:GetText())
    if y_offset ~= nil then
        label.y_offset = y_offset
    end

    local font_name = controls[key .. "_font_name"]:get_value()
    if type(font_name) == "number" then
        label.font.name = font_name
    end

    local font_size = tonumber(controls[key .. "_font_size"].tb:GetText())
    if font_size ~= nil then
        label.font.size = font_size
    end

    _apply_color(ui, label.font.color, controls[key .. "_font_color"].tb:GetText())

    local font_style = controls[key .. "_font_style"]:get_value()
    if type(font_style) == "number" then
        label.font.style = font_style
    end

    _apply_color(ui, label.font.outline_color, controls[key .. "_font_outline_color"].tb:GetText())
end

function SelfVitals.load(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.self.vitals

    page.loading = true
    controls.self_width.tb:SetText(tostring(v.frame.width))
    controls.self_border_width.tb:SetText(tostring(v.frame.border_width))
    controls.self_incombat_opacity.tb:SetText(tostring(v.frame.incombat_opacity))
    controls.self_outcombat_opacity.tb:SetText(tostring(v.frame.outcombat_opacity))
    controls.self_effects_position:set_value(v.frame.effects_position)

    controls.self_morale_height.tb:SetText(tostring(v.morale.height))
    controls.self_morale_background_color.tb:SetText(ui.color_to_hex(v.morale.color.background))
    controls.self_ressource_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    controls.self_ressource_background_dimming.tb:SetText(tostring(v.background_dimming))
    controls.self_border_color.tb:SetText(ui.color_to_hex(v.frame.border_color))
    controls.self_morale_bubble_color.tb:SetText(ui.color_to_hex(v.morale.color.bubble))
    controls.self_morale_color_neutral.tb:SetText(ui.color_to_hex(v.morale.color.neutral))
    controls.self_morale_gradient.cb:SetChecked(v.morale.color.gradient == true)
    controls.self_morale_gradient_full.tb:SetText(ui.color_to_hex(v.morale.color.gradient_full))
    controls.self_morale_gradient_mid.tb:SetText(ui.color_to_hex(v.morale.color.gradient_mid))
    controls.self_morale_gradient_low.tb:SetText(ui.color_to_hex(v.morale.color.gradient_low))
    controls.self_morale_color_high.tb:SetText(ui.color_to_hex(v.morale.color.high))
    controls.self_morale_color_medium.tb:SetText(ui.color_to_hex(v.morale.color.medium))
    controls.self_morale_color_low.tb:SetText(ui.color_to_hex(v.morale.color.low))
    controls.self_morale_color_critical.tb:SetText(ui.color_to_hex(v.morale.color.critical))
    controls.self_morale_bubble_text.tb:SetText(tostring(v.morale.bubble_format))
    _load_vital_label(controls, "self", "morale", 1, v.morale.labels[1], ui)
    _load_vital_label(controls, "self", "morale", 2, v.morale.labels[2], ui)

    controls.self_power_height.tb:SetText(tostring(v.power.height))
    controls.self_power_color.tb:SetText(ui.color_to_hex(v.power.color.power))
    controls.self_wrath_color.tb:SetText(ui.color_to_hex(v.power.color.wrath))
    _load_vital_label(controls, "self", "power", 1, v.power.labels[1], ui)
    _load_vital_label(controls, "self", "power", 2, v.power.labels[2], ui)

    controls.self_buff_size.tb:SetText(tostring(v.effects.buffs.icon_size))
    controls.self_effects_height.tb:SetText(tostring(v.frame.effects_height))
    controls.self_buff_timer_font_name:set_value(v.effects.buffs.timer_font.name)
    controls.self_buff_timer_font_size.tb:SetText(tostring(v.effects.buffs.timer_font.size))
    controls.self_buff_timer_font_color.tb:SetText(ui.color_to_hex(v.effects.buffs.timer_font.color))
    controls.self_buff_timer_font_style:set_value(v.effects.buffs.timer_font.style)
    controls.self_buff_timer_font_outline_color.tb:SetText(ui.color_to_hex(v.effects.buffs.timer_font.outline_color))

    controls.self_debuff_size.tb:SetText(tostring(v.effects.debuffs.icon_size))
    controls.self_debuff_track_curable.cb:SetChecked(v.effects.debuffs.track_curable == true)
    controls.self_debuff_track_noncurable.cb:SetChecked(v.effects.debuffs.track_noncurable == true)
    controls.self_debuff_timer_font_name:set_value(v.effects.debuffs.timer_font.name)
    controls.self_debuff_timer_font_size.tb:SetText(tostring(v.effects.debuffs.timer_font.size))
    controls.self_debuff_timer_font_color.tb:SetText(ui.color_to_hex(v.effects.debuffs.timer_font.color))
    controls.self_debuff_timer_font_style:set_value(v.effects.debuffs.timer_font.style)
    controls.self_debuff_timer_font_outline_color.tb:SetText(ui.color_to_hex(v.effects.debuffs.timer_font.outline_color))
    page.loading = false
    page:layout()
end

function SelfVitals.apply(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.self.vitals

    local w = tonumber(controls.self_width.tb:GetText())
    if w ~= nil then
        v.frame.width = w
    end

    local bw = tonumber(controls.self_border_width.tb:GetText())
    if bw ~= nil then
        v.frame.border_width = bw
    end

    local in_op = tonumber(controls.self_incombat_opacity.tb:GetText())
    if in_op ~= nil then
        v.frame.incombat_opacity = in_op
    end

    local out_op = tonumber(controls.self_outcombat_opacity.tb:GetText())
    if out_op ~= nil then
        v.frame.outcombat_opacity = out_op
    end

    local mh = tonumber(controls.self_morale_height.tb:GetText())
    if mh ~= nil then
        v.morale.height = mh
    end

    _apply_color(ui, v.morale.color.background, controls.self_morale_background_color.tb:GetText())
    v.background_matches_missing = controls.self_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_background_dimming = tonumber(controls.self_ressource_background_dimming.tb:GetText())
    if ressource_background_dimming ~= nil then
        v.background_dimming = ressource_background_dimming
    end
    _apply_color(ui, v.frame.border_color, controls.self_border_color.tb:GetText())
    _apply_color(ui, v.morale.color.bubble, controls.self_morale_bubble_color.tb:GetText())
    _apply_color(ui, v.morale.color.neutral, controls.self_morale_color_neutral.tb:GetText())
    v.morale.color.gradient = controls.self_morale_gradient.cb:IsChecked() == true
    _apply_color(ui, v.morale.color.gradient_full, controls.self_morale_gradient_full.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_mid, controls.self_morale_gradient_mid.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_low, controls.self_morale_gradient_low.tb:GetText())
    _apply_color(ui, v.morale.color.high, controls.self_morale_color_high.tb:GetText())
    _apply_color(ui, v.morale.color.medium, controls.self_morale_color_medium.tb:GetText())
    _apply_color(ui, v.morale.color.low, controls.self_morale_color_low.tb:GetText())
    _apply_color(ui, v.morale.color.critical, controls.self_morale_color_critical.tb:GetText())
    local self_bubble_text = controls.self_morale_bubble_text.tb:GetText()
    if type(self_bubble_text) == "string" then
        v.morale.bubble_format = self_bubble_text
    end
    _apply_vital_label(controls, "self", "morale", 1, v.morale.labels[1], ui)
    _apply_vital_label(controls, "self", "morale", 2, v.morale.labels[2], ui)

    local ph = tonumber(controls.self_power_height.tb:GetText())
    if ph ~= nil then
        v.power.height = ph
    end

    _apply_color(ui, v.power.color.power, controls.self_power_color.tb:GetText())
    _apply_color(ui, v.power.color.wrath, controls.self_wrath_color.tb:GetText())
    _apply_vital_label(controls, "self", "power", 1, v.power.labels[1], ui)
    _apply_vital_label(controls, "self", "power", 2, v.power.labels[2], ui)

    local effects_h = tonumber(controls.self_effects_height.tb:GetText())
    if effects_h ~= nil then
        v.frame.effects_height = effects_h
    end
    local effects_position = controls.self_effects_position:get_value()
    if type(effects_position) == "number" then
        v.frame.effects_position = effects_position
    end

    local buff_size = tonumber(controls.self_buff_size.tb:GetText())
    if buff_size ~= nil then
        v.effects.buffs.icon_size = buff_size
    end

    local buff_timer_font_name = controls.self_buff_timer_font_name:get_value()
    if type(buff_timer_font_name) == "number" then
        v.effects.buffs.timer_font.name = buff_timer_font_name
    end
    local buff_timer_font_size = tonumber(controls.self_buff_timer_font_size.tb:GetText())
    if buff_timer_font_size ~= nil then
        v.effects.buffs.timer_font.size = buff_timer_font_size
    end
    _apply_color(ui, v.effects.buffs.timer_font.color, controls.self_buff_timer_font_color.tb:GetText())
    local buff_timer_font_style = controls.self_buff_timer_font_style:get_value()
    if type(buff_timer_font_style) == "number" then
        v.effects.buffs.timer_font.style = buff_timer_font_style
    end
    _apply_color(ui, v.effects.buffs.timer_font.outline_color, controls.self_buff_timer_font_outline_color.tb:GetText())

    local debuff_size = tonumber(controls.self_debuff_size.tb:GetText())
    if debuff_size ~= nil then
        v.effects.debuffs.icon_size = debuff_size
    end
    v.effects.debuffs.track_curable = controls.self_debuff_track_curable.cb:IsChecked() == true
    v.effects.debuffs.track_noncurable = controls.self_debuff_track_noncurable.cb:IsChecked() == true

    local debuff_timer_font_name = controls.self_debuff_timer_font_name:get_value()
    if type(debuff_timer_font_name) == "number" then
        v.effects.debuffs.timer_font.name = debuff_timer_font_name
    end
    local debuff_timer_font_size = tonumber(controls.self_debuff_timer_font_size.tb:GetText())
    if debuff_timer_font_size ~= nil then
        v.effects.debuffs.timer_font.size = debuff_timer_font_size
    end
    _apply_color(ui, v.effects.debuffs.timer_font.color, controls.self_debuff_timer_font_color.tb:GetText())
    local debuff_timer_font_style = controls.self_debuff_timer_font_style:get_value()
    if type(debuff_timer_font_style) == "number" then
        v.effects.debuffs.timer_font.style = debuff_timer_font_style
    end
    _apply_color(ui, v.effects.debuffs.timer_font.outline_color,
        controls.self_debuff_timer_font_outline_color.tb:GetText())
end
