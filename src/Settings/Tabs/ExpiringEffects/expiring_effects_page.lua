import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.section_page"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local ConfigSectionPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_section_page) or
    ConfigSectionPage
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
end

local function _apply_color(ui, dest, hex)
    local color = ui.hex_to_color(hex)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
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

local function _new_colors_section(window, refresh_preview, settings_getter, prefix, bar_specs)
    local ui = window._ui

    local frame = ConfigContent(window, 3, refresh_preview)
    frame:add_color_picker(TR["Background Color"], prefix .. "_background_color",
        function(value)
            _apply_color(ui, settings_getter().color.background, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().color.background))
        end)
    frame:add_color_picker(TR["Border Color"], prefix .. "_border_color",
        function(value)
            _apply_color(ui, settings_getter().color.border, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().color.border))
        end)

    local bars = ConfigContent(window, 3, refresh_preview)
    for i = 1, #bar_specs do
        local spec = bar_specs[i]
        bars:add_color_picker(spec.label, spec.key,
            function(value)
                _apply_color(ui, spec.get_target(settings_getter()), value)
            end,
            function(entry)
                entry.tb:SetText(ui.color_to_hex(spec.get_target(settings_getter())))
            end)
    end

    local text = ConfigContent(window, 3, refresh_preview)
    text:add_color_picker(TR["Font Color"], prefix .. "_font_color",
        function(value)
            _apply_color(ui, settings_getter().font.color, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.color))
        end)
    text:add_color_picker(TR["Outline Color"], prefix .. "_font_outline_color",
        function(value)
            _apply_color(ui, settings_getter().font.outline_color, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.outline_color))
        end)

    local page = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_sub_page(TR["Frame"], module_for_page("frame", frame))
    page:add_sub_page(TR["Bars"], module_for_page("bars", bars))
    page:add_sub_page(TR["Text"], module_for_page("text", text))

    function page:load()
        frame:load()
        bars:load()
        text:load()
    end

    function page:save()
        frame:save()
        bars:save()
        text:save()
    end

    return page, text
end

