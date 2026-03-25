import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Settings.default_layouts"
import "LUI.src.UI.Widgets"

local WINDOW_W = 260
local WINDOW_H = 140
local FRAME_BORDER = 2
local WINDOW_MARGIN = 6
local TITLE_TOP = 4
local TITLE_H = 20
local TITLE_RULE_GAP = 2
local BODY_TOP = 40
local BODY_H = 30
local BUTTON_W = 80
local BUTTON_H = 18
local BUTTON_GAP = 5
local SCALE_INPUT_W = 55
local SCALE_INPUT_H = 18
local SCALE_BUTTON_W = 22
local SCALE_ROW_Y = 72
local CONFIG_DROPDOWN_W = 180
local CONFIG_DROPDOWN_H = 20
local LAYOUT_BUTTON_W = 100
local LAYOUT_BUTTON_H = 22
local LAYOUT_LABEL_Y = 63
local LAYOUT_ROW_Y = 80

local FRAME_BORDER_COLOR = Turbine.UI.Color(1, 0.35, 0.40, 0.50)
local FRAME_BACKGROUND_COLOR = Turbine.UI.Color(1, 0.15, 0.15, 0.15)
local FRAME_RULE_COLOR = Turbine.UI.Color(1, 0.35, 0.40, 0.50)

local OVERLAY_COLOR = Turbine.UI.Color(0.14, 0, 0, 0)

local function _scaled_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local function _format_scale(value)
    local text = string.format("%.2f", value)
    text = string.gsub(text, "0+$", "")
    text = string.gsub(text, "%.$", "")
    return text
end

local function _trim_submit_suffix(text)
    if type(text) ~= "string" then
        return nil
    end

    if string.sub(text, -1) ~= "\n" then
        return nil
    end

    return string.gsub(text, "[\r\n]+$", "")
end

local function _clamp_scale(value)
    local n = tonumber(value)
    if n == nil then
        return nil
    end
    if n < 0.50 then
        n = 0.50
    end
    if n > 3.00 then
        n = 3.00
    end
    return math.floor((n * 100) + 0.5) / 100
end

local function _persist_window_position(window, raw_window)
    if window == nil or raw_window == nil or window.GetPosition == nil then
        return
    end

    local left, top = window:GetPosition()
    raw_window.left = left
    raw_window.top = top
end

local function _round(value)
    return math.floor(value + 0.5)
end

local function _get_edge_ratio(pos, size, display_size)
    if type(pos) ~= "number" or type(size) ~= "number" or type(display_size) ~= "number" or size <= 0 then
        return 0
    end

    local available = display_size - size
    if available <= 0 then
        return 0
    end

    local clamped_pos = pos
    if clamped_pos < 0 then
        clamped_pos = 0
    end
    if clamped_pos > available then
        clamped_pos = available
    end

    return clamped_pos / available
end

local function _clamp_window_pos(pos, size, display_size)
    local out = _round(pos)
    local max_pos = display_size - size
    if max_pos < 0 then
        max_pos = 0
    end
    if out < 0 then
        return 0
    end
    if out > max_pos then
        return max_pos
    end
    return out
end

local function _get_preview_window_specs()
    return {
        {
            get_window = function()
                return PLAYER_VITAL
            end,
            get_raw_window = function()
                return _G.loaded_settings.self.vitals.window
            end,
        },
        {
            get_window = function()
                return TARGET_VITAL
            end,
            get_raw_window = function()
                return _G.loaded_settings.target.vitals.window
            end,
        },
        {
            get_window = function()
                return TARGET_VITAL ~= nil and TARGET_VITAL.targets_target_window or nil
            end,
            get_raw_window = function()
                return _G.loaded_settings.target.vitals.targets_target.window
            end,
        },
        {
            get_window = function()
                return BOSS_VITAL
            end,
            get_raw_window = function()
                return _G.loaded_settings.target.boss_vitals.window
            end,
        },
        {
            get_window = function()
                return PARTY_VITALS
            end,
            get_raw_window = function()
                return _G.loaded_settings.party.window
            end,
        },
        {
            get_window = function()
                return EXPIRING_SELF_EFFECTS_WINDOW
            end,
            get_raw_window = function()
                return _G.loaded_settings.self.expiring_effects.window
            end,
        },
        {
            get_window = function()
                return EXPIRING_TARGET_EFFECTS_WINDOW
            end,
            get_raw_window = function()
                return _G.loaded_settings.target.expiring_effects.window
            end,
        },
        {
            get_window = function()
                return COOLDOWNS_WINDOW
            end,
            get_raw_window = function()
                return _G.loaded_settings.self.cooldowns.window
            end,
        },
        {
            get_window = function()
                return INVENTORY_WINDOW
            end,
            get_raw_window = function()
                return _G.loaded_settings.inventory.window
            end,
        },
    }
