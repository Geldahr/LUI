-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Bag Order Guide logic (no game API): the target layout (rows per bag),
-- the guided steps, the reference list's column flow and the marker
-- checks. The game's bags show the backpack as rows of 5 slots that the
-- player can drag between bags; a row only drops at the bottom of another
-- bag, and a bag may be empty. The guide empties each bag, then has the
-- player add its rows one at a time, found by a marker item the plugin
-- moves into the row's first slot.

local Inventory = _G.LUI.Features.Inventory

local Model = {}
Inventory.BagOrderModel = Model

Model.ROW_SIZE = 5
Model.MAX_BAGS = 6

function Model.row_count(slot_count)
    return math.ceil(slot_count / Model.ROW_SIZE)
end

function Model.first_slot(row)
    return ((row - 1) * Model.ROW_SIZE) + 1
end

function Model.last_slot(row, slot_count)
    return math.min(row * Model.ROW_SIZE, slot_count)
end

function Model.row_of_slot(slot)
    return math.floor((slot - 1) / Model.ROW_SIZE) + 1
end

-- rows split evenly over the bags, the first bags taking the extra rows
function Model.even_rows(row_count, bag_count)
    local rows = {}
    local base = math.floor(row_count / bag_count)
    local extra = row_count - (base * bag_count)
    for bag = 1, bag_count do
        rows[bag] = base
        if bag <= extra then
            rows[bag] = base + 1
        end
    end
    return rows
end

-- the last bag's rows: what the other bags leave (negative = too many)
function Model.remainder(rows, bag_count, row_count)
    local used = 0
    for bag = 1, bag_count - 1 do
        used = used + rows[bag]
    end
    return row_count - used
end

-- the bag every row is emptied into: one that stays empty if there is one
-- (the last such), else the last bag
function Model.dump_bag(rows, bag_count)
    for bag = bag_count, 1, -1 do
        if rows[bag] == 0 then
            return bag
        end
    end
    return bag_count
end

-- The guided steps, bag by bag:
--   { kind = "empty", bag, into }: every row of `bag` to the bottom of `into`
--   { kind = "add", bag, row, position, count }: row `row` (slot order) to
--     the bottom of `bag`, its `position`-th of `count` rows
-- The dump bag gets no Empty step while it stays empty; when it gets rows,
-- it is emptied into the bag filled just before it. No row is ever dropped
-- on its own bag, and every bag fills from the top down.
function Model.build_steps(rows, bag_count)
    local steps = {}
    local dump = Model.dump_bag(rows, bag_count)
    local previous = nil
    local row = 1
    for bag = 1, bag_count do
        local count = rows[bag]
        if bag ~= dump or count > 0 then
            local into = dump
            if bag == dump then
                into = previous
            end
            steps[#steps + 1] = { kind = "empty", bag = bag, into = into }
            for position = 1, count do
                steps[#steps + 1] = { kind = "add", bag = bag, row = row, position = position, count = count }
                row = row + 1
            end
            if count > 0 then
                previous = bag
            end
        end
    end
    return steps
end

-- the reference list's entries in bag order: a header per bag, then its rows
function Model.list_items(rows, bag_count)
    local items = {}
    local row = 1
    for bag = 1, bag_count do
        items[#items + 1] = { kind = "header", bag = bag, cont = false, empty = rows[bag] == 0 }
        for _ = 1, rows[bag] do
            items[#items + 1] = { kind = "row", bag = bag, row = row }
            row = row + 1
        end
    end
    return items
end

-- Fills columns top to bottom up to `limit`. A header moves with its first
-- row; a bag that goes on in a new column repeats its header (cont).
local function _fill_columns(items, header_h, row_h, limit)
    local columns = { {} }
    local height = 0
    local tallest = 0
    for i = 1, #items do
        local item = items[i]
        local item_h = row_h
        local need = row_h
        if item.kind == "header" then
            item_h = header_h
            need = header_h
            local next_item = items[i + 1]
            if next_item ~= nil and next_item.kind == "row" then
                need = header_h + row_h
            end
        end
        local column = columns[#columns]
        if #column > 0 and height + need > limit then
            column = {}
            columns[#columns + 1] = column
            height = 0
            if item.kind == "row" then
                column[1] = { kind = "header", bag = item.bag, cont = true, empty = false }
                height = header_h
            end
        end
        column[#column + 1] = item
        height = height + item_h
        if height > tallest then
            tallest = height
        end
    end
    return columns, tallest
end

-- Newspaper flow of the list: the fewest columns (up to max_columns) whose
-- height fits max_height, balanced; returns the columns and their height.
function Model.flow_columns(items, header_h, row_h, max_height, max_columns)
    local total = 0
    for i = 1, #items do
        if items[i].kind == "header" then
            total = total + header_h
        else
            total = total + row_h
        end
    end
    local columns, tallest
    for count = 1, max_columns do
        local limit = math.max(math.ceil(total / count), header_h + row_h)
        columns, tallest = _fill_columns(items, header_h, row_h, limit)
        while #columns > count do
            limit = limit + row_h
            columns, tallest = _fill_columns(items, header_h, row_h, limit)
        end
        if tallest <= max_height then
            return columns, tallest
        end
    end
    return columns, tallest
end

-- Why the item in `slot` can't be the marker, nil when it can: the player
-- finds the marker by its look, so its name and its icon must be unique.
-- entries: backpack entries by slot { empty, name, name_key, icon_id }.
function Model.marker_problem(entries, slot)
    local marker = entries[slot]
    local same_name = 1
    local look_alike = nil
    for i = 1, #entries do
        local entry = entries[i]
        if i ~= slot and entry.empty ~= true then
            if entry.name_key == marker.name_key then
                same_name = same_name + 1
            elseif look_alike == nil and marker.icon_id ~= 0 and entry.icon_id == marker.icon_id then
                look_alike = entry.name
            end
        end
    end
    if same_name > 1 then
        return { kind = "duplicate", count = same_name }
    end
    if look_alike ~= nil then
        return { kind = "look_alike", name = look_alike }
    end
    return nil
end

-- the slot holding the marker (unique merge key), nil when gone or doubled
function Model.find_marker(entries, merge_key)
    local found = nil
    for i = 1, #entries do
        local entry = entries[i]
        if entry.empty ~= true and entry.merge_key == merge_key then
            if found ~= nil then
                return nil
            end
            found = i
        end
    end
    return found
end

-- the first slot holding an item with this merge key, nil when none
function Model.first_with_key(entries, merge_key)
    for i = 1, #entries do
        local entry = entries[i]
        if entry.empty ~= true and entry.merge_key == merge_key then
            return i
        end
    end
    return nil
end
