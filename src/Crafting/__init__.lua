Crafting = Crafting or {}

import "LUI.src.Crafting.crafting_store"
import "LUI.src.Crafting.crafting_window"

local _shared_store = nil
local _tracked_plan_cache = nil

local function _copy_tracked_plan_entries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for i = 1, #entries do
        local entry = entries[i]
        if type(entry) == "table" then
            out[#out + 1] = {
                id = entry.id,
                profession_key = entry.profession_key,
                result_key = entry.result_key,
                recipe_name_key = entry.recipe_name_key,
                category_name_key = entry.category_name_key,
                tier = entry.tier,
                count = entry.count,
            }
        end
    end

    return out
end

local function _tracked_plan_settings()
    if type(_G.loaded_settings) ~= "table" then
        return nil
    end
    if type(_G.loaded_settings.crafting) ~= "table" then
        _G.loaded_settings.crafting = {}
    end
    if type(_G.loaded_settings.crafting.tracked_plan) ~= "table" then
        _G.loaded_settings.crafting.tracked_plan = {}
    end
    if type(_G.loaded_settings.crafting.tracked_plan.entries) ~= "table" then
        _G.loaded_settings.crafting.tracked_plan.entries = {}
    end
    return _G.loaded_settings.crafting.tracked_plan
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
                tostring(entry.id or ""),
                tostring(entry.profession_key or ""),
                tostring(entry.result_key or ""),
                tostring(entry.recipe_name_key or ""),
                tostring(entry.category_name_key or ""),
                tostring(entry.tier or ""),
                tostring(entry.count or ""),
            }, "\31")
        end
    end
    return table.concat(parts, "\30")
end

function Crafting.invalidate_tracked_plan_cache()
    _tracked_plan_cache = nil
end

function Crafting.get_shared_store()
    if _G.LUI_IS_UNLOADING == true then
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
    if type(_G.settings) == "table" and type(_G.settings.crafting) == "table" then
        _G.settings.crafting.tracked_plan = tracked_plan
    end
    Crafting.invalidate_tracked_plan_cache()

    if save_now == true and _G.save_settings ~= nil then
        _G.save_settings()
    end
end

function Crafting.resolve_tracked_plan_entries(store)
    local crafting_store = store or Crafting.get_shared_store()
    if crafting_store == nil or crafting_store.resolve_saved_plan_entries == nil then
        return {
            entries = {},
            unresolved_count = 0,
            total_count = 0,
        }
    end

    local entries = Crafting.get_tracked_plan_entries()
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
    local crafting_store = store or Crafting.get_shared_store()
    if crafting_store == nil or crafting_store.evaluate_plan_resources == nil then
        return nil
    end

    local entries = Crafting.get_tracked_plan_entries()
    local signature = _tracked_plan_signature(entries)
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