end

local function _apply_runtime_settings()
    if ensure_loaded_settings ~= nil then
        ensure_loaded_settings()
    end
    if fix_colors ~= nil then
        fix_colors()
    end
    if rebuild_settings ~= nil then
        rebuild_settings()
    end
    if apply_inventory_settings ~= nil then
        apply_inventory_settings()
    end
    if apply_status_bar_settings ~= nil then
        apply_status_bar_settings()
    end
    if apply_cooldowns_settings ~= nil then
        apply_cooldowns_settings()
    end

    if CONFIG_WINDOW ~= nil then
        if CONFIG_WINDOW.apply_ui_scale ~= nil then
            CONFIG_WINDOW:apply_ui_scale()
        end
        if CONFIG_WINDOW.layout ~= nil then
            CONFIG_WINDOW:layout()
        end
    end

    if PLAYER_VITAL ~= nil and PLAYER_VITAL.resize ~= nil then
        PLAYER_VITAL:resize()
    end
    if TARGET_VITAL ~= nil and TARGET_VITAL.resize ~= nil then
        TARGET_VITAL:resize()
    end
    if BOSS_VITAL ~= nil and BOSS_VITAL.resize ~= nil then
        BOSS_VITAL:resize()
    end
    if PARTY_VITALS ~= nil and PARTY_VITALS.apply_settings ~= nil then
        PARTY_VITALS:apply_settings()
    end
    if EXPIRING_SELF_EFFECTS_WINDOW ~= nil and EXPIRING_SELF_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_SELF_EFFECTS_WINDOW:apply_settings()
    end
    if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil and EXPIRING_TARGET_EFFECTS_WINDOW.apply_settings ~= nil then
        EXPIRING_TARGET_EFFECTS_WINDOW:apply_settings()
    end
    if COOLDOWNS_WINDOW ~= nil and COOLDOWNS_WINDOW.apply_settings ~= nil then
        COOLDOWNS_WINDOW:apply_settings()
    end
    if PLAYER_VITAL ~= nil and PLAYER_VITAL.on_target_changed ~= nil then
        PLAYER_VITAL:on_target_changed()
    end

    if PLAYER_VITAL ~= nil and PLAYER_VITAL.is_move_mode ~= nil and PLAYER_VITAL:is_move_mode() == true then
        if PLAYER_VITAL.set_move_mode ~= nil then
            PLAYER_VITAL:set_move_mode(true)
        end
        if TARGET_VITAL ~= nil and TARGET_VITAL.set_move_mode ~= nil then
            TARGET_VITAL:set_move_mode(true)
        end
        if BOSS_VITAL ~= nil and BOSS_VITAL.set_move_mode ~= nil then
            BOSS_VITAL:set_move_mode(true)
        end
        if PARTY_VITALS ~= nil and PARTY_VITALS.set_move_mode ~= nil then
            PARTY_VITALS:set_move_mode(true)
        end
        if EXPIRING_SELF_EFFECTS_WINDOW ~= nil and EXPIRING_SELF_EFFECTS_WINDOW.set_move_mode ~= nil then
            EXPIRING_SELF_EFFECTS_WINDOW:set_move_mode(true)
        end
        if EXPIRING_TARGET_EFFECTS_WINDOW ~= nil and EXPIRING_TARGET_EFFECTS_WINDOW.set_move_mode ~= nil then
            EXPIRING_TARGET_EFFECTS_WINDOW:set_move_mode(true)
        end
        if COOLDOWNS_WINDOW ~= nil and COOLDOWNS_WINDOW.set_move_mode ~= nil then
            COOLDOWNS_WINDOW:set_move_mode(true)
        end
    end
end

