import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Settings.Tabs.form_page"

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

local function _layout_text_area(entry)
    if entry == nil or entry.control == nil or entry.tb == nil or entry.label == nil then
        return
    end

    local w, h = entry.control:GetSize()
    local label_h = 20
    local gap = 4

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(w, label_h)

    entry.tb:SetPosition(0, label_h + gap)
    entry.tb:SetSize(w, math.max(10, h - label_h - gap))
end

local function _bind_hint(window, target, help_text)
    if target == nil or type(help_text) ~= "string" or help_text == "" then
        return
    end

    local prev_enter = target.MouseEnter
    target.MouseEnter = function(sender, args)
        if prev_enter ~= nil then
            prev_enter(sender, args)
        end
        window:show_hint_for(target, help_text)
    end

    local prev_leave = target.MouseLeave
    target.MouseLeave = function(sender, args)
        if prev_leave ~= nil then
            prev_leave(sender, args)
        end
        window:hide_hint()
    end
end

local function _create_text_area(page, key, label_text, help_text)
    local entry = page:add_custom(key, 89)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(page.window.field_label_font)
    entry.label:SetMultiline(false)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)

    entry.tb = Turbine.UI.Lotro.TextBox()
    entry.tb:SetParent(entry.control)
    entry.tb:SetFont(page.window.input_font)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    if entry.tb.SetMultiline ~= nil then
        entry.tb:SetMultiline(true)
    end

    _bind_hint(page.window, entry.tb, help_text)

    entry.apply_ui_scale = function()
        entry.label:SetFont(page.window.field_label_font)
        entry.tb:SetFont(page.window.input_font)
        _layout_text_area(entry)
    end

    function entry:refresh_text()
        self.tb:SetText(self.tb:GetText() or "")
    end

    entry.control.SizeChanged = function()
        _layout_text_area(entry)
    end
    _layout_text_area(entry)

    return entry
end

CooldownsPage = class(SettingsFormPage)

function CooldownsPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    local bar_mode_labels = { TR("Load"), TR("Unload") }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }
    local flow_labels = { TR("Top to bottom"), TR("Bottom to top") }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local min_base_help = TR("Skills whose base cooldown is below this value are ignored.")
    local fmt_help = table.concat({
        TR("Tokens:"),
        TR("  %name% - skill name"),
        TR("  %t - remaining time with tenths (X.Ys)"),
        TR("  %s - remaining time without tenths (Xs)"),
        "",
        TR("Examples:"),
        TR("  %name% - %t"),
        TR("  %name% - %s"),
    }, "\n")
    local list_help = TR("One skill name per line or comma-separated. Case-insensitive. Exact match or prefix with trailing *.")

    self.refresh_preview = function()
        self.window:update_cooldowns_preview()
    end

    self:add_title(TR("Cooldowns"))

    self:add_hr()
    self:add_title(TR("General"))
    self:add_checkbox("cd_enabled", TR("Enabled"), true)
    self:add_text("cd_threshold", TR("Threshold (s)"))
    self:add_text("cd_min_base_cooldown", TR("Min base cooldown (s)"), false, min_base_help)

    self:add_hr()
    self:add_title(TR("Layout"))
    self:add_text("cd_item_w", TR("Item width"))
    self:add_text("cd_item_h", TR("Item height"))
    self:add_text("cd_spacing", TR("Spacing (px)"))
    self:add_text("cd_border_width", TR("Border width (px)"))
    self:add_text("cd_columns", TR("Columns"))
    self:add_text("cd_rows", TR("Rows"))
    self:add_dropdown("cd_flow", TR("Order"), flow_labels, flow_values)
    self:add_dropdown("cd_icon_side", TR("Icon position"), self.side_labels, self.side_values)
    self:add_dropdown("cd_bar_mode", TR("Bar mode"), bar_mode_labels, bar_mode_values)
    self:add_dropdown("cd_bar_expire_towards", TR("Bar movement towards"), self.side_labels, self.side_values)
    self:add_text("cd_bg_color", TR("Background color"), true)
    self:add_text("cd_bar_color", TR("Bar color"), true)
    self:add_text("cd_border_color", TR("Border color"), true)

    self:add_hr()
    self:add_title(TR("Text"))
    self:add_text("cd_text_template", TR("Text template"), false, fmt_help, true)
    self:add_dropdown("cd_text_alignment", TR("Text alignment"), self.text_alignment_labels, self.text_alignment_values)
    self:add_text("cd_text_margin", TR("Text margin (px)"))
    self:add_text("cd_name_max_chars", TR("Max name chars"))

    self:add_hr()
    self:add_title(TR("Font"))
    self:add_dropdown("cd_font_name", TR("Font"), self.font_name_labels, self.font_name_values)
    self:add_text("cd_font_size", TR("Font size"))
    self:add_text("cd_font_color", TR("Font color"), true)
    self:add_dropdown("cd_font_style", TR("Font style"), self.font_style_labels, self.font_style_values)
    self:add_text("cd_font_outline_color", TR("Outline color"), true)

    self:add_hr()
    self:add_title(TR("Preview"))
    self:add_custom("cooldowns_preview", 52)

    self:add_hr()
    self:add_title(TR("Lists"))
    _create_text_area(self, "cd_whitelist", TR("Whitelist"), list_help)
    _create_text_area(self, "cd_blacklist", TR("Blacklist"), list_help)

    self.controls.cd_font_outline_color.visible_if = function()
        return _is_outline(self.controls.cd_font_style)
    end

    _hook_layout_on_change(self, self.controls.cd_font_style)
end
