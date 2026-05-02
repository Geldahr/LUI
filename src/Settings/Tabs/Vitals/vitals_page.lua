import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Tabs.Self.self_vitals"
import "LUI.src.Settings.Tabs.Target.target_vitals"
import "LUI.src.Settings.Tabs.Target.target_boss_vitals"
import "LUI.src.Settings.Tabs.Target.target_targets_target"
import "LUI.src.Settings.Tabs.Party.party_layout"
import "LUI.src.Settings.Tabs.Party.party_vitals"

local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local ConfigSectionPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_section_page) or
    ConfigSectionPage
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local SelfVitals = LUI.src.Settings.Tabs.Self.SelfVitals
local TargetVitals = LUI.src.Settings.Tabs.Target.TargetVitals
local TargetBossVitals = LUI.src.Settings.Tabs.Target.TargetBossVitals
local TargetTargetsTarget = LUI.src.Settings.Tabs.Target.TargetTargetsTarget
local PartyLayout = LUI.src.Settings.Tabs.Party.PartyLayout
local PartyVitals = LUI.src.Settings.Tabs.Party.PartyVitals

local NESTED_TAB_SCALE = 0.78
local NESTED_TAB_FONT_SIZE = 11
local SECTION_FRAME_PADDING = 8

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _add_font_identity_controls(page, base_key, font_label, size_label, style_label)
    page:add_dropdown(base_key .. "_font_name", font_label or TR["Font"], page.font_name_labels,
        page.font_name_values)
    page:add_text(base_key .. "_font_size", size_label or TR["Font Size"])
    page:add_dropdown(base_key .. "_font_style", style_label or TR["Font Style"], page.font_style_labels,
        page.font_style_values)
end

local function _add_font_color_controls(page, base_key, color_label, outline_label)
    page:add_text(base_key .. "_font_color", color_label or TR["Font Color"], true)
    page:add_text(base_key .. "_font_outline_color", outline_label or TR["Outline Color"], true)
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

