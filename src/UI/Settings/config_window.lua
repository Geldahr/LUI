import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Turbine.Gameplay"

import "LUI.src.UI.Widgets"
import "LUI.src.Utils.icons"
import "LUI.src.Utils.color"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.stretch"
import "LUI.src.Utils.time_format"
import "LUI.src.Utils.token_format"
import "LUI.src.Settings.enums"

import "LUI.src.UI.Settings.Tabs.global"
import "LUI.src.UI.Settings.Tabs.profile_manager"
import "LUI.src.UI.Settings.Tabs.self_vitals"
import "LUI.src.UI.Settings.Tabs.target_vitals"
import "LUI.src.UI.Settings.Tabs.target_boss_vitals"
import "LUI.src.UI.Settings.Tabs.target_targets_target"
import "LUI.src.UI.Settings.Tabs.expiring_target_effects"
import "LUI.src.UI.Settings.Tabs.party_layout"
import "LUI.src.UI.Settings.Tabs.party_vitals"
import "LUI.src.UI.Settings.Tabs.self_expiring_effects"
import "LUI.src.UI.Settings.Tabs.inventory"
import "LUI.src.UI.Settings.Tabs.assets"
import "LUI.src.UI.Settings.Tabs.status_bar"
import "LUI.src.UI.Settings.Tabs.cooldowns"
import "LUI.src.UI.Settings.Tabs.help"

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
local BASE_SCROLL_W = 10
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
    self.help:SetText(TR("Use '/LUI config' to toggle the configuration window."))
end

ConfigWindow = class(Turbine.UI.Lotro.Window)

import "LUI.src.UI.Settings.Window.window_geometry"
import "LUI.src.UI.Settings.Preview.common"
import "LUI.src.UI.Settings.Preview.self_expiring_effects"
import "LUI.src.UI.Settings.Preview.cooldowns"
import "LUI.src.UI.Settings.Preview.expiring_target_effects"
import "LUI.src.UI.Settings.Preview.target_boss_vitals"
import "LUI.src.UI.Settings.Preview.target_targets_target"
import "LUI.src.UI.Settings.Preview.party_vitals"
import "LUI.src.UI.Settings.Preview.vitals"

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function ConfigWindow:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetText(TR("LUI Configuration"))
    self:SetResizable(true)
    self:SetVisible(false)

    self:_update_ui_scale_metrics()

    self.main_tab_bar = UI.Widgets.LuiTabBar()
    self.main_tab_bar:SetParent(self)
    self.main_tab_bar:set_tab_position(UI.Widgets.LuiTabBar.position.left)
    self.main_tab_bar:set_show_content_border(false)
    self.main_tab_bar.selection_changed = function(_, _, _, host)
        if self._syncing_tab_widgets == true or host == nil then
            return
        end
        self:select_main_tab(host._tab_key)
    end

    self.scroll = Turbine.UI.ListBox()
    self.scroll:SetParent(self)
    self.scroll:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.scroll_bar = Turbine.UI.Lotro.ScrollBar()
    self.scroll_bar:SetParent(self)
    self.scroll_bar:SetOrientation(Turbine.UI.Orientation.Vertical)
    self.scroll_bar:SetWidth(BASE_SCROLL_W)
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

    self.hint_label = UI.Widgets.LuiLabel()
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

    self.confirm_dialog_label = UI.Widgets.LuiLabel()
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
        self:cancel()
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

    self.VisibleChanged = function()
        if self:IsVisible() == false then
            self:hide_hint()
            self:hide_confirmation_dialog()
            self:close_all_dropdowns()
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

    if self.main_tab_bar ~= nil then
        self.main_tab_bar:set_scale(scale)
        self.main_tab_bar:set_font(self.tab_font)
    end
    if self.sub_tab_bars ~= nil then
        for _, bar in pairs(self.sub_tab_bars) do
            if bar ~= nil then
                bar:set_scale(scale)
                bar:set_font(self.tab_font)
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
                if field.cb.SetScale ~= nil then
                    field.cb:SetScale(scale)
                end
                field.cb:SetFont(self.field_label_font)
            end
        end
    end

    for _, page in pairs(self._tab_pages or {}) do
        if page ~= nil and page.apply_ui_scale ~= nil then
            page:apply_ui_scale()
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

    for _, page in pairs(self._tab_pages or {}) do
        if page ~= nil and page.close_all_dropdowns ~= nil then
            page:close_all_dropdowns()
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

