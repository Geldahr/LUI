import "LUI.integrations.settings"
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
local Schema = integrations.SettingsSchema
local FieldType = integrations.FieldType
local _normalize_key = Schema.normalize_key

local DEFAULT_WINDOW_WIDTH = 900
local DEFAULT_WINDOW_HEIGHT = 650
local SIZE_WINDOW = "window"
local SIZE_CONTENT = "content"

local function _action_key(entry_key, action_key)
    return "integration:" .. entry_key .. ":" .. action_key
end

local function _action_token_key(entry_key, action_key)
    return "integration." .. entry_key .. "." .. action_key
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

local function _spec_size_mode(spec, integration_key)
    local value = spec.size
    if value == nil then
        return SIZE_WINDOW
    end
    if value == SIZE_WINDOW or value == SIZE_CONTENT then
        return value
    end
    error("Invalid integration size mode: " .. tostring(integration_key))
end

local function _raw_settings()
    local settings = State.loaded_settings
    if type(settings) ~= "table" then
        error("Integration settings are unavailable")
    end
    return settings
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

local function _configure_window(entry)
    local window = entry.window
    window:set_title(entry.title)
    window:set_icon(entry.icon)
    window:set_padding(0, 0, 0, 0)
    window:SetSize(entry.window_width, entry.window_height)
end

local function _new_window(entry)
    local window = UI.Widgets.LuiWindow()
    window.show = function(self)
        if integrations.is_enabled(entry.key) ~= true then
            return
        end
        integrations.resolve_content_window(entry)
        UI.Widgets.LuiWindow.show(self)
    end
    window.resolve = function()
        return integrations.resolve_content_window(entry)
    end
    return window
end

local function _load_entry(entry)
    if entry._loaded == true then
        return entry.runtime
    end
    if entry.load == nil then
        entry._loaded = true
        return nil
    end

    local runtime = entry.load(entry, entry.window)
    entry.runtime = runtime
    entry._loaded = true
    return runtime
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
    if spec.load ~= nil and type(spec.load) ~= "function" then
        error("Integration load must be a function: " .. key)
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
    if entry.load ~= spec.load then
        entry.load = spec.load
        entry.runtime = nil
        entry._loaded = spec.load == nil
        entry._content_loaded = false
    end
    local content_window = spec.content_window or spec.window
    if entry.content_window ~= content_window then
        entry.content_window = content_window
        entry._content_loaded = false
    end
    entry.window_width = _spec_dimension(spec, "window_width", "width", DEFAULT_WINDOW_WIDTH, key)
    entry.window_height = _spec_dimension(spec, "window_height", "height", DEFAULT_WINDOW_HEIGHT, key)
    entry.size = _spec_size_mode(spec, key)
    entry.settings_template = spec.settings or spec.template or {}
    if spec.set_settings ~= nil and type(spec.set_settings) ~= "function" then
        error("Integration set_settings must be a function: " .. key)
    end
    entry.set_settings = spec.set_settings
    if spec.on_enable ~= nil or spec.on_disable ~= nil or spec.on_unload ~= nil then
        error("Integration lifecycle callbacks must be assigned on the returned window: " .. key)
    end
    entry._applied_enabled = nil
    entry.actions_by_key = {}
    entry.action_order = {}
    if entry.window == nil then
        entry.window = _new_window(entry)
    end
    Windows.integrations[key] = entry.window
    _configure_window(entry)

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

    return entry.window
end

function integrations.init(spec)
    return integrations.register(spec)
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
    entry.url = spec.url
    return entry
end

