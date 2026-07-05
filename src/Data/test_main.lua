-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Dev harness for the generated lore database ("LUI Data Test" plugin).
-- Imports the Recipes domain on the live client, verifies known records,
-- and prints Lua 5.1 timings to chat. Not part of the LUI release.

import "Turbine"

local byte = string.byte
local sub = string.sub
local find = string.find
local floor = math.floor

local function out(msg)
    Turbine.Shell.WriteLine("[DataTest] " .. msg)
end

local clock = os.clock
if clock == nil then
    -- external capability fallback: GetGameTime is seconds as float
    clock = Turbine.Engine.GetGameTime
end

local function timed_import(package_name)
    local t0 = clock()
    import(package_name)
    return (clock() - t0) * 1000
end

out("=== generated Recipes DB, in-game Lua " .. tostring(_VERSION) .. " ===")
local load_total = 0
local load_reports = {}
local files = { "manifest", "records", "labels_en", "labels_fr", "names_fr", "search_fr", "categories" }
for i = 1, #files do
    local ms = timed_import("LUI.src.Data.Recipes." .. files[i])
    load_total = load_total + ms
    load_reports[#load_reports + 1] = string.format("%s %.1fms", files[i], ms)
end
out("imports: " .. table.concat(load_reports, ", "))
out(string.format("import total: %.1f ms", load_total))

local Data = _G.LoreData
local M = Data["Recipes.manifest"]
local R = Data["Recipes.records"]
local L = Data["Recipes.labels_fr"]
local NM = Data["Recipes.names_fr"]
local S = Data["Recipes.search_fr"]
local C = Data["Recipes.categories"]

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

local W = M.widths
local count = M.count
local base_id = M.base_id
local idw = M.id_width
local offw = M.off_width
local IB = M.item_base

local function ordinal_of(id)
    local target = id - base_id
    local lo, hi = 1, count
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        local v = u(R.IDS, (mid - 1) * idw + 1, idw)
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

local function decode(ordinal)
    local p = u(R.OFF, (ordinal - 1) * offw + 1, offw)
    local D = R.DATA
    local function take(w)
        local v = u(D, p, w)
        p = p + w
        return v
    end
    local rec = {}
    rec.profession = M.enums.profession[take(W.profession)]
    rec.tier = take(W.tier)
    rec.category = take(W.category)
    rec.xp = take(W.xp)
    rec.cooldown = take(W.cooldown)
    local flags = take(W.flags)
    rec.guild = flags % 2 == 1
    rec.single_use = flags % 4 >= 2
    rec.conversion = flags >= 4
    local sc = take(W.item)
    if sc > 0 then rec.scroll = sc + IB end
    local pk = take(W.item)
    if pk > 0 then rec.pack = pk + IB end
    rec.pack_count = take(W.pack_count)
    rec.versions = {}
    for vi = 1, take(W.n) do
        local v = {
            crit = take(W.crit),
            ingredients = {}, optionals = {}, results = {}, crit_results = {},
        }
        local ni, no, nr, nc = take(W.n), take(W.n), take(W.n), take(W.n)
        for k = 1, ni do v.ingredients[k] = { take(W.item) + IB, take(W.qty) } end
        for k = 1, no do v.optionals[k] = { take(W.item) + IB, take(W.qty), take(W.bonus) } end
        for k = 1, nr do v.results[k] = { take(W.item) + IB, take(W.qty) } end
        for k = 1, nc do v.crit_results[k] = { take(W.item) + IB, take(W.qty) } end
        rec.versions[vi] = v
    end
    return rec
end

local lw = L.loff_width
local function label(i)
    return sub(L.LBL, u(L.LOFF, (i - 1) * lw + 1, lw), u(L.LOFF, i * lw + 1, lw) - 1)
end

local ow = NM.ord_width
local nw = NM.noff_width
local ecount = NM.entry_count
local function name_to_ordinals(name)
    local lo, hi = 1, ecount
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
            return res, n
        elseif entry < name then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil, 0
end

-- ===== spot checks: Barley Bread 1879205385 =====
local i = ordinal_of(1879205385)
assert(i ~= nil, "Barley Bread not found")
local r = decode(i)
assert(r.profession == "COOK", "profession")
assert(r.tier == 1 and r.category == 6 and r.xp == 8, "header")
assert(r.scroll == 1879205382, "scroll")
assert(r.pack == 1879277247 and r.pack_count == 2, "pack")
local v = r.versions[1]
assert(v.crit == 5, "crit")
assert(#v.ingredients == 3 and v.ingredients[1][1] == 1879182209, "ingredients")
assert(#v.optionals == 2 and v.optionals[2][3] == 100, "optionals")
assert(v.results[1][1] == 1879205391, "result")
assert(v.crit_results[1][2] == 2, "crit result")
assert(label(i) == "Pain à l'orge", "fr label: " .. label(i))
local ords = name_to_ordinals("Pain à l'orge")
assert(ords ~= nil, "fr name lookup failed")
assert(C.CATS.fr[6] ~= nil, "fr category label")
out("spot checks: OK (Barley Bread, fr label, fr name->id, category)")

-- ===== timings (amplified loops; clock may be coarse in-game) =====
math.randomseed(42)
local REPS = 10

local t0 = clock()
for _ = 1, REPS do
    for _ = 1, 100 do
        local rec = decode(math.random(count))
        if rec.tier == nil then error("decode failed") end
    end
end
out(string.format("100 full recipe decodes: %.2f ms", (clock() - t0) * 1000 / REPS))

t0 = clock()
local matches = 0
for _ = 1, REPS do
    matches = 0
    for ord = 1, count do
        local p = u(R.OFF, (ord - 1) * offw + 1, offw)
        if u(R.DATA, p, W.profession) == 3 and u(R.DATA, p + W.profession, W.tier) == 1 then
            matches = matches + 1
        end
    end
end
out(string.format("profession+tier scan (%d recipes): %.2f ms, matches %d",
    count, (clock() - t0) * 1000 / REPS, matches))

local names = {}
for k = 1, 100 do
    names[k] = label(math.random(count))
end
t0 = clock()
local hits = 0
for _ = 1, REPS do
    hits = 0
    for k = 1, 100 do
        if name_to_ordinals(names[k]) ~= nil then hits = hits + 1 end
    end
end
out(string.format("100 name->id (bsearch): %.2f ms, hits %d", (clock() - t0) * 1000 / REPS, hits))

-- type-ahead: cold 1-char scan then refines (worst-case keystroke path)
local sw = S.soff_width
local function soff(k) return u(S.SOFF, (k - 1) * sw + 1, sw) end
local function entry_at(pos)
    local lo, hi = 1, count
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        if soff(mid) <= pos then lo = mid else hi = mid - 1 end
    end
    return lo
end
local function scan(needle)
    local res, n, pos = {}, 0, 1
    while true do
        local s = find(S.SRCH, needle, pos, true)
        if s == nil then break end
        local e = entry_at(s)
        n = n + 1
        res[n] = e
        pos = soff(e + 1)
    end
    return res, n
end
local function refine(set, needle)
    local res, n = {}, 0
    for k = 1, #set do
        local e = set[k]
        if find(sub(S.SRCH, soff(e), soff(e + 1) - 2), needle, 1, true) ~= nil then
            n = n + 1
            res[n] = e
        end
    end
    return res, n
end

t0 = clock()
local rs, rn = scan("p")
out(string.format('search "p" cold: %.2f ms, %d results', (clock() - t0) * 1000, rn))
t0 = clock()
rs, rn = refine(rs, "pa")
out(string.format('search "pa" refine: %.2f ms, %d results', (clock() - t0) * 1000, rn))
t0 = clock()
rs, rn = refine(rs, "pain")
out(string.format('search "pain" refine: %.2f ms, %d results', (clock() - t0) * 1000, rn))

collectgarbage("collect")
out(string.format("Lua memory after harness: %.1f MB", collectgarbage("count") / 1024))
out("=== done ===")
