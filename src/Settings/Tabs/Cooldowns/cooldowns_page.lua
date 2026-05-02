import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.Settings.Tabs.Self.cooldowns"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local configure_compact_form = FeatureShell.configure_compact_form
local add_compact_row_break = FeatureShell.add_compact_row_break
local module_for_page = FeatureShell.module_for_page
local Cooldowns = LUI.src.Settings.Tabs.Self.Cooldowns

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _bind_hint(window, target, help_text)
    if target == nil or type(help_text) ~= "string" or help_text == "" then
        return
    end

    if window.bind_tooltip ~= nil then
        window:bind_tooltip(target, help_text)
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

local function _layout_text_area(entry)
    local width, height = entry.control:GetSize()
    local label_h = 20
    local gap = 4

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(width, label_h)

    entry.tb:SetPosition(0, label_h + gap)
    entry.tb:SetSize(width, math.max(10, height - label_h - gap))
end

local function _create_text_area(page, key, label_text, help_text)
    local entry = page:add_custom(key, 89)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(page.window.field_label_font)
    entry.label:SetMultiline(false)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)

    entry.tb = UI.Widgets.LuiLineEdit()
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

local function _bind_outline_visibility(owner_page, colors_text_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        colors_text_page:layout()
        owner_page:layout()
    end
end

local function _new_general_page(window, refresh_preview_fn)
    local min_base_help = TR["Skills whose base cooldown is below this value are ignored."]
    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_checkbox("cd_enabled", TR["Enabled"], true)
    add_compact_row_break(page)
    page:add_text("cd_threshold", TR["Threshold (s)"])
    page:add_text("cd_min_base_cooldown", TR["Min base cooldown (s)"], false, min_base_help)
    return page
end

local function _new_layout_page(window, refresh_preview_fn)
    local flow_labels = { TR["Top to bottom"], TR["Bottom to top"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local bar_mode_labels = { TR["Load"], TR["Unload"] }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }

    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_text("cd_item_w", TR["Item width"])
    page:add_text("cd_item_h", TR["Item height"])
    page:add_text("cd_spacing", TR["Spacing (px)"])
    page:add_text("cd_border_width", TR["Border width (px)"])
    page:add_text("cd_columns", TR["Columns"])
    page:add_text("cd_rows", TR["Rows"])
    add_compact_row_break(page)
    page:add_dropdown("cd_flow", TR["Order"], flow_labels, flow_values)
    page:add_dropdown("cd_icon_side", TR["Icon position"], page.side_labels, page.side_values)
    add_compact_row_break(page)
    page:add_dropdown("cd_bar_mode", TR["Bar mode"], bar_mode_labels, bar_mode_values)
    page:add_dropdown("cd_bar_expire_towards", TR["Bar movement towards"], page.side_labels, page.side_values)
    return page
end

local function _new_frame_colors_page(window, refresh_preview_fn)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    page:add_text("cd_bg_color", TR["Background color"], true)
    page:add_text("cd_border_color", TR["Border color"], true)
    return page
end

local function _new_bar_colors_page(window, refresh_preview_fn)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    page:add_text("cd_bar_color", TR["Bar color"], true)
    return page
end

local function _new_text_colors_page(window, refresh_preview_fn)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    page:add_text("cd_font_color", TR["Font color"], true)
    page:add_text("cd_font_outline_color", TR["Outline color"], true)
    return page
end

local function _new_colors_section(window, refresh_preview_fn)
    local frame = _new_frame_colors_page(window, refresh_preview_fn)
    local bar = _new_bar_colors_page(window, refresh_preview_fn)
    local text = _new_text_colors_page(window, refresh_preview_fn)

    local page = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_sub_page(TR["Frame"], module_for_page("frame", frame))
    page:add_sub_page(TR["Bar"], module_for_page("bar", bar))
    page:add_sub_page(TR["Text"], module_for_page("text", text))
    return page, text
end

local function _new_text_page(window, refresh_preview_fn)
    local time_format_labels = { TR["Auto precision"], TR["Whole seconds"] }
    local time_format_values = {
        LUI_ENUMS.cooldown_time_format.AUTO,
        LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
    }

    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_dropdown("cd_time_format", TR["Time format"], time_format_labels, time_format_values)
    page:add_text("cd_text_margin", TR["Text margin (px)"])
    page:add_text("cd_name_max_chars", TR["Max name chars"])
    add_compact_row_break(page)
    page:add_dropdown("cd_font_name", TR["Font"], page.font_name_labels, page.font_name_values)
    page:add_text("cd_font_size", TR["Font size"])
    page:add_dropdown("cd_font_style", TR["Font style"], page.font_style_labels, page.font_style_values)
    return page
end

local function _new_filters_page(window, refresh_preview_fn)
    local list_help = TR["One skill name per line or comma-separated. Case-insensitive. Exact match or prefix with trailing *."]
    local page = configure_compact_form(SettingsFormPage(window), 1, refresh_preview_fn)
    _create_text_area(page, "cd_whitelist", TR["Whitelist"], list_help)
    page:add_break()
    _create_text_area(page, "cd_blacklist", TR["Blacklist"], list_help)
    return page
end

CooldownsFeaturePage = class(SettingsFeatureSectionPage)

function CooldownsFeaturePage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window, "cooldowns_preview", 52, function(win)
        win:update_cooldowns_preview()
    end, false)

    self:add_section(TR["General"], "general", _new_general_page(window, self.refresh_preview))
    self:add_section(TR["Layout"], "layout", _new_layout_page(window, self.refresh_preview))
    local colors, colors_text = _new_colors_section(window, self.refresh_preview)
    self:add_section(TR["Colors"], "colors", colors)
    self:add_section(TR["Text"], "text", _new_text_page(window, self.refresh_preview))
    self:add_section(TR["Filters"], "filters", _new_filters_page(window, self.refresh_preview))
    _bind_outline_visibility(self, colors_text, "cd_font_style", "cd_font_outline_color")
end

function CooldownsFeaturePage:load_from_settings(s, ui)
    Cooldowns.load(self, s, ui)
end

function CooldownsFeaturePage:apply_to_settings(s, ui)
    Cooldowns.apply(self, s, ui)
end
