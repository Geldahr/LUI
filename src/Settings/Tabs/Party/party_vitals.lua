import "LUI.src.Settings.Tabs.Party.party_vitals_page"

PartyVitals = {
    key = "party_vitals",
    text = TR["Party Vitals"],
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

function PartyVitals.create_page(window)
    return PartyVitalsPage(window)
end

function PartyVitals.load(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.party

    page.loading = true
    controls.party_width.tb:SetText(tostring(v.frame.width))
    controls.party_border_width.tb:SetText(tostring(v.frame.border_width))
    controls.party_incombat_opacity.tb:SetText(tostring(v.frame.incombat_opacity))
    controls.party_outcombat_opacity.tb:SetText(tostring(v.frame.outcombat_opacity))
    controls.party_class_icon_enabled.cb:SetChecked(v.class_icon.enabled == true)
    controls.party_class_icon_size.tb:SetText(tostring(v.class_icon.size))
    controls.party_class_icon_x.tb:SetText(tostring(v.class_icon.x))
    controls.party_class_icon_y.tb:SetText(tostring(v.class_icon.y))
    controls.party_leader_icon_enabled.cb:SetChecked(v.leader_icon.enabled == true)
    controls.party_leader_icon_size.tb:SetText(tostring(v.leader_icon.size))
    controls.party_leader_icon_x.tb:SetText(tostring(v.leader_icon.x))
    controls.party_leader_icon_y.tb:SetText(tostring(v.leader_icon.y))

    controls.party_morale_height.tb:SetText(tostring(v.morale.height))
    controls.party_morale_background_color.tb:SetText(ui.color_to_hex(v.morale.color.background))
    controls.party_ressource_background_matches_missing.cb:SetChecked(v.background_matches_missing == true)
    controls.party_ressource_background_dimming.tb:SetText(tostring(v.background_dimming))
    controls.party_border_color.tb:SetText(ui.color_to_hex(v.frame.border_color))
    controls.party_morale_bubble_color.tb:SetText(ui.color_to_hex(v.morale.color.bubble))
    controls.party_morale_color_neutral.tb:SetText(ui.color_to_hex(v.morale.color.neutral))
    controls.party_morale_gradient.cb:SetChecked(v.morale.color.gradient == true)
    controls.party_morale_gradient_full.tb:SetText(ui.color_to_hex(v.morale.color.gradient_full))
    controls.party_morale_gradient_mid.tb:SetText(ui.color_to_hex(v.morale.color.gradient_mid))
    controls.party_morale_gradient_low.tb:SetText(ui.color_to_hex(v.morale.color.gradient_low))
    controls.party_morale_color_high.tb:SetText(ui.color_to_hex(v.morale.color.high))
    controls.party_morale_color_medium.tb:SetText(ui.color_to_hex(v.morale.color.medium))
    controls.party_morale_color_low.tb:SetText(ui.color_to_hex(v.morale.color.low))
    controls.party_morale_color_critical.tb:SetText(ui.color_to_hex(v.morale.color.critical))
    controls.party_morale_bubble_text.tb:SetText(tostring(v.morale.bubble_format))
    _load_vital_label(controls, "party", "morale", 1, v.morale.labels[1], ui)
    _load_vital_label(controls, "party", "morale", 2, v.morale.labels[2], ui)

    controls.party_power_height.tb:SetText(tostring(v.power.height))
    controls.party_power_color.tb:SetText(ui.color_to_hex(v.power.color.power))
    controls.party_wrath_color.tb:SetText(ui.color_to_hex(v.power.color.wrath))
    _load_vital_label(controls, "party", "power", 1, v.power.labels[1], ui)
    _load_vital_label(controls, "party", "power", 2, v.power.labels[2], ui)
    page.loading = false
    page:layout()
end

function PartyVitals.apply(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.party

    local w = tonumber(controls.party_width.tb:GetText())
    if w ~= nil then
        v.frame.width = w
    end

    local bw = tonumber(controls.party_border_width.tb:GetText())
    if bw ~= nil then
        v.frame.border_width = bw
    end

    local in_op = tonumber(controls.party_incombat_opacity.tb:GetText())
    if in_op ~= nil then
        v.frame.incombat_opacity = in_op
    end

    local out_op = tonumber(controls.party_outcombat_opacity.tb:GetText())
    if out_op ~= nil then
        v.frame.outcombat_opacity = out_op
    end

    v.class_icon.enabled = controls.party_class_icon_enabled.cb:IsChecked() == true
    local icon_size = tonumber(controls.party_class_icon_size.tb:GetText())
    if icon_size ~= nil then
        v.class_icon.size = icon_size
    end
    local icon_x = tonumber(controls.party_class_icon_x.tb:GetText())
    if icon_x ~= nil then
        v.class_icon.x = icon_x
    end
    local icon_y = tonumber(controls.party_class_icon_y.tb:GetText())
    if icon_y ~= nil then
        v.class_icon.y = icon_y
    end

    v.leader_icon.enabled = controls.party_leader_icon_enabled.cb:IsChecked() == true
    local leader_size = tonumber(controls.party_leader_icon_size.tb:GetText())
    if leader_size ~= nil then
        v.leader_icon.size = leader_size
    end
    local leader_x = tonumber(controls.party_leader_icon_x.tb:GetText())
    if leader_x ~= nil then
        v.leader_icon.x = leader_x
    end
    local leader_y = tonumber(controls.party_leader_icon_y.tb:GetText())
    if leader_y ~= nil then
        v.leader_icon.y = leader_y
    end

    local mh = tonumber(controls.party_morale_height.tb:GetText())
    if mh ~= nil then
        v.morale.height = mh
    end

    _apply_color(ui, v.morale.color.background, controls.party_morale_background_color.tb:GetText())
    v.background_matches_missing = controls.party_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_background_dimming = tonumber(controls.party_ressource_background_dimming.tb:GetText())
    if ressource_background_dimming ~= nil then
        v.background_dimming = ressource_background_dimming
    end
    _apply_color(ui, v.frame.border_color, controls.party_border_color.tb:GetText())
    _apply_color(ui, v.morale.color.bubble, controls.party_morale_bubble_color.tb:GetText())
    _apply_color(ui, v.morale.color.neutral, controls.party_morale_color_neutral.tb:GetText())
    v.morale.color.gradient = controls.party_morale_gradient.cb:IsChecked() == true
    _apply_color(ui, v.morale.color.gradient_full, controls.party_morale_gradient_full.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_mid, controls.party_morale_gradient_mid.tb:GetText())
    _apply_color(ui, v.morale.color.gradient_low, controls.party_morale_gradient_low.tb:GetText())
    _apply_color(ui, v.morale.color.high, controls.party_morale_color_high.tb:GetText())
    _apply_color(ui, v.morale.color.medium, controls.party_morale_color_medium.tb:GetText())
    _apply_color(ui, v.morale.color.low, controls.party_morale_color_low.tb:GetText())
    _apply_color(ui, v.morale.color.critical, controls.party_morale_color_critical.tb:GetText())
    local bubble_text = controls.party_morale_bubble_text.tb:GetText()
    if type(bubble_text) == "string" then
        v.morale.bubble_format = bubble_text
    end
    _apply_vital_label(controls, "party", "morale", 1, v.morale.labels[1], ui)
    _apply_vital_label(controls, "party", "morale", 2, v.morale.labels[2], ui)

    local ph = tonumber(controls.party_power_height.tb:GetText())
    if ph ~= nil then
        v.power.height = ph
    end

    _apply_color(ui, v.power.color.power, controls.party_power_color.tb:GetText())
    _apply_color(ui, v.power.color.wrath, controls.party_wrath_color.tb:GetText())
    _apply_vital_label(controls, "party", "power", 1, v.power.labels[1], ui)
    _apply_vital_label(controls, "party", "power", 2, v.power.labels[2], ui)
end
