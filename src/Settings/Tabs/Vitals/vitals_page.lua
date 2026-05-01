import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.Settings.Tabs.Self.self_vitals"
import "LUI.src.Settings.Tabs.Target.target_vitals"
import "LUI.src.Settings.Tabs.Target.target_boss_vitals"
import "LUI.src.Settings.Tabs.Target.target_targets_target"
import "LUI.src.Settings.Tabs.Party.party_layout"
import "LUI.src.Settings.Tabs.Party.party_vitals"

local Style = UI.Widgets.Style
local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or
    _G.SettingsFormPage or SettingsFormPage
local SelfVitals = LUI.src.Settings.Tabs.Self.SelfVitals
local TargetVitals = LUI.src.Settings.Tabs.Target.TargetVitals
local TargetBossVitals = LUI.src.Settings.Tabs.Target.TargetBossVitals
local TargetTargetsTarget = LUI.src.Settings.Tabs.Target.TargetTargetsTarget
local PartyLayout = LUI.src.Settings.Tabs.Party.PartyLayout
local PartyVitals = LUI.src.Settings.Tabs.Party.PartyVitals

local SECTION_TAB_SCALE = 0.88
local NESTED_TAB_SCALE = 0.78
local SECTION_TAB_FONT_SIZE = 12
local NESTED_TAB_FONT_SIZE = 11
local BASE_TAB_HEIGHT = 24
local PREVIEW_GAP = 10
local SECTION_CONTENT_GAP = 8
local SECTION_FRAME_PADDING = 8
local CONTENT_BORDER_COLOR = Turbine.UI.Color(1, 0.2, 0.2, 0.2)

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, size * _G.settings.global.scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size * _G.settings.global.scale))
    end
    return font
end

local function _refresh_preview_noop()
end

local function _apply_button_tab_bar_theme(tab_bar)
    tab_bar._strip_back = Style.BACKGROUND
    tab_bar._content_back = Style.BACKGROUND
    tab_bar._content_border_color = CONTENT_BORDER_COLOR
    tab_bar:refresh_layout()
end

local function _configure_compact_form(page, columns, refresh_preview_fn)
    page:set_compact_fields(true)
    page:set_grid_columns(columns)
    page.refresh_preview = refresh_preview_fn or _refresh_preview_noop
    return page
end

local function _add_compact_row_break(page)
    page:add_break(0)
end

local function _add_font_identity_controls(page, base_key, font_label, size_label, style_label)
    page:add_dropdown(base_key .. "_font_name", font_label or TR["Font"], page.font_name_labels, page.font_name_values)
    page:add_text(base_key .. "_font_size", size_label or TR["Font Size"])
    page:add_dropdown(base_key .. "_font_style", style_label or TR["Font Style"], page.font_style_labels,
        page.font_style_values)
end

local function _add_font_color_controls(page, base_key, color_label, outline_label)
    page:add_text(base_key .. "_font_color", color_label or TR["Font Color"], true)
    page:add_text(base_key .. "_font_outline_color", outline_label or TR["Outline Color"], true)
end

