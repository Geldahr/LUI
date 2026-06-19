# LUI Integrations

Integrations let LUI host another plugin or plugin-like feature inside LUI instead of letting that plugin create its own launcher button, settings window, status bar UI, or independent user-facing settings.

An integration lives under `integrations/<Name>/__init__.lua` and is imported from `integrations/__init__.lua`.

```lua
import "LUI.integrations.api"
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

integrations.init({
    key = "example_plugin",
    title = "Example Plugin",
    icon = "Author/ExamplePlugin/icon.tga",
    window_width = 900,
    window_height = 650,
    content_window = function(entry, lui_window)
        local root = Turbine.UI.Control()
        root:SetSize(860, 600)

        local label = Turbine.UI.Label()
        label:SetParent(root)
        label:SetSize(300, 24)
        label:SetText("Example integration content")

        return root
    end,
    actions = {
        {
            key = "open",
            title = "Example Plugin",
            icon = "Author/ExamplePlugin/icon.tga",
        },
    },
    set_settings = function(settings, state, entry)
        ExamplePlugin.settings.show_panel = settings.General.Display.show_panel
        ExamplePlugin.settings.mode = settings.General.Display.mode
        ExamplePlugin.settings.accent = settings.General.Display.accent
    end,
    on_enable = function(settings, state, entry)
        integrations.resolve_content_window(entry)
    end,
    on_disable = function(settings, state, entry)
        local window = _G.LUI.Runtime.Windows.integrations[entry.key]
        if window ~= nil then
            window:hide()
        end
    end,
    on_unload = function(settings, state, entry)
        ExamplePlugin.shutdown()
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

If `actions` is omitted, LUI registers one default `open` action using the integration title and icon.

```lua
actions = {
    {
        key = "open",
        title = "Example Plugin",
        icon = "Author/ExamplePlugin/icon.tga",
        activate = function(entry, action)
            integrations.toggle_content_window(entry)
        end,
        is_active = function(entry, action)
            local window = _G.LUI.Runtime.Windows.integrations[entry.key]
            return window ~= nil and window:IsVisible() == true
        end,
    },
}
```

## External Plugin Integration

If the integration wraps an external plugin, do not change the external plugin source. Import only what is required, suppress startup functions that would create native surfaces, and route user-facing state through LUI.

```lua
local integrations = _G.LUI.integrations

local runtime = integrations.import_external("ExamplePlugin", {
    imports = {
        "Author.ExamplePlugin.Data",
        "Author.ExamplePlugin.Main",
    },
    suppress_startup = {
        BuildWindow = true,
        BuildLauncherButton = true,
        RegisterCallbacks = true,
    },
})
```

For external-plugin availability:

```lua
if integrations.is_plugin_available("ExamplePlugin") ~= true then
    integrations.register_potential({
        key = "example_plugin",
        title = "Example Plugin",
        icon = "Author/ExamplePlugin/icon.tga",
        plugin_name = "ExamplePlugin",
        description = "Install ExamplePlugin to enable this integration.",
    })
    return
end

integrations.disable_plugin("ExamplePlugin")
```

User-editable plugin settings belong in the LUI settings template and are applied through `set_settings`. Internal plugin state that is not exposed to the user may remain owned by the plugin.

## Content Window Rules

`content_window(entry, lui_window)` must return the root control hosted inside the LUI window. Use LUI widgets where practical. The integration title and icon are used for the LUI window and for default LUI Menu/status bar actions.

Window geometry is captured by LUI and saved in `window_geometry`; integration code should not save LUI window position or size itself.
