import "LUI.src.UI.shortcuts"
import "LUI.src.StatusBar.common"
import "LUI.src.UI.Widgets.window"

local LUI = _G.LUI
local integrations = LUI.integrations
local State = LUI.Settings.State
local Shortcuts = LUI.UI.Shortcuts
local UI = LUI.UI
local StatusBarCommon = LUI.Features.StatusBar.Common
local Windows = LUI.Runtime.Windows

local Registry = integrations.Registry

local Potential = integrations.Potential

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

local DEFAULT_WINDOW_WIDTH = 900
local DEFAULT_WINDOW_HEIGHT = 650

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

local function _normalize_key(value)
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

local function _field_type(field)
    local value = field.type
    if value == nil then
        error("Integration settings field is missing type")
    end
    return value
end

local function _field_base_key(field, index)
    local key = _normalize_key(field.key)
    if key ~= nil then
        return key
    end

    key = _normalize_key(field.name)
    if key ~= nil then
        return key
    end

    key = _normalize_key(field.label)
    if key ~= nil then
        return key
    end

    key = _normalize_key(field.description)
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

local function _field_storage_key(first_key, second_key, index, field)
    local first = _normalize_key(tostring(first_key))
    local second = _normalize_key(tostring(second_key))
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

local function _field_default(field)
    if field.default ~= nil then
        return _copy_table(field.default)
    end

    local field_type = _field_type(field)
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

local function _walk_fields(settings_template, fn)
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

local function _is_clean_integration_settings(value)
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

local function _attach_runtime_integration_settings(settings)
    if settings ~= State.loaded_settings then
        return
    end
    if type(State.integration_settings) ~= "table" then
        State.integration_settings = {}
    end
    settings.integrations = State.integration_settings
end

local function _ensure_integration_settings(settings, key)
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

local function _action_key(entry_key, action_key)
    return "integration:" .. entry_key .. ":" .. action_key
end

local function _action_token_key(entry_key, action_key)
    return "integration." .. entry_key .. "." .. action_key
end

local function _window_is_visible(window)
    if window == nil then
        return false
    end
    return window:IsVisible() == true
end

local function _spec_dimension(spec, primary_key, alias_key, default_value, integration_key)
    local value = spec[primary_key]
    if value == nil then
        value = spec[alias_key]
    end
    if value == nil then
        value = default_value
    end

    local numeric = tonumber(value)
    if numeric == nil or numeric <= 0 then
        error("Invalid integration window " .. primary_key .. ": " .. tostring(integration_key))
    end
    return numeric
end

local function _noop()
end

local function _suppression_set(values)
    local set = {}
    if values == nil then
        return set
    end
    if type(values) ~= "table" then
        error("External integration suppression list must be a table")
    end

    for key, value in pairs(values) do
        if type(key) == "number" then
            if type(value) ~= "string" or value == "" then
                error("External integration suppression entry must be a non-empty string")
            end
            set[value] = true
        elseif value == true then
            if type(key) ~= "string" or key == "" then
                error("External integration suppression key must be a non-empty string")
            end
            set[key] = true
        end
    end
    return set
end