FirstRunQuickSetup = class(Turbine.UI.Window)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function FirstRunQuickSetup:Constructor(options)
    Turbine.UI.Window.Constructor(self)

    self:SetVisible(false)
    self:SetZOrder(1500)
    self:SetBackColor(FRAME_BORDER_COLOR)
    self:SetMouseVisible(true)

    self.step = 1
    self.selected_scale = _G.DefaultLayouts.get_resolution_scale()
    self.selected_layout = nil
    self.updating_scale_text = false
    self.closing = false
    self.create_profile_on_finish = options ~= nil and options.create_profile_on_finish == true
    self.previous_profile_id = self.create_profile_on_finish == true and _G.current_profile_id or nil
    self.created_profile_id = nil
    self.initial_settings = _G.DefaultLayouts.copy_table(_G.loaded_settings)
    self.existing_config_labels, self.existing_config_values = get_configuration_options()
    self.has_existing_configurations =
        not (options ~= nil and options.skip_existing_configurations == true) and #self.existing_config_values > 0

    self.preview_overlay = Turbine.UI.Window()
    self.preview_overlay:SetVisible(false)
    self.preview_overlay:SetMouseVisible(true)
    self.preview_overlay:SetZOrder(1000)
    self.preview_overlay:SetBackColor(OVERLAY_COLOR)

    self.inner = Turbine.UI.Control()
    self.inner:SetParent(self)
    self.inner:SetMouseVisible(false)
    self.inner:SetBackColor(FRAME_BACKGROUND_COLOR)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self.inner)
    self.title:SetMouseVisible(false)
    self.title:SetSelectable(false)
    self.title:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    self.title:SetFont(_scaled_font("BookAntiqua", 22))
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.title:SetText(TR("LUI"))

    self.title_rule = Turbine.UI.Control()
    self.title_rule:SetParent(self.inner)
    self.title_rule:SetMouseVisible(false)
    self.title_rule:SetBackColor(FRAME_RULE_COLOR)

    self.body = UI.Widgets.LuiLabel()
    self.body:SetParent(self.inner)
    self.body:SetMouseVisible(false)
    self.body:SetSelectable(false)
    self.body:SetMultiline(true)
    self.body:SetFont(_scaled_font("Verdana", 13))
    self.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.body:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))

    self.scale_minus = UI.Widgets.LuiButton()
    self.scale_minus:SetParent(self.inner)
    self.scale_minus:SetText("-")
    self.scale_minus.Click = function()
        self:adjust_scale(-0.05)
    end

    self.scale_box = Turbine.UI.Lotro.TextBox()
    self.scale_box:SetParent(self.inner)
    self.scale_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.scale_box:SetWantsKeyEvents(true)
    self.scale_box.TextChanged = function()
        if self.updating_scale_text == true then
            return
        end

        local trimmed = _trim_submit_suffix(self.scale_box:GetText())
        if trimmed ~= nil then
            self.updating_scale_text = true
            self.scale_box:SetText(trimmed)
            self.updating_scale_text = false
            self:apply_scale_from_input()
        end
    end
    self.scale_box.FocusLost = function()
        self:apply_scale_from_input()
    end

    self.scale_plus = UI.Widgets.LuiButton()
    self.scale_plus:SetParent(self.inner)
    self.scale_plus:SetText("+")
    self.scale_plus.Click = function()
        self:adjust_scale(0.05)
    end

    self.config_dropdown = UI.Widgets.LuiDropdown()
    self.config_dropdown:SetParent(self.inner)
    self.config_dropdown:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.config_dropdown:SetPopupHost(self)
    self.config_dropdown:SetMappedOptions(self.existing_config_labels, self.existing_config_values)

    self.layout_label = UI.Widgets.LuiLabel()
    self.layout_label:SetParent(self.inner)
    self.layout_label:SetMouseVisible(false)
    self.layout_label:SetSelectable(false)
    self.layout_label:SetMultiline(true)
    self.layout_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.layout_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))

    self.layout_bottom = UI.Widgets.LuiButton()
    self.layout_bottom:SetParent(self.inner)
    self.layout_bottom:SetText(TR("Bottom layout"))
    self.layout_bottom.Click = function()
        self:select_layout("bottom")
    end

    self.layout_top = UI.Widgets.LuiButton()
    self.layout_top:SetParent(self.inner)
    self.layout_top:SetText(TR("Top layout"))
    self.layout_top.Click = function()
        self:select_layout("top")
    end

    self.choice_no = UI.Widgets.LuiButton()
    self.choice_no:SetParent(self.inner)
    self.choice_no:SetText(TR("No"))
    self.choice_no.Click = function()
        self:select_binary_choice(false)
    end

    self.choice_yes = UI.Widgets.LuiButton()
    self.choice_yes:SetParent(self.inner)
    self.choice_yes:SetText(TR("Yes"))
    self.choice_yes.Click = function()
        self:select_binary_choice(true)
    end

    self.use_button = UI.Widgets.LuiButton()
    self.use_button:SetParent(self.inner)
    self.use_button:SetText(TR("Use"))
    self.use_button.Click = function()
        self:use_selected_configuration()
    end

    self.new_button = UI.Widgets.LuiButton()
    self.new_button:SetParent(self.inner)
    self.new_button:SetText(TR("New"))
    self.new_button.Click = function()
        self:go_next()
    end

    self.cancel_button = UI.Widgets.LuiButton()
    self.cancel_button:SetParent(self.inner)
    self.cancel_button:SetText(TR("Cancel"))
    self.cancel_button.Click = function()
        self:cancel_setup()
    end

    self.next_button = UI.Widgets.LuiButton()
    self.next_button:SetParent(self.inner)
    self.next_button:SetText(TR("Next"))
    self.next_button.Click = function()
        self:go_next()
    end

    self.done_button = UI.Widgets.LuiButton()
    self.done_button:SetParent(self.inner)
    self.done_button:SetText(TR("Done"))
    self.done_button.Click = function()
        self:finish_done()
    end

    self.move_manually_button = UI.Widgets.LuiButton()
    self.move_manually_button:SetParent(self.inner)
    self.move_manually_button:SetText(TR("Move"))
    self.move_manually_button.Click = function()
        self:finish_move_manually()
    end

    self.settings_button = UI.Widgets.LuiButton()
    self.settings_button:SetParent(self.inner)
    self.settings_button:SetText(TR("Settings"))
    self.settings_button.Click = function()
        self:finish_settings()
    end

    self.SizeChanged = function()
        self:layout()
    end

    self.VisibleChanged = function()
        if self:IsVisible() == true then
            self:bring_to_front()
            self:center()
            return
        end

        self.preview_overlay:SetVisible(false)

        if self.closing == true then
            return
        end

        self:cancel_setup()
    end

    self:set_scale_text(self.selected_scale)
    self:apply_ui_scale()
    self:update_step()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function FirstRunQuickSetup:open()
    self:SetVisible(true)
    self:bring_to_front()
    self:center()
