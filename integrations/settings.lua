local LUI = _G.LUI
local integrations = LUI.integrations
local State = LUI.Settings.State

local Schema = {}
integrations.SettingsSchema = Schema

local FieldType = {
    CHECKBOX = "checkbox",
    CheckBox = "checkbox",
    DROPDOWN = "dropdown",
    DropDown = "dropdown",
    LINE_EDIT = "line_edit",
    LineEdit = "line_edit",
    TEXT = "line_edit",
    Text = "line_edit",
    NUMBER = "number",
    Number = "number",
    COLOR = "color",
    Color = "color",
    INFO = "info",
    Info = "info",
    TITLE = "title",
    Title = "title",
    BREAK_LINE = "break",
    BreakLine = "break",
}
integrations.FieldType = FieldType

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = _copy_table(child)
    end
    return copy
end

function Schema.normalize_key(value)
    if type(value) ~= "string" then
        return nil
    end

    local key = string.lower(value)
    key = key:gsub("^%s+", "")
    key = key:gsub("%s+$", "")
    key = key:gsub("[^%w_%-%.]+", "_")
    key = key:gsub("_+", "_")
    key = key:gsub("^_+", "")
    key = key:gsub("_+$", "")
    if key == "" then
        return nil
    end
    return key
end

local function _sorted_keys(t)
    local keys = {}
    for key, _ in pairs(t) do
        if key ~= "order" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function _ordered_keys(t)
    if type(t.order) == "table" then
        local keys = {}
        local seen = {}
        for i = 1, #t.order do
            local key = t.order[i]
            if t[key] ~= nil then
                keys[#keys + 1] = key
                seen[key] = true
            end
        end
        local sorted = _sorted_keys(t)
        for i = 1, #sorted do
            local key = sorted[i]
            if seen[key] ~= true then
                keys[#keys + 1] = key
            end
        end
        return keys
    end
    return _sorted_keys(t)
end

local function _is_field_list(value)
    return type(value) == "table" and (value[1] == nil or type(value[1]) == "table") and value.type == nil
end

function Schema.field_type(field)
    local value = field.type
    if value == nil then
        error("Integration settings field is missing type")
    end
    return value
end

local function _field_base_key(field, index)
    local key = Schema.normalize_key(field.key)
    if key ~= nil then
        return key
    end

    key = Schema.normalize_key(field.name)
    if key ~= nil then
        return key
    end

    key = Schema.normalize_key(field.label)
    if key ~= nil then
        return key
    end

    key = Schema.normalize_key(field.description)
    if key ~= nil then
        return key .. "_" .. tostring(index)
    end

    error("Integration settings field is missing key, name, label, or description")
end

local function _field_callback_path(field, index)
    local path = field.path
    if path == nil then
        path = field.key
    end
    if path == nil then
        path = field.name
    end
    if path == nil then
        return _field_base_key(field, index)
    end
    if type(path) ~= "string" or path == "" then
        error("Integration settings field path must be a non-empty string")
    end
    return path
end

function Schema.field_storage_key(first_key, second_key, index, field)
    local first = Schema.normalize_key(tostring(first_key))
    local second = Schema.normalize_key(tostring(second_key))
    local base = _field_base_key(field, index)
    return first .. "." .. second .. "." .. base
end

local function _dropdown_value(option)
    if type(option) == "table" then
        if option.value == nil then
            error("Integration dropdown option is missing value")
        end
        return option.value
    end
    return option
end

function Schema.field_default(field)
    if field.default ~= nil then
        return _copy_table(field.default)
    end

    local field_type = Schema.field_type(field)
    if field_type == FieldType.CHECKBOX then
        return false
    end
    if field_type == FieldType.DROPDOWN then
        if type(field.values) ~= "table" or #field.values < 1 then
            error("Integration dropdown field is missing values")
        end
        return _dropdown_value(field.values[1])
    end
    if field_type == FieldType.NUMBER then
        return 0
    end
    if field_type == FieldType.LINE_EDIT then
        return ""
    end
    if field_type == FieldType.COLOR then
        return "#FFFFFFFF"
    end

    error("Unsupported integration setting field type: " .. tostring(field_type))
end

function Schema.walk_fields(settings_template, fn)
    if type(settings_template) ~= "table" then
        error("Integration settings template must be a table")
    end

    local first_keys = _ordered_keys(settings_template)
    for first_index = 1, #first_keys do
        local first_key = first_keys[first_index]
        local first_value = settings_template[first_key]
        if _is_field_list(first_value) == true and first_value[1] ~= nil and first_value[1].type ~= nil then
            for field_index = 1, #first_value do
                fn(first_key, "General", field_index, first_value[field_index])
            end
        else
            local second_keys = _ordered_keys(first_value)
            for second_index = 1, #second_keys do
                local second_key = second_keys[second_index]
                local fields = first_value[second_key]
                if type(fields) ~= "table" then
                    error("Integration settings section must be a field list: " .. tostring(first_key) .. "/" ..
                        tostring(second_key))
                end
                for field_index = 1, #fields do
                    fn(first_key, second_key, field_index, fields[field_index])
                end
            end
        end
    end
end

function Schema.is_clean_settings(value)
    if type(value) ~= "table" then
        return false
    end
    if type(value.enabled) ~= "boolean" then
        return false
    end
    if type(value.plugin_settings) ~= "table" then
        return false
    end
    if type(value.window_geometry) ~= "table" then
        return false
    end

    for key, _ in pairs(value) do
        if key ~= "enabled" and key ~= "plugin_settings" and key ~= "window_geometry" then
            return false
        end
    end
    return true
end

function Schema.attach_runtime_settings(settings)
    if settings ~= State.loaded_settings then
        return
    end
    if type(State.integration_settings) ~= "table" then
        State.integration_settings = {}
    end
    settings.integrations = State.integration_settings
end

function Schema.ensure_settings(settings, key)
    if type(settings.integrations) ~= "table" then
        settings.integrations = {}
    end

    local integration_settings = settings.integrations[key]
    if type(integration_settings) ~= "table" then
        integration_settings = {}
    end

    local clean_settings = {
        enabled = integration_settings.enabled == true,
        plugin_settings = integration_settings.plugin_settings,
        window_geometry = integration_settings.window_geometry,
    }
    if type(clean_settings.plugin_settings) ~= "table" then
        clean_settings.plugin_settings = {}
    end
    if type(clean_settings.window_geometry) ~= "table" then
        clean_settings.window_geometry = {}
    end

    settings.integrations[key] = clean_settings
    return clean_settings
end

local function _set_nested_value(root, path, value)
    if type(path) ~= "string" or path == "" then
        error("Integration settings path must be a non-empty string")
    end
    if string.sub(path, 1, 1) == "." or string.sub(path, -1) == "." or string.find(path, "..", 1, true) ~= nil then
        error("Integration settings path contains an empty segment: " .. path)
    end

    local current = root
    local parts = {}
    for part in string.gmatch(path, "([^%.]+)") do
        if part == "" then
            error("Integration settings path contains an empty segment: " .. path)
        end
        parts[#parts + 1] = part
    end
    if #parts == 0 then
        error("Integration settings path contains no segments: " .. path)
    end

    for i = 1, #parts - 1 do
        local part = parts[i]
        if current[part] == nil then
            current[part] = {}
        elseif type(current[part]) ~= "table" then
            error("Integration settings path collides with scalar value: " .. path)
        end
        current = current[part]
    end

    current[parts[#parts]] = value
end

function Schema.nested_settings(entry, integration_settings)
    local nested = {}
    Schema.walk_fields(entry.settings_template, function(first_key, second_key, index, field)
        local field_type = Schema.field_type(field)
        if field_type ~= FieldType.INFO and field_type ~= FieldType.TITLE and field_type ~= FieldType.BREAK_LINE then
            local field_key = Schema.field_storage_key(first_key, second_key, index, field)
            local field_value = integration_settings.plugin_settings[field_key]
            if field_value == nil then
                field_value = Schema.field_default(field)
            end
            _set_nested_value(nested, tostring(first_key) .. "." .. tostring(second_key) .. "." ..
                _field_callback_path(field, index), field_value)
        end
    end)
    return nested
end

function Schema.integration_state(integration_settings)
    return {
        enabled = integration_settings.enabled == true,
    }
end

function integrations.get_field_storage_key(first_key, second_key, index, field)
    return Schema.field_storage_key(first_key, second_key, index, field)
end

function integrations.walk_fields(settings_template, fn)
    Schema.walk_fields(settings_template, fn)
end
