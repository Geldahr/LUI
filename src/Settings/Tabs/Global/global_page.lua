import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.nested_tabs"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local ConfigSectionPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_section_page) or
    ConfigSectionPage
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local scaled_int = FeatureShell.scaled_int
local Style = UI.Widgets.Style

local STYLE_FONT_NAME_LABELS = {
    "Verdana",
    "BookAntiqua",
    "BookAntiquaBold",
    "TrajanPro",
    "TrajanProBold",
    "Arial",
    "FixedSys",
    "LucidaConsole",
    "VerdanaBold",
}

local STYLE_FONT_NAME_VALUES = {
    "Verdana",
    "BookAntiqua",
    "BookAntiquaBold",
    "TrajanPro",
    "TrajanProBold",
    "Arial",
    "FixedSys",
    "LucidaConsole",
    "VerdanaBold",
}

local function _style_settings(settings)
    return settings.global.style
end

local function _style_override_value(style, key)
    local value = style[key]
    if value ~= nil then
        return value
    end

    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        return _style_override_value(style, fallback)
    end

    return nil
end

local function _dev_style_value(key)
    if _G.STYLE ~= nil then
        local value = _style_override_value(_G.STYLE, key)
        if value ~= nil then
            return value
        end
    end

    return Style.DEFAULTS[key]
end

local function _style_value(settings, key)
    local style = _style_settings(settings)
    local value = style[key]
    if value ~= nil then
        return value, true
    end

    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        local inherited = _style_override_value(style, fallback)
        if inherited ~= nil then
            return inherited, false
        end
    end

    return _dev_style_value(key), false
end

local function _style_inherited_value(settings, key)
    local style = _style_settings(settings)
    local fallback = Style.FALLBACKS[key]
    if fallback ~= nil then
        local inherited = _style_override_value(style, fallback)
        if inherited ~= nil then
            return inherited
        end
    end
    return _dev_style_value(key)
end

local function _same_color_hex(page, left, right)
    return page.color_to_hex(left) == page.color_to_hex(right)
end

local function _color_alpha(color)
    local value = tonumber(color.A)
    if value == nil then
        return 1
    end
    return value
end

