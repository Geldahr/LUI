import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local configure_compact_form = FeatureShell.configure_compact_form
local module_for_page = FeatureShell.module_for_page
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

CraftingPage = class(SettingsTabbedPage)

function CraftingPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))

    local general = configure_compact_form(SettingsFormPage(window), 4, nil)
    general:add_checkbox("crafting_enabled", TR["Enabled"])
    self:add_sub_page(TR["General"], module_for_page("general", general))

    local recipes = configure_compact_form(SettingsFormPage(window), 4, nil)
    recipes:add_dropdown("crafting_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES,
        DISPLAY_MODE_HELP)
    recipes:add_info(TR["Reload the plugin for display mode changes to take effect."])
    recipes.controls.crafting_display_mode.visible_if = function()
        return self.controls.crafting_enabled.cb:IsChecked() == true
    end
    self:add_sub_page(TR["Recipes"], module_for_page("recipes", recipes))
end

function CraftingPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
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
