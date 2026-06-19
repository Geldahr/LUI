local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local ConfigNestedTabs = _G.LUI.Settings.Content.ConfigNestedTabs
local integrations = _G.LUI.integrations
local class = _G.LUI.Core.class
import "LUI.integrations.api"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.nested_tabs"

local FieldType = integrations.FieldType
local Placement = integrations.Placement

local PLACEMENT_LABELS = {
    TR["None"],
    TR["LUI Menu"],
    TR["Status Bar"],
}

local PLACEMENT_VALUES = {
    Placement.NONE,
    Placement.LUI_MENU,
    Placement.STATUS_BAR,
}

local function _normalize_key(value)
    local key = string.lower(tostring(value))
    key = key:gsub("[^%w_%-%.]+", "_")
    key = key:gsub("_+", "_")
    key = key:gsub("^_+", "")
    key = key:gsub("_+$", "")
    if key == "" then
        return "settings"
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
    if type(field.key) == "string" and field.key ~= "" then
        return field.key
    end
    error("Integration setting field is missing label")
end

local function _option_label(option)
    if type(option) == "table" then
        if type(option.label) == "string" then
            return option.label
        end
        return tostring(option.value)
    end
    return tostring(option)
end

local function _option_value(option)
    if type(option) == "table" then
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

local function _field_default(field)
    if field.default ~= nil then
        return field.default
    end

    if field.type == FieldType.CHECKBOX then
        return false
    end
    if field.type == FieldType.DROPDOWN then
        return _option_value(field.values[1])
    end
    if field.type == FieldType.NUMBER then
        return 0
    end
    if field.type == FieldType.LINE_EDIT then
        return ""
    end
    if field.type == FieldType.COLOR then
        return "#FFFFFFFF"
    end
    return nil
end

local function _field_value(page_owner, field_key, field)
    local integration_settings = page_owner:integration_settings()
    local value = integration_settings.settings[field_key]
    if value == nil then
        return _field_default(field)
    end
    return value
end

local function _save_field_value(page_owner, field_key, value)
    local integration_settings = page_owner:integration_settings()
    integration_settings.settings[field_key] = value
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
                _save_field_value(page_owner, storage_key, tostring(value or ""))
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
                _save_field_value(page_owner, storage_key, tostring(value or ""))
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

local IntegrationDetailPage = class(ConfigTabs)

function IntegrationDetailPage:Constructor(window, integration)
    ConfigTabs.Constructor(self, window)
    self.integration = integration

    local general = ConfigContent(window, 4)
    general:add_checkbox("integration_" .. integration.key .. "_enabled", TR["Enabled"],
        function(value)
            self:integration_settings().enabled = value == true
        end,
        function()
            return self:integration_settings().enabled == true
        end,
        true)
    general:add_dropdown("integration_" .. integration.key .. "_placement", TR["Button"], PLACEMENT_LABELS,
        PLACEMENT_VALUES,
        function(value)
            self:integration_settings().placement = value
        end,
        function()
            return self:integration_settings().placement
        end,
        nil,
        true)
    self:add_tab(TR["General"], "general", general)

    self:_build_template_tabs()
end

function IntegrationDetailPage:integration_settings()
    return self._settings.integrations[self.integration.key]
end

function IntegrationDetailPage:_build_template_tabs()
    local template = self.integration.settings_template
    if type(template) ~= "table" then
        return
    end

    local first_pages = {}
    integrations.walk_fields(template, function(first_key, second_key, field_index, field)
        local first_page = first_pages[first_key]
        if first_page == nil then
            first_page = {
                tabs = ConfigNestedTabs(self.window),
                second_pages = {},
            }
            first_pages[first_key] = first_page
            self:add_tab(tostring(first_key), "settings_" .. _normalize_key(first_key), first_page.tabs)
        end

        local second_page = first_page.second_pages[second_key]
        if second_page == nil then
            second_page = ConfigContent(self.window, 4)
            first_page.second_pages[second_key] = second_page
            first_page.tabs:add_tab(tostring(second_key), _normalize_key(second_key), second_page)
        end

        _add_generated_field(second_page, self, first_key, second_key, field_index, field)
    end)
end

local PotentialPage = class(ConfigContent)

function PotentialPage:Constructor(window)
    ConfigContent.Constructor(self, window, 4)

    local potential = integrations.get_potential()
    if #potential == 0 then
        self:add_info(TR["No integrations detected."], 34)
        return
    end

    for i = 1, #potential do
        local entry = potential[i]
        self:add_title(entry.title)
        local text = entry.description
        if type(text) ~= "string" or text == "" then
            text = TR["Plugin not installed."]
        end
        self:add_info(text, 34)
    end
end

local IntegrationsPage = class(ConfigTabs)
Pages.IntegrationsPage = IntegrationsPage

function IntegrationsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false

    local registered = integrations.get_registered()
    for i = 1, #registered do
        local entry = registered[i]
        self:add_tab(entry.title, entry.key, IntegrationDetailPage(window, entry))
    end

    local potential = integrations.get_potential()
    if #registered == 0 or #potential > 0 then
        self:add_tab(TR["Available"], "available", PotentialPage(window))
    end
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
