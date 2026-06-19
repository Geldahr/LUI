local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigSectionPage = _G.LUI.Settings.Content.ConfigSectionPage
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local ConfigNestedTabs = _G.LUI.Settings.Content.ConfigNestedTabs
local integrations = _G.LUI.integrations
local UI = _G.LUI.UI
local class = _G.LUI.Core.class

import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.integrations.api"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.section_page"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.nested_tabs"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local FieldType = integrations.FieldType
local Style = UI.Widgets.Style
local scaled_int = FeatureShell.scaled_int
local AVAILABLE_LINK_ENTRY_HEIGHT = 58
local AVAILABLE_TITLE_HEIGHT = 22
local AVAILABLE_LINE_EDIT_HEIGHT = 24
local AVAILABLE_GAP = 4

local function _normalize_key(value, context)
    if type(value) ~= "string" or value == "" then
        error("Integration settings tab key must be a non-empty string: " .. tostring(context))
    end

    local key = string.lower(value)
    key = key:gsub("[^%w_%-%.]+", "_")
    key = key:gsub("_+", "_")
    key = key:gsub("^_+", "")
    key = key:gsub("_+$", "")
    if key == "" then
        error("Integration settings tab key normalizes to empty: " .. tostring(value))
    end
    return key
end

local function _field_label(field)
    if type(field.label) == "string" and field.label ~= "" then
        return field.label
    end
    if type(field.description) == "string" and field.description ~= "" then
        return field.description
    end
    error("Integration setting field is missing label")
end

local function _option_label(option)
    if type(option) == "table" then
        if option.value == nil then
            error("Integration dropdown option is missing value")
        end
        if type(option.label) == "string" then
            return option.label
        end
        return tostring(option.value)
    end
    return tostring(option)
end

local function _option_value(option)
    if type(option) == "table" then
        if option.value == nil then
            error("Integration dropdown option is missing value")
        end
        return option.value
    end
    return option
end

local function _dropdown_options(field)
    if type(field.values) ~= "table" or #field.values < 1 then
        error("Integration dropdown setting is missing values")
    end

    local labels = {}
    local values = {}
    for i = 1, #field.values do
        labels[i] = _option_label(field.values[i])
        values[i] = _option_value(field.values[i])
    end
    return labels, values
end

local function _field_value(page_owner, field_key, field)
    local integration_settings = page_owner:integration_settings()
    local value = integration_settings.plugin_settings[field_key]
    if value == nil then
        error("Missing persisted integration setting: " .. page_owner.integration.key .. "/" .. field_key)
    end
    return value
end

local function _save_field_value(page_owner, field_key, value)
    local integration_settings = page_owner:integration_settings()
    integration_settings.plugin_settings[field_key] = value
end

local function _add_generated_field(page, page_owner, first_key, second_key, field_index, field)
    local field_type = field.type
    if field_type == FieldType.TITLE then
        page:add_title(_field_label(field))
        return
    end
    if field_type == FieldType.INFO then
        page:add_info(_field_label(field), field.height)
        return
    end
    if field_type == FieldType.BREAK_LINE then
        page:add_break(field.height)
        return
    end

    local storage_key = integrations.get_field_storage_key(first_key, second_key, field_index, field)
    local control_key = "integration_" .. page_owner.integration.key .. "_" .. storage_key
    local label = _field_label(field)
    local span = field.span

    if field_type == FieldType.CHECKBOX then
        page:add_checkbox(control_key, label,
            function(value)
                _save_field_value(page_owner, storage_key, value == true)
            end,
            function()
                return _field_value(page_owner, storage_key, field) == true
            end,
            span)
        return
    end

    if field_type == FieldType.DROPDOWN then
        local labels, values = _dropdown_options(field)
        page:add_dropdown(control_key, label, labels, values,
            function(value)
                _save_field_value(page_owner, storage_key, value)
            end,
            function()
                return _field_value(page_owner, storage_key, field)
            end,
            field.help,
            span)
        return
    end

    if field_type == FieldType.NUMBER then
        page:add_line_edit(control_key, label,
            function(value)
                local numeric = tonumber(value)
                if numeric ~= nil then
                    _save_field_value(page_owner, storage_key, numeric)
                end
            end,
            function()
                return tostring(_field_value(page_owner, storage_key, field))
            end,
            field.help,
            span)
        return
    end

    if field_type == FieldType.LINE_EDIT then
        page:add_line_edit(control_key, label,
            function(value)
                _save_field_value(page_owner, storage_key, value)
            end,
            function()
                return tostring(_field_value(page_owner, storage_key, field))
            end,
            field.help,
            span)
        return
    end

    if field_type == FieldType.COLOR then
        page:add_color_picker(control_key, label,
            function(value)
                _save_field_value(page_owner, storage_key, value)
            end,
            function()
                return tostring(_field_value(page_owner, storage_key, field))
            end,
            field.help,
            span)
        return
    end

    error("Unsupported integration setting field type: " .. tostring(field_type))
