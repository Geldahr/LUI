import "Turbine.UI"

import "LUI.src.UI.hidable"
import "LUI.src.UI.native_scaling"

---@class LuiBaseWindow : Turbine.UI.Window
LuiBaseWindow = class(Turbine.UI.Window)

function LuiBaseWindow:Constructor(opts)
    Turbine.UI.Window.Constructor(self)

    if type(opts) ~= "table" then
        opts = {}
    end

    self._hideable = false
    self._hide_key = nil

    self:apply_native_scaling()

    if opts.hideable == true then
        self:set_hideable(true, opts.hide_key)
    end
end

function LuiBaseWindow:apply_native_scaling(target_window)
    local target = target_window or self
    local native_scaling = UI ~= nil and UI.NativeScaling or _G.LUI_NATIVE_SCALING
    if native_scaling ~= nil and native_scaling.disable ~= nil then
        native_scaling.disable(target)
    end
end

function LuiBaseWindow:set_hideable(enabled, hide_key)
    local registry = _G.LUI_HIDABLE
    if registry == nil then
        self._hideable = false
        self._hide_key = nil
        return
    end

    if self._hideable == true and registry.unregister ~= nil then
        registry.unregister(self)
    end

    self._hideable = enabled == true
    self._hide_key = self._hideable and hide_key or nil

    if self._hideable == true and registry.register ~= nil then
        registry.register(self, self._hide_key)
    end
end

function LuiBaseWindow:is_hideable()
    return self._hideable == true
end

function LuiBaseWindow:get_hide_key()
    return self._hide_key
end

function LuiBaseWindow:unregister_hideable()
    local registry = _G.LUI_HIDABLE
    if self._hideable == true and registry ~= nil and registry.unregister ~= nil then
        registry.unregister(self)
    end
    self._hideable = false
    self._hide_key = nil
end
