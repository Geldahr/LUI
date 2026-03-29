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

local STEP_COLORS_INFO = TR("Used when gradient colors are disabled. High, Medium, Low and Critical apply by thresholds.")
local GRADIENT_COLORS_INFO = TR("When enabled, this bypasses the step colors and blends between Full, Mid and Low.")

TargetTargetsTargetPage = class(SettingsFormPage)

function TargetTargetsTargetPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    self.refresh_preview = function()
        self.window:update_target_targets_target_preview()
    end

    self:add_title(TR("Target's Target"))

    self:add_hr()
    self:add_title(TR("Frame"))
    self:add_text("target_targets_target_width", TR("Frame Width"))
    self:add_text("target_targets_target_height", TR("Bar Height"))
    self:add_text("target_targets_target_border_width", TR("Border Width"))

    self:add_hr()
    self:add_title(TR("Font"))
    self:add_dropdown("target_targets_target_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("target_targets_target_font_size", TR("Font Size"))
    self:add_text("target_targets_target_font_color", TR("Font Color"), true)
    self:add_dropdown("target_targets_target_font_style", TR("Font Style"), self.font_style_labels,
        self.font_style_values)
    self:add_text("target_targets_target_font_outline_color", TR("Outline Color"), true)

    self:add_hr()
    self:add_title(TR("Text"))
    self:add_text("target_targets_target_text", TR("Text"), false, self.vital_format_help, true)
    self:add_text("target_targets_target_bubble_text", TR("Bubble Format (%B)"), false, self.bubble_format_help, true)
    self:add_dropdown("target_targets_target_text_alignment", TR("Text alignment"), self.text_alignment_labels,
        self.text_alignment_values)
    self:add_text("target_targets_target_text_margin", TR("Text margin"))

    self:add_hr()
    self:add_title(TR("Colors"))
    self:add_text("target_targets_target_background_color", TR("Background Color"), true)
    self:add_break()
    self:add_checkbox("target_targets_target_background_matches_missing", TR("Background matches missing ressource"))
    self:add_text("target_targets_target_background_dimming", TR("Dimming"))
    self:add_break()
    self:add_text("target_targets_target_border_color", TR("Border Color"), true)
    self:add_text("target_targets_target_bubble_color", TR("Bubble Color"), true)
    self:add_text("target_targets_target_color_neutral", TR("Neutral Color"), true)
    self:add_break()
    self:add_title(TR("Step Colors"))
    self:add_info(STEP_COLORS_INFO)
    self:add_break()
    self:add_text("target_targets_target_color_high", TR("High Color"), true)
    self:add_text("target_targets_target_color_medium", TR("Medium Color"), true)
    self:add_text("target_targets_target_color_low", TR("Low Color"), true)
    self:add_text("target_targets_target_color_critical", TR("Critical Color"), true)
    self:add_break()
    self:add_title(TR("Gradient Colors"))
    self:add_info(GRADIENT_COLORS_INFO)
    self:add_checkbox("target_targets_target_color_gradient", TR("Enable gradient colors"), true)
    self:add_break()
    self:add_text("target_targets_target_color_gradient_full", TR("Full Color"), true)
    self:add_text("target_targets_target_color_gradient_mid", TR("Mid Color"), true)
    self:add_text("target_targets_target_color_gradient_low", TR("Low Color"), true)
    self:add_custom("target_targets_target_color_gradient_preview", 30)

    self:add_hr()
    self:add_title(TR("Preview"))
    self:add_custom("target_targets_target_preview", 133)

    self.controls.target_targets_target_font_outline_color.visible_if = function()
        return _is_outline(self.controls.target_targets_target_font_style)
    end

    _hook_layout_on_change(self, self.controls.target_targets_target_font_style)
end
