import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.Settings.Content.nested_tabs"

local FeatureShell = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.feature_shell) or SettingsFeatureShell
local ConfigContent = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_content) or ConfigContent
local ConfigTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_tabs) or ConfigTabs
local ConfigNestedTabs = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.config_nested_tabs) or
    ConfigNestedTabs
local scaled_int = FeatureShell.scaled_int
local PREVIEW_GAP = 10
local PREVIEW_MIN_TOP_HEIGHT = 120
local PREVIEW_MIN_HEIGHT = 100

local function _apply_color(ui, dest, hex)
    local color = ui.hex_to_color(hex)
    dest.R, dest.G, dest.B = color.R, color.G, color.B
end

local function _new_colors_section(window, refresh_preview, settings_getter)
    local ui = window._ui

    local hud = ConfigContent(window, 3, refresh_preview)
    hud:add_line_edit(TR["Background opacity (0..1)"], "drops_hud_background_opacity",
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().hud.background_opacity = opacity
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().hud.background_opacity))
        end)
    hud:add_color_picker(TR["Background color"], "drops_hud_background_color",
        function(value)
            _apply_color(ui, settings_getter().hud.background_color, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().hud.background_color))
        end)

    local item = ConfigContent(window, 3, refresh_preview)
    item:add_line_edit(TR["Background opacity (0..1)"], "drops_item_background_opacity",
        function(value)
            local opacity = tonumber(value)
            if opacity ~= nil then
                settings_getter().item.background_opacity = opacity
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().item.background_opacity))
        end)
    item:add_color_picker(TR["Background color"], "drops_item_background_color",
        function(value)
            _apply_color(ui, settings_getter().item.background_color, value)
        end,
        function(entry)
            entry.tb:SetText(ui.color_to_hex(settings_getter().item.background_color))
        end)

    local page = ConfigNestedTabs(window, UI.Widgets.LuiTabBar.position.top,
        FeatureShell.nested_tab_scale, FeatureShell.nested_tab_font_size)
    page:add_tab(TR["HUD"], "hud", hud)
    page:add_tab(TR["Item"], "item", item)

    return page
end

DropsPage = class(ConfigTabs)

function DropsPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
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
    local settings_getter = function()
        return self._settings.drops
    end

    local general = ConfigContent(window, 4, refresh_preview)
    general:add_checkbox(TR["Enabled"], "drops_enabled",
        function(value)
            settings_getter().enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().enabled == true)
        end, true)
    general:break_line()
    general:add_line_edit(TR["Visible duration (s)"], "drops_visible_duration",
        function(value)
            local visible_duration = tonumber(value)
            if visible_duration ~= nil then
                settings_getter().visible_duration = visible_duration
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().visible_duration))
        end)
    general:add_info(
        TR["Carry-alls may bypass inventory item events. Those drops can appear without icon or hover and will be shown as text only."],
        42)
    self:add_tab(TR["General"], "general", general)

    local layout = ConfigContent(window, 4, refresh_preview)
    layout:add_line_edit(TR["Width"], "drops_width",
        function(value)
            local width = tonumber(value)
            if width ~= nil then
                settings_getter().width = width
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().width))
        end)
    layout:add_line_edit(TR["Rows"], "drops_rows",
        function(value)
            local rows = tonumber(value)
            if rows ~= nil then
                settings_getter().rows = rows
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().rows))
        end)
    layout:add_line_edit(TR["Icon Size"], "drops_icon_size",
        function(value)
            local icon_size = tonumber(value)
            if icon_size ~= nil then
                settings_getter().icon_size = icon_size
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().icon_size))
        end)
    layout:break_line()
    layout:add_dropdown(TR["Order"], "drops_flow", flow_labels, flow_values,
        function(value)
            settings_getter().flow = value
        end,
        function(entry)
            entry:set_value(settings_getter().flow)
        end)
    layout:add_dropdown(TR["Align"], "drops_align", align_labels, align_values,
        function(value)
            settings_getter().align = value
        end,
        function(entry)
            entry:set_value(settings_getter().align)
        end)
    layout:add_dropdown(TR["Icon position"], "drops_icon_side", side_labels, side_values,
        function(value)
            settings_getter().icon_side = value
        end,
        function(entry)
            entry:set_value(settings_getter().icon_side)
        end)
    self:add_tab(TR["Layout"], "layout", layout)

    self:add_tab(TR["Colors"], "colors", _new_colors_section(window, refresh_preview, settings_getter))

    local motion = ConfigContent(window, 4, refresh_preview)
    motion:add_checkbox(TR["Animations"], "drops_animations_enabled",
        function(value)
            settings_getter().animations_enabled = value == true
        end,
        function(entry)
            entry.cb:SetChecked(settings_getter().animations_enabled == true)
        end, true)
    motion:break_line()
    motion:add_line_edit(TR["Move duration (ms)"], "drops_move_duration",
        function(value)
            local move_duration = tonumber(value)
            if move_duration ~= nil then
                settings_getter().move_duration = move_duration
            end
        end,
        function(entry)
            entry.tb:SetText(tostring(settings_getter().move_duration))
        end)
    self:add_tab(TR["Motion"], "motion", motion)

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
    ConfigTabs.apply_ui_scale(self)
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

function DropsPage:load_from_settings(s)
    self._settings = s
    self:load()
end

function DropsPage:apply_to_settings(s)
    self._settings = s
    self:save()
end
