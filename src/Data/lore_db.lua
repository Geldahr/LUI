-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Runtime access layer for the generated lore databases (tools/lore2lua).
-- Domains import their packed-string files on first load_*() call; nothing
-- is imported at plugin load. Decoding is offset arithmetic over the blobs.

local Lore = _G.LUI.Data.Lore

local byte = string.byte
local sub = string.sub
local find = string.find
local floor = math.floor

-- base-93 decode: w chars at 1-based position p
local function u(s, p, w)
    local v = 0
    for k = p, p + w - 1 do
        local b = byte(s, k)
        if b > 93 then
            v = v * 93 + (b - 34)
        else
            v = v * 93 + (b - 33)
        end
    end
    return v
end

function Lore.language()
    if Lore._language == nil then
        -- same client-language detection the rest of LUI uses
        Lore._language = _G.LUI.Locale.language_code()
    end
    return Lore._language
end

local function _bsearch_id(IDS, id_width, count, target)
    local lo, hi = 1, count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local v = u(IDS, (mid - 1) * id_width + 1, id_width)
        if v == target then
            return mid
        elseif v < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

-- Bytewise string order. The generated name indexes are sorted bytewise;
-- Lua 5.1's `<` uses strcoll (locale-dependent), so it cannot be trusted
-- for the binary search when names contain non-ASCII bytes.
local function _bytewise_less(a, b)
    local la, lb = #a, #b
    local n = la
    if lb < n then
        n = lb
    end
    for k = 1, n do
        local ba, bb = byte(a, k), byte(b, k)
        if ba ~= bb then
            return ba < bb
        end
    end
    return la < lb
end

-- name -> ordinals over a sorted NAME/NOFF index; nil means "not in DB"
local function _find_ordinals(NM, name)
    local nw, ow = NM.noff_width, NM.ord_width
    local lo, hi = 1, NM.entry_count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local p = u(NM.NOFF, (mid - 1) * nw + 1, nw)
        local q = find(NM.NAME, "\t", p + 1, true)
        local entry = sub(NM.NAME, p + 1, q - 1)
        if entry == name then
            local res, n = {}, 0
            local e = find(NM.NAME, "\n", q + 1, true)
            for k = q + 1, e - 1, ow do
                n = n + 1
                res[n] = u(NM.NAME, k, ow)
            end
            return res
        elseif _bytewise_less(entry, name) then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

-- ------------------------------------------------------------- Recipes ----

Lore.Recipes = Lore.Recipes or {}
local Recipes = Lore.Recipes

function Lore.load_recipes()
    if Recipes.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Recipes.manifest")
    import("LUI.src.Data.Recipes.records")
    import("LUI.src.Data.Recipes.labels_" .. lang)
    import("LUI.src.Data.Recipes.names_" .. lang)
    import("LUI.src.Data.Recipes.categories")
    local Data = _G.LoreData
    Recipes.M = Data["Recipes.manifest"]
    Recipes.R = Data["Recipes.records"]
    Recipes.L = Data["Recipes.labels_" .. lang]
    Recipes.NM = Data["Recipes.names_" .. lang]
    Recipes.CATS = Data["Recipes.categories"].CATS[lang]
    Recipes.PROFS = Data["Recipes.categories"].PROFS[lang]
    Recipes.count = Recipes.M.count
    Recipes.profession_codes = {}
    for code = 1, #Recipes.M.enums.profession do
        Recipes.profession_codes[Recipes.M.enums.profession[code]] = code
    end
    Recipes.loaded = true
end

function Recipes.find_ordinals(name)
    return _find_ordinals(Recipes.NM, name)
end

function Recipes.id_of(ordinal)
    local M = Recipes.M
    return u(Recipes.R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width) + M.base_id
end

