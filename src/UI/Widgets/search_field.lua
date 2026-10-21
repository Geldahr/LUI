-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- SearchField: a window's search bar in one of two modes (per-window
-- setting):
--   "classic"  a LuiLineEdit, the query is its text, searched as typed
--   "tokens"   a TokenInput, the query is its chips, searched on chip change
-- The owner declares its keywords with set_keywords:
--   { key = "loc", icon = Widgets.Icons name, hint = text,
--     aliases = { words that also suggest the key },
--     values = optional function -> { { name = text, children = { text } } },
--     child_hint = optional format for "<n> children" (e.g. "%d areas"),
--     multi = true when the value is a comma list (complete the last item) }
-- Keyword chips show the icon instead of "key:". Optional callback:
--   QueryChanged(sender)   a user edit changed the query (programmatic
--                          set_query / replace_keyword do not fire it)

local LUI = _G.LUI
local TR = LUI.Locale.TR
local UI = LUI.UI
local Utils = LUI.Utils
local class = LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.Widgets.line_edit"
import "LUI.src.UI.Widgets.token_input"
import "LUI.src.Utils.search_query"

local Widgets = UI.Widgets
local SearchQuery = Utils.SearchQuery

local MODE_TOKENS = "tokens"

local function _trim(text)
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

---@class SearchField : Turbine.UI.Control
local SearchField = class(Turbine.UI.Control)
Widgets.SearchField = SearchField
SearchField.CLASSIC = "classic"
SearchField.TOKENS = MODE_TOKENS

function SearchField:Constructor()
    Turbine.UI.Control.Constructor(self)
    self:SetMouseVisible(false)

    self.QueryChanged = nil
    self._mode = nil
    self._keywords = {}
    self._keyword_by_key = {}
    self._token_keys = {}

    self.line_edit = Widgets.LuiLineEdit()
    self.line_edit:SetParent(self)
    self.line_edit:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.line_edit:set_clearable(true)
    self.line_edit.TextChanged = function()
        self:_fire_changed()
    end

    self.tokens = Widgets.TokenInput()
    self.tokens:SetParent(self)
    self.tokens:set_leading_icon("search")
    self.tokens:SetVisible(false)
    self.tokens.FormatToken = function(_, token)
        return self:_format_chip(token)
    end
    self.tokens.Suggestions = function(_, text)
        return self:_suggestions(text)
    end
    self.tokens.KeywordOf = function(_, text)
        return self:_typed_keyword(text)
    end
    self.tokens.TokensChanged = function()
        self:_fire_changed()
    end
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function SearchField:set_keywords(keywords)
    self._keywords = keywords
    self._keyword_by_key = {}
    self._token_keys = {}
    for i = 1, #keywords do
        self._keyword_by_key[keywords[i].key] = keywords[i]
        self._token_keys[keywords[i].key] = true
    end
    self.tokens:refresh_tokens()
end

function SearchField:token_keys()
    return self._token_keys
end

function SearchField:set_popup_host(host)
    self.tokens:set_popup_host(host)
end

function SearchField:set_placeholder(text)
    self.line_edit:set_placeholder_text(text)
    self.tokens:set_placeholder(text)
end

function SearchField:set_scale(scale)
    self.line_edit:set_scale(scale)
    self.tokens:set_scale(scale)
    self:_layout()
end

-- the Classic field's font (TokenInput sizes its own text)
function SearchField:SetFont(font)
    self.line_edit:SetFont(font)
end

function SearchField:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout()
end

-- shows the widget of `mode`; a switch carries the query over (Classic
-- text <-> chips). Returns true when an existing mode changed (the owner
-- then adds its field filters as chips and searches again).
function SearchField:set_mode(mode)
    if mode == self._mode then
        return false
    end
    local previous = self._mode
    self._mode = mode
    local tokens = mode == MODE_TOKENS
    self.line_edit:SetVisible(tokens ~= true)
    self.tokens:SetVisible(tokens)
    if previous == nil then
        return false
    end

    if tokens == true then
        local chips = SearchQuery.query_to_chips(self.line_edit:GetText() or "", self._token_keys)
        self.line_edit:SetText("")
        self.tokens:set_tokens(chips, false)
    else
        self.line_edit:SetText(SearchQuery.chips_to_query(self.tokens:get_tokens(), self._token_keys))
        self.tokens:set_tokens({}, false)
    end
    return true
end

function SearchField:is_tokens()
    return self._mode == MODE_TOKENS
end

-- parsed query of the shown widget: SearchQuery.parse / parse_chips state
-- (chip_groups: every entry must match)
function SearchField:get_query_state()
    if self:is_tokens() == true then
        return SearchQuery.parse_chips(self.tokens:get_tokens(), self._token_keys)
    end
    return SearchQuery.parse(self.line_edit:GetText() or "", self._token_keys)
end

-- the query as one text (Classic text, or the chips joined)
function SearchField:get_query_text()
    if self:is_tokens() == true then
        return SearchQuery.chips_to_query(self.tokens:get_tokens(), self._token_keys)
    end
    return self.line_edit:GetText() or ""
end

-- replaces the query (cross-window searches); does not fire QueryChanged
function SearchField:set_query(text)
    if self:is_tokens() == true then
        self.tokens:set_tokens(SearchQuery.query_to_chips(text, self._token_keys), false)
        return
    end
    self.line_edit:SetText(text)
    -- the TextBox does not paint text set while its window was hidden
    self.line_edit:refresh_text_async()
