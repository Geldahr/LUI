_G.SearchQuery = _G.SearchQuery or {}
SearchQuery = _G.SearchQuery

local function _trim_text(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function _lower_text(text)
    if type(text) ~= "string" then
        return ""
    end

    return string.lower(text)
end

local function _push_term(group, term)
    if type(term) ~= "string" then
        return
    end

    local trimmed = _trim_text(term)
    if trimmed == "" then
        return
    end

    group[#group + 1] = trimmed
end

local function _end_group(groups, group)
    if #group > 0 then
        groups[#groups + 1] = group
    end
end

local function _read_quoted_value(text, index)
    local end_index = index + 1
    local length = #text
    while end_index <= length and text:sub(end_index, end_index) ~= "\"" do
        end_index = end_index + 1
    end

    return text:sub(index + 1, end_index - 1), (end_index <= length) and (end_index + 1) or (length + 1)
end

local function _read_bare_value(text, index)
    local end_index = index
    local length = #text
    while end_index <= length do
        local next_char = text:sub(end_index, end_index)
        if next_char == "|" or next_char == "\"" or next_char:match("%s") then
            break
        end
        end_index = end_index + 1
    end

    return text:sub(index, end_index - 1), end_index
end

local function _read_token_key(text, index)
    local length = #text
    local end_index = index
    while end_index <= length do
        local next_char = text:sub(end_index, end_index)
        if next_char == ":" then
            break
        end
        if next_char:match("[%a]") ~= next_char then
            return nil, nil
        end
        end_index = end_index + 1
    end

    if end_index > length or text:sub(end_index, end_index) ~= ":" then
        return nil, nil
    end

    return string.lower(text:sub(index, end_index - 1)), end_index + 1
end

local function _serialize_term(term, token_keys)
    local text = _trim_text(term)
    if text == "" then
        return nil
    end

    local token_key = _read_token_key(text, 1)
    if text:find("[\"|%s]") ~= nil or (type(token_key) == "string" and token_keys ~= nil and token_keys[token_key] == true) then
        return "\"" .. text:gsub("\"", "") .. "\""
    end

    return text
end

local function _serialize_token_value(value)
    local text = _trim_text(value)
    if text == "" then
        return nil
    end

    if text:find("[\"|%s]") ~= nil then
        return "\"" .. text:gsub("\"", "") .. "\""
    end

    return text
end

local function _copy_token_entries(entries)
    local copied = {}
    if type(entries) ~= "table" then
        return copied
    end

    for index = 1, #entries do
        local entry = entries[index]
        copied[#copied + 1] = {
            key = entry.key,
            value = entry.value,
        }
    end

    return copied
end

function SearchQuery.normalize_groups(groups)
    if type(groups) ~= "table" or #groups == 0 then
        return {}
    end

    local out = {}
    for group_index = 1, #groups do
        local group = groups[group_index]
        if type(group) == "table" and #group > 0 then
            local normalized_group = {}
            for term_index = 1, #group do
                local term = group[term_index]
                if type(term) == "string" then
                    term = _lower_text(term)
                    if term ~= "" then
                        normalized_group[#normalized_group + 1] = term
                    end
                end
            end
            if #normalized_group > 0 then
                out[#out + 1] = normalized_group
            end
        end
    end

    return out
end

function SearchQuery.group_matches(group, haystack_lower)
    if type(group) ~= "table" or #group == 0 or type(haystack_lower) ~= "string" then
        return false
    end

    for term_index = 1, #group do
        local term = group[term_index]
        if term ~= "" and string.find(haystack_lower, term, 1, true) == nil then
            return false
        end
    end

    return true
end

function SearchQuery.matches_groups(groups, haystack_lower)
    if type(groups) ~= "table" or #groups == 0 then
        return true
    end
    if type(haystack_lower) ~= "string" then
        return false
    end

    for group_index = 1, #groups do
        if SearchQuery.group_matches(groups[group_index], haystack_lower) == true then
            return true
        end
    end

    return false
end

function SearchQuery.parse(query, token_keys)
    local text = type(query) == "string" and query or ""
    local groups = {}
    local current_group = {}
    local tokens = {}
    local token_map = {}
    local index = 1
    local length = #text

    while index <= length do
        local char = text:sub(index, index)
        if char == "\"" then
            local value
            value, index = _read_quoted_value(text, index)
            _push_term(current_group, value)
        elseif char == "|" then
            _end_group(groups, current_group)
            current_group = {}
            index = index + 1
        elseif char:match("%s") then
            index = index + 1
        else
            local token_key, value_index = _read_token_key(text, index)
            if type(token_key) == "string" and type(token_keys) == "table" and token_keys[token_key] == true then
                local value
                if value_index <= length and text:sub(value_index, value_index) == "\"" then
                    value, index = _read_quoted_value(text, value_index)
                else
                    value, index = _read_bare_value(text, value_index)
                end

                value = _trim_text(value)
                tokens[#tokens + 1] = {
                    key = token_key,
                    value = value,
                }
                token_map[token_key] = value
            else
                local value
                value, index = _read_bare_value(text, index)
                _push_term(current_group, value)
            end
        end
    end

    _end_group(groups, current_group)

    return {
        raw = text,
        text_groups = groups,
        normalized_groups = SearchQuery.normalize_groups(groups),
        tokens = tokens,
        token_map = token_map,
    }
end

function SearchQuery.parse_text_groups(query)
    return SearchQuery.parse(query, nil).text_groups
end

function SearchQuery.serialize(text_groups, token_entries, token_keys)
    local parts = {}

    if type(text_groups) == "table" then
        local group_parts = {}
        for group_index = 1, #text_groups do
            local group = text_groups[group_index]
            if type(group) == "table" and #group > 0 then
                local term_parts = {}
                for term_index = 1, #group do
                    local rendered = _serialize_term(group[term_index], token_keys)
                    if rendered ~= nil then
                        term_parts[#term_parts + 1] = rendered
                    end
                end
                if #term_parts > 0 then
                    group_parts[#group_parts + 1] = table.concat(term_parts, " ")
                end
            end
        end
        if #group_parts > 0 then
            parts[#parts + 1] = table.concat(group_parts, "|")
        end
    end

    if type(token_entries) == "table" then
        for index = 1, #token_entries do
            local entry = token_entries[index]
            local rendered = _serialize_token_value(entry.value)
            if type(entry.key) == "string" and rendered ~= nil then
                parts[#parts + 1] = entry.key .. ":" .. rendered
            end
        end
    end

    return table.concat(parts, " ")
end

function SearchQuery.add_token(token_entries, key, value)
    local text = _trim_text(value)
    if text == "" then
        return
    end

    token_entries[#token_entries + 1] = {
        key = key,
        value = text,
    }
end

function SearchQuery.copy_tokens_except(state, excluded_keys)
    local copied = {}
    local entries = state.tokens
    for index = 1, #entries do
        local entry = entries[index]
        if excluded_keys[entry.key] ~= true then
            copied[#copied + 1] = {
                key = entry.key,
                value = entry.value,
            }
        end
    end

    return copied
end

function SearchQuery.copy_tokens(state)
    return _copy_token_entries(state.tokens)
end

function SearchQuery.parse_path(value)
    local text = _trim_text(value)
    if text == "" then
        return nil
    end

    local parts = {}
    for segment in string.gmatch(text, "([^>]+)") do
        local part = _trim_text(segment)
        if part == "" then
            return nil
        end
        parts[#parts + 1] = part
    end

    if #parts == 0 then
        return nil
    end

    return parts
end

function SearchQuery.format_path(parts)
    if type(parts) ~= "table" or #parts == 0 then
        return nil
    end

    local out = {}
    for index = 1, #parts do
        local part = _trim_text(parts[index])
        if part == "" then
            return nil
        end
        out[#out + 1] = part
    end

    if #out == 0 then
        return nil
    end

    return table.concat(out, " > ")
end

function SearchQuery.read_level_filter(state, key)
    local filter = {
        min = nil,
        max = nil,
        exact = nil,
        active = false,
        impossible = false,
    }

    for index = 1, #state.tokens do
        local entry = state.tokens[index]
        if entry.key == key then
            local raw = _trim_text(entry.value)
            local op = ""
            local number_text = raw

            if raw:sub(1, 2) == ">=" or raw:sub(1, 2) == "<=" then
                op = raw:sub(1, 2)
                number_text = raw:sub(3)
            elseif raw:sub(1, 1) == ">" or raw:sub(1, 1) == "<" or raw:sub(1, 1) == "=" then
                op = raw:sub(1, 1)
                number_text = raw:sub(2)
            else
                op = "="
            end

            local value = tonumber(number_text)
            if value ~= nil then
                value = math.floor(value)
                if value >= 1 then
                    filter.active = true
                    if op == ">" then
                        value = value + 1
                        filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                    elseif op == ">=" then
                        filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                    elseif op == "<" then
                        value = value - 1
                        filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                    elseif op == "<=" then
                        filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                    else
                        filter.exact = value
                        filter.min = filter.min ~= nil and math.max(filter.min, value) or value
                        filter.max = filter.max ~= nil and math.min(filter.max, value) or value
                    end
                end
            end
        end
    end

    if filter.min ~= nil and filter.max ~= nil and filter.min > filter.max then
        filter.impossible = true
    end

    return filter
end

function SearchQuery.build_level_tokens(key, min_value, max_value)
    local tokens = {}
    if min_value == nil and max_value == nil then
        return tokens
    end

    if min_value ~= nil and max_value ~= nil and min_value == max_value then
        tokens[1] = {
            key = key,
            value = "=" .. tostring(min_value),
        }
        return tokens
    end

    if min_value ~= nil then
        tokens[#tokens + 1] = {
            key = key,
            value = ">=" .. tostring(min_value),
        }
    end
    if max_value ~= nil then
        tokens[#tokens + 1] = {
            key = key,
            value = "<=" .. tostring(max_value),
        }
    end

    return tokens
end
