import "LUI.src.UI.Settings.Tabs.form_page"

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

SelfVitalsPage = class(SettingsFormPage)

function SelfVitalsPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    self.refresh_preview = function()
        self.window:update_self_vitals_preview()
    end

    self:add_title(TR("Self Vitals"))

    self:add_hr()
    self:add_title(TR("Frame"))
    self:add_text("self_width", TR("Frame Width"))
    self:add_text("self_border_width", TR("Border Width"))
    self:add_break()
    self:add_text("self_incombat_opacity", TR("In-combat opacity"))
    self:add_text("self_outcombat_opacity", TR("Out-of-combat opacity"))
    self:add_text("self_effects_height", TR("Effects Height"))
    self:add_dropdown("self_effects_position", TR("Effects Position"), self.vitals_effects_position_labels,
        self.vitals_effects_position_values)
    self:add_break()
    self:add_checkbox("self_ressource_background_matches_missing", TR("Background matches missing ressource"))
    self:add_text("self_ressource_background_dimming", TR("Dimming"))

    self:add_hr()
    self:add_title(TR("Morale"))
    self:add_text("self_morale_height", TR("Bar Height"))
    self:add_break()
    self:add_dropdown("self_morale_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("self_morale_font_size", TR("Font Size"))
    self:add_text("self_morale_font_color", TR("Font Color"), true)
    self:add_dropdown("self_morale_font_style", TR("Font Style"), self.font_style_labels, self.font_style_values)
    self:add_text("self_morale_font_outline_color", TR("Outline Color"), true)
    self:add_break()
    self:add_text("self_morale_background_color", TR("Background Color"), true)
    self:add_break()
    self:add_text("self_border_color", TR("Border Color"), true)
    self:add_text("self_morale_bubble_color", TR("Bubble Color"), true)
    self:add_break()
    self:add_text("self_morale_color_neutral", TR("Neutral Color"), true)
    self:add_break()
    self:add_title(TR("Step Colors"))
    self:add_info(STEP_COLORS_INFO)
    self:add_break()
    self:add_text("self_morale_color_high", TR("High Color"), true)
    self:add_text("self_morale_color_medium", TR("Medium Color"), true)
    self:add_text("self_morale_color_low", TR("Low Color"), true)
    self:add_text("self_morale_color_critical", TR("Critical Color"), true)
    self:add_break()
    self:add_title(TR("Gradient Colors"))
    self:add_info(GRADIENT_COLORS_INFO)
    self:add_checkbox("self_morale_gradient", TR("Enable gradient colors"), true)
    self:add_break()
    self:add_text("self_morale_gradient_full", TR("Full Color"), true)
    self:add_text("self_morale_gradient_mid", TR("Mid Color"), true)
    self:add_text("self_morale_gradient_low", TR("Low Color"), true)
    self:add_custom("self_morale_gradient_preview", 30)
    self:add_break()
    self:add_text("self_morale_text", TR("Text"), false, self.vital_format_help, true)
    self:add_text("self_morale_bubble_text", TR("Bubble Format (%B)"), false, self.bubble_format_help, true)
    self:add_dropdown("self_morale_text_alignment", TR("Text alignment"), self.text_alignment_labels,
        self.text_alignment_values)
    self:add_text("self_morale_text_margin", TR("Text margin"))

    self:add_hr()
    self:add_title(TR("Power / Wrath"))
    self:add_text("self_power_height", TR("Bar Height"))
    self:add_break()
    self:add_dropdown("self_power_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("self_power_font_size", TR("Font Size"))
    self:add_text("self_power_font_color", TR("Font Color"), true)
    self:add_dropdown("self_power_font_style", TR("Font Style"), self.font_style_labels, self.font_style_values)
    self:add_text("self_power_font_outline_color", TR("Outline Color"), true)
    self:add_break()
    self:add_text("self_power_color", TR("Power Color"), true)
    self:add_text("self_wrath_color", TR("Wrath Color"), true)
    self:add_break()
    self:add_text("self_power_text", TR("Text"), false, self.vital_format_help, true)
    self:add_dropdown("self_power_text_alignment", TR("Text alignment"), self.text_alignment_labels,
        self.text_alignment_values)
    self:add_text("self_power_text_margin", TR("Text margin"))

    self:add_hr()
    self:add_title(TR("Buffs"))
    self:add_break()
    self:add_text("self_buff_size", TR("Icon Size"))
    self:add_break()
    self:add_dropdown("self_buff_timer_font_name", TR("Timer Font"), self.font_name_labels, self.font_name_values)
    self:add_text("self_buff_timer_font_size", TR("Timer Font Size"))
    self:add_text("self_buff_timer_font_color", TR("Timer Font Color"), true)
    self:add_dropdown("self_buff_timer_font_style", TR("Timer Font Style"), self.font_style_labels,
        self.font_style_values)
    self:add_text("self_buff_timer_font_outline_color", TR("Timer Outline Color"), true)

    self:add_hr()
    self:add_title(TR("Debuffs"))
    self:add_checkbox("self_debuff_track_curable", TR("Track curable debuffs"))
    self:add_checkbox("self_debuff_track_noncurable", TR("Track non-curable debuffs"))
    self:add_break()
    self:add_text("self_debuff_size", TR("Icon Size"))
    self:add_break()
    self:add_dropdown("self_debuff_timer_font_name", TR("Timer Font"), self.font_name_labels, self.font_name_values)
    self:add_text("self_debuff_timer_font_size", TR("Timer Font Size"))
    self:add_text("self_debuff_timer_font_color", TR("Timer Font Color"), true)
    self:add_dropdown("self_debuff_timer_font_style", TR("Timer Font Style"), self.font_style_labels,
        self.font_style_values)
    self:add_text("self_debuff_timer_font_outline_color", TR("Timer Outline Color"), true)

    self:add_hr()
    self:add_title(TR("Preview"))
    self:add_custom("self_vitals_preview", 207)

    self.controls.self_morale_font_outline_color.visible_if = function()
        return _is_outline(self.controls.self_morale_font_style)
    end
    self.controls.self_power_font_outline_color.visible_if = function()
        return _is_outline(self.controls.self_power_font_style)
    end
    self.controls.self_buff_timer_font_outline_color.visible_if = function()
        return _is_outline(self.controls.self_buff_timer_font_style)
    end
    self.controls.self_debuff_timer_font_outline_color.visible_if = function()
        return _is_outline(self.controls.self_debuff_timer_font_style)
    end

    _hook_layout_on_change(self, self.controls.self_morale_font_style)
    _hook_layout_on_change(self, self.controls.self_power_font_style)
    _hook_layout_on_change(self, self.controls.self_buff_timer_font_style)
    _hook_layout_on_change(self, self.controls.self_debuff_timer_font_style)
end
