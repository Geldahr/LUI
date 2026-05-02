Cooldowns = {
    key = "cooldowns",
    text = TR["Cooldowns"],
}

function Cooldowns.load(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local cd = s.self.cooldowns

    page.loading = true
    controls.cd_enabled.cb:SetChecked(cd.enabled == true)
    controls.cd_threshold.tb:SetText(tostring(cd.threshold))
    controls.cd_min_base_cooldown.tb:SetText(tostring(cd.min_base_cooldown or 0))
    controls.cd_item_w.tb:SetText(tostring(cd.item_w))
    controls.cd_item_h.tb:SetText(tostring(cd.item_h))
    controls.cd_spacing.tb:SetText(tostring(cd.spacing))
    controls.cd_border_width.tb:SetText(tostring(cd.border_width))
    controls.cd_columns.tb:SetText(tostring(cd.columns))
    controls.cd_rows.tb:SetText(tostring(cd.rows))
    controls.cd_flow:set_value(cd.flow)
    controls.cd_icon_side:set_value(cd.icon_side)
    controls.cd_bar_mode:set_value(cd.bar_mode)
    controls.cd_bar_expire_towards:set_value(cd.bar_expire_towards)
    controls.cd_bg_color.tb:SetText(ui.color_to_hex(cd.color.background))
    controls.cd_bar_color.tb:SetText(ui.color_to_hex(cd.color.bar))
    controls.cd_border_color.tb:SetText(ui.color_to_hex(cd.color.border))

    controls.cd_time_format:set_value(cd.time_format)
    controls.cd_text_margin.tb:SetText(tostring(cd.text_margin))
    controls.cd_name_max_chars.tb:SetText(tostring(cd.name_max_chars))

    controls.cd_font_name:set_value(cd.font.name)
    controls.cd_font_size.tb:SetText(tostring(cd.font.size))
    controls.cd_font_color.tb:SetText(ui.color_to_hex(cd.font.color))
    controls.cd_font_style:set_value(cd.font.style)
    controls.cd_font_outline_color.tb:SetText(ui.color_to_hex(cd.font.outline_color))

    controls.cd_whitelist.tb:SetText(tostring(cd.whitelist or ""))
    controls.cd_blacklist.tb:SetText(tostring(cd.blacklist or ""))
    page.loading = false
    page:layout()
end

function Cooldowns.apply(page, s, ui)
    if page == nil then
        return
    end

    local controls = page.controls
    local cd = s.self.cooldowns

    cd.enabled = controls.cd_enabled.cb:IsChecked() == true

    local threshold = tonumber(controls.cd_threshold.tb:GetText())
    if threshold ~= nil then
        cd.threshold = threshold
    end
    local min_base_cooldown = tonumber(controls.cd_min_base_cooldown.tb:GetText())
    if min_base_cooldown ~= nil then
        cd.min_base_cooldown = min_base_cooldown
    end

    local item_w = tonumber(controls.cd_item_w.tb:GetText())
    if item_w ~= nil then
        cd.item_w = item_w
    end
    local item_h = tonumber(controls.cd_item_h.tb:GetText())
    if item_h ~= nil then
        cd.item_h = item_h
    end
    local spacing = tonumber(controls.cd_spacing.tb:GetText())
    if spacing ~= nil then
        cd.spacing = spacing
    end
    local border_width = tonumber(controls.cd_border_width.tb:GetText())
    if border_width ~= nil then
        cd.border_width = border_width
    end
    local columns = tonumber(controls.cd_columns.tb:GetText())
    if columns ~= nil then
        cd.columns = columns
    end
    local rows = tonumber(controls.cd_rows.tb:GetText())
    if rows ~= nil then
        cd.rows = rows
    end

    cd.flow = controls.cd_flow:get_value()
    cd.icon_side = controls.cd_icon_side:get_value()
    cd.bar_mode = controls.cd_bar_mode:get_value()
    cd.bar_expire_towards = controls.cd_bar_expire_towards:get_value()

    local bg_color = ui.hex_to_color(controls.cd_bg_color.tb:GetText())
    if bg_color ~= nil then
        cd.color.background = bg_color
    end
    local bar_color = ui.hex_to_color(controls.cd_bar_color.tb:GetText())
    if bar_color ~= nil then
        cd.color.bar = bar_color
    end
    local border_color = ui.hex_to_color(controls.cd_border_color.tb:GetText())
    if border_color ~= nil then
        cd.color.border = border_color
    end

    cd.time_format = controls.cd_time_format:get_value()
    local text_margin = tonumber(controls.cd_text_margin.tb:GetText())
    if text_margin ~= nil then
        cd.text_margin = text_margin
    end
    local name_max_chars = tonumber(controls.cd_name_max_chars.tb:GetText())
    if name_max_chars ~= nil then
        cd.name_max_chars = name_max_chars
    end

    cd.font.name = controls.cd_font_name:get_value()
    local font_size = tonumber(controls.cd_font_size.tb:GetText())
    if font_size ~= nil then
        cd.font.size = font_size
    end
    local font_color = ui.hex_to_color(controls.cd_font_color.tb:GetText())
    if font_color ~= nil then
        cd.font.color = font_color
    end
    cd.font.style = controls.cd_font_style:get_value()
    local outline_color = ui.hex_to_color(controls.cd_font_outline_color.tb:GetText())
    if outline_color ~= nil then
        cd.font.outline_color = outline_color
    end

    cd.whitelist = controls.cd_whitelist.tb:GetText() or ""
    cd.blacklist = controls.cd_blacklist.tb:GetText() or ""
end
