import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.Settings.Tabs.Self.cooldowns"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local configure_compact_form = FeatureShell.configure_compact_form
local add_compact_row_break = FeatureShell.add_compact_row_break
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int
local Cooldowns = LUI.src.Settings.Tabs.Self.Cooldowns
local PREVIEW_GAP = 10
local PREVIEW_MIN_TOP_HEIGHT = 120
local PREVIEW_MIN_HEIGHT = 100

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

CooldownsFeaturePage = class(SettingsTabbedPage)

function CooldownsFeaturePage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self._preview_default_height = 52
    self.controls = self.controls or {}

    local refresh_preview = function()
        window:update_cooldowns_preview()
    end

    self:add_sub_page(TR["General"], module_for_page("general", _new_general_page(window, refresh_preview)))
    self:add_sub_page(TR["Layout"], module_for_page("layout", _new_layout_page(window, refresh_preview)))
    local colors, colors_text = _new_colors_section(window, refresh_preview)
    self:add_sub_page(TR["Colors"], module_for_page("colors", colors))
    self:add_sub_page(TR["Text"], module_for_page("text", _new_text_page(window, refresh_preview)))
    self:add_sub_page(TR["Filters"], module_for_page("filters", _new_filters_page(window, refresh_preview)))

    self.preview_holder = {
        kind = "custom",
        key = "cooldowns_preview",
        height = self._preview_default_height,
    }
    self.preview_holder.control = Turbine.UI.Control()
    self.preview_holder.control:SetParent(self)
    self.preview_holder.control:SetMouseVisible(false)
    self.controls.cooldowns_preview = self.preview_holder

    _bind_outline_visibility(self, colors_text, "cd_font_style", "cd_font_outline_color")
end

function CooldownsFeaturePage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function CooldownsFeaturePage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    local preview_h = self.preview_holder.height or self._preview_default_height
    local preview_gap = scaled_int(PREVIEW_GAP)
    local min_top_h = scaled_int(PREVIEW_MIN_TOP_HEIGHT)
    local top_h = height - preview_h - preview_gap
    if top_h < min_top_h then
        top_h = min_top_h
        preview_h = height - top_h - preview_gap
    end
    if preview_h < scaled_int(PREVIEW_MIN_HEIGHT) then
        preview_h = scaled_int(PREVIEW_MIN_HEIGHT)
        top_h = height - preview_h - preview_gap
    end
    if top_h < 1 then
        top_h = 1
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, top_h)
    self.sub_tab_bar:refresh_layout()

    self.preview_holder.control:SetPosition(0, top_h + preview_gap)
    self.preview_holder.control:SetSize(width, preview_h)
end

function CooldownsFeaturePage:load_from_settings(s, ui)
    Cooldowns.load(self, s, ui)
end

function CooldownsFeaturePage:apply_to_settings(s, ui)
    Cooldowns.apply(self, s, ui)
end
