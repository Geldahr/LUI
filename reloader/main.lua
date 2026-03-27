import "Turbine";
import "Turbine.UI";
import "LUI.src.Utils.class"

local function _log(message)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#33C1FF>LUIReloader</rgb>: " .. tostring(message or ""))
    end
end

local function _register_button()
    local _, err = LUI.api.StatusBar.add({
        key = "reloader",
        title = "LUI Reloader button",
        description = "Button to reload the LUI plugin",
        image = 0x411BBF59,
        command = "/luireloader",
    })

    if err ~= nil then
        _log("Failed to register status bar entry: " .. tostring(err))
    end
end

_G.reload_command = Turbine.ShellCommand()

ReloaderWindow=class(Turbine.UI.Window);
function ReloaderWindow:Constructor()
	Turbine.UI.Window.Constructor(self);
    self:SetVisible(false)

    -- Async reload
    self.Update=function()
        if self:IsVisible() then
            self:SetWantsUpdates(false);
            Turbine.PluginManager.UnloadScriptState("LUI")
            Turbine.PluginManager.LoadPlugin("LUI")
            _register_button()
        end
    end
end
_G.reloader_async = ReloaderWindow();

function reload_command:Execute(_, arguments)
    _G.reloader_async:SetVisible(true)
    _G.reloader_async:SetWantsUpdates(true)
end

Turbine.Shell.AddCommand("LUIReloader", reload_command)

import "LUI.api"

_register_button()