end

function FirstRunQuickSetup:bring_to_front()
    self:SetZOrder(1500)
    if self.preview_overlay ~= nil then
        self.preview_overlay:SetZOrder(1000)
    end
end

function FirstRunQuickSetup:center()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local w, h = self:GetSize()

    self:SetPosition(math.floor((display_w - w) / 2), math.floor((display_h - h) / 2))

    if self.preview_overlay ~= nil then
        self.preview_overlay:SetPosition(0, 0)
        self.preview_overlay:SetSize(display_w, display_h)
    end
end

function FirstRunQuickSetup:apply_ui_scale()
    self:SetSize(_scaled_int(WINDOW_W), _scaled_int(WINDOW_H))

    local title_font = _scaled_font("BookAntiqua", 22)
    local body_font = _scaled_font("Verdana", 13)
    local hint_font = _scaled_font("Verdana", 12)
    local button_font = _scaled_font("Verdana", 12)

    self.title:SetFont(title_font)

    self.body:SetFont(body_font)
    self.layout_label:SetFont(hint_font)
    self.scale_box:SetFont(body_font)
    self.config_dropdown:SetFont(body_font)
    self.config_dropdown:SetScale(_G.settings.global.scale)

    self.scale_minus:SetFont(button_font)
    self.scale_plus:SetFont(button_font)
    self.use_button:SetFont(button_font)
    self.new_button:SetFont(button_font)
    self.cancel_button:SetFont(button_font)
    self.next_button:SetFont(button_font)
    self.done_button:SetFont(button_font)
    self.move_manually_button:SetFont(button_font)
    self.settings_button:SetFont(button_font)
    self.layout_bottom:SetFont(button_font)
    self.layout_top:SetFont(button_font)
    self.choice_no:SetFont(button_font)
    self.choice_yes:SetFont(button_font)

    self:layout()
    self:center()
end