function ConfigWindow:cancel()
    self:hide_confirmation_dialog()
    self:SetVisible(false)
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
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function ConfigWindow:build_tabs()
    self._tab_pages = {}

    local function _tab_widget(key)
        local module = self._tab_modules_by_key ~= nil and self._tab_modules_by_key[key] or nil
        if module ~= nil and module.create_page ~= nil then
            local page = module.create_page(self)
            if page ~= nil then
                page._tab_key = key
                self._tab_pages[key] = page
                return page
            end
        end

        local host = Turbine.UI.Control()
        host._tab_key = key
        return host
    end

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

    self.main_tab_index_by_key = {}
    self.main_tab_hosts = {}
    for i = 1, #self.main_tabs do
        local t = self.main_tabs[i]
        local widget = _tab_widget(t.key)
        if self._tab_pages[t.key] == nil then
            self.main_tab_hosts[t.key] = widget
        end
        self.main_tab_index_by_key[t.key] = self.main_tab_bar:add_tab(t.text, widget)
    end

    self.sub_tab_bars = {}
    self.sub_tab_hosts_by_main = {}
    self.sub_tab_index_by_key = {}
    for main_key, list in pairs(self.sub_tabs_by_main) do
        local bar = UI.Widgets.LuiTabBar()
        bar:SetParent(self.main_tab_hosts[main_key])
        bar:set_tab_position(UI.Widgets.LuiTabBar.position.top)
        bar:set_content_padding(4)
        bar:set_show_border_left(false)
        bar.selection_changed = function(_, _, _, host)
            if self._syncing_tab_widgets == true or host == nil then
                return
            end
            self:select_sub_tab(host._tab_key)
        end

        self.sub_tab_bars[main_key] = bar
        self.sub_tab_hosts_by_main[main_key] = {}
        self.sub_tab_index_by_key[main_key] = {}

        for i = 1, #list do
            local t = list[i]
            local widget = _tab_widget(t.key)
            if self._tab_pages[t.key] == nil then
                self.sub_tab_hosts_by_main[main_key][t.key] = widget
            end
            self.sub_tab_index_by_key[main_key][t.key] = bar:add_tab(t.text, widget)
        end
    end
end

function ConfigWindow:_main_tab_default_key(main_key)
    if main_key == "global" then
        return "global"
    elseif main_key == "inventory" then
        return "inventory"
    elseif main_key == "assets" then
        return "assets"
    elseif main_key == "status_bar" then
        return "status_bar"
    elseif main_key == "profile_manager" then
        return "profile_manager"
    elseif main_key == "help" then
        return "help"
    end
    return nil
end

function ConfigWindow:_main_tab_has_sub_tabs(main_key)
    local sub_list = self.sub_tabs_by_main ~= nil and self.sub_tabs_by_main[main_key] or nil
    return sub_list ~= nil and #sub_list > 1
end

function ConfigWindow:_active_scroll_host()
    if self._tab_pages ~= nil and self._tab_pages[self.active_tab] ~= nil then
        return nil
    end

    local main_key = self.active_main_tab
    if type(main_key) ~= "string" then
        return nil
    end

    if self:_main_tab_has_sub_tabs(main_key) == true then
        local sub_hosts = self.sub_tab_hosts_by_main ~= nil and self.sub_tab_hosts_by_main[main_key] or nil
        if sub_hosts ~= nil then
            return sub_hosts[self.active_tab]
        end
        return nil
    end

    return self.main_tab_hosts ~= nil and self.main_tab_hosts[main_key] or nil
end

function ConfigWindow:_attach_scroll_to_host(host)
    if host == nil then
        return
    end

    self.scroll:SetParent(host)
    self.scroll_bar:SetParent(host)
end

function ConfigWindow:select_main_tab(main_key, preferred_sub_key)
    if type(main_key) ~= "string" then
        main_key = "global"
    end
    if main_key == "cooldowns" then
        main_key = "self"
        preferred_sub_key = "cooldowns"
    end

    if self.main_tab_index_by_key ~= nil and self.main_tab_index_by_key[main_key] == nil then
        main_key = "global"
    end

    local tab_key = self:_main_tab_default_key(main_key)
    if tab_key == nil then
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
        main_key = "global"
    end

    self.active_main_tab = main_key

    self._syncing_tab_widgets = true
    if self.main_tab_bar ~= nil then
        self.main_tab_bar:set_selected_index(self.main_tab_index_by_key[main_key], false)
    end
    if self:_main_tab_has_sub_tabs(main_key) == true then
        local bar = self.sub_tab_bars ~= nil and self.sub_tab_bars[main_key] or nil
        local index = self.sub_tab_index_by_key ~= nil and self.sub_tab_index_by_key[main_key] ~= nil and
            self.sub_tab_index_by_key[main_key][tab_key] or nil
        if bar ~= nil and index ~= nil then
            bar:set_selected_index(index, false)
        end
    end
    self._syncing_tab_widgets = false

    self:select_tab(tab_key)
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
    local page = self._tab_pages ~= nil and self._tab_pages[key] or nil
    if self.tab_fields[key] == nil and page == nil then
        return
    end

    self:hide_hint()

    self:hide_all_fields()
    self.active_tab = key
    self.fields = self.tab_fields[key] or {}
    if page == nil then
        self:show_fields(self.fields)
    end
    self:layout()

    if page ~= nil and page.on_selected ~= nil then
        page:on_selected()
        return
    end

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

