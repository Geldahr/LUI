import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local scaled_int = FeatureShell.scaled_int

local DISPLAY_MODE_LABELS = {
    TR["Pages (Recommended)"],
    TR["Scroll view"],
}

local DISPLAY_MODE_VALUES = {
    "pages",
    "scroll",
}

local DISPLAY_MODE_HELP = table.concat({
    TR["Changes take effect only after reloading the plugin."],
    "",
    TR["Scroll view creates many row widgets. On large recipe lists it can increase memory usage and slow load/unload."],
}, "\n")

CraftingPage = class(ConfigTabs)

function CraftingPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = ConfigContent(window, 4)
    general:add_checkbox(TR["Enabled"], "crafting_enabled",
        function(value)
            self._settings.crafting.enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(self._settings.crafting.enabled == true)
        end)
    self:add_tab(TR["General"], "general", general)

    local recipes = ConfigContent(window, 4)
    recipes:add_dropdown(TR["Display"], "crafting_display_mode", DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES,
        function(value)
            self._settings.crafting.display_mode = value
        end,
        function(entry)
            entry:set_value(self._settings.crafting.display_mode)
        end, DISPLAY_MODE_HELP)
    recipes:add_info(TR["Reload the plugin for display mode changes to take effect."])
    recipes.controls.crafting_display_mode.visible_if = function()
        return self.controls.crafting_enabled.cb:IsChecked() == true
    end
    self:add_tab(TR["Recipes"], "recipes", recipes)
end

function CraftingPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function CraftingPage:load_from_settings(s)
    self._settings = s
    self:load()
end

function CraftingPage:apply_to_settings(s)
    self._settings = s
    self:save()
end
