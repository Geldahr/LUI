import "LUI.src.UI.Settings.config_window"
import "LUI.src.UI.Settings.first_run_quick_setup"

-- Re-export into the UI namespace for callers.
-- NOTE: In LOTRO, `import` may run in a package environment where `_G` does not contain UI.
if UI ~= nil and UI.Settings ~= nil then
    if UI.Settings.Options ~= nil then
        UI.Options = UI.Settings.Options
    end
    if UI.Settings.ConfigWindow ~= nil then
        UI.ConfigWindow = UI.Settings.ConfigWindow
    end
    if UI.Settings.FirstRunQuickSetup ~= nil then
        UI.FirstRunQuickSetup = UI.Settings.FirstRunQuickSetup
    end
end
