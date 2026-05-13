import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"

local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local ConfigSectionPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_section_page) or
    ConfigSectionPage
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs

local NESTED_TAB_SCALE = 0.78
local NESTED_TAB_FONT_SIZE = 11
local SECTION_FRAME_PADDING = 8

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _set_color(dest, color)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
end

local function _add_number_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_line_edit(key, label,
        function(value)
            local number = tonumber(value)
            if number ~= nil then
                set_value(number)
            end
        end,
        function()
            return tostring(get_value())
        end,
        help_text, full_width)
end

local function _add_text_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_line_edit(key, label,
        function(value)
            set_value(value)
        end,
        function()
            return get_value()
        end,
        help_text, full_width)
end

local function _add_checkbox_field(page, key, label, get_value, set_value, full_width)
    page:add_checkbox(key, label,
        function(value)
            set_value(value == true)
        end,
        function()
            return get_value() == true
        end,
        full_width)
end

local function _add_dropdown_field(page, key, label, labels, values, get_value, set_value, help_text, full_width)
    page:add_dropdown(key, label, labels, values,
        function(value)
            set_value(value)
        end,
        function()
            return get_value()
        end,
        help_text, full_width)
end

local function _add_color_field(page, key, label, get_value, set_value, help_text, full_width)
    page:add_color_picker(key, label,
        function(value)
            set_value(page.hex_to_color(value))
        end,
        function()
            return page.color_to_hex(get_value())
        end,
        help_text, full_width)
end

local function _add_font_identity_controls(page, base_key, font, font_label, size_label, style_label)
    _add_dropdown_field(page, base_key .. "_font_name", font_label or TR["Font"], page.font_name_labels,
        page.font_name_values,
        function()
            return font().name
        end,
        function(value)
            font().name = value
        end)
    _add_number_field(page, base_key .. "_font_size", size_label or TR["Font Size"],
        function()
            return font().size
        end,
        function(value)
            font().size = value
        end)
    _add_dropdown_field(page, base_key .. "_font_style", style_label or TR["Font Style"], page.font_style_labels,
        page.font_style_values,
        function()
            return font().style
        end,
        function(value)
            font().style = value
        end)
end

local function _add_font_color_controls(page, base_key, font, color_label, outline_label)
    _add_color_field(page, base_key .. "_font_color", color_label or TR["Font Color"],
        function()
            return font().color
        end,
        function(color)
            _set_color(font().color, color)
        end)
    _add_color_field(page, base_key .. "_font_outline_color", outline_label or TR["Outline Color"],
        function()
            return font().outline_color
        end,
        function(color)
            _set_color(font().outline_color, color)
        end)
end

local function _bind_outline_visibility(owner_page, colors_page, outline_page, style_key, outline_key)
    local outline = outline_page.controls[outline_key]
    local style = owner_page.controls[style_key]
    local previous_on_changed = style.on_changed

    outline.visible_if = function()
        return style:get_value() == LUI_ENUMS.font_style.OUTLINE
    end

    style.on_changed = function(...)
        if type(previous_on_changed) == "function" then
            previous_on_changed(...)
        end
        outline_page:layout()
        colors_page:layout()
        owner_page:layout()
    end
end

