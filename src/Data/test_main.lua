-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Dev harness for the generated lore database ("LUI Data Test" plugin).
-- Drives the SAME runtime decode layer the plugin ships (src/Data/lore_db):
-- staged imports, spot checks and Lua 5.1 timings printed to chat. The only
-- local decoding is the type-ahead search prototype, which lore_db does not
-- expose yet. Not part of the LUI release.

import "Turbine"
import "LUI.src.namespace"
import "LUI.src.Utils.i18n"
import "LUI.src.Data.lore_db"

local Lore = _G.LUI.Data.Lore

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

out("=== generated lore DB, in-game " .. tostring(_VERSION) .. ", lang " .. Lore.language() .. " ===")

-- staged imports, timed per file (this is the plan the crafting store uses)
local total_ms = 0
for _, package_name in ipairs(Lore.import_plan()) do
    local t0 = clock()
    Lore.import_step(package_name)
    local ms = (clock() - t0) * 1000
    total_ms = total_ms + ms
    out(string.format("import %-38s %7.1f ms", package_name, ms))
end
local t0 = clock()
Lore.load_recipes()
Lore.load_items()
out(string.format("finalize (load_recipes+load_items): %.1f ms; imports total %.1f ms",
    (clock() - t0) * 1000, total_ms))

-- ===== spot checks: Barley Bread 1879205385 (values from recipes.xml) =====
local barley_ordinal = nil
for ordinal = 1, Lore.Recipes.count do
    if Lore.Recipes.id_of(ordinal) == 1879205385 then
        barley_ordinal = ordinal
        break
    end
end
assert(barley_ordinal ~= nil, "Barley Bread not found")
local rec = Lore.Recipes.decode(barley_ordinal)
assert(rec.profession == "COOK", "profession")
assert(rec.tier == 1 and rec.category == 6 and rec.xp == 8, "header")
assert(rec.scroll == 1879205382, "scroll")
assert(rec.pack == 1879277247 and rec.pack_count == 2, "pack")
assert(rec.conversion ~= true, "conversion flag")
local version = rec.versions[1]
assert(version.crit == 5, "crit")
assert(#version.ingredients == 3 and version.ingredients[1][1] == 1879182209, "ingredients")
assert(#version.optionals == 2 and version.optionals[2][3] == 100, "optionals")
assert(version.results[1][1] == 1879205391, "result")
assert(version.crit_results[1][2] == 2, "crit result")

local barley_label = Lore.Recipes.label(barley_ordinal)
assert(barley_label ~= "", "empty recipe label")
local ordinals = Lore.Recipes.find_ordinals(barley_label)
assert(ordinals ~= nil, "name index lookup failed")
local found = false
for k = 1, #ordinals do
    if ordinals[k] == barley_ordinal then
        found = true
    end
end
assert(found, "name index does not contain Barley Bread")
assert(Lore.Recipes.category_name(rec.category) ~= "", "category name")
assert(Lore.Recipes.profession_name("COOK") ~= nil, "profession name")
assert(Lore.Recipes.profession_code(barley_ordinal) == Lore.Recipes.profession_codes["COOK"], "profession probe")
assert(Lore.Recipes.tier_of(barley_ordinal) == 1, "tier probe")

local hengaim = Lore.Items.ordinal_of(1879049233)
assert(hengaim ~= nil, "Hengaim not found")
assert(Lore.Items.label(hengaim) ~= "", "item label")
local layer1 = Lore.Items.icon_layers(hengaim)
assert(type(layer1) == "number", "icon layer")
assert(Lore.Items.quality_name(hengaim) == "UNCOMMON", "quality")
out("spot checks: OK (Barley Bread decode, name index, probes, Hengaim)")

-- ===== timings (amplified loops; clock may be coarse in-game) =====
math.randomseed(42)
local REPS = 10

local t = clock()
for _ = 1, REPS do
    for _ = 1, 100 do
        local r = Lore.Recipes.decode(math.random(Lore.Recipes.count))
        if r.tier == nil then
            error("decode failed")
        end
    end
end
out(string.format("100 full recipe decodes: %.2f ms", (clock() - t) * 1000 / REPS))

local names = {}
for k = 1, 200 do
    names[k] = Lore.Recipes.label(math.random(Lore.Recipes.count))
end
t = clock()
local hits = 0
for _ = 1, REPS do
    hits = 0
    for k = 1, 200 do
        if Lore.Recipes.find_ordinals(names[k]) ~= nil then
            hits = hits + 1
        end
    end
end
out(string.format("200 name->ordinals lookups: %.2f ms, hits %d", (clock() - t) * 1000 / REPS, hits))

t = clock()
for _ = 1, REPS do
    for _ = 1, 100 do
        local ordinal = Lore.Items.ordinal_of(1879000000 + math.random(900000))
        if ordinal ~= nil then
            Lore.Items.label(ordinal)
        end
    end
end
out(string.format("100 item id lookups (+label when hit): %.2f ms", (clock() - t) * 1000 / REPS))

-- ===== type-ahead search prototype (no lore_db counterpart yet) =====
local lang = Lore.language()
import("LUI.src.Data.Recipes.search_" .. lang)
local S = _G.LoreData["Recipes.search_" .. lang]

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
local sw = S.soff_width
local count = Lore.Recipes.count
local function soff(k)
    return u(S.SOFF, (k - 1) * sw + 1, sw)
end
local function entry_at(pos)
    local lo, hi = 1, count
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        if soff(mid) <= pos then
            lo = mid
        else
            hi = mid - 1
        end
    end
    return lo
end
local function scan(needle)
    local res, n, pos = {}, 0, 1
    while true do
        local s = find(S.SRCH, needle, pos, true)
        if s == nil then
            break
        end
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

t = clock()
local rs, rn = scan("p")
out(string.format('search "p" cold: %.2f ms, %d results', (clock() - t) * 1000, rn))
t = clock()
rs, rn = refine(rs, "pa")
out(string.format('search "pa" refine: %.2f ms, %d results', (clock() - t) * 1000, rn))
t = clock()
rs, rn = refine(rs, "pain")
out(string.format('search "pain" refine: %.2f ms, %d results', (clock() - t) * 1000, rn))

collectgarbage("collect")
out(string.format("Lua memory after harness: %.1f MB", collectgarbage("count") / 1024))
out("=== done ===")