function FirstRunQuickSetup:cancel_setup()
    self.closing = true

    self:_cleanup_preview(true)
    self:restore_initial_settings()
    save_settings()

    self.preview_overlay:SetVisible(false)
    self:SetVisible(false)
    FIRST_RUN_QUICK_SETUP_WINDOW = nil
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function FirstRunQuickSetup:layout()
    local w, h = self:GetSize()
    local border = FRAME_BORDER
    self.inner:SetPosition(border, border)
    self.inner:SetSize(w - (border * 2), h - (border * 2))

    local inner_w, inner_h = self.inner:GetSize()
    local margin = _scaled_int(WINDOW_MARGIN)
    local title_top = _scaled_int(TITLE_TOP)
    local title_h = _scaled_int(TITLE_H)
    local title_rule_y = title_top + title_h + _scaled_int(TITLE_RULE_GAP)
    local body_top = _scaled_int(BODY_TOP)
    local body_h = _scaled_int(BODY_H)
    local button_w = _scaled_int(BUTTON_W)
    local button_h = _scaled_int(BUTTON_H)
    local button_gap = _scaled_int(BUTTON_GAP)

    self.title:SetPosition(margin, title_top)
    self.title:SetSize(inner_w - (margin * 2), title_h)

    self.title_rule:SetPosition(margin, title_rule_y)
    self.title_rule:SetSize(inner_w - (margin * 2), 1)

    self.body:SetPosition(margin, body_top)
    self.body:SetSize(inner_w - (margin * 2), body_h)

    local scale_row_y = _scaled_int(SCALE_ROW_Y)
    local scale_button_w = _scaled_int(SCALE_BUTTON_W)
    local scale_input_w = _scaled_int(SCALE_INPUT_W)
    local scale_input_h = _scaled_int(SCALE_INPUT_H)
    local scale_row_w = (scale_button_w * 2) + scale_input_w + (button_gap * 2)
    local scale_row_x = math.floor((inner_w - scale_row_w) / 2)
    local scale_input_y = scale_row_y + math.floor((button_h - scale_input_h) / 2)

    self.scale_minus:SetPosition(scale_row_x, scale_row_y)
    self.scale_minus:SetSize(scale_button_w, button_h)
    self.scale_box:SetPosition(scale_row_x + scale_button_w + button_gap, scale_input_y)
    self.scale_box:SetSize(scale_input_w, scale_input_h)
    self.scale_plus:SetPosition(scale_row_x + scale_button_w + button_gap + scale_input_w + button_gap, scale_row_y)
    self.scale_plus:SetSize(scale_button_w, button_h)

    local config_dropdown_w = _scaled_int(CONFIG_DROPDOWN_W)
    local config_dropdown_h = _scaled_int(CONFIG_DROPDOWN_H)
    local config_dropdown_x = math.floor((inner_w - config_dropdown_w) / 2)
    local config_dropdown_y = scale_row_y + math.floor((button_h - config_dropdown_h) / 2)
    self.config_dropdown:SetPosition(config_dropdown_x, config_dropdown_y)
    self.config_dropdown:SetSize(config_dropdown_w, config_dropdown_h)

    self.layout_label:SetPosition(margin, _scaled_int(LAYOUT_LABEL_Y))
    self.layout_label:SetSize(inner_w - (margin * 2), _scaled_int(16))

    local layout_button_w = _scaled_int(LAYOUT_BUTTON_W)
    local layout_button_h = _scaled_int(LAYOUT_BUTTON_H)
    local layout_row_y = _scaled_int(LAYOUT_ROW_Y)
    local layout_row_w = (layout_button_w * 2) + button_gap
    local layout_row_x = math.floor((inner_w - layout_row_w) / 2)

    self.layout_bottom:SetPosition(layout_row_x, layout_row_y)
    self.layout_bottom:SetSize(layout_button_w, layout_button_h)
    self.layout_top:SetPosition(layout_row_x + layout_button_w + button_gap, layout_row_y)
    self.layout_top:SetSize(layout_button_w, layout_button_h)
    self.choice_no:SetPosition(layout_row_x, layout_row_y)
    self.choice_no:SetSize(layout_button_w, layout_button_h)
    self.choice_yes:SetPosition(layout_row_x + layout_button_w + button_gap, layout_row_y)
    self.choice_yes:SetSize(layout_button_w, layout_button_h)

    local bottom_y = inner_h - margin - button_h
    self.cancel_button:SetPosition(margin, bottom_y)
    self.cancel_button:SetSize(button_w, button_h)

    self.next_button:SetPosition(inner_w - margin - button_w, bottom_y)
    self.next_button:SetSize(button_w, button_h)

    local import_row_w = (button_w * 2) + button_gap
    local import_row_x = math.floor((inner_w - import_row_w) / 2)
    self.use_button:SetPosition(import_row_x, bottom_y)
    self.use_button:SetSize(button_w, button_h)
    self.new_button:SetPosition(import_row_x + button_w + button_gap, bottom_y)
    self.new_button:SetSize(button_w, button_h)

    self.done_button:SetSize(button_w, button_h)

    local action_gap = button_gap
    local action_row_w = (button_w * 3) + (action_gap * 2)
    if action_row_w > inner_w then
        action_gap = math.floor((inner_w - (button_w * 3)) / 2)
        if action_gap < 0 then
            action_gap = 0
        end
        action_row_w = (button_w * 3) + (action_gap * 2)
    end
    local action_row_x = math.floor((inner_w - action_row_w) / 2)
    if action_row_x < 0 then
        action_row_x = 0
    end

    self.move_manually_button:SetPosition(action_row_x, bottom_y)
    self.move_manually_button:SetSize(button_w, button_h)
    self.settings_button:SetPosition(action_row_x + button_w + action_gap, bottom_y)
    self.settings_button:SetSize(button_w, button_h)
    self.done_button:SetPosition(action_row_x + (button_w * 2) + (action_gap * 2), bottom_y)
