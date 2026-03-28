local function _require_module(module)
    if type(module) ~= "table" then
        error("Invalid settings tab module")
    end
    if module.key == nil then
        error("Settings tab module is missing key")
    end
    if type(module.create_page) ~= "function" then
        error("Settings tab module is missing create_page: " .. tostring(module.key))
    end
    return module
end

local function _add_main_tab(window, module)
    module = _require_module(module)

    local page = module.create_page(window)
    if page == nil then
        error("Settings tab create_page returned nil: " .. tostring(module.key))
    end

    page._tab_key = module.key
    window._tab_pages[module.key] = page
    window.main_tab_index_by_key[module.key] = window.main_tab_bar:add_tab(module.text, page)
    return page
end

local function _normalize_main_tab_request(main_key, preferred_sub_key)
    if type(main_key) ~= "string" then
        return "global", preferred_sub_key
    end

    if main_key == "self_vitals" or main_key == "expiring_effects" or main_key == "cooldowns" then
        return "self", main_key
    end
    if main_key == "target_vitals" or main_key == "target_boss_vitals" or
        main_key == "target_targets_target" or main_key == "expiring_target_effects" then
        return "target", main_key
    end
    if main_key == "party_layout" or main_key == "party_vitals" then
        return "party", main_key
    end

    return main_key, preferred_sub_key
end

local MAIN_TABS_WITH_CONTENT_BORDER = {
    global = true,
    inventory = true,
    assets = true,
    status_bar = true,
    profile_manager = true,
    help = true,
}

local function _apply_main_tab_content_border(window, main_key)
    if window == nil or window.main_tab_bar == nil then
        return
    end

    window.main_tab_bar:set_show_content_border(MAIN_TABS_WITH_CONTENT_BORDER[main_key] == true)
end

function ConfigWindow:_activate_active_page()
    local key = self.active_main_tab
    local page = key ~= nil and self._tab_pages ~= nil and self._tab_pages[key] or nil
    if page == nil and self.main_tab_bar ~= nil then
        page = self.main_tab_bar:get_selected_widget()
    end
    if page == nil then
        return
    end

    if page.on_selected ~= nil then
        page:on_selected()
    elseif page.layout ~= nil then
        page:layout()
    end

    if page.get_active_tab_key ~= nil then
        self.active_tab = page:get_active_tab_key() or key
    elseif key ~= nil then
        self.active_tab = key
    end
end

function ConfigWindow:build_tabs()
    local tabs = _G.LUI_SETTINGS_TABS or {}

    self._tab_pages = {}
    self.main_tab_index_by_key = {}

    _add_main_tab(self, tabs.global)
    _add_main_tab(self, tabs.self)
    _add_main_tab(self, tabs.target)
    _add_main_tab(self, tabs.party)
    _add_main_tab(self, tabs.inventory)
    _add_main_tab(self, tabs.assets)
    _add_main_tab(self, tabs.status_bar)
    _add_main_tab(self, tabs.profile_manager)
    _add_main_tab(self, tabs.help)
end

function ConfigWindow:select_main_tab(main_key, preferred_sub_key)
    main_key, preferred_sub_key = _normalize_main_tab_request(main_key, preferred_sub_key)

    if self.main_tab_index_by_key ~= nil and self.main_tab_index_by_key[main_key] == nil then
        main_key = "global"
        preferred_sub_key = nil
    end

    local page = self._tab_pages ~= nil and self._tab_pages[main_key] or nil
    if page == nil then
        return
    end

    self.active_main_tab = main_key
    _apply_main_tab_content_border(self, main_key)

    self._syncing_tab_widgets = true
    if self.main_tab_bar ~= nil then
        self.main_tab_bar:set_selected_index(self.main_tab_index_by_key[main_key], false)
    end
    self._syncing_tab_widgets = false

    self:hide_hint()
    self:layout()

    if page.on_selected ~= nil then
        page:on_selected(preferred_sub_key)
    elseif page.layout ~= nil then
        page:layout()
    end

    if page.get_active_tab_key ~= nil then
        self.active_tab = page:get_active_tab_key() or main_key
    else
        self.active_tab = main_key
    end
end