local function _add_vitals_label_controls(page, prefix, bar_key, label_index)
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)

    page:add_checkbox(key .. "_enabled", TR["Enabled"], true)
    page:add_row_break()
    page:add_text(key .. "_text", TR["Text"], false, page.vital_format_help, true)
    page:add_row_break()
    page:add_dropdown(key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values)
    page:add_dropdown(key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values)
    page:add_dropdown(key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    page:add_row_break()
    page:add_text(key .. "_x_offset", TR["X offset"])
    page:add_text(key .. "_y_offset", TR["Y offset"])
    page:add_row_break()
    _add_font_identity_controls(page, key, TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _add_targets_target_label_controls(page, label_index)
    local key = "target_targets_target_label" .. tostring(label_index)

    page:add_checkbox(key .. "_enabled", TR["Enabled"], true)
    page:add_row_break()
    page:add_text(key .. "_text", TR["Text"], false, page.vital_format_help, true)
    page:add_row_break()
    page:add_dropdown(key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values)
    page:add_dropdown(key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values)
    page:add_dropdown(key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    page:add_row_break()
    page:add_text(key .. "_x_offset", TR["X offset"])
    page:add_text(key .. "_y_offset", TR["Y offset"])
    page:add_row_break()
    _add_font_identity_controls(page, key, TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_standard_frame_colors_form(page, prefix)
    page:add_text(prefix .. "_morale_background_color", TR["Background Color"], true)
    page:add_text(prefix .. "_border_color", TR["Border Color"], true)
end

local function _build_standard_morale_form(page, prefix)
    page:add_text(prefix .. "_morale_height", TR["Bar Height"])
    page:add_row_break()
    page:add_text(prefix .. "_morale_bubble_text", TR["Bubble Format (%B)"], false, page.bubble_format_help, true)
end

local function _build_standard_morale_colors_form(page, prefix)
    page:add_text(prefix .. "_morale_bubble_color", TR["Bubble Color"], true)
    page:add_text(prefix .. "_morale_color_neutral", TR["Neutral Color"], true)
    page:add_row_break()
    page:add_title(TR["Step Colors"])
    page:add_text(prefix .. "_morale_color_high", TR["High Color"], true)
    page:add_text(prefix .. "_morale_color_medium", TR["Medium Color"], true)
    page:add_text(prefix .. "_morale_color_low", TR["Low Color"], true)
    page:add_row_break()
    page:add_text(prefix .. "_morale_color_critical", TR["Critical Color"], true)
    page:add_break()
    page:add_title(TR["Gradient Colors"])
    page:add_checkbox(prefix .. "_morale_gradient", TR["Enable gradient colors"], true)
    page:add_row_break()
    page:add_text(prefix .. "_morale_gradient_full", TR["Full Color"], true)
    page:add_text(prefix .. "_morale_gradient_mid", TR["Mid Color"], true)
    page:add_text(prefix .. "_morale_gradient_low", TR["Low Color"], true)
    page:add_row_break()
    page:add_custom(prefix .. "_morale_gradient_preview", 30)
end

local function _build_standard_power_form(page, prefix, include_boss_fields)
    if include_boss_fields == true then
        page:add_checkbox(prefix .. "_power_hide", TR["Hide power / wrath"], true)
        page:add_row_break()
        page:add_text(prefix .. "_power_width", TR["Width"])
        page:add_text(prefix .. "_power_height", TR["Bar Height"])
        page:add_row_break()
        page:add_dropdown(prefix .. "_power_side", TR["Side"], page.side_labels, page.side_values)
        page:add_row_break()
    else
        page:add_text(prefix .. "_power_height", TR["Bar Height"])
    end
end

local function _build_standard_power_colors_form(page, prefix)
    page:add_text(prefix .. "_power_color", TR["Power Color"], true)
    page:add_text(prefix .. "_wrath_color", TR["Wrath Color"], true)
end

local function _build_buffs_form(page, prefix)
    page:add_text(prefix .. "_buff_size", TR["Icon Size"])
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_buff_timer", TR["Timer Font"], TR["Timer Font Size"],
        TR["Timer Font Style"])
end

local function _build_debuffs_form(page, prefix)
    page:add_checkbox(prefix .. "_debuff_track_curable", TR["Track curable debuffs"], false)
    page:add_checkbox(prefix .. "_debuff_track_noncurable", TR["Track non-curable debuffs"], false)
    page:add_row_break()
    page:add_text(prefix .. "_debuff_size", TR["Icon Size"])
    page:add_row_break()
    _add_font_identity_controls(page, prefix .. "_debuff_timer", TR["Timer Font"], TR["Timer Font Size"],
        TR["Timer Font Style"])
end

local function _build_standard_text_colors_form(page, prefix)
    page:add_title(TR["Morale 1"])
    _add_font_color_controls(page, prefix .. "_morale_label1", TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Morale 2"])
    _add_font_color_controls(page, prefix .. "_morale_label2", TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Power 1"])
    _add_font_color_controls(page, prefix .. "_power_label1", TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Power 2"])
    _add_font_color_controls(page, prefix .. "_power_label2", TR["Font Color"], TR["Outline Color"])
end

local function _build_targets_target_text_colors_form(page)
    page:add_title(TR["Label 1"])
    _add_font_color_controls(page, "target_targets_target_label1", TR["Font Color"], TR["Outline Color"])
    page:add_break()
    page:add_title(TR["Label 2"])
    _add_font_color_controls(page, "target_targets_target_label2", TR["Font Color"], TR["Outline Color"])
end

local function _build_effects_colors_form(page, prefix)
    page:add_title(TR["Buffs"])
    _add_font_color_controls(page, prefix .. "_buff_timer", TR["Timer Font Color"], TR["Timer Outline Color"])
    page:add_break()
    page:add_title(TR["Debuffs"])
    _add_font_color_controls(page, prefix .. "_debuff_timer", TR["Timer Font Color"], TR["Timer Outline Color"])
end

local function _new_standard_colors_section(window, refresh_preview_fn, prefix, include_effects)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_frame_colors_form(frame, prefix)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_morale_colors_form(morale, prefix)

    local power = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_power_colors_form(power, prefix)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_standard_text_colors_form(text, prefix)

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
        _build_effects_colors_form(effects, prefix)
        page._effects_page = effects
        page:add_tab(TR["Effects"], "effects", effects)
    end

    return page
end

local function _new_targets_target_colors_section(window, refresh_preview_fn)
    local frame = ConfigContent(window, 3, refresh_preview_fn)
    frame:add_text("target_targets_target_background_color", TR["Background Color"], true)
    frame:add_text("target_targets_target_border_color", TR["Border Color"], true)

    local morale = ConfigContent(window, 3, refresh_preview_fn)
    morale:add_text("target_targets_target_bubble_color", TR["Bubble Color"], true)
    morale:add_text("target_targets_target_color_neutral", TR["Neutral Color"], true)
    morale:add_row_break()
    morale:add_break()
    morale:add_title(TR["Step Colors"])
    morale:add_text("target_targets_target_color_high", TR["High Color"], true)
    morale:add_text("target_targets_target_color_medium", TR["Medium Color"], true)
    morale:add_text("target_targets_target_color_low", TR["Low Color"], true)
    morale:add_row_break()
    morale:add_text("target_targets_target_color_critical", TR["Critical Color"], true)
    morale:add_break()
    morale:add_title(TR["Gradient Colors"])
    morale:add_checkbox("target_targets_target_color_gradient", TR["Enable gradient colors"], true)
    morale:add_row_break()
    morale:add_text("target_targets_target_color_gradient_full", TR["Full Color"], true)
    morale:add_text("target_targets_target_color_gradient_mid", TR["Mid Color"], true)
    morale:add_text("target_targets_target_color_gradient_low", TR["Low Color"], true)
    morale:add_row_break()
    morale:add_custom("target_targets_target_color_gradient_preview", 30)

    local text = ConfigContent(window, 3, refresh_preview_fn)
    _build_targets_target_text_colors_form(text)

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
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, prefix .. "_morale_label1_font_style",
        prefix .. "_morale_label1_font_outline_color")
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, prefix .. "_morale_label2_font_style",
        prefix .. "_morale_label2_font_outline_color")
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, prefix .. "_power_label1_font_style",
        prefix .. "_power_label1_font_outline_color")
    _bind_outline_visibility(owner_page, colors_page, colors_page._text_page, prefix .. "_power_label2_font_style",
        prefix .. "_power_label2_font_outline_color")

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

local function _walk_page_tree(page, fn)
    fn(page)

    if page.each_child_page ~= nil then
        page:each_child_page(function(child)
            _walk_page_tree(child, fn)
        end)
        return
    end

    if page._sub_page_order ~= nil and page._sub_pages ~= nil then
        for i = 1, #page._sub_page_order do
            local key = page._sub_page_order[i]
            local child = page._sub_pages[key]
            _walk_page_tree(child, fn)
        end
    end
end

local function _new_label_page(window, refresh_preview_fn, columns, prefix, bar_key, label_index)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_vitals_label_controls(page, prefix, bar_key, label_index)
    return page
end

local function _new_targets_target_label_page(window, refresh_preview_fn, columns, label_index)
    local page = ConfigContent(window, columns, refresh_preview_fn)
    _add_targets_target_label_controls(page, label_index)
    return page
end

local function _new_texts_section(window, refresh_preview_fn, prefix)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Morale 1"], "morale_label1", _new_label_page(window, refresh_preview_fn, 3, prefix, "morale", 1))
    page:add_tab(TR["Morale 2"], "morale_label2", _new_label_page(window, refresh_preview_fn, 3, prefix, "morale", 2))
    page:add_tab(TR["Power 1"], "power_label1", _new_label_page(window, refresh_preview_fn, 3, prefix, "power", 1))
    page:add_tab(TR["Power 2"], "power_label2", _new_label_page(window, refresh_preview_fn, 3, prefix, "power", 2))
    return page
end

local function _new_targets_target_texts_section(window, refresh_preview_fn)
    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Label 1"], "label1", _new_targets_target_label_page(window, refresh_preview_fn, 3, 1))
    page:add_tab(TR["Label 2"], "label2", _new_targets_target_label_page(window, refresh_preview_fn, 3, 2))
    return page
end

local function _new_effects_section(window, refresh_preview_fn, prefix)
    local buffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_buffs_form(buffs, prefix)

    local debuffs = ConfigContent(window, 3, refresh_preview_fn)
    _build_debuffs_form(debuffs, prefix)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_tab(TR["Buffs"], "buffs", buffs)
    page:add_tab(TR["Debuffs"], "debuffs", debuffs)
    return page
end

local function _new_self_unit_page(window)
    local page = ConfigSectionPage(window, "self_vitals_preview", 207, function(win)
        win:update_self_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame:add_text("self_width", TR["Frame Width"])
    frame:add_text("self_border_width", TR["Border Width"])
    frame:add_row_break()
    frame:add_text("self_effects_height", TR["Effects Height"])
    frame:add_row_break()
    frame:add_dropdown("self_effects_position", TR["Effects Position"], frame.vitals_effects_position_labels,
        frame.vitals_effects_position_values)
    frame:add_row_break()
    frame:add_text("self_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("self_outcombat_opacity", TR["Out-of-combat opacity"])
    frame:add_row_break()
    frame:add_checkbox("self_ressource_background_matches_missing", TR["Matching background"], true)
    frame:add_row_break()
    frame:add_text("self_ressource_background_dimming", TR["Dimming"])
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "self", true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "self")
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "self", false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "self"))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "self"))
    _bind_standard_outline_visibility(page, colors, "self", true)

    return page
