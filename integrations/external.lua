local integrations = _G.LUI.integrations

local function _noop()
end

local function _plugin_manager_list(method_name)
    if Turbine == nil or Turbine.PluginManager == nil then
        return nil
    end

    local manager = Turbine.PluginManager
    local method = manager[method_name]
    if method == nil then
        return nil
    end

    local ok, result = pcall(function()
        return method()
    end)
    if ok == true and type(result) == "table" then
        return result
    end

    ok, result = pcall(function()
        return method(manager)
    end)
    if ok == true and type(result) == "table" then
        return result
    end

    return nil
end

local function _available_plugin(plugin_name)
    local available = _plugin_manager_list("GetAvailablePlugins")
    if available == nil then
        return nil
    end

    for _, plugin in pairs(available) do
        if plugin.Name == plugin_name then
            return plugin
        end
    end
    return nil
end

local function _plugin_manager_unload(plugin_name)
    local method = Turbine.PluginManager.UnloadScriptState
    if method == nil then
        return false
    end

    local dot_ok = pcall(function()
        method(plugin_name)
    end)

    local colon_ok = pcall(function()
        method(Turbine.PluginManager, plugin_name)
    end)
    return dot_ok == true or colon_ok == true
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

local function _import_external(namespace, spec)
    if type(namespace) ~= "string" or namespace == "" then
        error("External integration import requires a namespace")
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

    local previous_namespace_value = _G[namespace]
    local previous_unload = Turbine.Plugin.Unload
    local previous_add_command = Turbine.Shell.AddCommand
    local previous_remove_command = Turbine.Shell.RemoveCommand
    local previous_write_line = Turbine.Shell.WriteLine

    _G[namespace] = runtime
    Turbine.Shell.AddCommand = _noop
    Turbine.Shell.RemoveCommand = _noop
    Turbine.Shell.WriteLine = _noop

    local ok, err = pcall(function()
        for i = 1, #spec.imports do
            import(spec.imports[i])
        end
    end)

    local imported_runtime = _G[namespace]
    local native_unload = Turbine.Plugin.Unload
    Turbine.Plugin.Unload = previous_unload
    Turbine.Shell.AddCommand = previous_add_command
    Turbine.Shell.RemoveCommand = previous_remove_command
    Turbine.Shell.WriteLine = previous_write_line
    setmetatable(runtime, nil)

    if ok ~= true then
        _G[namespace] = previous_namespace_value
        error(err)
    end

    if imported_runtime ~= runtime then
        if type(imported_runtime) ~= "table" then
            _G[namespace] = previous_namespace_value
            error("External integration import did not create table namespace: " .. namespace)
        end

        runtime = imported_runtime
        for key, _ in pairs(suppressed_names) do
            local value = runtime[key]
            if type(value) == "function" then
                suppressed[key] = value
                runtime[key] = _noop
            end
        end
    else
        for key, value in pairs(store) do
            runtime[key] = value
        end
        for key, value in pairs(suppressed) do
            runtime[key] = value
        end
    end

    return runtime, {
        suppressed = suppressed,
        unload = native_unload,
        previous_namespace_value = previous_namespace_value,
        previous_unload = previous_unload,
    }
end

local function _register_potential(spec)
    integrations.register_potential({
        key = spec.key,
        title = spec.title,
        icon = spec.icon,
        plugin_name = spec.plugin_name,
        description = spec.description or ("Install " .. spec.plugin_name .. " to enable this integration."),
        url = spec.url,
    })
end

local function _unload_plugins(spec)
    integrations.unload_plugin(spec.plugin_name)

    local unload_plugins = spec.unload_plugins
    if unload_plugins == nil then
        return
    end
    if type(unload_plugins) ~= "table" then
        error("External integration unload_plugins must be a table")
    end

    for key, value in pairs(unload_plugins) do
        local plugin_name = value
        if type(key) ~= "number" and value == true then
            plugin_name = key
        end
        if type(plugin_name) ~= "string" or plugin_name == "" then
            error("External integration unload plugin entry must be a non-empty string")
        end
        integrations.unload_plugin(plugin_name)
    end
end

local function _has_required_runtime(spec, runtime)
    local required = spec.required_runtime
    if required == nil then
        return true
    end
    if type(required) ~= "table" then
        error("External integration required_runtime must be a table")
    end

    for key, value in pairs(required) do
        local function_name = value
        if type(key) ~= "number" and value == true then
            function_name = key
        end
        if type(function_name) ~= "string" or function_name == "" then
            error("External integration required runtime entry must be a non-empty string")
        end
        if type(runtime[function_name]) ~= "function" then
            return false
        end
    end

    return true
end

local function _install_unload_method(spec, runtime, external)
    local method_name = spec.unload_method
    if method_name == nil then
        return
    end
    if type(method_name) ~= "string" or method_name == "" then
        error("External integration unload_method must be a non-empty string")
    end

    runtime[method_name] = function()
        external.unload()
    end
end

local function _setup_runtime(spec, runtime, external)
    _install_unload_method(spec, runtime, external)
    if spec.setup ~= nil then
        if type(spec.setup) ~= "function" then
            error("External integration setup must be a function")
        end
        spec.setup(runtime, external)
    end
end

function integrations.load_external(spec)
    if type(spec) ~= "table" then
        error("integrations.load_external expects a table")
    end
    if type(spec.plugin_name) ~= "string" or spec.plugin_name == "" then
        error("External integration is missing plugin_name")
    end

    if integrations.exists(spec.plugin_name) ~= true then
        _register_potential(spec)
        return nil
    end

    _unload_plugins(spec)

    local namespace = spec.namespace or spec.plugin_name
    local runtime, external = _import_external(namespace, spec)
    if _has_required_runtime(spec, runtime) ~= true then
        local previous_runtime = external.previous_namespace_value
        if type(previous_runtime) == "table" and _has_required_runtime(spec, previous_runtime) == true then
            runtime = previous_runtime
            _G[namespace] = runtime
        else
            _G[namespace] = previous_runtime
            error("External integration import did not define required runtime for: " .. spec.plugin_name)
        end
    end

    _setup_runtime(spec, runtime, external)
    return runtime, external
end

function integrations.prepare_external(spec)
    if type(spec) ~= "table" then
        error("integrations.prepare_external expects a table")
    end
    if type(spec.plugin_name) ~= "string" or spec.plugin_name == "" then
        error("External integration is missing plugin_name")
    end

    if integrations.exists(spec.plugin_name) ~= true then
        _register_potential(spec)
        return false
    end

    return true
end

function integrations.exists(plugin_name)
    if Turbine == nil or Turbine.PluginManager == nil then
        return false
    end

    return _available_plugin(plugin_name) ~= nil
end

function integrations.is_plugin_available(plugin_name)
    return integrations.exists(plugin_name)
end

function integrations.is_plugin_loaded(plugin_name)
    if Turbine == nil or Turbine.PluginManager == nil then
        return false
    end

    local loaded = _plugin_manager_list("GetLoadedPlugins")
    if loaded == nil then
        return false
    end

    for _, plugin in pairs(loaded) do
        if plugin.Name == plugin_name then
            return true
        end
    end
    return false
end

function integrations.unload_plugin_if_loaded(plugin_name)
    if integrations.is_plugin_loaded(plugin_name) ~= true then
        return false
    end
    return _plugin_manager_unload(plugin_name)
end

function integrations.unload_plugin(plugin_name)
    if Turbine == nil or Turbine.PluginManager == nil then
        return false
    end
    return _plugin_manager_unload(plugin_name)
end