local function _add_vitals_label_controls(page, prefix, label_index, label)
    local key = prefix .. "_label" .. tostring(label_index)

    _add_checkbox_field(page, key .. "_enabled", TR["Enabled"],
        function()
            return label().enabled
        end,
        function(value)
            label().enabled = value
        end, true)
    page:add_row_break()
    _add_text_field(page, key .. "_text", TR["Text"],
        function()
            return label().text
        end,
        function(value)
            label().text = value
        end,
        page.vital_format_help, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_link_to", TR["Section"], page.vitals_label_link_labels,
        page.vitals_label_link_values,
        function()
            return label().link_to
        end,
        function(value)
            label().link_to = value
        end, nil, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values,
        function()
            return label().anchor
        end,
        function(value)
            label().anchor = value
        end)
    _add_dropdown_field(page, key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values,
        function()
            return label().width_mode
        end,
        function(value)
            label().width_mode = value
        end)
    _add_dropdown_field(page, key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values,
        function()
            return label().text_alignment
        end,
        function(value)
            label().text_alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, key .. "_x_offset", TR["X offset"],
        function()
            return label().x_offset
        end,
        function(value)
            label().x_offset = value
        end)
    _add_number_field(page, key .. "_y_offset", TR["Y offset"],
        function()
            return label().y_offset
        end,
        function(value)
            label().y_offset = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, key,
        function()
            return label().font
        end,
        TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_info_form(page, prefix, get)
    _add_checkbox_field(page, prefix .. "_info_enabled", TR["Enabled"],
        function()
            return get().info.enabled
        end,
        function(value)
            get().info.enabled = value
        end, true)
    page:add_row_break()
    _add_number_field(page, prefix .. "_info_height", TR["Height"],
        function()
            return get().info.height
        end,
        function(value)
            get().info.height = value
        end)
    _add_number_field(page, prefix .. "_info_opacity", TR["Opacity"],
        function()
            return get().info.opacity
        end,
        function(value)
            get().info.opacity = value
        end)
end

local function _add_targets_target_label_controls(page, label_index, label)
    local key = "target_targets_target_label" .. tostring(label_index)

    _add_checkbox_field(page, key .. "_enabled", TR["Enabled"],
        function()
            return label().enabled
        end,
        function(value)
            label().enabled = value
        end, true)
    page:add_row_break()
    _add_text_field(page, key .. "_text", TR["Text"],
        function()
            return label().text
        end,
        function(value)
            label().text = value
        end,
        page.vital_format_help, true)
    page:add_row_break()
    _add_dropdown_field(page, key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values,
        function()
            return label().anchor
        end,
        function(value)
            label().anchor = value
        end)
    _add_dropdown_field(page, key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values,
        function()
            return label().width_mode
        end,
        function(value)
            label().width_mode = value
        end)
    _add_dropdown_field(page, key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values,
        function()
            return label().text_alignment
        end,
        function(value)
            label().text_alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, key .. "_x_offset", TR["X offset"],
        function()
            return label().x_offset
        end,
        function(value)
            label().x_offset = value
        end)
    _add_number_field(page, key .. "_y_offset", TR["Y offset"],
        function()
            return label().y_offset
        end,
        function(value)
            label().y_offset = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, key,
        function()
            return label().font
        end,
        TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_standard_frame_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_morale_background_color", TR["Background Color"],
        function()
            return get().morale.color.background
        end,
        function(color)
            _set_color(get().morale.color.background, color)
        end)
    _add_color_field(page, prefix .. "_border_color", TR["Border Color"],
        function()
            return get().frame.border_color
        end,
        function(color)
            _set_color(get().frame.border_color, color)
        end)
    page:add_row_break()
    _add_color_field(page, prefix .. "_info_background_color", TR["Info Background Color"],
        function()
            return get().info.color.background
        end,
        function(color)
            _set_color(get().info.color.background, color)
        end)
end

local function _build_standard_morale_form(page, prefix, get)
    _add_number_field(page, prefix .. "_morale_height", TR["Bar Height"],
        function()
            return get().morale.height
        end,
        function(value)
            get().morale.height = value
        end)
    page:add_row_break()
    _add_text_field(page, prefix .. "_morale_bubble_text", TR["Bubble Format (%B)"],
        function()
            return get().morale.bubble_format
        end,
        function(value)
            get().morale.bubble_format = value
        end,
        page.bubble_format_help, true)
end

local function _build_standard_morale_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_morale_bubble_color", TR["Bubble Color"],
        function()
            return get().morale.color.bubble
        end,
        function(color)
            _set_color(get().morale.color.bubble, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_neutral", TR["Neutral Color"],
        function()
            return get().morale.color.neutral
        end,
        function(color)
            _set_color(get().morale.color.neutral, color)
        end)
    page:add_row_break()
    page:add_title(TR["Step Colors"])
    _add_color_field(page, prefix .. "_morale_color_high", TR["High Color"],
        function()
            return get().morale.color.high
        end,
        function(color)
            _set_color(get().morale.color.high, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_medium", TR["Medium Color"],
        function()
            return get().morale.color.medium
        end,
        function(color)
            _set_color(get().morale.color.medium, color)
        end)
    _add_color_field(page, prefix .. "_morale_color_low", TR["Low Color"],
        function()
            return get().morale.color.low
        end,
        function(color)
            _set_color(get().morale.color.low, color)
        end)
    page:add_row_break()
    _add_color_field(page, prefix .. "_morale_color_critical", TR["Critical Color"],
        function()
            return get().morale.color.critical
        end,
        function(color)
            _set_color(get().morale.color.critical, color)
        end)
    page:add_break()
    page:add_title(TR["Gradient Colors"])
    _add_checkbox_field(page, prefix .. "_morale_gradient", TR["Enable gradient colors"],
        function()
            return get().morale.color.gradient
        end,
        function(value)
            get().morale.color.gradient = value
        end, true)
    page:add_row_break()
    _add_color_field(page, prefix .. "_morale_gradient_full", TR["Full Color"],
        function()
            return get().morale.color.gradient_full
        end,
        function(color)
            _set_color(get().morale.color.gradient_full, color)
        end)
    _add_color_field(page, prefix .. "_morale_gradient_mid", TR["Mid Color"],
        function()
            return get().morale.color.gradient_mid
        end,
        function(color)
            _set_color(get().morale.color.gradient_mid, color)
        end)
    _add_color_field(page, prefix .. "_morale_gradient_low", TR["Low Color"],
        function()
            return get().morale.color.gradient_low
        end,
        function(color)
            _set_color(get().morale.color.gradient_low, color)
        end)
    page:add_row_break()
    page:add_custom(prefix .. "_morale_gradient_preview", 30)
end

local function _build_standard_power_form(page, prefix, get, include_boss_fields)
    if include_boss_fields == true then
        _add_checkbox_field(page, prefix .. "_power_hide", TR["Hide power / wrath"],
            function()
                return get().power.hide
            end,
            function(value)
                get().power.hide = value
            end, true)
        page:add_row_break()
        _add_number_field(page, prefix .. "_power_width", TR["Width"],
            function()
                return get().power.width
            end,
            function(value)
                get().power.width = value
            end)
        _add_number_field(page, prefix .. "_power_height", TR["Bar Height"],
            function()
                return get().power.height
            end,
            function(value)
                get().power.height = value
            end)
        page:add_row_break()
        _add_dropdown_field(page, prefix .. "_power_side", TR["Side"], page.side_labels, page.side_values,
            function()
                return get().power.side
            end,
            function(value)
                get().power.side = value
            end)
        page:add_row_break()
    else
        _add_number_field(page, prefix .. "_power_height", TR["Bar Height"],
            function()
                return get().power.height
            end,
            function(value)
                get().power.height = value
            end)
    end
end

local function _build_standard_power_colors_form(page, prefix, get)
    _add_color_field(page, prefix .. "_power_color", TR["Power Color"],
        function()
            return get().power.color.power
        end,
        function(color)
            _set_color(get().power.color.power, color)
        end)
    _add_color_field(page, prefix .. "_wrath_color", TR["Wrath Color"],
        function()
            return get().power.color.wrath
        end,
        function(color)
            _set_color(get().power.color.wrath, color)
        end)
end

local function _build_buffs_form(page, prefix, get)
    _add_dropdown_field(page, prefix .. "_buff_slot", TR["Buffs Slot"], page.vitals_effect_slot_labels,
        page.vitals_effect_slot_values,
        function()
            return get().effects.buffs.slot
        end,
        function(value)
            get().effects.buffs.slot = value
        end)
    _add_dropdown_field(page, prefix .. "_buff_alignment", TR["Alignment"], page.side_labels, page.side_values,
        function()
            return get().effects.buffs.alignment
        end,
        function(value)
            get().effects.buffs.alignment = value
        end)
    page:add_row_break()
    _add_number_field(page, prefix .. "_buff_size", TR["Icon Size"],
        function()
            return get().effects.buffs.icon_size
        end,
        function(value)
            get().effects.buffs.icon_size = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_buff_timer",
        function()
            return get().effects.buffs.timer_font
        end,
        TR["Timer Font"], TR["Timer Font Size"], TR["Timer Font Style"])
end

local function _build_debuffs_form(page, prefix, get)
    _add_dropdown_field(page, prefix .. "_debuff_slot", TR["Debuffs Slot"], page.vitals_effect_slot_labels,
        page.vitals_effect_slot_values,
        function()
            return get().effects.debuffs.slot
        end,
        function(value)
            get().effects.debuffs.slot = value
        end)
    _add_dropdown_field(page, prefix .. "_debuff_alignment", TR["Alignment"], page.side_labels, page.side_values,
        function()
            return get().effects.debuffs.alignment
        end,
        function(value)
            get().effects.debuffs.alignment = value
        end)
    page:add_row_break()
    _add_checkbox_field(page, prefix .. "_debuff_track_curable", TR["Track curable debuffs"],
        function()
            return get().effects.debuffs.track_curable
        end,
        function(value)
            get().effects.debuffs.track_curable = value
        end, false)
    _add_checkbox_field(page, prefix .. "_debuff_track_noncurable", TR["Track non-curable debuffs"],
        function()
            return get().effects.debuffs.track_noncurable
        end,
        function(value)
            get().effects.debuffs.track_noncurable = value
        end, false)
    page:add_row_break()
    _add_number_field(page, prefix .. "_debuff_size", TR["Icon Size"],
        function()
            return get().effects.debuffs.icon_size
        end,
        function(value)
            get().effects.debuffs.icon_size = value
        end)
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_debuff_timer",
        function()
            return get().effects.debuffs.timer_font
        end,
        TR["Timer Font"], TR["Timer Font Size"], TR["Timer Font Style"])
end

local function _build_standard_text_colors_form(page, prefix, get)
    page:add_title(TR["Text 1"])
    _add_font_color_controls(page, prefix .. "_label1",
        function()
            return get().labels[1].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 2"])
    _add_font_color_controls(page, prefix .. "_label2",
        function()
            return get().labels[2].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 3"])
    _add_font_color_controls(page, prefix .. "_label3",
        function()
            return get().labels[3].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 4"])
    _add_font_color_controls(page, prefix .. "_label4",
        function()
            return get().labels[4].font
        end,
        TR["Font Color"], TR["Outline Color"])
end

local function _build_targets_target_text_colors_form(page, get)
    page:add_title(TR["Text 1"])
    _add_font_color_controls(page, "target_targets_target_label1",
        function()
            return get().labels[1].font
        end,
        TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Text 2"])
    _add_font_color_controls(page, "target_targets_target_label2",
        function()
            return get().labels[2].font
        end,
        TR["Font Color"], TR["Outline Color"])
end

local function _build_effects_colors_form(page, prefix, get)
    page:add_title(TR["Buffs"])
    _add_font_color_controls(page, prefix .. "_buff_timer",
        function()
            return get().effects.buffs.timer_font
        end,
        TR["Timer Font Color"], TR["Timer Outline Color"])
    page:add_break()
    page:add_title(TR["Debuffs"])
    _add_font_color_controls(page, prefix .. "_debuff_timer",
        function()
            return get().effects.debuffs.timer_font
        end,
        TR["Timer Font Color"], TR["Timer Outline Color"])
end

local function _new_standard_colors_section(window, refresh_preview_fn, prefix, get, include_effects)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_frame_colors_form(frame, prefix, get)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_morale_colors_form(morale, prefix, get)

    local power = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_power_colors_form(power, prefix, get)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_text_colors_form(text, prefix, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page._frame_page = frame
    page._morale_page = morale
    page._power_page = power
    page._text_page = text
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Morale"], "morale", morale)
    page:add_tab(TR["Power / Wrath"], "power", power)
    page:add_tab(TR["Text"], "text", text)

    if include_effects == true then
        local effects = ConfigContent(window, 3, refresh_preview_fn)
        _build_effects_colors_form(effects, prefix, get)
        page._effects_page = effects
        page:add_tab(TR["Effects"], "effects", effects)
    end

    return page
end

local function _new_targets_target_colors_section(window, refresh_preview_fn, get)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    _add_color_field(frame, "target_targets_target_background_color", TR["Background Color"],
        function()
            return get().color.background
        end,
        function(color)
            _set_color(get().color.background, color)
        end)
    _add_color_field(frame, "target_targets_target_border_color", TR["Border Color"],
        function()
            return get().color.border
        end,
        function(color)
            _set_color(get().color.border, color)
        end)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    _add_color_field(morale, "target_targets_target_bubble_color", TR["Bubble Color"],
        function()
            return get().color.bubble
        end,
        function(color)
            _set_color(get().color.bubble, color)
        end)
    _add_color_field(morale, "target_targets_target_color_neutral", TR["Neutral Color"],
        function()
            return get().color.neutral
        end,
        function(color)
            _set_color(get().color.neutral, color)
        end)
    morale:add_row_break()
    morale:add_break()
    morale:add_title(TR["Step Colors"])
    _add_color_field(morale, "target_targets_target_color_high", TR["High Color"],
        function()
            return get().color.high
        end,
        function(color)
            _set_color(get().color.high, color)
        end)
    _add_color_field(morale, "target_targets_target_color_medium", TR["Medium Color"],
        function()
            return get().color.medium
        end,
        function(color)
            _set_color(get().color.medium, color)
        end)
    _add_color_field(morale, "target_targets_target_color_low", TR["Low Color"],
        function()
            return get().color.low
        end,
        function(color)
            _set_color(get().color.low, color)
        end)
    morale:add_row_break()
    _add_color_field(morale, "target_targets_target_color_critical", TR["Critical Color"],
        function()
            return get().color.critical
        end,
        function(color)
            _set_color(get().color.critical, color)
        end)
    morale:add_break()
    morale:add_title(TR["Gradient Colors"])
    _add_checkbox_field(morale, "target_targets_target_color_gradient", TR["Enable gradient colors"],
        function()
            return get().color.gradient
        end,
        function(value)
            get().color.gradient = value
        end, true)
    morale:add_row_break()
    _add_color_field(morale, "target_targets_target_color_gradient_full", TR["Full Color"],
        function()
            return get().color.gradient_full
        end,
        function(color)
            _set_color(get().color.gradient_full, color)
        end)
    _add_color_field(morale, "target_targets_target_color_gradient_mid", TR["Mid Color"],
        function()
            return get().color.gradient_mid
        end,
        function(color)
            _set_color(get().color.gradient_mid, color)
        end)
    _add_color_field(morale, "target_targets_target_color_gradient_low", TR["Low Color"],
        function()
            return get().color.gradient_low
        end,
        function(color)
            _set_color(get().color.gradient_low, color)
        end)
    morale:add_row_break()
    morale:add_custom("target_targets_target_color_gradient_preview", 30)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_targets_target_text_colors_form(text, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page._frame_page = frame
    page._morale_page = morale
    page._text_page = text
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Morale"], "morale", morale)
    page:add_tab(TR["Text"], "text", text)
    return page
end

local function _bind_standard_outline_visibility(owner_page, colors_page, prefix, include_effects)
    for i = 1, 4 do
        _bind_outline_visibility(owner_page, colors_page, colors_page._text_page,
            prefix .. "_label" .. tostring(i) .. "_font_style",
            prefix .. "_label" .. tostring(i) .. "_font_outline_color")
    end

    if include_effects == true then
        _bind_outline_visibility(owner_page, colors_page, colors_page._effects_page, prefix .. "_buff_timer_font_style",
            prefix .. "_buff_timer_font_outline_color")
        _bind_outline_visibility(owner_page, colors_page, colors_page._effects_page,
            prefix .. "_debuff_timer_font_style", prefix .. "_debuff_timer_font_outline_color")
    end
end

local function _bind_targets_target_outline_visibility(owner_page, colors_page)
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, "target_targets_target_label1_font_style",
        "target_targets_target_label1_font_outline_color")
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, "target_targets_target_label2_font_style",
        "target_targets_target_label2_font_outline_color")
end

local function _new_label_page(window, refresh_preview_fn, columns, prefix, label_index, label)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_vitals_label_controls(page, prefix, label_index, label)
    return page
end

local function _new_targets_target_label_page(window, refresh_preview_fn, columns, label_index, label)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_targets_target_label_controls(page, label_index, label)
    return page
end

local function _new_texts_section(window, refresh_preview_fn, prefix, get)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Text 1"], "label1",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 1, function()
            return get().labels[1]
        end))
    page:add_tab(TR["Text 2"], "label2",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 2, function()
            return get().labels[2]
        end))
    page:add_tab(TR["Text 3"], "label3",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 3, function()
            return get().labels[3]
        end))
    page:add_tab(TR["Text 4"], "label4",
        _new_label_page(window, refresh_preview_fn, 3, prefix, 4, function()
            return get().labels[4]
        end))
    return page
end

local function _new_targets_target_texts_section(window, refresh_preview_fn, get)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Text 1"], "label1",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 1, function()
            return get().labels[1]
        end))
    page:add_tab(TR["Text 2"], "label2",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 2, function()
            return get().labels[2]
        end))
    return page
