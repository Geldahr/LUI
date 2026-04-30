import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local ICON_SIZE_LABELS = {
    TR["Small (32)"],
    TR["Large (40)"],
}

local ICON_SIZE_VALUES = {
    32,
    40,
}

DropsPage = class(SettingsFormPage)

function DropsPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    local flow_labels = { TR["Latest at top"], TR["Latest at bottom"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }

    self.refresh_preview = function()
        self.window:update_drops_preview()
    end

    self:add_title(TR["Drops"])

    self:add_hr()
    self:add_title(TR["General"])
    self:add_checkbox("drops_enabled", TR["Enabled"], true)
    self:add_text("drops_visible_duration", TR["Visible duration (s)"])
    self:add_text("drops_width", TR["Width"])
    self:add_text("drops_rows", TR["Rows"])
    self:add_dropdown("drops_icon_size", TR["Icon Size"], ICON_SIZE_LABELS, ICON_SIZE_VALUES)
    self:add_dropdown("drops_flow", TR["Order"], flow_labels, flow_values)
    self:add_checkbox("drops_animations_enabled", TR["Animations"], true)

    self:add_break()
    self:add_info(TR["Carry-alls may bypass inventory item events. Those drops can appear without icon or hover and will be shown as text only."], 42)

    self:add_hr()
    self:add_title(TR["HUD"])
    self:add_text("drops_hud_background_opacity", TR["Background opacity (0..1)"])
    self:add_text("drops_hud_background_color", TR["Background color"], true)

    self:add_hr()
    self:add_title(TR["Item"])
    self:add_text("drops_item_background_opacity", TR["Background opacity (0..1)"])
    self:add_text("drops_item_background_color", TR["Background color"], true)

    self:add_hr()
    self:add_title(TR["Preview"])
    self:add_custom("drops_preview", 136)
end

function DropsPage:load(drops, ui)
    self.loading = true
    self.controls.drops_enabled.cb:SetChecked(drops.enabled == true)
    self.controls.drops_visible_duration.tb:SetText(tostring(drops.visible_duration))
    self.controls.drops_width.tb:SetText(tostring(drops.width))
    self.controls.drops_rows.tb:SetText(tostring(drops.rows))
    self.controls.drops_icon_size:set_value(drops.icon_size)
    self.controls.drops_flow:set_value(drops.flow)
    self.controls.drops_animations_enabled.cb:SetChecked(drops.animations_enabled == true)
    self.controls.drops_hud_background_opacity.tb:SetText(tostring(drops.hud.background_opacity))
    self.controls.drops_hud_background_color.tb:SetText(ui.color_to_hex(drops.hud.background_color))
    self.controls.drops_item_background_opacity.tb:SetText(tostring(drops.item.background_opacity))
    self.controls.drops_item_background_color.tb:SetText(ui.color_to_hex(drops.item.background_color))
    self.loading = false
end

local function _apply_color(ui, dest, hex)
    local c = ui.hex_to_color(hex)
    if c ~= nil then
        dest.R, dest.G, dest.B = c.R, c.G, c.B
    end
end

function DropsPage:apply(drops, ui)
    drops.enabled = self.controls.drops_enabled.cb:IsChecked() == true

    local visible_duration = tonumber(self.controls.drops_visible_duration.tb:GetText())
    if visible_duration ~= nil then
        drops.visible_duration = visible_duration
    end

    local width = tonumber(self.controls.drops_width.tb:GetText())
    if width ~= nil then
        drops.width = width
    end

    local rows = tonumber(self.controls.drops_rows.tb:GetText())
    if rows ~= nil then
        drops.rows = rows
    end

    drops.icon_size = self.controls.drops_icon_size:get_value()
    drops.flow = self.controls.drops_flow:get_value()
    drops.animations_enabled = self.controls.drops_animations_enabled.cb:IsChecked() == true

    local hud_opacity = tonumber(self.controls.drops_hud_background_opacity.tb:GetText())
    if hud_opacity ~= nil then
        drops.hud.background_opacity = hud_opacity
    end
    _apply_color(ui, drops.hud.background_color, self.controls.drops_hud_background_color.tb:GetText())

    local item_opacity = tonumber(self.controls.drops_item_background_opacity.tb:GetText())
    if item_opacity ~= nil then
        drops.item.background_opacity = item_opacity
    end
    _apply_color(ui, drops.item.background_color, self.controls.drops_item_background_color.tb:GetText())
end

function DropsPage:load_from_settings(s, ui)
    self:load(s.drops, ui)
end

function DropsPage:apply_to_settings(s, ui)
    self:apply(s.drops, ui)
end