end

function FirstRunQuickSetup:capture_preview_window_snapshots()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local specs = _get_preview_window_specs()
    local snapshots = {}

    for i = 1, #specs do
        local spec = specs[i]
        local window = spec.get_window()
        if window ~= nil and window.GetPosition ~= nil and window.GetSize ~= nil then
            local left, top = window:GetPosition()
            local width, height = window:GetSize()
            if type(left) == "number" and type(top) == "number" and
                type(width) == "number" and type(height) == "number" and
                width > 0 and height > 0 then
                snapshots[#snapshots + 1] = {
                    spec = spec,
                    left = left,
                    top = top,
                    width = width,
                    height = height,
                    left_ratio = _get_edge_ratio(left, width, display_w),
                    top_ratio = _get_edge_ratio(top, height, display_h),
                }
            end
        end
    end

    return snapshots
end

function FirstRunQuickSetup:apply_preview_window_snapshots(snapshots)
    if snapshots == nil then
        return
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    for i = 1, #snapshots do
        local snapshot = snapshots[i]
        local window = snapshot.spec.get_window()
        local raw_window = snapshot.spec.get_raw_window()
        if window ~= nil and raw_window ~= nil and window.GetPosition ~= nil and window.GetSize ~= nil then
            local width, height = window:GetSize()
            if type(width) == "number" and type(height) == "number" and
                width > 0 and height > 0 then
                local next_left = snapshot.left - ((width - snapshot.width) * snapshot.left_ratio)
                local next_top = snapshot.top - ((height - snapshot.height) * snapshot.top_ratio)
                next_left = _clamp_window_pos(next_left, width, display_w)
                next_top = _clamp_window_pos(next_top, height, display_h)
                window:SetPosition(next_left, next_top)
                raw_window.left = next_left
                raw_window.top = next_top
            end
        end
    end
end

function FirstRunQuickSetup:apply_preview_layout(layout_key, scale)
    local preserved_config_window = self:get_preserved_config_window()
    local base_scale = 1.35
    if _G.DefaultLayouts ~= nil and _G.DefaultLayouts.get_base_scale ~= nil then
        base_scale = _G.DefaultLayouts.get_base_scale()
    end

    local snapshots = nil
    if scale ~= base_scale then
        _G.loaded_settings = _G.DefaultLayouts.build(layout_key, base_scale, preserved_config_window)
        _apply_runtime_settings()
        snapshots = self:capture_preview_window_snapshots()
    end

    _G.loaded_settings = _G.DefaultLayouts.build(layout_key, scale, preserved_config_window)
    _apply_runtime_settings()

    if snapshots ~= nil then
        self:apply_preview_window_snapshots(snapshots)
    end
end

function FirstRunQuickSetup:update_step()
    self.body:SetVisible(true)
    self.scale_minus:SetVisible(false)
    self.scale_box:SetVisible(false)
    self.scale_plus:SetVisible(false)
    self.config_dropdown:SetVisible(false)
    self.layout_label:SetVisible(false)
    self.layout_bottom:SetVisible(false)
    self.layout_top:SetVisible(false)
    self.choice_no:SetVisible(false)
    self.choice_yes:SetVisible(false)
    self.use_button:SetVisible(false)
    self.new_button:SetVisible(false)
    self.cancel_button:SetVisible(false)
    self.next_button:SetVisible(false)
    self.done_button:SetVisible(false)
    self.move_manually_button:SetVisible(false)
    self.settings_button:SetVisible(false)

    if self.has_existing_configurations == true and self.step == 1 then
        self.body:SetText(TR("Do you want to use an existing configuration?"))
        self.config_dropdown:SetVisible(true)
        self.use_button:SetVisible(true)
        self.new_button:SetVisible(true)
        return
    end

    local setup_step = self.step
    if self.has_existing_configurations == true then
        setup_step = setup_step - 1
    end

    if setup_step == 1 then
        self.body:SetText(table.concat({
            TR("Thank you for using LUI."),
            TR("We will guide you through a few short steps."),
        }, "\n"))

        self.cancel_button:SetVisible(true)
        self.next_button:SetVisible(true)
        return
    end

    self:ensure_preview_mode()

    if setup_step == 2 then
        if self.selected_layout == nil then
            self:select_layout("bottom")
        end

        self.body:SetText(TR("Which layout do you prefer?"))
        self.layout_label:SetText(TR("Pick the closest layout."))
        self.layout_label:SetVisible(true)
        self.layout_bottom:SetVisible(true)
        self.layout_top:SetVisible(true)
        self.next_button:SetVisible(true)
        return
    end

    if self.selected_layout == nil then
        self:select_layout("bottom")
    end

    if setup_step == 4 then
        self.body:SetText(TR("Replace the default inventory bags?"))
        self:update_binary_choice_buttons(_G.loaded_settings.inventory.replace == true)
        self.choice_no:SetVisible(true)
        self.choice_yes:SetVisible(true)
        self.next_button:SetVisible(true)
        return
    end

    if setup_step == 3 then
        self.body:SetText(TR("Select your scaling."))
        self.scale_minus:SetVisible(true)
        self.scale_box:SetVisible(true)
        self.scale_plus:SetVisible(true)
        self.next_button:SetVisible(true)
        return
    end

    if setup_step == 5 then
        self.body:SetText(TR("Enable the status bar?"))
        self:update_binary_choice_buttons(_G.loaded_settings.status_bar.enabled == true)
        self.choice_no:SetVisible(true)
        self.choice_yes:SetVisible(true)
        self.next_button:SetVisible(true)
        return
    end

    self.body:SetText(TR("Do you want to modify anything else?"))
    self.done_button:SetVisible(true)
    self.move_manually_button:SetVisible(true)
    self.settings_button:SetVisible(true)
