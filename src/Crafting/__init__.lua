Crafting = Crafting or {}

import "LUI.src.Crafting.crafting_store"
import "LUI.src.Crafting.crafting_window"

local _shared_store = nil
local _tracked_plan_cache = nil
local _tracked_plan_autoload_after = nil

local function _is_enabled()
    return type(_G.settings) == "table" and type(_G.settings.crafting) == "table" and _G.settings.crafting.enabled == true
end

local function _copy_tracked_plan_entries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            local count = math.floor((tonumber(entry.q) or 0) + 0.5)
            if entry.i ~= nil and count > 0 then
                out[#out + 1] = {
                    i = entry.i,
                    p = entry.p,
                    r = entry.r,
                    n = entry.n,
                    c = entry.c,
                    q = count,
                }
            end
        end
    end

    return out
end

local function _copy_favorite_entries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" and entry.p ~= nil and entry.r ~= nil then
            out[#out + 1] = {
                i = entry.i,
                p = entry.p,
                r = entry.r,
                n = entry.n,
                c = entry.c,
            }
        end
    end

    return out
end

local function _current_character_entry()
    if _G.ensure_server_settings ~= nil then
        _G.ensure_server_settings()
    end
    if type(_G.server_settings) ~= "table" or type(_G.server_settings.characters) ~= "table" then
        return nil
    end

    local character_name = _G.current_character_name
    if type(character_name) ~= "string" or string.len(character_name) == 0 then
        return nil
    end

    local entry = _G.server_settings.characters[character_name]
    if type(entry) ~= "table" then
        entry = {}
        _G.server_settings.characters[character_name] = entry
    end
    return entry
end

local function _character_crafting_settings()
    local entry = _current_character_entry()
    if entry == nil then
        return nil
    end

    if type(entry.crafting) ~= "table" then
        entry.crafting = {}
    end
    return entry.crafting
end

local function _character_section_settings(section_key)
    local crafting = _character_crafting_settings()
    if crafting == nil then
        return nil
    end

    if type(crafting[section_key]) ~= "table" then
        crafting[section_key] = {}
    end
    local section = crafting[section_key]
    if type(section.entries) ~= "table" then
        section.entries = {}
    end

    return section
end

local function _tracked_plan_settings()
    return _character_section_settings("tracked_plan")
end

local function _favorite_settings()
    return _character_section_settings("favorites")
end

local function _tracked_plan_signature(entries)
    local parts = {}
    if type(entries) ~= "table" then
        return ""
    end
    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            parts[#parts + 1] = table.concat({
                tostring(entry.i or ""),
                tostring(entry.p or ""),
                tostring(entry.r or ""),
                tostring(entry.n or ""),
                tostring(entry.c or ""),
                tostring(entry.q or ""),
            }, "\31")
        end
    end
    return table.concat(parts, "\30")
end

function Crafting.invalidate_tracked_plan_cache()
    _tracked_plan_cache = nil
end

function Crafting.is_enabled()
    return _is_enabled()
end

function Crafting.get_shared_store()
    if _G.LUI_IS_UNLOADING == true or _is_enabled() ~= true then
        return nil
    end
    if _shared_store == nil then
        _shared_store = CraftingStore()
        _G.CRAFTING_STORE = _shared_store
    end
    return _shared_store
end

function Crafting.destroy_shared_store()
    if _shared_store ~= nil and _shared_store.destroy ~= nil then
        _shared_store:destroy()
    end
    _shared_store = nil
    _G.CRAFTING_STORE = nil
    _tracked_plan_autoload_after = nil
    Crafting.invalidate_tracked_plan_cache()
end

function Crafting.get_tracked_plan_entries()
    local tracked_plan = _tracked_plan_settings()
    return _copy_tracked_plan_entries(tracked_plan ~= nil and tracked_plan.entries or nil)
end

function Crafting.set_tracked_plan_entries(entries, save_now)
    local tracked_plan = _tracked_plan_settings()
    if tracked_plan == nil then
        return
    end

    tracked_plan.entries = _copy_tracked_plan_entries(entries)
    Crafting.invalidate_tracked_plan_cache()
    _tracked_plan_autoload_after = nil

    if save_now == true and _G.save_settings ~= nil then
        _G.save_settings()
    end