end

local function _new_target_unit_page(window)
    local page = ConfigSectionPage(window, "target_vitals_preview", 222, function(win)
        win:update_target_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame:add_text("target_width", TR["Frame Width"])
    frame:add_text("target_border_width", TR["Border Width"])
    frame:add_row_break()
    frame:add_text("target_effects_height", TR["Effects Height"])
    frame:add_row_break()
    frame:add_dropdown("target_effects_position", TR["Effects Position"], frame.vitals_effects_position_labels,
        frame.vitals_effects_position_values)
    frame:add_row_break()
    frame:add_text("target_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("target_outcombat_opacity", TR["Out-of-combat opacity"])
    frame:add_row_break()
    frame:add_checkbox("target_ressource_background_matches_missing", TR["Matching background"], true)
    frame:add_row_break()
    frame:add_text("target_ressource_background_dimming", TR["Dimming"])
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "target", true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target")
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "target", false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target"))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target"))
    _bind_standard_outline_visibility(page, colors, "target", true)

    return page
end

local function _new_boss_unit_page(window)
    local page = ConfigSectionPage(window, "target_boss_vitals_preview", 178, function(win)
        win:update_target_boss_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame:add_text("target_boss_width", TR["Frame Width"])
    frame:add_text("target_boss_border_width", TR["Border Width"])
    frame:add_row_break()
    frame:add_text("target_boss_effects_height", TR["Effects Height"])
    frame:add_row_break()
    frame:add_text("target_boss_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("target_boss_outcombat_opacity", TR["Out-of-combat opacity"])
    frame:add_row_break()
    frame:add_checkbox("target_boss_ressource_background_matches_missing", TR["Matching background"],
        true)
    frame:add_row_break()
    frame:add_text("target_boss_ressource_background_dimming", TR["Dimming"])
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "target_boss", true)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target_boss")
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "target_boss", true)
    page:add_tab(TR["Power / Wrath"], "power", power)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target_boss"))
    page:add_tab(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target_boss"))
    _bind_standard_outline_visibility(page, colors, "target_boss", true)

    return page
end

local function _new_targets_target_unit_page(window)
    local page = ConfigSectionPage(window, "target_targets_target_preview", 133, function(win)
        win:update_target_targets_target_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame:add_text("target_targets_target_width", TR["Frame Width"])
    frame:add_text("target_targets_target_height", TR["Bar Height"])
    frame:add_text("target_targets_target_border_width", TR["Border Width"])
    frame:add_row_break()
    frame:add_checkbox("target_targets_target_background_matches_missing", TR["Matching background"],
        true)
    frame:add_row_break()
    frame:add_text("target_targets_target_background_dimming", TR["Dimming"])
    frame:add_row_break()
    frame:add_text("target_targets_target_bubble_text", TR["Bubble Format (%B)"], false, frame.bubble_format_help,
        true)
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_targets_target_colors_section(window, page.refresh_preview)
    page:add_tab(TR["Colors"], "colors", colors)

    page:add_tab(TR["Texts"], "texts", _new_targets_target_texts_section(window, page.refresh_preview))
    _bind_targets_target_outline_visibility(page, colors)

    return page
end

local function _new_party_unit_page(window)
    local page = ConfigSectionPage(window, "party_vitals_preview", 178, function(win)
        win:update_party_vitals_preview()
    end)

    local frame = ConfigContent(window, 4, page.refresh_preview)
    frame.on_scroll_changed = function()
        window:update_party_vitals_preview()
    end
    frame:add_text("party_width", TR["Frame Width"])
    frame:add_text("party_border_width", TR["Border Width"])
    frame:add_row_break()
    frame:add_text("party_rows", TR["Rows per Column"])
    frame:add_row_break()
    frame:add_text("party_spacing_x", TR["Column Spacing"])
    frame:add_text("party_spacing_y", TR["Row Spacing"])
    frame:add_row_break()
    frame:add_text("party_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("party_outcombat_opacity", TR["Out-of-combat opacity"])
    frame:add_row_break()
    frame:add_checkbox("party_ressource_background_matches_missing", TR["Matching background"], true)
    frame:add_row_break()
    frame:add_text("party_ressource_background_dimming", TR["Dimming"])
    page:add_tab(TR["Frame"], "frame", frame)
    local colors = _new_standard_colors_section(window, page.refresh_preview, "party", false)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_morale_form(morale, "party")
    page:add_tab(TR["Morale"], "morale", morale)

    local power = ConfigContent(window, 4, page.refresh_preview)
    _build_standard_power_form(power, "party", false)
    page:add_tab(TR["Power / Wrath"], "power", power)

    page:add_tab(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "party"))

    local icons = ConfigContent(window, 4, page.refresh_preview)
    icons:add_checkbox("party_class_icon_enabled", TR["Show class icon"], true)
    icons:add_row_break()
    icons:add_text("party_class_icon_size", TR["Icon Size"])
    icons:add_row_break()
    icons:add_text("party_class_icon_x", TR["Icon X"])
    icons:add_text("party_class_icon_y", TR["Icon Y"])
    icons:add_row_break()
    icons:add_checkbox("party_leader_icon_enabled", TR["Show leader icon"], true)
    icons:add_row_break()
    icons:add_text("party_leader_icon_size", TR["Leader Icon Size"])
    icons:add_row_break()
    icons:add_text("party_leader_icon_x", TR["Leader Icon X"])
    icons:add_text("party_leader_icon_y", TR["Leader Icon Y"])
    page:add_tab(TR["Icons"], "icons", icons)
    _bind_standard_outline_visibility(page, colors, "party", false)

    return page
end

local function _new_general_page(window)
    local page = ConfigContent(window, 4)
    page:add_title(TR["General"])
    page:add_checkbox("target_boss_enabled", TR["Enable boss vitals"], true)
    return page
end

VitalsPage = class(ConfigTabs)

function VitalsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))

    self:add_tab(TR["General"], "general", _new_general_page(window))
    self:add_tab(TR["Self"], "self", _new_self_unit_page(window))
    self:add_tab(TR["Target"], "target", _new_target_unit_page(window))
    self:add_tab(TR["Boss"], "boss", _new_boss_unit_page(window))
    self:add_tab(TR["Target's Target"], "target_targets_target", _new_targets_target_unit_page(window))
    self:add_tab(TR["Party"], "party", _new_party_unit_page(window))
end

function VitalsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))
end

function VitalsPage:_set_all_loading(loading)
    _walk_page_tree(self, function(page)
        if page ~= self then
            page.loading = loading
        end
    end)
end

function VitalsPage:load_from_settings(s, ui)
    self:_set_all_loading(true)
    SelfVitals.load(self, s, ui)
    TargetVitals.load(self, s, ui)
    TargetBossVitals.load(self, s, ui)
    TargetTargetsTarget.load(self, s, ui)
    PartyLayout.load(self, s, ui)
    PartyVitals.load(self, s, ui)
    self:_set_all_loading(false)
    self:layout()
end

function VitalsPage:apply_to_settings(s, ui)
    SelfVitals.apply(self, s, ui)
    TargetVitals.apply(self, s, ui)
    TargetBossVitals.apply(self, s, ui)
    TargetTargetsTarget.apply(self, s, ui)
    PartyLayout.apply(self, s, ui)
    PartyVitals.apply(self, s, ui)
end
