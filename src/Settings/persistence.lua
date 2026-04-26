local ACCOUNT_DATA_SCOPE = Turbine.DataScope.Account
local SERVER_DATA_SCOPE = Turbine.DataScope.Server

local ACCOUNT_DATA_KEY = "LUI_PROFILES"
local SERVER_DATA_KEY = "LUI_CHARACTERS"
local SERVER_ASSETS_CACHE_KEY = "LUI_ASSETS_CACHE"
local SERVER_BESTIARY_CACHE_KEY = "LUI_BESTIARY_CACHE"

local FALLBACK_PROFILE_NAME = "Configuration"
local UNKNOWN_CHARACTER_NAME = "__unknown_character__"

local function _copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = _copy_table(v)
    end

    return copy
end

local function _trim(text)
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

local function _get_current_character_name()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetName == nil then
        return UNKNOWN_CHARACTER_NAME
    end

    local name = player:GetName()
    if type(name) ~= "string" or string.len(name) == 0 then
        return UNKNOWN_CHARACTER_NAME
    end

    return name
end

local function _profile_label(profile_id, profile)
    local name = profile.name
    if type(name) == "string" and string.len(name) > 0 then
        return name
    end

    return FALLBACK_PROFILE_NAME .. " " .. tostring(profile_id)
end

local function _sync_current_profile_settings()
    _G.ensure_account_settings()

    if _G.current_profile_id == nil then
        local profile_id = _G.create_configuration(_G.current_character_name, _G.loaded_settings)
        _G.assign_character_profile(profile_id)
        return
    end

    local profile = _G.account_settings.profiles[_G.current_profile_id]
    if type(profile) ~= "table" then
        local profile_id = _G.create_configuration(_G.current_character_name, _G.loaded_settings)
        _G.assign_character_profile(profile_id)
        return
    end

    if type(profile.name) ~= "string" or string.len(profile.name) == 0 then
        profile.name = _G.current_character_name
    end

    profile.settings = _G.loaded_settings
end

function _G.ensure_account_settings()
    if type(_G.account_settings) ~= "table" then
        _G.account_settings = {}
    end

    local s = _G.account_settings
    if type(s.profiles) ~= "table" then
        s.profiles = {}
    end
    if type(s.next_profile_id) ~= "number" or s.next_profile_id < 1 then
        s.next_profile_id = 1
    end
end

function _G.ensure_server_settings()
    if type(_G.server_settings) ~= "table" then
        _G.server_settings = {}
    end

    local s = _G.server_settings
    if type(s.characters) ~= "table" then
        s.characters = {}
    end
end

local function _merge_assets_cache(loaded)
    if type(loaded) ~= "table" then
        return
    end

    if type(_G.assets_cache) ~= "table" or next(_G.assets_cache) == nil then
        _G.assets_cache = loaded
        return
    end

    local current = _G.assets_cache
    if type(current.characters) ~= "table" then
        current.characters = {}
    end
    if type(loaded.characters) == "table" then
        for character_name, loaded_character_cache in pairs(loaded.characters) do
            if type(current.characters[character_name]) ~= "table" then
                current.characters[character_name] = loaded_character_cache
            elseif type(loaded_character_cache) == "table" then
                local current_character_cache = current.characters[character_name]
                local source_names = { "backpack", "bank", "vault" }
                for i = 1, #source_names do
                    local source_name = source_names[i]
                    local current_source = current_character_cache[source_name]
                    local loaded_source = loaded_character_cache[source_name]
                    if type(current_source) ~= "table" or type(current_source.items) ~= "table" or #current_source.items <= 0 then
                        current_character_cache[source_name] = loaded_source
                    end
                end
            end
        end
    end

    if type(current.shared_storage) ~= "table" or type(current.shared_storage.items) ~= "table" or #current.shared_storage.items <= 0 then
        current.shared_storage = loaded.shared_storage
    end
end

local function _merge_count_map(target, source)
    if type(source) ~= "table" then
        return
    end
    if type(target) ~= "table" then
        return
    end

    for key, value in pairs(source) do
        target[key] = (tonumber(target[key]) or 0) + (tonumber(value) or 0)
    end
