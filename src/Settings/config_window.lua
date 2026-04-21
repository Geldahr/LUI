import "Turbine.UI"
import "Turbine.Gameplay"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"
import "LUI.src.Utils.color"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.time_format"
import "LUI.src.Utils.token_format"
import "LUI.src.Settings.enums"

local SETTINGS_FONT_NAME = "Verdana"
local SETTINGS_FONT_SIZE = 13
local TAB_FONT_NAME = "Verdana"
local TAB_FONT_SIZE = 15
local TITLE_FONT_NAME = "BookAntiquaBold"
local TITLE_FONT_SIZE = 18
local FIELD_FONT_NAME = "Verdana"
local FIELD_FONT_SIZE = 12
local HINT_FONT_NAME = "Verdana"
local HINT_FONT_SIZE = 10
local function _scaled_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local _color_to_hex = lui_color_to_hex
local _hex_to_color = lui_hex_to_color

Options = class(Turbine.UI.Control)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function Options:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetSize(_scaled_int(444), _scaled_int(89))

    self.help = UI.Widgets.LuiLabel()
    self.help:SetParent(self)
    self.help:SetFont(_scaled_font(SETTINGS_FONT_NAME, SETTINGS_FONT_SIZE))
    self.help:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.help:SetPosition(_scaled_int(7), _scaled_int(7))
    self.help:SetSize(_scaled_int(430), _scaled_int(74))
    self.help:SetText(TR["Use '/LUI config' to toggle the configuration window."])
end

ConfigWindow = class(LuiWindow)

import "LUI.src.Settings.Window.window_geometry"
import "LUI.src.Settings.Window.window_tabs"
import "LUI.src.Settings.Window.window_layout"
import "LUI.src.Settings.Window.window_previews"
import "LUI.src.Settings.Window.window_profiles"

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function ConfigWindow:Constructor()
    LuiWindow.Constructor(self)

    self:set_title(TR["LUI Configuration"])
    self:set_resizable(true)
    self:hide()

    self:_update_ui_scale_metrics()
    self:set_minimum_size(_scaled_int(222), _scaled_int(185))

    local content = Turbine.UI.Control()
    content:SetMouseVisible(true)
    self:set_central_widget(content)

    self.main_tab_bar = UI.Widgets.LuiTabBar()
    self.main_tab_bar:SetParent(content)
    self.main_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.left)
    self.main_tab_bar:set_show_content_border(false)
    self.main_tab_bar.on_tab_changed = function(index, page, text)
        if page == nil then
            return
        end
        self:_on_main_tab_changed(index, page, text, self._pending_main_tab_sub_key)
    end

    self.tooltip = UI.Widgets.LuiTooltip()
    self.tooltip:SetScale(_G.settings.global.scale)
    self.tooltip:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))

    self.confirm_overlay = Turbine.UI.Control()
    self.confirm_overlay:SetParent(content)
    self.confirm_overlay:SetVisible(false)
    self.confirm_overlay:SetMouseVisible(true)
    self.confirm_overlay:SetZOrder(2000)
    self.confirm_overlay:SetBackColor(Turbine.UI.Color(0.45, 0, 0, 0))
    self.confirm_overlay:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.confirm_overlay:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self.confirm_dialog = Turbine.UI.Control()
    self.confirm_dialog:SetParent(self.confirm_overlay)
    self.confirm_dialog:SetMouseVisible(true)
    self.confirm_dialog:SetBackColor(Turbine.UI.Color(0.95, 0.08, 0.08, 0.08))
    self.confirm_dialog:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.confirm_dialog:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self.confirm_dialog_label = UI.Widgets.LuiLabel()
    self.confirm_dialog_label:SetParent(self.confirm_dialog)
    self.confirm_dialog_label:SetMultiline(true)
    self.confirm_dialog_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.confirm_dialog_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))

    self.confirm_cancel_button = UI.Widgets.LuiButton()
    self.confirm_cancel_button:SetParent(self.confirm_dialog)
    self.confirm_cancel_button:set_text(TR["Cancel"])
    self.confirm_cancel_button.Click = function()
        self:hide_confirmation_dialog()
    end

    self.confirm_confirm_button = UI.Widgets.LuiButton()
    self.confirm_confirm_button:SetParent(self.confirm_dialog)
    self.confirm_confirm_button:set_text(TR["Delete"])
    self.confirm_confirm_button.Click = function()
        local action = self.confirm_dialog_action
        self:hide_confirmation_dialog()
        if action ~= nil then
            action()
        end
    end

    self.button_bar = Turbine.UI.Control()
    self.button_bar:SetParent(content)

    self.cancel_button = UI.Widgets.LuiButton()
    self.cancel_button:SetParent(self.button_bar)
    self.cancel_button:set_font(self.settings_font)
    self.cancel_button:set_text(TR["Cancel"])
    self.cancel_button.Click = function()
        self:cancel()
    end

    self.apply_button = UI.Widgets.LuiButton()
    self.apply_button:SetParent(self.button_bar)
    self.apply_button:set_font(self.settings_font)
    self.apply_button:set_text(TR["Apply"])
    self.apply_button.Click = function()
        self:apply_changes(false)
    end

    self.save_button = UI.Widgets.LuiButton()
    self.save_button:SetParent(self.button_bar)
    self.save_button:set_font(self.settings_font)
    self.save_button:set_text(TR["Save"])
    self.save_button.Click = function()
        self:apply_changes(true)
    end

    self:build_controls()
    self:build_tabs()
    self:_rebuild_control_registry()

    self.move_ui_button = UI.Widgets.LuiButton()
    self.move_ui_button:SetParent(self.button_bar)
    self.move_ui_button:set_font(self.settings_font)
    self.move_ui_button:set_text(TR["Move UI"])
    self.move_ui_button.Click = function()
        if set_move_ui_mode ~= nil then
            set_move_ui_mode(true, true)
        end
    end

    self:apply_ui_scale()

    self.SizeChanged = function()
        LuiWindow._layout(self)
        self:layout()
    end

    self.VisibleChanged = function()
        if self:IsVisible() == false then
            self:hide_hint()
            self:hide_confirmation_dialog()
            self:close_all_dropdowns()
            return
        end

        self:layout()
        self:_activate_active_page()
    end

    self:apply_saved_geometry()
    self:select_main_tab("global")
    self:layout()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function ConfigWindow:_update_ui_scale_metrics()
    self.settings_font = _scaled_font(SETTINGS_FONT_NAME, SETTINGS_FONT_SIZE)
    self.tab_font = _scaled_font(TAB_FONT_NAME, TAB_FONT_SIZE)

    self.margin_left = _scaled_int(15)
    self.margin_top = _scaled_int(11)
    self.margin_right = _scaled_int(15)
    self.margin_bottom = _scaled_int(15)

    self.button_bar_height = _scaled_int(30)
    self.row_height = _scaled_int(34)
    self.col_gap = _scaled_int(22)
    self.inner_gap = _scaled_int(4)
    self.content_padding = _scaled_int(7)
    self.scroll_bar_gap = _scaled_int(3)

    self.title_font = _scaled_font(TITLE_FONT_NAME, TITLE_FONT_SIZE)
    self.field_label_font = _scaled_font(FIELD_FONT_NAME, FIELD_FONT_SIZE)
    self.input_font = _scaled_font(FIELD_FONT_NAME, FIELD_FONT_SIZE)
    self.field_label_height = _scaled_int(31)
    self.input_height = _scaled_int(21)
    self.dropdown_y_offset = _scaled_int(1)
