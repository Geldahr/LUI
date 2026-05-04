local function _save_profile_manager_state(window, selected_profile_id)
    window.profile_manager_selected_profile_id = selected_profile_id
    window:update_saved_geometry()
    save_settings()
    window:load_from_settings()
end

local function _refresh_runtime_after_profile_change(window, selected_profile_id)
    ensure_loaded_settings()
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
    if profile_id == nil or profile_id == _G.current_profile_id then
        return
    end

    _G.capture_runtime_geometry()

    if assign_character_profile(profile_id) ~= true then
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

    if rename_configuration(profile_id, profile_name) ~= true then
        return
    end

    _save_profile_manager_state(self, profile_id)
end

function ConfigWindow:confirm_delete_selected_profile()
    local profile_id = self.controls.profile_manager_profile:get_value()
    if profile_id == nil or get_configuration_count() <= 1 then
        return
    end

    local profile_name = get_configuration_name(profile_id) or TR["Profile"]
    local message = table.concat({
        string.format(TR["Delete profile '%s'?"], profile_name),
        TR["This will delete it for all characters using it."],
        TR["This action cannot be undone."],
    }, "\n")

    self:show_confirmation_dialog(message, TR["Delete"], function()
        local deleting_current_profile = profile_id == _G.current_profile_id
        if delete_configuration(profile_id) ~= true then
            return
        end

        local selected_profile_id = self.profile_manager_selected_profile_id
        if deleting_current_profile == true then
            local fallback_profile_id = get_first_configuration_id()
            assign_character_profile(fallback_profile_id)
            ensure_loaded_settings()
            self:refresh_runtime_settings()
            selected_profile_id = fallback_profile_id
        else
            selected_profile_id = _G.current_profile_id
        end

        _save_profile_manager_state(self, selected_profile_id)
    end)
end

function ConfigWindow:create_profile_from_current()
    if _G.current_profile_id == nil then
        return
    end

    local profile_name = _get_profile_manager_name(self)
    if profile_name == nil then
        return
    end

    _G.capture_runtime_geometry()

    local duplicate_profile_id = duplicate_configuration(_G.current_profile_id)
    if duplicate_profile_id == nil then
        return
    end

    get_configuration(duplicate_profile_id).name = profile_name

    if assign_character_profile(duplicate_profile_id) ~= true then
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

    FIRST_RUN_QUICK_SETUP_WINDOW = Settings.FirstRunQuickSetup({
        skip_existing_configurations = true,
        create_profile_on_finish = true,
        profile_name = profile_name,
    })
    FIRST_RUN_QUICK_SETUP_WINDOW:open()
end
