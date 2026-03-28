import "Turbine.UI"

import "LUI.src.UI.Settings.Tabs.form_page"
import "LUI.src.UI.Widgets"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or _G.SettingsFormPage or
    SettingsFormPage

local HELP_FONT_NAME = "Verdana"
local HELP_FONT_SIZE = 13
local GITHUB_URL = "https://github.com/Geldahr/LUI"
local LINK_BACKGROUND = Turbine.UI.Color(1.0, 0.2, 0.2, 0.2)
local GITHUB_LABEL_TEXT = TR("For more information, feature requests, or bug reports, please visit the GitHub repository:")
local ABOUT_HEIGHT = 156
local GITHUB_HEIGHT = 59
local COMMANDS_HEIGHT = 205
local GITHUB_LINK_HEIGHT = 22
local GITHUB_LABEL_HEIGHT = 30

local function _scaled_help_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_help_int(value)
    return math.floor(_scaled_help_size(value) + 0.5)
end

local function _scaled_help_font()
    local font = FONT_TO_LOTRO(HELP_FONT_NAME, _scaled_help_size(HELP_FONT_SIZE))
    if font == nil then
        error("Missing help font: " .. tostring(HELP_FONT_NAME) .. " " .. tostring(HELP_FONT_SIZE))
    end
    return font
end

local function _layout_help_text(entry)
    if entry == nil or entry.control == nil or entry.body == nil then
        return
    end

    local w, h = entry.control:GetSize()
    entry.body:SetPosition(0, 0)
    entry.body:SetSize(w, h)
end

local function _create_help_text(page, key, text, height)
    local entry = page:add_custom(key, height)

    entry.body = UI.Widgets.LuiLabel()
    entry.body:SetParent(entry.control)
    entry.body:SetFont(_scaled_help_font())
    entry.body:SetMultiline(true)
    entry.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    entry.body:SetText(text)

    entry.control.SizeChanged = function()
        _layout_help_text(entry)
    end
    entry.apply_ui_scale = function()
        entry.body:SetFont(_scaled_help_font())
        _layout_help_text(entry)
    end
    entry:apply_ui_scale()

    return entry
end

local function _layout_link_box(entry)
    if entry == nil or entry.control == nil or entry.label == nil or entry.link_tb == nil then
        return
    end

    local w = entry.control:GetWidth()
    local link_h = _scaled_help_int(GITHUB_LINK_HEIGHT)
    local label_h = _scaled_help_int(GITHUB_LABEL_HEIGHT)
    if label_h < 1 then
        label_h = 1
    end

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(w, label_h)
    entry.link_tb:SetPosition(0, entry.label:GetTop() + entry.label:GetHeight())
    entry.link_tb:SetSize(w, link_h)
end

local function _create_link_box(page, key, label_text, link_text, height)
    local entry = page:add_custom(key, height)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(_scaled_help_font())
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    entry.label:SetText(label_text)

    entry.link_tb = Turbine.UI.TextBox()
    entry.link_tb:SetParent(entry.control)
    entry.link_tb:SetFont(_scaled_help_font())
    entry.link_tb:SetMultiline(false)
    entry.link_tb:SetReadOnly(true)
    entry.link_tb:SetSelectable(true)
    entry.link_tb:SetText(link_text)
    entry.link_tb:SetBackColor(LINK_BACKGROUND)
    entry.link_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.link_tb:SetZOrder(2)

    entry.control.SizeChanged = function()
        _layout_link_box(entry)
    end
    entry.apply_ui_scale = function()
        entry.label:SetFont(_scaled_help_font())
        entry.link_tb:SetFont(_scaled_help_font())
        _layout_link_box(entry)
    end
    entry:apply_ui_scale()

    return entry
end

HelpPage = class(SettingsFormPage)

function HelpPage:Constructor(window)
    SettingsFormPage.Constructor(self, window)
    self.show_main_content_border = true

    local about_text = table.concat({
        TR("LUI replaces and extends key LotRO UI elements with a cleaner and more configurable layout."),
        TR("It focuses on combat-related UI such as self vitals, target vitals, boss vitals, party vitals, expiring effects, cooldowns elements and also inventory, and status bar."),
        "",
        TR("The global LUI UI scale applies uniformly across the whole LUI interface."),
        TR("It is separate from the built-in LotRO UI scaling."),
        "",
        TR("For the best experience, set the global LUI UI scale before changing individual sizes."),
        TR("Recommended starting points: 1080p = 1.0, 1440p = 1.3 to 1.4, 2160p / 4k = 2.0."),
        TR("After the global LUI UI scale feels right, use the other settings for micro adjustments."),
    }, "\n")

    local commands_text = table.concat({
        TR("/lui config - Toggle the configuration window."),
        TR("/lui move - Toggle LUI move mode."),
        TR("/lui move cancel - Leave move mode without saving the current positions."),
        TR("/lui inventory - Toggle the inventory window."),
        TR("/lui inv - Short alias for /lui inventory."),
        TR("/lui assets - Toggle the assets window."),
        TR("/lui bestiary - Toggle the bestiary window."),
        TR("/lui beast - Alias for /lui bestiary."),
        TR("/lui b - Short alias for /lui bestiary."),
    }, "\n")

    self:add_title(TR("About LUI"))
    _create_help_text(self, "help_about", about_text, ABOUT_HEIGHT)
    self:add_break()
    _create_link_box(self, "help_github", GITHUB_LABEL_TEXT, GITHUB_URL, GITHUB_HEIGHT)

    self:add_hr()
    self:add_title(TR("Commands"))
    _create_help_text(self, "help_commands", commands_text, COMMANDS_HEIGHT)
end

function HelpPage:load_from_settings()
end

function HelpPage:apply_to_settings()
end