local function _new_actor_page(window, preview_key, preview_height, refresh_preview_fn, prefix, settings_getter, bar_specs)
    local page = ConfigSectionPage(window, preview_key, preview_height, refresh_preview_fn)

    local general = ConfigContent(window, 4, page.refresh_preview)
    general:add_checkbox(TR["Enabled"], prefix .. "_enabled",
        function(value)
            settings_getter().enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().enabled == true)
        end, true)
    general:break_line()
    general:add_checkbox(TR["Track buffs"], prefix .. "_show_buffs",
        function(value)
            settings_getter().show_buffs = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().show_buffs == true)
        end, false)
    general:add_checkbox(TR["Track curable debuffs"], prefix .. "_show_curable_debuffs",
        function(value)
            settings_getter().show_curable_debuffs = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().show_curable_debuffs ~= false)
        end, false)
    general:add_checkbox(TR["Track non-curable debuffs"], prefix .. "_show_noncurable_debuffs",
        function(value)
            settings_getter().show_noncurable_debuffs = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().show_noncurable_debuffs ~= false)
        end, false)
    general:break_line()
    general:add_line_edit(TR["Show when less than seconds remaining"], prefix .. "_threshold",
        function(value)
            local threshold = tonumber(value)
            if threshold ~= nil then
                settings_getter().threshold = threshold
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().threshold))
        end)
    page:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, page.refresh_preview)
    layout:add_line_edit(TR["Bar Width"], prefix .. "_bar_width",
        function(value)
            local bar_width = tonumber(value)
            if bar_width ~= nil then
                settings_getter().bar_width = bar_width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().bar_width))
        end)
    layout:add_line_edit(TR["Bar Height"], prefix .. "_bar_height",
        function(value)
            local bar_height = tonumber(value)
            if bar_height ~= nil then
                settings_getter().bar_height = bar_height
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().bar_height))
        end)
    layout:add_line_edit(TR["Border Width"], prefix .. "_border_width",
        function(value)
            local border_width = tonumber(value)
            if border_width ~= nil then
                settings_getter().border_width = border_width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().border_width))
        end)
    layout:break_line()
    layout:add_line_edit(TR["Columns"], prefix .. "_columns",
        function(value)
            local columns = tonumber(value)
            if columns ~= nil then
                settings_getter().columns = columns
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().columns))
        end)
    layout:add_line_edit(TR["Rows"], prefix .. "_rows",
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().rows))
        end)
    layout:add_line_edit(TR["Spacing"], prefix .. "_spacing",
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().spacing))
        end)
    layout:break_line()
    layout:add_dropdown(TR["Icon position"], prefix .. "_icon_side", layout.side_labels, layout.side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function(entry)
            entry:set_value(settings_getter().icon_side)
        end)
    layout:add_dropdown(TR["Bar expires towards"], prefix .. "_bar_expire_towards", layout.side_labels,
        layout.side_values,
        function(value)
            settings_getter().bar_expire_towards = value
        end,
        function(entry)
            entry:set_value(settings_getter().bar_expire_towards)
        end)
    page:add_tab(TR["Layout"], "layout", layout)

    local colors, colors_text = _new_colors_section(window, page.refresh_preview, settings_getter, prefix, bar_specs)
    page:add_tab(TR["Colors"], "colors", colors)

    local text = ConfigContent(window, 4, page.refresh_preview)
    text:add_line_edit(TR["Max name characters"], prefix .. "_name_max_chars",
        function(value)
            local name_max_chars = tonumber(value)
            if name_max_chars ~= nil then
                settings_getter().name_max_chars = name_max_chars
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().name_max_chars))
        end)
    text:break_line()
    text:add_dropdown(TR["Font"], prefix .. "_font_name", text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function(entry)
            entry:set_value(settings_getter().font.name)
        end)
    text:add_line_edit(TR["Font Size"], prefix .. "_font_size",
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().font.size))
        end)
    text:add_dropdown(TR["Font Style"], prefix .. "_font_style", text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function(entry)
            entry:set_value(settings_getter().font.style)
        end)
    page:add_tab(TR["Text"], "text", text)

    _bind_outline_visibility(page, colors_text, prefix .. "_font_style", prefix .. "_font_outline_color")
    return page
end

ExpiringEffectsPage = class(ConfigTabs)

function ExpiringEffectsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local self_bar_specs = {
        {
            key = "expiring_effects_bar_color",
            label = TR["Buff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_buff or settings.color.bar
            end,
        },
        {
            key = "expiring_effects_debuff_curable_bar_color",
            label = TR["Curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_curable or settings.color.bar
            end,
        },
        {
            key = "expiring_effects_debuff_noncurable_bar_color",
            label = TR["Non-curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_noncurable or settings.color.bar
            end,
        },
    }
    local target_bar_specs = {
        {
            key = "expiring_target_effects_buff_bar_color",
            label = TR["Buff Bar Color"],
            get_target = function(settings_getter)
                return settings_getter().color.bar_buff
            end,
        },
        {
            key = "expiring_target_effects_bar_color",
            label = TR["Curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_curable or settings.color.bar
            end,
        },
        {
            key = "expiring_target_effects_debuff_noncurable_bar_color",
            label = TR["Non-curable Debuff Bar Color"],
            get_target = function(settings_getter)
                local settings = settings_getter()
                return settings.color.bar_debuff_noncurable or settings.color.bar
            end,
        },
    }

    self:add_tab(TR["Self"], "self", _new_actor_page(window, "expiring_effects_preview", 53,
        function(win)
            win:update_expiring_effects_preview()
        end, "expiring_effects", function()
            return self._settings.self.expiring_effects
        end, self_bar_specs))
    self:add_tab(TR["Target"], "target", _new_actor_page(window, "expiring_target_effects_preview", 71,
        function(win)
            win:update_expiring_target_effects_preview()
        end, "expiring_target_effects", function()
            return self._settings.target.expiring_effects
        end, target_bar_specs))
end

function ExpiringEffectsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function ExpiringEffectsPage:load_from_settings(s)
    self._settings = s
    self:load()
end

function ExpiringEffectsPage:apply_to_settings(s)
    self._settings = s
    self:save()
end
