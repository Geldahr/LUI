Bestiary = Bestiary or {}
Bestiary.DataAccess = Bestiary.DataAccess or {}

local BUILTIN_BESTIARY = Bestiary.Data or {}

local function _trim(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function _lower(text)
    if type(text) ~= "string" then
        return ""
    end

    return string.lower(text)
end

local function _normalize_name(name)
    name = _trim(name)
    if name == nil then
        return nil
    end

    local lowered = string.lower(name)
    if string.sub(lowered, 1, 4) == "the " then
        name = _trim(string.sub(name, 5))
    end

    name = name:gsub("%s*%.+$", "")
    name = _trim(name)
    if name == nil or name == "" then
        return nil
    end

    return name
end

local function _normalized_lower(name)
    local normalized = _normalize_name(name)
    if normalized ~= nil then
        return _lower(normalized)
    end

    return _lower(_trim(name))
end

local function _alias_target(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return _trim(entry.alias)
end

local function _is_alias_entry(entry)
    return _alias_target(entry) ~= nil
end

local function _entry_base_name(name, entry)
    if type(entry) == "table" and type(entry.bn) == "string" and entry.bn ~= "" then
        return entry.bn
    end
    if type(entry) == "table" and type(entry.n) == "string" and entry.n ~= "" then
        return entry.n
    end

    return name
end

local function _copy_array(values)
    if type(values) ~= "table" then
        return nil
    end

    local out = {}
    for i = 1, #values do
        out[i] = values[i]
    end

    return out
end

local function _build_source_index(source)
    local index = {
        source = source,
        keys_by_lower = {},
        aliases_by_lower = {},
        first_key_by_base_lower = {},
        group_keys_by_base_lower = {},
    }

    if type(source) ~= "table" then
        return index
    end

    for name, entry in pairs(source) do
        if type(name) == "string" and type(entry) == "table" then
            local raw_lower = _lower(name)
            if raw_lower ~= "" then
                index.keys_by_lower[raw_lower] = name
            end

            local normalized_lower = _normalized_lower(name)
            if normalized_lower ~= "" then
                index.keys_by_lower[normalized_lower] = name
            end
        end
    end

    for name, entry in pairs(source) do
        if type(name) == "string" and type(entry) == "table" then
            local alias_target = _alias_target(entry)
            if alias_target ~= nil then
                local raw_lower = _lower(name)
                if raw_lower ~= "" then
                    index.aliases_by_lower[raw_lower] = alias_target
                end

                local normalized_lower = _normalized_lower(name)
                if normalized_lower ~= "" then
                    index.aliases_by_lower[normalized_lower] = alias_target
                end
            else
                local base_name = _entry_base_name(name, entry)
                local base_lower = _normalized_lower(base_name)
                local group_keys = index.group_keys_by_base_lower[base_lower]
                if type(group_keys) ~= "table" then
                    group_keys = {}
                    index.group_keys_by_base_lower[base_lower] = group_keys
                    index.first_key_by_base_lower[base_lower] = name
                end
                group_keys[#group_keys + 1] = name
            end
        end
    end

    return index
end

local BUILTIN_INDEX = nil
local CACHE_INDEX = nil
local CACHE_GENERATION = nil

function Bestiary.DataAccess.get_builtin_index()
    if BUILTIN_INDEX == nil or BUILTIN_INDEX.source ~= BUILTIN_BESTIARY then
        BUILTIN_INDEX = _build_source_index(BUILTIN_BESTIARY)
    end

    return BUILTIN_INDEX
end

function Bestiary.DataAccess.get_cache_index()
    local source = _G.bestiary_cache
    local generation = _G.bestiary_cache_generation or 0
    if CACHE_INDEX == nil or CACHE_INDEX.source ~= source or CACHE_GENERATION ~= generation then
        CACHE_INDEX = _build_source_index(source)
        CACHE_GENERATION = generation
    end

    return CACHE_INDEX
end

local function _resolve_key(source, index, name)
    if type(source) ~= "table" then
        return nil
    end

    local normalized = _normalize_name(name)
    if normalized == nil then
        return nil
    end

    local lowered = _lower(normalized)
    local alias_target = type(index) == "table" and index.aliases_by_lower[lowered] or nil
    if alias_target ~= nil then
        local alias_key = type(index) == "table" and index.keys_by_lower[_lower(alias_target)] or nil
        return alias_key or alias_target
    end

    local direct_key = type(index) == "table" and index.keys_by_lower[lowered] or nil
    if direct_key == nil and type(source[normalized]) == "table" then
        direct_key = normalized
    end
    if type(direct_key) == "string" then
        local direct_entry = source[direct_key]
        local nested_alias = _alias_target(direct_entry)
        if nested_alias ~= nil then
            local nested_key = type(index) == "table" and index.keys_by_lower[_lower(nested_alias)] or nil
            return nested_key or nested_alias
        end

        return direct_key
    end

    return type(index) == "table" and index.first_key_by_base_lower[lowered] or nil
end

function Bestiary.DataAccess.resolve_entry(source, index, name)
    local resolved_key = _resolve_key(source, index, name)
    if type(resolved_key) ~= "string" then
        return nil, nil
    end

    local entry = source[resolved_key]
    if type(entry) ~= "table" or _is_alias_entry(entry) == true then
        return nil, nil
    end

    return resolved_key, entry
end

function Bestiary.DataAccess.resolve_builtin_name(name)
    local resolved_key = _resolve_key(BUILTIN_BESTIARY, Bestiary.DataAccess.get_builtin_index(), name)
    if type(resolved_key) == "string" then
        return resolved_key
    end

    return _normalize_name(name)
end

function Bestiary.DataAccess.get_group_keys(source, index, base_name)
    local normalized = _normalize_name(base_name)
    if normalized == nil or type(index) ~= "table" then
        return nil
    end

    return _copy_array(index.group_keys_by_base_lower[_lower(normalized)])
end

function Bestiary.DataAccess.is_alias_entry(entry)
    return _is_alias_entry(entry)
end

function Bestiary.DataAccess.normalize_name(name)
    return _normalize_name(name)
end