function integrations.import_external(global_or_spec, options)
    local spec = global_or_spec
    local global_name = nil
    if type(global_or_spec) == "string" then
        global_name = global_or_spec
        spec = options
    end

    if type(spec) ~= "table" then
        error("External integration import spec must be a table")
    end
    if global_name == nil then
        global_name = spec.global
    end
    if type(global_name) ~= "string" or global_name == "" then
        error("External integration import requires a global name")
    end
    if type(spec.imports) ~= "table" or #spec.imports < 1 then
        error("External integration import requires imports")
    end

    local suppressed_names = _suppression_set(spec.suppress_startup or spec.suppress)
    local runtime = spec.runtime
    if runtime == nil then
        runtime = {}
    elseif type(runtime) ~= "table" then
        error("External integration runtime must be a table")
    end
    local store = {}
    local suppressed = {}

    setmetatable(runtime, {
        __index = store,
        __newindex = function(_, key, value)
            if suppressed_names[key] == true and type(value) == "function" then
                suppressed[key] = value
                store[key] = _noop
                return
            end
            store[key] = value
        end,
    })

    local previous_global = _G[global_name]
    local previous_unload = Turbine.Plugin.Unload
    local previous_add_command = Turbine.Shell.AddCommand
    local previous_remove_command = Turbine.Shell.RemoveCommand
    local previous_write_line = Turbine.Shell.WriteLine

    _G[global_name] = runtime
    Turbine.Shell.AddCommand = _noop
    Turbine.Shell.RemoveCommand = _noop
    Turbine.Shell.WriteLine = _noop

    local ok, err = pcall(function()
        for i = 1, #spec.imports do
            import(spec.imports[i])
        end
    end)

    local native_unload = Turbine.Plugin.Unload
    Turbine.Plugin.Unload = previous_unload
    Turbine.Shell.AddCommand = previous_add_command
    Turbine.Shell.RemoveCommand = previous_remove_command
    Turbine.Shell.WriteLine = previous_write_line
    setmetatable(runtime, nil)

    if ok ~= true then
        _G[global_name] = previous_global
        error(err)
    end

    for key, value in pairs(store) do
        runtime[key] = value
    end
    for key, value in pairs(suppressed) do
        runtime[key] = value
    end

    return runtime, {
        suppressed = suppressed,
        unload = native_unload,
        previous_global = previous_global,
        previous_unload = previous_unload,
    }
end

local function _raw_settings()
    local settings = State.loaded_settings
    if type(settings) ~= "table" then
        error("Integration settings are unavailable")
    end
    return settings
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

local function _nested_settings(entry, integration_settings)
    local nested = {}
    _walk_fields(entry.settings_template, function(first_key, second_key, index, field)
        local field_type = _field_type(field)
        if field_type ~= FieldType.INFO and field_type ~= FieldType.TITLE and field_type ~= FieldType.BREAK_LINE then
            local field_key = _field_storage_key(first_key, second_key, index, field)
            local field_value = integration_settings.plugin_settings[field_key]
            if field_value == nil then
                field_value = _field_default(field)
            end
            _set_nested_value(nested, tostring(first_key) .. "." .. tostring(second_key) .. "." ..
                _field_callback_path(field, index), field_value)
        end
    end)
    return nested
end

local function _integration_state(integration_settings)
    return {
        enabled = integration_settings.enabled == true,
    }
end

