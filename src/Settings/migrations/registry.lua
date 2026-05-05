local MAX_MIGRATION_STEPS = 50

local function _current_settings_version()
    return tostring(Plugins["LUI"]:GetVersion())
end

_G.SETTINGS_MIGRATIONS = _G.SETTINGS_MIGRATIONS or {
    account = {},
    profile = {},
    character = {},
}

function _G.get_settings_version()
    return _current_settings_version()
end

function _G.register_settings_migration(version, step)
    if type(version) ~= "string" then
        error("Settings migration version must be a string")
    end
    if type(step) ~= "table" then
        error("Settings migration step must be a table")
    end

    local registries = _G.SETTINGS_MIGRATIONS
    if type(step.account) == "function" then
        registries.account[version] = step.account
    end
    if type(step.profile) == "function" then
        registries.profile[version] = step.profile
    end
    if type(step.character) == "function" then
        registries.character[version] = step.character
    end
end

local function _run_migrations(config, registry)
    if type(config) ~= "table" then
        return nil, false
    end
    if type(config.version) ~= "string" then
        return nil, false
    end

    local current_version = _current_settings_version()
    local changed = false
    local safety = 0

    while config.version ~= current_version do
        safety = safety + 1
        if safety > MAX_MIGRATION_STEPS then
            return nil, changed
        end

        local from_version = config.version
        local step = registry[from_version]
        if type(step) ~= "function" then
            return nil, changed
        end

        local next_config = step(config)
        if type(next_config) ~= "table" then
            return nil, changed
        end
        if next_config.version == from_version then
            return nil, changed
        end

        config = next_config
        changed = true
    end

    return config, changed
end

function _G.migrate_account_settings(config)
    return _run_migrations(config, _G.SETTINGS_MIGRATIONS.account)
end

function _G.migrate_profile_settings(config)
    return _run_migrations(config, _G.SETTINGS_MIGRATIONS.profile)
end

function _G.migrate_character_settings(config)
    return _run_migrations(config, _G.SETTINGS_MIGRATIONS.character)
end
