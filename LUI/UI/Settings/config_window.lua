import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Turbine.Gameplay"

import "Geldahr.LUI.UI.Widgets"
import "Geldahr.LUI.Utils.class_icons"
import "Geldahr.LUI.Utils.color"
import "Geldahr.LUI.Utils.number_abbrev"
import "Geldahr.LUI.Utils.time_format"
import "Geldahr.LUI.Utils.token_format"
import "Geldahr.LUI.Settings.enums"

import "Geldahr.LUI.UI.Settings.Tabs.global"
import "Geldahr.LUI.UI.Settings.Tabs.profile_manager"
import "Geldahr.LUI.UI.Settings.Tabs.self_vitals"
import "Geldahr.LUI.UI.Settings.Tabs.target_vitals"
import "Geldahr.LUI.UI.Settings.Tabs.target_boss_vitals"
import "Geldahr.LUI.UI.Settings.Tabs.target_targets_target"
import "Geldahr.LUI.UI.Settings.Tabs.expiring_target_effects"
import "Geldahr.LUI.UI.Settings.Tabs.party_layout"
import "Geldahr.LUI.UI.Settings.Tabs.party_vitals"
import "Geldahr.LUI.UI.Settings.Tabs.self_expiring_effects"
import "Geldahr.LUI.UI.Settings.Tabs.inventory"
import "Geldahr.LUI.UI.Settings.Tabs.assets"
import "Geldahr.LUI.UI.Settings.Tabs.status_bar"
import "Geldahr.LUI.UI.Settings.Tabs.cooldowns"
import "Geldahr.LUI.UI.Settings.Tabs.help"

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
local CONFIRM_DIALOG_W = 296
local CONFIRM_DIALOG_H = 126
local CONFIRM_DIALOG_PADDING = 12
local CONFIRM_DIALOG_BUTTON_GAP = 7

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

local function _require_font(name, size)
    local font = FONT_TO_LOTRO(name, size)
    if font == nil then
        error("Missing font: " .. tostring(name) .. " " .. tostring(size))
    end
    return font
end

local _color_to_hex = lui_color_to_hex
local _hex_to_color = lui_hex_to_color
local _dim_color = lui_dim_color

local DEFAULT_GRADIENT_MID_COLOR = Turbine.UI.Color(1, 0.847059, 0.776471, 0.235294)

local _gradient_morale_color = lui_gradient_morale_color

local function _morale_color_preview(percent, gradient_enabled, gradient_full_color, gradient_mid_color,
                                     gradient_low_color, high_color, medium_color, low_color, critical_color)
    if gradient_enabled == true then
        return _gradient_morale_color(percent, gradient_full_color, gradient_mid_color, gradient_low_color)
    end
    if percent > 0.75 then
        return high_color
    elseif percent > 0.5 then
        return medium_color
    elseif percent > 0.25 then
        return low_color
    end
    return critical_color
end

local function _preview_number_abbrev_settings(window)
    local raw = _G.loaded_settings.global.number_abbrev
    local enabled = raw.enabled
    local digits = raw.digits
    local width = raw.width
    local method = raw.method

    local controls = window.controls
    enabled = controls.abbrev_enabled.cb:IsChecked()
    digits = controls.abbrev_digits:get_value()
    width = controls.abbrev_width:get_value()
    method = controls.abbrev_method:get_value()

    return {
        enabled = enabled,
        digits = digits,
        width = width,
        method = method,
    }
end

local function _apply_preview_border(p, w, h)
    if p == nil then
        return
    end
    if p.border_top == nil or p.border_bottom == nil or p.border_left == nil or p.border_right == nil then
        return
    end

    local bw = 1
    local ww = tonumber(w) or 0
    local hh = tonumber(h) or 0
    if ww < 1 then ww = 1 end
    if hh < 1 then hh = 1 end

    p.border_top:SetVisible(true)
    p.border_top:SetZOrder(999)
    p.border_top:SetPosition(0, 0)
    p.border_top:SetSize(ww, bw)

    p.border_bottom:SetVisible(true)
    p.border_bottom:SetZOrder(999)
    p.border_bottom:SetPosition(0, hh - bw)
    p.border_bottom:SetSize(ww, bw)

    p.border_left:SetVisible(true)
    p.border_left:SetZOrder(999)
    p.border_left:SetPosition(0, 0)
    p.border_left:SetSize(bw, hh)

    p.border_right:SetVisible(true)
    p.border_right:SetZOrder(999)
    p.border_right:SetPosition(ww - bw, 0)
    p.border_right:SetSize(bw, hh)
end

Options = class(Turbine.UI.Control)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function Options:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetSize(_scaled_int(444), _scaled_int(89))

    self.help = Turbine.UI.Label()
    self.help:SetParent(self)
    self.help:SetFont(_scaled_font(SETTINGS_FONT_NAME, SETTINGS_FONT_SIZE))
    self.help:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.help:SetPosition(_scaled_int(7), _scaled_int(7))
    self.help:SetSize(_scaled_int(430), _scaled_int(74))
    self.help:SetText(TR("Use '/LUI config' to open the configuration window."))
end

ConfigWindow = class(Turbine.UI.Lotro.Window)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function ConfigWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetText(TR("LUI Configuration"))
    self:SetResizable(true)
    self:SetVisible(false)

    self:_update_ui_scale_metrics()

    self.tab_bar = Turbine.UI.Control()
    self.tab_bar:SetParent(self)

    self.main_tab_bar = Turbine.UI.Control()
    self.main_tab_bar:SetParent(self)

    self.main_tab_separator = Turbine.UI.Control()
    self.main_tab_separator:SetParent(self)
    self.main_tab_separator:SetMouseVisible(false)
    self.main_tab_separator:SetBackColor(Turbine.UI.Color(0.55, 0.55, 0.55))

    self.scroll = Turbine.UI.ListBox()
    self.scroll:SetParent(self)
    self.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.scroll_bar = Turbine.UI.Lotro.ScrollBar()
    self.scroll_bar:SetParent(self)
    self.scroll_bar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scroll:SetVerticalScrollBar(self.scroll_bar)
    self.scroll_bar.ValueChanged = function()
        if self.active_tab == "party_vitals" then
            self:update_party_vitals_preview()
        end
    end

    self.form = Turbine.UI.Control()
    self.scroll:AddItem(self.form)

    self.hint = Turbine.UI.Window()
    self.hint:SetVisible(false)
    self.hint:SetMouseVisible(false)
    self.hint:SetZOrder(2000)
    self.hint:SetBackColor(Turbine.UI.Color(0.92, 0.05, 0.05, 0.05))

    self.hint_label = Turbine.UI.Label()
    self.hint_label:SetParent(self.hint)
    self.hint_label:SetPosition(_scaled_int(6), _scaled_int(4))
    self.hint_label:SetSize(_scaled_int(267), _scaled_int(148))
    self.hint_label:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))
    self.hint_label:SetForeColor(Turbine.UI.Color(1, 1, 1))
    self.hint_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.hint_label:SetMultiline(true)
    self.hint_label:SetMouseVisible(false)

    self.confirm_overlay = Turbine.UI.Control()
    self.confirm_overlay:SetParent(self)
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

    self.confirm_dialog_label = Turbine.UI.Label()
    self.confirm_dialog_label:SetParent(self.confirm_dialog)
    self.confirm_dialog_label:SetMultiline(true)
    self.confirm_dialog_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.confirm_dialog_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))

    self.confirm_cancel_button = UI.Widgets.LuiButton()
    self.confirm_cancel_button:SetParent(self.confirm_dialog)
    self.confirm_cancel_button:SetText(TR("Cancel"))
    self.confirm_cancel_button.Click = function()
        self:hide_confirmation_dialog()
    end

    self.confirm_confirm_button = UI.Widgets.LuiButton()
    self.confirm_confirm_button:SetParent(self.confirm_dialog)
    self.confirm_confirm_button:SetText(TR("Delete"))
    self.confirm_confirm_button.Click = function()
        local action = self.confirm_dialog_action
        self:hide_confirmation_dialog()
        if action ~= nil then
            action()
        end
    end

    self.button_bar = Turbine.UI.Control()
    self.button_bar:SetParent(self)

    self.cancel_button = UI.Widgets.LuiButton()
    self.cancel_button:SetParent(self.button_bar)
    self.cancel_button:SetFont(self.settings_font)
    self.cancel_button:SetText(TR("Cancel"))
    self.cancel_button.Click = function()
        self:SetVisible(false)
    end

    self.apply_button = UI.Widgets.LuiButton()
    self.apply_button:SetParent(self.button_bar)
    self.apply_button:SetFont(self.settings_font)
    self.apply_button:SetText(TR("Apply"))
    self.apply_button.Click = function()
        self:apply_changes(false)
    end

    self.save_button = UI.Widgets.LuiButton()
    self.save_button:SetParent(self.button_bar)
    self.save_button:SetFont(self.settings_font)
    self.save_button:SetText(TR("Save"))
    self.save_button.Click = function()
        self:apply_changes(true)
    end

    self.controls = {}
    self.all_fields = {}
    self.tab_fields = {}
    self:build_controls()
    self:build_tabs()

    self.move_ui_button = UI.Widgets.LuiButton()
    self.move_ui_button:SetParent(self.button_bar)
    self.move_ui_button:SetFont(self.settings_font)
    self.move_ui_button:SetText(TR("Move UI"))
    self.move_ui_button.Click = function()
        if set_move_ui_mode ~= nil then
            set_move_ui_mode(true, true)
        end
    end

    self:apply_ui_scale()

    self.SizeChanged = function()
        self:layout()
    end

    self.PositionChanged = function()
        self:update_saved_geometry()
    end

    self.VisibleChanged = function()
        if self:IsVisible() == false then
            self:hide_hint()
            self:hide_confirmation_dialog()
            self:close_all_dropdowns()
            self:persist_geometry()
        end
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
    self.margin_top = _scaled_int(33)
    self.margin_right = _scaled_int(15)
    self.margin_bottom = _scaled_int(15)

    self.tab_bar_height = _scaled_int(24)
    self.tab_bar_gap = _scaled_int(4)
    self.main_tab_bar_width = _scaled_int(111)
    self.main_tab_bar_gap = _scaled_int(9)
    self.main_tab_button_height = _scaled_int(24)
    self.main_tab_button_gap = _scaled_int(4)

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
    self:_update_ui_scale_metrics()
    local scale = _G.settings.global.scale

    if self.hint_label ~= nil then
        self.hint_label:SetPosition(_scaled_int(6), _scaled_int(4))
        self.hint_label:SetSize(_scaled_int(267), _scaled_int(148))
        self.hint_label:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))
    end

    if self.cancel_button ~= nil then
        self.cancel_button:SetFont(self.settings_font)
    end
    if self.apply_button ~= nil then
        self.apply_button:SetFont(self.settings_font)
    end
    if self.save_button ~= nil then
        self.save_button:SetFont(self.settings_font)
    end
    if self.move_ui_button ~= nil then
        self.move_ui_button:SetFont(self.settings_font)
    end
    if self.confirm_dialog_label ~= nil then
        self.confirm_dialog_label:SetFont(self.field_label_font)
    end
    if self.confirm_cancel_button ~= nil then
        self.confirm_cancel_button:SetFont(self.settings_font)
    end
    if self.confirm_confirm_button ~= nil then
        self.confirm_confirm_button:SetFont(self.settings_font)
    end

    if self.main_tab_buttons ~= nil then
        for _, b in pairs(self.main_tab_buttons) do
            if b ~= nil then
                b:SetFont(self.tab_font)
            end
        end
    end
    if self.sub_tab_buttons ~= nil then
        for _, b in pairs(self.sub_tab_buttons) do
            if b ~= nil then
                b:SetFont(self.tab_font)
            end
        end
    end

    for i = 1, #(self.all_fields or {}) do
        local field = self.all_fields[i]
        if field ~= nil then
            if field.kind == "title" and field.label ~= nil then
                field.label:SetFont(self.title_font)
            elseif field.kind == "info" then
                if field.label ~= nil then
                    field.label:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))
                end
                if field.base_height ~= nil then
                    field.height = _scaled_int(field.base_height)
                end
            elseif field.kind == "text" then
                if field.label ~= nil then
                    field.label:SetFont(self.field_label_font)
                end
                if field.tb ~= nil and field.tb.SetScale ~= nil then
                    field.tb:SetScale(scale)
                end
                if field.tb ~= nil and field.tb.SetFont ~= nil then
                    field.tb:SetFont(self.input_font)
                end
            elseif field.kind == "dropdown" then
                if field.label ~= nil then
                    field.label:SetFont(self.field_label_font)
                end
                if field.button ~= nil and field.button.SetScale ~= nil then
                    field.button:SetScale(scale)
                end
                if field.button ~= nil and field.button.SetFont ~= nil then
                    field.button:SetFont(self.input_font)
                end
            elseif (field.kind == "break" or field.kind == "custom") and field.base_height ~= nil then
                field.height = _scaled_int(field.base_height)
                if field.kind == "custom" and field.apply_ui_scale ~= nil then
                    field:apply_ui_scale()
                end
            elseif field.kind == "checkbox" and field.cb ~= nil then
                field.cb:SetFont(self.field_label_font)
            end
        end
    end
end

function ConfigWindow:close_all_dropdowns()
    local fields = self.all_fields or {}
    for i = 1, #fields do
        local field = fields[i]
        if field ~= nil and field.kind == "dropdown" then
            field.button:Close()
        end
    end
end

function ConfigWindow:show_hint_for(control, text)
    if control == nil or type(text) ~= "string" or string.len(text) == 0 then
        return
    end

    local max_width = _scaled_int(311)
    local padding_x = _scaled_int(12)
    local padding_y = _scaled_int(9)
    local line_height = _scaled_int(12)

    local line_count = 1
    for _ in text:gmatch("\n") do
        line_count = line_count + 1
    end

    local desired_height = math.min(
        _scaled_int(178),
        math.max(_scaled_int(44), (line_count * line_height) + padding_y + _scaled_int(7))
    )
    self.hint_label:SetText(text)
    self.hint_label:SetSize(max_width - padding_x, desired_height - padding_y)
    self.hint:SetSize(max_width, desired_height)

    local x, y = control:PointToScreen(0, control:GetHeight() + _scaled_int(1))
    local display_width, display_height = Turbine.UI.Display.GetSize()
    if x + max_width > display_width then
        x = display_width - max_width - _scaled_int(4)
    end
    if y + desired_height > display_height then
        y = y - desired_height - control:GetHeight() - _scaled_int(4)
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    self.hint:SetPosition(x, y)
    self.hint:SetVisible(true)
end

function ConfigWindow:hide_hint()
    if self.hint ~= nil then
        self.hint:SetVisible(false)
    end
end

function ConfigWindow:show_confirmation_dialog(text, confirm_text, action)
    if self.confirm_overlay == nil then
        return
    end

    self.confirm_dialog_action = action
    self.confirm_dialog_label:SetText(text or "")
    self.confirm_confirm_button:SetText(confirm_text or TR("Confirm"))
    self.confirm_overlay:SetVisible(true)
    self:layout()
end

function ConfigWindow:hide_confirmation_dialog()
    self.confirm_dialog_action = nil
    if self.confirm_overlay ~= nil then
        self.confirm_overlay:SetVisible(false)
    end
end

function ConfigWindow:open(main_key, preferred_sub_key)
    self:apply_saved_geometry()
    self:load_from_settings()
    if type(main_key) == "string" then
        self:select_main_tab(main_key, preferred_sub_key)
    end
    self:SetVisible(true)
    self:bring_to_front()
end

function ConfigWindow:bring_to_front()
    self:SetZOrder(999)
end

function ConfigWindow:build_tabs()
    self.main_tabs = {
        { key = "global",     text = TR("Global") },
        { key = "self",       text = TR("Self") },
        { key = "target",     text = TR("Target") },
        { key = "party",      text = TR("Party") },
        { key = "inventory",  text = TR("Inventory") },
        { key = "assets",      text = TR("Assets") },
        { key = "status_bar", text = TR("Status Bar") },
        { key = "profile_manager", text = TR("Profiles") },
        { key = "help",       text = TR("Help") },
    }

    self.sub_tabs_by_main = {
        self = {
            { key = "self_vitals",      text = TR("Vitals") },
            { key = "expiring_effects", text = TR("Expiring Effects") },
            { key = "cooldowns",        text = TR("Cooldowns") },
        },
        target = {
            { key = "target_vitals",           text = TR("Vitals") },
            { key = "target_boss_vitals",      text = TR("Boss vitals") },
            { key = "target_targets_target",   text = TR("Target's Target") },
            { key = "expiring_target_effects", text = TR("Expiring Effects") },
        },
        party = {
            { key = "party_layout", text = TR("Layout") },
            { key = "party_vitals", text = TR("Vitals") },
        },
    }

    self._main_for_sub = {
        self_vitals = "self",
        expiring_effects = "self",
        cooldowns = "self",
        target_vitals = "target",
        target_boss_vitals = "target",
        target_targets_target = "target",
        expiring_target_effects = "target",
        party_layout = "party",
        party_vitals = "party",
        global = "global",
        inventory = "inventory",
        assets = "assets",
        status_bar = "status_bar",
        profile_manager = "profile_manager",
        help = "help",
    }

    self.main_tab_buttons = {}
    for i = 1, #self.main_tabs do
        local t = self.main_tabs[i]
        local b = UI.Widgets.LuiButton()
        b:SetParent(self.main_tab_bar)
        b:SetFont(self.tab_font)
        b:SetText(t.text)
        b.Click = function()
            if self.active_main_tab == t.key then
                return
            end
            self:select_main_tab(t.key)
        end
        self.main_tab_buttons[t.key] = b
    end

    self.sub_tab_buttons = {}
    for _, list in pairs(self.sub_tabs_by_main) do
        for i = 1, #list do
            local t = list[i]
            if self.sub_tab_buttons[t.key] == nil then
                local b = UI.Widgets.LuiButton()
                b:SetParent(self.tab_bar)
                b:SetFont(self.tab_font)
                b:SetText(t.text)
                b.Click = function()
                    if self.active_tab == t.key then
                        return
                    end
                    self:select_sub_tab(t.key)
                end
                b:SetVisible(false)
                self.sub_tab_buttons[t.key] = b
            end
        end
    end
end

function ConfigWindow:update_tab_buttons()
    local main_key = self.active_main_tab or "global"

    -- Main
    for i = 1, #self.main_tabs do
        local t = self.main_tabs[i]
        local b = self.main_tab_buttons[t.key]
        if b ~= nil then
            b:set_active(t.key == main_key)
            b:SetEnabled(true)
        end
    end

    -- Sub
    local sub_list = self.sub_tabs_by_main[main_key]
    local show_sub = sub_list ~= nil and #sub_list > 1
    self._visible_sub_tabs = show_sub and sub_list or nil
    self.tab_bar:SetVisible(show_sub)

    for key, b in pairs(self.sub_tab_buttons) do
        if b ~= nil then
            b:SetVisible(false)
        end
    end

    if show_sub then
        for i = 1, #sub_list do
            local t = sub_list[i]
            local b = self.sub_tab_buttons[t.key]
            if b ~= nil then
                b:SetVisible(true)
                b:set_active(t.key == self.active_tab)
                b:SetEnabled(true)
            end
        end
    end
end

function ConfigWindow:select_main_tab(main_key, preferred_sub_key)
    if type(main_key) ~= "string" then
        main_key = "global"
    end
    if main_key == "cooldowns" then
        main_key = "self"
        preferred_sub_key = "cooldowns"
    end
    self.active_main_tab = main_key
    self:update_tab_buttons()

    local tab_key = nil
    if main_key == "global" then
        tab_key = "global"
    elseif main_key == "inventory" then
        tab_key = "inventory"
    elseif main_key == "assets" then
        tab_key = "assets"
    elseif main_key == "status_bar" then
        tab_key = "status_bar"
    elseif main_key == "profile_manager" then
        tab_key = "profile_manager"
    elseif main_key == "help" then
        tab_key = "help"
    else
        local sub_list = self.sub_tabs_by_main[main_key] or {}
        if type(preferred_sub_key) == "string" then
            for i = 1, #sub_list do
                if sub_list[i].key == preferred_sub_key then
                    tab_key = preferred_sub_key
                    break
                end
            end
        end
        if tab_key == nil and type(self.active_tab) == "string" then
            for i = 1, #sub_list do
                if sub_list[i].key == self.active_tab then
                    tab_key = self.active_tab
                    break
                end
            end
        end
        if tab_key == nil and #sub_list > 0 then
            tab_key = sub_list[1].key
        end
    end

    if tab_key == nil then
        tab_key = "global"
    end

    self:select_tab(tab_key)
    self:update_tab_buttons()
end

function ConfigWindow:select_sub_tab(key)
    local main_key = self._main_for_sub ~= nil and self._main_for_sub[key] or nil
    if main_key == nil then
        main_key = self.active_main_tab or "global"
    end
    self:select_main_tab(main_key, key)
end

function ConfigWindow:hide_all_fields()
    for i = 1, #self.all_fields do
        local field = self.all_fields[i]
        if field.kind == "title" then
            field.label:SetVisible(false)
        elseif field.kind == "info" then
            field.label:SetVisible(false)
        elseif field.kind == "hr" then
            field.line:SetVisible(false)
        elseif field.kind == "break" then
            field.spacer:SetVisible(false)
        elseif field.kind == "custom" then
            field.control:SetVisible(false)
        elseif field.kind == "text" then
            field.label:SetVisible(false)
            field.tb:SetVisible(false)
        elseif field.kind == "dropdown" then
            field.label:SetVisible(false)
            field.button:SetVisible(false)
            if field.popup ~= nil then
                field.popup:SetVisible(false)
            end
        elseif field.kind == "checkbox" then
            field.cb:SetVisible(false)
        end
    end
end

function ConfigWindow:show_fields(fields)
    for i = 1, #fields do
        local field = fields[i]
        if field.kind == "title" then
            field.label:SetVisible(true)
        elseif field.kind == "info" then
            field.label:SetVisible(true)
        elseif field.kind == "hr" then
            field.line:SetVisible(true)
        elseif field.kind == "break" then
            field.spacer:SetVisible(true)
        elseif field.kind == "custom" then
            field.control:SetVisible(true)
        elseif field.kind == "text" then
            field.label:SetVisible(true)
            field.tb:SetVisible(true)
        elseif field.kind == "dropdown" then
            field.label:SetVisible(true)
            field.button:SetVisible(true)
        elseif field.kind == "checkbox" then
            field.cb:SetVisible(true)
        end
    end
end

function ConfigWindow:select_tab(key)
    if self.tab_fields[key] == nil then
        return
    end

    self:hide_hint()

    self:hide_all_fields()
    self.active_tab = key
    self.fields = self.tab_fields[key] or {}
    self:show_fields(self.fields)
    self:layout()

    if key == "expiring_effects" then
        self:update_expiring_effects_preview()
    elseif key == "expiring_target_effects" then
        self:update_expiring_target_effects_preview()
    elseif key == "cooldowns" then
        self:update_cooldowns_preview()
    elseif key == "party_vitals" then
        self:update_party_vitals_preview()
    elseif key == "self_vitals" then
        self:update_self_vitals_preview()
    elseif key == "target_vitals" then
        self:update_target_vitals_preview()
    elseif key == "target_boss_vitals" then
        self:update_target_boss_vitals_preview()
    elseif key == "target_targets_target" then
        self:update_target_targets_target_preview()
    end
