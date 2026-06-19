# LUI Integrations

Integrations let LUI host another plugin or plugin-like feature inside LUI instead of letting that plugin create its own launcher button, settings window, status bar UI, or independent user-facing settings.

An integration lives under `integrations/<Name>/__init__.lua` and is imported from `integrations/__init__.lua`.

```lua
import "LUI.integrations"
import "LUI.integrations.ExamplePlugin"
```

## Runtime Shape

User-facing integration state is saved by LUI in account PluginData under `LUI_INTEGRATIONS`.

```lua
settings.integrations.example_plugin = {
    enabled = true,
    plugin_settings = {
        ["General.Display.show_panel"] = true,
    },
    window_geometry = {
        left = 200,
        top = 120,
        width = 900,
        height = 650,
        tile = nil,
    },
}
```

`settings.integrations` is still available at runtime, but it is not owned by profile saves. Profiles are saved in `LUI_PROFILES`; integration settings are saved separately in `LUI_INTEGRATIONS`.

## Registration

Use `LUI.integrations.init` or `LUI.integrations.register` from the integration file.

```lua
local integrations = _G.LUI.integrations
local FieldType = integrations.FieldType

local window = integrations.init({
    key = "example_plugin",
    title = "Example Plugin",
    icon = "Author/ExamplePlugin/icon.tga",
    size = "content",
    content_window = function(entry, lui_window)
        local root = Turbine.UI.Control()
        root:SetSize(860, 600)

        local label = Turbine.UI.Label()
        label:SetParent(root)
        label:SetSize(300, 24)
        label:SetText("Example integration content")

        return root
    end,
    set_settings = function(settings, state, entry)
        ExamplePlugin.settings.show_panel = settings.General.Display.show_panel
        ExamplePlugin.settings.mode = settings.General.Display.mode
        ExamplePlugin.settings.accent = settings.General.Display.accent
    end,
    settings = {
        order = { "General" },
        ["General"] = {
            order = { "Display" },
            ["Display"] = {
                {
                    key = "show_panel",
                    type = FieldType.CheckBox,
                    label = "Show panel",
                    default = true,
                },
                {
                    key = "mode",
                    type = FieldType.DropDown,
                    label = "Mode",
                    values = {
                        { label = "Compact", value = "compact" },
                        { label = "Detailed", value = "detailed" },
                    },
                    default = "compact",
                },
                {
                    key = "accent",
                    type = FieldType.Color,
                    label = "Accent color",
                    default = Turbine.UI.Color(1, 0.2, 0.6, 1),
                },
            },
        },
    },
})

window:set_resizable(window.RESIZE_BOTH)
window:set_minimum_size(520, 360)
window:set_padding(6)

window.on_enable = function(settings, state, entry)
    integrations.resolve_content_window(entry)
end

window.on_disable = function(settings, state, entry)
    local real_window = _G.LUI.Runtime.Windows.integrations[entry.key]
    if real_window ~= nil then
        real_window:hide()
    end
end

window.on_unload = function(settings, state, entry)
    ExamplePlugin.shutdown()
end

window.on_activate = function()
    window:toggle()
end

window.on_show = function()
    ExamplePlugin.refresh()
end

window.on_hide = function()
    ExamplePlugin.pause()
end

local menu = window:get_menu_bar():add_menu("Example")
menu:add_action({
    text = "Refresh",
    action = function()
        ExamplePlugin.refresh()
    end,
})
```

## Settings Template

The settings template is a two-level tab tree:

```lua
settings = {
    ["First layer tab"] = {
        ["Second layer tab"] = {
            {
                key = "setting_key",
                type = FieldType.DropDown,
                label = "Setting label",
                values = {
                    { label = "One", value = "1" },
                    { label = "Two", value = "2" },
                },
                default = "1",
            },
            {
                type = FieldType.BreakLine,
            },
        },
    },
}
```

Supported field types:

- `FieldType.CheckBox`
- `FieldType.DropDown`
- `FieldType.LineEdit`
- `FieldType.Number`
- `FieldType.Color`
- `FieldType.Info`
- `FieldType.Title`
- `FieldType.BreakLine`

Generated field values are passed to `set_settings(settings, state, entry)` as a nested table:

```lua
settings.General.Display.show_panel
settings.General.Display.mode
settings.General.Display.accent
```