end

function FirstRunQuickSetup:go_next()
    local max_step = self.has_existing_configurations == true and 7 or 6
    if self.step >= max_step then
        return
    end
    self.step = self.step + 1
    self:update_step()
end

function FirstRunQuickSetup:use_selected_configuration()
    local profile_id = self.config_dropdown:GetValue()
    if profile_id == nil then
        return
    end

    if assign_character_profile == nil or assign_character_profile(profile_id) ~= true then
        return
    end

    _G.loaded_settings_was_new = false
    _apply_runtime_settings()
    save_settings()

    self.closing = true
    self.preview_overlay:SetVisible(false)
    self:SetVisible(false)
    FIRST_RUN_QUICK_SETUP_WINDOW = nil
end

function FirstRunQuickSetup:set_scale_text(value)
    self.updating_scale_text = true
    self.scale_box:SetText(_format_scale(value))
    self.updating_scale_text = false
end

function FirstRunQuickSetup:apply_scale_from_input()
    local scale = _clamp_scale(self.scale_box:GetText())
    if scale == nil then
        self:set_scale_text(self.selected_scale)
        return
    end

    self:set_selected_scale(scale)
end

function FirstRunQuickSetup:adjust_scale(delta)
    local scale = _clamp_scale((self.selected_scale or 1) + delta)
    if scale == nil then
        return
    end

    self:set_selected_scale(scale)
end

function FirstRunQuickSetup:set_selected_scale(scale)
    if scale == nil then
        return
    end

    self.selected_scale = scale
    self:set_scale_text(scale)
    local layout_key = self.selected_layout or "bottom"
    self:apply_preview_layout(layout_key, scale)
    if refresh_move_mode_snapshot ~= nil then
        refresh_move_mode_snapshot()
    end
    self:apply_ui_scale()
end

function FirstRunQuickSetup:get_preserved_config_window()
    if _G.loaded_settings == nil or _G.loaded_settings.global == nil then
        return nil
    end

    return _G.DefaultLayouts.copy_table(_G.loaded_settings.global.config_window)
end

function FirstRunQuickSetup:select_layout(layout_key)
    self:apply_preview_layout(layout_key, self.selected_scale)

    self.selected_layout = layout_key
    self.layout_bottom:set_active(layout_key == "bottom")
    self.layout_top:set_active(layout_key == "top")

    if refresh_move_mode_snapshot ~= nil then
        refresh_move_mode_snapshot()
    end

    self:apply_ui_scale()
end

function FirstRunQuickSetup:update_binary_choice_buttons(enabled)
    self.choice_no:set_active(enabled ~= true)
    self.choice_yes:set_active(enabled == true)
end

function FirstRunQuickSetup:select_binary_choice(enabled)
    local value = enabled == true
    local setup_step = self.step
    if self.has_existing_configurations == true then
        setup_step = setup_step - 1
    end

    if setup_step == 4 then
        _G.loaded_settings.inventory.replace = value
    elseif setup_step == 5 then
        _G.loaded_settings.status_bar.enabled = value
    else
        return
    end

    self:update_binary_choice_buttons(value)
    _apply_runtime_settings()

    if refresh_move_mode_snapshot ~= nil then
        refresh_move_mode_snapshot()
    end

    self:apply_ui_scale()
end

