-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Utils.coords_data"

local Utils = _G.LUI.Utils

local REGION_NAMES = {
    [1] = "Eriador",
    [2] = "Rhovanion",
    [3] = "Gondor",
    [4] = "Mordor",
    [5] = "Haradwaith",
    [14] = "Tales of Yore",
}

local REGION_ORIGINS = {
    -- LotRO reuses the same developer/player origin offset across region layers.
    [1] = { origin_x = 29360, origin_y = 24880 },
    [2] = { origin_x = 29360, origin_y = 24880 },
    [3] = { origin_x = 29360, origin_y = 24880 },
    [4] = { origin_x = 29360, origin_y = 24880 },
    [5] = { origin_x = 29360, origin_y = 24880 },
    [14] = { origin_x = 29360, origin_y = 24880 },
}

Utils.Coords = Utils.Coords or {}
local Coords = Utils.Coords
Coords.DATA = Utils.CoordsData

-- nil when the /loc field was not found
local function _parse_decimal(value)
    if value == nil then
        return nil
    end

    local normalized = value:gsub(",", ".")
    return tonumber(normalized)
end

local function parse_loc(loc_text)
    local normalized = " " .. string.lower(loc_text) .. " "

    local region_id = tonumber(normalized:match("[^%w]r%s*(%d+)"))
    local lx = tonumber(normalized:match("[^%w]lx%s*[:=]?%s*(-?%d+)"))
    local ly = tonumber(normalized:match("[^%w]ly%s*[:=]?%s*(-?%d+)"))
    local ox = _parse_decimal(normalized:match("[^%w]ox%s*[:=]?%s*([%-%d%.,]+)"))
    local oy = _parse_decimal(normalized:match("[^%w]oy%s*[:=]?%s*([%-%d%.,]+)"))
    local oz = _parse_decimal(normalized:match("[^%w]oz%s*[:=]?%s*([%-%d%.,]+)"))

    if (region_id == nil or lx == nil or ly == nil or ox == nil or oy == nil or oz == nil) then
        return nil, "could not parse /loc string"
    end

    return {
        region_id = region_id,
        lx = lx,
        ly = ly,
        ox = ox,
        oy = oy,
        oz = oz,
    }
end

local function world_from_loc(loc)
    local block_x = math.floor(loc.lx / 8)
    local block_y = math.floor(loc.ly / 8)

    local world_x = (block_x * 160) + loc.ox
    local world_y = (block_y * 160) + loc.oy

    return world_x, world_y, loc.oz
end

local function player_coords_from_world(region_id, world_x, world_y, world_z)
    local origin = REGION_ORIGINS[region_id]
    if origin == nil then
        local region_name = REGION_NAMES[region_id]
        if region_name ~= nil then
            return nil,
                "unknown region origin (add REGION_ORIGINS entry for r"
                    .. tostring(region_id)
                    .. " - "
                    .. region_name
                    .. ")"
        end
        return nil, "unknown region origin (add REGION_ORIGINS entry for r" .. tostring(region_id) .. ")"
    end

    local ew = (world_x - origin.origin_x) / 200
    local ns = (world_y - origin.origin_y) / 200

    return {
        ns = ns,
        ew = ew,
        z = world_z,
    }
end

local function rect_contains_point(coords, ns, ew)
    return (
        ns <= coords.top and
        ns >= coords.bottom and
        ew >= coords.left and
        ew <= coords.right
    )
end


local function find_deepest(node, ns, ew)
    local children = node.sub_zones
    for i = 1, #children do
        local child = children[i]
        if rect_contains_point(child.coords, ns, ew) then
            return find_deepest(child, ns, ew)
        end
    end
    return node
end

function Coords.loc_to_player_coords(loc_text)
    local loc, err = parse_loc(loc_text)
    if loc == nil then
        return nil, err
    end

    local world_x, world_y, world_z = world_from_loc(loc)
    local player, perr = player_coords_from_world(loc.region_id, world_x, world_y, world_z)
    if player == nil then
        return nil, perr
    end

    return {
        region_id = loc.region_id,
        world_x = world_x,
        world_y = world_y,
        world_z = world_z,
        ns = player.ns,
        ew = player.ew,
        z = player.z,
    }
end

function Coords.get_best_zone_in_region(region_id, ns, ew)
    local zones = Coords.DATA[region_id].zones
    for i = 1, #zones do
        local zone = zones[i]
        if rect_contains_point(zone.coords, ns, ew) then
            return zone, find_deepest(zone, ns, ew)
        end
    end

    return nil
end

local function _node_names(node)
    local names = { node.name }
    for i = 1, #node.aliases do
        names[#names + 1] = node.aliases[i]
    end
    return names
end

-- names of the nodes from `zone` down to the deepest one containing the
-- point (first matching child at each level), deepest first; each entry is
-- { name, alias... }
local function _zone_names(zone, ns, ew)
    local path = {}
    local node = zone
    while node ~= nil do
        table.insert(path, 1, _node_names(node))
        local next_node = nil
        for i = 1, #node.sub_zones do
            local child = node.sub_zones[i]
            if rect_contains_point(child.coords, ns, ew) then
                next_node = child
                break
            end
        end
        node = next_node
    end
    return path
end

-- every path from `zone` down through ALL children containing the point
-- (sub-zones overlap too), each deepest first like _zone_names
local function _all_zone_paths(zone, ns, ew, above, out)
    local chain = { _node_names(zone) }
    for i = 1, #above do
        chain[#chain + 1] = above[i]
    end
    local deeper = false
    for i = 1, #zone.sub_zones do
        local child = zone.sub_zones[i]
        if rect_contains_point(child.coords, ns, ew) then
            deeper = true
            _all_zone_paths(child, ns, ew, chain, out)
        end
    end
    if deeper ~= true then
        out[#out + 1] = chain
    end
    return out
end

function Coords.get_zones_in_region(region_id, ns, ew)
    local out = {}
    local zones = Coords.DATA[region_id].zones
    for i = 1, #zones do
        local zone = zones[i]
        if rect_contains_point(zone.coords, ns, ew) then
            out[#out + 1] = zone
        end
    end
    return out
end

function Coords.get_zone_from_loc(loc_text)
    local coords, err = Coords.loc_to_player_coords(loc_text)
    if coords == nil then
        return nil, err
    end

    local zone, sub_zone = Coords.get_best_zone_in_region(coords.region_id, coords.ns, coords.ew)
    if zone == nil then
        return nil, "zone not found for these coordinates"
    end

    local candidates = {}
    local containing = Coords.get_zones_in_region(coords.region_id, coords.ns, coords.ew)
    for i = 1, #containing do
        _all_zone_paths(containing[i], coords.ns, coords.ew, {}, candidates)
    end

    return {
        zone = zone.name,
        sub_zone = (sub_zone ~= nil and sub_zone ~= zone) and sub_zone.name or nil,
        names = _zone_names(zone, coords.ns, coords.ew),
        candidates = candidates,
        player_coords = { ns = coords.ns, ew = coords.ew, z = coords.z },
        region_id = coords.region_id,
    }
end

function Coords.resolve_location_from_chat(loc_text)
    local result, err = Coords.get_zone_from_loc(loc_text)
    if result == nil then
        return nil, err
    end

    local area = result.sub_zone
    if area == result.zone then
        area = nil
    end

    return {
        region = result.zone,
        area = area,
        -- every zone level with its aliases, deepest first: the Bestiary
        -- matches them against both its regions and its areas
        names = result.names,
        -- the same for every zone containing the point (zones overlap)
        candidates = result.candidates,
        player_coords = result.player_coords,
        region_id = result.region_id,
    }
end
