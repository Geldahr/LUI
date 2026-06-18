local Bestiary = _G.LUI.Features.Bestiary
local DB = _G.LUI.Data.Bestiary.DB or {}
_G.LUI.Data.Bestiary.DB = DB
DB.en = DB.en or {}

local function _detect_language_code()
    local lang = Turbine.Engine.GetLanguage()

    if type(lang) == "number" then
        local language_enum = Turbine.Language
        if lang == language_enum.German then
            return "de"
        end
        if lang == language_enum.French then
            return "fr"
        end
        if lang == language_enum.English or lang == language_enum.EnglishGB then
            return "en"
        end

        if lang == 3 then
            return "de"
        end
        if lang == 2 then
            return "fr"
        end
        return "en"
    end

    if type(lang) == "string" then
        local lowered = lang:lower():gsub("_", "-")
        if lowered == "de" or lowered:find("^de%-") == 1 then
            return "de"
        end
        if lowered == "fr" or lowered:find("^fr%-") == 1 then
            return "fr"
        end
        return "en"
    end

    return "en"
end

local function _resolve_locale_table(requested_locale, key)
    local localized_bucket = type(DB[requested_locale]) == "table" and DB[requested_locale] or nil
    local localized_value = localized_bucket ~= nil and localized_bucket[key] or nil
    if type(localized_value) == "table" then
        return localized_value, requested_locale
    end

    local english_value = type(DB.en) == "table" and DB.en[key] or nil
    if type(english_value) == "table" then
        return english_value, "en"
    end

    return {}, "en"
end

local function _normalize_drop_name(name)
    if type(name) ~= "string" then
        return ""
    end

    local value = name:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then
        return ""
    end

    value = value:gsub("%s+", " ")
    return string.lower(value)
end

local function _build_drop_table(bestiary)
    local drop_table = {}
    if type(bestiary) ~= "table" then
        return drop_table
    end

    for _, entry in pairs(bestiary) do
        if type(entry) == "table" then
            local drops = entry.w
            if type(drops) == "table" then
                for i = 1, #drops do
                    local key = _normalize_drop_name(drops[i])
                    if key ~= "" then
                        drop_table[key] = true
                    end
                end
            end

            local chest_drops = entry.cw
            if type(chest_drops) == "table" then
                for i = 1, #chest_drops do
                    local key = _normalize_drop_name(chest_drops[i])
                    if key ~= "" then
                        drop_table[key] = true
                    end
                end
            end
        end
    end

    return drop_table
end

local function _ensure_drop_table(locale_code)
    local bucket = type(DB[locale_code]) == "table" and DB[locale_code] or nil
    if bucket == nil or type(bucket.drop_table) == "table" or type(bucket.bestiary) ~= "table" then
        return
    end

    bucket.drop_table = _build_drop_table(bucket.bestiary)
end

local requested_locale = _detect_language_code()

_ensure_drop_table("en")
if requested_locale ~= "en" then
    _ensure_drop_table(requested_locale)
end

Bestiary.RequestedLocale = requested_locale
Bestiary.Data, Bestiary.DataLocale = _resolve_locale_table(requested_locale, "bestiary")
Bestiary.DropTable, Bestiary.DropTableLocale = _resolve_locale_table(requested_locale, "drop_table")

function Bestiary.supports_target_name_lookup()
    local requested = Bestiary.RequestedLocale or "en"
    return Bestiary.DataLocale == requested
end

function Bestiary.supports_drop_name_lookup()
    local requested = Bestiary.RequestedLocale or "en"
    return Bestiary.DataLocale == requested and Bestiary.DropTableLocale == requested
end

function Bestiary.has_droppable_item(name)
    if Bestiary.supports_drop_name_lookup() ~= true then
        return false
    end

    local key = _normalize_drop_name(name)
    return key ~= "" and type(Bestiary.DropTable) == "table" and Bestiary.DropTable[key] == true
end