end

function ConfigWindow:apply_ui_scale()
    LuiWindow.apply_settings(self)
    self:_update_ui_scale_metrics()
    self:set_minimum_size(_scaled_int(222), _scaled_int(185))
    local scale = _G.settings.global.scale

    if self.tooltip ~= nil then
        self.tooltip:SetScale(scale)
        self.tooltip:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))
    end

    if self.cancel_button ~= nil then
        self.cancel_button:set_font(self.settings_font)
    end
    if self.apply_button ~= nil then
        self.apply_button:set_font(self.settings_font)
    end
    if self.save_button ~= nil then
        self.save_button:set_font(self.settings_font)
    end
    if self.move_ui_button ~= nil then
        self.move_ui_button:set_font(self.settings_font)
    end
    if self.confirm_dialog_label ~= nil then
        self.confirm_dialog_label:SetFont(self.field_label_font)
    end
    if self.confirm_cancel_button ~= nil then
        self.confirm_cancel_button:set_font(self.settings_font)
    end
    if self.confirm_confirm_button ~= nil then
        self.confirm_confirm_button:set_font(self.settings_font)
    end

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:set_scale(scale)
        self.main_tab_bar:set_font(self.tab_font)
    end

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.apply_ui_scale ~= nil then
                page:apply_ui_scale()
            end
        end)
    end
end

function ConfigWindow:close_all_dropdowns()
    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.close_all_dropdowns ~= nil then
                page:close_all_dropdowns()
            end
        end)
    end
end

function ConfigWindow:show_hint_for(control, text)
    if self.tooltip == nil then
        return
    end
    self.tooltip:ShowFor(control, text)
end

function ConfigWindow:hide_hint()
    if self.tooltip ~= nil then
        self.tooltip:Hide()
    end
end

