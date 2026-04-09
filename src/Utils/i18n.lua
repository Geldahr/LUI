import "LUI.src.Languages.de"
import "LUI.src.Languages.fr"

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
        local l = lang:lower():gsub("_", "-")
        if l == "de" or l:find("^de%-") == 1 then
            return "de"
        end
        if l == "fr" or l:find("^fr%-") == 1 then
            return "fr"
        end
        -- Treat en / en-gb / en-us etc as English.
        return "en"
    end

    -- Unknown numeric enum or missing API: default to English.
    return "en"
end

local function _load_translations()
    local code = _detect_language_code()
    local l = {}
    l.de = DE
    l.fr = FR
    local tr = l[code] or {}
    setmetatable(tr, { __index = function(k, v) return v or k end })
    return tr
end

_G.TR = _load_translations()

function _G.is_lui_english_language()
    return _detect_language_code() == "en"
end