end

local function _merge_bestiary_cache(loaded)
    if type(loaded) ~= "table" then
        return
    end

    if type(_G.bestiary_cache) ~= "table" or next(_G.bestiary_cache) == nil then
        _G.bestiary_cache = loaded
        return
    end

    local current = _G.bestiary_cache
    for name, loaded_entry in pairs(loaded) do
        if type(current[name]) ~= "table" then
            current[name] = loaded_entry
        elseif type(loaded_entry) == "table" then
            local current_entry = current[name]
            current_entry.k = (tonumber(current_entry.k) or 0) + (tonumber(loaded_entry.k) or 0)
            if type(current_entry.levels) ~= "table" then
                current_entry.levels = {}
            end
            if type(current_entry.d) ~= "table" then
                current_entry.d = {}
            end
            _merge_count_map(current_entry.levels, loaded_entry.levels)
            _merge_count_map(current_entry.d, loaded_entry.d)
        end
    end
end

function _G.ensure_assets_cache()
    if _G.assets_cache_loaded ~= true and _G.assets_cache_loading ~= true then
        _G.assets_cache_loading = true
        local loaded = Turbine.PluginData.Load(SERVER_DATA_SCOPE, SERVER_ASSETS_CACHE_KEY, function(data)
            if _G.LUI_IS_UNLOADING == true then
                return
            end
            _merge_assets_cache(data)
            _G.assets_cache_loaded = true
            _G.assets_cache_loading = false
            if _G.assets_cache_dirty ~= true then
                _G.assets_cache_dirty = false
            end
            if _G.ASSETS_STORE ~= nil then
                _G.ASSETS_STORE.generation = (tonumber(_G.ASSETS_STORE.generation) or 0) + 1
            end
        end)
        if loaded ~= nil then
            _merge_assets_cache(loaded)
            _G.assets_cache_loaded = true
            _G.assets_cache_loading = false
            if _G.assets_cache_dirty ~= true then
                _G.assets_cache_dirty = false
            end
        end
    end

    if type(_G.assets_cache) ~= "table" then
        _G.assets_cache = {}
    end

    local cache = _G.assets_cache
    if type(cache.characters) ~= "table" then
        cache.characters = {}
    end
    if type(cache.shared_storage) ~= "table" then
        cache.shared_storage = { items = {} }
    elseif type(cache.shared_storage.items) ~= "table" then
        cache.shared_storage.items = {}
    end

    return cache
end

function _G.ensure_bestiary_cache()
    if _G.bestiary_cache_loaded ~= true and _G.bestiary_cache_loading ~= true then
        _G.bestiary_cache_loading = true
        local loaded = Turbine.PluginData.Load(SERVER_DATA_SCOPE, SERVER_BESTIARY_CACHE_KEY, function(data)
            if _G.LUI_IS_UNLOADING == true then
                return
            end
            _merge_bestiary_cache(data)
            _G.bestiary_cache_loaded = true
            _G.bestiary_cache_loading = false
            if _G.bestiary_cache_dirty ~= true then
                _G.bestiary_cache_dirty = false
            end
            _G.bestiary_cache_generation = (_G.bestiary_cache_generation or 0) + 1
        end)
        if loaded ~= nil then
            _merge_bestiary_cache(loaded)
            _G.bestiary_cache_loaded = true
            _G.bestiary_cache_loading = false
            if _G.bestiary_cache_dirty ~= true then
                _G.bestiary_cache_dirty = false
            end
        end
    end

    if type(_G.bestiary_cache) ~= "table" then
        _G.bestiary_cache = {}
    end
    if type(_G.bestiary_cache_generation) ~= "number" then
        _G.bestiary_cache_generation = 1
    end

    return _G.bestiary_cache
end

function _G.create_configuration(name, settings)
    _G.ensure_account_settings()

    local s = _G.account_settings
    local profile_id = tostring(s.next_profile_id)
    s.next_profile_id = s.next_profile_id + 1

    s.profiles[profile_id] = {
        name = name,
        settings = settings,
    }

    return profile_id
end

