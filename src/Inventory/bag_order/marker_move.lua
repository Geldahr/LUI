-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- The Bag Order Guide's marker move: one item to another slot (a swap when
-- that slot holds an item), confirmed against the expected after-state. It
-- runs in the inventory window's operation slot like Sort / Merge, with the
-- same tick(now) -> { done, failed, message_key, moves } contract.

local Inventory = _G.LUI.Features.Inventory
import "LUI.src.Inventory.operations"

local Operations = Inventory.Operations

local MarkerMove = {}
MarkerMove.__index = MarkerMove
Inventory.MarkerMove = MarkerMove

local RESPONSE_TIMEOUT = 2
local MESSAGE_COMPLETE = "Item moved."
local MESSAGE_MERGES = "This move would merge two stacks."
local MESSAGE_FAILED = "Inventory action failed."
local MESSAGE_CHANGED = "Inventory changed; action stopped."
local MESSAGE_TIMEOUT = "Inventory action timed out."

function MarkerMove.create(backpack, from, to)
    local source = Operations.entry_for_slot(backpack, from)
    if source.empty == true then
        error("MarkerMove.create: slot " .. tostring(from) .. " is empty")
    end
    return setmetatable({
        kind = "move",
        backpack = backpack,
        size = backpack:GetSize(),
        from = from,
        to = to,
        source_before = source,
        destination_before = Operations.entry_for_slot(backpack, to),
        dropped_at = nil,
        moves = 0,
    }, MarkerMove)
end

function MarkerMove:_result(failed, message_key)
    return { done = true, failed = failed, message_key = message_key, moves = self.moves }
end

-- runs every frame while pending: reads only the two slots involved
function MarkerMove:tick(now)
    local backpack = self.backpack
    if backpack:GetSize() ~= self.size then
        return self:_result(true, MESSAGE_CHANGED)
    end
    local source = Operations.entry_for_slot(backpack, self.from)
    local destination = Operations.entry_for_slot(backpack, self.to)
    local before = Operations.entries_match(source, self.source_before) == true and
        Operations.entries_match(destination, self.destination_before) == true

    if self.dropped_at == nil then
        if before ~= true then
            return self:_result(true, MESSAGE_CHANGED)
        end
        if Operations.can_merge(source, destination) == true then
            return self:_result(true, MESSAGE_MERGES)
        end
        if Operations.drop_item(self.backpack, source.item, self.to) ~= true then
            return self:_result(true, MESSAGE_FAILED)
        end
        self.moves = 1
        self.dropped_at = now
        return { done = false, failed = false }
    end

    if Operations.entries_match(source, self.destination_before) == true and
        Operations.entries_match(destination, self.source_before) == true then
        return self:_result(false, MESSAGE_COMPLETE)
    end
    if now - self.dropped_at >= RESPONSE_TIMEOUT then
        if before == true then
            return self:_result(true, MESSAGE_TIMEOUT)
        end
        return self:_result(true, MESSAGE_CHANGED)
    end
    return { done = false, failed = false }
end