end

function ConfigWindow:get_geometry_state()
    if _G.loaded_settings == nil then
        return nil
    end

    if _G.loaded_settings.global == nil then
        _G.loaded_settings.global = {}
    end

    if _G.loaded_settings.global.config_window == nil then
        _G.loaded_settings.global.config_window = {}
    end

    return _G.loaded_settings.global.config_window
end

function ConfigWindow:update_saved_geometry()
    local state = self:get_geometry_state()
    if state == nil then
        return
    end

    local left, top = self:GetPosition()
    local width, height = self:GetSize()

    state.left = left
    state.top = top
    state.width = width
    state.height = height
end

function ConfigWindow:persist_geometry()
    self:update_saved_geometry()
    save_settings()
end

function ConfigWindow:apply_saved_geometry()
    local default_width = _scaled_int(459)
    local default_height = _scaled_int(385)

    local display_width, display_height = Turbine.UI.Display.GetSize()

    local state = nil
    if _G.loaded_settings ~= nil then
        if _G.loaded_settings.global ~= nil then
            state = _G.loaded_settings.global.config_window
        end
    end

    local width = default_width
    local height = default_height
    if state ~= nil and type(state.width) == "number" and type(state.height) == "number" then
        width = state.width
        height = state.height
    end

    if width > display_width then width = display_width end
    if height > display_height then height = display_height end
    if width < _scaled_int(222) then width = _scaled_int(222) end
    if height < _scaled_int(185) then height = _scaled_int(185) end

    self:SetSize(width, height)

    local left = math.floor((display_width - width) / 2)
    local top = math.floor((display_height - height) / 2)
    if state ~= nil and type(state.left) == "number" and type(state.top) == "number" then
        left = state.left
        top = state.top
    end

    if left < 0 then left = 0 end
    if top < 0 then top = 0 end
    if left > (display_width - _scaled_int(37)) then
        left = display_width - _scaled_int(37)
    end
    if top > (display_height - _scaled_int(37)) then
        top = display_height - _scaled_int(37)
    end

    self:SetPosition(left, top)

    self:update_saved_geometry()
end

function ConfigWindow:build_controls()
    self:build_controls_v2()
end

function ConfigWindow:build_controls_v2()
    local hr_color = Turbine.UI.Color(0.35, 0.35, 0.35)
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

    local font_style_labels = { TR("None"), TR("Outline") }
    local font_style_values = { LUI_ENUMS.font_style.NONE, LUI_ENUMS.font_style.OUTLINE }

    local side_labels = { TR("Left"), TR("Right") }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }

    local text_alignment_labels = { TR("Left"), TR("Center"), TR("Right") }
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

    local vitals_effects_position_labels = { TR("Above Morale"), TR("Below Power") }
    local vitals_effects_position_values = {
        LUI_ENUMS.vitals_effects_position.ABOVE,
        LUI_ENUMS.vitals_effects_position.BELOW,
    }

    self.controls = {}
    self.all_fields = {}
    self.tab_fields = {}
    self._color_fields = {}

    local function add_title(text)
        local entry = {}
        entry.kind = "title"

        entry.label = Turbine.UI.Label()
        entry.label:SetParent(self.form)
        entry.label:SetFont(self.title_font)
        entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        entry.label:SetText(text)

        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_info(text, height)
        local entry = {}
        entry.kind = "info"
        entry.base_height = height or 34
        entry.height = _scaled_int(entry.base_height)

        entry.label = Turbine.UI.Label()
        entry.label:SetParent(self.form)
        entry.label:SetFont(_scaled_font(HINT_FONT_NAME, HINT_FONT_SIZE))
        entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        entry.label:SetMultiline(true)
        entry.label:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.85))
        entry.label:SetText(text or "")
        entry.label:SetMouseVisible(false)

        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_hr()
        local entry = {}
        entry.kind = "hr"

        entry.line = Turbine.UI.Control()
        entry.line:SetParent(self.form)
        entry.line:SetMouseVisible(false)
        entry.line:SetBackColor(hr_color)

        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_break(height)
        local entry = {}
        entry.kind = "break"
        entry.base_height = height or 4
        entry.height = _scaled_int(entry.base_height)

        entry.spacer = Turbine.UI.Control()
        entry.spacer:SetParent(self.form)
        entry.spacer:SetMouseVisible(false)
        entry.spacer:SetVisible(true)

        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_custom(key, height)
        local entry = {}
        entry.kind = "custom"
        entry.key = key
        entry.base_height = height or 44
        entry.height = _scaled_int(entry.base_height)

        entry.control = Turbine.UI.Control()
        entry.control:SetParent(self.form)
        entry.control:SetMouseVisible(false)
        entry.control:SetVisible(true)

        self.controls[key] = entry
        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_text(key, label_text, is_color, help_text, full_width)
        local entry = {}
        entry.kind = "text"
        entry.key = key
        entry.label_text = label_text
        entry.is_color = is_color == true
        entry.help_text = help_text
        entry.full_width = full_width == true

        entry.label = Turbine.UI.Label()
        entry.label:SetParent(self.form)
        entry.label:SetFont(self.field_label_font)
        entry.label:SetMultiline(true)
        entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        entry.label:SetText(label_text)
        entry.label:SetZOrder(1)

        if entry.is_color then
            entry.tb = UI.Widgets.LuiColorField()
            ---@diagnostic disable-next-line: undefined-field
            entry.tb:SetScale(_G.settings.global.scale)
            ---@diagnostic disable-next-line: undefined-field
            entry.tb:SetPickerHost(self)
            entry.tb:SetParent(self.form)
            entry.tb:SetFont(self.input_font)
            entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            entry.tb:SetZOrder(2)
        else
            entry.tb = Turbine.UI.Lotro.TextBox()
            entry.tb:SetParent(self.form)
            entry.tb:SetFont(self.input_font)
            entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            entry.tb:SetZOrder(2)
        end

        if type(entry.help_text) == "string" and string.len(entry.help_text) > 0 then
            local function bind_hint(target)
                if target == nil then
                    return
                end
                local prev_enter = target.MouseEnter
                target.MouseEnter = function(sender, args)
                    if prev_enter ~= nil then
                        prev_enter(sender, args)
                    end
                    self:show_hint_for(target, entry.help_text)
                end
                local prev_leave = target.MouseLeave
                target.MouseLeave = function(sender, args)
                    if prev_leave ~= nil then
                        prev_leave(sender, args)
                    end
                    self:hide_hint()
                end
            end

            bind_hint(entry.tb)
            ---@diagnostic disable-next-line: undefined-field
            if entry.is_color == true and entry.tb.tb ~= nil then
                ---@diagnostic disable-next-line: undefined-field
                bind_hint(entry.tb.tb)
            end
            ---@diagnostic disable-next-line: undefined-field
            if entry.is_color == true and entry.tb.swatch_border ~= nil then
                ---@diagnostic disable-next-line: undefined-field
                bind_hint(entry.tb.swatch_border)
            end
        end

        if entry.is_color then
            table.insert(self._color_fields, entry)
        end

        entry.tb.TextChanged = function()
            if self.loading == true then
                return
            end
            if entry.is_color then
                self:update_swatch(entry)
            end
            if entry.on_changed ~= nil then
                entry.on_changed(entry.tb:GetText())
            end
            if self.active_tab == "expiring_effects" then
                self:update_expiring_effects_preview()
            elseif self.active_tab == "expiring_target_effects" then
                self:update_expiring_target_effects_preview()
            elseif self.active_tab == "party_vitals" then
                self:update_party_vitals_preview()
            elseif self.active_tab == "self_vitals" then
                self:update_self_vitals_preview()
            elseif self.active_tab == "target_vitals" then
                self:update_target_vitals_preview()
            elseif self.active_tab == "target_boss_vitals" then
                self:update_target_boss_vitals_preview()
            elseif self.active_tab == "target_targets_target" then
                self:update_target_targets_target_preview()
            end
        end

        entry.get_value = function()
            return entry.tb:GetText()
        end

        entry.set_value = function(value)
            entry.tb:SetText(value or "")
        end

        self.controls[key] = entry
        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_dropdown(key, label_text, option_labels, option_values, help_text, full_width)
        local entry = {}
        entry.kind = "dropdown"
        entry.key = key
        entry.label_text = label_text
        entry.option_labels = option_labels or {}
        entry.option_values = option_values or {}
        entry.help_text = help_text
        entry.full_width = full_width == true
        entry.value = nil

        entry.label = Turbine.UI.Label()
        entry.label:SetParent(self.form)
        entry.label:SetFont(self.field_label_font)
        entry.label:SetMultiline(true)
        entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        entry.label:SetText(label_text)
        entry.label:SetZOrder(1)

        entry.button = UI.Widgets.LuiDropdown()
        entry.button:SetParent(self.form)
        entry.button:SetScale(_G.settings.global.scale)
        entry.button:SetFont(self.input_font)
        entry.button:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        entry.button:SetPopupHost(self)
        entry.button:SetMappedOptions(entry.option_labels, entry.option_values)
        entry.button:SetZOrder(2)
        entry.value = entry.button:GetValue()
        entry.button.ValueChanged = function(_, value)
            entry.value = value
            if entry.on_changed ~= nil then
                entry.on_changed(value)
            end
            if self.loading == true then
                return
            end
            if self.active_tab == "expiring_effects" then
                self:update_expiring_effects_preview()
            elseif self.active_tab == "expiring_target_effects" then
                self:update_expiring_target_effects_preview()
            elseif self.active_tab == "party_vitals" then
                self:update_party_vitals_preview()
            elseif self.active_tab == "self_vitals" then
                self:update_self_vitals_preview()
            elseif self.active_tab == "target_vitals" then
                self:update_target_vitals_preview()
            elseif self.active_tab == "target_boss_vitals" then
                self:update_target_boss_vitals_preview()
            elseif self.active_tab == "target_targets_target" then
                self:update_target_targets_target_preview()
            end
        end

        if type(entry.help_text) == "string" and string.len(entry.help_text) > 0 then
            local target = entry.button.button or entry.button
            local prev_enter = target.MouseEnter
            target.MouseEnter = function(sender, args)
                if prev_enter ~= nil then
                    prev_enter(sender, args)
                end
                self:show_hint_for(target, entry.help_text)
            end
            local prev_leave = target.MouseLeave
            target.MouseLeave = function(sender, args)
                if prev_leave ~= nil then
                    prev_leave(sender, args)
                end
                self:hide_hint()
            end
        end

        function entry:get_value()
            return entry.button:GetValue()
        end

        function entry:set_value(value)
            local chosen = nil
            for i = 1, #entry.option_values do
                if entry.option_values[i] == value then
                    chosen = value
                    break
                end
            end
            if chosen == nil then
                chosen = entry.option_values[1]
            end

            entry.value = chosen
            entry.button:SetValue(chosen)
        end

        self.controls[key] = entry
        table.insert(self.all_fields, entry)
        return entry
    end

    local function add_checkbox(key, label_text, full_width)
        local entry = {}
        entry.kind = "checkbox"
        entry.key = key
        entry.label_text = label_text
        entry.full_width = full_width == true

        entry.cb = Turbine.UI.Lotro.CheckBox()
        entry.cb:SetParent(self.form)
        entry.cb:SetFont(self.field_label_font)
        entry.cb:SetText(" " .. tostring(label_text or ""))
        entry.cb:SetZOrder(2)
        entry.cb.CheckedChanged = function()
            if entry.on_changed ~= nil then
                entry.on_changed(entry.cb:IsChecked())
            end
            if self.loading == true then
                return
            end
            if self.active_tab == "party_vitals" then
                self:update_party_vitals_preview()
            elseif self.active_tab == "self_vitals" then
                self:update_self_vitals_preview()
            elseif self.active_tab == "target_vitals" then
                self:update_target_vitals_preview()
            elseif self.active_tab == "target_boss_vitals" then
                self:update_target_boss_vitals_preview()
            elseif self.active_tab == "target_targets_target" then
                self:update_target_targets_target_preview()
            end
        end

        self.controls[key] = entry
        table.insert(self.all_fields, entry)
        return entry
    end

    local vital_format_help = table.concat({
        TR("Text template tokens:"),
        TR("  %c = current value"),
        TR("  %t = total / maximum value"),
        TR("  %p = percent (e.g. 73%)"),
        TR("  %b = bubble value (temporary morale)"),
        TR("  %B = bubble format output (only when bubble > 0)"),
        TR("  %name% = entity name"),
        TR("  %level% = entity level"),
        "",
        TR("Set the text to empty to hide the label."),
        TR("You can use \\n for a new line."),
        TR("Example: [%level%] %name%\n%c / %t - %p"),
    }, "\n")

    local bubble_format_help = table.concat({
        TR("Bubble format (used by %B; only when bubble > 0)."),
        TR("Use %b for the bubble value."),
        TR("Example:  - %b"),
    }, "\n")

    local ui = {
        add_title = add_title,
        add_info = add_info,
        add_hr = add_hr,
        add_break = add_break,
        add_custom = add_custom,
        add_text = add_text,
        add_dropdown = add_dropdown,
        add_checkbox = add_checkbox,
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

    local tabs = Tabs
    local tab_global = tabs.Global
    local tab_profile_manager = tabs.ProfileManager
    local tab_self_vitals = tabs.SelfVitals
    local tab_target_vitals = tabs.TargetVitals
    local tab_target_boss_vitals = tabs.TargetBossVitals
    local tab_target_targets_target = tabs.TargetTargetsTarget
    local tab_expiring_target_effects = tabs.ExpiringTargetEffects
    local tab_party_layout = tabs.PartyLayout
    local tab_party_vitals = tabs.PartyVitals
    local tab_expiring_effects = tabs.SelfExpiringEffects
    local tab_inventory = tabs.Inventory
    local tab_assets = tabs.AssetsTab
    local tab_status_bar = tabs.StatusBar
    local tab_cooldowns = tabs.Cooldowns
    local tab_help = tabs.Help

    tab_global.create_controls(self, ui)
    tab_profile_manager.create_controls(self, ui)
    tab_self_vitals.create_controls(self, ui)
    tab_target_vitals.create_controls(self, ui)
    tab_target_boss_vitals.create_controls(self, ui)
    tab_target_targets_target.create_controls(self, ui)
    tab_expiring_target_effects.create_controls(self, ui)
    tab_party_layout.create_controls(self, ui)
    tab_party_vitals.create_controls(self, ui)
    tab_expiring_effects.create_controls(self, ui)
    tab_inventory.create_controls(self, ui)
    tab_assets.create_controls(self, ui)
    tab_status_bar.create_controls(self, ui)
    tab_cooldowns.create_controls(self, ui)
    tab_help.create_controls(self, ui)

    self.tab_fields.global = tab_global.register(self, ui)
    self.tab_fields.profile_manager = tab_profile_manager.register(self, ui)
    self.tab_fields.self_vitals = tab_self_vitals.register(self, ui)
    self.tab_fields.target_vitals = tab_target_vitals.register(self, ui)
    self.tab_fields.target_boss_vitals = tab_target_boss_vitals.register(self, ui)
    self.tab_fields.target_targets_target = tab_target_targets_target.register(self, ui)
    self.tab_fields.expiring_target_effects = tab_expiring_target_effects.register(self, ui)
    self.tab_fields.party_layout = tab_party_layout.register(self, ui)
    self.tab_fields.party_vitals = tab_party_vitals.register(self, ui)
    self.tab_fields.expiring_effects = tab_expiring_effects.register(self, ui)
    self.tab_fields.inventory = tab_inventory.register(self, ui)
    self.tab_fields.assets = tab_assets.register(self, ui)
    self.tab_fields.status_bar = tab_status_bar.register(self, ui)
    self.tab_fields.cooldowns = tab_cooldowns.register(self, ui)
    self.tab_fields.help = tab_help.register(self, ui)

    self._tab_modules = {
        tab_global,
        tab_profile_manager,
        tab_self_vitals,
        tab_target_vitals,
        tab_target_boss_vitals,
        tab_target_targets_target,
        tab_expiring_target_effects,
        tab_party_layout,
        tab_party_vitals,
        tab_expiring_effects,
        tab_inventory,
        tab_assets,
        tab_status_bar,
        tab_cooldowns,
        tab_help,
    }
    self._ui = ui

    self:init_expiring_effects_preview()
    self:hook_expiring_effects_preview_events()
    self:init_expiring_target_effects_preview()
    self:hook_expiring_target_effects_preview_events()
    self:init_cooldowns_preview()
    self:hook_cooldowns_preview_events()
    self:init_self_vitals_preview()
    self:init_target_vitals_preview()
    self:init_target_boss_vitals_preview()
    self:init_target_targets_target_preview()
    self:init_party_vitals_preview()
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

function ConfigWindow:init_expiring_effects_preview()
    local holder = self.controls.expiring_effects_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.expiring_effects_preview ~= nil then
        return
    end

    self.expiring_effects_preview = {}
    local p = self.expiring_effects_preview
    p.container = holder.control

    local function create_row()
        local row = {}

        row.border = Turbine.UI.Control()
        row.border:SetParent(p.container)
        row.border:SetMouseVisible(false)

        row.border_top = Turbine.UI.Control()
        row.border_top:SetParent(row.border)
        row.border_top:SetMouseVisible(false)
        row.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_bottom = Turbine.UI.Control()
        row.border_bottom:SetParent(row.border)
        row.border_bottom:SetMouseVisible(false)
        row.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_left = Turbine.UI.Control()
        row.border_left:SetParent(row.border)
        row.border_left:SetMouseVisible(false)
        row.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_right = Turbine.UI.Control()
        row.border_right:SetParent(row.border)
        row.border_right:SetMouseVisible(false)
        row.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.entry = Turbine.UI.Control()
        row.entry:SetParent(row.border)
        row.entry:SetMouseVisible(false)

        row.bar_border = Turbine.UI.Control()
        row.bar_border:SetParent(row.entry)
        row.bar_border:SetMouseVisible(false)

        row.bar_background = Turbine.UI.Control()
        row.bar_background:SetParent(row.bar_border)
        row.bar_background:SetMouseVisible(false)

        row.bar_fill = Turbine.UI.Control()
        row.bar_fill:SetParent(row.bar_background)
        row.bar_fill:SetMouseVisible(false)

        row.label = Turbine.UI.Label()
        row.label:SetParent(row.bar_background)
        row.label:SetMouseVisible(false)
        row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

        row.icon_border = Turbine.UI.Control()
        row.icon_border:SetParent(row.entry)
        row.icon_border:SetMouseVisible(false)

        row.icon_background = Turbine.UI.Control()
        row.icon_background:SetParent(row.icon_border)
        row.icon_background:SetMouseVisible(false)

        row.icon = Turbine.UI.Control()
        row.icon:SetParent(row.icon_background)
        row.icon:SetMouseVisible(false)
        row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        return row
    end

    p.buff = create_row()
    p.debuff_curable = create_row()
    p.debuff_noncurable = create_row()

    self:update_expiring_effects_preview()
end

function ConfigWindow:update_expiring_effects_preview()
    if self.expiring_effects_preview == nil then
        return
    end

    if self.active_tab ~= "expiring_effects" then
        return
    end

    local s = _G.loaded_settings

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return n * raw_scale
    end

    local raw_border = tonumber(self.controls.expiring_effects_border_width.tb:GetText()) or
        s.self.expiring_effects.border_width or 1
    local border = scaled_border(raw_border, 1)
    if border < 0 then border = 0 end

    local raw_bar_width = tonumber(self.controls.expiring_effects_bar_width.tb:GetText()) or
        s.self.expiring_effects.bar_width or 180
    local raw_bar_height = tonumber(self.controls.expiring_effects_bar_height.tb:GetText()) or
        s.self.expiring_effects.bar_height or 22
    local bar_width = scaled_int(raw_bar_width, 180)
    local bar_height = scaled_int(raw_bar_height, 22)
    if bar_width < 10 then bar_width = 10 end
    if bar_height < 10 then bar_height = 10 end
    local max_border = math.floor(math.min(bar_width, bar_height) / 2)
    if border > max_border then border = max_border end

    local background_color = _hex_to_color(self.controls.expiring_effects_background_color.tb:GetText())
        or (s.self.expiring_effects.color and s.self.expiring_effects.color.background)
        or Turbine.UI.Color(0, 0, 0)
    local border_color = _hex_to_color(self.controls.expiring_effects_border_color.tb:GetText())
        or (s.self.expiring_effects.color and s.self.expiring_effects.color.border)
        or background_color
    local buff_bar_color = _hex_to_color(self.controls.expiring_effects_bar_color.tb:GetText())
        or (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_buff or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.7, 0.2)
    local curable_debuff_bar_color = _hex_to_color(self.controls.expiring_effects_debuff_curable_bar_color.tb:GetText())
        or
        (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_debuff_curable or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)
    local noncurable_debuff_bar_color = _hex_to_color(self.controls.expiring_effects_debuff_noncurable_bar_color.tb
            :GetText())
        or
        (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_debuff_noncurable or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)

    local icon_side = self.controls.expiring_effects_icon_side.get_value and
        self.controls.expiring_effects_icon_side:get_value() or nil
    if type(icon_side) ~= "number" then
        icon_side = s.self.expiring_effects.icon_side or LUI_ENUMS.side.RIGHT
    end
    local icon_left = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = self.controls.expiring_effects_bar_expire_towards.get_value and
        self.controls.expiring_effects_bar_expire_towards:get_value() or nil
    if type(bar_expire_towards) ~= "number" then
        bar_expire_towards = s.self.expiring_effects.bar_expire_towards or LUI_ENUMS.side.RIGHT
    end
    local expire_towards_right = bar_expire_towards == LUI_ENUMS.side.RIGHT

    local text_template = self.controls.expiring_effects_text_template and
        self.controls.expiring_effects_text_template.tb and self.controls.expiring_effects_text_template.tb:GetText() or
        nil
    if type(text_template) ~= "string" then
        text_template = s.self.expiring_effects.text_template or "%n  %t"
    end
    if string.len(text_template) == 0 then
        text_template = "%n  %t"
    end
    local text_template_tokens = lui_tokenize_format(text_template)
    local text_alignment = self.controls.expiring_effects_text_alignment.get_value and
        self.controls.expiring_effects_text_alignment:get_value() or nil
    if type(text_alignment) ~= "number" then
        text_alignment = s.self.expiring_effects.text_alignment or LUI_ENUMS.text_alignment.LEFT
    end

    local name_max_chars = tonumber(self.controls.expiring_effects_name_max_chars and
            self.controls.expiring_effects_name_max_chars.tb and
            self.controls.expiring_effects_name_max_chars.tb:GetText() or
            "")
        or s.self.expiring_effects.name_max_chars
        or 10

    local font_name = self.controls.expiring_effects_font_name.get_value and
        self.controls.expiring_effects_font_name:get_value() or nil
    if type(font_name) ~= "number" then
        font_name = s.self.expiring_effects.font.name or LUI_ENUMS.font_name.VERDANA
    end
    local raw_font_size = tonumber(self.controls.expiring_effects_font_size.tb:GetText()) or
        s.self.expiring_effects.font.size or 14
    local font_size = scaled_number(raw_font_size, 14)
    local font = _require_font(font_name, font_size)

    local style_enum = self.controls.expiring_effects_font_style.get_value and
        self.controls.expiring_effects_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
    local font_style = LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None

    local font_color = _hex_to_color(self.controls.expiring_effects_font_color.tb:GetText()) or Turbine.UI.Color(1, 1, 1)
    local outline_color = _hex_to_color(self.controls.expiring_effects_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)

    local threshold = tonumber(self.controls.expiring_effects_threshold.tb:GetText()) or
        s.self.expiring_effects.threshold or 5
    if threshold <= 0 then threshold = 5 end
    local remaining = threshold / 2

    local icon_size = bar_height
    local entry_width = bar_width + icon_size
    local entry_height = bar_height
    local preview_border = 1
    if border > 1 then
        preview_border = 2
    end

    local holder = self.controls.expiring_effects_preview
    local row_spacing = scaled_int(6, 6)
    local bw = entry_width + (2 * preview_border)
    local bh = entry_height + (2 * preview_border)

    local desired_height = (3 * bh) + (2 * row_spacing) + 12
    if desired_height < 80 then desired_height = 80 end
    if holder.height ~= desired_height then
        holder.height = desired_height
        self:layout()
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    local function truncate_name(name, max_chars)
        local n = tostring(name or "")
        local m = max_chars
        if type(m) ~= "number" then
            m = tonumber(m)
        end
        if m == nil or m <= 0 then
            return n
        end
        m = math.floor(m + 0.5)
        if m < 1 then
            return ""
        end
        if string.len(n) <= m then
            return n
        end
        if m >= 4 then
            return string.sub(n, 1, m - 3) .. "..."
        end
        return string.sub(n, 1, m)
    end

    local function apply_row(row, x, y, effect_name, row_bar_color)
        row.border:SetSize(bw, bh)
        row.border:SetPosition(x, y)

        row.entry:SetPosition(preview_border, preview_border)
        row.entry:SetSize(entry_width, entry_height)

        row.border_top:SetPosition(0, 0)
        row.border_top:SetSize(bw, preview_border)
        row.border_bottom:SetPosition(0, bh - preview_border)
        row.border_bottom:SetSize(bw, preview_border)
        row.border_left:SetPosition(0, 0)
        row.border_left:SetSize(preview_border, bh)
        row.border_right:SetPosition(bw - preview_border, 0)
        row.border_right:SetSize(preview_border, bh)

        row.bar_border:SetPosition(icon_left and icon_size or 0, 0)
        row.bar_border:SetSize(bar_width, bar_height)
        row.bar_border:SetBackColor(border_color)

        row.icon_border:SetPosition(icon_left and 0 or bar_width, 0)
        row.icon_border:SetSize(icon_size, icon_size)
        row.icon_border:SetBackColor(border_color)

        local inner_width = bar_width - (2 * border)
        local inner_height = bar_height - (2 * border)
        if inner_width < 1 then inner_width = 1 end
        if inner_height < 1 then inner_height = 1 end

        local bar_inner_w = bar_width - border
        if bar_inner_w < 1 then bar_inner_w = 1 end

        local preview_fill_width = math.floor(inner_width * 0.5 + 0.5)
        if preview_fill_width < 0 then preview_fill_width = 0 end
        if preview_fill_width > inner_width then preview_fill_width = inner_width end
        local bar_bg_x = icon_left and 0 or border
        row.bar_background:SetPosition(bar_bg_x, border)
        row.bar_background:SetSize(bar_inner_w, inner_height)
        row.bar_background:SetBackColor(background_color)

        if expire_towards_right then
            row.bar_fill:SetPosition(bar_inner_w - preview_fill_width, 0)
        else
            row.bar_fill:SetPosition(0, 0)
        end
        row.bar_fill:SetSize(preview_fill_width, inner_height)
        row.bar_fill:SetBackColor(row_bar_color)

        local label_pad = 3
        local label_width = bar_inner_w - (2 * label_pad)
        if label_width < 1 then label_width = 1 end
        row.label:SetPosition(label_pad, 0)
        row.label:SetSize(label_width, inner_height)
        row.label:SetFont(font)
        row.label:SetFontStyle(font_style)
        row.label:SetTextAlignment(text_align(text_alignment))
        row.label:SetForeColor(font_color)
        row.label:SetOutlineColor(outline_color)
        local truncated = truncate_name(effect_name, name_max_chars)
        row.label:SetText(lui_format_tokenized(text_template_tokens, { n = truncated, t = lui_format_timeout(remaining) }))

        local icon_inner = icon_size - (2 * border)
        if icon_inner < 1 then icon_inner = 1 end
        row.icon_background:SetPosition(border, border)
        row.icon_background:SetSize(icon_inner, icon_inner)
        row.icon_background:SetBackColor(background_color)

        row.icon:SetPosition(0, 0)
        row.icon:SetSize(icon_inner, icon_inner)
    end

    local p = self.expiring_effects_preview
    local cw, ch = p.container:GetSize()
    local group_height = (3 * bh) + (2 * row_spacing)
    local x = math.floor((cw - bw) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - group_height) / 2)
    if y < 0 then y = 0 end

    apply_row(p.buff, x, y, TR("Buff"), buff_bar_color)
    apply_row(p.debuff_curable, x, y + bh + row_spacing, TR("Curable Debuff"), curable_debuff_bar_color)
    apply_row(p.debuff_noncurable, x, y + (2 * (bh + row_spacing)), TR("Non-curable Debuff"), noncurable_debuff_bar_color)