function ConfigWindow:bind_tooltip(control, text_source)
    if self.tooltip ~= nil then
        self.tooltip:Bind(control, text_source)
    end
end

function ConfigWindow:show_confirmation_dialog(text, confirm_text, action)
    if self.confirm_overlay == nil then
        return
    end

    self.confirm_dialog_action = action
    self.confirm_dialog_label:SetText(text or "")
    self.confirm_confirm_button:set_text(confirm_text or TR["Confirm"])
    self.confirm_overlay:SetVisible(true)
    self:layout()
end

function ConfigWindow:hide_confirmation_dialog()
    self.confirm_dialog_action = nil
    if self.confirm_overlay ~= nil then
        self.confirm_overlay:SetVisible(false)
    end
end

function ConfigWindow:cancel()
    self:hide_confirmation_dialog()
    self:hide()
end

function ConfigWindow:open(main_key, preferred_sub_key)
    self:apply_saved_geometry()
    self:load_from_settings()
    if type(main_key) == "string" then
        self:select_main_tab(main_key, preferred_sub_key)
    end
    self:show()
    self:layout()
    self:_activate_active_page()
end

function ConfigWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function ConfigWindow:_rebuild_control_registry()
    self.controls = {}
    self._color_fields = {}

    if self.main_tab_bar == nil then
        return
    end

    self.main_tab_bar:each_widget(function(_, page)
        if page ~= nil and page.controls ~= nil then
            for control_key, entry in pairs(page.controls) do
                self.controls[control_key] = entry
            end
        end
        if page ~= nil and page._color_fields ~= nil then
            for i = 1, #page._color_fields do
                self._color_fields[#self._color_fields + 1] = page._color_fields[i]
            end
        end
    end)
end

function ConfigWindow:build_controls()
    local font_name_labels = {
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
    local font_name_values = {
        LUI_ENUMS.font_name.VERDANA,
        LUI_ENUMS.font_name.BOOK_ANTIQUA,
        LUI_ENUMS.font_name.BOOK_ANTIQUA_BOLD,
        LUI_ENUMS.font_name.TRAJAN_PRO,
        LUI_ENUMS.font_name.TRAJAN_PRO_BOLD,
        LUI_ENUMS.font_name.ARIAL,
        LUI_ENUMS.font_name.FIXED_SYS,
        LUI_ENUMS.font_name.LUCIDA_CONSOLE,
        LUI_ENUMS.font_name.VERDANA_BOLD,
    }

    local font_style_labels = { TR["None"], TR["Outline"] }
    local font_style_values = { LUI_ENUMS.font_style.NONE, LUI_ENUMS.font_style.OUTLINE }

    local side_labels = { TR["Left"], TR["Right"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }

    local text_alignment_labels = { TR["Left"], TR["Center"], TR["Right"] }
    local text_alignment_values = {
        LUI_ENUMS.text_alignment.LEFT,
        LUI_ENUMS.text_alignment.CENTER,
        LUI_ENUMS.text_alignment.RIGHT,
    }

    local abbrev_digits_labels = { "3", "4" }
    local abbrev_digits_values = { LUI_ENUMS.abbrev_digits.DIGITS_3, LUI_ENUMS.abbrev_digits.DIGITS_4 }
    local abbrev_width_labels = { "3", "4" }
    local abbrev_width_values = {
        LUI_ENUMS.abbrev_width.CHARS_3,
        LUI_ENUMS.abbrev_width.CHARS_4,
    }
    local abbrev_method_labels = {
        "k / M / G",
        "k / M / B",
        "k / m / M",
        "e3 / e6 / e9",
    }
    local abbrev_method_values = {
        LUI_ENUMS.abbrev_method.K_M_G,
        LUI_ENUMS.abbrev_method.K_M_B,
        LUI_ENUMS.abbrev_method.K_m_M,
        LUI_ENUMS.abbrev_method.E3_E6_E9,
    }

    local vitals_effects_position_labels = { TR["Above Morale"], TR["Below Power"] }
    local vitals_effects_position_values = {
        LUI_ENUMS.vitals_effects_position.ABOVE,
        LUI_ENUMS.vitals_effects_position.BELOW,
    }

    local vital_format_help = table.concat({
        TR["Text template tokens:"],
        TR["  %c = current value"],
        TR["  %t = total / maximum value"],
        TR["  %p = percent (e.g. 73%)"],
        TR["  %b = bubble value (temporary morale)"],
        TR["  %B = bubble format output (only when bubble > 0)"],
        TR["  %name% = entity name"],
        TR["  %level% = entity level"],
        "",
        TR["Set the text to empty to hide the label."],
        TR["You can use \\n for a new line."],
        TR["Example: [%level%] %name%\n%c / %t - %p"],
    }, "\n")

    local bubble_format_help = table.concat({
        TR["Bubble format (used by %B; only when bubble > 0)."],
        TR["Use %b for the bubble value."],
        TR["Example:  - %b"],
    }, "\n")

    self.controls = {}
    self._color_fields = {}
    self._ui = {
        font_name_labels = font_name_labels,
        font_name_values = font_name_values,
        font_style_labels = font_style_labels,
        font_style_values = font_style_values,
        side_labels = side_labels,
        side_values = side_values,
        text_alignment_labels = text_alignment_labels,
        text_alignment_values = text_alignment_values,
        abbrev_digits_labels = abbrev_digits_labels,
        abbrev_digits_values = abbrev_digits_values,
        abbrev_width_labels = abbrev_width_labels,
        abbrev_width_values = abbrev_width_values,
        abbrev_method_labels = abbrev_method_labels,
        abbrev_method_values = abbrev_method_values,
        vitals_effects_position_labels = vitals_effects_position_labels,
        vitals_effects_position_values = vitals_effects_position_values,
        vital_format_help = vital_format_help,
        bubble_format_help = bubble_format_help,
        color_to_hex = _color_to_hex,
        hex_to_color = _hex_to_color,
    }

end
function ConfigWindow:update_swatch(entry)
    if entry == nil or entry.is_color ~= true or entry.tb == nil then
        return
    end

    if entry.tb.update_swatch ~= nil then
        entry.tb:update_swatch()
    end
end

function ConfigWindow:update_all_swatches()
    if self._color_fields == nil then
        return
    end
    for i = 1, #self._color_fields do
        self:update_swatch(self._color_fields[i])
    end
end

function ConfigWindow:load_from_settings()
    if _G.loaded_settings == nil then
        return
    end

    self.loading = true

    local s = _G.loaded_settings

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.load_from_settings ~= nil then
                page:load_from_settings(s, self._ui)
            end
        end)
    end

    self:update_all_swatches()

    self.loading = false
    self:_refresh_active_preview()
end

function ConfigWindow:refresh_runtime_settings()
    fix_colors()
    rebuild_settings()
    apply_inventory_settings()
    apply_assets_settings()
    apply_status_bar_settings()
    apply_cooldowns_settings()
    apply_crafting_settings()

    self:apply_ui_scale()
    self:layout()

    if PLAYER_VITAL ~= nil and PLAYER_VITAL.resize ~= nil then
        PLAYER_VITAL:resize()
    end
    if TARGET_VITAL ~= nil and TARGET_VITAL.resize ~= nil then
        TARGET_VITAL:resize()
    end
    if BOSS_VITAL ~= nil and BOSS_VITAL.resize ~= nil then
        BOSS_VITAL:resize()
    end
    if PARTY_VITALS ~= nil and PARTY_VITALS.apply_settings ~= nil then
        PARTY_VITALS:apply_settings()
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil and EXPIRING_SELF_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:apply_settings()
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil and EXPIRING_TARGET_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:apply_settings()
    end
    if INVENTORY_WINDOW ~= nil and INVENTORY_WINDOW.apply_settings ~= nil then
        INVENTORY_WINDOW:apply_settings()
    end
    if ASSETS_WINDOW ~= nil and ASSETS_WINDOW.apply_settings ~= nil then
        ASSETS_WINDOW:apply_settings()
    end
    if COOLDOWNS_WINDOW ~= nil and COOLDOWNS_WINDOW.apply_settings ~= nil then
        COOLDOWNS_WINDOW:apply_settings()
    end
    if BESTIARY_WINDOW ~= nil and BESTIARY_WINDOW.apply_settings ~= nil then
        BESTIARY_WINDOW:apply_settings()
    end
    if CRAFTING_WINDOW ~= nil and CRAFTING_WINDOW.apply_settings ~= nil then
        CRAFTING_WINDOW:apply_settings()
    end
    if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.apply_settings ~= nil then
        BESTIARY_TRACKER:apply_settings()
    end
    if PLAYER_VITAL ~= nil and PLAYER_VITAL.on_target_changed ~= nil then
        PLAYER_VITAL:on_target_changed()
    end

    self:_refresh_active_preview()
end

function ConfigWindow:apply_changes(close_after)
    if _G.loaded_settings == nil then
        return
    end

    local s = _G.loaded_settings

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:each_widget(function(_, page)
            if page ~= nil and page.apply_to_settings ~= nil then
                page:apply_to_settings(s, self._ui)
            end
        end)
    end

    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
    end

    self:refresh_runtime_settings()

    self:update_saved_geometry()
    save_settings()

    if close_after then
        self:hide()
    end
end
