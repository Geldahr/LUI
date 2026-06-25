-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local MAX_MIGRATION_STEPS = 50
local Migrations = _G.LUI.Settings.Migrations

local function _current_settings_version()
    return tostring(Plugins["LUI"]:GetVersion())
end

local function _default_migration(config)
    config.version = _current_settings_version()
    return config
end

local function _make_migration_registry(existing)
    local registry = existing
    if type(registry) ~= "table" then
        registry = {}
    end

    return setmetatable(registry, {
        __index = function(t, key)
            local fn = rawget(t, key)
            if type(fn) == "function" then
                return fn
            end

            return function(config)
                return _default_migration(config)
            end
        end,
    })
end

Migrations.Registry = Migrations.Registry or {}
Migrations.Registry.account = _make_migration_registry(Migrations.Registry.account)
Migrations.Registry.profile = _make_migration_registry(Migrations.Registry.profile)
Migrations.Registry.character = _make_migration_registry(Migrations.Registry.character)

function Migrations.get_settings_version()
    return _current_settings_version()
end

function Migrations.register_settings_migration(version, step)
    if type(version) ~= "string" then
        error("Settings migration version must be a string")
    end
    if type(step) ~= "table" then
        error("Settings migration step must be a table")
    end

    local registries = Migrations.Registry
    local registered = false
    if type(step.account) == "function" then
        if type(rawget(registries.account, version)) == "function" then
            error("Duplicate account settings migration: " .. version)
        end
        registries.account[version] = step.account
        registered = true
    end
    if type(step.profile) == "function" then
        if type(rawget(registries.profile, version)) == "function" then
            error("Duplicate profile settings migration: " .. version)
        end
        registries.profile[version] = step.profile
        registered = true
    end
    if type(step.character) == "function" then
        if type(rawget(registries.character, version)) == "function" then
            error("Duplicate character settings migration: " .. version)
        end
        registries.character[version] = step.character
        registered = true
    end

    if registered ~= true then
        error("Settings migration step must define account, profile, or character")
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

function Migrations.migrate_account_settings(config)
    return _run_migrations(config, Migrations.Registry.account)
end

function Migrations.migrate_profile_settings(config)
    return _run_migrations(config, Migrations.Registry.profile)
end

function Migrations.migrate_character_settings(config)
    return _run_migrations(config, Migrations.Registry.character)
end