function integrations.get_registered()
    local out = {}
    for i = 1, #Registry.order do
        local key = Registry.order[i]
        out[#out + 1] = Registry.by_key[key]
    end
    return out
end

function integrations.get_potential()
    local out = {}
    for i = 1, #Potential.order do
        local key = Potential.order[i]
        if Registry.by_key[key] == nil then
            out[#out + 1] = Potential.by_key[key]
        end
    end
    return out
end

function integrations.is_enabled(key)
    local entry = Registry.by_key[key]
    if entry == nil then
        error("Unknown integration: " .. tostring(key))
    end

    local integration_settings = Schema.ensure_settings(_raw_settings(), entry.key)
    return integration_settings.enabled == true
end

function integrations.load(target)
    if type(target) == "string" then
        local entry = Registry.by_key[target]
        if entry == nil then
            error("Unknown integration: " .. tostring(target))
        end
        return _load_entry(entry)
    end

    if type(target) ~= "table" then
        error("integrations.load expects an integration key or entry")
    end
    return _load_entry(target)
end

function integrations.is_action_active(key, action_key)
    local entry = Registry.by_key[key]
    if entry == nil then
        error("Unknown integration: " .. tostring(key))
    end
    if integrations.is_enabled(key) ~= true then
        return false
    end

    local action = entry.actions_by_key[action_key]
    if action == nil then
        error("Unknown integration action: " .. tostring(key) .. "/" .. tostring(action_key))
    end
    integrations.load(entry)

    if type(action.is_active) == "function" then
        return action.is_active(entry, action) == true
    end

    return Windows.integrations[entry.key]:IsVisible() == true
end

local function _has_window_geometry(geometry)
    return type(geometry) == "table" and
        type(geometry.left) == "number" and
        type(geometry.top) == "number" and
        type(geometry.width) == "number" and
        type(geometry.height) == "number"
end

local function _apply_window_geometry(entry, window)
    local integration_settings = Schema.ensure_settings(_raw_settings(), entry.key)
    if _has_window_geometry(integration_settings.window_geometry) == true then
        window:set_geometry(integration_settings.window_geometry)
    end
end

local function _apply_window_runtime(entry)
    local window = entry.window
    window:apply_settings(State.settings.global.scale)
    if entry._geometry_applied ~= true then
        _apply_window_geometry(entry, window)
        entry._geometry_applied = true
    end
end

local function _capture_window_geometry(settings, key, window)
    local integration_settings = Schema.ensure_settings(settings, key)
    local geometry = window:get_geometry()
    local state = integration_settings.window_geometry
    state.left = geometry.left
    state.top = geometry.top
    state.width = geometry.width
    state.height = geometry.height
    state.tile = geometry.tile
end

function integrations.resolve_content_window(entry)
    local window = entry.window
    if integrations.is_enabled(entry.key) ~= true then
        return window
    end

    _apply_window_runtime(entry)
    integrations.load(entry)
    if entry._content_loaded == true then
        if entry.size == SIZE_CONTENT then
            window:size_to_content()
        end
        return window
    end

    local content = entry.content_window
    if type(content) == "function" then
        content = content(entry, window)
    end
    if content == nil then
        error("Integration has no content window: " .. entry.key)
    end

    if entry.size == SIZE_CONTENT then
        window:size_to_content(content)
    end
    window:set_central_widget(content)
    entry._content_loaded = true
    return window
end

function integrations.toggle_content_window(entry)
    if integrations.is_enabled(entry.key) ~= true then
        return
    end

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
    integrations.load(entry)

    if type(action.activate) == "function" then
        action.activate(entry, action)
        return
    end

    if type(entry.window.on_activate) == "function" then
        entry.window.on_activate(entry, action)
        return
    end

    integrations.toggle_content_window(entry)
end

function integrations.ensure_loaded_settings(settings)
    if type(settings) ~= "table" then
        error("Integration settings root must be a table")
    end

    Schema.attach_runtime_settings(settings)

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
        local had_settings_tree = Schema.is_clean_settings(existing)
        settings.integrations[key] = existing
        local integration_settings = Schema.ensure_settings(settings, key)
        if had_settings_tree ~= true then
            changed = true
        end

        Schema.walk_fields(entry.settings_template, function(first_key, second_key, index, field)
            local field_type = Schema.field_type(field)
            if field_type ~= FieldType.INFO and field_type ~= FieldType.TITLE and field_type ~= FieldType.BREAK_LINE then
                local field_key = Schema.field_storage_key(first_key, second_key, index, field)
                if integration_settings.plugin_settings[field_key] == nil then
                    integration_settings.plugin_settings[field_key] = Schema.field_default(field)
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
        _capture_window_geometry(settings, key, Windows.integrations[key])
    end
end

function integrations.apply_settings()
    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        local integration_settings = Schema.ensure_settings(_raw_settings(), key)
        local nested_settings = Schema.nested_settings(entry, integration_settings)
        local state = Schema.integration_state(integration_settings)

        _apply_window_runtime(entry)

        local was_enabled = entry._applied_enabled == true
        if state.enabled == true or was_enabled == true or entry._content_loaded == true then
            integrations.load(entry)
        end
        if entry.set_settings ~= nil and (state.enabled == true or was_enabled == true or entry._content_loaded == true) then
            entry.set_settings(nested_settings, state, entry)
        end

        if was_enabled ~= true and state.enabled == true then
            if type(entry.window.on_enable) == "function" then
                entry.window.on_enable(nested_settings, state, entry)
            end
        elseif was_enabled == true and state.enabled ~= true then
            if type(entry.window.on_disable) == "function" then
                entry.window.on_disable(nested_settings, state, entry)
            end
        end
        entry._applied_enabled = state.enabled

        if state.enabled ~= true then
            local window = Windows.integrations[key]
            window:SetWantsUpdates(false)
            window:hide()
        end
    end
end

function integrations.unload()
    local settings = _raw_settings()
    integrations.ensure_loaded_settings(settings)

    for i = 1, #Registry.order do
        local key = Registry.order[i]
        local entry = Registry.by_key[key]
        local integration_settings = Schema.ensure_settings(settings, key)
        local nested_settings = Schema.nested_settings(entry, integration_settings)
        local state = Schema.integration_state(integration_settings)

        if type(entry.window.on_unload) == "function" then
            entry.window.on_unload(nested_settings, state, entry)
        end

        local window = Windows.integrations[key]
        _capture_window_geometry(settings, key, window)
        window:SetWantsUpdates(false)
        window:hide()
        window:set_central_widget(nil)
        window:unregister_hideable()
        Windows.integrations[key] = nil

        entry._applied_enabled = nil
    end
end