end

function ConfigWindow:init_cooldowns_preview()
    local holder = self.controls.cooldowns_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.cooldowns_preview ~= nil then
        return
    end

    self.cooldowns_preview = {}
    local p = self.cooldowns_preview
    p.container = holder.control
    p.preview_border_thickness = 1

    p.container.SizeChanged = function()
        self:update_cooldowns_preview()
    end

    local function create_row()
        local row = {}

        row.preview = Turbine.UI.Control()
        row.preview:SetParent(p.container)
        row.preview:SetMouseVisible(false)

        row.preview_top = Turbine.UI.Control()
        row.preview_top:SetParent(row.preview)
        row.preview_top:SetMouseVisible(false)
        row.preview_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_bottom = Turbine.UI.Control()
        row.preview_bottom:SetParent(row.preview)
        row.preview_bottom:SetMouseVisible(false)
        row.preview_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_left = Turbine.UI.Control()
        row.preview_left:SetParent(row.preview)
        row.preview_left:SetMouseVisible(false)
        row.preview_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_right = Turbine.UI.Control()
        row.preview_right:SetParent(row.preview)
        row.preview_right:SetMouseVisible(false)
        row.preview_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border = Turbine.UI.Control()
        row.border:SetParent(row.preview)
        row.border:SetMouseVisible(false)

        row.border_top = Turbine.UI.Control()
        row.border_top:SetParent(row.border)
        row.border_top:SetMouseVisible(false)
        row.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_bottom = Turbine.UI.Control()
        row.border_bottom:SetParent(row.border)
        row.border_bottom:SetMouseVisible(false)
        row.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_left = Turbine.UI.Control()
        row.border_left:SetParent(row.border)
        row.border_left:SetMouseVisible(false)
        row.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_right = Turbine.UI.Control()
        row.border_right:SetParent(row.border)
        row.border_right:SetMouseVisible(false)
        row.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.entry = Turbine.UI.Control()
        row.entry:SetParent(row.border)
        row.entry:SetMouseVisible(false)

        row.separator = Turbine.UI.Control()
        row.separator:SetParent(row.entry)
        row.separator:SetMouseVisible(false)

        row.bar_background = Turbine.UI.Control()
        row.bar_background:SetParent(row.entry)
        row.bar_background:SetMouseVisible(false)

        row.bar_fill = Turbine.UI.Control()
        row.bar_fill:SetParent(row.bar_background)
        row.bar_fill:SetMouseVisible(false)

        row.label = Turbine.UI.Label()
        row.label:SetParent(row.bar_background)
        row.label:SetMouseVisible(false)
        row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        row.label:SetText("")

        row.icon_background = Turbine.UI.Control()
        row.icon_background:SetParent(row.entry)
        row.icon_background:SetMouseVisible(false)

        row.icon = Turbine.UI.Control()
        row.icon:SetParent(row.icon_background)
        row.icon:SetMouseVisible(false)
        row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        return row
    end

    p.row = create_row()
    self:update_cooldowns_preview()
end

function ConfigWindow:update_cooldowns_preview()
    if self.cooldowns_preview == nil then
        return
    end
    if self.active_tab ~= "cooldowns" then
        return
    end

    local s = _G.loaded_settings

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return n * raw_scale
    end

    local cd = s.self.cooldowns

    local raw_item_w = tonumber(self.controls.cd_item_w.tb:GetText()) or cd.item_w or 150
    local raw_item_h = tonumber(self.controls.cd_item_h.tb:GetText()) or cd.item_h or 26
    local item_w = scaled_int(raw_item_w, 150)
    local item_h = scaled_int(raw_item_h, 26)
    if item_w < 10 then item_w = 10 end
    if item_h < 10 then item_h = 10 end

    local bg = _hex_to_color(self.controls.cd_bg_color.tb:GetText())
        or (cd.color and cd.color.background)
        or Turbine.UI.Color(0, 0, 0)
    local bar = _hex_to_color(self.controls.cd_bar_color.tb:GetText())
        or (cd.color and cd.color.bar)
        or Turbine.UI.Color(1, 0.0, 0.545098, 0.545098)
    local border_color = _hex_to_color(self.controls.cd_border_color.tb:GetText())
        or (cd.color and cd.color.border)
        or Turbine.UI.Color(1, 0, 0, 0)

    local raw_border_w = tonumber(self.controls.cd_border_width.tb:GetText()) or cd.border_width or 1
    local border = scaled_border(raw_border_w, 1)
    if border < 0 then border = 0 end

    local icon_side = self.controls.cd_icon_side.get_value and self.controls.cd_icon_side:get_value() or nil
    if type(icon_side) ~= "number" then
        icon_side = cd.icon_side or LUI_ENUMS.side.RIGHT
    end
    local icon_left = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = self.controls.cd_bar_expire_towards.get_value and
        self.controls.cd_bar_expire_towards:get_value() or nil
    if type(bar_expire_towards) ~= "number" then
        bar_expire_towards = cd.bar_expire_towards or LUI_ENUMS.side.RIGHT
    end

    local bar_mode = self.controls.cd_bar_mode.get_value and self.controls.cd_bar_mode:get_value() or nil
    if type(bar_mode) ~= "number" then
        bar_mode = cd.bar_mode or LUI_ENUMS.bar_mode.UNLOAD
    end

    local text_template = self.controls.cd_text_template.tb:GetText()
    if type(text_template) ~= "string" or text_template == "" then
        text_template = cd.text_template or "%name% - %t"
    end
    local text_template_tokens = lui_tokenize_format(text_template)

    local text_alignment = self.controls.cd_text_alignment.get_value and self.controls.cd_text_alignment:get_value() or nil
    if type(text_alignment) ~= "number" then
        text_alignment = cd.text_alignment or LUI_ENUMS.text_alignment.CENTER
    end

    local raw_text_margin = tonumber(self.controls.cd_text_margin.tb:GetText()) or cd.text_margin or 4
    local text_margin = scaled_int(raw_text_margin, 4)
    if text_margin < 0 then text_margin = 0 end

    local font_name = self.controls.cd_font_name.get_value and self.controls.cd_font_name:get_value() or nil
    if type(font_name) ~= "number" then
        font_name = cd.font.name or LUI_ENUMS.font_name.VERDANA
    end
    local raw_font_size = tonumber(self.controls.cd_font_size.tb:GetText()) or cd.font.size or 14
    local font_size = scaled_number(raw_font_size, 14)
    local font = _require_font(font_name, font_size)

    local font_style = self.controls.cd_font_style.get_value and self.controls.cd_font_style:get_value() or nil
    if type(font_style) ~= "number" then
        font_style = cd.font.style or LUI_ENUMS.font_style.OUTLINE
    end
    local font_style_lotro = LUI_TO_LOTRO.font_style[font_style] or Turbine.UI.FontStyle.None

    local font_color = _hex_to_color(self.controls.cd_font_color.tb:GetText())
        or (cd.font and cd.font.color)
        or Turbine.UI.Color(1, 1, 1, 1)
    local outline_color = _hex_to_color(self.controls.cd_font_outline_color.tb:GetText())
        or (cd.font and cd.font.outline_color)
        or Turbine.UI.Color(1, 0, 0, 0)

    local row = self.cooldowns_preview.row
    local p = self.cooldowns_preview

    local outer_bw = p.preview_border_thickness or 1
    if outer_bw < 1 then outer_bw = 1 end

    local pw, ph = p.container:GetSize()

    local show_w = item_w
    local show_h = item_h

    local max_show_w = pw - (2 * outer_bw)
    local max_show_h = ph - (2 * outer_bw)
    if max_show_w < 1 then max_show_w = 1 end
    if max_show_h < 1 then max_show_h = 1 end

    if show_w > max_show_w then show_w = max_show_w end
    if show_h > max_show_h then show_h = max_show_h end
    if show_w < 1 then show_w = 1 end
    if show_h < 1 then show_h = 1 end

    local bw_draw = border
    if bw_draw * 2 >= show_w then bw_draw = math.floor((show_w - 1) / 2) end
    if bw_draw * 2 >= show_h then bw_draw = math.floor((show_h - 1) / 2) end
    if bw_draw < 0 then bw_draw = 0 end

    local preview_w = show_w + (2 * outer_bw)
    local preview_h = show_h + (2 * outer_bw)

    local off_x = math.max(0, math.floor((pw - preview_w) / 2))
    local off_y = math.max(0, math.floor((ph - preview_h) / 2))

    row.preview:SetPosition(off_x, off_y)
    row.preview:SetSize(preview_w, preview_h)

    row.preview_top:SetPosition(0, 0)
    row.preview_top:SetSize(preview_w, outer_bw)
    row.preview_bottom:SetPosition(0, preview_h - outer_bw)
    row.preview_bottom:SetSize(preview_w, outer_bw)
    row.preview_left:SetPosition(0, 0)
    row.preview_left:SetSize(outer_bw, preview_h)
    row.preview_right:SetPosition(preview_w - outer_bw, 0)
    row.preview_right:SetSize(outer_bw, preview_h)

    row.border:SetPosition(outer_bw, outer_bw)
    row.border:SetSize(show_w, show_h)

    row.border_top:SetBackColor(border_color)
    row.border_bottom:SetBackColor(border_color)
    row.border_left:SetBackColor(border_color)
    row.border_right:SetBackColor(border_color)

    row.border_top:SetPosition(0, 0)
    row.border_top:SetSize(show_w, bw_draw)
    row.border_bottom:SetPosition(0, show_h - bw_draw)
    row.border_bottom:SetSize(show_w, bw_draw)
    row.border_left:SetPosition(0, 0)
    row.border_left:SetSize(bw_draw, show_h)
    row.border_right:SetPosition(show_w - bw_draw, 0)
    row.border_right:SetSize(bw_draw, show_h)

    local inner_x = bw_draw
    local inner_y = bw_draw
    local inner_w = show_w - (2 * bw_draw)
    local inner_h = show_h - (2 * bw_draw)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    row.entry:SetPosition(inner_x, inner_y)
    row.entry:SetSize(inner_w, inner_h)

    local sep_w = bw_draw
    if sep_w < 0 then sep_w = 0 end
    if sep_w >= inner_w then sep_w = inner_w - 1 end
    if sep_w < 0 then sep_w = 0 end

    local icon_size = inner_h
    local max_icon = inner_w - sep_w - 1
    if max_icon < 1 then max_icon = 1 end
    if icon_size > max_icon then
        icon_size = max_icon
    end

    local bar_width = inner_w - icon_size - sep_w
    if bar_width < 1 then bar_width = 1 end

    row.separator:SetBackColor(border_color)
    row.separator:SetVisible(sep_w > 0)

    if icon_left then
        row.icon_background:SetPosition(0, 0)
        row.icon_background:SetSize(icon_size, icon_size)
        row.icon_background:SetBackColor(bg)

        row.separator:SetPosition(icon_size, 0)
        row.separator:SetSize(sep_w, inner_h)

        row.bar_background:SetPosition(icon_size + sep_w, 0)
    else
        row.bar_background:SetPosition(0, 0)

        row.separator:SetPosition(bar_width, 0)
        row.separator:SetSize(sep_w, inner_h)

        row.icon_background:SetPosition(bar_width + sep_w, 0)
        row.icon_background:SetSize(icon_size, icon_size)
        row.icon_background:SetBackColor(bg)
    end

    row.bar_background:SetSize(bar_width, inner_h)
    row.bar_background:SetBackColor(bg)

    local bar_inner_w = bar_width
    local bar_inner_h = inner_h

    local threshold = tonumber(self.controls.cd_threshold.tb:GetText()) or cd.threshold or 30
    if threshold <= 0 then threshold = 30 end

    local total = threshold * 1.4
    if total < 3 then total = 3 end

    local base = total
    if base > threshold then
        base = threshold
    end

    local remaining = base * 0.6
    local ratio = remaining / base
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local percent = ratio
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - ratio
    end

    local fill_width = math.floor(bar_inner_w * percent + 0.5)
    if fill_width < 0 then fill_width = 0 end
    if fill_width > bar_inner_w then fill_width = bar_inner_w end

    local towards_right = bar_expire_towards == LUI_ENUMS.side.RIGHT
    local anchor_right = towards_right
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        anchor_right = towards_right ~= true
    end

    if anchor_right then
        row.bar_fill:SetPosition(bar_inner_w - fill_width, 0)
    else
        row.bar_fill:SetPosition(0, 0)
    end
    row.bar_fill:SetSize(fill_width, bar_inner_h)
    row.bar_fill:SetBackColor(bar)

    row.label:SetFont(font)
    row.label:SetFontStyle(font_style_lotro)
    row.label:SetForeColor(font_color)
    row.label:SetOutlineColor(outline_color)
    row.label:SetTextAlignment(LUI_TO_LOTRO.text_alignment[text_alignment] or Turbine.UI.ContentAlignment.MiddleCenter)

    row.label:SetPosition(text_margin, 0)
    row.label:SetSize(math.max(1, bar_inner_w - (2 * text_margin)), inner_h)

    row.icon:SetPosition(0, 0)
    row.icon:SetSize(icon_size, icon_size)

    local time_t = lui_format_timeout(remaining)
    local time_s = lui_format_timeout_seconds(remaining)
    local ctx = {
        name = TR("Example skill"),
        t = time_t,
        s = time_s,
        n = TR("Example skill"),
        ts = time_s,
    }

    row.label:SetText(lui_format_tokenized(text_template_tokens, ctx))
end

function ConfigWindow:hook_cooldowns_preview_events()
    if self._cooldowns_preview_events_hooked == true then
        return
    end
    self._cooldowns_preview_events_hooked = true

    local function hook_text(key)
        local c = self.controls[key]
        if c == nil or c.tb == nil then
            return
        end
        local prev = c.tb.TextChanged
        c.tb.TextChanged = function(...)
            if prev ~= nil then
                prev(...)
            end
            if self.loading == true then
                return
            end
            self:update_cooldowns_preview()
        end
    end

    local function hook_dropdown(key)
        local c = self.controls[key]
        if c == nil then
            return
        end
        local prev = c.on_changed
        c.on_changed = function(value)
            if prev ~= nil then
                prev(value)
            end
            if self.loading == true then
                return
            end
            self:update_cooldowns_preview()
        end
    end

    hook_text("scale")
    hook_text("self_border_width")
    hook_text("cd_threshold")
    hook_text("cd_item_w")
    hook_text("cd_item_h")
    hook_text("cd_text_template")
    hook_text("cd_text_margin")
    hook_text("cd_name_max_chars")
    hook_text("cd_bg_color")
    hook_text("cd_bar_color")
    hook_text("cd_border_width")
    hook_text("cd_border_color")
    hook_text("cd_font_size")
    hook_text("cd_font_color")
    hook_text("cd_font_outline_color")

    hook_dropdown("cd_icon_side")
    hook_dropdown("cd_flow")
    hook_dropdown("cd_bar_mode")
    hook_dropdown("cd_bar_expire_towards")
    hook_dropdown("cd_text_alignment")
    hook_dropdown("cd_font_name")
    hook_dropdown("cd_font_style")
end

function ConfigWindow:init_expiring_target_effects_preview()
    local holder = self.controls.expiring_target_effects_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.expiring_target_effects_preview ~= nil then
        return
    end

    self.expiring_target_effects_preview = {}
    local p = self.expiring_target_effects_preview
    p.container = holder.control

    local function create_row()
        local row = {}

        row.border = Turbine.UI.Control()
        row.border:SetParent(p.container)
        row.border:SetMouseVisible(false)

        row.border_top = Turbine.UI.Control()
        row.border_top:SetParent(row.border)
        row.border_top:SetMouseVisible(false)
        row.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_bottom = Turbine.UI.Control()
        row.border_bottom:SetParent(row.border)
        row.border_bottom:SetMouseVisible(false)
        row.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_left = Turbine.UI.Control()
        row.border_left:SetParent(row.border)
        row.border_left:SetMouseVisible(false)
        row.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border_right = Turbine.UI.Control()
        row.border_right:SetParent(row.border)
        row.border_right:SetMouseVisible(false)
        row.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.entry = Turbine.UI.Control()
        row.entry:SetParent(row.border)
        row.entry:SetMouseVisible(false)

        row.bar_border = Turbine.UI.Control()
        row.bar_border:SetParent(row.entry)
        row.bar_border:SetMouseVisible(false)

        row.bar_background = Turbine.UI.Control()
        row.bar_background:SetParent(row.bar_border)
        row.bar_background:SetMouseVisible(false)

        row.bar_fill = Turbine.UI.Control()
        row.bar_fill:SetParent(row.bar_background)
        row.bar_fill:SetMouseVisible(false)

        row.label = Turbine.UI.Label()
        row.label:SetParent(row.bar_background)
        row.label:SetMouseVisible(false)
        row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

        row.icon_border = Turbine.UI.Control()
        row.icon_border:SetParent(row.entry)
        row.icon_border:SetMouseVisible(false)

        row.icon_background = Turbine.UI.Control()
        row.icon_background:SetParent(row.icon_border)
        row.icon_background:SetMouseVisible(false)

        row.icon = Turbine.UI.Control()
        row.icon:SetParent(row.icon_background)
        row.icon:SetMouseVisible(false)
        row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        return row
    end

    p.buff = create_row()
    p.debuff_curable = create_row()
    p.debuff_noncurable = create_row()

    self:update_expiring_target_effects_preview()
