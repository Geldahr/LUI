import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureSectionPage = FeatureShell.section_page_class
local configure_compact_form = FeatureShell.configure_compact_form

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

CraftingPage = class(SettingsFeatureSectionPage)

function CraftingPage:Constructor(window)
    SettingsFeatureSectionPage.Constructor(self, window, nil, nil, nil, false)

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("crafting_enabled", TR["Enabled"])
    self:add_section(TR["General"], "general", general)

    local recipes = configure_compact_form(SettingsFormPage(window), 4, nil)
    recipes:add_dropdown("crafting_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES,
        DISPLAY_MODE_HELP)
    recipes:add_info(TR["Reload the plugin for display mode changes to take effect."])
    recipes.controls.crafting_display_mode.visible_if = function()
        return self.controls.crafting_enabled.cb:IsChecked() == true
    end
    self:add_section(TR["Recipes"], "recipes", recipes)
end

function CraftingPage:load(crafting)
    self.loading = true
    self.controls.crafting_enabled.cb:SetChecked(crafting.enabled == true)
    self.controls.crafting_display_mode:set_value(crafting.display_mode)
    self.loading = false
    self:layout()
end

function CraftingPage:apply(crafting)
    crafting.enabled = self.controls.crafting_enabled.cb:IsChecked() == true
    crafting.display_mode = self.controls.crafting_display_mode:get_value()
end

function CraftingPage:load_from_settings(s)
    self:load(s.crafting)
end

function CraftingPage:apply_to_settings(s)
    self:apply(s.crafting)
end
