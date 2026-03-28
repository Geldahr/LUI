import "LUI.src.UI.Settings.Tabs.Party.party_vitals_page"

PartyVitals = {
    key = "party_vitals",
    text = TR("Party Vitals"),
}

local function _page(window)
    return window ~= nil and window._tab_pages ~= nil and window._tab_pages.party_vitals or nil
end

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

function PartyVitals.create_page(window)
    return PartyVitalsPage(window)
end

function PartyVitals.load(window, s, ui)
    local page = _page(window)
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
    controls.party_morale_font_name:set_value(v.morale.font.name)
    controls.party_morale_font_size.tb:SetText(tostring(v.morale.font.size))
    controls.party_morale_font_color.tb:SetText(ui.color_to_hex(v.morale.font.color))
    controls.party_morale_font_style:set_value(v.morale.font.style)
    controls.party_morale_font_outline_color.tb:SetText(ui.color_to_hex(v.morale.font.outline_color))

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

    controls.party_morale_text.tb:SetText(tostring(v.morale.string_format))
    controls.party_morale_text_alignment:set_value(v.morale.text_alignment)
    controls.party_morale_bubble_text.tb:SetText(tostring(v.morale.bubble_format))
    controls.party_morale_text_margin.tb:SetText(tostring(v.morale.text_margin))

    controls.party_power_height.tb:SetText(tostring(v.power.height))
    controls.party_power_font_name:set_value(v.power.font.name)
    controls.party_power_font_size.tb:SetText(tostring(v.power.font.size))
    controls.party_power_font_color.tb:SetText(ui.color_to_hex(v.power.font.color))
    controls.party_power_font_style:set_value(v.power.font.style)
    controls.party_power_font_outline_color.tb:SetText(ui.color_to_hex(v.power.font.outline_color))

    controls.party_power_color.tb:SetText(ui.color_to_hex(v.power.color.power))
    controls.party_wrath_color.tb:SetText(ui.color_to_hex(v.power.color.wrath))
    controls.party_power_text.tb:SetText(tostring(v.power.string_format))
    controls.party_power_text_alignment:set_value(v.power.text_alignment)
    controls.party_power_text_margin.tb:SetText(tostring(v.power.text_margin))
    page.loading = false
    page:layout()
end

function PartyVitals.apply(window, s, ui)
    local page = _page(window)
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

    local morale_font_name = controls.party_morale_font_name:get_value()
    if type(morale_font_name) == "number" then
        v.morale.font.name = morale_font_name
    end
    local morale_font_size = tonumber(controls.party_morale_font_size.tb:GetText())
    if morale_font_size ~= nil then
        v.morale.font.size = morale_font_size
    end
    _apply_color(ui, v.morale.font.color, controls.party_morale_font_color.tb:GetText())
    local morale_font_style = controls.party_morale_font_style:get_value()
    if type(morale_font_style) == "number" then
        v.morale.font.style = morale_font_style
    end
    _apply_color(ui, v.morale.font.outline_color, controls.party_morale_font_outline_color.tb:GetText())

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

    local morale_text = controls.party_morale_text.tb:GetText()
    if type(morale_text) == "string" then
        v.morale.string_format = morale_text
    end
    local morale_text_alignment = controls.party_morale_text_alignment:get_value()
    if type(morale_text_alignment) == "number" then
        v.morale.text_alignment = morale_text_alignment
    end
    local morale_text_margin = tonumber(controls.party_morale_text_margin.tb:GetText())
    if morale_text_margin ~= nil then
        v.morale.text_margin = morale_text_margin
    end
    local bubble_text = controls.party_morale_bubble_text.tb:GetText()
    if type(bubble_text) == "string" then
        v.morale.bubble_format = bubble_text
    end

    local ph = tonumber(controls.party_power_height.tb:GetText())
    if ph ~= nil then
        v.power.height = ph
    end

    local power_font_name = controls.party_power_font_name:get_value()
    if type(power_font_name) == "number" then
        v.power.font.name = power_font_name
    end
    local power_font_size = tonumber(controls.party_power_font_size.tb:GetText())
    if power_font_size ~= nil then
        v.power.font.size = power_font_size
    end
    _apply_color(ui, v.power.font.color, controls.party_power_font_color.tb:GetText())
    local power_font_style = controls.party_power_font_style:get_value()
    if type(power_font_style) == "number" then
        v.power.font.style = power_font_style
    end
    _apply_color(ui, v.power.font.outline_color, controls.party_power_font_outline_color.tb:GetText())

    _apply_color(ui, v.power.color.power, controls.party_power_color.tb:GetText())
    _apply_color(ui, v.power.color.wrath, controls.party_wrath_color.tb:GetText())

    local power_text = controls.party_power_text.tb:GetText()
    if type(power_text) == "string" then
        v.power.string_format = power_text
    end
    local power_text_alignment = controls.party_power_text_alignment:get_value()
    if type(power_text_alignment) == "number" then
        v.power.text_alignment = power_text_alignment
    end
    local power_text_margin = tonumber(controls.party_power_text_margin.tb:GetText())
    if power_text_margin ~= nil then
        v.power.text_margin = power_text_margin
    end
end
