import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.nested_tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local scaled_int = FeatureShell.scaled_int
local PREVIEW_GAP = 10
local PREVIEW_MIN_TOP_HEIGHT = 120
local PREVIEW_MIN_HEIGHT = 100

local function _is_outline(control)
    return control:get_value() == LUI_ENUMS.font_style.OUTLINE
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

    page.window:bind_tooltip(entry.tb, help_text)

    entry.apply_ui_scale = function()
        entry.label:SetFont(page.window.field_label_font)
        entry.tb:SetFont(page.window.input_font)
        _layout_text_area(entry)
    end

    function entry:refresh_text()
        self.tb:SetText(self.tb:GetText())
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

local function _new_colors_section(window, refresh_preview, settings_getter)
    local ui = window._ui

    local frame = ConfigContent(window, 3, refresh_preview)
    frame:add_color_picker(TR["Background color"], "cd_bg_color",
        function(value)
            settings_getter().color.background = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().color.background))
        end)
    frame:add_color_picker(TR["Border color"], "cd_border_color",
        function(value)
            settings_getter().color.border = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().color.border))
        end)

    local bar = ConfigContent(window, 3, refresh_preview)
    bar:add_color_picker(TR["Bar color"], "cd_bar_color",
        function(value)
            settings_getter().color.bar = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().color.bar))
        end)

    local text = ConfigContent(window, 3, refresh_preview)
    text:add_color_picker(TR["Font color"], "cd_font_color",
        function(value)
            settings_getter().font.color = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.color))
        end)
    text:add_color_picker(TR["Outline color"], "cd_font_outline_color",
        function(value)
            settings_getter().font.outline_color = ui.hex_to_color(value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().font.outline_color))
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Bar"], "bar", bar)
    page:add_tab(TR["Text"], "text", text)

    return page, text
end

CooldownsFeaturePage = class(ConfigTabs)