end

function ConfigWindow:update_expiring_target_effects_preview()
    if self.expiring_target_effects_preview == nil then
        return
    end

    if self.active_tab ~= "expiring_target_effects" then
        return
    end

    local s = _G.loaded_settings

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            n = fallback or 0
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            n = fallback or 0
        end
        return n * raw_scale
    end

    local raw_border = tonumber(self.controls.expiring_target_effects_border_width.tb:GetText()) or
        s.target.expiring_effects.border_width or 1
    local border = scaled_border(raw_border, 1)
    if border < 0 then border = 0 end

    local raw_bar_width = tonumber(self.controls.expiring_target_effects_bar_width.tb:GetText()) or
        s.target.expiring_effects.bar_width or 180
    local raw_bar_height = tonumber(self.controls.expiring_target_effects_bar_height.tb:GetText()) or
        s.target.expiring_effects.bar_height or 22
    local bar_width = scaled_int(raw_bar_width, 180)
    local bar_height = scaled_int(raw_bar_height, 22)
    if bar_width < 10 then bar_width = 10 end
    if bar_height < 10 then bar_height = 10 end
    local max_border = math.floor(math.min(bar_width, bar_height) / 2)
    if border > max_border then border = max_border end

    local background_color = _hex_to_color(self.controls.expiring_target_effects_background_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local border_color = _hex_to_color(self.controls.expiring_target_effects_border_color.tb:GetText())
        or (s.target.expiring_effects.color and s.target.expiring_effects.color.border)
        or background_color

    local debuff_curable_bar_color = _hex_to_color(self.controls.expiring_target_effects_bar_color.tb:GetText())
        or
        (s.target.expiring_effects.color and (s.target.expiring_effects.color.bar_debuff_curable or s.target.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)
    local debuff_noncurable_bar_color = _hex_to_color(self.controls.expiring_target_effects_debuff_noncurable_bar_color
            .tb:GetText())
        or
        (s.target.expiring_effects.color and (s.target.expiring_effects.color.bar_debuff_noncurable or s.target.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)
    local buff_bar_color = _hex_to_color(self.controls.expiring_target_effects_buff_bar_color.tb:GetText())
        or
        (s.target.expiring_effects.color and (s.target.expiring_effects.color.bar_buff or s.target.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.7, 0.2)

    local icon_side = self.controls.expiring_target_effects_icon_side.get_value and
        self.controls.expiring_target_effects_icon_side:get_value() or nil
    if type(icon_side) ~= "number" then
        icon_side = s.target.expiring_effects.icon_side or LUI_ENUMS.side.RIGHT
    end
    local icon_left = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = self.controls.expiring_target_effects_bar_expire_towards.get_value and
        self.controls.expiring_target_effects_bar_expire_towards:get_value() or nil
    if type(bar_expire_towards) ~= "number" then
        bar_expire_towards = s.target.expiring_effects.bar_expire_towards or LUI_ENUMS.side.RIGHT
    end
    local expire_towards_right = bar_expire_towards == LUI_ENUMS.side.RIGHT

    local text_template = self.controls.expiring_target_effects_text_template and
        self.controls.expiring_target_effects_text_template.tb and
        self.controls.expiring_target_effects_text_template.tb:GetText() or nil
    if type(text_template) ~= "string" then
        text_template = s.target.expiring_effects.text_template or "%n  %t"
    end
    if string.len(text_template) == 0 then
        text_template = "%n  %t"
    end
    local text_template_tokens = lui_tokenize_format(text_template)
    local text_alignment = self.controls.expiring_target_effects_text_alignment.get_value and
        self.controls.expiring_target_effects_text_alignment:get_value() or nil
    if type(text_alignment) ~= "number" then
        text_alignment = s.target.expiring_effects.text_alignment or LUI_ENUMS.text_alignment.LEFT
    end

    local name_max_chars = tonumber(self.controls.expiring_target_effects_name_max_chars and
            self.controls.expiring_target_effects_name_max_chars.tb and
            self.controls.expiring_target_effects_name_max_chars.tb:GetText() or "")
        or s.target.expiring_effects.name_max_chars
        or 10

    local font_name = self.controls.expiring_target_effects_font_name.get_value and
        self.controls.expiring_target_effects_font_name:get_value() or nil
    if type(font_name) ~= "number" then
        font_name = s.target.expiring_effects.font.name or LUI_ENUMS.font_name.VERDANA
    end
    local raw_font_size = tonumber(self.controls.expiring_target_effects_font_size.tb:GetText()) or
        s.target.expiring_effects.font.size or 14
    local font_size = scaled_number(raw_font_size, 14)
    local font = _require_font(font_name, font_size)

    local style_enum = self.controls.expiring_target_effects_font_style.get_value and
        self.controls.expiring_target_effects_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
    local font_style = LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None

    local font_color = _hex_to_color(self.controls.expiring_target_effects_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1)
    local outline_color = _hex_to_color(self.controls.expiring_target_effects_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)

    local remaining = 3.6
    local raw_threshold = tonumber(self.controls.expiring_target_effects_threshold.tb:GetText()) or
        s.target.expiring_effects.threshold or 5
    if raw_threshold ~= nil and raw_threshold > 0 then
        remaining = math.max(0.5, math.min(raw_threshold - 0.4, raw_threshold))
    end

    local p = self.expiring_target_effects_preview

    local icon_size = bar_height
    local preview_border = 1
    local bw = bar_width + icon_size + (2 * preview_border)
    local bh = bar_height + (2 * preview_border)

    local row_spacing = scaled_int(6, 6)

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    local function truncate_name(name, max_chars)
        local n = tostring(name or "")
        local m = max_chars
        if type(m) ~= "number" then
            m = tonumber(m)
        end
        if m == nil or m <= 0 then
            return n
        end
        m = math.floor(m + 0.5)
        if m < 1 then
            return ""
        end
        if string.len(n) <= m then
            return n
        end
        if m >= 4 then
            return string.sub(n, 1, m - 3) .. "..."
        end
        return string.sub(n, 1, m)
    end

    local function apply_row(row, x, y, effect_name, row_bar_color)
        row.border:SetSize(bw, bh)
        row.border:SetPosition(x, y)

        row.entry:SetPosition(preview_border, preview_border)
        row.entry:SetSize(bar_width + icon_size, bar_height)

        row.border_top:SetPosition(0, 0)
        row.border_top:SetSize(bw, preview_border)
        row.border_bottom:SetPosition(0, bh - preview_border)
        row.border_bottom:SetSize(bw, preview_border)
        row.border_left:SetPosition(0, 0)
        row.border_left:SetSize(preview_border, bh)
        row.border_right:SetPosition(bw - preview_border, 0)
        row.border_right:SetSize(preview_border, bh)

        row.bar_border:SetPosition(icon_left and icon_size or 0, 0)
        row.bar_border:SetSize(bar_width, bar_height)
        row.bar_border:SetBackColor(border_color)

        row.icon_border:SetPosition(icon_left and 0 or bar_width, 0)
        row.icon_border:SetSize(icon_size, icon_size)
        row.icon_border:SetBackColor(border_color)

        local inner_width = bar_width - (2 * border)
        local inner_height = bar_height - (2 * border)
        if inner_width < 1 then inner_width = 1 end
        if inner_height < 1 then inner_height = 1 end

        local bar_inner_w = bar_width - border
        if bar_inner_w < 1 then bar_inner_w = 1 end

        local preview_fill_width = math.floor(inner_width * 0.5 + 0.5)
        if preview_fill_width < 0 then preview_fill_width = 0 end
        if preview_fill_width > inner_width then preview_fill_width = inner_width end
        local bar_bg_x = icon_left and 0 or border
        row.bar_background:SetPosition(bar_bg_x, border)
        row.bar_background:SetSize(bar_inner_w, inner_height)
        row.bar_background:SetBackColor(background_color)

        if expire_towards_right then
            row.bar_fill:SetPosition(bar_inner_w - preview_fill_width, 0)
        else
            row.bar_fill:SetPosition(0, 0)
        end
        row.bar_fill:SetSize(preview_fill_width, inner_height)
        row.bar_fill:SetBackColor(row_bar_color)

        local label_pad = 3
        local label_width = bar_inner_w - (2 * label_pad)
        if label_width < 1 then label_width = 1 end
        row.label:SetPosition(label_pad, 0)
        row.label:SetSize(label_width, inner_height)
        row.label:SetFont(font)
        row.label:SetFontStyle(font_style)
        row.label:SetTextAlignment(text_align(text_alignment))
        row.label:SetForeColor(font_color)
        row.label:SetOutlineColor(outline_color)
        local truncated = truncate_name(effect_name, name_max_chars)
        row.label:SetText(lui_format_tokenized(text_template_tokens, { n = truncated, t = lui_format_timeout(remaining) }))

        local icon_inner = icon_size - (2 * border)
        if icon_inner < 1 then icon_inner = 1 end
        row.icon_background:SetPosition(border, border)
        row.icon_background:SetSize(icon_inner, icon_inner)
        row.icon_background:SetBackColor(background_color)

        row.icon:SetPosition(0, 0)
        row.icon:SetSize(icon_inner, icon_inner)
    end

    local holder = self.controls.expiring_target_effects_preview
    local desired_height = (3 * bh) + (2 * row_spacing) + 12
    if desired_height < 96 then desired_height = 96 end
    if holder ~= nil and holder.height ~= desired_height then
        holder.height = desired_height
        self:layout()
    end

    local cw, ch = p.container:GetSize()
    local group_height = (3 * bh) + (2 * row_spacing)
    local x = math.floor((cw - bw) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - group_height) / 2)
    if y < 0 then y = 0 end

    apply_row(p.buff, x, y, "Buff", buff_bar_color)
    apply_row(p.debuff_curable, x, y + bh + row_spacing, "Curable Debuff", debuff_curable_bar_color)
    apply_row(p.debuff_noncurable, x, y + (2 * (bh + row_spacing)), "Non-curable Debuff", debuff_noncurable_bar_color)
end

function ConfigWindow:init_self_vitals_preview()
    self:_init_vitals_preview("self_vitals_preview", false)
end

function ConfigWindow:_ensure_gradient_preview(control_key)
    local holder = self.controls[control_key]
    if holder == nil or holder.control == nil then
        return nil
    end
    if holder.gradient_preview ~= nil then
        return holder.gradient_preview
    end

    local p = {}
    p.border = Turbine.UI.Control()
    p.border:SetParent(holder.control)
    p.border:SetMouseVisible(false)

    p.inner = Turbine.UI.Control()
    p.inner:SetParent(p.border)
    p.inner:SetMouseVisible(false)
    p.inner:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))

    p.segments = {}
    for i = 1, 21 do
        local seg = Turbine.UI.Control()
        seg:SetParent(p.inner)
        seg:SetMouseVisible(false)
        p.segments[i] = seg
    end

    holder.gradient_preview = p
    return p
end

function ConfigWindow:_update_gradient_preview(control_key, full_color, mid_color, low_color)
    local holder = self.controls[control_key]
    if holder == nil or holder.control == nil then
        return
    end

    local p = self:_ensure_gradient_preview(control_key)
    if p == nil then
        return
    end

    local w, h = holder.control:GetSize()
    if w == nil or h == nil or w < 1 or h < 1 then
        return
    end

    local strip_w = math.floor((w * 0.5) + 0.5)
    local min_strip_w = _scaled_int(111)
    if strip_w < min_strip_w then strip_w = min_strip_w end
    if strip_w > w then strip_w = w end

    local strip_h = self.input_height
    local min_strip_h = _scaled_int(11)
    if strip_h < min_strip_h then strip_h = min_strip_h end
    if strip_h > h then strip_h = h end

    local border = 1
    local x = math.floor((w - strip_w) / 2)
    local y = math.floor((h - strip_h) / 2)

    p.border:SetPosition(x, y)
    p.border:SetSize(strip_w, strip_h)
    p.border:SetBackColor(Turbine.UI.Color(1, 0.15, 0.15, 0.15))

    local inner_w = strip_w - (2 * border)
    local inner_h = strip_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    p.inner:SetPosition(border, border)
    p.inner:SetSize(inner_w, inner_h)

    local total_units = 20
    local current_units = 0
    for i = 0, 20 do
        local weight = (i == 0 or i == 20) and 0.5 or 1
        local x0 = math.floor((current_units / total_units) * inner_w)
        current_units = current_units + weight
        local x1 = math.floor((current_units / total_units) * inner_w)

        local seg = p.segments[i + 1]
        local seg_w = x1 - x0
        if seg_w < 1 then seg_w = 1 end

        seg:SetPosition(x0, 0)
        seg:SetSize(seg_w, inner_h)
        seg:SetBackColor(_gradient_morale_color(i * 0.05, full_color, mid_color, low_color))
    end
end

function ConfigWindow:init_target_vitals_preview()
    self:_init_vitals_preview("target_vitals_preview", true)
end

function ConfigWindow:update_self_vitals_preview()
    self:_update_vitals_preview("self")
end

function ConfigWindow:update_target_vitals_preview()
    self:_update_vitals_preview("target")
end

function ConfigWindow:init_target_boss_vitals_preview()
    local holder = self.controls.target_boss_vitals_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.target_boss_vitals_preview ~= nil then
        return
    end

    self.target_boss_vitals_preview = {
        root = Turbine.UI.Control(),
        border_top = Turbine.UI.Control(),
        border_bottom = Turbine.UI.Control(),
        border_left = Turbine.UI.Control(),
        border_right = Turbine.UI.Control(),
        effects_top_border = Turbine.UI.Control(),
        morale_border = Turbine.UI.Control(),
        morale_back = Turbine.UI.Control(),
        morale_fill = Turbine.UI.Control(),
        morale_bubble = Turbine.UI.Control(),
        morale_label = Turbine.UI.Label(),
        power_border = Turbine.UI.Control(),
        power_back = Turbine.UI.Control(),
        power_fill = Turbine.UI.Control(),
        power_label = Turbine.UI.Label(),
        buffs = {},
        debuffs = {},
    }

    local p = self.target_boss_vitals_preview
    local all = {
        p.root,
        p.border_top, p.border_bottom, p.border_left, p.border_right,
        p.effects_top_border,
        p.morale_border, p.morale_back, p.morale_fill, p.morale_bubble, p.morale_label,
        p.power_border, p.power_back, p.power_fill, p.power_label,
    }

    for i = 1, #all do
        all[i]:SetParent(holder.control)
        all[i]:SetMouseVisible(false)
    end

    p.morale_back:SetParent(p.morale_border)
    p.morale_fill:SetParent(p.morale_back)
    p.morale_bubble:SetParent(p.morale_back)
    p.morale_label:SetParent(p.morale_border)
    p.power_back:SetParent(p.power_border)
    p.power_fill:SetParent(p.power_back)
    p.power_label:SetParent(p.power_border)

    p.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    p.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    p.morale_label:SetMultiline(true)
    p.power_label:SetMultiline(true)

    for i = 1, 12 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = Turbine.UI.Label()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.buffs[i] = { root = icon, label = label }
    end

    for i = 1, 16 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = Turbine.UI.Label()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.debuffs[i] = { root = icon, label = label }
    end
end

function ConfigWindow:update_target_boss_vitals_preview()
    if self.active_tab ~= "target_boss_vitals" then
        return
    end

    local p = self.target_boss_vitals_preview
    if p == nil then
        self:init_target_boss_vitals_preview()
        p = self.target_boss_vitals_preview
    end
    if p == nil then
        return
    end

    local raw_scale = _G.loaded_settings.global.scale

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        return n * raw_scale
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    local function timer_style(style_enum)
        return LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None
    end

    local raw_configured_frame_w = tonumber(self.controls.target_boss_width.tb:GetText()) or 520
    local raw_configured_power_w = tonumber(self.controls.target_boss_power_width.tb:GetText()) or 140
    local configured_frame_w = scaled_int(raw_configured_frame_w, 520)
    local border = scaled_border(self.controls.target_boss_border_width.tb:GetText(), 1)
    local morale_h = scaled_int(self.controls.target_boss_morale_height.tb:GetText(), 50)
    local power_h = scaled_int(self.controls.target_boss_power_height.tb:GetText(), 26)
    local configured_power_w = scaled_int(raw_configured_power_w, 140)
    local effects_h = scaled_int(self.controls.target_boss_effects_height.tb:GetText(), 132)
    local buff_size = scaled_int(self.controls.target_boss_buff_size.tb:GetText(), 22)
    local debuff_size = scaled_int(self.controls.target_boss_debuff_size.tb:GetText(), 31)
    local power_side = self.controls.target_boss_power_side:get_value() or LUI_ENUMS.side.LEFT
    local power_hidden = self.controls.target_boss_power_hide.cb:IsChecked() == true
    local stacked_effects = power_hidden ~= true and
        (raw_configured_frame_w < 400 or raw_configured_power_w > (raw_configured_frame_w / 2))

    if buff_size < 1 then buff_size = 1 end
    if debuff_size < 1 then debuff_size = 1 end

    local holder = self.controls.target_boss_vitals_preview
    local holder_w = holder.control:GetWidth() or configured_frame_w
    local preview_border = 1
    local frame_w = math.min(configured_frame_w, math.max(1, holder_w - (2 * preview_border)))
    local power_w = power_hidden == true and 0 or configured_power_w

    if power_w > frame_w then
        power_w = frame_w
    end
    if stacked_effects ~= true and power_w >= frame_w then
        power_w = frame_w - 1
    end
    if power_w < 0 then
        power_w = 0
    end

    local effects_w = stacked_effects == true and frame_w or (frame_w - power_w)
    if effects_w < 1 then effects_w = 1 end

    local effects_content_h = math.max(0, effects_h - border)
    local buff_cols = math.max(1, math.floor(effects_w / buff_size))
    local buff_count = 6
    local buff_rows = math.ceil(buff_count / buff_cols)
    local buffs_h = math.min(effects_content_h, buff_rows * buff_size)

    local debuff_cols = math.max(1, math.floor(effects_w / debuff_size))
    local debuff_count = 10
    local debuff_rows = math.ceil(debuff_count / debuff_cols)
    local debuffs_h = math.min(math.max(0, effects_content_h - buffs_h), debuff_rows * debuff_size)

    local effects_total_h = buffs_h + debuffs_h
    local lower_top = morale_h - border
    local reserved_effects_h = math.max(border + effects_total_h, border)
    local lower_h
    local effects_top
    if power_hidden == true then
        lower_h = reserved_effects_h
        effects_top = lower_top
    elseif stacked_effects == true then
        lower_h = power_h + reserved_effects_h
        effects_top = lower_top + power_h - border
    else
        lower_h = math.max(power_h, reserved_effects_h)
        effects_top = lower_top
    end
    local total_h = lower_top + lower_h
    local outer_w = frame_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local holder_extra_h = _scaled_int(9)
    if holder ~= nil and holder.height ~= (outer_h + holder_extra_h) then
        holder.height = outer_h + holder_extra_h
        self:layout()
    end

    local off_x = math.max(0, math.floor((holder_w - outer_w) / 2))
    local outer_y = _scaled_int(4)

    p.root:SetPosition(off_x + preview_border, outer_y + preview_border)
    p.root:SetSize(frame_w, total_h)
    _apply_preview_border({
        border_top = p.border_top,
        border_bottom = p.border_bottom,
        border_left = p.border_left,
        border_right = p.border_right,
    }, outer_w, outer_h)

    local border_color = _hex_to_color(self.controls.target_boss_border_color.tb:GetText()) or Turbine.UI.Color(1, 0, 0,
        0)
    local morale_back = _hex_to_color(self.controls.target_boss_morale_background_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)
    local ressource_back_matches_missing =
        self.controls.target_boss_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_back_dimming = tonumber(self.controls.target_boss_ressource_background_dimming.tb:GetText()) or 0.75
    local morale_high = _hex_to_color(self.controls.target_boss_morale_color_high.tb:GetText()) or
        Turbine.UI.Color(1, 0.290196, 0.639216, 0.286275)
    local morale_medium = _hex_to_color(self.controls.target_boss_morale_color_medium.tb:GetText()) or
        Turbine.UI.Color(1, 0.650980, 0.803922, 0.196078)
    local morale_low = _hex_to_color(self.controls.target_boss_morale_color_low.tb:GetText()) or
        Turbine.UI.Color(1, 0.87, 0.55, 0)
    local morale_critical = _hex_to_color(self.controls.target_boss_morale_color_critical.tb:GetText()) or
        Turbine.UI.Color(1, 0.87, 0.11, 0)
    local morale_gradient = self.controls.target_boss_morale_gradient.cb:IsChecked() == true
    local morale_gradient_full = _hex_to_color(self.controls.target_boss_morale_gradient_full.tb:GetText()) or
        morale_high
    local morale_gradient_mid = _hex_to_color(self.controls.target_boss_morale_gradient_mid.tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local morale_gradient_low = _hex_to_color(self.controls.target_boss_morale_gradient_low.tb:GetText()) or
        morale_critical
    self:_update_gradient_preview("target_boss_morale_gradient_preview", morale_gradient_full, morale_gradient_mid,
        morale_gradient_low)
    local bubble_color = _hex_to_color(self.controls.target_boss_morale_bubble_color.tb:GetText()) or
        Turbine.UI.Color(1, 0.5, 0.8, 1)
    local power_fill = _hex_to_color(self.controls.target_boss_power_color.tb:GetText()) or
        Turbine.UI.Color(1, 0.2, 0.6, 0.98)
    local buff_colors = {
        Turbine.UI.Color(1, 0.15, 0.55, 0.55),
        Turbine.UI.Color(1, 0.20, 0.45, 0.72),
        Turbine.UI.Color(1, 0.33, 0.62, 0.28),
        Turbine.UI.Color(1, 0.58, 0.42, 0.76),
        Turbine.UI.Color(1, 0.72, 0.54, 0.20),
        Turbine.UI.Color(1, 0.24, 0.64, 0.44),
    }
    local debuff_colors = {
        Turbine.UI.Color(1, 0.70, 0.35, 0.18),
        Turbine.UI.Color(1, 0.76, 0.20, 0.24),
        Turbine.UI.Color(1, 0.52, 0.24, 0.68),
        Turbine.UI.Color(1, 0.78, 0.48, 0.14),
        Turbine.UI.Color(1, 0.60, 0.18, 0.46),
        Turbine.UI.Color(1, 0.84, 0.30, 0.10),
    }
    local morale_percent = 0.72
    local bubble_percent = 0.08
    local power_percent = 0.55

    local function resource_background(fill_color)
        if ressource_back_matches_missing == true then
            return _dim_color(fill_color, ressource_back_dimming)
        end
        return morale_back
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    p.border_top:SetBackColor(border_color)
    p.border_bottom:SetBackColor(border_color)
    p.border_left:SetBackColor(border_color)
    p.border_right:SetBackColor(border_color)
    p.effects_top_border:SetBackColor(border_color)
    p.border_top:SetPosition(off_x, outer_y)
    p.border_bottom:SetPosition(off_x, outer_y + outer_h - preview_border)
    p.border_left:SetPosition(off_x, outer_y)
    p.border_right:SetPosition(off_x + outer_w - preview_border, outer_y)

    p.morale_border:SetPosition(off_x + preview_border, outer_y + preview_border)
    p.morale_border:SetSize(frame_w, morale_h)
    p.morale_border:SetBackColor(border_color)
    p.morale_back:SetPosition(border, border)
    p.morale_back:SetSize(frame_w - (2 * border), morale_h - (2 * border))
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, morale_gradient_full,
        morale_gradient_mid, morale_gradient_low, morale_high, morale_medium, morale_low, morale_critical)
    p.morale_back:SetBackColor(resource_background(morale_fill_color))
    p.morale_fill:SetPosition(0, 0)
    p.morale_fill:SetSize(math.floor((frame_w - (2 * border)) * morale_percent + 0.5), morale_h - (2 * border))
    p.morale_fill:SetBackColor(morale_fill_color)
    p.morale_bubble:SetPosition(p.morale_fill:GetWidth(), 0)
    p.morale_bubble:SetSize(math.floor((frame_w - (2 * border)) * bubble_percent + 0.5), morale_h - (2 * border))
    p.morale_bubble:SetBackColor(bubble_color)

    do
        local morale_font_name = self.controls.target_boss_morale_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
        local raw_morale_font_size = tonumber(self.controls.target_boss_morale_font_size.tb:GetText()) or 16
        local morale_font_size = scaled_number(raw_morale_font_size, 16)
        local morale_font = _require_font(morale_font_name, morale_font_size)
        local morale_style_enum = self.controls.target_boss_morale_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
        local morale_font_style = LUI_TO_LOTRO.font_style[morale_style_enum] or Turbine.UI.FontStyle.None
        local morale_font_color = _hex_to_color(self.controls.target_boss_morale_font_color.tb:GetText()) or
            Turbine.UI.Color(1, 1, 1, 1)
        local morale_outline_color = _hex_to_color(self.controls.target_boss_morale_font_outline_color.tb:GetText()) or
            Turbine.UI.Color(1, 0, 0, 0)
        local morale_fmt = self.controls.target_boss_morale_text.tb:GetText() or ""
        local bubble_fmt = self.controls.target_boss_morale_bubble_text.tb:GetText() or ""
        local morale_fmt_tokens = lui_tokenize_format(morale_fmt)
        local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)
        local morale_align_text = self.controls.target_boss_morale_text_alignment:get_value() or
            LUI_ENUMS.text_alignment.CENTER
        local raw_morale_margin = tonumber(self.controls.target_boss_morale_text_margin.tb:GetText()) or 4
        local morale_margin = border + scaled_int(raw_morale_margin, 4)
        local morale_max = 600000
        local morale_cur = math.floor(morale_max * morale_percent + 0.5)
        local bubble_value = math.floor(morale_max * bubble_percent + 0.5)
        local bubble_text = bubble_value > 0 and lui_abbrev_number(bubble_value) or ""
        local bubble_formatted = ""
        if bubble_value > 0 and string.len(bubble_fmt) > 0 then
            bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
        end

        if morale_align_text == LUI_ENUMS.text_alignment.LEFT then
            p.morale_label:SetPosition(morale_margin, 0)
            p.morale_label:SetSize(math.max(1, frame_w - morale_margin), morale_h)
        elseif morale_align_text == LUI_ENUMS.text_alignment.RIGHT then
            p.morale_label:SetPosition(0, 0)
            p.morale_label:SetSize(math.max(1, frame_w - morale_margin), morale_h)
        else
            p.morale_label:SetPosition(0, 0)
            p.morale_label:SetSize(frame_w, morale_h)
        end

        p.morale_label:SetFont(morale_font)
        p.morale_label:SetFontStyle(morale_font_style)
        p.morale_label:SetForeColor(morale_font_color)
        p.morale_label:SetOutlineColor(morale_outline_color)
        p.morale_label:SetTextAlignment(text_align(morale_align_text))
        p.morale_label:SetText(lui_format_tokenized(morale_fmt_tokens, {
            name = "The Watcher in the Water",
            level = "150",
            c = lui_abbrev_number(morale_cur),
            t = lui_abbrev_number(morale_max),
            p = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%",
            b = bubble_text,
            B = bubble_formatted,
        }))
    end

    local power_left = 0
    local effects_left = stacked_effects == true and 0 or power_w
    if stacked_effects ~= true and power_side == LUI_ENUMS.side.RIGHT then
        power_left = frame_w - power_w
        effects_left = 0
    elseif stacked_effects == true and power_side == LUI_ENUMS.side.RIGHT then
        power_left = frame_w - power_w
    end

    p.effects_top_border:SetPosition(off_x + preview_border + effects_left, outer_y + preview_border + effects_top)
    p.effects_top_border:SetSize(effects_w, border)
    p.power_border:SetVisible(power_hidden ~= true)
    p.power_back:SetVisible(power_hidden ~= true)
    p.power_fill:SetVisible(power_hidden ~= true)
    p.power_label:SetVisible(power_hidden ~= true)
    if power_hidden ~= true then
        p.power_border:SetPosition(off_x + preview_border + power_left, outer_y + preview_border + lower_top)
        p.power_border:SetSize(power_w, power_h)
        p.power_border:SetBackColor(border_color)
        p.power_back:SetPosition(border, border)
        p.power_back:SetSize(power_w - (2 * border), power_h - (2 * border))
        p.power_back:SetBackColor(resource_background(power_fill))
        p.power_fill:SetPosition(0, 0)
        p.power_fill:SetSize(math.floor((power_w - (2 * border)) * 0.55 + 0.5), power_h - (2 * border))
        p.power_fill:SetBackColor(power_fill)

        do
            local power_font_name = self.controls.target_boss_power_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
            local raw_power_font_size = tonumber(self.controls.target_boss_power_font_size.tb:GetText()) or 14
            local power_font_size = scaled_number(raw_power_font_size, 14)
            local power_font = _require_font(power_font_name, power_font_size)
            local power_style_enum = self.controls.target_boss_power_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
            local power_font_style = LUI_TO_LOTRO.font_style[power_style_enum] or Turbine.UI.FontStyle.None
            local power_font_color = _hex_to_color(self.controls.target_boss_power_font_color.tb:GetText()) or
                Turbine.UI.Color(1, 1, 1, 1)
            local power_outline_color = _hex_to_color(self.controls.target_boss_power_font_outline_color.tb:GetText()) or
                Turbine.UI.Color(1, 0, 0, 0)
            local power_fmt = self.controls.target_boss_power_text.tb:GetText() or ""
            local power_fmt_tokens = lui_tokenize_format(power_fmt)
            local power_align_text = self.controls.target_boss_power_text_alignment:get_value() or
                LUI_ENUMS.text_alignment.CENTER
            local raw_power_margin = tonumber(self.controls.target_boss_power_text_margin.tb:GetText()) or 4
            local power_margin = border + scaled_int(raw_power_margin, 4)
            local power_max = 120000
            local power_cur = math.floor(power_max * power_percent + 0.5)

            if power_align_text == LUI_ENUMS.text_alignment.LEFT then
                p.power_label:SetPosition(power_margin, 0)
                p.power_label:SetSize(math.max(1, power_w - power_margin), power_h)
            elseif power_align_text == LUI_ENUMS.text_alignment.RIGHT then
                p.power_label:SetPosition(0, 0)
                p.power_label:SetSize(math.max(1, power_w - power_margin), power_h)
            else
                p.power_label:SetPosition(0, 0)
                p.power_label:SetSize(power_w, power_h)
            end

            p.power_label:SetFont(power_font)
            p.power_label:SetFontStyle(power_font_style)
            p.power_label:SetForeColor(power_font_color)
            p.power_label:SetOutlineColor(power_outline_color)
            p.power_label:SetTextAlignment(text_align(power_align_text))
            p.power_label:SetText(lui_format_tokenized(power_fmt_tokens, {
                name = "The Watcher in the Water",
                level = "150",
                c = lui_abbrev_number(power_cur),
                t = lui_abbrev_number(power_max),
                p = tostring(math.floor(power_percent * 100 + 0.5)) .. "%",
            }))
        end
    end

    local buff_timer_font_name = self.controls.target_boss_buff_timer_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_buff_timer_font_size = tonumber(self.controls.target_boss_buff_timer_font_size.tb:GetText()) or 12
    local buff_timer_font_size = scaled_number(raw_buff_timer_font_size, 12)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style = timer_style(self.controls.target_boss_buff_timer_font_style:get_value() or
        LUI_ENUMS.font_style.OUTLINE)
    local buff_timer_color = _hex_to_color(self.controls.target_boss_buff_timer_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1, 1)
    local buff_timer_outline = _hex_to_color(self.controls.target_boss_buff_timer_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)

    local buffs_top = effects_top + border
    for i = 1, #p.buffs do
        local icon = p.buffs[i]
        if i <= buff_count then
            local idx = i - 1
            local col = idx % buff_cols
            local row = math.floor(idx / buff_cols)
            icon.root:SetVisible(true)
            icon.root:SetPosition(
                off_x + preview_border + effects_left + (col * buff_size),
                outer_y + preview_border + buffs_top + (row * buff_size)
            )
            icon.root:SetSize(buff_size, buff_size)
            icon.root:SetBackColor(buff_colors[((i - 1) % #buff_colors) + 1])
            icon.label:SetPosition(0, 0)
            icon.label:SetSize(buff_size, buff_size)
            icon.label:SetFont(buff_timer_font)
            icon.label:SetFontStyle(buff_timer_style)
            icon.label:SetForeColor(buff_timer_color)
            icon.label:SetOutlineColor(buff_timer_outline)
            icon.label:SetText(i == 1 and lui_format_timeout(6) or (i == 2 and lui_format_timeout(2.4) or ""))
        else
            icon.root:SetVisible(false)
        end
    end

    local debuff_timer_font_name = self.controls.target_boss_debuff_timer_font_name:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_debuff_timer_font_size = tonumber(self.controls.target_boss_debuff_timer_font_size.tb:GetText()) or 25
    local debuff_timer_font_size = scaled_number(raw_debuff_timer_font_size, 25)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style = timer_style(self.controls.target_boss_debuff_timer_font_style:get_value() or
        LUI_ENUMS.font_style.OUTLINE)
    local debuff_timer_color = _hex_to_color(self.controls.target_boss_debuff_timer_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1, 1)
    local debuff_timer_outline = _hex_to_color(self.controls.target_boss_debuff_timer_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)

    local debuffs_top = buffs_top + buffs_h
    for i = 1, #p.debuffs do
        local icon = p.debuffs[i]
        if i <= debuff_count then
            local idx = i - 1
            local col = idx % debuff_cols
            local row = math.floor(idx / debuff_cols)
            icon.root:SetVisible(true)
            icon.root:SetPosition(
                off_x + preview_border + effects_left + (col * debuff_size),
                outer_y + preview_border + debuffs_top + (row * debuff_size)
            )
            icon.root:SetSize(debuff_size, debuff_size)
            icon.root:SetBackColor(debuff_colors[((i - 1) % #debuff_colors) + 1])
            icon.label:SetPosition(0, 0)
            icon.label:SetSize(debuff_size, debuff_size)
            icon.label:SetFont(debuff_timer_font)
            icon.label:SetFontStyle(debuff_timer_style)
            icon.label:SetForeColor(debuff_timer_color)
            icon.label:SetOutlineColor(debuff_timer_outline)
            icon.label:SetText(i == 1 and lui_format_timeout(7) or (i == 2 and lui_format_timeout(2.2) or ""))
        else
            icon.root:SetVisible(false)
        end
    end

    lui_clear_number_abbrev_preview_settings()
end

function ConfigWindow:init_target_targets_target_preview()
    local holder = self.controls.target_targets_target_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.target_targets_target_preview ~= nil then
        return
    end

    self.target_targets_target_preview = {
        container = holder.control,
    }

    local p = self.target_targets_target_preview
    p.container:SetMouseVisible(false)

    p.outer = Turbine.UI.Control()
    p.outer:SetParent(p.container)
    p.outer:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.outer)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.outer)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.outer)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.outer)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.outer)
    p.root:SetMouseVisible(false)

    p.background = Turbine.UI.Control()
    p.background:SetParent(p.root)
    p.background:SetMouseVisible(false)

    p.morale = Turbine.UI.Control()
    p.morale:SetParent(p.background)
    p.morale:SetMouseVisible(false)
    p.morale:SetZOrder(1)

    p.bubble = Turbine.UI.Control()
    p.bubble:SetParent(p.background)
    p.bubble:SetMouseVisible(false)
    p.bubble:SetZOrder(2)
    p.bubble:SetVisible(false)

    p.label = Turbine.UI.Label()
    p.label:SetParent(p.root)
    p.label:SetMouseVisible(false)
    p.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    p.label:SetZOrder(10)
end

function ConfigWindow:update_target_targets_target_preview()
    if self.active_tab ~= "target_targets_target" then
        return
    end

    local p = self.target_targets_target_preview
    if p == nil then
        self:init_target_targets_target_preview()
        p = self.target_targets_target_preview
    end
    if p == nil then
        return
    end

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        return n * raw_scale
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local frame_w = scaled_int(tonumber(self.controls.target_targets_target_width.tb:GetText()), 250)
    local border = scaled_border(tonumber(self.controls.target_targets_target_border_width.tb:GetText()), 1)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_h = tonumber(self.controls.target_targets_target_height.tb:GetText()) or 26
    local bar_h = scaled_int(raw_h, 26)
    if bar_h < 10 then bar_h = 10 end

    local preview_border = 1
    local outer_w = frame_w + (2 * preview_border)
    local outer_h = bar_h + (2 * preview_border)
    local desired_h = bar_h + 24 + (2 * preview_border)
    local holder = self.controls.target_targets_target_preview
    if holder ~= nil and holder.height ~= desired_h then
        holder.height = desired_h
        self:layout()
    end

    local cw, ch = p.container:GetSize()
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - outer_h) / 2)
    if y < 0 then y = 0 end

    p.outer:SetPosition(x, y)
    p.outer:SetSize(outer_w, outer_h)
    p.root:SetPosition(preview_border, preview_border)
    p.root:SetSize(frame_w, bar_h)
    _apply_preview_border(p, outer_w, outer_h)

    local morale_bg = _hex_to_color(self.controls.target_targets_target_background_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local ressource_bg_matches_missing =
        self.controls.target_targets_target_background_matches_missing.cb:IsChecked() == true
    local ressource_bg_dimming = tonumber(self.controls.target_targets_target_background_dimming.tb:GetText()) or 0.75
    local border_color = _hex_to_color(self.controls.target_targets_target_border_color.tb:GetText()) or morale_bg
    local bubble_color = _hex_to_color(self.controls.target_targets_target_bubble_color.tb:GetText()) or
        Turbine.UI.Color(0.2, 0.8, 1.0)
    local gradient_enabled = self.controls.target_targets_target_color_gradient.cb:IsChecked() == true
    local high = _hex_to_color(self.controls.target_targets_target_color_high.tb:GetText()) or
        Turbine.UI.Color(0.290196, 0.639216, 0.286275)
    local medium = _hex_to_color(self.controls.target_targets_target_color_medium.tb:GetText()) or
        Turbine.UI.Color(1, 0.650980, 0.803922, 0.196078)
    local low = _hex_to_color(self.controls.target_targets_target_color_low.tb:GetText()) or
        Turbine.UI.Color(1, 0.5, 0)
    local critical = _hex_to_color(self.controls.target_targets_target_color_critical.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0)
    local gradient_full = _hex_to_color(self.controls.target_targets_target_color_gradient_full.tb:GetText()) or high
    local gradient_mid = _hex_to_color(self.controls.target_targets_target_color_gradient_mid.tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local gradient_low = _hex_to_color(self.controls.target_targets_target_color_gradient_low.tb:GetText()) or critical
    self:_update_gradient_preview("target_targets_target_color_gradient_preview", gradient_full, gradient_mid,
        gradient_low)

    local function morale_color(percent)
        return _morale_color_preview(percent, gradient_enabled, gradient_full, gradient_mid, gradient_low, high,
            medium, low, critical)
    end

    local function resource_background(fill_color)
        if ressource_bg_matches_missing == true then
            return _dim_color(fill_color, ressource_bg_dimming)
        end
        return morale_bg
    end

    p.root:SetBackColor(border_color)

    local inner_w = frame_w - (2 * border)
    local inner_h = bar_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    local percent = 0.72
    local fill_color = morale_color(percent)

    p.background:SetPosition(border, border)
    p.background:SetSize(inner_w, inner_h)
    p.background:SetBackColor(resource_background(fill_color))

    local fill_w = math.floor(inner_w * percent + 0.5)
    if fill_w < 0 then fill_w = 0 end
    if fill_w > inner_w then fill_w = inner_w end

    p.morale:SetPosition(0, 0)
    p.morale:SetSize(fill_w, inner_h)
    p.morale:SetBackColor(fill_color)

    local bubble_percent = 0.20
    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        p.bubble:SetVisible(true)
        p.bubble:SetBackColor(bubble_color)
        p.bubble:SetTop(0)
        p.bubble:SetHeight(inner_h)
        p.bubble:SetWidth(bubble_w)
        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = fill_w
        if left_inner > max_left then left_inner = max_left end
        p.bubble:SetLeft(left_inner)
    else
        p.bubble:SetVisible(false)
    end

    local tt_font_name = self.controls.target_targets_target_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_tt_font_size = tonumber(self.controls.target_targets_target_font_size.tb:GetText()) or 14
    local tt_font_size = scaled_number(raw_tt_font_size, 14)
    local tt_font = _require_font(tt_font_name, tt_font_size)
    local tt_style_enum = self.controls.target_targets_target_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
    local tt_font_style = LUI_TO_LOTRO.font_style[tt_style_enum] or Turbine.UI.FontStyle.None
    local tt_font_color = _hex_to_color(self.controls.target_targets_target_font_color.tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local tt_outline_color = _hex_to_color(self.controls.target_targets_target_font_outline_color.tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    p.label:SetFont(tt_font)
    p.label:SetFontStyle(tt_font_style)
    p.label:SetForeColor(tt_font_color)
    p.label:SetOutlineColor(tt_outline_color)

    local tt_align_text = self.controls.target_targets_target_text_alignment:get_value() or
        LUI_ENUMS.text_alignment.CENTER
    p.label:SetTextAlignment(text_align(tt_align_text))

    do
        local raw_margin = tonumber(self.controls.target_targets_target_text_margin.tb:GetText()) or 4
        local m = border + scaled_int(raw_margin, 4)
        if tt_align_text == LUI_ENUMS.text_alignment.LEFT then
            p.label:SetPosition(m, 0)
            p.label:SetSize(frame_w - m, bar_h)
        elseif tt_align_text == LUI_ENUMS.text_alignment.RIGHT then
            p.label:SetPosition(0, 0)
            p.label:SetSize(frame_w - m, bar_h)
        else
            p.label:SetPosition(0, 0)
            p.label:SetSize(frame_w, bar_h)
        end
    end

    local tt_fmt = self.controls.target_targets_target_text.tb:GetText() or ""
    local tt_bubble_fmt = self.controls.target_targets_target_bubble_text.tb:GetText() or ""
    local tt_fmt_tokens = lui_tokenize_format(tt_fmt)
    local tt_bubble_tokens = lui_tokenize_format(tt_bubble_fmt)

    local tt_max = 10000
    local tt_cur = math.floor(tt_max * percent + 0.5)
    local tt_bubble = math.floor(tt_max * bubble_percent + 0.5)
    local tt_pct_text = tostring(math.floor(percent * 100 + 0.5)) .. "%"

    local tt_bubble_text = ""
    if tt_bubble > 0 then
        tt_bubble_text = lui_abbrev_number(tt_bubble)
    end

    local tt_bubble_formatted = ""
    if tt_bubble > 0 and string.len(tt_bubble_fmt) > 0 then
        tt_bubble_formatted = lui_format_tokenized(tt_bubble_tokens, { b = tt_bubble_text })
    end

    p.label:SetText(lui_format_tokenized(tt_fmt_tokens, {
        name = TR("Target's Target"),
        level = "150",
        c = lui_abbrev_number(tt_cur),
        t = lui_abbrev_number(tt_max),
        p = tt_pct_text,
        b = tt_bubble_text,
        B = tt_bubble_formatted,
    }))

    lui_clear_number_abbrev_preview_settings()
end

function ConfigWindow:init_party_vitals_preview()
    local holder = self.controls.party_vitals_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.party_vitals_preview ~= nil then
        return
    end

    self.party_vitals_preview = {
        container = holder.control,
        members = {},
        max_members = 24,
    }

    local p = self.party_vitals_preview
    p.container:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.container)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.container)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.container)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.container)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.container)
    p.root:SetMouseVisible(false)

    for i = 1, p.max_members do
        local m = {}

        m.root = Turbine.UI.Control()
        m.root:SetParent(p.root)
        m.root:SetMouseVisible(false)

        m.class_icon = Turbine.UI.Control()
        m.class_icon:SetParent(m.root)
        m.class_icon:SetMouseVisible(false)
        m.class_icon:SetZOrder(9)
        m.class_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        m.class_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
        m.class_icon:SetVisible(false)

        m.leader_icon = Turbine.UI.Control()
        m.leader_icon:SetParent(m.root)
        m.leader_icon:SetMouseVisible(false)
        m.leader_icon:SetZOrder(10)
        m.leader_icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
        m.leader_icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
        m.leader_icon:SetVisible(false)

        m.morale_border = Turbine.UI.Control()
        m.morale_border:SetParent(m.root)
        m.morale_border:SetMouseVisible(false)

        m.morale_background = Turbine.UI.Control()
        m.morale_background:SetParent(m.morale_border)
        m.morale_background:SetMouseVisible(false)

        m.morale_bar = Turbine.UI.Control()
        m.morale_bar:SetParent(m.morale_background)
        m.morale_bar:SetMouseVisible(false)
        m.morale_bar:SetZOrder(1)

        m.bubble_bar = Turbine.UI.Control()
        m.bubble_bar:SetParent(m.morale_background)
        m.bubble_bar:SetMouseVisible(false)
        m.bubble_bar:SetZOrder(2)

        m.morale_label = Turbine.UI.Label()
        m.morale_label:SetParent(m.morale_border)
        m.morale_label:SetMouseVisible(false)
        m.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        m.morale_label:SetZOrder(10)

        m.power_border = Turbine.UI.Control()
        m.power_border:SetParent(m.root)
        m.power_border:SetMouseVisible(false)

        m.power_background = Turbine.UI.Control()
        m.power_background:SetParent(m.power_border)
        m.power_background:SetMouseVisible(false)

        m.power_bar = Turbine.UI.Control()
        m.power_bar:SetParent(m.power_background)
        m.power_bar:SetMouseVisible(false)

        m.power_label = Turbine.UI.Label()
        m.power_label:SetParent(m.power_border)
        m.power_label:SetMouseVisible(false)
        m.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

        table.insert(p.members, m)
    end

    self:update_party_vitals_preview()