local function _add_vitals_label_controls(page, prefix, bar_key, label_index)
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)

    page:add_checkbox(key .. "_enabled", TR["Enabled"], true)
    _add_compact_row_break(page)
    page:add_text(key .. "_text", TR["Text"], false, page.vital_format_help, true)
    _add_compact_row_break(page)
    page:add_dropdown(key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values)
    page:add_dropdown(key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values)
    page:add_dropdown(key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    _add_compact_row_break(page)
    page:add_text(key .. "_x_offset", TR["X offset"])
    page:add_text(key .. "_y_offset", TR["Y offset"])
    _add_compact_row_break(page)
    _add_font_identity_controls(page, key, TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _add_targets_target_label_controls(page, label_index)
    local key = "target_targets_target_label" .. tostring(label_index)

    page:add_checkbox(key .. "_enabled", TR["Enabled"], true)
    _add_compact_row_break(page)
    page:add_text(key .. "_text", TR["Text"], false, page.vital_format_help, true)
    _add_compact_row_break(page)
    page:add_dropdown(key .. "_anchor", TR["Anchor"], page.vitals_label_anchor_labels,
        page.vitals_label_anchor_values)
    page:add_dropdown(key .. "_width_mode", TR["Width mode"], page.vitals_label_width_mode_labels,
        page.vitals_label_width_mode_values)
    page:add_dropdown(key .. "_text_alignment", TR["Text alignment"], page.text_alignment_labels,
        page.text_alignment_values)
    _add_compact_row_break(page)
    page:add_text(key .. "_x_offset", TR["X offset"])
    page:add_text(key .. "_y_offset", TR["Y offset"])
    _add_compact_row_break(page)
    _add_font_identity_controls(page, key, TR["Font"], TR["Font Size"], TR["Font Style"])
end

local function _build_standard_frame_colors_form(page, prefix)
    page:add_text(prefix .. "_morale_background_color", TR["Background Color"], true)
    page:add_text(prefix .. "_border_color", TR["Border Color"], true)
end

local function _build_standard_morale_form(page, prefix)
    page:add_text(prefix .. "_morale_height", TR["Bar Height"])
    _add_compact_row_break(page)
    page:add_text(prefix .. "_morale_bubble_text", TR["Bubble Format (%B)"], false, page.bubble_format_help, true)
end

local function _build_standard_morale_colors_form(page, prefix)
    page:add_text(prefix .. "_morale_bubble_color", TR["Bubble Color"], true)
    page:add_text(prefix .. "_morale_color_neutral", TR["Neutral Color"], true)
    _add_compact_row_break(page)
    page:add_title(TR["Step Colors"])
    page:add_text(prefix .. "_morale_color_high", TR["High Color"], true)
    page:add_text(prefix .. "_morale_color_medium", TR["Medium Color"], true)
    page:add_text(prefix .. "_morale_color_low", TR["Low Color"], true)
    _add_compact_row_break(page)
    page:add_text(prefix .. "_morale_color_critical", TR["Critical Color"], true)
    page:add_break()
    page:add_title(TR["Gradient Colors"])
    page:add_checkbox(prefix .. "_morale_gradient", TR["Enable gradient colors"], true)
    _add_compact_row_break(page)
    page:add_text(prefix .. "_morale_gradient_full", TR["Full Color"], true)
    page:add_text(prefix .. "_morale_gradient_mid", TR["Mid Color"], true)
    page:add_text(prefix .. "_morale_gradient_low", TR["Low Color"], true)
    _add_compact_row_break(page)
    page:add_custom(prefix .. "_morale_gradient_preview", 30)
end

local function _build_standard_power_form(page, prefix, include_boss_fields)
    if include_boss_fields == true then
        page:add_checkbox(prefix .. "_power_hide", TR["Hide power / wrath"], true)
        _add_compact_row_break(page)
        page:add_text(prefix .. "_power_width", TR["Width"])
        page:add_text(prefix .. "_power_height", TR["Bar Height"])
        _add_compact_row_break(page)
        page:add_dropdown(prefix .. "_power_side", TR["Side"], page.side_labels, page.side_values)
        _add_compact_row_break(page)
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
    _add_compact_row_break(page)
    _add_font_identity_controls(page, prefix .. "_buff_timer", TR["Timer Font"], TR["Timer Font Size"],
        TR["Timer Font Style"])
end

local function _build_debuffs_form(page, prefix)
    page:add_checkbox(prefix .. "_debuff_track_curable", TR["Track curable debuffs"], false)
    page:add_checkbox(prefix .. "_debuff_track_noncurable", TR["Track non-curable debuffs"], false)
    _add_compact_row_break(page)
    page:add_text(prefix .. "_debuff_size", TR["Icon Size"])
    _add_compact_row_break(page)
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

local _module_for_page

local function _new_standard_colors_section(window, refresh_preview_fn, prefix, include_effects)
    local frame = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_standard_frame_colors_form(frame, prefix)

    local morale = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_standard_morale_colors_form(morale, prefix)

    local power = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_standard_power_colors_form(power, prefix)

    local text = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_standard_text_colors_form(text, prefix)

    local page = CompactNestedTabbedPage(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_sub_page(TR["Frame"], _module_for_page("frame", frame))
    page:add_sub_page(TR["Morale"], _module_for_page("morale", morale))
    page:add_sub_page(TR["Power / Wrath"], _module_for_page("power", power))
    page:add_sub_page(TR["Text"], _module_for_page("text", text))

    if include_effects == true then
        local effects = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
        _build_effects_colors_form(effects, prefix)
        page:add_sub_page(TR["Effects"], _module_for_page("effects", effects))
    end

    return page
end

local function _new_targets_target_colors_section(window, refresh_preview_fn)
    local frame = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    frame:add_text("target_targets_target_background_color", TR["Background Color"], true)
    frame:add_text("target_targets_target_border_color", TR["Border Color"], true)

    local morale = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    morale:add_text("target_targets_target_bubble_color", TR["Bubble Color"], true)
    morale:add_text("target_targets_target_color_neutral", TR["Neutral Color"], true)
    _add_compact_row_break(morale)
    morale:add_break()
    morale:add_title(TR["Step Colors"])
    morale:add_text("target_targets_target_color_high", TR["High Color"], true)
    morale:add_text("target_targets_target_color_medium", TR["Medium Color"], true)
    morale:add_text("target_targets_target_color_low", TR["Low Color"], true)
    _add_compact_row_break(morale)
    morale:add_text("target_targets_target_color_critical", TR["Critical Color"], true)
    morale:add_break()
    morale:add_title(TR["Gradient Colors"])
    morale:add_checkbox("target_targets_target_color_gradient", TR["Enable gradient colors"], true)
    _add_compact_row_break(morale)
    morale:add_text("target_targets_target_color_gradient_full", TR["Full Color"], true)
    morale:add_text("target_targets_target_color_gradient_mid", TR["Mid Color"], true)
    morale:add_text("target_targets_target_color_gradient_low", TR["Low Color"], true)
    _add_compact_row_break(morale)
    morale:add_custom("target_targets_target_color_gradient_preview", 30)

    local text = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_targets_target_text_colors_form(text)

    local page = CompactNestedTabbedPage(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_sub_page(TR["Frame"], _module_for_page("frame", frame))
    page:add_sub_page(TR["Morale"], _module_for_page("morale", morale))
    page:add_sub_page(TR["Text"], _module_for_page("text", text))
    return page
end

_module_for_page = function(key, page)
    return {
        key = key,
        create_page = function()
            return page
        end,
    }
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

CompactNestedTabbedPage = class(SettingsTabbedPage)

function CompactNestedTabbedPage:Constructor(window, tab_position, scale_factor, font_size)
    SettingsTabbedPage.Constructor(self, window)
    self._compact_tab_position = tab_position or UI.Widgets.LuiTabBar.position.left
    self._compact_tab_scale_factor = scale_factor or NESTED_TAB_SCALE
    self._compact_tab_font_size = font_size or NESTED_TAB_FONT_SIZE
    self.show_main_content_border = false

    self.sub_tab_bar:set_tab_position(self._compact_tab_position)
    self.sub_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.button)
    self.sub_tab_bar:set_show_content_border(true)
    self.sub_tab_bar:set_button_side_margin(0)
    self.sub_tab_bar:set_button_content_gap(_scaled_int(SECTION_FRAME_PADDING))
    self.sub_tab_bar:set_content_padding(0)
    _apply_button_tab_bar_theme(self.sub_tab_bar)
end

function CompactNestedTabbedPage:apply_ui_scale()
    self.sub_tab_bar:set_tab_position(self._compact_tab_position)
    self.sub_tab_bar:set_show_content_border(true)
    self.sub_tab_bar:set_button_side_margin(0)
    self.sub_tab_bar:set_button_content_gap(_scaled_int(SECTION_FRAME_PADDING))
    self.sub_tab_bar:set_content_padding(0)
    self.sub_tab_bar:set_scale(_G.settings.global.scale * self._compact_tab_scale_factor)
    self.sub_tab_bar:set_font(_scaled_font("Verdana", self._compact_tab_font_size))
    _apply_button_tab_bar_theme(self.sub_tab_bar)

    self.sub_tab_bar:each_widget(function(_, page)
        if page.apply_ui_scale ~= nil then
            page:apply_ui_scale()
        end
    end)

    self:layout()
end

function CompactNestedTabbedPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    if self._compact_tab_position == UI.Widgets.LuiTabBar.position.left or
        self._compact_tab_position == UI.Widgets.LuiTabBar.position.right then
        local gap = self.window.col_gap
        local side_col_w = math.floor((width - (2 * gap)) / 4)
        if side_col_w < _scaled_int(74) then
            side_col_w = _scaled_int(74)
        end
        self.sub_tab_bar:set_side_tab_width(side_col_w)
    else
        self.sub_tab_bar:set_side_tab_width(nil)
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, height)
    self.sub_tab_bar:refresh_layout()
end

VitalsUnitPage = class(Turbine.UI.Control)

function VitalsUnitPage:Constructor(window, preview_key, preview_height, preview_refresh_fn)
    Turbine.UI.Control.Constructor(self)

    self.window = window
    self.controls = {}
    self._color_fields = {}
    self._preview_key = preview_key
    self._preview_default_height = preview_height
    self._preview_refresh_fn = preview_refresh_fn
    self._section_order = {}
    self._sections = {}
    self._section_tabs = {}
    self._active_section_key = nil
    self.loading = false

    self.section_tab_bar = UI.Widgets.LuiTabBar()
    self.section_tab_bar:SetParent(self)
    self.section_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.section_tab_bar:set_selection_style(UI.Widgets.LuiTabBar.selection_style.button)
    self.section_tab_bar:set_show_content_border(false)
    self.section_tab_bar:set_content_padding(0)
    _apply_button_tab_bar_theme(self.section_tab_bar)
    self.section_tab_bar.on_tab_changed = function(_, page)
        self:_on_section_changed(page)
    end

    self.section_frame = Turbine.UI.Control()
    self.section_frame:SetParent(self)
    self.section_frame:SetBackColor(CONTENT_BORDER_COLOR)

    self.section_frame_inner = Turbine.UI.Control()
    self.section_frame_inner:SetParent(self.section_frame)
    self.section_frame_inner:SetBackColor(Style.BACKGROUND)

    self.section_frame_body = Turbine.UI.Control()
    self.section_frame_body:SetParent(self.section_frame_inner)
    self.section_frame_body:SetBackColor(Style.BACKGROUND)

    self.preview_holder = {
        kind = "custom",
        key = preview_key,
        height = preview_height,
    }
    self.preview_holder.control = Turbine.UI.Control()
    self.preview_holder.control:SetParent(self)
    self.preview_holder.control:SetMouseVisible(false)
    self.controls[preview_key] = self.preview_holder

    self.refresh_preview = function()
        self._preview_refresh_fn(self.window)
    end

    self.SizeChanged = function()
        self:layout()
    end
end

function VitalsUnitPage:_merge_page_controls(page)
    for key, entry in pairs(page.controls) do
        self.controls[key] = entry
    end

    for i = 1, #page._color_fields do
        self._color_fields[#self._color_fields + 1] = page._color_fields[i]
    end
end

function VitalsUnitPage:add_section(text, key, page)
    local tab = Turbine.UI.Control()
    tab._tab_key = key

    page._tab_key = key
    page:SetParent(self.section_frame_body)
    page:SetVisible(false)

    self._section_order[#self._section_order + 1] = key
    self._sections[key] = page
    self._section_tabs[key] = tab
    self.section_tab_bar:add_tab(text, tab)
    self:_merge_page_controls(page)
    if self._active_section_key == nil then
        self._active_section_key = key
    end
end

function VitalsUnitPage:_sync_active_section_visibility()
    for i = 1, #self._section_order do
        local key = self._section_order[i]
        local page = self._sections[key]
        page:SetVisible(key == self._active_section_key)
    end
end

function VitalsUnitPage:_on_section_changed(tab)
    self._active_section_key = tab._tab_key
    self:_sync_active_section_visibility()

    local page = self._sections[self._active_section_key]

    self:layout()

    if page.on_selected ~= nil then
        page:on_selected()
    elseif page.layout ~= nil then
        page:layout()
    end

    self:refresh_preview()
end

function VitalsUnitPage:on_selected(preferred_key)
    self:layout()
    self:select_section(preferred_key)
end

function VitalsUnitPage:select_section(key)
    if self._sections[key] == nil then
        key = self._active_section_key or self._section_order[1]
    end

    local page = self._section_tabs[key]
    local index = self.section_tab_bar:find_index(function(_, candidate)
        return candidate == page
    end)

    if self.section_tab_bar:get_selected_index() == index then
        self:_on_section_changed(page)
        return
    end

    self.section_tab_bar:select_tab(index)
end

function VitalsUnitPage:each_child_page(fn)
    for i = 1, #self._section_order do
        fn(self._sections[self._section_order[i]])
    end
end

function VitalsUnitPage:apply_ui_scale()
    self.section_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
    self.section_tab_bar:set_show_content_border(false)
    self.section_tab_bar:set_content_padding(0)
    self.section_tab_bar:set_scale(_G.settings.global.scale * SECTION_TAB_SCALE)
    self.section_tab_bar:set_font(_scaled_font("Verdana", SECTION_TAB_FONT_SIZE))
    _apply_button_tab_bar_theme(self.section_tab_bar)

    for i = 1, #self._section_order do
        local page = self._sections[self._section_order[i]]
        if page.apply_ui_scale ~= nil then
            page:apply_ui_scale()
        end
    end

    self:layout()
end

function VitalsUnitPage:close_all_dropdowns()
    for i = 1, #self._section_order do
        local page = self._sections[self._section_order[i]]
        if page.close_all_dropdowns ~= nil then
            page:close_all_dropdowns()
        end
    end
end

function VitalsUnitPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    local section_tab_h = _scaled_int(BASE_TAB_HEIGHT * SECTION_TAB_SCALE)
    local frame_margin = _scaled_int(SECTION_FRAME_PADDING)
    local section_gap = frame_margin
    local preview_h = self.preview_holder.height or self._preview_default_height
    local preview_gap = _scaled_int(PREVIEW_GAP)
    local min_frame_h = _scaled_int(120)
    local min_top_h = section_tab_h + section_gap + min_frame_h
    local top_h = height - preview_h - preview_gap
    if top_h < min_top_h then
        top_h = min_top_h
        preview_h = height - top_h - preview_gap
    end
    if preview_h < _scaled_int(100) then
        preview_h = _scaled_int(100)
        top_h = height - preview_h - preview_gap
    end
    if top_h < 1 then
        top_h = 1
    end

    local frame_x = 0
    local frame_y = section_tab_h + section_gap
    local frame_w = width
    local frame_h = top_h - frame_y
    if frame_w < 1 then
        frame_w = 1
    end
    if frame_h < 1 then
        frame_h = 1
    end

    self.section_tab_bar:SetPosition(0, 0)
    self.section_tab_bar:SetSize(width, section_tab_h)
    self.section_tab_bar:refresh_layout()

    local border = math.max(1, _scaled_int(tonumber(Style.BORDER_WIDTH) or 1))
    local body_pad = frame_margin

    self.section_frame:SetPosition(frame_x, frame_y)
    self.section_frame:SetSize(frame_w, frame_h)

    self.section_frame_inner:SetPosition(border, border)
    self.section_frame_inner:SetSize(math.max(0, frame_w - (border * 2)), math.max(0, frame_h - (border * 2)))

    local inner_w, inner_h = self.section_frame_inner:GetSize()
    self.section_frame_body:SetPosition(body_pad, body_pad)
    self.section_frame_body:SetSize(math.max(0, inner_w - (body_pad * 2)), math.max(0, inner_h - (body_pad * 2)))

    local body_w, body_h = self.section_frame_body:GetSize()
    for i = 1, #self._section_order do
        local page = self._sections[self._section_order[i]]
        page:SetPosition(0, 0)
        page:SetSize(body_w, body_h)
    end

    self.preview_holder.control:SetPosition(0, top_h + preview_gap)
    self.preview_holder.control:SetSize(width, preview_h)
end

local function _new_label_page(window, refresh_preview_fn, columns, prefix, bar_key, label_index)
    local page = _configure_compact_form(SettingsFormPage(window), columns, refresh_preview_fn)
    _add_vitals_label_controls(page, prefix, bar_key, label_index)
    return page
end

local function _new_targets_target_label_page(window, refresh_preview_fn, columns, label_index)
    local page = _configure_compact_form(SettingsFormPage(window), columns, refresh_preview_fn)
    _add_targets_target_label_controls(page, label_index)
    return page
end

local function _new_texts_section(window, refresh_preview_fn, prefix)
    local page = CompactNestedTabbedPage(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_sub_page(TR["Morale 1"], _module_for_page("morale_label1",
        _new_label_page(window, refresh_preview_fn, 3, prefix, "morale", 1)))
    page:add_sub_page(TR["Morale 2"], _module_for_page("morale_label2",
        _new_label_page(window, refresh_preview_fn, 3, prefix, "morale", 2)))
    page:add_sub_page(TR["Power 1"], _module_for_page("power_label1",
        _new_label_page(window, refresh_preview_fn, 3, prefix, "power", 1)))
    page:add_sub_page(TR["Power 2"], _module_for_page("power_label2",
        _new_label_page(window, refresh_preview_fn, 3, prefix, "power", 2)))
    return page
end

local function _new_targets_target_texts_section(window, refresh_preview_fn)
    local page = CompactNestedTabbedPage(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_sub_page(TR["Label 1"], _module_for_page("label1",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 1)))
    page:add_sub_page(TR["Label 2"], _module_for_page("label2",
        _new_targets_target_label_page(window, refresh_preview_fn, 3, 2)))
    return page
end

local function _new_effects_section(window, refresh_preview_fn, prefix)
    local buffs = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_buffs_form(buffs, prefix)

    local debuffs = _configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    _build_debuffs_form(debuffs, prefix)

    local page = CompactNestedTabbedPage(window, UI.Widgets.LuiTabBar.position.left, NESTED_TAB_SCALE,
        NESTED_TAB_FONT_SIZE)
    page:add_sub_page(TR["Buffs"], _module_for_page("buffs", buffs))
    page:add_sub_page(TR["Debuffs"], _module_for_page("debuffs", debuffs))
    return page
end

local function _new_self_unit_page(window)
    local page = VitalsUnitPage(window, "self_vitals_preview", 207, function(win)
        win:update_self_vitals_preview()
    end)

    local frame = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    frame:add_text("self_width", TR["Frame Width"])
    frame:add_text("self_border_width", TR["Border Width"])
    _add_compact_row_break(frame)
    frame:add_text("self_effects_height", TR["Effects Height"])
    _add_compact_row_break(frame)
    frame:add_dropdown("self_effects_position", TR["Effects Position"], frame.vitals_effects_position_labels,
        frame.vitals_effects_position_values)
    _add_compact_row_break(frame)
    frame:add_text("self_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("self_outcombat_opacity", TR["Out-of-combat opacity"])
    _add_compact_row_break(frame)
    frame:add_checkbox("self_ressource_background_matches_missing", TR["Matching background"], true)
    _add_compact_row_break(frame)
    frame:add_text("self_ressource_background_dimming", TR["Dimming"])
    page:add_section(TR["Frame"], "frame", frame)
    page:add_section(TR["Colors"], "colors", _new_standard_colors_section(window, page.refresh_preview, "self", true))

    local morale = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_morale_form(morale, "self")
    page:add_section(TR["Morale"], "morale", morale)

    local power = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_power_form(power, "self", false)
    page:add_section(TR["Power / Wrath"], "power", power)

    page:add_section(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "self"))
    page:add_section(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "self"))

    return page
end

local function _new_target_unit_page(window)
    local page = VitalsUnitPage(window, "target_vitals_preview", 222, function(win)
        win:update_target_vitals_preview()
    end)

    local frame = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    frame:add_text("target_width", TR["Frame Width"])
    frame:add_text("target_border_width", TR["Border Width"])
    _add_compact_row_break(frame)
    frame:add_text("target_effects_height", TR["Effects Height"])
    _add_compact_row_break(frame)
    frame:add_dropdown("target_effects_position", TR["Effects Position"], frame.vitals_effects_position_labels,
        frame.vitals_effects_position_values)
    _add_compact_row_break(frame)
    frame:add_text("target_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("target_outcombat_opacity", TR["Out-of-combat opacity"])
    _add_compact_row_break(frame)
    frame:add_checkbox("target_ressource_background_matches_missing", TR["Matching background"], true)
    _add_compact_row_break(frame)
    frame:add_text("target_ressource_background_dimming", TR["Dimming"])
    page:add_section(TR["Frame"], "frame", frame)
    page:add_section(TR["Colors"], "colors", _new_standard_colors_section(window, page.refresh_preview, "target", true))

    local morale = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target")
    page:add_section(TR["Morale"], "morale", morale)

    local power = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_power_form(power, "target", false)
    page:add_section(TR["Power / Wrath"], "power", power)

    page:add_section(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target"))
    page:add_section(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target"))

    return page
end

local function _new_boss_unit_page(window)
    local page = VitalsUnitPage(window, "target_boss_vitals_preview", 178, function(win)
        win:update_target_boss_vitals_preview()
    end)

    local frame = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    frame:add_text("target_boss_width", TR["Frame Width"])
    frame:add_text("target_boss_border_width", TR["Border Width"])
    _add_compact_row_break(frame)
    frame:add_text("target_boss_effects_height", TR["Effects Height"])
    _add_compact_row_break(frame)
    frame:add_text("target_boss_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("target_boss_outcombat_opacity", TR["Out-of-combat opacity"])
    _add_compact_row_break(frame)
    frame:add_checkbox("target_boss_ressource_background_matches_missing", TR["Matching background"],
        true)
    _add_compact_row_break(frame)
    frame:add_text("target_boss_ressource_background_dimming", TR["Dimming"])
    page:add_section(TR["Frame"], "frame", frame)
    page:add_section(TR["Colors"], "colors", _new_standard_colors_section(window, page.refresh_preview, "target_boss", true))

    local morale = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_morale_form(morale, "target_boss")
    page:add_section(TR["Morale"], "morale", morale)

    local power = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_power_form(power, "target_boss", true)
    page:add_section(TR["Power / Wrath"], "power", power)

    page:add_section(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "target_boss"))
    page:add_section(TR["Effects"], "effects", _new_effects_section(window, page.refresh_preview, "target_boss"))

    return page
end

local function _new_targets_target_unit_page(window)
    local page = VitalsUnitPage(window, "target_targets_target_preview", 133, function(win)
        win:update_target_targets_target_preview()
    end)

    local frame = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    frame:add_text("target_targets_target_width", TR["Frame Width"])
    frame:add_text("target_targets_target_height", TR["Bar Height"])
    frame:add_text("target_targets_target_border_width", TR["Border Width"])
    _add_compact_row_break(frame)
    frame:add_checkbox("target_targets_target_background_matches_missing", TR["Matching background"],
        true)
    _add_compact_row_break(frame)
    frame:add_text("target_targets_target_background_dimming", TR["Dimming"])
    _add_compact_row_break(frame)
    frame:add_text("target_targets_target_bubble_text", TR["Bubble Format (%B)"], false, frame.bubble_format_help,
        true)
    page:add_section(TR["Frame"], "frame", frame)
    page:add_section(TR["Colors"], "colors", _new_targets_target_colors_section(window, page.refresh_preview))

    page:add_section(TR["Texts"], "texts", _new_targets_target_texts_section(window, page.refresh_preview))

    return page
end

local function _new_party_unit_page(window)
    local page = VitalsUnitPage(window, "party_vitals_preview", 178, function(win)
        win:update_party_vitals_preview()
    end)

    local frame = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    frame.on_scroll_changed = function()
        window:update_party_vitals_preview()
    end
    frame:add_text("party_width", TR["Frame Width"])
    frame:add_text("party_border_width", TR["Border Width"])
    _add_compact_row_break(frame)
    frame:add_text("party_rows", TR["Rows per Column"])
    _add_compact_row_break(frame)
    frame:add_text("party_spacing_x", TR["Column Spacing"])
    frame:add_text("party_spacing_y", TR["Row Spacing"])
    _add_compact_row_break(frame)
    frame:add_text("party_incombat_opacity", TR["In-combat opacity"])
    frame:add_text("party_outcombat_opacity", TR["Out-of-combat opacity"])
    _add_compact_row_break(frame)
    frame:add_checkbox("party_ressource_background_matches_missing", TR["Matching background"], true)
    _add_compact_row_break(frame)
    frame:add_text("party_ressource_background_dimming", TR["Dimming"])
    page:add_section(TR["Frame"], "frame", frame)
    page:add_section(TR["Colors"], "colors", _new_standard_colors_section(window, page.refresh_preview, "party", false))

    local morale = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_morale_form(morale, "party")
    page:add_section(TR["Morale"], "morale", morale)

    local power = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    _build_standard_power_form(power, "party", false)
    page:add_section(TR["Power / Wrath"], "power", power)

    page:add_section(TR["Texts"], "texts", _new_texts_section(window, page.refresh_preview, "party"))

    local icons = _configure_compact_form(SettingsFormPage(window), 4, page.refresh_preview)
    icons:add_checkbox("party_class_icon_enabled", TR["Show class icon"], true)
    _add_compact_row_break(icons)
    icons:add_text("party_class_icon_size", TR["Icon Size"])
    _add_compact_row_break(icons)
    icons:add_text("party_class_icon_x", TR["Icon X"])
    icons:add_text("party_class_icon_y", TR["Icon Y"])
    _add_compact_row_break(icons)
    icons:add_checkbox("party_leader_icon_enabled", TR["Show leader icon"], true)
    _add_compact_row_break(icons)
    icons:add_text("party_leader_icon_size", TR["Leader Icon Size"])
    _add_compact_row_break(icons)
    icons:add_text("party_leader_icon_x", TR["Leader Icon X"])
    icons:add_text("party_leader_icon_y", TR["Leader Icon Y"])
    page:add_section(TR["Icons"], "icons", icons)

    return page
end

local function _new_general_page(window)
    local page = _configure_compact_form(SettingsFormPage(window), 4, nil)
    page:add_title(TR["General"])
    page:add_checkbox("target_boss_enabled", TR["Enable boss vitals"], true)
    return page
end

VitalsPage = class(SettingsTabbedPage)

function VitalsPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(_scaled_int(SECTION_FRAME_PADDING))

    self:add_sub_page(TR["General"], _module_for_page("general", _new_general_page(window)))
    self:add_sub_page(TR["Self"], _module_for_page("self", _new_self_unit_page(window)))
    self:add_sub_page(TR["Target"], _module_for_page("target", _new_target_unit_page(window)))
    self:add_sub_page(TR["Boss"], _module_for_page("boss", _new_boss_unit_page(window)))
    self:add_sub_page(TR["Target's Target"], _module_for_page("target_targets_target",
        _new_targets_target_unit_page(window)))
    self:add_sub_page(TR["Party"], _module_for_page("party", _new_party_unit_page(window)))
end

function VitalsPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
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