local function _color_with_alpha(color, alpha)
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _opacity_value(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    if number < 0 then
        number = 0
    elseif number > 1 then
        number = 1
    end
    return math.floor((number * 100) + 0.5) / 100
end

local function _opacity_text(value)
    return string.format("%.2f", _opacity_value(value) or 1)
end

local function _same_style_color(page, left, right)
    return _same_color_hex(page, left, right) == true and _opacity_text(_color_alpha(left)) == _opacity_text(_color_alpha(right))
end

local function _style_control_key(key)
    return "global_ui_style_" .. string.lower(key)
end

local function _add_style_color(page, settings_getter, key, label)
    local entry = nil
    entry = page:add_color_picker(_style_control_key(key), label,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local color = page.hex_to_color(value)
            local current = _style_value(settings_getter(), key)
            color = _color_with_alpha(color, _color_alpha(current))
            local style = _style_settings(settings_getter())
            if _same_style_color(page, color, _style_inherited_value(settings_getter(), key)) == true then
                style[key] = nil
            else
                style[key] = color
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local hex = page.color_to_hex(value)
            entry._loaded_value = hex
            entry._loaded_direct = direct == true
            entry._style_default_value = page.color_to_hex(Style.DEFAULTS[key])
            return hex
        end)
    return entry
end

local function _add_style_opacity(page, settings_getter, key, label)
    local entry = nil
    entry = page:add_line_edit(_style_control_key(key) .. "_opacity", label,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local alpha = _opacity_value(value)
            if alpha ~= nil then
                local current = _style_value(settings_getter(), key)
                local color = _color_with_alpha(current, alpha)
                local style = _style_settings(settings_getter())
                if _same_style_color(page, color, _style_inherited_value(settings_getter(), key)) == true then
                    style[key] = nil
                else
                    style[key] = color
                end
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local text = _opacity_text(_color_alpha(value))
            entry._loaded_value = text
            entry._loaded_direct = direct == true
            entry._style_default_value = _opacity_text(_color_alpha(Style.DEFAULTS[key]))
            return text
        end)
    return entry
end

local function _add_style_number(page, settings_getter, key, label)
    local entry = nil
    entry = page:add_line_edit(_style_control_key(key), label,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local number = tonumber(value)
            if number ~= nil then
                local style = _style_settings(settings_getter())
                if number == tonumber(_style_inherited_value(settings_getter(), key)) then
                    style[key] = nil
                else
                    style[key] = number
                end
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            local text = tostring(value)
            entry._loaded_value = text
            entry._loaded_direct = direct == true
            entry._style_default_value = tostring(Style.DEFAULTS[key])
            return text
        end)
    return entry
end

local function _add_style_font_name(page, settings_getter, key, label)
    local entry = nil
    entry = page:add_dropdown(_style_control_key(key), label, STYLE_FONT_NAME_LABELS, STYLE_FONT_NAME_VALUES,
        function(value)
            if entry._loaded_direct ~= true and value == entry._loaded_value then
                return
            end

            local style = _style_settings(settings_getter())
            if value == _style_inherited_value(settings_getter(), key) then
                style[key] = nil
            else
                style[key] = value
            end
        end,
        function()
            local value, direct = _style_value(settings_getter(), key)
            entry._loaded_value = value
            entry._loaded_direct = direct == true
            entry._style_default_value = Style.DEFAULTS[key]
            return value
        end)
    return entry
end

local function _reset_style_controls(page, settings_getter)
    local style = _style_settings(settings_getter())
    for key in pairs(style) do
        style[key] = nil
    end
    page:load()
    page.window:update_all_swatches()
    page:layout()
end

local function _add_reset_button(page, content, settings_getter)
    return content:add_button("global_ui_style_reset", TR["Reset shared UI style"], function()
        _reset_style_controls(page, settings_getter)
    end)
end

local function _new_ui_colors_section(window, settings_getter)
    local frame = ConfigContent(window, 3)
    _add_style_color(frame, settings_getter, "CONTROL_BORDER", TR["Border color"])
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_HOVER", TR["Hover border color"])
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_ACTIVE", TR["Active border color"])
    frame:add_row_break()
    _add_style_color(frame, settings_getter, "CONTROL_BORDER_DISABLED", TR["Disabled border color"])

    local backgrounds = ConfigContent(window, 3)
    _add_style_color(backgrounds, settings_getter, "BACKGROUND", TR["Window background"])
    _add_style_color(backgrounds, settings_getter, "ALTERNATE_BACKGROUND", TR["Alternate background"])
    backgrounds:add_row_break()
    _add_style_color(backgrounds, settings_getter, "PANEL_BACKGROUND", TR["Panel background"])
    _add_style_color(backgrounds, settings_getter, "PANEL_INNER_BACKGROUND", TR["Panel inner background"])
    backgrounds:add_row_break()
    _add_style_color(backgrounds, settings_getter, "CONTROL_BACKGROUND", TR["Control background"])

    local controls = ConfigContent(window, 3)
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_HOVER", TR["Hover background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_PRESSED", TR["Pressed background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_ACTIVE", TR["Active background"])
    controls:add_row_break()
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_DISABLED", TR["Disabled background"])
    _add_style_color(controls, settings_getter, "CONTROL_BACKGROUND_READONLY", TR["Read-only background"])

    local selection = ConfigContent(window, 3)
    _add_style_color(selection, settings_getter, "SELECTION_BACKGROUND", TR["Selection background"])
    _add_style_color(selection, settings_getter, "SELECTION_BACKGROUND_HOVER", TR["Selection hover background"])
    _add_style_color(selection, settings_getter, "SELECTION_FOREGROUND", TR["Selection text"])
    selection:add_row_break()
    _add_style_color(selection, settings_getter, "ALTERNATE_SELECTION_BACKGROUND", TR["Alternate selection background"])
    _add_style_color(selection, settings_getter, "ALTERNATE_SELECTION_FOREGROUND", TR["Alternate selection text"])

    local text = ConfigContent(window, 3)
    _add_style_color(text, settings_getter, "FOREGROUND", TR["Main text"])
    _add_style_color(text, settings_getter, "ALTERNATE_FOREGROUND", TR["Secondary text"])
    _add_style_color(text, settings_getter, "INFO_FOREGROUND", TR["Info text"])
    text:add_row_break()
    _add_style_color(text, settings_getter, "FOREGROUND_DISABLED", TR["Disabled text"])
    _add_style_color(text, settings_getter, "PLACEHOLDER_FOREGROUND", TR["Placeholder text"])
    _add_style_color(text, settings_getter, "TEXT_OUTLINE", TR["Text outline"])

    local control_text = ConfigContent(window, 3)
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND", TR["Control text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_HOVER", TR["Control hover text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_PRESSED", TR["Control pressed text"])
    control_text:add_row_break()
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_ACTIVE", TR["Control active text"])
    _add_style_color(control_text, settings_getter, "CONTROL_FOREGROUND_DISABLED", TR["Control disabled text"])

    local accents = ConfigContent(window, 3)
    _add_style_color(accents, settings_getter, "ACCENT_BACKGROUND", TR["Accent background"])
    _add_style_color(accents, settings_getter, "ACCENT_FOREGROUND", TR["Accent text"])
    accents:add_row_break()
    _add_style_color(accents, settings_getter, "ACCENT_BACKGROUND_DISABLED", TR["Disabled accent"])
    _add_style_color(accents, settings_getter, "INVALID_BACKGROUND", TR["Invalid background"])

    local overlays = ConfigContent(window, 3)
    _add_style_color(overlays, settings_getter, "MODAL_OVERLAY_BACKGROUND", TR["Modal overlay background"])
    _add_style_opacity(overlays, settings_getter, "MODAL_OVERLAY_BACKGROUND", TR["Modal overlay opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "MODAL_DIALOG_BACKGROUND", TR["Modal dialog background"])
    _add_style_opacity(overlays, settings_getter, "MODAL_DIALOG_BACKGROUND", TR["Modal dialog opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "PREVIEW_OVERLAY_BACKGROUND", TR["Preview overlay background"])
    _add_style_opacity(overlays, settings_getter, "PREVIEW_OVERLAY_BACKGROUND", TR["Preview overlay opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_BACKGROUND", TR["Drag ghost background"])
    _add_style_opacity(overlays, settings_getter, "DRAG_GHOST_BACKGROUND", TR["Drag ghost opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_BORDER", TR["Drag ghost border"])
    _add_style_color(overlays, settings_getter, "DRAG_GHOST_FOREGROUND", TR["Drag ghost text"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_PREVIEW_FILL", TR["Drag preview fill"])
    _add_style_opacity(overlays, settings_getter, "DRAG_PREVIEW_FILL", TR["Drag preview fill opacity"])
    overlays:add_row_break()
    _add_style_color(overlays, settings_getter, "DRAG_PREVIEW_EDGE", TR["Drag preview edge"])
    _add_style_opacity(overlays, settings_getter, "DRAG_PREVIEW_EDGE", TR["Drag preview edge opacity"])

    local move_mode = ConfigContent(window, 3)
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_BACKGROUND", TR["Move overlay background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_OVERLAY_BACKGROUND", TR["Move overlay opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_HEADER_BACKGROUND", TR["Move header background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_OVERLAY_HEADER_BACKGROUND", TR["Move header opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_OVERLAY_FOREGROUND", TR["Move text"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_BACKGROUND", TR["Move grid background"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_BACKGROUND", TR["Move grid opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_CENTER_LINE", TR["Move grid center line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_CENTER_LINE", TR["Move grid center opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_MAJOR_LINE", TR["Move grid major line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_MAJOR_LINE", TR["Move grid major opacity"])
    move_mode:add_row_break()
    _add_style_color(move_mode, settings_getter, "MOVE_GRID_MINOR_LINE", TR["Move grid minor line"])
    _add_style_opacity(move_mode, settings_getter, "MOVE_GRID_MINOR_LINE", TR["Move grid minor opacity"])

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.left,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["Frame"], "frame", frame)
    page:add_tab(TR["Backgrounds"], "backgrounds", backgrounds)
    page:add_tab(TR["Controls"], "controls", controls)
    page:add_tab(TR["Selection"], "selection", selection)
    page:add_tab(TR["Text"], "text", text)
    page:add_tab(TR["Control Text"], "control_text", control_text)
    page:add_tab(TR["Accents"], "accents", accents)
    page:add_tab(TR["Overlays"], "overlays", overlays)
    page:add_tab(TR["Move Mode"], "move_mode", move_mode)
    return page
end

local function _new_ui_page(window, settings_getter)
    local page = ConfigSectionPage(window, nil, nil, nil)

    local general = ConfigContent(window, 4)
    general:add_info(TR["Style changes apply after reloading the plugin."], 34)
    _add_reset_button(page, general, settings_getter)
    page:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4)
    _add_style_number(layout, settings_getter, "BORDER_WIDTH", TR["Border width"])
    _add_style_number(layout, settings_getter, "BORDER_WIDTH_THIN", TR["Thin border width"])
    _add_style_number(layout, settings_getter, "BORDER_WIDTH_LARGE", TR["Large border width"])
    page:add_tab(TR["Layout"], "layout", layout)

    page:add_tab(TR["Colors"], "colors", _new_ui_colors_section(window, settings_getter))

    local text = ConfigContent(window, 4)
    _add_style_font_name(text, settings_getter, "CONTROL_FONT_NAME", TR["Default control font"])
    _add_style_number(text, settings_getter, "CONTROL_FONT_SIZE", TR["Default control font size"])
    text:add_row_break()
    _add_style_font_name(text, settings_getter, "WINDOW_TITLE_FONT_NAME", TR["Window title font"])
    _add_style_number(text, settings_getter, "WINDOW_TITLE_FONT_SIZE", TR["Window title font size"])
    text:add_row_break()
    _add_style_font_name(text, settings_getter, "SETTINGS_TITLE_FONT_NAME", TR["Settings title font"])
    _add_style_number(text, settings_getter, "SETTINGS_TITLE_FONT_SIZE", TR["Settings title font size"])
    text:add_row_break()
    _add_style_font_name(text, settings_getter, "FIRST_RUN_TITLE_FONT_NAME", TR["First-run title font"])
    _add_style_number(text, settings_getter, "FIRST_RUN_TITLE_FONT_SIZE", TR["First-run title font size"])
    text:add_row_break()
    _add_style_font_name(text, settings_getter, "TAB_FONT_NAME", TR["Tab font"])
    _add_style_number(text, settings_getter, "TAB_FONT_SIZE", TR["Tab font size"])
    text:add_row_break()
    _add_style_font_name(text, settings_getter, "HELP_FONT_NAME", TR["Help / tooltip font"])
    _add_style_number(text, settings_getter, "HELP_FONT_SIZE", TR["Help / tooltip font size"])
    page:add_tab(TR["Text"], "text", text)

    return page
end

GlobalPage = class(ConfigTabs)

function GlobalPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local digits_help = table.concat({
        TR["How many digits are shown before shortening."],
        TR["3 digits: 999 -> 999, 1000 -> 1.0k, 1000000 -> 1.0M"],
        TR["4 digits: 9999 -> 9999, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local width_help = table.concat({
        TR["Maximum number of characters used by the shortened numeric part. The decimal point counts. Values are truncated, never rounded up."],
        TR["3 chars: 1000 -> 1.0k, 10000 -> 10k, 100000 -> 100k"],
        TR["4 chars: 1000 -> 1.0k, 10000 -> 10.0k, 1000000 -> 1000k"],
    }, "\n")
    local method_help = table.concat({
        TR["Which style is used for all shortened numbers."],
        TR["k / M / G: 2500000000 -> 2.5G"],
        TR["k / M / B: 2500000000 -> 2.5B"],
        TR["k / m / M: 2500000000 -> 2.5M"],
        TR["e3 / e6 / e9: 2500000000 -> 2.5e9"],
    }, "\n")

    local general = ConfigContent(window, 4)
    general:add_line_edit("scale", TR["UI Scale"],
        function(value)
            local scale = tonumber(value)
            if scale ~= nil and scale > 0 then
                self._settings.global.scale = scale
            end
        end,
        function()
            return tostring(self._settings.global.scale)
        end)
    general:add_checkbox("native_scaling", TR["Use native LotRO UI scaling"],
        function(value)
            self._settings.global.native_scaling = value == true
        end,
        function()
            return self._settings.global.native_scaling == true
        end, true)
    general:add_row_break()
    general:add_line_edit("refresh_rate", TR["Refresh rate of some UI elements (fps)"],
        function(value)
            local refresh_rate = tonumber(value)
            if refresh_rate ~= nil and refresh_rate > 0 then
                self._settings.global.refresh_rate = refresh_rate
            end
        end,
        function()
            return tostring(self._settings.global.refresh_rate)
        end)
    general:add_row_break()
    general:add_checkbox("move_mode_shortcut", TR["Use LotRO move mode shortcut"],
        function(value)
            self._settings.global.move_mode_shortcut = value == true
        end,
        function()
            return self._settings.global.move_mode_shortcut == true
        end, 2)
    general:add_row_break()
    general:add_checkbox("bestiary_capture", TR["Enable bestiary capture (English client only)"],
        function(value)
            if is_lui_english_language() == true then
                self._settings.global.bestiary_capture = value == true
            else
                self._settings.global.bestiary_capture = false
            end
        end,
        function()
            return is_lui_english_language() == true and self._settings.global.bestiary_capture == true
        end, true)
    general.controls.bestiary_capture.load_fn = function()
        local english_only = is_lui_english_language() == true
        general.controls.bestiary_capture.cb:SetEnabled(english_only == true)
        return english_only == true and self._settings.global.bestiary_capture == true
    end
    self:add_tab(TR["General"], "general", general)

    local numbers = ConfigContent(window, 4)
    numbers:add_checkbox("abbrev_enabled", TR["Shorten large numbers"],
        function(value)
            self._settings.global.number_abbrev.enabled = value == true
        end,
        function()
            return self._settings.global.number_abbrev.enabled == true
        end)
    numbers:add_row_break()
    numbers:add_dropdown("abbrev_digits", TR["Digits Before Shortening"], numbers.abbrev_digits_labels,
        numbers.abbrev_digits_values,
        function(value)
            self._settings.global.number_abbrev.digits = value
        end,
        function()
            return self._settings.global.number_abbrev.digits
        end, digits_help)
    numbers:add_dropdown("abbrev_width", TR["Max Shortened Width"], numbers.abbrev_width_labels,
        numbers.abbrev_width_values,
        function(value)
            self._settings.global.number_abbrev.width = value
        end,
        function()
            return self._settings.global.number_abbrev.width
        end, width_help)
    numbers:add_dropdown("abbrev_method", TR["Shortening Style"], numbers.abbrev_method_labels,
        numbers.abbrev_method_values,
        function(value)
            self._settings.global.number_abbrev.method = value
        end,
        function()
            return self._settings.global.number_abbrev.method
        end, method_help)
    self:add_tab(TR["Numbers"], "numbers", numbers)

    self:add_tab(TR["UI"], "ui", _new_ui_page(window, function()
        return self._settings
    end))
end

function GlobalPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