end

function ConfigWindow:update_party_vitals_preview()
    if self.party_vitals_preview == nil then
        return
    end

    if self.active_tab ~= "party_vitals" then
        return
    end

    local s = _G.loaded_settings

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            n = fallback or 0
        end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = raw_value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            n = fallback or 0
        end
        return n * raw_scale
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local raw_rows = tonumber(self.controls.party_rows.tb:GetText()) or s.party.layout.rows or 6
    local rows = raw_rows
    if rows < 1 then rows = 1 end

    local raw_spacing_x = tonumber(self.controls.party_spacing_x.tb:GetText()) or s.party.layout.spacing_x or 6
    local raw_spacing_y = tonumber(self.controls.party_spacing_y.tb:GetText()) or s.party.layout.spacing_y or 6
    local spacing_x = scaled_int(raw_spacing_x, 6)
    local spacing_y = scaled_int(raw_spacing_y, 6)
    if spacing_x < 0 then spacing_x = 0 end
    if spacing_y < 0 then spacing_y = 0 end

    local raw_frame_w = tonumber(self.controls.party_width.tb:GetText()) or s.party.frame.width or 250
    local raw_border = tonumber(self.controls.party_border_width.tb:GetText()) or s.party.frame.border_width or 1
    local frame_w = scaled_int(raw_frame_w, 250)
    local border = scaled_border(raw_border, 1)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_morale_h = tonumber(self.controls.party_morale_height.tb:GetText()) or s.party.morale.height or 50
    local raw_power_h = tonumber(self.controls.party_power_height.tb:GetText()) or s.party.power.height or 26
    local morale_h = scaled_int(raw_morale_h, 50)
    local power_h = scaled_int(raw_power_h, 26)
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end

    local icon_enabled = true
    if self.controls.party_class_icon_enabled ~= nil then
        icon_enabled = self.controls.party_class_icon_enabled.cb:IsChecked()
    else
        icon_enabled = s.party.class_icon.enabled ~= false
    end

    local raw_icon_size = tonumber(self.controls.party_class_icon_size.tb:GetText()) or s.party.class_icon.size or 24
    local raw_icon_x = tonumber(self.controls.party_class_icon_x.tb:GetText()) or s.party.class_icon.x or 2
    local raw_icon_y = tonumber(self.controls.party_class_icon_y.tb:GetText()) or s.party.class_icon.y or 2
    local icon_size = scaled_int(raw_icon_size, 24)
    local icon_x = scaled_int(raw_icon_x, 2)
    local icon_y = scaled_int(raw_icon_y, 2)
    if icon_size < 16 then icon_size = 16 end
    if icon_size > 50 then icon_size = 50 end

    local leader_enabled = true
    if self.controls.party_leader_icon_enabled ~= nil then
        leader_enabled = self.controls.party_leader_icon_enabled.cb:IsChecked()
    else
        leader_enabled = s.party.leader_icon.enabled ~= false
    end

    local raw_leader_size = tonumber(self.controls.party_leader_icon_size.tb:GetText()) or s.party.leader_icon.size or 24
    local raw_leader_x = tonumber(self.controls.party_leader_icon_x.tb:GetText()) or s.party.leader_icon.x or 0
    local raw_leader_y = tonumber(self.controls.party_leader_icon_y.tb:GetText()) or s.party.leader_icon.y or 2
    local leader_size = scaled_int(raw_leader_size, 24)
    local leader_x = scaled_int(raw_leader_x, 0)
    local leader_y = scaled_int(raw_leader_y, 2)
    if leader_size < 16 then leader_size = 16 end
    if leader_size > 50 then leader_size = 50 end

    local power_y = morale_h - border
    local member_h = morale_h + power_h - border
    if member_h < 1 then member_h = 1 end

    local morale_bg = _hex_to_color(self.controls.party_morale_background_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local border_color = _hex_to_color(self.controls.party_border_color.tb:GetText()) or morale_bg
    local bubble_color = _hex_to_color(self.controls.party_morale_bubble_color.tb:GetText()) or
        Turbine.UI.Color(0.53, 0.8, 0.98)
    local neutral_color = _hex_to_color(self.controls.party_morale_color_neutral.tb:GetText()) or
        Turbine.UI.Color(0.5, 0.6, 0.5)
    local high_color = _hex_to_color(self.controls.party_morale_color_high.tb:GetText()) or
        Turbine.UI.Color(0.290196, 0.639216, 0.286275)
    local med_color = _hex_to_color(self.controls.party_morale_color_medium.tb:GetText()) or
        Turbine.UI.Color(0.650980, 0.803922, 0.196078)
    local low_color = _hex_to_color(self.controls.party_morale_color_low.tb:GetText()) or
        Turbine.UI.Color(0.87, 0.55, 0.0)
    local crit_color = _hex_to_color(self.controls.party_morale_color_critical.tb:GetText()) or
        Turbine.UI.Color(0.87, 0.11, 0.0)
    local morale_gradient = self.controls.party_morale_gradient.cb:IsChecked() == true
    local gradient_full = _hex_to_color(self.controls.party_morale_gradient_full.tb:GetText()) or high_color
    local gradient_mid = _hex_to_color(self.controls.party_morale_gradient_mid.tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local gradient_low = _hex_to_color(self.controls.party_morale_gradient_low.tb:GetText()) or crit_color
    self:_update_gradient_preview("party_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)
    local ressource_bg_matches_missing = self.controls.party_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_bg_dimming = tonumber(self.controls.party_ressource_background_dimming.tb:GetText()) or 0.75

    local power_color = _hex_to_color(self.controls.party_power_color.tb:GetText()) or Turbine.UI.Color(0.2, 0.6, 0.98)
    local wrath_color = _hex_to_color(self.controls.party_wrath_color.tb:GetText()) or Turbine.UI.Color(1, 0.33, 0.13)

    local morale_font_name = self.controls.party_morale_font_name:get_value()
    if type(morale_font_name) ~= "number" then
        morale_font_name = (s.party and s.party.morale and s.party.morale.font and s.party.morale.font.name) or
            LUI_ENUMS.font_name.VERDANA
    end
    local morale_font_size = scaled_number(
        tonumber(self.controls.party_morale_font_size.tb:GetText()) or s.party.morale.font.size or 16, 16)
    local morale_font = _require_font(morale_font_name, morale_font_size)
    local morale_style_enum = self.controls.party_morale_font_style:get_value()
        or (s.party and s.party.morale and s.party.morale.font and s.party.morale.font.style)
        or LUI_ENUMS.font_style.OUTLINE
    local morale_font_style = LUI_TO_LOTRO.font_style[morale_style_enum] or Turbine.UI.FontStyle.None
    local morale_font_color = _hex_to_color(self.controls.party_morale_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1)
    local morale_outline_color = _hex_to_color(self.controls.party_morale_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)

    local power_font_name = self.controls.party_power_font_name:get_value()
    if type(power_font_name) ~= "number" then
        power_font_name = (s.party and s.party.power and s.party.power.font and s.party.power.font.name) or
            LUI_ENUMS.font_name.VERDANA
    end
    local power_font_size = scaled_number(
        tonumber(self.controls.party_power_font_size.tb:GetText()) or s.party.power.font.size or 14, 14)
    local power_font = _require_font(power_font_name, power_font_size)
    local power_style_enum = self.controls.party_power_font_style:get_value()
        or (s.party and s.party.power and s.party.power.font and s.party.power.font.style)
        or LUI_ENUMS.font_style.OUTLINE
    local power_font_style = LUI_TO_LOTRO.font_style[power_style_enum] or Turbine.UI.FontStyle.None
    local power_font_color = _hex_to_color(self.controls.party_power_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1)
    local power_outline_color = _hex_to_color(self.controls.party_power_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)

    local morale_fmt = self.controls.party_morale_text.tb:GetText()
    if type(morale_fmt) ~= "string" then morale_fmt = "" end
    local bubble_fmt = self.controls.party_morale_bubble_text.tb:GetText()
    if type(bubble_fmt) ~= "string" then bubble_fmt = "" end
    local power_fmt = self.controls.party_power_text.tb:GetText()
    if type(power_fmt) ~= "string" then power_fmt = "" end
    local morale_fmt_tokens = lui_tokenize_format(morale_fmt)
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)
    local power_fmt_tokens = lui_tokenize_format(power_fmt)
    local morale_align_text = nil
    if self.controls.party_morale_text_alignment ~= nil and self.controls.party_morale_text_alignment.get_value ~= nil then
        morale_align_text = self.controls.party_morale_text_alignment:get_value()
    end
    if type(morale_align_text) ~= "number" then
        morale_align_text = (s.party and s.party.morale and s.party.morale.text_alignment) or
            LUI_ENUMS.text_alignment.CENTER
    end
    local power_align_text = nil
    if self.controls.party_power_text_alignment ~= nil and self.controls.party_power_text_alignment.get_value ~= nil then
        power_align_text = self.controls.party_power_text_alignment:get_value()
    end
    if type(power_align_text) ~= "number" then
        power_align_text = (s.party and s.party.power and s.party.power.text_alignment) or
            LUI_ENUMS.text_alignment.CENTER
    end

    local morale_margin = border +
        scaled_int(
            tonumber(self.controls.party_morale_text_margin.tb:GetText()) or
            (s.party and s.party.morale and s.party.morale.text_margin) or 4, 4)
    local power_margin = border +
        scaled_int(
            tonumber(self.controls.party_power_text_margin.tb:GetText()) or
            (s.party and s.party.power and s.party.power.text_margin) or 4, 4)

    local function resource_background(fill_color)
        if ressource_bg_matches_missing == true then
            return _dim_color(fill_color, ressource_bg_dimming)
        end
        return morale_bg
    end

    local preview_count = 24
    local columns = math.ceil(preview_count / rows)
    if columns < 1 then columns = 1 end

    local used_rows = preview_count
    if used_rows > rows then used_rows = rows end
    if used_rows < 1 then used_rows = 1 end

    local total_w = (columns * frame_w) + ((columns - 1) * spacing_x)
    local total_h = (used_rows * member_h) + ((used_rows - 1) * spacing_y)

    local holder = self.controls.party_vitals_preview
    local preview_border = 1
    local desired_height = total_h + 12 + (2 * preview_border)
    if desired_height < 80 then desired_height = 80 end
    if holder.height ~= desired_height then
        holder.height = desired_height
        self:layout()
    end

    local p = self.party_vitals_preview
    local outer_w = total_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    p.container:SetSize(outer_w, outer_h)
    if p.root ~= nil then
        p.root:SetPosition(preview_border, preview_border)
        p.root:SetSize(total_w, total_h)
    end
    _apply_preview_border(p, outer_w, outer_h)

    local icon_classes = _G.CLASS_ICON_CLASSES

    for i = 1, #p.members do
        local m = p.members[i]
        if m == nil then
            -- skip
        elseif i > preview_count then
            m.root:SetVisible(false)
        else
            m.root:SetVisible(true)

            local idx = i - 1
            local col = math.floor(idx / rows)
            local row = idx - (col * rows)
            local x = col * (frame_w + spacing_x)
            local y = row * (member_h + spacing_y)
            m.root:SetPosition(x, y)
            m.root:SetSize(frame_w, member_h)

            -- BUG: There is a strange bug with SetStretchMode the icon will appear ABOVE everything
            -- m.class_icon:SetStretchMode(1)

            if icon_enabled == true and icon_size > 0 then
                m.class_icon:SetVisible(true)
                m.class_icon:SetSize(icon_size, icon_size)
                m.class_icon:SetPosition(icon_x, icon_y)
                local icon = _G.get_class_icon(icon_classes[((i - 1) % #icon_classes) + 1], icon_size)
                if icon ~= nil then
                    m.class_icon:SetBackground(icon)
                else
                    m.class_icon:SetVisible(false)
                end
            else
                m.class_icon:SetVisible(false)
            end

            if leader_enabled == true and leader_size > 0 and i == 1 then
                m.leader_icon:SetVisible(true)
                m.leader_icon:SetSize(leader_size, leader_size)
                m.leader_icon:SetPosition(leader_x, leader_y)
                m.leader_icon:SetBackground("Geldahr/LUI/PluginAssets/scaled/gold_shield_" .. leader_size .. ".tga")
            else
                m.leader_icon:SetVisible(false)
            end

            m.morale_border:SetPosition(0, 0)
            m.morale_border:SetSize(frame_w, morale_h)
            m.morale_border:SetBackColor(border_color)

            local inner_w = frame_w - (2 * border)
            local inner_morale_h = morale_h - (2 * border)
            if inner_w < 1 then inner_w = 1 end
            if inner_morale_h < 1 then inner_morale_h = 1 end

            m.morale_background:SetPosition(border, border)
            m.morale_background:SetSize(inner_w, inner_morale_h)
            m.morale_background:SetBackColor(morale_bg)

            m.morale_bar:SetPosition(0, 0)
            m.morale_bar:SetSize(inner_w, inner_morale_h)

            local morale_samples = {
                -- Include a few bubble examples + a full and half-full example.
                { max = 9999,   cur = 9999,   bubble = 0 },     -- full (no bubble)
                { max = 200000, cur = 101234, bubble = 0 },     -- ~50%
                { max = 150000, cur = 120345, bubble = 25000 }, -- bubble
                { max = 120000, cur = 120000, bubble = 15000 }, -- full + bubble
                { max = 250000, cur = 123456, bubble = 40000 }, -- ~50% + bubble

                { max = 999,    cur = 875,    bubble = 0 },     -- 3 digits max
                { max = 12345,  cur = 9876,   bubble = 0 },     -- 5 digits max, 4 digits cur
                { max = 54321,  cur = 23456,  bubble = 0 },     -- 5/5 digits
                { max = 100000, cur = 99999,  bubble = 0 },     -- 6 digits max, 5 digits cur
                { max = 250000, cur = 123456, bubble = 0 },     -- 6/6 digits
                { max = 999999, cur = 888888, bubble = 0 },     -- 6/6 digits
                { max = 10000,  cur = 4321,   bubble = 0 },     -- 5 digits max? (10000), 4 digits cur
                { max = 99999,  cur = 54321,  bubble = 0 },     -- 5/5 digits
                { max = 600000, cur = 499999, bubble = 0 },     -- 6/6 digits
                { max = 45000,  cur = 12345,  bubble = 0 },     -- 5/5 digits
            }

            local sample = morale_samples[((i - 1) % #morale_samples) + 1] or {}
            local morale_max = tonumber(sample.max) or 1
            local morale_cur = tonumber(sample.cur) or 0
            local bubble_cur = tonumber(sample.bubble) or 0

            if morale_max <= 0 then morale_max = 1 end
            if morale_cur < 0 then morale_cur = 0 end
            if bubble_cur < 0 then bubble_cur = 0 end
            if morale_cur > morale_max then
                morale_cur = morale_max
            end

            local morale_percent = morale_cur / morale_max
            if morale_percent < 0 then morale_percent = 0 end
            if morale_percent > 1 then morale_percent = 1 end
            local morale_fill_w = math.floor((inner_w * morale_percent) + 0.5)
            if morale_fill_w < 0 then morale_fill_w = 0 end
            if morale_fill_w > inner_w then morale_fill_w = inner_w end
            local fill_color = _morale_color_preview(morale_percent, morale_gradient, gradient_full, gradient_mid,
                gradient_low, high_color, med_color, low_color, crit_color)
            m.morale_background:SetBackColor(resource_background(fill_color))
            m.morale_bar:SetBackColor(fill_color)
            m.morale_bar:SetWidth(morale_fill_w)

            local bubble_percent = 0.0
            if bubble_cur > 0 then
                bubble_percent = bubble_cur / morale_max
                if bubble_percent < 0 then bubble_percent = 0 end
                if bubble_percent > 1 then bubble_percent = 1 end
            end
            local bubble_w = math.floor((inner_w * bubble_percent) + 0.5)
            if bubble_w < 0 then bubble_w = 0 end
            if bubble_w > inner_w then bubble_w = inner_w end
            if bubble_w > 0 then
                m.bubble_bar:SetVisible(true)
                m.bubble_bar:SetTop(0)
                m.bubble_bar:SetHeight(inner_morale_h)
                m.bubble_bar:SetWidth(bubble_w)
                local max_left = inner_w - bubble_w
                if max_left < 0 then max_left = 0 end
                local left_inner = morale_fill_w
                if left_inner > max_left then left_inner = max_left end
                m.bubble_bar:SetLeft(left_inner)
                m.bubble_bar:SetBackColor(bubble_color)
            else
                m.bubble_bar:SetVisible(false)
            end

            if morale_align_text == LUI_ENUMS.text_alignment.LEFT then
                m.morale_label:SetPosition(morale_margin, 0)
                m.morale_label:SetSize(frame_w - morale_margin, morale_h)
            elseif morale_align_text == LUI_ENUMS.text_alignment.RIGHT then
                m.morale_label:SetPosition(0, 0)
                m.morale_label:SetSize(frame_w - morale_margin, morale_h)
            else
                m.morale_label:SetPosition(0, 0)
                m.morale_label:SetSize(frame_w, morale_h)
            end
            m.morale_label:SetFont(morale_font)
            m.morale_label:SetFontStyle(morale_font_style)
            m.morale_label:SetForeColor(morale_font_color)
            m.morale_label:SetOutlineColor(morale_outline_color)
            m.morale_label:SetTextAlignment(text_align(morale_align_text))

            local bubble_text = ""
            if bubble_cur > 0 then
                bubble_text = lui_abbrev_number(bubble_cur)
            end
            local morale_pct_text = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%"
            local ctx = {
                c = lui_abbrev_number(morale_cur),
                t = lui_abbrev_number(morale_max),
                p = morale_pct_text,
                b = bubble_text,
                B = "",
                name = TR("Player ") .. tostring(i),
                level = "150",
            }

            if bubble_cur > 0 and string.len(bubble_fmt) > 0 then
                ctx.B = lui_format_tokenized(bubble_fmt_tokens, { b = ctx.b })
            end

            m.morale_label:SetText(lui_format_tokenized(morale_fmt_tokens, ctx))

            m.power_border:SetPosition(0, power_y)
            m.power_border:SetSize(frame_w, power_h)
            m.power_border:SetBackColor(border_color)

            local inner_power_h = power_h - (2 * border)
            if inner_power_h < 1 then inner_power_h = 1 end

            m.power_background:SetPosition(border, border)
            m.power_background:SetSize(inner_w, inner_power_h)

            m.power_bar:SetPosition(0, 0)
            m.power_bar:SetSize(inner_w, inner_power_h)

            local power_percent = 0.66 - ((i - 1) * 0.08)
            if power_percent < 0.08 then power_percent = 0.08 end
            if i == 1 then
                power_percent = 1.0
            end
            local power_fill_w = math.floor((inner_w * power_percent) + 0.5)
            if power_fill_w < 0 then power_fill_w = 0 end
            if power_fill_w > inner_w then power_fill_w = inner_w end

            m.power_bar:SetWidth(power_fill_w)
            local power_fill_color = (i % 3) == 0 and wrath_color or power_color
            m.power_bar:SetBackColor(power_fill_color)
            m.power_background:SetBackColor(resource_background(power_fill_color))

            if power_align_text == LUI_ENUMS.text_alignment.LEFT then
                m.power_label:SetPosition(power_margin, 0)
                m.power_label:SetSize(frame_w - power_margin, power_h)
            elseif power_align_text == LUI_ENUMS.text_alignment.RIGHT then
                m.power_label:SetPosition(0, 0)
                m.power_label:SetSize(frame_w - power_margin, power_h)
            else
                m.power_label:SetPosition(0, 0)
                m.power_label:SetSize(frame_w, power_h)
            end
            m.power_label:SetFont(power_font)
            m.power_label:SetFontStyle(power_font_style)
            m.power_label:SetForeColor(power_font_color)
            m.power_label:SetOutlineColor(power_outline_color)
            m.power_label:SetTextAlignment(text_align(power_align_text))

            local power_max = 30000
            local power_cur = math.floor(power_max * power_percent + 0.5)
            local power_pct_text = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"
            m.power_label:SetText(lui_format_tokenized(power_fmt_tokens, {
                c = lui_abbrev_number(power_cur),
                t = lui_abbrev_number(power_max),
                p = power_pct_text,
                name = TR("Player ") .. tostring(i),
                level = "150",
            }))
        end
    end

    lui_clear_number_abbrev_preview_settings()
end

function ConfigWindow:hook_expiring_effects_preview_events()
    if self._expiring_effects_preview_events_hooked == true then
        return
    end
    self._expiring_effects_preview_events_hooked = true

    local function hook_checkbox(key)
        local cb = self.controls[key] and self.controls[key].cb or nil
        if cb == nil then
            return
        end
        local prev = cb.CheckedChanged
        cb.CheckedChanged = function(...)
            if prev ~= nil then
                prev(...)
            end
            if self.loading == true then
                return
            end
            self:layout()
            self:update_expiring_effects_preview()
        end
    end

    local function hook_text(key)
        local c = self.controls[key]
        if c == nil or c.tb == nil then
            return
        end
        local prev = c.tb.TextChanged
        c.tb.TextChanged = function(...)
            if prev ~= nil then
                prev(...)
            end
            if self.loading == true then
                return
            end
            self:update_expiring_effects_preview()
        end
    end

    local function hook_dropdown(key)
        local c = self.controls[key]
        if c == nil then
            return
        end
        local prev = c.on_changed
        c.on_changed = function(value)
            if prev ~= nil then
                prev(value)
            end
            if self.loading == true then
                return
            end
            self:update_expiring_effects_preview()
        end
    end

    hook_text("scale")
    hook_text("expiring_effects_background_color")
    hook_text("expiring_effects_border_width")
    hook_text("expiring_effects_border_color")

    hook_text("expiring_effects_threshold")
    hook_text("expiring_effects_bar_width")
    hook_text("expiring_effects_bar_height")
    hook_text("expiring_effects_bar_color")
    hook_text("expiring_effects_debuff_curable_bar_color")
    hook_text("expiring_effects_debuff_noncurable_bar_color")
    hook_text("expiring_effects_font_size")
    hook_text("expiring_effects_font_color")
    hook_text("expiring_effects_font_outline_color")
    hook_text("expiring_effects_text_template")
    hook_text("expiring_effects_name_max_chars")

    hook_dropdown("expiring_effects_font_name")
    hook_dropdown("expiring_effects_font_style")
    hook_dropdown("expiring_effects_icon_side")
    hook_dropdown("expiring_effects_bar_expire_towards")
    hook_dropdown("expiring_effects_text_alignment")

    hook_checkbox("expiring_effects_enabled")
    hook_checkbox("expiring_effects_show_buffs")
    hook_checkbox("expiring_effects_show_curable_debuffs")
    hook_checkbox("expiring_effects_show_noncurable_debuffs")
end

function ConfigWindow:hook_expiring_target_effects_preview_events()
    if self._expiring_target_effects_preview_events_hooked == true then
        return
    end
    self._expiring_target_effects_preview_events_hooked = true

    local function hook_checkbox(key)
        local cb = self.controls[key] and self.controls[key].cb or nil
        if cb == nil then
            return
        end
        local prev = cb.CheckedChanged
        cb.CheckedChanged = function(...)
            if prev ~= nil then
                prev(...)
            end
            if self.loading == true then
                return
            end
            self:layout()
            self:update_expiring_target_effects_preview()
        end
    end

    local function hook_text(key)
        local c = self.controls[key]
        if c == nil or c.tb == nil then
            return
        end
        local prev = c.tb.TextChanged
        c.tb.TextChanged = function(...)
            if prev ~= nil then
                prev(...)
            end
            if self.loading == true then
                return
            end
            self:update_expiring_target_effects_preview()
        end
    end

    local function hook_dropdown(key)
        local c = self.controls[key]
        if c == nil then
            return
        end
        local prev = c.on_changed
        c.on_changed = function(value)
            if prev ~= nil then
                prev(value)
            end
            if self.loading == true then
                return
            end
            self:update_expiring_target_effects_preview()
        end
    end

    hook_text("scale")
    hook_text("expiring_target_effects_background_color")
    hook_text("expiring_target_effects_border_width")
    hook_text("expiring_target_effects_border_color")

    hook_text("expiring_target_effects_threshold")
    hook_text("expiring_target_effects_bar_width")
    hook_text("expiring_target_effects_bar_height")
    hook_text("expiring_target_effects_bar_color")
    hook_text("expiring_target_effects_debuff_noncurable_bar_color")
    hook_text("expiring_target_effects_buff_bar_color")
    hook_text("expiring_target_effects_font_size")
    hook_text("expiring_target_effects_font_color")
    hook_text("expiring_target_effects_font_outline_color")
    hook_text("expiring_target_effects_text_template")
    hook_text("expiring_target_effects_name_max_chars")

    hook_dropdown("expiring_target_effects_font_name")
    hook_dropdown("expiring_target_effects_font_style")
    hook_dropdown("expiring_target_effects_icon_side")
    hook_dropdown("expiring_target_effects_bar_expire_towards")
    hook_dropdown("expiring_target_effects_text_alignment")

    hook_checkbox("expiring_target_effects_enabled")
    hook_checkbox("expiring_target_effects_show_buffs")
    hook_checkbox("expiring_target_effects_show_curable_debuffs")
    hook_checkbox("expiring_target_effects_show_noncurable_debuffs")
end

function ConfigWindow:layout()
    local window_width, window_height = self:GetSize()
    local button_gap = _scaled_int(7)
    local min_content_h = _scaled_int(59)
    local min_left_w = _scaled_int(67)
    local min_main_remainder = _scaled_int(89)
    local min_content_w = _scaled_int(104)
    local desired_tab_width = _scaled_int(104)
    local scroll_w = _scaled_int(12)
    local content_gap = _scaled_int(7)
    local title_h = _scaled_int(22)
    local title_gap = _scaled_int(24)
    local hr_top = _scaled_int(3)
    local hr_gap = _scaled_int(6)
    local custom_default_h = _scaled_int(44)
    local custom_min_h = _scaled_int(7)
    local custom_gap = _scaled_int(4)
    local form_pad = _scaled_int(4)

    local button_bar_width = window_width - self.margin_left - self.margin_right
    self.button_bar:SetPosition(self.margin_left, window_height - self.margin_bottom - self.button_bar_height)
    self.button_bar:SetSize(button_bar_width, self.button_bar_height)

    local button_width = _scaled_int(81)
    local button_height = self.button_bar_height

    self.cancel_button:SetSize(button_width, button_height)
    self.apply_button:SetSize(button_width, button_height)
    self.save_button:SetSize(button_width, button_height)
    self.move_ui_button:SetSize(button_width, button_height)

    self.save_button:SetPosition(button_bar_width - button_width, 0)
    self.apply_button:SetPosition(button_bar_width - (2 * button_width) - button_gap, 0)
    self.cancel_button:SetPosition(0, 0)
    self.move_ui_button:SetPosition(button_width + button_gap, 0)

    local content_height = window_height - self.margin_top - self.margin_bottom - self.button_bar_height - content_gap
    if content_height < min_content_h then content_height = min_content_h end

    local left_w = self.main_tab_bar_width
    if left_w < min_left_w then left_w = min_left_w end
    if left_w > (button_bar_width - min_main_remainder) then
        left_w = math.max(min_left_w, button_bar_width - min_main_remainder)
    end

    self.main_tab_bar:SetPosition(self.margin_left, self.margin_top)
    self.main_tab_bar:SetSize(left_w, content_height)

    local sep_x = self.margin_left + left_w + math.floor(self.main_tab_bar_gap / 2)
    self.main_tab_separator:SetPosition(sep_x, self.margin_top)
    self.main_tab_separator:SetSize(_scaled_int(1), content_height)

    local main_count = #self.main_tabs
    for i = 1, main_count do
        local t = self.main_tabs[i]
        local b = self.main_tab_buttons[t.key]
        if b ~= nil then
            b:SetPosition(0, (i - 1) * (self.main_tab_button_height + self.main_tab_button_gap))
            b:SetSize(left_w, self.main_tab_button_height)
        end
    end

    local content_left = self.margin_left + left_w + self.main_tab_bar_gap
    local content_width = window_width - content_left - self.margin_right
    if content_width < min_content_w then content_width = min_content_w end

    local sub_list = self._visible_sub_tabs
    local show_sub = sub_list ~= nil and #sub_list > 1
    local sub_height = show_sub and self.tab_bar_height or 0

    self.tab_bar:SetPosition(content_left, self.margin_top)
    self.tab_bar:SetSize(content_width, self.tab_bar_height)
    self.tab_bar:SetVisible(show_sub)

    if show_sub and sub_list ~= nil then
        local tab_count = #sub_list
        local tab_width = desired_tab_width
        if (tab_width * tab_count) + ((tab_count - 1) * self.tab_bar_gap) > content_width then
            tab_width = math.floor((content_width - ((tab_count - 1) * self.tab_bar_gap)) / tab_count)
        end
        for i = 1, tab_count do
            local t = sub_list[i]
            local b = self.sub_tab_buttons[t.key]
            if b ~= nil and b:IsVisible() then
                b:SetPosition((i - 1) * (tab_width + self.tab_bar_gap), 0)
                b:SetSize(tab_width, self.tab_bar_height)
            end
        end
    end

    local scroll_top = self.margin_top + sub_height
    if show_sub then
        scroll_top = scroll_top + content_gap
    end

    local scroll_height = window_height - scroll_top - self.margin_bottom - self.button_bar_height - content_gap
    if scroll_height < _scaled_int(30) then
        scroll_height = _scaled_int(30)
    end

    self.scroll:SetPosition(content_left, scroll_top)
    self.scroll:SetSize(content_width - scroll_w - self.scroll_bar_gap, scroll_height)

    self.scroll_bar:SetPosition(content_left + self.scroll:GetWidth() + self.scroll_bar_gap, scroll_top)
    self.scroll_bar:SetSize(scroll_w, scroll_height)

    local form_width = self.scroll:GetWidth()
    local inner_width = form_width - (2 * self.content_padding)
    if inner_width < _scaled_int(74) then
        inner_width = _scaled_int(74)
    end

    local col_width = math.floor((inner_width - self.col_gap) / 2)
    local label_width = math.floor(col_width * 0.55)
    local base_input_width = col_width - label_width - self.inner_gap
    local input_width = base_input_width

    local y = form_pad
    local col = 0

    local fields = self.fields or {}
    for i = 1, #fields do
        local field = fields[i]
        local is_visible = true
        if field.visible_if ~= nil and field.visible_if() == false then
            is_visible = false
        end

        if field.kind == "title" then
            field.label:SetVisible(is_visible)
        elseif field.kind == "info" then
            field.label:SetVisible(is_visible)
        elseif field.kind == "hr" then
            field.line:SetVisible(is_visible)
        elseif field.kind == "break" then
            field.spacer:SetVisible(is_visible)
        elseif field.kind == "custom" then
            field.control:SetVisible(is_visible)
        elseif field.kind == "text" then
            field.label:SetVisible(is_visible)
            field.tb:SetVisible(is_visible)
        elseif field.kind == "dropdown" then
            field.label:SetVisible(is_visible)
            field.button:SetVisible(is_visible)
        elseif field.kind == "checkbox" then
            field.cb:SetVisible(is_visible)
        end

        if is_visible and field.kind == "title" then
            if col == 1 then
                y = y + self.row_height
                col = 0
            end

            field.label:SetPosition(self.content_padding, y)
            field.label:SetSize(inner_width, title_h)
            y = y + title_gap
            col = 0
        elseif is_visible and field.kind == "info" then
            if col == 1 then
                y = y + self.row_height
                col = 0
            end

            local h = field.height or self.row_height
            field.label:SetPosition(self.content_padding, y)
            field.label:SetSize(inner_width, h)
            y = y + h
            col = 0
        elseif is_visible and field.kind == "hr" then
            if col == 1 then
                y = y + self.row_height
                col = 0
            end

            field.line:SetPosition(self.content_padding, y + hr_top)
            field.line:SetSize(inner_width, 1)
            y = y + hr_gap
            col = 0
        elseif is_visible and field.kind == "break" then
            if col == 1 then
                y = y + self.row_height
                col = 0
            end

            field.spacer:SetPosition(self.content_padding, y)
            field.spacer:SetSize(inner_width, field.height)
            y = y + field.height
            col = 0
        elseif is_visible and field.kind == "custom" then
            if col == 1 then
                y = y + self.row_height
                col = 0
            end

            local h = field.height or custom_default_h
            if type(h) ~= "number" then
                h = custom_default_h
            end
            if h < custom_min_h then
                h = custom_min_h
            end

            field.control:SetPosition(self.content_padding, y)
            field.control:SetSize(inner_width, h)
            y = y + h + custom_gap
            col = 0
        elseif is_visible then
            if field.kind == "checkbox" and field.full_width == true then
                if col == 1 then
                    y = y + self.row_height
                    col = 0
                end

                field.cb:SetPosition(self.content_padding, y)
                field.cb:SetSize(inner_width, self.field_label_height)
                y = y + self.row_height
                col = 0
            elseif (field.kind == "text" or field.kind == "dropdown") and field.full_width == true then
                if col == 1 then
                    y = y + self.row_height
                    col = 0
                end

                local label_width_full = label_width
                local input_start_x = self.content_padding + label_width_full + self.inner_gap
                local input_right_x = self.content_padding + (col_width + self.col_gap) + label_width + self.inner_gap +
                    input_width
                local input_width_full = input_right_x - input_start_x
                if input_width_full < _scaled_int(59) then
                    input_width_full = _scaled_int(59)
                end

                field.label:SetPosition(self.content_padding, y)
                field.label:SetSize(label_width_full, self.field_label_height)

                local input_y = y + math.floor((self.field_label_height - self.input_height) / 2)
                if field.kind == "text" then
                    field.tb:SetPosition(input_start_x, input_y)
                    field.tb:SetSize(input_width_full, self.input_height)
                else
                    field.button:SetPosition(input_start_x, input_y + self.dropdown_y_offset)
                    field.button:SetSize(input_width_full, self.input_height)
                end

                y = y + self.row_height
                col = 0
            else
                local x = self.content_padding + (col * (col_width + self.col_gap))

                if field.kind == "text" then
                    field.label:SetPosition(x, y)
                    field.label:SetSize(label_width, self.field_label_height)

                    local input_y = y + math.floor((self.field_label_height - self.input_height) / 2)
                    field.tb:SetPosition(x + label_width + self.inner_gap, input_y)
                    field.tb:SetSize(input_width, self.input_height)
                elseif field.kind == "dropdown" then
                    field.label:SetPosition(x, y)
                    field.label:SetSize(label_width, self.field_label_height)

                    local input_y = y + math.floor((self.field_label_height - self.input_height) / 2)
                    field.button:SetPosition(x + label_width + self.inner_gap, input_y + self.dropdown_y_offset)
                    field.button:SetSize(input_width, self.input_height)
                else
                    field.cb:SetPosition(x, y)
                    field.cb:SetSize(col_width, self.field_label_height)
                end

                if col == 0 then
                    col = 1
                else
                    y = y + self.row_height
                    col = 0
                end
            end
        end
    end

    if col == 1 then
        y = y + self.row_height
    end

    self.form:SetSize(form_width, y + form_pad)

    if self.confirm_overlay ~= nil then
        self.confirm_overlay:SetPosition(0, 0)
        self.confirm_overlay:SetSize(window_width, window_height)

        local dialog_width = _scaled_int(CONFIRM_DIALOG_W)
        local dialog_height = _scaled_int(CONFIRM_DIALOG_H)
        if dialog_width > window_width - (2 * self.margin_left) then
            dialog_width = window_width - (2 * self.margin_left)
        end
        if dialog_height > window_height - (2 * self.margin_top) then
            dialog_height = window_height - (2 * self.margin_top)
        end
        if dialog_width < _scaled_int(148) then
            dialog_width = _scaled_int(148)
        end
        if dialog_height < _scaled_int(89) then
            dialog_height = _scaled_int(89)
        end

        self.confirm_dialog:SetSize(dialog_width, dialog_height)
        self.confirm_dialog:SetPosition(
            math.floor((window_width - dialog_width) / 2),
            math.floor((window_height - dialog_height) / 2)
        )

        local padding = _scaled_int(CONFIRM_DIALOG_PADDING)
        local confirm_button_gap = _scaled_int(CONFIRM_DIALOG_BUTTON_GAP)
        local confirm_button_width = _scaled_int(81)
        local confirm_button_height = _scaled_int(22)
        local label_height = dialog_height - (padding * 2) - confirm_button_height - confirm_button_gap
        if label_height < _scaled_int(30) then
            label_height = _scaled_int(30)
        end

        self.confirm_dialog_label:SetPosition(padding, padding)
        self.confirm_dialog_label:SetSize(dialog_width - (padding * 2), label_height)

        self.confirm_cancel_button:SetSize(confirm_button_width, confirm_button_height)
        self.confirm_confirm_button:SetSize(confirm_button_width, confirm_button_height)
        self.confirm_confirm_button:SetPosition(dialog_width - padding - confirm_button_width,
            dialog_height - padding - confirm_button_height)
        self.confirm_cancel_button:SetPosition(
            self.confirm_confirm_button:GetLeft() - confirm_button_gap - confirm_button_width,
            self.confirm_confirm_button:GetTop()
        )
    end
end

function ConfigWindow:load_from_settings()
    self:load_from_settings_v2()
end

function ConfigWindow:load_from_settings_v2()
    if _G.loaded_settings == nil then
        return
    end

    self.loading = true

    local s = _G.loaded_settings

    if self._tab_modules ~= nil then
        for i = 1, #self._tab_modules do
            local m = self._tab_modules[i]
            if m ~= nil and m.load ~= nil then
                m.load(self, s, self._ui)
            end
        end
    end

    self:update_all_swatches()

    self.loading = false
    self:update_expiring_effects_preview()
end

function ConfigWindow:apply_changes(close_after)
    self:apply_changes_v2(close_after)
end

function ConfigWindow:refresh_runtime_settings()
    fix_colors()
    rebuild_settings()
    apply_inventory_settings()
    apply_assets_settings()
    apply_status_bar_settings()
    apply_cooldowns_settings()

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
    if PLAYER_VITAL ~= nil and PLAYER_VITAL.on_target_changed ~= nil then
        PLAYER_VITAL:on_target_changed()
    end

    if self.active_tab == "expiring_effects" then
        self:update_expiring_effects_preview()
    elseif self.active_tab == "expiring_target_effects" then
        self:update_expiring_target_effects_preview()
    elseif self.active_tab == "party_vitals" then
        self:update_party_vitals_preview()
    elseif self.active_tab == "self_vitals" then
        self:update_self_vitals_preview()
    elseif self.active_tab == "target_vitals" then
        self:update_target_vitals_preview()
    elseif self.active_tab == "target_boss_vitals" then
        self:update_target_boss_vitals_preview()
    elseif self.active_tab == "target_targets_target" then
        self:update_target_targets_target_preview()
    elseif self.active_tab == "cooldowns" then
        self:update_cooldowns_preview()
    end
end

function ConfigWindow:apply_changes_v2(close_after)
    if _G.loaded_settings == nil then
        return
    end

    local s = _G.loaded_settings

    if self._tab_modules ~= nil then
        for i = 1, #self._tab_modules do
            local m = self._tab_modules[i]
            if m ~= nil and m.apply ~= nil then
                m.apply(self, s, self._ui)
            end
        end
    end

    self:refresh_runtime_settings()

    self:update_saved_geometry()
    save_settings()

    if close_after then
        self:SetVisible(false)
    end
end

function ConfigWindow:use_selected_profile()
    local profile_control = self.controls.profile_manager_profile
    if profile_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil or profile_id == _G.current_profile_id then
        return
    end

    if assign_character_profile(profile_id) ~= true then
        return
    end

    ensure_loaded_settings()
    self:refresh_runtime_settings()
    self:update_saved_geometry()
    save_settings()
    self.profile_manager_selected_profile_id = profile_id
    self:load_from_settings()
end

function ConfigWindow:rename_selected_profile()
    local profile_control = self.controls.profile_manager_profile
    local name_control = self.controls.profile_manager_name
    if profile_control == nil or name_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil then
        return
    end

    if rename_configuration(profile_id, name_control.tb:GetText()) ~= true then
        return
    end

    self.profile_manager_selected_profile_id = profile_id
    self:update_saved_geometry()
    save_settings()
    self:load_from_settings()
end

function ConfigWindow:confirm_delete_selected_profile()
    local profile_control = self.controls.profile_manager_profile
    if profile_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil or get_configuration_count() <= 1 then
        return
    end

    local profile_name = get_configuration_name(profile_id) or TR("Profile")
    local message = table.concat({
        string.format(TR("Delete profile '%s'?"), profile_name),
        TR("This will delete it for all characters using it."),
        TR("This action cannot be undone."),
    }, "\n")

    self:show_confirmation_dialog(message, TR("Delete"), function()
        local deleting_current_profile = profile_id == _G.current_profile_id
        if delete_configuration(profile_id) ~= true then
            return
        end

        if deleting_current_profile == true then
            local fallback_profile_id = get_first_configuration_id()
            if fallback_profile_id ~= nil then
                assign_character_profile(fallback_profile_id)
                ensure_loaded_settings()
                self:refresh_runtime_settings()
                self.profile_manager_selected_profile_id = fallback_profile_id
            end
        else
            self.profile_manager_selected_profile_id = _G.current_profile_id
        end

        self:update_saved_geometry()
        save_settings()
        self:load_from_settings()
    end)
end

function ConfigWindow:create_profile_from_current()
    if _G.current_profile_id == nil then
        return
    end

    local duplicate_profile_id = duplicate_configuration(_G.current_profile_id)
    if duplicate_profile_id == nil then
        return
    end

    if assign_character_profile(duplicate_profile_id) ~= true then
        return
    end

    ensure_loaded_settings()
    self:refresh_runtime_settings()
    self.profile_manager_selected_profile_id = duplicate_profile_id
    self:update_saved_geometry()
    save_settings()
    self:load_from_settings()
end

function ConfigWindow:start_new_profile_quick_setup()
    self:hide_confirmation_dialog()
    self:SetVisible(false)

    FIRST_RUN_QUICK_SETUP_WINDOW = UI.Settings.FirstRunQuickSetup({
        skip_existing_configurations = true,
        create_profile_on_finish = true,
    })
    FIRST_RUN_QUICK_SETUP_WINDOW:open()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function ConfigWindow:_init_vitals_preview(holder_key, include_targets_target)
    local holder = self.controls[holder_key]
    if holder == nil or holder.control == nil then
        return nil
    end

    local state_key = include_targets_target and "target_vitals_preview" or "self_vitals_preview"
    if self[state_key] ~= nil then
        return self[state_key]
    end

    local p = {}
    self[state_key] = p

    p.container = holder.control
    p.container:SetMouseVisible(false)

    p.outer = Turbine.UI.Control()
    p.outer:SetParent(p.container)
    p.outer:SetMouseVisible(false)

    p.info_label = Turbine.UI.Label()
    p.info_label:SetParent(p.container)
    p.info_label:SetMouseVisible(false)
    p.info_label:SetMultiline(true)
    p.info_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.outer)
    p.root:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.outer)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_top:SetVisible(false)

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.outer)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_bottom:SetVisible(false)

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.outer)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_left:SetVisible(false)

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.outer)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_right:SetVisible(false)

    p.effects_debuffs = Turbine.UI.Control()
    p.effects_debuffs:SetParent(p.root)
    p.effects_debuffs:SetMouseVisible(false)
    -- Pale red background for debuffs area.
    p.effects_debuffs:SetBackColor(Turbine.UI.Color(0.32, 0.14, 0.14))

    p.effects_debuffs_label = Turbine.UI.Label()
    p.effects_debuffs_label:SetParent(p.effects_debuffs)
    p.effects_debuffs_label:SetMouseVisible(false)
    p.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    p.debuff_icons = {}
    for i = 1, 2 do
        local icon = {}

        icon.root = Turbine.UI.Control()
        icon.root:SetParent(p.effects_debuffs)
        icon.root:SetMouseVisible(false)
        icon.root:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))

        icon.inner = Turbine.UI.Control()
        icon.inner:SetParent(icon.root)
        icon.inner:SetMouseVisible(false)
        icon.inner:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        icon.timer = Turbine.UI.Label()
        icon.timer:SetParent(icon.root)
        icon.timer:SetMouseVisible(false)
        icon.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        icon.timer:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
        icon.timer:SetOutlineColor(Turbine.UI.Color(0, 0, 0, 1))
        icon.timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

        p.debuff_icons[i] = icon
    end

    p.effects_buffs = Turbine.UI.Control()
    p.effects_buffs:SetParent(p.root)
    p.effects_buffs:SetMouseVisible(false)
    -- Pale blue background for buffs area.
    p.effects_buffs:SetBackColor(Turbine.UI.Color(0.14, 0.18, 0.32))

    p.effects_buffs_label = Turbine.UI.Label()
    p.effects_buffs_label:SetParent(p.effects_buffs)
    p.effects_buffs_label:SetMouseVisible(false)
    p.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    p.buff_icons = {}
    for i = 1, 2 do
        local icon = {}

        icon.root = Turbine.UI.Control()
        icon.root:SetParent(p.effects_buffs)
        icon.root:SetMouseVisible(false)
        icon.root:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))

        icon.inner = Turbine.UI.Control()
        icon.inner:SetParent(icon.root)
        icon.inner:SetMouseVisible(false)
        icon.inner:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        icon.timer = Turbine.UI.Label()
        icon.timer:SetParent(icon.root)
        icon.timer:SetMouseVisible(false)
        icon.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        icon.timer:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
        icon.timer:SetOutlineColor(Turbine.UI.Color(0, 0, 0, 1))
        icon.timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

        p.buff_icons[i] = icon
    end

    p.morale_border = Turbine.UI.Control()
    p.morale_border:SetParent(p.root)
    p.morale_border:SetMouseVisible(false)

    p.morale_background = Turbine.UI.Control()
    p.morale_background:SetParent(p.morale_border)
    p.morale_background:SetMouseVisible(false)

    p.morale_bar = Turbine.UI.Control()
    p.morale_bar:SetParent(p.morale_background)
    p.morale_bar:SetMouseVisible(false)
    p.morale_bar:SetZOrder(1)

    p.bubble_bar = Turbine.UI.Control()
    p.bubble_bar:SetParent(p.morale_background)
    p.bubble_bar:SetMouseVisible(false)
    p.bubble_bar:SetZOrder(2)

    p.morale_label = Turbine.UI.Label()
    p.morale_label:SetParent(p.morale_border)
    p.morale_label:SetMouseVisible(false)
    p.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    p.morale_label:SetZOrder(10)

    p.power_border = Turbine.UI.Control()
    p.power_border:SetParent(p.root)
    p.power_border:SetMouseVisible(false)

    p.power_background = Turbine.UI.Control()
    p.power_background:SetParent(p.power_border)
    p.power_background:SetMouseVisible(false)

    p.power_bar = Turbine.UI.Control()
    p.power_bar:SetParent(p.power_background)
    p.power_bar:SetMouseVisible(false)

    p.power_label = Turbine.UI.Label()
    p.power_label:SetParent(p.power_border)
    p.power_label:SetMouseVisible(false)
    p.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    p.include_targets_target = include_targets_target == true
    if p.include_targets_target then
        p.targets_target_background = Turbine.UI.Control()
        p.targets_target_background:SetParent(p.root)
        p.targets_target_background:SetMouseVisible(false)

        p.targets_target_bar = Turbine.UI.Control()
        p.targets_target_bar:SetParent(p.targets_target_background)
        p.targets_target_bar:SetMouseVisible(false)
        p.targets_target_bar:SetZOrder(1)

        p.targets_target_bubble = Turbine.UI.Control()
        p.targets_target_bubble:SetParent(p.targets_target_background)
        p.targets_target_bubble:SetMouseVisible(false)
        p.targets_target_bubble:SetZOrder(2)
        p.targets_target_bubble:SetVisible(false)

        p.targets_target_label = Turbine.UI.Label()
        p.targets_target_label:SetParent(p.targets_target_background)
        p.targets_target_label:SetMouseVisible(false)
        p.targets_target_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        p.targets_target_label:SetZOrder(10)
    end

    return p
