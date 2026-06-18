-- Example migration file.
-- This file is intentionally not imported. It exists only as a template.

local VERSION = "0.6.0"
local Migrations = _G.LUI.Settings.Migrations

local function migrate_account(account_settings)
    account_settings.some_removed_root_field = nil
    account_settings.version = "0.6.5"
    return account_settings
end

local function migrate_profile(profile_settings)
    profile_settings.color = nil
    profile_settings.window = profile_settings.window or {}
    profile_settings.window.height = profile_settings.height
    profile_settings.height = nil
    profile_settings.new_value = "hello"
    profile_settings.version = "0.6.5"
    return profile_settings
end

local function migrate_character(character_settings)
    character_settings.legacy_flag = nil
    character_settings.version = "0.6.5"
    return character_settings
end

Migrations.register_settings_migration(VERSION, {
    account = migrate_account,
    profile = migrate_profile,
    character = migrate_character,
})