end

function Crafting.get_favorite_recipe_entries()
    local favorites = _favorite_settings()
    return _copy_favorite_entries(favorites ~= nil and favorites.entries or nil)
end

function Crafting.set_favorite_recipe_entries(entries, save_now)
    local favorites = _favorite_settings()
    if favorites == nil then
        return
    end

    favorites.entries = _copy_favorite_entries(entries)

    if save_now == true and _G.save_settings ~= nil then
        _G.save_settings()
    end
end

function Crafting.resolve_tracked_plan_entries(store)
    local entries = Crafting.get_tracked_plan_entries()
    if #entries <= 0 then
        return {
            entries = {},
            unresolved_count = 0,
            total_count = 0,
        }
    end

    local crafting_store = store or _G.CRAFTING_STORE
    if crafting_store == nil or crafting_store.resolve_saved_plan_entries == nil then
        return {
            entries = {},
            unresolved_count = #entries,
            total_count = #entries,
        }
    end

    local signature = _tracked_plan_signature(entries)
    local store_version = tonumber(crafting_store.version) or 0
    if type(_tracked_plan_cache) == "table" and _tracked_plan_cache.signature == signature and
        _tracked_plan_cache.store_version == store_version and _tracked_plan_cache.resolved ~= nil then
        return _tracked_plan_cache.resolved
    end

    local resolved = crafting_store:resolve_saved_plan_entries(entries)
    _tracked_plan_cache = {
        signature = signature,
        store_version = store_version,
        resolved = resolved,
    }
    return resolved
end

function Crafting.get_tracked_plan_resource_state(store)
    local entries = Crafting.get_tracked_plan_entries()
    local signature = _tracked_plan_signature(entries)
    if _is_enabled() ~= true then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = 0,
            unresolved_count = 0,
            total_entry_count = 0,
            loading = false,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end
    if #entries <= 0 then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = 0,
            unresolved_count = 0,
            total_entry_count = 0,
            loading = false,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end

    local crafting_store = store or _G.CRAFTING_STORE
    if store == nil and crafting_store == nil and _G.LUI_IS_UNLOADING ~= true then
        local now = Turbine.Engine.GetGameTime()
        if _tracked_plan_autoload_after == nil then
            _tracked_plan_autoload_after = now + 1.50
        end
        if now >= _tracked_plan_autoload_after then
            crafting_store = Crafting.get_shared_store()
            _tracked_plan_autoload_after = nil
        end
    end

    if crafting_store == nil or crafting_store.evaluate_plan_resources == nil then
        return {
            resources = {},
            incomplete_resources = {},
            ready = false,
            saved_entry_count = #entries,
            unresolved_count = #entries,
            total_entry_count = #entries,
            loading = _G.LUI_IS_UNLOADING ~= true,
            loading_loaded = 0,
            loading_total = 0,
            loading_complete = false,
        }
    end

    local store_version = tonumber(crafting_store.version) or 0
    if type(_tracked_plan_cache) == "table" and _tracked_plan_cache.signature == signature and
        _tracked_plan_cache.store_version == store_version and _tracked_plan_cache.resource_state ~= nil then
        return _tracked_plan_cache.resource_state
    end

    local resolved = Crafting.resolve_tracked_plan_entries(crafting_store)
    local resource_state = crafting_store:evaluate_plan_resources(resolved.entries, "inventory")
    resource_state.saved_entry_count = #entries
    resource_state.unresolved_count = resolved.unresolved_count or 0
    resource_state.total_entry_count = resolved.total_count or #entries
    local progress = crafting_store.get_loading_progress ~= nil and crafting_store:get_loading_progress() or nil
    resource_state.loading = progress ~= nil and progress.loading == true
    resource_state.loading_loaded = progress ~= nil and (tonumber(progress.loaded) or 0) or 0
    resource_state.loading_total = progress ~= nil and (tonumber(progress.total) or 0) or 0
    resource_state.loading_complete = progress ~= nil and progress.complete == true

    _tracked_plan_cache = {
        signature = signature,
        store_version = store_version,
        resolved = resolved,
        resource_state = resource_state,
    }
    return resource_state
end

Crafting.CraftingStore = CraftingStore
Crafting.CraftingWindow = CraftingWindow