-- header probes: read one field without decoding the record
function Recipes.profession_code(ordinal)
    local M = Recipes.M
    local p = u(Recipes.R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    return u(Recipes.R.DATA, p, M.widths.profession)
end

function Recipes.tier_of(ordinal)
    local M = Recipes.M
    local p = u(Recipes.R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    return u(Recipes.R.DATA, p + M.widths.profession, M.widths.tier)
end

function Recipes.label(ordinal)
    local L = Recipes.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

function Recipes.category_name(code)
    local name = Recipes.CATS[code]
    if name == nil then
        return ""
    end
    return name
end

function Recipes.profession_name(key)
    return Recipes.PROFS[key]
end

function Recipes.decode(ordinal)
    local M = Recipes.M
    local R = Recipes.R
    local W = M.widths
    local D = R.DATA
    local IB = M.item_base
    local p = u(R.OFF, (ordinal - 1) * M.off_width + 1, M.off_width)
    local function take(w)
        local v = u(D, p, w)
        p = p + w
        return v
    end
    local rec = {}
    rec.id = u(R.IDS, (ordinal - 1) * M.id_width + 1, M.id_width) + M.base_id
    rec.profession = M.enums.profession[take(W.profession)]
    rec.tier = take(W.tier)
    rec.category = take(W.category)
    rec.xp = take(W.xp)
    rec.cooldown = take(W.cooldown)
    local flags = take(W.flags)
    rec.guild = flags % 2 == 1
    rec.single_use = flags % 4 >= 2
    rec.conversion = flags >= 4
    local scroll = take(W.item)
    if scroll > 0 then
        rec.scroll = scroll + IB
    end
    local pack = take(W.item)
    if pack > 0 then
        rec.pack = pack + IB
    end
    rec.pack_count = take(W.pack_count)
    rec.versions = {}
    for vi = 1, take(W.n) do
        local version = {
            crit = take(W.crit),
            ingredients = {},
            optionals = {},
            results = {},
            crit_results = {},
        }
        local ni, no, nr, nc = take(W.n), take(W.n), take(W.n), take(W.n)
        for k = 1, ni do
            version.ingredients[k] = { take(W.item) + IB, take(W.qty) }
        end
        for k = 1, no do
            version.optionals[k] = { take(W.item) + IB, take(W.qty), take(W.bonus) }
        end
        for k = 1, nr do
            version.results[k] = { take(W.item) + IB, take(W.qty) }
        end
        for k = 1, nc do
            version.crit_results[k] = { take(W.item) + IB, take(W.qty) }
        end
        rec.versions[vi] = version
    end
    return rec
end

-- --------------------------------------------------------------- Items ----

Lore.Items = Lore.Items or {}
local Items = Lore.Items

function Lore.load_items()
    if Items.loaded == true then
        return
    end
    local lang = Lore.language()
    import("LUI.src.Data.Items.manifest")
    import("LUI.src.Data.Items.records")
    import("LUI.src.Data.Items.labels_" .. lang)
    local Data = _G.LoreData
    Items.M = Data["Items.manifest"]
    Items.R = Data["Items.records"]
    Items.L = Data["Items.labels_" .. lang]
    Items.count = Items.M.count
    local M = Items.M
    -- field byte offsets within a record tuple
    local at = 0
    Items._field_at = {}
    for k = 1, #M.widths do
        Items._field_at[M.fields[k]] = at
        at = at + M.widths[k]
    end
    Items._field_w = {}
    for k = 1, #M.widths do
        Items._field_w[M.fields[k]] = M.widths[k]
    end
    Items.loaded = true
end

function Items.ordinal_of(id)
    local M = Items.M
    local target = id - M.base_id
    if target < 0 then
        return nil
    end
    return _bsearch_id(Items.R.IDS, M.id_width, M.count, target)
end

function Items.label(ordinal)
    local L = Items.L
    local w = L.loff_width
    return sub(L.LBL, u(L.LOFF, (ordinal - 1) * w + 1, w), u(L.LOFF, ordinal * w + 1, w) - 1)
end

local function _item_field(ordinal, field)
    local M = Items.M
    local p = (ordinal - 1) * M.stride + 1 + Items._field_at[field]
    return u(Items.R.REC, p, Items._field_w[field])
end

function Items.min_level(ordinal)
    local v = _item_field(ordinal, "min_level")
    if v == 0 then
        return nil
    end
    return v
end

function Items.quality_name(ordinal)
    local code = _item_field(ordinal, "quality")
    if code == 0 then
        return nil
    end
    return Items.M.enums.quality[code]
end

-- composite icon "main-background-shadow-underlay": up to 4 numeric layers
function Items.icon_layers(ordinal)
    local ref = _item_field(ordinal, "icon")
    if ref == 0 then
        return nil
    end
    local R = Items.R
    local w = Items.M.poff_width
    local composite = sub(R.POOL, u(R.POFF, (ref - 1) * w + 1, w), u(R.POFF, ref * w + 1, w) - 1)
    local layers = {}
    local start = 1
    while true do
        local dash = find(composite, "-", start, true)
        if dash == nil then
            layers[#layers + 1] = tonumber(sub(composite, start))
            break
        end
        layers[#layers + 1] = tonumber(sub(composite, start, dash - 1))
        start = dash + 1
    end
    return layers[1], layers[2], layers[3], layers[4]
end
