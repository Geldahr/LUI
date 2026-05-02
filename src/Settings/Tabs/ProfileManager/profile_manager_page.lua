import "Turbine.UI"

import "LUI.src.Settings.Tabs.form_page"
import "LUI.src.UI.Widgets"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local PROFILE_INFO_FONT_NAME = "Verdana"
local PROFILE_INFO_FONT_SIZE = 13
local INFO_HEIGHT = 59
local ACTION_ROW_HEIGHT = 24
local BLOCK_GAP = 24
local PROFILE_COLUMNS = 4

local function _scaled_profile_info_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_profile_info_font()
    local font = FONT_TO_LOTRO(PROFILE_INFO_FONT_NAME, _scaled_profile_info_size(PROFILE_INFO_FONT_SIZE))
    if font == nil then
        error("Missing profile info font: " .. tostring(PROFILE_INFO_FONT_NAME) .. " " ..
            tostring(PROFILE_INFO_FONT_SIZE))
    end
    return font
end

local function _layout_info(entry)
    local width, height = entry.control:GetSize()
    entry.body:SetPosition(0, 0)
    entry.body:SetSize(width, height)
end

local function _layout_button_row(window, entry, buttons)
    local width, height = entry.control:GetSize()
    local grid_gaps = (PROFILE_COLUMNS - 1) * window.col_gap
    local col_width = math.floor((width - grid_gaps) / PROFILE_COLUMNS)
    if col_width < 1 then
        col_width = 1
    end

    if #buttons < 1 then
        return
    end

    for i = 1, #buttons do
        local item = buttons[i]
        local button = item.button
        local col = item.col - 1
        local x = col * (col_width + window.col_gap)
        button:SetPosition(x, 0)
        button:SetSize(col_width, height)
    end
end

local function _apply_info_scale(entry)
    entry.body:SetFont(_scaled_profile_info_font())
    _layout_info(entry)
end

local function _apply_row_scale(window, entry, buttons)
    for i = 1, #buttons do
        buttons[i].button:set_font(window.settings_font)
    end
    _layout_button_row(window, entry, buttons)
end

local function _refresh_profile_manager(page, selected_profile_id)
    if page.window.profile_manager_refreshing == true then
        return
    end

    local profile_dropdown = page.controls.profile_manager_profile
    local name_field = page.controls.profile_manager_name

    page.window.profile_manager_refreshing = true

    local labels, values = get_configuration_options()
    profile_dropdown.option_labels = labels
    profile_dropdown.option_values = values
    profile_dropdown.button:SetMappedOptions(labels, values)

    local wanted_profile_id = selected_profile_id
    if wanted_profile_id == nil then
        wanted_profile_id = profile_dropdown:get_value()
    end
    if wanted_profile_id == nil then
        wanted_profile_id = _G.current_profile_id
    end
    if wanted_profile_id == nil then
        wanted_profile_id = get_first_configuration_id()
    end

    if wanted_profile_id ~= nil then
        profile_dropdown:set_value(wanted_profile_id)
    end

    local active_profile_id = profile_dropdown:get_value()
    page.window.profile_manager_selected_profile_id = active_profile_id
    local profile_name = get_configuration_name(active_profile_id) or ""
    name_field.tb:SetText(profile_name)

    local can_delete = active_profile_id ~= nil and get_configuration_count() > 1
    page.profile_manager_use_button:set_enabled(active_profile_id ~= nil and active_profile_id ~= _G.current_profile_id)
    page.profile_manager_rename_button:set_enabled(active_profile_id ~= nil)
    page.profile_manager_delete_button:set_enabled(can_delete)

    page.window.profile_manager_refreshing = false
end

ProfileManagerPage = class(SettingsFormPage)

function ProfileManagerPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = false
    self:set_compact_fields(true)
    self:set_grid_columns(PROFILE_COLUMNS)

    local info_entry = self:add_custom("profile_manager_info", INFO_HEIGHT)
    info_entry.body = UI.Widgets.LuiLabel()
    info_entry.body:SetParent(info_entry.control)
    info_entry.body:SetMouseVisible(false)
    info_entry.body:SetSelectable(false)
    info_entry.body:SetMultiline(true)
    info_entry.body:SetFont(_scaled_profile_info_font())
    info_entry.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    info_entry.body:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    info_entry.body:SetText(table.concat({
        TR["Profile actions here apply immediately."],
        TR["Deleting a profile removes it for all characters using it."],
        TR["Profile Manager changes override unsaved changes in other tabs."],
    }, "\n"))
    info_entry.control.SizeChanged = function()
        _layout_info(info_entry)
    end
    info_entry.apply_ui_scale = function()
        _apply_info_scale(info_entry)
    end
    info_entry:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    local profile_dropdown = self:add_dropdown("profile_manager_profile", TR["Profile"], {}, {}, nil, true)
    profile_dropdown.on_changed = function(value)
        _refresh_profile_manager(self, value)
    end

    local profile_actions = self:add_custom("profile_manager_profile_actions", ACTION_ROW_HEIGHT)
    profile_actions.use_button = UI.Widgets.LuiButton()
    profile_actions.use_button:SetParent(profile_actions.control)
    profile_actions.use_button:set_text(TR["Use"])
    profile_actions.use_button.Click = function()
        window:use_selected_profile()
    end

    profile_actions.delete_button = UI.Widgets.LuiButton()
    profile_actions.delete_button:SetParent(profile_actions.control)
    profile_actions.delete_button:set_text(TR["Delete"])
    profile_actions.delete_button.Click = function()
        window:confirm_delete_selected_profile()
    end

    profile_actions.control.SizeChanged = function()
        _layout_button_row(window, profile_actions, {
            { button = profile_actions.use_button, col = 1 },
            { button = profile_actions.delete_button, col = 4 },
        })
    end
    profile_actions.apply_ui_scale = function()
        _apply_row_scale(window, profile_actions, {
            { button = profile_actions.use_button, col = 1 },
            { button = profile_actions.delete_button, col = 4 },
        })
    end
    profile_actions:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    self:add_text("profile_manager_name", TR["Name"], false, nil, true)

    local name_actions = self:add_custom("profile_manager_name_actions", ACTION_ROW_HEIGHT)
    name_actions.rename_button = UI.Widgets.LuiButton()
    name_actions.rename_button:SetParent(name_actions.control)
    name_actions.rename_button:set_text(TR["Rename"])
    name_actions.rename_button.Click = function()
        window:rename_selected_profile()
    end

    name_actions.new_from_current_button = UI.Widgets.LuiButton()
    name_actions.new_from_current_button:SetParent(name_actions.control)
    name_actions.new_from_current_button:set_text(TR["New from current"])
    name_actions.new_from_current_button.Click = function()
        window:create_profile_from_current()
    end

    name_actions.new_button = UI.Widgets.LuiButton()
    name_actions.new_button:SetParent(name_actions.control)
    name_actions.new_button:set_text(TR["New"])
    name_actions.new_button.Click = function()
        window:start_new_profile_quick_setup()
    end

    name_actions.control.SizeChanged = function()
        _layout_button_row(window, name_actions, {
            { button = name_actions.rename_button, col = 1 },
            { button = name_actions.new_from_current_button, col = 3 },
            { button = name_actions.new_button, col = 4 },
        })
    end
    name_actions.apply_ui_scale = function()
        _apply_row_scale(window, name_actions, {
            { button = name_actions.rename_button, col = 1 },
            { button = name_actions.new_from_current_button, col = 3 },
            { button = name_actions.new_button, col = 4 },
        })
    end
    name_actions:apply_ui_scale()

    self.profile_manager_use_button = profile_actions.use_button
    self.profile_manager_delete_button = profile_actions.delete_button
    self.profile_manager_rename_button = name_actions.rename_button
end

function ProfileManagerPage:load()
    local selected_profile_id = self.window.profile_manager_selected_profile_id or _G.current_profile_id
    _refresh_profile_manager(self, selected_profile_id)
end

function ProfileManagerPage:apply()
end

function ProfileManagerPage:load_from_settings()
    self:load()
end

function ProfileManagerPage:apply_to_settings()
    self:apply()
end
