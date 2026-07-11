-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Languages.de"
import "LUI.src.Languages.fr"

local LUI = _G.LUI
local Locale = _G.LUI.Locale

local LANGUAGE_TABLES = {
    de = LUI.src.Languages.de.DE,
    fr = LUI.src.Languages.fr.FR,
}

local function _language_code_from_value(lang)
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

local function _detect_language_code()
    return _language_code_from_value(Turbine.Engine.GetLanguage())
end

local function _translation_table_for_code(code)
    if code == "en" then
        return {}
    end
    return LANGUAGE_TABLES[code]
end

local function _load_translations()
    local code = _detect_language_code()
    local tr = _translation_table_for_code(code)
    setmetatable(tr, { __index = function(k, v) return v or k end })
    return tr
end

Locale.TR = _load_translations()

function Locale.is_english_language()
    return _detect_language_code() == "en"
end

function Locale.language_code()
    return _detect_language_code()
end
