import "LUI.src.UI.Settings.Tabs.Target.target_targets_target_page"

TargetTargetsTarget = {
    key = "target_targets_target",
    text = TR("Target's Target"),
}

local function _page(window)
    return window ~= nil and window._tab_pages ~= nil and window._tab_pages.target_targets_target or nil
end

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

function TargetTargetsTarget.create_page(window)
    return TargetTargetsTargetPage(window)
end

function TargetTargetsTarget.load(window, s, ui)
    local page = _page(window)
    if page == nil then
        return
    end

    local controls = page.controls
    local v = s.target.vitals.targets_target

    page.loading = true
    controls.target_targets_target_width.tb:SetText(tostring(v.width))
    controls.target_targets_target_height.tb:SetText(tostring(v.height))
    controls.target_targets_target_border_width.tb:SetText(tostring(v.border_width))
    controls.target_targets_target_font_name:set_value(v.font.name)
    controls.target_targets_target_font_size.tb:SetText(tostring(v.font.size))
    controls.target_targets_target_font_color.tb:SetText(ui.color_to_hex(v.font.color))
    controls.target_targets_target_font_style:set_value(v.font.style)
    controls.target_targets_target_font_outline_color.tb:SetText(ui.color_to_hex(v.font.outline_color))

    controls.target_targets_target_text.tb:SetText(tostring(v.text))
    controls.target_targets_target_bubble_text.tb:SetText(tostring(v.bubble_format))
    controls.target_targets_target_text_alignment:set_value(v.text_alignment)
    controls.target_targets_target_text_margin.tb:SetText(tostring(v.text_margin))

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

function TargetTargetsTarget.apply(window, s, ui)
    local page = _page(window)
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

    v.font.name = controls.target_targets_target_font_name:get_value()
    local tt_font_size = tonumber(controls.target_targets_target_font_size.tb:GetText())
    if tt_font_size ~= nil then
        v.font.size = tt_font_size
    end
    _apply_color(ui, v.font.color, controls.target_targets_target_font_color.tb:GetText())
    v.font.style = controls.target_targets_target_font_style:get_value()
    _apply_color(ui, v.font.outline_color, controls.target_targets_target_font_outline_color.tb:GetText())

    v.text = controls.target_targets_target_text.tb:GetText()
    v.bubble_format = controls.target_targets_target_bubble_text.tb:GetText()
    v.text_alignment = controls.target_targets_target_text_alignment:get_value()
    local tt_text_margin = tonumber(controls.target_targets_target_text_margin.tb:GetText())
    if tt_text_margin ~= nil then
        v.text_margin = tt_text_margin
    end

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