function FirstRunQuickSetup:restore_initial_settings()
    if self.previous_profile_id ~= nil then
        assign_character_profile(self.previous_profile_id)
    end

    _G.loaded_settings = _G.DefaultLayouts.copy_table(self.initial_settings)
    _apply_runtime_settings()
    self.selected_scale = _G.loaded_settings.global.scale
    self.selected_layout = nil
    self.layout_bottom:set_active(false)
    self.layout_top:set_active(false)
    self:set_scale_text(self.selected_scale)
    self:apply_ui_scale()
end

function FirstRunQuickSetup:ensure_finish_profile()
    if self.create_profile_on_finish ~= true then
        return true
    end

    if self.created_profile_id ~= nil then
        return true
    end

    local profile_id = create_configuration(_G.current_character_name, _G.loaded_settings)
    if assign_character_profile(profile_id) ~= true then
        return false
    end

    self.created_profile_id = profile_id
    return true
end

function FirstRunQuickSetup:commit_preview_settings()
    _G.loaded_settings.global.scale = self.selected_scale

    _persist_window_position(PLAYER_VITAL, _G.loaded_settings.self.vitals.window)
    _persist_window_position(TARGET_VITAL, _G.loaded_settings.target.vitals.window)
    _persist_window_position(BOSS_VITAL, _G.loaded_settings.target.boss_vitals.window)
    _persist_window_position(PARTY_VITALS, _G.loaded_settings.party.window)
    _persist_window_position(EXPIRING_SELF_EFFECTS_WINDOW, _G.loaded_settings.self.expiring_effects.window)
    _persist_window_position(EXPIRING_TARGET_EFFECTS_WINDOW, _G.loaded_settings.target.expiring_effects.window)
    _persist_window_position(COOLDOWNS_WINDOW, _G.loaded_settings.self.cooldowns.window)

    if TARGET_VITAL ~= nil and TARGET_VITAL.targets_target_window ~= nil then
        _persist_window_position(TARGET_VITAL.targets_target_window, _G.loaded_settings.target.vitals.targets_target.window)
    end

    if CONFIG_WINDOW ~= nil and CONFIG_WINDOW.GetPosition ~= nil and CONFIG_WINDOW.GetSize ~= nil then
        local left, top = CONFIG_WINDOW:GetPosition()
        local width, height = CONFIG_WINDOW:GetSize()
        _G.loaded_settings.global.config_window.left = left
        _G.loaded_settings.global.config_window.top = top
        _G.loaded_settings.global.config_window.width = width
        _G.loaded_settings.global.config_window.height = height
    end
end

function FirstRunQuickSetup:ensure_preview_mode()
    if PLAYER_VITAL == nil or PLAYER_VITAL.is_move_mode == nil then
        return
    end

    if PLAYER_VITAL:is_move_mode() ~= true and set_move_ui_mode ~= nil then
        set_move_ui_mode(true)
    end

    if set_move_ui_preview_lock ~= nil then
        set_move_ui_preview_lock(true)
    end

    self.preview_overlay:SetVisible(true)
    self:bring_to_front()
    self:center()
end

function FirstRunQuickSetup:_cleanup_preview(cancel_changes)
    if set_move_ui_preview_lock ~= nil then
        set_move_ui_preview_lock(false)
    end

    self.preview_overlay:SetVisible(false)

    if PLAYER_VITAL ~= nil and PLAYER_VITAL.is_move_mode ~= nil and PLAYER_VITAL:is_move_mode() == true then
        if cancel_changes == true and cancel_move_mode ~= nil then
            cancel_move_mode()
        elseif cancel_changes ~= true and set_move_ui_mode ~= nil then
            set_move_ui_mode(false)
        end
    end
end

function FirstRunQuickSetup:finish_done()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true
    self:_cleanup_preview(false)
    save_settings()
    self:SetVisible(false)
    FIRST_RUN_QUICK_SETUP_WINDOW = nil
end

function FirstRunQuickSetup:finish_move_manually()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true

    if set_move_ui_preview_lock ~= nil then
        set_move_ui_preview_lock(false)
    end
    self.preview_overlay:SetVisible(false)

    if refresh_move_mode_snapshot ~= nil then
        refresh_move_mode_snapshot()
    end
    save_settings()

    self:SetVisible(false)
    FIRST_RUN_QUICK_SETUP_WINDOW = nil
end

function FirstRunQuickSetup:finish_settings()
    self:commit_preview_settings()
    if self:ensure_finish_profile() ~= true then
        return
    end
    self.closing = true
    self:_cleanup_preview(false)
    self:SetVisible(false)
    FIRST_RUN_QUICK_SETUP_WINDOW = nil

    if CONFIG_WINDOW ~= nil then
        CONFIG_WINDOW:open("global")
    end
end