end

-- Tokens mode: one chip per keyword; replaces (nil removes) the `key:`
-- chip. Does not fire QueryChanged.
function SearchField:replace_keyword(key, value)
    local chips = {}
    local current = self.tokens:get_tokens()
    for i = 1, #current do
        if SearchQuery.split_chip(current[i], self._token_keys) ~= key then
            chips[#chips + 1] = current[i]
        end
    end
    if value ~= nil then
        chips[#chips + 1] = key .. ":" .. value
    end
    self.tokens:set_tokens(chips, false)
end

function SearchField:has_keyword(key)
    local current = self.tokens:get_tokens()
    for i = 1, #current do
        if SearchQuery.split_chip(current[i], self._token_keys) == key then
            return true
        end
    end
    return false
end

function SearchField:Focus()
    if self:is_tokens() == true then
        self.tokens:Focus()
    else
        self.line_edit:Focus()
    end
end

function SearchField:destroy()
    self.tokens:destroy()
    self.line_edit:destroy()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function SearchField:_fire_changed()
    if type(self.QueryChanged) == "function" then
        self:QueryChanged()
    end
end

function SearchField:_layout()
    local w, h = self:GetSize()
    self.line_edit:SetPosition(0, 0)
    self.line_edit:SetSize(w, h)
    self.tokens:SetPosition(0, math.floor((h - self.tokens:get_height()) / 2))
    self.tokens:SetSize(w)
end

function SearchField:_format_chip(token)
    local key, value = SearchQuery.split_chip(token, self._token_keys)
    if key == nil then
        return nil, token
    end
    return self._keyword_by_key[key].icon, value
end

-- TokenInput KeywordOf: the declared keyword `text` starts with, read as
-- _suggestions reads it (set whenever values are listed, never over
-- keyword names), and the chip value (nil when empty: "lvl:" is no chip)
function SearchField:_typed_keyword(text)
    local key = string.match(string.lower(_trim(text)), "^(%a+):")
    if key == nil or self._keyword_by_key[key] == nil then
        return nil, nil
    end
    local _, value = SearchQuery.split_chip(text, self._token_keys)
    return key, value
end

function SearchField:_keyword_items(typed)
    local out = {}
    for _, keyword in ipairs(self._keywords) do
        local hit = typed == "" or string.sub(keyword.key, 1, #typed) == typed
        for _, alias in ipairs(keyword.aliases) do
            if string.sub(string.lower(alias), 1, #typed) == typed then
                hit = true
            end
        end
        if hit == true then
            out[#out + 1] = {
                icon = keyword.icon,
                text = keyword.key .. ":",
                hint = keyword.hint,
                value = keyword.key .. ":",
            }
        end
    end
    return out
end

-- first-level values; the pick replaces the typed value only
local function _value_items(keyword, index, typed)
    local out = {}
    for _, entry in ipairs(index) do
        if typed == "" or string.find(string.lower(entry.name), typed, 1, true) ~= nil then
            if entry.children ~= nil and #entry.children > 0 then
                out[#out + 1] = {
                    text = entry.name,
                    hint = string.format(keyword.child_hint, #entry.children),
                    value = entry.name .. " > ",
                }
            else
                out[#out + 1] = { text = entry.name, value = entry.name, final = true }
            end
        end
    end
    return out
end

-- second-level values of one entry; the pick replaces the whole text
local function _child_items(keyword, entry, typed)
    local out = {}
    if typed == "" then
        out[1] = {
            text = string.format(TR["All of %s"], entry.name),
            value = keyword.key .. ":" .. entry.name,
            final = true,
        }
    end
    for _, child in ipairs(entry.children) do
        if string.lower(child) == typed then
            return {}
        end
        if typed == "" or string.find(string.lower(child), typed, 1, true) ~= nil then
            out[#out + 1] = { text = child, value = keyword.key .. ":" .. entry.name .. " > " .. child, final = true }
        end
    end
    return out
end

-- TokenInput suggestions: keywords, then the keyword's values (a value with
-- children continues with "value > child")
function SearchField:_suggestions(text)
    local typed = string.lower(_trim(text))
    local key, rest = string.match(typed, "^(%a+):(.*)$")
    if key == nil then
        return self:_keyword_items(typed)
    end
    local keyword = self._keyword_by_key[key]
    if keyword == nil or keyword.values == nil then
        return {}
    end
    local index = keyword.values()
    local parent_part, child_part = string.match(rest, "^(.-)%s*>%s*(.*)$")
    if parent_part ~= nil then
        parent_part = _trim(parent_part)
        for _, entry in ipairs(index) do
            if string.lower(entry.name) == parent_part and entry.children ~= nil then
                return _child_items(keyword, entry, _trim(child_part))
            end
        end
        return {}
    end

    local from = string.find(text, ":", 1, true) + 1
    local segment = rest
    if keyword.multi == true then
        -- comma list: complete the item after the last comma
        local comma = string.find(text, ",[^,]*$", from)
        if comma ~= nil then
            from = comma + 1
            segment = string.lower(string.sub(text, from))
        end
    end
    return _value_items(keyword, index, _trim(segment)), from
end
