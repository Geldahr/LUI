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
    self._global_hide_active = false
    self._global_hide_previous_visible = nil

    self:apply_native_scaling()

    if opts.hideable == true then
        self:set_hideable(true)
    end
end

function LuiBaseWindow:apply_native_scaling(target_window)
    local target = target_window or self
    local native_scaling = UI ~= nil and UI.NativeScaling or _G.LUI_NATIVE_SCALING
    if native_scaling == nil then
        return
    end

    local use_native = native_scaling.is_enabled ~= nil and native_scaling.is_enabled() == true and
        native_scaling.has_global_scaling_api ~= nil and native_scaling.has_global_scaling_api(target) == true

    if use_native and native_scaling.enable ~= nil then
        native_scaling.enable(target)
    elseif native_scaling.disable ~= nil then
        native_scaling.disable(target)
    end
end

function LuiBaseWindow:set_hideable(enabled)
    local registry = _G.LUI_HIDABLE
    if registry == nil then
        self._hideable = false
        return
    end

    if self._hideable == true and registry.unregister ~= nil then
        registry.unregister(self)
    end

    self._hideable = enabled == true

    if self._hideable == true and registry.register ~= nil then
        registry.register(self)
    end
end

function LuiBaseWindow:is_hideable()
    return self._hideable == true
end

function LuiBaseWindow:unregister_hideable()
    local registry = _G.LUI_HIDABLE
    if self._hideable == true and registry ~= nil and registry.unregister ~= nil then
        registry.unregister(self)
    end
    self._hideable = false
end

function LuiBaseWindow:SetVisible(visible)
    visible = visible == true
    if self._global_hide_active == true and visible == true then
        return
    end
    Turbine.UI.Window.SetVisible(self, visible)
end

function LuiBaseWindow:global_hide(visible)
    if visible == true then
        local restore_visible = self._global_hide_active == true and self._global_hide_previous_visible == true
        self._global_hide_active = false
        self._global_hide_previous_visible = nil
        if restore_visible == true then
            if self.show ~= nil then
                self:show()
            else
                Turbine.UI.Window.SetVisible(self, true)
            end
        end
        return
    end

    if self._global_hide_active ~= true then
        if self.IsVisible ~= nil then
            self._global_hide_previous_visible = self:IsVisible() == true
        else
            self._global_hide_previous_visible = false
        end
    end

    self._global_hide_active = true
    if self._global_hide_previous_visible == true then
        if self.hide ~= nil then
            self:hide()
        else
            Turbine.UI.Window.SetVisible(self, false)
        end
    end
end