end

local function _collect_template_groups(integration)
    local groups = {}
    local order = {}

    integrations.walk_fields(integration.settings_template, function(first_key, second_key, field_index, field)
        local first_group = groups[first_key]
        if first_group == nil then
            first_group = {
                second_groups = {},
                second_order = {},
            }
            groups[first_key] = first_group
            order[#order + 1] = first_key
        end

        local second_group = first_group.second_groups[second_key]
        if second_group == nil then
            second_group = {}
            first_group.second_groups[second_key] = second_group
            first_group.second_order[#first_group.second_order + 1] = second_key
        end

        second_group[#second_group + 1] = {
            index = field_index,
            field = field,
        }
    end)

    return groups, order
end

local function _add_field_group(page, page_owner, first_key, second_key, fields)
    for i = 1, #fields do
        local field_entry = fields[i]
        _add_generated_field(page, page_owner, first_key, second_key, field_entry.index, field_entry.field)
    end
end

local IntegrationDetailPage = class(ConfigSectionPage)

function IntegrationDetailPage:Constructor(window, integration)
    ConfigSectionPage.Constructor(self, window, nil, nil, nil)
    self.integration = integration

    self:_build_template_tabs()
end

function IntegrationDetailPage:integration_settings()
    return self._settings.integrations[self.integration.key]
end

function IntegrationDetailPage:_build_template_tabs()
    local template = self.integration.settings_template
    if type(template) ~= "table" then
        error("Integration settings template must be a table: " .. self.integration.key)
    end

    local groups, order = _collect_template_groups(self.integration)
    local consumed_general = {}

    local general = ConfigContent(self.window, 4)
    general:add_checkbox("integration_" .. self.integration.key .. "_enabled", TR["Enabled"],
        function(value)
            self:integration_settings().enabled = value == true
        end,
        function()
            return self:integration_settings().enabled == true
        end,
        true)

    local general_first_key = nil
    if groups[TR["General"]] ~= nil then
        general_first_key = TR["General"]
    elseif groups["General"] ~= nil then
        general_first_key = "General"
    end
    local general_group = general_first_key ~= nil and groups[general_first_key] or nil
    if general_group ~= nil then
        local general_second_key = nil
        if general_group.second_groups[TR["General"]] ~= nil then
            general_second_key = TR["General"]
        elseif general_group.second_groups["General"] ~= nil then
            general_second_key = "General"
        end
        local general_fields = general_second_key ~= nil and general_group.second_groups[general_second_key] or nil
        if general_fields ~= nil then
            _add_field_group(general, self, general_first_key, general_second_key, general_fields)
            consumed_general[general_second_key] = true
        end
    end
    self:add_tab(TR["General"], "general", general)

    if general_group ~= nil then
        for second_index = 1, #general_group.second_order do
            local second_key = general_group.second_order[second_index]
            if consumed_general[second_key] ~= true then
                local page = ConfigContent(self.window, 4)
                _add_field_group(page, self, general_first_key, second_key, general_group.second_groups[second_key])
                self:add_tab(second_key, _normalize_key(second_key, self.integration.key .. "/" .. general_first_key),
                    page)
            end
        end
    end

    for first_index = 1, #order do
        local first_key = order[first_index]
        if first_key ~= "General" and first_key ~= TR["General"] then
            local first_group = groups[first_key]
            local only_second_key = first_group.second_order[1]
            if #first_group.second_order == 1 and (only_second_key == "General" or only_second_key == TR["General"]) then
                local page = ConfigContent(self.window, 4)
                _add_field_group(page, self, first_key, only_second_key, first_group.second_groups[only_second_key])
                self:add_tab(first_key, _normalize_key(first_key, self.integration.key), page)
            else
                local page = ConfigNestedTabs(self.window, UI.Widgets.LuiTabBar.position.left,
                    FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
                for second_index = 1, #first_group.second_order do
                    local second_key = first_group.second_order[second_index]
                    local second_page = ConfigContent(self.window, 3)
                    _add_field_group(second_page, self, first_key, second_key, first_group.second_groups[second_key])
                    page:add_tab(second_key, _normalize_key(second_key, self.integration.key .. "/" .. first_key),
                        second_page)
                end
                self:add_tab(first_key, "settings_" .. _normalize_key(first_key, self.integration.key), page)
            end
        end
    end
end

local AvailablePage = class(ConfigContent)

local function _layout_available_link_entry(entry)
    local width = entry.control:GetWidth()
    local title_h = scaled_int(AVAILABLE_TITLE_HEIGHT)
    local gap = scaled_int(AVAILABLE_GAP)
    local link_h = scaled_int(AVAILABLE_LINE_EDIT_HEIGHT)

    entry.title_label:SetPosition(0, 0)
    entry.title_label:SetSize(width, title_h)
    entry.link_tb:SetPosition(0, title_h + gap)
    entry.link_tb:SetSize(width, link_h)
end

local function _add_available_link_entry(page, integration)
    local row = page:add_custom("available_" .. integration.key, AVAILABLE_LINK_ENTRY_HEIGHT)
    row.title_label = UI.Widgets.LuiLabel()
    row.title_label:SetParent(row.control)
    row.title_label:SetFont(page.window.title_font)
    row.title_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    row.title_label:SetForeColor(Style.FOREGROUND)
    row.title_label:SetText(integration.title .. ": " .. TR["Not installed"])
    row.title_label:SetMouseVisible(false)

    row.link_tb = UI.Widgets.LuiLineEdit()
    row.link_tb:SetParent(row.control)
    row.link_tb:SetFont(page.window.input_font)
    row.link_tb:SetForeColor(Style.CONTROL_FOREGROUND)
    row.link_tb:SetBackColor(Style.CONTROL_BACKGROUND_READONLY)
    row.link_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    row.link_tb:SetMultiline(false)
    row.link_tb:SetReadOnly(true)
    row.link_tb:SetSelectable(true)
    row.link_tb:SetText(integration.url)
    row.link_tb:SetZOrder(2)

    row.control.SizeChanged = function()
        _layout_available_link_entry(row)
    end
    row.apply_ui_scale = function()
        row.title_label:SetFont(page.window.title_font)
        row.link_tb:SetFont(page.window.input_font)
        _layout_available_link_entry(row)
    end
    row:apply_ui_scale()
    return row
end

function AvailablePage:Constructor(window)
    ConfigContent.Constructor(self, window, 4)

    local registered = integrations.get_registered()
    local potential = integrations.get_potential()

    if #registered == 0 and #potential == 0 then
        self:add_info(TR["No integrations detected."], 34)
        return
    end

    for i = 1, #registered do
        local entry = registered[i]
        self:add_hr()
        self:add_title(entry.title .. ": " .. TR["Installed"])
        self:add_info(TR["Configure this integration in its own tab."], 34)
    end

    for i = 1, #potential do
        local entry = potential[i]
        self:add_hr()
        if type(entry.url) == "string" and entry.url ~= "" then
            _add_available_link_entry(self, entry)
        else
            self:add_title(entry.title .. ": " .. TR["Not installed"])
            local text = entry.description
            if type(text) ~= "string" or text == "" then
                text = TR["Plugin not installed."]
            end
            self:add_info(text, 34)
        end
    end
    self:add_hr()
end

local IntegrationsPage = class(ConfigTabs)
Pages.IntegrationsPage = IntegrationsPage

function IntegrationsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    self:add_tab(TR["Available"], "available", AvailablePage(window))

    local registered = integrations.get_registered()
    for i = 1, #registered do
        local entry = registered[i]
        self:add_tab(entry.title, entry.key, IntegrationDetailPage(window, entry))
    end
end

function IntegrationsPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function IntegrationsPage:load()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page._settings = self._settings
        page:load()
    end
end

function IntegrationsPage:save()
    for i = 1, #self._sub_page_order do
        local page = self._sub_pages[self._sub_page_order[i]]
        page._settings = self._settings
        page:save()
    end
end
