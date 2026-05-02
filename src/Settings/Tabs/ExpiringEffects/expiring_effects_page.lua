import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.Settings.Tabs.Self.self_expiring_effects"
import "LUI.src.Settings.Tabs.Target.expiring_target_effects"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or
    _G.SettingsFormPage or SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local configure_compact_form = FeatureShell.configure_compact_form
local add_compact_row_break = FeatureShell.add_compact_row_break
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int
local SelfExpiringEffects = LUI.src.Settings.Tabs.Self.SelfExpiringEffects
local ExpiringTargetEffects = LUI.src.Settings.Tabs.Target.ExpiringTargetEffects

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _bind_outline_visibility(owner_page, nested_text_page, style_key, outline_key)
    owner_page.controls[outline_key].visible_if = function()
        return _is_outline(owner_page.controls[style_key])
    end

    local prev = owner_page.controls[style_key].on_changed
    owner_page.controls[style_key].on_changed = function(value)
        if prev ~= nil then
            prev(value)
        end
        nested_text_page:layout()
        owner_page:layout()
    end
end

local function _new_general_page(window, refresh_preview_fn, prefix)
    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_checkbox(prefix .. "_enabled", TR["Enabled"], true)
    add_compact_row_break(page)
    page:add_checkbox(prefix .. "_show_buffs", TR["Track buffs"], false)
    page:add_checkbox(prefix .. "_show_curable_debuffs", TR["Track curable debuffs"], false)
    page:add_checkbox(prefix .. "_show_noncurable_debuffs", TR["Track non-curable debuffs"], false)
    add_compact_row_break(page)
    page:add_text(prefix .. "_threshold", TR["Show when less than seconds remaining"])
    return page
end

local function _new_layout_page(window, refresh_preview_fn, prefix)
    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_text(prefix .. "_bar_width", TR["Bar Width"])
    page:add_text(prefix .. "_bar_height", TR["Bar Height"])
    page:add_text(prefix .. "_border_width", TR["Border Width"])
    add_compact_row_break(page)
    page:add_text(prefix .. "_columns", TR["Columns"])
    page:add_text(prefix .. "_rows", TR["Rows"])
    page:add_text(prefix .. "_spacing", TR["Spacing"])
    add_compact_row_break(page)
    page:add_dropdown(prefix .. "_icon_side", TR["Icon position"], page.side_labels, page.side_values)
    page:add_dropdown(prefix .. "_bar_expire_towards", TR["Bar expires towards"], page.side_labels, page.side_values)
    return page
end

local function _new_frame_colors_page(window, refresh_preview_fn, prefix)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    page:add_text(prefix .. "_background_color", TR["Background Color"], true)
    page:add_text(prefix .. "_border_color", TR["Border Color"], true)
    return page
end

local function _new_bars_colors_page(window, refresh_preview_fn, specs)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    for i = 1, #specs do
        page:add_text(specs[i].key, specs[i].label, true)
    end
    return page
end

local function _new_text_colors_page(window, refresh_preview_fn, prefix)
    local page = configure_compact_form(SettingsFormPage(window), 3, refresh_preview_fn)
    page:add_text(prefix .. "_font_color", TR["Font Color"], true)
    page:add_text(prefix .. "_font_outline_color", TR["Outline Color"], true)
    return page
end

local function _new_text_page(window, refresh_preview_fn, prefix)
    local page = configure_compact_form(SettingsFormPage(window), 4, refresh_preview_fn)
    page:add_text(prefix .. "_name_max_chars", TR["Max name characters"])
    add_compact_row_break(page)
    page:add_dropdown(prefix .. "_font_name", TR["Font"], page.font_name_labels, page.font_name_values)
    page:add_text(prefix .. "_font_size", TR["Font Size"])
    page:add_dropdown(prefix .. "_font_style", TR["Font Style"], page.font_style_labels, page.font_style_values)
    return page
end

local function _new_colors_section(window, refresh_preview_fn, prefix, bar_specs)
    local frame = _new_frame_colors_page(window, refresh_preview_fn, prefix)
    local bars = _new_bars_colors_page(window, refresh_preview_fn, bar_specs)
    local text = _new_text_colors_page(window, refresh_preview_fn, prefix)

    local page = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_sub_page(TR["Frame"], module_for_page("frame", frame))
    page:add_sub_page(TR["Bars"], module_for_page("bars", bars))
    page:add_sub_page(TR["Text"], module_for_page("text", text))

    return page, text
end

local function _new_actor_page(window, preview_key, preview_height, refresh_preview_fn, prefix, bar_specs)
    local page = SettingsFeatureSectionPage(window, preview_key, preview_height, refresh_preview_fn)
    page:add_section(TR["General"], "general", _new_general_page(window, page.refresh_preview, prefix))
    page:add_section(TR["Layout"], "layout", _new_layout_page(window, page.refresh_preview, prefix))
    local colors, colors_text = _new_colors_section(window, page.refresh_preview, prefix, bar_specs)
    page:add_section(TR["Colors"], "colors", colors)
    page:add_section(TR["Text"], "text", _new_text_page(window, page.refresh_preview, prefix))
    _bind_outline_visibility(page, colors_text, prefix .. "_font_style", prefix .. "_font_outline_color")
    return page
end

ExpiringEffectsPage = class(SettingsTabbedPage)

function ExpiringEffectsPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local self_bar_specs = {
        { key = "expiring_effects_bar_color", label = TR["Buff Bar Color"] },
        { key = "expiring_effects_debuff_curable_bar_color", label = TR["Curable Debuff Bar Color"] },
        { key = "expiring_effects_debuff_noncurable_bar_color", label = TR["Non-curable Debuff Bar Color"] },
    }
    local target_bar_specs = {
        { key = "expiring_target_effects_buff_bar_color", label = TR["Buff Bar Color"] },
        { key = "expiring_target_effects_bar_color", label = TR["Curable Debuff Bar Color"] },
        { key = "expiring_target_effects_debuff_noncurable_bar_color", label = TR["Non-curable Debuff Bar Color"] },
    }

    self:add_sub_page(TR["Self"], module_for_page("self", _new_actor_page(window, "expiring_effects_preview", 53,
        function(win)
            win:update_expiring_effects_preview()
        end, "expiring_effects", self_bar_specs)))
    self:add_sub_page(TR["Target"], module_for_page("target", _new_actor_page(window,
        "expiring_target_effects_preview", 71, function(win)
            win:update_expiring_target_effects_preview()
        end, "expiring_target_effects", target_bar_specs)))
end

function ExpiringEffectsPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function ExpiringEffectsPage:load_from_settings(s, ui)
    SelfExpiringEffects.load(self._sub_pages.self, s, ui)
    ExpiringTargetEffects.load(self._sub_pages.target, s, ui)
end

function ExpiringEffectsPage:apply_to_settings(s, ui)
    SelfExpiringEffects.apply(self._sub_pages.self, s, ui)
    ExpiringTargetEffects.apply(self._sub_pages.target, s, ui)
end
