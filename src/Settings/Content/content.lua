import "LUI.src.Settings.Tabs.form_page"

local SettingsFormPage = (_G.LUI_SETTINGS_SHARED ~= nil and _G.LUI_SETTINGS_SHARED.form_page) or
    _G.SettingsFormPage or SettingsFormPage

ConfigContent = class(SettingsFormPage)
_G.ConfigContent = ConfigContent
_G.LUI_SETTINGS_SHARED = _G.LUI_SETTINGS_SHARED or {}
_G.LUI_SETTINGS_SHARED.config_content = ConfigContent

local function _entry_value(entry)
    if entry.tb ~= nil then
        return entry.tb:GetText()
    end
    if entry.button ~= nil then
        return entry.button:GetValue()
    end
    if entry.cb ~= nil then
        return entry.cb:IsChecked()
    end
    error("ConfigContent entry has no readable value control")
end

function ConfigContent:Constructor(window, columns, refresh_preview_fn)
    SettingsFormPage.Constructor(self, window)

    self._bindings = {}
    self:set_compact_fields(true)
    if columns ~= nil then
        self:set_grid_columns(columns)
    end
    if refresh_preview_fn ~= nil then
        self.refresh_preview = refresh_preview_fn
    end
end

function ConfigContent:bind(entry, save_fn, load_fn)
    if type(save_fn) ~= "function" then
        error("ConfigContent binding is missing save_fn")
    end
    if type(load_fn) ~= "function" then
        error("ConfigContent binding is missing load_fn")
    end

    self._bindings[#self._bindings + 1] = {
        entry = entry,
        save = save_fn,
        load = load_fn,
    }

    return entry
end

function ConfigContent:add_line_edit(label_text, key, save_fn, load_fn, help_text, full_width)
    local entry = SettingsFormPage.add_text(self, key, label_text, false, help_text, full_width)
    return self:bind(entry, save_fn, load_fn)
end

function ConfigContent:add_color_picker(label_text, key, save_fn, load_fn, help_text, full_width)
    local entry = SettingsFormPage.add_text(self, key, label_text, true, help_text, full_width)
    return self:bind(entry, save_fn, load_fn)
end

function ConfigContent:add_bound_dropdown(label_text, key, option_labels, option_values, save_fn, load_fn, help_text,
                                          full_width)
    local entry = SettingsFormPage.add_dropdown(self, key, label_text, option_labels, option_values, help_text,
        full_width)
    return self:bind(entry, save_fn, load_fn)
end

function ConfigContent:add_bound_checkbox(label_text, key, save_fn, load_fn, full_width)
    local entry = SettingsFormPage.add_checkbox(self, key, label_text, full_width)
    return self:bind(entry, save_fn, load_fn)
end

function ConfigContent:add_dropdown(key, label_text, option_labels, option_values, help_text, full_width)
    return SettingsFormPage.add_dropdown(self, key, label_text, option_labels, option_values, help_text, full_width)
end

function ConfigContent:add_checkbox(key, label_text, full_width)
    return SettingsFormPage.add_checkbox(self, key, label_text, full_width)
end

function ConfigContent:add_row_break()
    return SettingsFormPage.add_break(self, 0)
end

function ConfigContent:break_line()
    return self:add_row_break()
end

function ConfigContent:load()
    self.loading = true

    for i = 1, #self._bindings do
        local binding = self._bindings[i]
        binding.load(binding.entry, self)
    end

    self.loading = false
    self:update_all_swatches()
    self:layout()
end

function ConfigContent:save()
    for i = 1, #self._bindings do
        local binding = self._bindings[i]
        binding.save(_entry_value(binding.entry), binding.entry, self)
    end
end