local function _register_action(entry, action_spec)
    if type(action_spec) ~= "table" then
        error("Integration action must be a table: " .. entry.key)
    end

    local action_key = _normalize_key(action_spec.key or "open")
    if action_key == nil then
        error("Integration action is missing key: " .. entry.key)
    end

    local title = action_spec.title or entry.title
    if type(title) ~= "string" or title == "" then
        error("Integration action is missing title: " .. entry.key .. "/" .. action_key)
    end

    local icon = action_spec.icon or entry.icon
    if icon == nil then
        error("Integration action is missing icon: " .. entry.key .. "/" .. action_key)
    end

    local shortcut_key = _action_key(entry.key, action_key)
    local action = {
        key = action_key,
        title = title,
        icon = icon,
        activate = action_spec.activate,
        is_active = action_spec.is_active,
        shortcut_key = shortcut_key,
    }
    entry.actions_by_key[action_key] = action
    entry.action_order[#entry.action_order + 1] = action_key

    Shortcuts.register({
        key = shortcut_key,
        label = title,
        icon = icon,
        visible_if = function()
            return integrations.is_enabled(entry.key) == true
        end,
        get_state = function()
            return integrations.is_enabled(entry.key), integrations.is_action_active(entry.key, action_key)
        end,
        activate = function()
            integrations.activate(entry.key, action_key)
        end,
    })

    StatusBarCommon.register_status_bar_shortcut_widget({
        shortcut_key = shortcut_key,
        token_key = _action_token_key(entry.key, action_key),
        title = title,
        visible_if = function()
            return integrations.is_enabled(entry.key) == true
        end,
    })

    return action
end

function integrations.register(spec)
    if type(spec) ~= "table" then
        error("integrations.register expects a table")
    end

    local key = _normalize_key(spec.key)
    if key == nil then
        key = _normalize_key(spec.title)
    end
    if key == nil then
        error("Integration is missing key")
    end

    if type(spec.title) ~= "string" or spec.title == "" then
        error("Integration is missing title: " .. key)
    end
    if spec.icon == nil then
        error("Integration is missing icon: " .. key)
    end

    local entry = Registry.by_key[key]
    if entry == nil then
        entry = {}
        Registry.by_key[key] = entry
        Registry.order[#Registry.order + 1] = key
    end

    entry.key = key
    entry.title = spec.title
    entry.icon = spec.icon
    entry.content_window = spec.content_window or spec.window
    entry.window_width = _spec_dimension(spec, "window_width", "width", DEFAULT_WINDOW_WIDTH, key)
    entry.window_height = _spec_dimension(spec, "window_height", "height", DEFAULT_WINDOW_HEIGHT, key)
    entry.settings_template = spec.settings or spec.template or {}
    if spec.set_settings ~= nil and type(spec.set_settings) ~= "function" then
        error("Integration set_settings must be a function: " .. key)
    end
    entry.set_settings = spec.set_settings
    if spec.on_enable ~= nil and type(spec.on_enable) ~= "function" then
        error("Integration on_enable must be a function: " .. key)
    end
    if spec.on_disable ~= nil and type(spec.on_disable) ~= "function" then
        error("Integration on_disable must be a function: " .. key)
    end
    if spec.on_unload ~= nil and type(spec.on_unload) ~= "function" then
        error("Integration on_unload must be a function: " .. key)
    end
    entry.on_enable = spec.on_enable
    entry.on_disable = spec.on_disable
    entry.on_unload = spec.on_unload
    entry._applied_enabled = nil
    entry.actions_by_key = {}
    entry.action_order = {}

    if type(spec.actions) == "table" then
        for i = 1, #spec.actions do
            _register_action(entry, spec.actions[i])
        end
    else
        _register_action(entry, {
            key = "open",
            title = entry.title,
            icon = entry.icon,
        })
    end

    return entry
end

function integrations.init(arg1, arg2, arg3, arg4, arg5, arg6)
    if type(arg1) == "table" then
        return integrations.register(arg1)
    end

    if arg6 ~= nil then
        return integrations.register({
            key = arg1,
            icon = arg2,
            title = arg3,
            content_window = arg4,
            settings = arg5,
            set_settings = arg6,
        })
    end

    if type(arg5) == "function" then
        return integrations.register({
            icon = arg1,
            title = arg2,
            content_window = arg3,
            settings = arg4,
            set_settings = arg5,
        })
    end

    if arg5 ~= nil then
        return integrations.register({
            key = arg1,
            icon = arg2,
            title = arg3,
            content_window = arg4,
            settings = arg5,
        })
    end

    return integrations.register({
        icon = arg1,
        title = arg2,
        content_window = arg3,
        settings = arg4,
    })
end

function integrations.register_potential(spec)
    if type(spec) ~= "table" then
        error("integrations.register_potential expects a table")
    end

    local key = _normalize_key(spec.key)
    if key == nil then
        key = _normalize_key(spec.title)
    end
    if key == nil then
        error("Potential integration is missing key")
    end
    if type(spec.title) ~= "string" or spec.title == "" then
        error("Potential integration is missing title: " .. key)
    end

    local entry = Potential.by_key[key]
    if entry == nil then
        entry = {}
        Potential.by_key[key] = entry
        Potential.order[#Potential.order + 1] = key
    end

    entry.key = key
    entry.title = spec.title
    entry.icon = spec.icon
    entry.plugin_name = spec.plugin_name
    entry.description = spec.description
    return entry
end

function integrations.get_registered()
    local out = {}
    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        if entry ~= nil then
            out[#out + 1] = entry
        end
    end
    return out
end

function integrations.get_potential()
    local out = {}
    for i = 1, #Potential.order do
        local key = Potential.order[i]
        if Registry.by_key[key] == nil then
            local entry = Potential.by_key[key]
            if entry ~= nil then
                out[#out + 1] = entry
            end
        end
    end
    return out
end

function integrations.get_field_storage_key(first_key, second_key, index, field)
    return _field_storage_key(first_key, second_key, index, field)
end

function integrations.walk_fields(settings_template, fn)
    _walk_fields(settings_template, fn)
end

function integrations.is_enabled(key)
    local entry = Registry.by_key[key]
    if entry == nil then
        error("Unknown integration: " .. tostring(key))
    end

    local integration_settings = _ensure_integration_settings(_raw_settings(), entry.key)
    return integration_settings.enabled == true
end

function integrations.is_action_active(key, action_key)
    local entry = Registry.by_key[key]
    if entry == nil then
        error("Unknown integration: " .. tostring(key))
    end
    local action = entry.actions_by_key[action_key]
    if action == nil then
        error("Unknown integration action: " .. tostring(key) .. "/" .. tostring(action_key))
    end

    if type(action.is_active) == "function" then
        return action.is_active(entry, action) == true
    end

    return _window_is_visible(Windows.integrations[entry.key])
end

local function _has_window_geometry(geometry)
    return type(geometry) == "table" and
        type(geometry.left) == "number" and
        type(geometry.top) == "number" and
        type(geometry.width) == "number" and
        type(geometry.height) == "number"
end

local function _apply_window_geometry(entry, window)
    local integration_settings = _ensure_integration_settings(_raw_settings(), entry.key)
    if _has_window_geometry(integration_settings.window_geometry) == true then
        window:set_geometry(integration_settings.window_geometry)
    end
end

local function _capture_window_geometry(settings, key, window)
    local integration_settings = _ensure_integration_settings(settings, key)
    local geometry = window:get_geometry()
    local state = integration_settings.window_geometry
    state.left = geometry.left
    state.top = geometry.top
    state.width = geometry.width
    state.height = geometry.height
    state.tile = geometry.tile
end

function integrations.resolve_content_window(entry)
    local existing = Windows.integrations[entry.key]
    if existing ~= nil then
        return existing
    end

    local window = UI.Widgets.LuiWindow()
    window:set_title(entry.title)
    window:set_icon(entry.icon)
    window:set_margin(0, 0, 0, 0)
    window:SetSize(entry.window_width, entry.window_height)
    window:apply_settings(State.settings.global.scale)

    local content = entry.content_window
    if type(content) == "function" then
        content = content(entry, window)
    end
    if content == nil then
        error("Integration has no content window: " .. entry.key)
    end

    window:set_central_widget(content)
    _apply_window_geometry(entry, window)
    Windows.integrations[entry.key] = window
    return window
end

function integrations.toggle_content_window(entry)
    local window = integrations.resolve_content_window(entry)
    if window:IsVisible() == true then
        window:hide()
        return
    end

    window:show()
end

function integrations.activate(key, action_key)
    if integrations.is_enabled(key) ~= true then
        return
    end

    local entry = Registry.by_key[key]
    local action = entry.actions_by_key[action_key]
    if action == nil then
        error("Unknown integration action: " .. tostring(key) .. "/" .. tostring(action_key))
    end

    if type(action.activate) == "function" then
        action.activate(entry, action)
        return
    end

    integrations.toggle_content_window(entry)
end

function integrations.ensure_loaded_settings(settings)
    if type(settings) ~= "table" then
        error("Integration settings root must be a table")
    end

    _attach_runtime_integration_settings(settings)

    local source = settings.integrations
    local changed = type(source) ~= "table"
    if type(source) ~= "table" then
        source = {}
    end

    for key, _ in pairs(source) do
        if Registry.by_key[key] == nil then
            changed = true
        end
    end

    settings.integrations = {}
    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        local existing = source[key]
        local had_settings_tree = _is_clean_integration_settings(existing)
        settings.integrations[key] = existing
        local integration_settings = _ensure_integration_settings(settings, key)
        if had_settings_tree ~= true then
            changed = true
        end

        _walk_fields(entry.settings_template, function(first_key, second_key, index, field)
            local field_type = _field_type(field)
            if field_type ~= FieldType.INFO and field_type ~= FieldType.TITLE and field_type ~= FieldType.BREAK_LINE then
                local field_key = _field_storage_key(first_key, second_key, index, field)
                if integration_settings.plugin_settings[field_key] == nil then
                    integration_settings.plugin_settings[field_key] = _field_default(field)
                    changed = true
                end
            end
        end)
    end

    if settings == State.loaded_settings then
        State.integration_settings = settings.integrations
    end

    return changed
end

function integrations.capture_window_geometry(settings)
    if settings == nil then
        settings = _raw_settings()
    end
    if type(settings) ~= "table" then
        error("Integration settings root must be a table")
    end
    integrations.ensure_loaded_settings(settings)

    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local window = Windows.integrations[key]
        if window ~= nil then
            _capture_window_geometry(settings, key, window)
        end
    end
end

function integrations.apply_settings()
    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        local integration_settings = _ensure_integration_settings(_raw_settings(), key)
        local nested_settings = _nested_settings(entry, integration_settings)
        local state = _integration_state(integration_settings)

        if entry.set_settings ~= nil then
            entry.set_settings(nested_settings, state, entry)
        end

        if entry._applied_enabled ~= true and state.enabled == true then
            if entry.on_enable ~= nil then
                entry.on_enable(nested_settings, state, entry)
            end
        elseif entry._applied_enabled == true and state.enabled ~= true then
            if entry.on_disable ~= nil then
                entry.on_disable(nested_settings, state, entry)
            end
        end
        entry._applied_enabled = state.enabled

        if state.enabled ~= true then
            local window = Windows.integrations[key]
            if window ~= nil then
                window:SetWantsUpdates(false)
                window:hide()
            end
        end
    end
end

function integrations.unload()
    local settings = _raw_settings()
    integrations.ensure_loaded_settings(settings)

    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        local integration_settings = _ensure_integration_settings(settings, key)
        local nested_settings = _nested_settings(entry, integration_settings)
        local state = _integration_state(integration_settings)

        if entry.on_unload ~= nil then
            entry.on_unload(nested_settings, state, entry)
        end

        local window = Windows.integrations[key]
        if window ~= nil then
            _capture_window_geometry(settings, key, window)
            window:SetWantsUpdates(false)
            window:hide()
            window:set_central_widget(nil)
            window:unregister_hideable()
            Windows.integrations[key] = nil
        end

        entry._applied_enabled = nil
    end
end

function integrations.is_plugin_available(plugin_name)
    if Turbine == nil or Turbine.PluginManager == nil or Turbine.PluginManager.GetAvailablePlugins == nil then
        return false
    end

    local available = Turbine.PluginManager.GetAvailablePlugins()
    for _, plugin in pairs(available) do
        if plugin.Name == plugin_name then
            return true
        end
    end
    return false
end

function integrations.is_plugin_loaded(plugin_name)
    if Turbine == nil or Turbine.PluginManager == nil or Turbine.PluginManager.GetLoadedPlugins == nil then
        return false
    end

    local loaded = Turbine.PluginManager.GetLoadedPlugins()
    for _, plugin in pairs(loaded) do
        if plugin.Name == plugin_name then
            return true
        end
    end
    return false
end

function integrations.disable_plugin(plugin_name)
    if integrations.is_plugin_loaded(plugin_name) ~= true then
        return
    end
    if Turbine.PluginManager.UnloadScriptState ~= nil then
        Turbine.PluginManager.UnloadScriptState(plugin_name)
    end
end
