import "Geldahr.LUI.Utils.CoordsData"

local REGION_NAMES = {
    [1] = "Eriador",
    [2] = "Rhovanion",
    [3] = "Gondor",
    [4] = "Mordor",
    [5] = "Haradwaith",
    [14] = "Tales of Yore",
}

local REGION_ORIGINS = {
    -- r1: values commonly used for Eriador in /loc conversions.
    -- Add other regions here if your /loc output uses r2/r3/... and you need zone lookup there.
    [1] = { origin_x = 29360, origin_y = 24880 },
}

Coords = Coords or {}
Coords.DATA = CoordsData

local function parse_loc(loc_text)
    if type(loc_text) ~= "string" then
        return nil, "loc_text must be a string"
    end

    local region_id = tonumber(loc_text:match("%sat%s+r(%d+)%s"))
    local lx = tonumber(loc_text:match("%slx(-?%d+)%s"))
    local ly = tonumber(loc_text:match("%sly(-?%d+)%s"))
    local ox = tonumber(loc_text:match("%sox([%-%d%.]+)%s"))
    local oy = tonumber(loc_text:match("%soy([%-%d%.]+)%s"))
    local oz = tonumber(loc_text:match("%soz([%-%d%.]+)%s"))

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

local function rect_area(coords)
    return math.abs((coords.top - coords.bottom) * (coords.right - coords.left))
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

function Coords.get_best_zone(ns, ew)
    return Coords.get_best_zone_in_region(1, ns, ew)
end

function Coords.get_best_zone_in_region(region_id, ns, ew)
    local best_zone = nil
    local best_zone_area = nil

    local region = CoordsData[region_id]
    if region == nil or region.zones == nil then
        return nil
    end

    local zones = region.zones
    for i = 1, #zones do
        local zone = zones[i]
        if rect_contains_point(zone.coords, ns, ew) then
            local area = rect_area(zone.coords)
            if best_zone == nil or area < best_zone_area then
                best_zone = zone
                best_zone_area = area
            end
        end
    end

    if best_zone == nil then
        return nil
    end

    local best_sub_zone = find_deepest(best_zone, ns, ew)
    return best_zone, best_sub_zone
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

    return {
        zone = zone.name,
        sub_zone = (sub_zone ~= nil and sub_zone ~= zone) and sub_zone.name or nil,
        player_coords = { ns = coords.ns, ew = coords.ew, z = coords.z },
        region_id = coords.region_id,
    }
end

function Coords.get_zone_name_from_loc(loc_text)
    local result, err = Coords.get_zone_from_loc(loc_text)
    if result == nil then
        return nil, nil, err
    end
    return result.zone, result.sub_zone, nil
end