function _G.assign_character_profile(profile_id)
    _G.ensure_account_settings()
    _G.ensure_server_settings()

    local profile = _G.account_settings.profiles[profile_id]
    if type(profile) ~= "table" or type(profile.settings) ~= "table" then
        return false
    end

    local character_name = _G.current_character_name or _get_current_character_name()
    local character_entry = _G.server_settings.characters[character_name]
    if type(character_entry) ~= "table" then
        character_entry = {}
        _G.server_settings.characters[character_name] = character_entry
    end
    character_entry.profile_id = profile_id

    _G.current_character_name = character_name
    _G.current_profile_id = profile_id
    _G.loaded_settings = profile.settings
    return true
end

function _G.get_configuration_options()
    _G.ensure_account_settings()

    local entries = {}
    for profile_id, profile in pairs(_G.account_settings.profiles) do
        if type(profile) == "table" and type(profile.settings) == "table" then
            entries[#entries + 1] = {
                label = _profile_label(profile_id, profile),
                value = profile_id,
            }
        end
    end

    table.sort(entries, function(a, b)
        local left = string.lower(a.label)
        local right = string.lower(b.label)
        if left == right then
            return tostring(a.value) < tostring(b.value)
        end
        return left < right
    end)

    local labels = {}
    local values = {}
    for i = 1, #entries do
        labels[i] = entries[i].label
        values[i] = entries[i].value
    end

    return labels, values
end

function _G.get_configuration(profile_id)
    _G.ensure_account_settings()
    return _G.account_settings.profiles[profile_id]
end

function _G.get_configuration_name(profile_id)
    local profile = _G.get_configuration(profile_id)
    if type(profile) ~= "table" then
        return nil
    end

    return _profile_label(profile_id, profile)
end

function _G.get_configuration_count()
    _G.ensure_account_settings()

    local count = 0
    for _, profile in pairs(_G.account_settings.profiles) do
        if type(profile) == "table" and type(profile.settings) == "table" then
            count = count + 1
        end
    end

    return count
end

function _G.get_first_configuration_id()
    local _, values = _G.get_configuration_options()
    return values[1]
end

function _G.rename_configuration(profile_id, name)
    _G.ensure_account_settings()

    local profile = _G.account_settings.profiles[profile_id]
    local trimmed_name = _trim(name)
    if type(profile) ~= "table" or trimmed_name == nil then
        return false
    end

    profile.name = trimmed_name
    return true
end

function _G.duplicate_configuration(profile_id)
    _G.ensure_account_settings()

    local profile = _G.account_settings.profiles[profile_id]
    if type(profile) ~= "table" or type(profile.settings) ~= "table" then
        return nil
    end

    local duplicate_name = _profile_label(profile_id, profile) .. " (copy)"
    local duplicate_settings = _copy_table(profile.settings)
    return _G.create_configuration(duplicate_name, duplicate_settings)
end

function _G.delete_configuration(profile_id)
    _G.ensure_account_settings()
    _G.ensure_server_settings()

    if _G.get_configuration_count() <= 1 then
        return false
    end

    local profile = _G.account_settings.profiles[profile_id]
    if type(profile) ~= "table" then
        return false
    end

    _G.account_settings.profiles[profile_id] = nil

    for character_name, entry in pairs(_G.server_settings.characters) do
        if type(entry) == "table" and entry.profile_id == profile_id then
            entry.profile_id = nil
            if next(entry) == nil then
                _G.server_settings.characters[character_name] = nil
            end
        end
    end

    if _G.current_profile_id == profile_id then
        _G.current_profile_id = nil
    end

    return true
end

function _G.save_settings()
    _G.ensure_account_settings()
    _G.ensure_server_settings()

    if _G.capture_runtime_geometry ~= nil then
        _G.capture_runtime_geometry()
    end

    _sync_current_profile_settings()

    Turbine.PluginData.Save(ACCOUNT_DATA_SCOPE, ACCOUNT_DATA_KEY, _G.account_settings)
    Turbine.PluginData.Save(SERVER_DATA_SCOPE, SERVER_DATA_KEY, _G.server_settings)
end

