import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Tabs.tabbed_page"
import "LUI.src.Settings.Tabs.form_page"

local SettingsTabbedPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.tabbed_page) or
    _G.SettingsTabbedPage or SettingsTabbedPage
local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage
local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local SettingsFeatureNestedPage = FeatureShell.nested_page_class
local configure_compact_form = FeatureShell.configure_compact_form
local add_compact_row_break = FeatureShell.add_compact_row_break
local module_for_page = FeatureShell.module_for_page
local scaled_int = FeatureShell.scaled_int
local PREVIEW_GAP = 10
local PREVIEW_MIN_TOP_HEIGHT = 120
local PREVIEW_MIN_HEIGHT = 100

DropsPage = class(SettingsTabbedPage)

function DropsPage:Constructor(window)
    SettingsTabbedPage.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self._preview_default_height = 136
    self.controls = self.controls or {}

    local flow_labels = { TR["Latest at top"], TR["Latest at bottom"] }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }
    local align_labels = { TR["Top"], TR["Bottom"] }
    local align_values = { LUI_ENUMS.vertical_align.TOP, LUI_ENUMS.vertical_align.BOTTOM }
    local side_labels = { TR["Left"], TR["Right"] }
    local side_values = { LUI_ENUMS.side.LEFT, LUI_ENUMS.side.RIGHT }
    local refresh_preview = function()
        window:update_drops_preview()
    end

    local general = configure_compact_form(SettingsFormPage(window), 4, refresh_preview)
    general:add_checkbox("drops_enabled", TR["Enabled"], true)
    add_compact_row_break(general)
    general:add_text("drops_visible_duration", TR["Visible duration (s)"])
    general:add_info(TR["Carry-alls may bypass inventory item events. Those drops can appear without icon or hover and will be shown as text only."], 42)
    self:add_sub_page(TR["General"], module_for_page("general", general))

    local layout = configure_compact_form(SettingsFormPage(window), 4, refresh_preview)
    layout:add_text("drops_width", TR["Width"])
    layout:add_text("drops_rows", TR["Rows"])
    layout:add_text("drops_icon_size", TR["Icon Size"])
    add_compact_row_break(layout)
    layout:add_dropdown("drops_flow", TR["Order"], flow_labels, flow_values)
    layout:add_dropdown("drops_align", TR["Align"], align_labels, align_values)
    layout:add_dropdown("drops_icon_side", TR["Icon position"], side_labels, side_values)
    self:add_sub_page(TR["Layout"], module_for_page("layout", layout))

    local hud = configure_compact_form(SettingsFormPage(window), 3, refresh_preview)
    hud:add_text("drops_hud_background_opacity", TR["Background opacity (0..1)"])
    hud:add_text("drops_hud_background_color", TR["Background color"], true)

    local item = configure_compact_form(SettingsFormPage(window), 3, refresh_preview)
    item:add_text("drops_item_background_opacity", TR["Background opacity (0..1)"])
    item:add_text("drops_item_background_color", TR["Background color"], true)

    local colors = SettingsFeatureNestedPage(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    colors:add_sub_page(TR["HUD"], module_for_page("hud", hud))
    colors:add_sub_page(TR["Item"], module_for_page("item", item))
    self:add_sub_page(TR["Colors"], module_for_page("colors", colors))

    local motion = configure_compact_form(SettingsFormPage(window), 4, refresh_preview)
    motion:add_checkbox("drops_animations_enabled", TR["Animations"], true)
    add_compact_row_break(motion)
    motion:add_text("drops_move_duration", TR["Move duration (ms)"])
    self:add_sub_page(TR["Motion"], module_for_page("motion", motion))

    self.preview_holder = {
        kind = "custom",
        key = "drops_preview",
        height = self._preview_default_height,
    }
    self.preview_holder.control = Turbine.UI.Control()
    self.preview_holder.control:SetParent(self)
    self.preview_holder.control:SetMouseVisible(false)
    self.controls.drops_preview = self.preview_holder
end

function DropsPage:apply_ui_scale()
    SettingsTabbedPage.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end

function DropsPage:layout()
    local width, height = self:GetSize()
    if width == nil or height == nil or width < 1 or height < 1 then
        return
    end

    local preview_h = self.preview_holder.height or self._preview_default_height
    local preview_gap = scaled_int(PREVIEW_GAP)
    local min_top_h = scaled_int(PREVIEW_MIN_TOP_HEIGHT)
    local top_h = height - preview_h - preview_gap
    if top_h < min_top_h then
        top_h = min_top_h
        preview_h = height - top_h - preview_gap
    end
    if preview_h < scaled_int(PREVIEW_MIN_HEIGHT) then
        preview_h = scaled_int(PREVIEW_MIN_HEIGHT)
        top_h = height - preview_h - preview_gap
    end
    if top_h < 1 then
        top_h = 1
    end

    self.sub_tab_bar:SetPosition(0, 0)
    self.sub_tab_bar:SetSize(width, top_h)
    self.sub_tab_bar:refresh_layout()

    self.preview_holder.control:SetPosition(0, top_h + preview_gap)
    self.preview_holder.control:SetSize(width, preview_h)
end

function DropsPage:load(drops, ui)
    self.loading = true
    self.controls.drops_enabled.cb:SetChecked(drops.enabled == true)
    self.controls.drops_visible_duration.tb:SetText(tostring(drops.visible_duration))
    self.controls.drops_width.tb:SetText(tostring(drops.width))
    self.controls.drops_rows.tb:SetText(tostring(drops.rows))
    self.controls.drops_icon_size.tb:SetText(tostring(drops.icon_size))
    self.controls.drops_flow:set_value(drops.flow)
    self.controls.drops_align:set_value(drops.align)
    self.controls.drops_icon_side:set_value(drops.icon_side)
    self.controls.drops_animations_enabled.cb:SetChecked(drops.animations_enabled == true)
    self.controls.drops_move_duration.tb:SetText(tostring(drops.move_duration))
    self.controls.drops_hud_background_opacity.tb:SetText(tostring(drops.hud.background_opacity))
    self.controls.drops_hud_background_color.tb:SetText(ui.color_to_hex(drops.hud.background_color))
    self.controls.drops_item_background_opacity.tb:SetText(tostring(drops.item.background_opacity))
    self.controls.drops_item_background_color.tb:SetText(ui.color_to_hex(drops.item.background_color))
    self.loading = false
    self:layout()
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

    local icon_size = tonumber(self.controls.drops_icon_size.tb:GetText())
    if icon_size ~= nil then
        drops.icon_size = icon_size
    end
    drops.flow = self.controls.drops_flow:get_value()
    drops.align = self.controls.drops_align:get_value()
    drops.icon_side = self.controls.drops_icon_side:get_value()
    drops.animations_enabled = self.controls.drops_animations_enabled.cb:IsChecked() == true
    local move_duration = tonumber(self.controls.drops_move_duration.tb:GetText())
    if move_duration ~= nil then
        drops.move_duration = move_duration
    end

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
