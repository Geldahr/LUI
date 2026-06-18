local Windows = _G.LUI.Runtime.Windows
local MoveMode = _G.LUI.UI.MoveMode
local TR = _G.LUI.Locale.TR
local SearchQuery = _G.LUI.Utils.SearchQuery
local Coords = _G.LUI.Utils.Coords
local is_boss_target = _G.LUI.Utils.is_boss_target
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_format_timeout_seconds = _G.LUI.Utils.lui_format_timeout_seconds
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_timed_row_resolved_font_size = _G.LUI.Utils.lui_timed_row_resolved_font_size
local lui_timed_row_estimate_text_width = _G.LUI.Utils.lui_timed_row_estimate_text_width
local lui_timed_row_format_time = _G.LUI.Utils.lui_timed_row_format_time
local lui_timed_row_text_gap = _G.LUI.Utils.lui_timed_row_text_gap
local lui_timed_row_time_label_width = _G.LUI.Utils.lui_timed_row_time_label_width
local lui_timed_row_min_name_width = _G.LUI.Utils.lui_timed_row_min_name_width
local lui_timed_row_min_timed_bar_width = _G.LUI.Utils.lui_timed_row_min_timed_bar_width
local lui_timed_row_min_item_width = _G.LUI.Utils.lui_timed_row_min_item_width
local lui_format_cooldown_time = _G.LUI.Utils.lui_format_cooldown_time
local lui_cooldown_resolved_font_size = _G.LUI.Utils.lui_cooldown_resolved_font_size
local lui_cooldown_estimate_text_width = _G.LUI.Utils.lui_cooldown_estimate_text_width
local lui_cooldown_text_gap = _G.LUI.Utils.lui_cooldown_text_gap
local lui_cooldown_time_label_width = _G.LUI.Utils.lui_cooldown_time_label_width
local lui_cooldown_min_name_width = _G.LUI.Utils.lui_cooldown_min_name_width
local lui_cooldown_min_timed_bar_width = _G.LUI.Utils.lui_cooldown_min_timed_bar_width
local lui_cooldown_min_item_width = _G.LUI.Utils.lui_cooldown_min_item_width
local lui_clamp_ratio = _G.LUI.Utils.lui_clamp_ratio
local lui_dim_color = _G.LUI.Utils.lui_dim_color
local lui_lerp_number = _G.LUI.Utils.lui_lerp_number
local lui_lerp_color = _G.LUI.Utils.lui_lerp_color
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_gradient_morale_color = _G.LUI.Utils.lui_gradient_morale_color
local lui_color_to_hex = _G.LUI.Utils.lui_color_to_hex
local lui_hex_to_color = _G.LUI.Utils.lui_hex_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local lui_abbrev_gold = _G.LUI.Utils.lui_abbrev_gold
local ConfigWindow = _G.LUI.Settings.ConfigWindow
local Settings = _G.LUI.Settings
local Defaults = _G.LUI.Settings.Defaults
local Persistence = _G.LUI.Settings.Persistence
local State = _G.LUI.Settings.State
local function _save_profile_manager_state(window, selected_profile_id)
    window.profile_manager_selected_profile_id = selected_profile_id
    window:update_saved_geometry()
    Persistence.save_settings()
    window:load_from_settings()
end

local function _refresh_runtime_after_profile_change(window, selected_profile_id)
    Defaults.ensure_loaded_settings()
    window:refresh_runtime_settings()
    _save_profile_manager_state(window, selected_profile_id)
end

local function _trim_profile_name(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = string.gsub(text, "^%s+", "")
    trimmed = string.gsub(trimmed, "%s+$", "")
    if string.len(trimmed) == 0 then
        return nil
    end

    return trimmed
end

local function _get_profile_manager_name(window)
    return _trim_profile_name(window.controls.profile_manager_name:get_value())
end

function ConfigWindow:use_selected_profile()
    local profile_id = self.controls.profile_manager_profile:get_value()
    if profile_id == nil or profile_id == State.current_profile_id then
        return
    end

    Persistence.capture_runtime_geometry()

    if Persistence.assign_character_profile(profile_id) ~= true then
        return
    end

    _refresh_runtime_after_profile_change(self, profile_id)
end

function ConfigWindow:rename_selected_profile()
    local profile_id = self.controls.profile_manager_profile:get_value()
    if profile_id == nil then
        return
    end

    local profile_name = _get_profile_manager_name(self)
    if profile_name == nil then
        return
    end

    if Persistence.rename_configuration(profile_id, profile_name) ~= true then
        return
    end

    _save_profile_manager_state(self, profile_id)
end

function ConfigWindow:confirm_delete_selected_profile()
    local profile_id = self.controls.profile_manager_profile:get_value()
    if profile_id == nil or Persistence.get_configuration_count() <= 1 then
        return
    end

    local profile_name = Persistence.get_configuration_name(profile_id) or TR["Profile"]
    local message = table.concat({
        string.format(TR["Delete profile '%s'?"], profile_name),
        TR["This will delete it for all characters using it."],
        TR["This action cannot be undone."],
    }, "\n")

    self:show_confirmation_dialog(message, TR["Delete"], function()
        local deleting_current_profile = profile_id == State.current_profile_id
        if Persistence.delete_configuration(profile_id) ~= true then
            return
        end

        local selected_profile_id = self.profile_manager_selected_profile_id
        if deleting_current_profile == true then
            local fallback_profile_id = Persistence.get_first_configuration_id()
            Persistence.assign_character_profile(fallback_profile_id)
            Defaults.ensure_loaded_settings()
            self:refresh_runtime_settings()
            selected_profile_id = fallback_profile_id
        else
            selected_profile_id = State.current_profile_id
        end

        _save_profile_manager_state(self, selected_profile_id)
    end)
end

function ConfigWindow:create_profile_from_current()
    if State.current_profile_id == nil then
        return
    end

    local profile_name = _get_profile_manager_name(self)
    if profile_name == nil then
        return
    end

    Persistence.capture_runtime_geometry()

    local duplicate_profile_id = Persistence.duplicate_configuration(State.current_profile_id)
    if duplicate_profile_id == nil then
        return
    end

    Persistence.get_configuration(duplicate_profile_id).name = profile_name

    if Persistence.assign_character_profile(duplicate_profile_id) ~= true then
        return
    end

    _refresh_runtime_after_profile_change(self, duplicate_profile_id)
end

function ConfigWindow:start_new_profile_quick_setup()
    local profile_name = _get_profile_manager_name(self)
    if profile_name == nil then
        return
    end

    self:hide_confirmation_dialog()
    self:SetVisible(false)

    Windows.first_run_quick_setup = Settings.FirstRunQuickSetup({
        skip_existing_configurations = true,
        create_profile_on_finish = true,
        profile_name = profile_name,
    })
    Windows.first_run_quick_setup:open()
end