function _G.capture_runtime_geometry()
    if CONFIG_WINDOW ~= nil and CONFIG_WINDOW.update_saved_geometry ~= nil then
        CONFIG_WINDOW:update_saved_geometry()
    end

    if INVENTORY_WINDOW ~= nil then
        if INVENTORY_WINDOW.capture_geometry ~= nil then
            INVENTORY_WINDOW:capture_geometry()
        elseif INVENTORY_WINDOW.persist_geometry ~= nil then
            INVENTORY_WINDOW:persist_geometry()
        end
    end

    if ASSETS_WINDOW ~= nil then
        if ASSETS_WINDOW.capture_geometry ~= nil then
            ASSETS_WINDOW:capture_geometry()
        elseif ASSETS_WINDOW.persist_geometry ~= nil then
            ASSETS_WINDOW:persist_geometry()
        end
    end

    if BESTIARY_WINDOW ~= nil then
        if BESTIARY_WINDOW.capture_geometry ~= nil then
            BESTIARY_WINDOW:capture_geometry()
        elseif BESTIARY_WINDOW.persist_geometry ~= nil then
            BESTIARY_WINDOW:persist_geometry()
        end
    end

    if _G.LUI_IS_UNLOADING ~= true and CRAFTING_WINDOW ~= nil then
        if CRAFTING_WINDOW.capture_geometry ~= nil then
            CRAFTING_WINDOW:capture_geometry()
        elseif CRAFTING_WINDOW.persist_geometry ~= nil then
            CRAFTING_WINDOW:persist_geometry()
        end
    end

    if _G.LUI_IS_UNLOADING ~= true and TRAVEL_WINDOW ~= nil then
        if TRAVEL_WINDOW.capture_geometry ~= nil then
            TRAVEL_WINDOW:capture_geometry()
        elseif TRAVEL_WINDOW.persist_geometry ~= nil then
            TRAVEL_WINDOW:persist_geometry()
        end
    end
end

function _G.save_assets_cache()
    if _G.assets_cache_dirty ~= true then
        return
    end
    if type(_G.assets_cache) ~= "table" then
        _G.assets_cache = {}
    end
    Turbine.PluginData.Save(SERVER_DATA_SCOPE, SERVER_ASSETS_CACHE_KEY, _G.assets_cache)
    _G.assets_cache_dirty = false
end

function _G.save_bestiary_cache()
    if _G.bestiary_cache_dirty ~= true then
        return
    end
    if type(_G.bestiary_cache) ~= "table" then
        _G.bestiary_cache = {}
    end
    Turbine.PluginData.Save(SERVER_DATA_SCOPE, SERVER_BESTIARY_CACHE_KEY, _G.bestiary_cache)
    _G.bestiary_cache_dirty = false
end

function _G.load_settings()
    _G.account_settings = Turbine.PluginData.Load(ACCOUNT_DATA_SCOPE, ACCOUNT_DATA_KEY)
    _G.server_settings = Turbine.PluginData.Load(SERVER_DATA_SCOPE, SERVER_DATA_KEY)
    _G.assets_cache = nil
    _G.assets_cache_loaded = false
    _G.assets_cache_loading = false
    _G.assets_cache_dirty = false
    _G.bestiary_cache = nil
    _G.bestiary_cache_loaded = false
    _G.bestiary_cache_loading = false
    _G.bestiary_cache_dirty = false

    _G.ensure_account_settings()
    _G.ensure_server_settings()

    _G.current_character_name = _get_current_character_name()
    _G.current_profile_id = nil

    local character_entry = _G.server_settings.characters[_G.current_character_name]
    local profile_id = nil
    if type(character_entry) == "table" then
        profile_id = character_entry.profile_id
    end

    local profile = nil
    if profile_id ~= nil then
        profile = _G.account_settings.profiles[profile_id]
        if type(profile) ~= "table" then
            character_entry.profile_id = nil
        end
    end

    _G.loaded_settings_was_new = true
    if type(profile) == "table" and type(profile.settings) == "table" then
        _G.current_profile_id = profile_id
        _G.loaded_settings = profile.settings
        _G.loaded_settings_was_new = false
    else
        _G.loaded_settings = {}
    end

    _G.ensure_loaded_settings()
    _G.fix_colors()
    _G.rebuild_settings()
end
