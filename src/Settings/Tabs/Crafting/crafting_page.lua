import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

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

CraftingPage = class(SettingsFormPage)

function CraftingPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    self:add_title(TR["Crafting"])

    self:add_hr()
    self:add_title(TR["Recipes"])
    self:add_dropdown("crafting_display_mode", TR["Display"], DISPLAY_MODE_LABELS, DISPLAY_MODE_VALUES, DISPLAY_MODE_HELP)
    self:add_info(TR["Reload the plugin for display mode changes to take effect."])
end

function CraftingPage:load(crafting)
    if crafting == nil then
        return
    end

    self.loading = true
    self.controls.crafting_display_mode:set_value(crafting.display_mode)
    self.loading = false
end

function CraftingPage:apply(crafting)
    if crafting == nil then
        return
    end

    crafting.display_mode = self.controls.crafting_display_mode:get_value()
end

function CraftingPage:load_from_settings(s)
    self:load(s.crafting)
end

function CraftingPage:apply_to_settings(s)
    self:apply(s.crafting)
end
