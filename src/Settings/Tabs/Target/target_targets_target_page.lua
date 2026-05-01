import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _hook_layout_on_change(page, control)
    local prev = control.on_changed
    control.on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        page:layout()
    end
end

local STEP_COLORS_INFO = TR["Used when gradient colors are disabled. High, Medium, Low and Critical apply by thresholds."]
local GRADIENT_COLORS_INFO = TR["When enabled, this bypasses the step colors and blends between Full, Mid and Low."]

local function _add_targets_target_label_controls(page, label_index, title)
    local key = "target_targets_target_label" .. tostring(label_index)

    page:add_title(title)
    page:add_checkbox(key .. "_enabled", TR["Enabled"])
    page:add_break()
    page:add_text(key .. "_text", TR["Text"], false, page.vital_format_help, true)
    page:add_dropdown(key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values)
    page:add_dropdown(key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values)
    page:add_break()
    page:add_dropdown(key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    page:add_break()
    page:add_text(key .. "_x_offset", TR["X offset"])
    page:add_text(key .. "_y_offset", TR["Y offset"])
    page:add_break()
    page:add_dropdown(key .. "_font_name", TR["Font"], page.font_name_labels, page.font_name_values)
    page:add_text(key .. "_font_size", TR["Font Size"])
    page:add_text(key .. "_font_color", TR["Font Color"], true)
    page:add_dropdown(key .. "_font_style", TR["Font Style"], page.font_style_labels, page.font_style_values)
    page:add_text(key .. "_font_outline_color", TR["Outline Color"], true)
end

local function _hook_outline_control(page, style_key, outline_key)
    page.controls[outline_key].visible_if = function()
        return _is_outline(page.controls[style_key])
    end
    _hook_layout_on_change(page, page.controls[style_key])
end

TargetTargetsTargetPage = class(SettingsFormPage)

function TargetTargetsTargetPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    self.refresh_preview = function()
        self.window:update_target_targets_target_preview()
    end

    self:add_title(TR["Target's Target"])

    self:add_hr()
    self:add_title(TR["Frame"])
    self:add_text("target_targets_target_width", TR["Frame Width"])
    self:add_text("target_targets_target_height", TR["Bar Height"])
    self:add_text("target_targets_target_border_width", TR["Border Width"])

    self:add_hr()
    self:add_title(TR["Texts"])
    self:add_text("target_targets_target_bubble_text", TR["Bubble Format (%B)"], false, self.bubble_format_help, true)
    self:add_break()
    _add_targets_target_label_controls(self, 1, TR["Label 1"])
    self:add_break()
    _add_targets_target_label_controls(self, 2, TR["Label 2"])

    self:add_hr()
    self:add_title(TR["Colors"])
    self:add_text("target_targets_target_background_color", TR["Background Color"], true)
    self:add_break()
    self:add_checkbox("target_targets_target_background_matches_missing", TR["Background matches missing ressource"])
    self:add_text("target_targets_target_background_dimming", TR["Dimming"])
    self:add_break()
    self:add_text("target_targets_target_border_color", TR["Border Color"], true)
    self:add_text("target_targets_target_bubble_color", TR["Bubble Color"], true)
    self:add_text("target_targets_target_color_neutral", TR["Neutral Color"], true)
    self:add_break()
    self:add_title(TR["Step Colors"])
    self:add_info(STEP_COLORS_INFO)
    self:add_break()
    self:add_text("target_targets_target_color_high", TR["High Color"], true)
    self:add_text("target_targets_target_color_medium", TR["Medium Color"], true)
    self:add_text("target_targets_target_color_low", TR["Low Color"], true)
    self:add_text("target_targets_target_color_critical", TR["Critical Color"], true)
    self:add_break()
    self:add_title(TR["Gradient Colors"])
    self:add_info(GRADIENT_COLORS_INFO)
    self:add_checkbox("target_targets_target_color_gradient", TR["Enable gradient colors"], true)
    self:add_break()
    self:add_text("target_targets_target_color_gradient_full", TR["Full Color"], true)
    self:add_text("target_targets_target_color_gradient_mid", TR["Mid Color"], true)
    self:add_text("target_targets_target_color_gradient_low", TR["Low Color"], true)
    self:add_custom("target_targets_target_color_gradient_preview", 30)

    self:add_hr()
    self:add_title(TR["Preview"])
    self:add_custom("target_targets_target_preview", 133)

    _hook_outline_control(self, "target_targets_target_label1_font_style",
        "target_targets_target_label1_font_outline_color")
    _hook_outline_control(self, "target_targets_target_label2_font_style",
        "target_targets_target_label2_font_outline_color")
end