end

function ConfigWindow:_update_vitals_preview(kind)
    local is_target = kind == "target"
    local active_key = is_target and "target_vitals" or "self_vitals"
    if self.active_tab ~= active_key then
        return
    end

    local p = is_target and self.target_vitals_preview or self.self_vitals_preview
    if p == nil then
        if is_target then
            self:init_target_vitals_preview()
            p = self.target_vitals_preview
        else
            self:init_self_vitals_preview()
            p = self.self_vitals_preview
        end
    end
    if p == nil then
        return
    end

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return n * raw_scale
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    local prefix = is_target and "target" or "self"

    local raw_frame_w = tonumber(self.controls[prefix .. "_width"].tb:GetText()) or 250
    local raw_border = tonumber(self.controls[prefix .. "_border_width"].tb:GetText()) or 1
    local frame_w = scaled_int(raw_frame_w, 250)
    local border = scaled_border(raw_border, 1)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_morale_h = tonumber(self.controls[prefix .. "_morale_height"].tb:GetText()) or 50
    local raw_power_h = tonumber(self.controls[prefix .. "_power_height"].tb:GetText()) or 26
    local morale_h = scaled_int(raw_morale_h, 50)
    local power_h = scaled_int(raw_power_h, 26)
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end

    local raw_effects_h = tonumber(self.controls[prefix .. "_effects_height"].tb:GetText()) or 200
    local effects_height = scaled_int(raw_effects_h, 200)
    local effects_half = effects_height / 2

    local raw_effects_position = self.controls[prefix .. "_effects_position"]:get_value()
    raw_effects_position = tonumber(raw_effects_position) or LUI_ENUMS.vitals_effects_position.ABOVE
    local effects_below = raw_effects_position == LUI_ENUMS.vitals_effects_position.BELOW

    local raw_buff_size = tonumber(self.controls[prefix .. "_buff_size"].tb:GetText()) or 32
    local raw_debuff_size = tonumber(self.controls[prefix .. "_debuff_size"].tb:GetText()) or 36
    local buff_icon = scaled_int(raw_buff_size, 32)
    local debuff_icon = scaled_int(raw_debuff_size, 36)
    if buff_icon < 1 then buff_icon = 1 end
    if debuff_icon < 1 then debuff_icon = 1 end

    local buff_cols = math.floor(frame_w / buff_icon)
    if buff_cols < 1 then buff_cols = 1 end
    local debuff_cols = math.floor(frame_w / debuff_icon)
    if debuff_cols < 1 then debuff_cols = 1 end

    local buff_rows = math.floor(effects_half / buff_icon)
    if buff_rows < 1 then buff_rows = 1 end
    local debuff_rows = math.floor(effects_half / debuff_icon)
    if debuff_rows < 1 then debuff_rows = 1 end

    local max_buffs = buff_cols * buff_rows
    local max_debuffs = debuff_cols * debuff_rows

    local label_font = self.field_label_font
    local info_h = _scaled_int(46)
    local preview_border = 1
    local root_inner_h = effects_height + morale_h + power_h - border
    if root_inner_h < 1 then root_inner_h = 1 end
    local desired_h_inner = info_h + root_inner_h + _scaled_int(9)
    local desired_h = desired_h_inner + (2 * preview_border)
    local holder = self.controls[is_target and "target_vitals_preview" or "self_vitals_preview"]
    if holder ~= nil and holder.height ~= desired_h then
        holder.height = desired_h
        self:layout()
    end

    local cw, ch = p.container:GetSize()
    local root_outer_h = root_inner_h + (2 * preview_border)
    local outer_w = frame_w + (2 * preview_border)
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = _scaled_int(4)
    if y < 0 then y = 0 end

    if p.info_label ~= nil then
        local info_w = cw
        if info_w == nil or info_w < 1 then
            info_w = frame_w
        end
        local info_font = _scaled_font(LUI_ENUMS.font_name.VERDANA, 13)
        p.info_label:SetPosition(0, y)
        p.info_label:SetSize(info_w, info_h)
        p.info_label:SetFont(info_font)
        p.info_label:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.85))
        p.info_label:SetText(TR(
            "Buffs area auto-resizes to the number of rows, up to the max height. Debuffs fill the remaining effects height. Effects can be placed above Morale or below Power."))
    end

    y = y + info_h
    p.outer:SetPosition(x, y)
    p.outer:SetSize(outer_w, root_outer_h)
    p.root:SetPosition(preview_border, preview_border)
    p.root:SetSize(frame_w, root_inner_h)
    _apply_preview_border(p, outer_w, root_outer_h)

    local reverse_fill = effects_below ~= true
    local effects_top = 0
    local morale_top = effects_height
    if effects_below == true then
        morale_top = 0
    end
    local power_top = morale_top + morale_h - border
    if effects_below == true then
        effects_top = power_top + power_h
    end

    local buff_area_h = effects_half
    local debuff_area_h = effects_half

    if effects_below == true then
        p.effects_buffs:SetPosition(0, effects_top)
        p.effects_buffs:SetSize(frame_w, buff_area_h)
        p.effects_debuffs:SetPosition(0, effects_top + buff_area_h)
        p.effects_debuffs:SetSize(frame_w, debuff_area_h)
    else
        p.effects_debuffs:SetPosition(0, effects_top)
        p.effects_debuffs:SetSize(frame_w, debuff_area_h)
        p.effects_buffs:SetPosition(0, effects_top + debuff_area_h)
        p.effects_buffs:SetSize(frame_w, buff_area_h)
    end

    local debuff_label_h = 16
    if debuff_label_h > debuff_area_h then
        debuff_label_h = debuff_area_h
    end
    local buff_label_h = 16
    if buff_label_h > buff_area_h then
        buff_label_h = buff_area_h
    end

    p.effects_debuffs_label:SetFont(label_font)
    p.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    p.effects_debuffs_label:SetPosition(0, 0)
    p.effects_debuffs_label:SetSize(frame_w, debuff_label_h)
    p.effects_debuffs_label:SetText(string.format(TR("Debuffs: max %d (%dx%d)"), max_debuffs, debuff_cols, debuff_rows))

    p.effects_buffs_label:SetFont(label_font)
    p.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    p.effects_buffs_label:SetPosition(0, 0)
    p.effects_buffs_label:SetSize(frame_w, buff_label_h)
    p.effects_buffs_label:SetText(string.format(TR("Buffs: max %d (%dx%d)"), max_buffs, buff_cols, buff_rows))

    local function _timer_text(time_left)
        local t = tonumber(time_left)
        if t == nil then return "" end
        if t < 0 then
            return ""
        end
        if t < 9 then
            return lui_format_timeout(t)
        end
        return ""
    end

    local function _timer_style(style_enum)
        return LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local buff_timer_font_name = self.controls[prefix .. "_buff_timer_font_name"]:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_buff_timer_font_size = tonumber(self.controls[prefix .. "_buff_timer_font_size"].tb:GetText()) or 12
    local buff_timer_font_size = scaled_number(raw_buff_timer_font_size, 12)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style_enum = self.controls[prefix .. "_buff_timer_font_style"]:get_value() or
        LUI_ENUMS.font_style.OUTLINE
    local buff_timer_style = _timer_style(buff_timer_style_enum)
    local buff_timer_color = _hex_to_color(self.controls[prefix .. "_buff_timer_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local buff_timer_outline = _hex_to_color(self.controls[prefix .. "_buff_timer_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local debuff_timer_font_name = self.controls[prefix .. "_debuff_timer_font_name"]:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_debuff_timer_font_size = tonumber(self.controls[prefix .. "_debuff_timer_font_size"].tb:GetText()) or 25
    local debuff_timer_font_size = scaled_number(raw_debuff_timer_font_size, 25)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style_enum = self.controls[prefix .. "_debuff_timer_font_style"]:get_value() or
        LUI_ENUMS.font_style.OUTLINE
    local debuff_timer_style = _timer_style(debuff_timer_style_enum)
    local debuff_timer_color = _hex_to_color(self.controls[prefix .. "_debuff_timer_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local debuff_timer_outline = _hex_to_color(self.controls[prefix .. "_debuff_timer_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local function layout_icons(icons, area_w, area_h, icon_size, cols, times, font, style, color, outline,
                                reverse_fill_enabled)
        if icons == nil then
            return
        end
        local columns = cols
        if columns < 1 then columns = 1 end
        for i = 1, #icons do
            local icon = icons[i]
            if icon ~= nil and icon.root ~= nil and icon.timer ~= nil then
                local size = icon_size
                if size > area_h then
                    size = area_h
                end
                if size < 1 then
                    size = 1
                end

                local idx = i - 1
                local x = 0
                local y = 0
                if reverse_fill_enabled == true then
                    -- Reverse fill: bottom-right to top-left.
                    local col_from_right = idx % columns
                    local row_from_bottom = math.floor(idx / columns)
                    x = area_w - ((col_from_right + 1) * size)
                    y = area_h - ((row_from_bottom + 1) * size)
                else
                    -- Normal fill: top-left to bottom-right.
                    local col = idx % columns
                    local row = math.floor(idx / columns)
                    x = col * size
                    y = row * size
                end
                if x < 0 then x = 0 end
                if y < 0 then y = 0 end

                icon.root:SetPosition(x, y)
                icon.root:SetSize(size, size)

                local preview_border = 1
                local inner_size = size - (2 * preview_border)
                if inner_size < 1 then inner_size = 1 end
                if icon.inner ~= nil then
                    icon.inner:SetPosition(preview_border, preview_border)
                    icon.inner:SetSize(inner_size, inner_size)
                end

                icon.timer:SetPosition(0, 0)
                icon.timer:SetSize(size, size)
                icon.timer:SetFont(font)
                icon.timer:SetFontStyle(style)
                icon.timer:SetForeColor(color)
                icon.timer:SetOutlineColor(outline)
                icon.timer:SetText(_timer_text(times[i]))
            end
        end
    end

    -- Use remaining time samples (sorted like the real windows: longest first).
    local debuff_times = { 8.4, 2.6 }
    if p.debuff_icons ~= nil then
        layout_icons(p.debuff_icons, frame_w, debuff_area_h, debuff_icon, debuff_cols, debuff_times, debuff_timer_font,
            debuff_timer_style, debuff_timer_color, debuff_timer_outline, reverse_fill)
    end

    local buff_times = { 6.2, 1.8 }
    if p.buff_icons ~= nil then
        layout_icons(p.buff_icons, frame_w, buff_area_h, buff_icon, buff_cols, buff_times, buff_timer_font,
            buff_timer_style, buff_timer_color, buff_timer_outline, reverse_fill)
    end

    local morale_bg = _hex_to_color(self.controls[prefix .. "_morale_background_color"].tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local ressource_bg_matches_missing = self.controls[prefix .. "_ressource_background_matches_missing"].cb:IsChecked() ==
        true
    local ressource_bg_dimming = tonumber(self.controls[prefix .. "_ressource_background_dimming"].tb:GetText()) or 0.75
    local border_color = _hex_to_color(self.controls[prefix .. "_border_color"].tb:GetText()) or morale_bg
    local bubble_color = _hex_to_color(self.controls[prefix .. "_morale_bubble_color"].tb:GetText()) or
        Turbine.UI.Color(0.53, 0.8, 0.98)
    local high_color = _hex_to_color(self.controls[prefix .. "_morale_color_high"].tb:GetText()) or
        Turbine.UI.Color(0.290196, 0.639216, 0.286275)
    local med_color = _hex_to_color(self.controls[prefix .. "_morale_color_medium"].tb:GetText()) or
        Turbine.UI.Color(0.650980, 0.803922, 0.196078)
    local low_color = _hex_to_color(self.controls[prefix .. "_morale_color_low"].tb:GetText()) or
        Turbine.UI.Color(0.87, 0.55, 0)
    local crit_color = _hex_to_color(self.controls[prefix .. "_morale_color_critical"].tb:GetText()) or
        Turbine.UI.Color(0.87, 0.11, 0)
    local morale_gradient = self.controls[prefix .. "_morale_gradient"].cb:IsChecked() == true
    local gradient_full = _hex_to_color(self.controls[prefix .. "_morale_gradient_full"].tb:GetText()) or high_color
    local gradient_mid = _hex_to_color(self.controls[prefix .. "_morale_gradient_mid"].tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local gradient_low = _hex_to_color(self.controls[prefix .. "_morale_gradient_low"].tb:GetText()) or crit_color
    self:_update_gradient_preview(prefix .. "_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)

    local function resource_background(fill_color)
        if ressource_bg_matches_missing == true then
            return _dim_color(fill_color, ressource_bg_dimming)
        end
        return morale_bg
    end

    local inner_w = frame_w - (2 * border)
    local inner_morale_h = morale_h - (2 * border)
    local inner_power_h = power_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_morale_h < 1 then inner_morale_h = 1 end
    if inner_power_h < 1 then inner_power_h = 1 end

    local morale_percent = 0.67
    local bubble_percent = 0.20
    local power_percent = 0.55

    p.morale_border:SetPosition(0, morale_top)
    p.morale_border:SetSize(frame_w, morale_h)
    p.morale_border:SetBackColor(border_color)

    p.morale_background:SetPosition(border, border)
    p.morale_background:SetSize(inner_w, inner_morale_h)
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, gradient_full, gradient_mid,
        gradient_low, high_color, med_color, low_color, crit_color)
    p.morale_background:SetBackColor(resource_background(morale_fill_color))

    local morale_fill_w = math.floor(inner_w * morale_percent + 0.5)
    if morale_fill_w < 0 then morale_fill_w = 0 end
    if morale_fill_w > inner_w then morale_fill_w = inner_w end

    p.morale_bar:SetPosition(0, 0)
    p.morale_bar:SetSize(morale_fill_w, inner_morale_h)
    p.morale_bar:SetBackColor(morale_fill_color)

    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        p.bubble_bar:SetVisible(true)
        p.bubble_bar:SetTop(0)
        p.bubble_bar:SetHeight(inner_morale_h)
        p.bubble_bar:SetWidth(bubble_w)

        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = morale_fill_w
        if left_inner > max_left then left_inner = max_left end
        p.bubble_bar:SetLeft(left_inner)
        p.bubble_bar:SetBackColor(bubble_color)
    else
        p.bubble_bar:SetVisible(false)
    end

    local morale_font_name = self.controls[prefix .. "_morale_font_name"]:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_morale_font_size = tonumber(self.controls[prefix .. "_morale_font_size"].tb:GetText()) or 16
    local morale_font_size = scaled_number(raw_morale_font_size, 16)
    local morale_font = _require_font(morale_font_name, morale_font_size)
    local morale_style_enum = self.controls[prefix .. "_morale_font_style"]:get_value() or LUI_ENUMS.font_style.OUTLINE
    local morale_font_style = LUI_TO_LOTRO.font_style[morale_style_enum] or Turbine.UI.FontStyle.None
    local morale_font_color = _hex_to_color(self.controls[prefix .. "_morale_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local morale_outline_color = _hex_to_color(self.controls[prefix .. "_morale_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local morale_fmt = self.controls[prefix .. "_morale_text"].tb:GetText() or ""
    local bubble_fmt = self.controls[prefix .. "_morale_bubble_text"].tb:GetText() or ""
    local morale_fmt_tokens = lui_tokenize_format(morale_fmt)
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)
    local morale_align_text = self.controls[prefix .. "_morale_text_alignment"]:get_value() or
        LUI_ENUMS.text_alignment.CENTER

    local morale_max = 10000
    local morale_cur = math.floor(morale_max * morale_percent + 0.5)
    local bubble_max = math.floor(morale_max * bubble_percent + 0.5)
    local morale_pct_text = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%"

    local name = is_target and TR("Target") or TR("Player")
    local level = is_target and "150" or ""
    local bubble_text = ""
    if bubble_max > 0 then
        bubble_text = lui_abbrev_number(bubble_max)
    end

    local bubble_formatted = ""
    if bubble_max > 0 and string.len(bubble_fmt) > 0 then
        bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
    end

    p.morale_label:SetPosition(0, 0)
    do
        local raw_margin = tonumber(self.controls[prefix .. "_morale_text_margin"].tb:GetText()) or 4
        local m = border + scaled_int(raw_margin, 4)
        if morale_align_text == LUI_ENUMS.text_alignment.LEFT then
            p.morale_label:SetPosition(m, 0)
            p.morale_label:SetSize(frame_w - m, morale_h)
        elseif morale_align_text == LUI_ENUMS.text_alignment.RIGHT then
            p.morale_label:SetPosition(0, 0)
            p.morale_label:SetSize(frame_w - m, morale_h)
        else
            p.morale_label:SetPosition(0, 0)
            p.morale_label:SetSize(frame_w, morale_h)
        end
    end
    p.morale_label:SetFont(morale_font)
    p.morale_label:SetFontStyle(morale_font_style)
    p.morale_label:SetForeColor(morale_font_color)
    p.morale_label:SetOutlineColor(morale_outline_color)
    p.morale_label:SetTextAlignment(text_align(morale_align_text))
    p.morale_label:SetText(lui_format_tokenized(morale_fmt_tokens, {
        name = name,
        level = level,
        c = lui_abbrev_number(morale_cur),
        t = lui_abbrev_number(morale_max),
        p = morale_pct_text,
        b = bubble_text,
        B = bubble_formatted,
    }))

    p.power_border:SetPosition(0, power_top)
    p.power_border:SetSize(frame_w, power_h)
    p.power_border:SetBackColor(border_color)

    p.power_background:SetPosition(border, border)
    p.power_background:SetSize(inner_w, inner_power_h)
    local power_color = _hex_to_color(self.controls[prefix .. "_power_color"].tb:GetText()) or
        Turbine.UI.Color(0.2, 0.6, 0.98)
    p.power_background:SetBackColor(resource_background(power_color))
    p.power_bar:SetPosition(0, 0)
    p.power_bar:SetSize(math.floor(inner_w * power_percent + 0.5), inner_power_h)
    p.power_bar:SetBackColor(power_color)

    local power_font_name = self.controls[prefix .. "_power_font_name"]:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_power_font_size = tonumber(self.controls[prefix .. "_power_font_size"].tb:GetText()) or 14
    local power_font_size = scaled_number(raw_power_font_size, 14)
    local power_font = _require_font(power_font_name, power_font_size)
    local power_style_enum = self.controls[prefix .. "_power_font_style"]:get_value() or LUI_ENUMS.font_style.OUTLINE
    local power_font_style = LUI_TO_LOTRO.font_style[power_style_enum] or Turbine.UI.FontStyle.None
    local power_font_color = _hex_to_color(self.controls[prefix .. "_power_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local power_outline_color = _hex_to_color(self.controls[prefix .. "_power_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local power_fmt = self.controls[prefix .. "_power_text"].tb:GetText() or ""
    local power_fmt_tokens = lui_tokenize_format(power_fmt)
    local power_align_text = self.controls[prefix .. "_power_text_alignment"]:get_value() or
        LUI_ENUMS.text_alignment.CENTER
    local power_max = 30000
    local power_cur = math.floor(power_max * power_percent + 0.5)
    local power_pct_text = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"

    p.power_label:SetPosition(0, 0)
    do
        local raw_margin = tonumber(self.controls[prefix .. "_power_text_margin"].tb:GetText()) or 4
        local m = border + scaled_int(raw_margin, 4)
        if power_align_text == LUI_ENUMS.text_alignment.LEFT then
            p.power_label:SetPosition(m, 0)
            p.power_label:SetSize(frame_w - m, power_h)
        elseif power_align_text == LUI_ENUMS.text_alignment.RIGHT then
            p.power_label:SetPosition(0, 0)
            p.power_label:SetSize(frame_w - m, power_h)
        else
            p.power_label:SetPosition(0, 0)
            p.power_label:SetSize(frame_w, power_h)
        end
    end
    p.power_label:SetFont(power_font)
    p.power_label:SetFontStyle(power_font_style)
    p.power_label:SetForeColor(power_font_color)
    p.power_label:SetOutlineColor(power_outline_color)
    p.power_label:SetTextAlignment(text_align(power_align_text))
    p.power_label:SetText(lui_format_tokenized(power_fmt_tokens, {
        name = name,
        level = level,
        c = lui_abbrev_number(power_cur),
        t = lui_abbrev_number(power_max),
        p = power_pct_text,
    }))
    if p.include_targets_target and p.targets_target_background ~= nil then
        p.targets_target_background:SetVisible(false)
    end

    lui_clear_number_abbrev_preview_settings()
end
