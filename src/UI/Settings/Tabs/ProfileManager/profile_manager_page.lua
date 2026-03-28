import "Turbine.UI"

import "LUI.src.UI.Settings.Tabs.form_page"
import "LUI.src.UI.Widgets"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local PROFILE_INFO_FONT_NAME = "Verdana"
local PROFILE_INFO_FONT_SIZE = 13
local INFO_HEIGHT = 59
local ACTION_ROW_HEIGHT = 24
local ACTION_BUTTON_WIDTH = 122
local BLOCK_GAP = 24

local function _scaled_profile_info_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_action_button_width()
    return math.floor((ACTION_BUTTON_WIDTH * _G.settings.global.scale) + 0.5)
end

local function _scaled_profile_info_font()
    local font = FONT_TO_LOTRO(PROFILE_INFO_FONT_NAME, _scaled_profile_info_size(PROFILE_INFO_FONT_SIZE))
    if font == nil then
        error("Missing profile info font: " .. tostring(PROFILE_INFO_FONT_NAME) .. " " .. tostring(PROFILE_INFO_FONT_SIZE))
    end
    return font
end

local function _layout_info(entry)
    if entry == nil or entry.control == nil or entry.body == nil then
        return
    end

    local width, height = entry.control:GetSize()
    entry.body:SetPosition(0, 0)
    entry.body:SetSize(width, height)
end

local function _layout_button_row(window, entry, left_button, right_button)
    if entry == nil or entry.control == nil or left_button == nil then
        return
    end

    local gap = window.inner_gap or 0
    local width, height = entry.control:GetSize()
    local button_width = _scaled_action_button_width()
    if button_width > width then
        button_width = width
    end

    if right_button == nil then
        left_button:SetPosition(0, 0)
        left_button:SetSize(button_width, height)
        return
    end

    if (button_width * 2) + gap > width then
        button_width = math.floor((width - gap) / 2)
    end
    if button_width < 1 then
        button_width = 1
    end

    left_button:SetPosition(0, 0)
    left_button:SetSize(button_width, height)

    right_button:SetPosition(button_width + gap, 0)
    right_button:SetSize(button_width, height)
end

local function _apply_info_scale(entry)
    if entry == nil or entry.body == nil then
        return
    end

    entry.body:SetFont(_scaled_profile_info_font())
    _layout_info(entry)
end

local function _apply_row_scale(window, entry, left_button, right_button)
    if left_button ~= nil then
        left_button:SetFont(window.settings_font)
    end
    if right_button ~= nil then
        right_button:SetFont(window.settings_font)
    end
    _layout_button_row(window, entry, left_button, right_button)
end

local function _refresh_profile_manager(page, selected_profile_id)
    if page == nil or page.controls == nil then
        return
    end
    if page.window.profile_manager_refreshing == true then
        return
    end

    local profile_dropdown = page.controls.profile_manager_profile
    local name_field = page.controls.profile_manager_name
    if profile_dropdown == nil or name_field == nil then
        return
    end

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
    if page.profile_manager_use_button ~= nil then
        page.profile_manager_use_button:SetEnabled(active_profile_id ~= nil and active_profile_id ~= _G.current_profile_id)
    end
    if page.profile_manager_rename_button ~= nil then
        page.profile_manager_rename_button:SetEnabled(active_profile_id ~= nil)
    end
    if page.profile_manager_delete_button ~= nil then
        page.profile_manager_delete_button:SetEnabled(can_delete)
    end

    page.window.profile_manager_refreshing = false
end

ProfileManagerPage = class(SettingsFormPage)

function ProfileManagerPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)

    self:add_title(TR("Configuration / Profile Manager"))

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
        TR("Profile actions here apply immediately."),
        TR("Deleting a profile removes it for all characters using it."),
        TR("Profile Manager changes override unsaved changes in other tabs."),
    }, "\n"))
    info_entry.control.SizeChanged = function()
        _layout_info(info_entry)
    end
    info_entry.apply_ui_scale = function()
        _apply_info_scale(info_entry)
    end
    info_entry:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    local profile_dropdown = self:add_dropdown("profile_manager_profile", TR("Profile"), {}, {}, nil, true)
    profile_dropdown.on_changed = function(value)
        _refresh_profile_manager(self, value)
    end

    local profile_actions = self:add_custom("profile_manager_profile_actions", ACTION_ROW_HEIGHT)
    profile_actions.use_button = UI.Widgets.LuiButton()
    profile_actions.use_button:SetParent(profile_actions.control)
    profile_actions.use_button:SetText(TR("Use"))
    profile_actions.use_button.Click = function()
        window:use_selected_profile()
    end

    profile_actions.delete_button = UI.Widgets.LuiButton()
    profile_actions.delete_button:SetParent(profile_actions.control)
    profile_actions.delete_button:SetText(TR("Delete"))
    profile_actions.delete_button.Click = function()
        window:confirm_delete_selected_profile()
    end

    profile_actions.control.SizeChanged = function()
        _layout_button_row(window, profile_actions, profile_actions.use_button, profile_actions.delete_button)
    end
    profile_actions.apply_ui_scale = function()
        _apply_row_scale(window, profile_actions, profile_actions.use_button, profile_actions.delete_button)
    end
    profile_actions:apply_ui_scale()

    self:add_break(BLOCK_GAP)

    self:add_text("profile_manager_name", TR("Name"), false, nil, true)

    local rename_actions = self:add_custom("profile_manager_name_actions", ACTION_ROW_HEIGHT)
    rename_actions.rename_button = UI.Widgets.LuiButton()
    rename_actions.rename_button:SetParent(rename_actions.control)
    rename_actions.rename_button:SetText(TR("Rename"))
    rename_actions.rename_button.Click = function()
        window:rename_selected_profile()
    end

    rename_actions.control.SizeChanged = function()
        _layout_button_row(window, rename_actions, rename_actions.rename_button, nil)
    end
    rename_actions.apply_ui_scale = function()
        _apply_row_scale(window, rename_actions, rename_actions.rename_button, nil)
    end
    rename_actions:apply_ui_scale()

    self:add_break(BLOCK_GAP)
    self:add_title(TR("Create"))

    local new_actions = self:add_custom("profile_manager_new_actions", ACTION_ROW_HEIGHT)
    new_actions.new_from_current_button = UI.Widgets.LuiButton()
    new_actions.new_from_current_button:SetParent(new_actions.control)
    new_actions.new_from_current_button:SetText(TR("New from current"))
    new_actions.new_from_current_button.Click = function()
        window:create_profile_from_current()
    end

    new_actions.new_button = UI.Widgets.LuiButton()
    new_actions.new_button:SetParent(new_actions.control)
    new_actions.new_button:SetText(TR("New"))
    new_actions.new_button.Click = function()
        window:start_new_profile_quick_setup()
    end

    new_actions.control.SizeChanged = function()
        _layout_button_row(window, new_actions, new_actions.new_from_current_button, new_actions.new_button)
    end
    new_actions.apply_ui_scale = function()
        _apply_row_scale(window, new_actions, new_actions.new_from_current_button, new_actions.new_button)
    end
    new_actions:apply_ui_scale()

    self.profile_manager_use_button = profile_actions.use_button
    self.profile_manager_delete_button = profile_actions.delete_button
    self.profile_manager_rename_button = rename_actions.rename_button
end

function ProfileManagerPage:load()
    local selected_profile_id = self.window.profile_manager_selected_profile_id or _G.current_profile_id
    _refresh_profile_manager(self, selected_profile_id)
end

function ProfileManagerPage:apply()
end
