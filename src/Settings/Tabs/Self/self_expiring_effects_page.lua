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

SelfExpiringEffectsPage = class(SettingsFormPage)

function SelfExpiringEffectsPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    local template_help = table.concat({
        TR["Text template tokens:"],
        TR["  %n = effect name"],
        TR["  %t = remaining time"],
        "",
        TR["You can use \\n for a new line."],
        TR["Example: %n  %t"],
    }, "\n")

    self.refresh_preview = function()
        self.window:update_expiring_effects_preview()
    end

    self:add_title(TR["Expiring Effects"])
    self:add_checkbox("expiring_effects_enabled", TR["Enable expiring effects window"], true)

    self:add_hr()
    self:add_title(TR["Tracking"])
    self:add_checkbox("expiring_effects_show_buffs", TR["Track buffs"])
    self:add_break()
    self:add_checkbox("expiring_effects_show_curable_debuffs", TR["Track curable debuffs"])
    self:add_checkbox("expiring_effects_show_noncurable_debuffs", TR["Track non-curable debuffs"])
    self:add_break()
    self:add_title(TR["Trigger"])
    self:add_text("expiring_effects_threshold", TR["Show when less than seconds remaining"])

    self:add_hr()
    self:add_title(TR["Layout"])
    self:add_text("expiring_effects_columns", TR["Columns"])
    self:add_text("expiring_effects_rows", TR["Rows"])
    self:add_break()
    self:add_text("expiring_effects_bar_width", TR["Bar Width"])
    self:add_text("expiring_effects_bar_height", TR["Bar Height"])
    self:add_text("expiring_effects_border_width", TR["Border Width"])
    self:add_text("expiring_effects_spacing", TR["Spacing"])
    self:add_break()
    self:add_dropdown("expiring_effects_icon_side", TR["Icon position"], self.side_labels, self.side_values)
    self:add_dropdown("expiring_effects_bar_expire_towards", TR["Bar expires towards"], self.side_labels,
        self.side_values)

    self:add_hr()
    self:add_title(TR["Style"])
    self:add_text("expiring_effects_bar_color", TR["Buff Bar Color"], true)
    self:add_text("expiring_effects_debuff_curable_bar_color", TR["Curable Debuff Bar Color"], true)
    self:add_text("expiring_effects_debuff_noncurable_bar_color", TR["Non-curable Debuff Bar Color"], true)
    self:add_text("expiring_effects_background_color", TR["Background Color"], true)
    self:add_text("expiring_effects_border_color", TR["Border Color"], true)
    self:add_break()
    self:add_text("expiring_effects_name_max_chars", TR["Max name characters"])
    self:add_text("expiring_effects_text_template", TR["Text template"], false, template_help, true)
    self:add_dropdown("expiring_effects_text_alignment", TR["Text alignment"], self.text_alignment_labels,
        self.text_alignment_values)
    self:add_break()
    self:add_dropdown("expiring_effects_font_name", TR["Font"], self.font_name_labels, self.font_name_values)
    self:add_text("expiring_effects_font_size", TR["Font Size"])
    self:add_text("expiring_effects_font_color", TR["Font Color"], true)
    self:add_dropdown("expiring_effects_font_style", TR["Font Style"], self.font_style_labels, self.font_style_values)
    self:add_text("expiring_effects_font_outline_color", TR["Outline Color"], true)

    self:add_hr()
    self:add_title(TR["Preview"])
    self:add_custom("expiring_effects_preview", 53)

    self.controls.expiring_effects_font_outline_color.visible_if = function()
        return _is_outline(self.controls.expiring_effects_font_style)
    end

    _hook_layout_on_change(self, self.controls.expiring_effects_font_style)
end