function CooldownsFeaturePage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self._preview_default_height = 52
    self.controls = self.controls or {}

    local flow_labels = { TR["Top to bottom"], TR["Bottom to top"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local bar_mode_labels = { TR["Load"], TR["Unload"] }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }
    local time_format_labels = { TR["Auto precision"], TR["Whole seconds"] }
    local time_format_values = {
        LUI_ENUMS.cooldown_time_format.AUTO,
        LUI_ENUMS.cooldown_time_format.WHOLE_SECONDS,
    }
    local min_base_help = TR["Skills whose base cooldown is below this value are ignored."]
    local list_help = TR["One skill name per line or comma-separated. Case-insensitive. Exact match or prefix with trailing *."]
    local refresh_preview = function()
        window:update_cooldowns_preview()
    end
    local settings_getter = function()
        return self._settings.self.cooldowns
    end

    local general = ConfigContent(window, 4, refresh_preview)
    general:add_checkbox(TR["Enabled"], "cd_enabled",
        function(value)
            settings_getter().enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().enabled == true)
        end, true)
    general:break_line()
    general:add_line_edit(TR["Threshold (s)"], "cd_threshold",
        function(value)
            local threshold = tonumber(value)
            if threshold ~= nil then
                settings_getter().threshold = threshold
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().threshold))
        end)
    general:add_line_edit(TR["Min base cooldown (s)"], "cd_min_base_cooldown",
        function(value)
            local min_base_cooldown = tonumber(value)
            if min_base_cooldown ~= nil then
                settings_getter().min_base_cooldown = min_base_cooldown
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().min_base_cooldown))
        end, min_base_help)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, refresh_preview)
    layout:add_line_edit(TR["Item width"], "cd_item_w",
        function(value)
            local item_w = tonumber(value)
            if item_w ~= nil then
                settings_getter().item_w = item_w
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().item_w))
        end)
    layout:add_line_edit(TR["Item height"], "cd_item_h",
        function(value)
            local item_h = tonumber(value)
            if item_h ~= nil then
                settings_getter().item_h = item_h
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().item_h))
        end)
    layout:add_line_edit(TR["Spacing (px)"], "cd_spacing",
        function(value)
            local spacing = tonumber(value)
            if spacing ~= nil then
                settings_getter().spacing = spacing
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().spacing))
        end)
    layout:add_line_edit(TR["Border width (px)"], "cd_border_width",
        function(value)
            local border_width = tonumber(value)
            if border_width ~= nil then
                settings_getter().border_width = border_width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().border_width))
        end)
    layout:add_line_edit(TR["Columns"], "cd_columns",
        function(value)
            local columns = tonumber(value)
            if columns ~= nil then
                settings_getter().columns = columns
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().columns))
        end)
    layout:add_line_edit(TR["Rows"], "cd_rows",
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().rows))
        end)
    layout:break_line()
    layout:add_dropdown(TR["Order"], "cd_flow", flow_labels, flow_values,
        function(value)
            settings_getter().flow = value
        end,
        function(entry)
            entry:set_value(settings_getter().flow)
        end)
    layout:add_dropdown(TR["Icon position"], "cd_icon_side", layout.side_labels, layout.side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function(entry)
            entry:set_value(settings_getter().icon_side)
        end)
    layout:break_line()
    layout:add_dropdown(TR["Bar mode"], "cd_bar_mode", bar_mode_labels, bar_mode_values,
        function(value)
            settings_getter().bar_mode = value
        end,
        function(entry)
            entry:set_value(settings_getter().bar_mode)
        end)
    layout:add_dropdown(TR["Bar movement towards"], "cd_bar_expire_towards", layout.side_labels, layout.side_values,
        function(value)
            settings_getter().bar_expire_towards = value
        end,
        function(entry)
            entry:set_value(settings_getter().bar_expire_towards)
        end)
    self:add_tab(TR["Layout"], "layout", layout)

    local colors, colors_text = _new_colors_section(window, refresh_preview, settings_getter)
    self:add_tab(TR["Colors"], "colors", colors)

    local text = ConfigContent(window, 4, refresh_preview)
    text:add_dropdown(TR["Time format"], "cd_time_format", time_format_labels, time_format_values,
        function(value)
            settings_getter().time_format = value
        end,
        function(entry)
            entry:set_value(settings_getter().time_format)
        end)
    text:add_line_edit(TR["Text margin (px)"], "cd_text_margin",
        function(value)
            local text_margin = tonumber(value)
            if text_margin ~= nil then
                settings_getter().text_margin = text_margin
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().text_margin))
        end)
    text:add_line_edit(TR["Max name chars"], "cd_name_max_chars",
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
    text:add_dropdown(TR["Font"], "cd_font_name", text.font_name_labels, text.font_name_values,
        function(value)
            settings_getter().font.name = value
        end,
        function(entry)
            entry:set_value(settings_getter().font.name)
        end)
    text:add_line_edit(TR["Font size"], "cd_font_size",
        function(value)
            local font_size = tonumber(value)
            if font_size ~= nil then
                settings_getter().font.size = font_size
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().font.size))
        end)
    text:add_dropdown(TR["Font style"], "cd_font_style", text.font_style_labels, text.font_style_values,
        function(value)
            settings_getter().font.style = value
        end,
        function(entry)
            entry.set_value(entry, settings_getter().font.style)
        end)
    self:add_tab(TR["Text"], "text", text)

    local filters = ConfigContent(window, 1, refresh_preview)
    local whitelist = _create_text_area(filters, "cd_whitelist", TR["Whitelist"], list_help)
    filters:bind(whitelist,
        function(value)
            settings_getter().whitelist = value
        end,
        function(entry)
            entry.tb:SetText(settings_getter().whitelist)
        end)
    filters:add_break()
    local blacklist = _create_text_area(filters, "cd_blacklist", TR["Blacklist"], list_help)
    filters:bind(blacklist,
        function(value)
            settings_getter().blacklist = value
        end,
        function(entry)
            entry.tb:SetText(settings_getter().blacklist)
        end)
    self:add_tab(TR["Filters"], "filters", filters)

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
    ConfigTabs.apply_ui_scale(self)
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

function CooldownsFeaturePage:load_from_settings(s)
    self._settings = s
    self:load()
end

function CooldownsFeaturePage:apply_to_settings(s)
    self._settings = s
    self:save()
end