end

local function _new_effects_section(window, refresh_preview_fn, prefix, get)
    local buffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_buffs_form(buffs, prefix, get)

    local debuffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_debuffs_form(debuffs, prefix, get)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Buffs"], "buffs", buffs)
    page:add_tab(TR["Debuffs"], "debuffs", debuffs)
    return page
end

local function _new_self_unit_page(window, root)
    local get = function()
        return root._settings.self.vitals
    end
    local page = ConfigSectionPage(window, "self_vitals_preview", 207, function(win)
        win:update_self_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    _add_number_field(frame, "self_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    _add_number_field(frame, "self_border_width", TR["Border Width"], function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    _add_number_field(frame, "self_effects_height", TR["Effects Height"], function() return get().frame.effects_height end,
        function(value) get().frame.effects_height = value end)
    frame:add_row_break()
    _add_number_field(frame, "self_incombat_opacity", TR["In-combat opacity"], function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    _add_number_field(frame, "self_outcombat_opacity", TR["Out-of-combat opacity"], function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    _add_checkbox_field(frame, "self_ressource_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    _add_number_field(frame, "self_ressource_background_dimming", TR["Dimming"], function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "self", get, true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "self", get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "self", get, false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = ConfigContent(window, 4, page.refresh_preview)
    _build_info_form(info, "self", get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "self", get))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "self", get))
    _bind_standard_outline_visibility(page, colors, "self", true)

    return page
end

local function _new_target_unit_page(window, root)
    local get = function()
        return root._settings.target.vitals
    end
    local page = ConfigSectionPage(window, "target_vitals_preview", 222, function(win)
        win:update_target_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    _add_number_field(frame, "target_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    _add_number_field(frame, "target_border_width", TR["Border Width"], function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    _add_number_field(frame, "target_effects_height", TR["Effects Height"], function() return get().frame.effects_height end,
        function(value) get().frame.effects_height = value end)
    frame:add_row_break()
    _add_number_field(frame, "target_incombat_opacity", TR["In-combat opacity"], function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    _add_number_field(frame, "target_outcombat_opacity", TR["Out-of-combat opacity"], function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    _add_checkbox_field(frame, "target_ressource_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    _add_number_field(frame, "target_ressource_background_dimming", TR["Dimming"], function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "target", get, true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target", get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "target", get, false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = ConfigContent(window, 4, page.refresh_preview)
    _build_info_form(info, "target", get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target", get))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target", get))
    _bind_standard_outline_visibility(page, colors, "target", true)

    return page
end

local function _new_boss_unit_page(window, root)
    local get = function()
        return root._settings.target.boss_vitals
    end
    local page = ConfigSectionPage(window, "target_boss_vitals_preview", 178, function(win)
        win:update_target_boss_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    _add_number_field(frame, "target_boss_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    _add_number_field(frame, "target_boss_border_width", TR["Border Width"], function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    _add_number_field(frame, "target_boss_effects_height", TR["Effects Height"], function() return get().frame.effects_height end,
        function(value) get().frame.effects_height = value end)
    frame:add_row_break()
    _add_number_field(frame, "target_boss_incombat_opacity", TR["In-combat opacity"], function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    _add_number_field(frame, "target_boss_outcombat_opacity", TR["Out-of-combat opacity"], function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    _add_checkbox_field(frame, "target_boss_ressource_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    _add_number_field(frame, "target_boss_ressource_background_dimming", TR["Dimming"], function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "target_boss", get, true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target_boss", get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "target_boss", get, true)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = ConfigContent(window, 4, page.refresh_preview)
    _build_info_form(info, "target_boss", get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target_boss", get))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target_boss", get))
    _bind_standard_outline_visibility(page, colors, "target_boss", true)

    return page
end

local function _new_targets_target_unit_page(window, root)
    local get = function()
        return root._settings.target.vitals.targets_target
    end
    local page = ConfigSectionPage(window, "target_targets_target_preview", 133, function(win)
        win:update_target_targets_target_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    _add_number_field(frame, "target_targets_target_width", TR["Frame Width"], function() return get().width end,
        function(value) get().width = value end)
    _add_number_field(frame, "target_targets_target_height", TR["Bar Height"], function() return get().height end,
        function(value) get().height = value end)
    _add_number_field(frame, "target_targets_target_border_width", TR["Border Width"], function() return get().border_width end,
        function(value) get().border_width = value end)
    frame:add_row_break()
    _add_checkbox_field(frame, "target_targets_target_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    _add_number_field(frame, "target_targets_target_background_dimming", TR["Dimming"], function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    frame:add_row_break()
    _add_text_field(frame, "target_targets_target_bubble_text", TR["Bubble Format (%B)"],
        function() return get().bubble_format end,
        function(value) get().bubble_format = value end,
        frame.bubble_format_help, true)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_targets_target_colors_section(window, page.refresh_preview, get)
    page:add_tab(TR["Colors"], "colors", colors)

    page:add_tab(TR["Texts"], "texts", _new_targets_target_texts_section(window, page.refresh_preview, get))
    _bind_targets_target_outline_visibility(page, colors)

    return page
end

local function _new_party_unit_page(window, root)
    local get = function()
        return root._settings.party
    end
    local page = ConfigSectionPage(window, "party_vitals_preview", 178, function(win)
        win:update_party_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame.on_scroll_changed = function()
        window:update_party_vitals_preview()
    end
    _add_number_field(frame, "party_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    _add_number_field(frame, "party_border_width", TR["Border Width"], function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    _add_number_field(frame, "party_rows", TR["Rows per Column"], function() return get().layout.rows end,
        function(value) get().layout.rows = value end)
    frame:add_row_break()
    _add_number_field(frame, "party_spacing_x", TR["Column Spacing"], function() return get().layout.spacing_x end,
        function(value) get().layout.spacing_x = value end)
    _add_number_field(frame, "party_spacing_y", TR["Row Spacing"], function() return get().layout.spacing_y end,
        function(value) get().layout.spacing_y = value end)
    frame:add_row_break()
    _add_number_field(frame, "party_incombat_opacity", TR["In-combat opacity"], function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    _add_number_field(frame, "party_outcombat_opacity", TR["Out-of-combat opacity"], function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    frame:add_row_break()
    _add_checkbox_field(frame, "party_ressource_background_matches_missing", TR["Matching background"],
        function() return get().background_matches_missing end,
        function(value) get().background_matches_missing = value end)
    _add_number_field(frame, "party_ressource_background_dimming", TR["Dimming"], function() return get().background_dimming end,
        function(value) get().background_dimming = value end)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "party", get, false)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "party", get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "party", get, false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = ConfigContent(window, 4, page.refresh_preview)
    _build_info_form(info, "party", get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "party", get))

    local icons = ConfigContent(window, 4, page.refresh_preview)
    _add_checkbox_field(icons, "party_class_icon_enabled", TR["Show class icon"],
        function() return get().class_icon.enabled end,
        function(value) get().class_icon.enabled = value end, true)
    icons:add_row_break()
    _add_number_field(icons, "party_class_icon_size", TR["Icon Size"], function() return get().class_icon.size end,
        function(value) get().class_icon.size = value end)
    icons:add_row_break()
    _add_number_field(icons, "party_class_icon_x", TR["Icon X"], function() return get().class_icon.x end,
        function(value) get().class_icon.x = value end)
    _add_number_field(icons, "party_class_icon_y", TR["Icon Y"], function() return get().class_icon.y end,
        function(value) get().class_icon.y = value end)
    icons:add_row_break()
    _add_checkbox_field(icons, "party_leader_icon_enabled", TR["Show leader icon"],
        function() return get().leader_icon.enabled end,
        function(value) get().leader_icon.enabled = value end, true)
    icons:add_row_break()
    _add_number_field(icons, "party_leader_icon_size", TR["Leader Icon Size"], function() return get().leader_icon.size end,
        function(value) get().leader_icon.size = value end)
    icons:add_row_break()
    _add_number_field(icons, "party_leader_icon_x", TR["Leader Icon X"], function() return get().leader_icon.x end,
        function(value) get().leader_icon.x = value end)
    _add_number_field(icons, "party_leader_icon_y", TR["Leader Icon Y"], function() return get().leader_icon.y end,
        function(value) get().leader_icon.y = value end)
    page:add_tab(TR["Icons"], "icons", icons)
    _bind_standard_outline_visibility(page, colors, "party", false)

    return page
end

local function _new_general_page(window, root)
    local page = ConfigContent(window, 4)
    page:add_title(TR["General"])
    page:add_checkbox("self_vitals_enabled", TR["Enable self vitals"],
        function(value)
            root._settings.self.vitals.enabled = value == true
        end,
        function()
            return root._settings.self.vitals.enabled == true
        end)
    page:add_checkbox("target_vitals_enabled", TR["Enable target vitals"],
        function(value)
            root._settings.target.vitals.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.enabled == true
        end)
    page:add_checkbox("target_boss_enabled", TR["Enable boss vitals"],
        function(value)
            root._settings.target.boss_vitals.enabled = value == true
        end,
        function()
            return root._settings.target.boss_vitals.enabled == true
        end)
    page:add_checkbox("target_targets_target_enabled", TR["Enable target's target"],
        function(value)
            root._settings.target.vitals.targets_target.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.targets_target.enabled == true
        end)
    page:add_checkbox("party_vitals_enabled", TR["Enable party vitals"],
        function(value)
            root._settings.party.enabled = value == true
        end,
        function()
            return root._settings.party.enabled == true
        end)
    return page
end

VitalsPage = class(ConfigTabs)

function VitalsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))

    self:add_tab(TR["General"], "general", _new_general_page(window, self))
    self:add_tab(TR["Self"], "self", _new_self_unit_page(window, self))
    self:add_tab(TR["Target"], "target", _new_target_unit_page(window, self))
    self:add_tab(TR["Boss"], "boss", _new_boss_unit_page(window, self))
    self:add_tab(TR["Target's Target"], "target_targets_target", _new_targets_target_unit_page(window, self))
    self:add_tab(TR["Party"], "party", _new_party_unit_page(window, self))
end

function VitalsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))
end
