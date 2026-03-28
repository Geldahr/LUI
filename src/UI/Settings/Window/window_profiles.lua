local function _capture_runtime_geometry()
    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
    end
end

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

function ConfigWindow:_controls_for_tab(key)
    local page = nil
    if self.main_tab_bar ~= nil then
        _, page = self.main_tab_bar:find_index(function(_, candidate)
            return candidate ~= nil and candidate._tab_key == key
        end)
    end
    if page ~= nil and page.controls ~= nil then
        return page.controls
    end
    return self.controls
end

function ConfigWindow:use_selected_profile()
    local controls = self:_controls_for_tab("profile_manager")
    local profile_control = controls ~= nil and controls.profile_manager_profile or nil
    if profile_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil or profile_id == _G.current_profile_id then
        return
    end

    _capture_runtime_geometry()

    if assign_character_profile(profile_id) ~= true then
        return
    end

    _refresh_runtime_after_profile_change(self, profile_id)
end

function ConfigWindow:rename_selected_profile()
    local controls = self:_controls_for_tab("profile_manager")
    local profile_control = controls ~= nil and controls.profile_manager_profile or nil
    local name_control = controls ~= nil and controls.profile_manager_name or nil
    if profile_control == nil or name_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil then
        return
    end

    if rename_configuration(profile_id, name_control.tb:GetText()) ~= true then
        return
    end

    _save_profile_manager_state(self, profile_id)
end

function ConfigWindow:confirm_delete_selected_profile()
    local controls = self:_controls_for_tab("profile_manager")
    local profile_control = controls ~= nil and controls.profile_manager_profile or nil
    if profile_control == nil or profile_control.get_value == nil then
        return
    end

    local profile_id = profile_control:get_value()
    if profile_id == nil or get_configuration_count() <= 1 then
        return
    end

    local profile_name = get_configuration_name(profile_id) or TR("Profile")
    local message = table.concat({
        string.format(TR("Delete profile '%s'?"), profile_name),
        TR("This will delete it for all characters using it."),
        TR("This action cannot be undone."),
    }, "\n")

    self:show_confirmation_dialog(message, TR("Delete"), function()
        local deleting_current_profile = profile_id == _G.current_profile_id
        if delete_configuration(profile_id) ~= true then
            return
        end

        local selected_profile_id = self.profile_manager_selected_profile_id
        if deleting_current_profile == true then
            local fallback_profile_id = get_first_configuration_id()
            if fallback_profile_id ~= nil then
                assign_character_profile(fallback_profile_id)
                ensure_loaded_settings()
                self:refresh_runtime_settings()
                selected_profile_id = fallback_profile_id
            end
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

    _capture_runtime_geometry()

    local duplicate_profile_id = duplicate_configuration(_G.current_profile_id)
    if duplicate_profile_id == nil then
        return
    end

    if assign_character_profile(duplicate_profile_id) ~= true then
        return
    end

    _refresh_runtime_after_profile_change(self, duplicate_profile_id)
end

function ConfigWindow:start_new_profile_quick_setup()
    self:hide_confirmation_dialog()
    self:SetVisible(false)

    FIRST_RUN_QUICK_SETUP_WINDOW = UI.Settings.FirstRunQuickSetup({
        skip_existing_configurations = true,
        create_profile_on_finish = true,
    })
    FIRST_RUN_QUICK_SETUP_WINDOW:open()
end