function ConfigWindow:build_controls()
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

        entry.label = UI.Widgets.LuiLabel()
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

        entry.label = UI.Widgets.LuiLabel()
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

        entry.label = UI.Widgets.LuiLabel()
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

        entry.label = UI.Widgets.LuiLabel()
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

        entry.cb = UI.Widgets.LuiCheckBox()
        entry.cb:SetParent(self.form)
        entry.cb:SetFont(self.field_label_font)
        entry.cb:SetText(tostring(label_text or ""))
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
    self._tab_modules = {
        tabs.Global,
        tabs.ProfileManager,
        tabs.SelfVitals,
        tabs.TargetVitals,
        tabs.TargetBossVitals,
        tabs.TargetTargetsTarget,
        tabs.ExpiringTargetEffects,
        tabs.PartyLayout,
        tabs.PartyVitals,
        tabs.SelfExpiringEffects,
        tabs.Inventory,
        tabs.AssetsTab,
        tabs.StatusBar,
        tabs.Cooldowns,
        tabs.Help,
    }

    self._tab_modules_by_key = {}
    for i = 1, #self._tab_modules do
        local module = self._tab_modules[i]
        if module ~= nil and module.key ~= nil then
            self._tab_modules_by_key[module.key] = module
        end
        if module ~= nil and module.create_controls ~= nil and module.create_page == nil then
            module.create_controls(self, ui)
        end
    end

    for i = 1, #self._tab_modules do
        local module = self._tab_modules[i]
        if module ~= nil and module.register ~= nil and module.create_page == nil then
            self.tab_fields[module.key] = module.register(self, ui)
        end
    end

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

function ConfigWindow:layout()
    local window_width, window_height = self:GetSize()
    local button_gap = _scaled_int(7)
    local min_content_h = _scaled_int(59)
    local scroll_w = BASE_SCROLL_W
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

    self.main_tab_bar:SetPosition(self.margin_left, self.margin_top)
    self.main_tab_bar:SetSize(button_bar_width, content_height)
    self.main_tab_bar:refresh_layout()

    local active_main_key = self.active_main_tab or "global"
    if self.sub_tab_bars ~= nil then
        for key, bar in pairs(self.sub_tab_bars) do
            if bar ~= nil then
                local show_bar = key == active_main_key and self:_main_tab_has_sub_tabs(key) == true
                bar:SetVisible(show_bar)
                if show_bar == true then
                    local host = self.main_tab_hosts ~= nil and self.main_tab_hosts[key] or nil
                    if host ~= nil then
                        bar:SetPosition(0, 0)
                        bar:SetSize(host:GetWidth(), host:GetHeight())
                        bar:refresh_layout()
                    end
                end
            end
        end
    end

    local scroll_host = self:_active_scroll_host()
    local form_width = 0
    local inner_width = 0
    if scroll_host ~= nil then
        self:_attach_scroll_to_host(scroll_host)

        local scroll_width = scroll_host:GetWidth()
        local scroll_height = scroll_host:GetHeight()
        if scroll_height < _scaled_int(30) then
            scroll_height = _scaled_int(30)
        end

        self.scroll:SetVisible(true)
        self.scroll_bar:SetVisible(true)
        self.scroll:SetPosition(0, 0)
        self.scroll:SetSize(math.max(0, scroll_width - scroll_w - self.scroll_bar_gap), scroll_height)

        self.scroll_bar:SetPosition(self.scroll:GetWidth() + self.scroll_bar_gap, 0)
        self.scroll_bar:SetHeight(scroll_height)

        form_width = self.scroll:GetWidth()
        inner_width = form_width - (2 * self.content_padding)
        if inner_width < _scaled_int(74) then
            inner_width = _scaled_int(74)
        end
    else
        self.scroll:SetVisible(false)
        self.scroll_bar:SetVisible(false)
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
    if BESTIARY_WINDOW ~= nil and BESTIARY_WINDOW.apply_settings ~= nil then
        BESTIARY_WINDOW:apply_settings()
    end
    if BESTIARY_TRACKER ~= nil and BESTIARY_TRACKER.apply_settings ~= nil then
        BESTIARY_TRACKER:apply_settings()
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

function ConfigWindow:apply_changes(close_after)
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

    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
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

    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
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

    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
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