If a field needs to write to a different callback path, set `path`:

```lua
{
    key = "text_color",
    path = "Text.Color.rgb_value",
    type = FieldType.Color,
    label = "Text color",
}
```

Then `set_settings` receives:

```lua
settings.General.Display.Text.Color.rgb_value
```

## Actions

Each action becomes an LUI shortcut. Users can place that shortcut in the LUI Menu or status bar through the existing LUI button configuration. The action is visible only when the integration is enabled.

If `actions` is omitted, LUI registers one default `open` action using the integration title and icon. Set `window.on_activate` to customize what that default action does.

```lua
local window = integrations.init({
    key = "example_plugin",
    title = "Example Plugin",
    icon = "Author/ExamplePlugin/icon.tga",
    content_window = build_content,
    actions = {
        {
            key = "refresh",
            title = "Refresh Example Plugin",
            icon = "Author/ExamplePlugin/refresh.tga",
            activate = function(entry, action)
                ExamplePlugin.refresh()
            end,
        },
    },
})

window.on_activate = function()
    window:toggle()
end
```

`integrations.init` returns the integration `LuiWindow`, so integration code can configure the window immediately. The window exists immediately; integration content is built the first time the window is resolved or shown.

Use `size = "content"` when the returned root control has a fixed or preferred size. LUI reads `content:GetSize()` before attaching the content to the window, then sizes the outer window around that content plus padding, title bar, divider, and border.

```lua
local bar = window:get_menu_bar()
local file = bar:add_menu("File")
local close_action = file:add_action({
    text = "Close",
    action = function()
        window:hide()
    end,
})
close_action:set_enabled(true)

window:set_padding(0, 0, 0, 0)
window:enable_maximize(false)
window.on_show = function()
    ExamplePlugin.refresh()
end
window.on_hide = function()
    ExamplePlugin.pause()
end
```

Additional actions can still provide their own state:

```lua
actions = {
    {
        key = "refresh",
        title = "Refresh Example Plugin",
        icon = "Author/ExamplePlugin/refresh.tga",
        activate = function(entry, action)
            ExamplePlugin.refresh()
        end,
        is_active = function(entry, action)
            return ExamplePlugin.is_refreshing == true
        end,
    },
}
```

## External Plugin Integration

If the integration wraps an external plugin, do not change the external plugin source. Import only what is required, suppress startup functions that would create native surfaces, and route user-facing state through LUI.

```lua
local integrations = _G.LUI.integrations

local runtime, external = integrations.load_external({
    key = "example_plugin",
    title = "Example Plugin",
    icon = "Author/ExamplePlugin/icon.tga",
    plugin_name = "ExamplePlugin",
    description = "Install ExamplePlugin to enable this integration.",
    namespace = "ExamplePlugin",
    imports = {
        "Author.ExamplePlugin.Data",
        "Author.ExamplePlugin.Main",
    },
    suppress_startup = {
        BuildWindow = true,
        BuildLauncherButton = true,
        RegisterCallbacks = true,
    },
    unload_plugins = {
        "ExamplePluginHelper",
    },
    required_runtime = {
        "LoadSettings",
    },
    unload_method = "UnloadIntegration",
    setup = function(plugin)
        plugin.BuildContent = function(parent)
            local root = Turbine.UI.Control()
            root:SetParent(parent)
            root:SetSize(500, 300)
            return root
        end
    end,
})

if runtime == nil then
    return
end
```

`load_external` checks `integrations.exists(plugin_name)` before importing anything, unloads native plugin script states when they appear loaded, protected-imports the requested files, validates required runtime functions, wires `unload_method` when provided, runs `setup` when provided, and registers a potential integration instead of registering a live integration when the external plugin cannot be imported.

Use `integrations.exists(plugin_name)` directly only when an integration needs custom behavior before calling the generic loader.

User-editable plugin settings belong in the LUI settings template and are applied through `set_settings`. Internal plugin state that is not exposed to the user may remain owned by the plugin.

## Content Window Rules

`content_window(entry, lui_window)` must return the root control hosted inside the LUI window. Use LUI widgets where practical. The integration title and icon are used for the LUI window and for default LUI Menu/status bar actions.

Window geometry is captured by LUI and saved in `window_geometry`; integration code should not save LUI window position or size itself.
