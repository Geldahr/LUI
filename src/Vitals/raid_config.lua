-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- RaidConfig: the raid slot assignment store. Slots 1-6 are Group A,
-- 7-12 B, 13-18 C, 19-24 D. Two modes:
--
-- - auto: members render in game order, chunked into groups of 6 (the
--   historical behavior). Active while no manual layout exists.
-- - manual: a user-arranged (or chat-received) name-per-slot layout that
--   supersedes the automatic layout entirely. Roster members without an
--   assigned slot fill empty cells so newcomers appear immediately.
--
-- The manual layout persists per character (State.character_settings), so
-- it survives reloads mid-raid. Hash values received from chat are kept
-- in-session so members who join later still resolve into their shared slot.

import "LUI.src.Vitals.raid_share_codec"

local Vitals = _G.LUI.Features.Vitals
local RaidConfig = Vitals.RaidConfig or {}
Vitals.RaidConfig = RaidConfig

local RaidShareCodec = Vitals.RaidShareCodec
local State = _G.LUI.Settings.State

local SLOT_COUNT = 24

RaidConfig.SLOT_COUNT = SLOT_COUNT

-- persisted slot keys are strings ("1".."24"); baked once so roster
-- rebuilds allocate no tostring garbage
local SLOT_KEYS = {}
for i = 1, SLOT_COUNT do
    SLOT_KEYS[i] = tostring(i)
end

-- Chat-received hash values not yet matched to a roster member
-- (session-only; resolved names go straight into the persisted layout).
local _pending = nil

local function _layout()
    return State.character_settings.raid_layout
end

local function _member_name(member)
    if member.GetName == nil then
        return nil
    end
    return member:GetName()
end

function RaidConfig.is_manual()
    return _layout().manual == true
end

function RaidConfig.clear()
    local layout = _layout()
    layout.manual = false
    layout.slots = {}
    _pending = nil
end

function RaidConfig.seed_from_snapshot(snapshot)
    local layout = _layout()
    local slots = {}
    local members = snapshot.members
    for i = 1, SLOT_COUNT do
        local member = members[i]
        if member ~= nil then
            slots[SLOT_KEYS[i]] = _member_name(member)
        end
    end
    layout.slots = slots
    layout.manual = true
    _pending = nil
end

-- display: array 1..24 of { name = ... } or false, as returned by
-- display_slots. Freezes what is currently shown into the manual layout.
function RaidConfig.seed_from_display(display)
    local layout = _layout()
    local slots = {}
    for i = 1, SLOT_COUNT do
        local cell = display[i]
        if cell ~= false then
            slots[SLOT_KEYS[i]] = cell.name
        end
    end
    layout.slots = slots
    layout.manual = true
    _pending = nil
end

-- Drop of from_slot onto to_slot: move when the target is empty
-- (to_name == nil), swap otherwise. Caller must be in manual mode.
function RaidConfig.apply_move(from_slot, from_name, to_slot, to_name)
    local slots = _layout().slots
    slots[SLOT_KEYS[to_slot]] = from_name
    slots[SLOT_KEYS[from_slot]] = to_name
end

function RaidConfig.apply_share(share, snapshot)
    local layout = _layout()
    layout.slots = {}
    layout.manual = true
    _pending = {
        salt = share.salt,
        values = share.values,
    }
    RaidConfig.resolve_pending(snapshot)
end

-- Matches still-pending share hashes against the current roster and writes
-- resolved names into the persisted layout. Cheap: runs only while a share
-- has unresolved cells, on roster rebuilds.
function RaidConfig.resolve_pending(snapshot)
    if _pending == nil then
        return
    end

    local layout = _layout()
    local taken = {}
    for i = 1, SLOT_COUNT do
        local name = layout.slots[SLOT_KEYS[i]]
        if name ~= nil then
            taken[name] = true
        end
    end

    local by_hash = {}
    local members = snapshot.members
    for i = 1, #members do
        local name = _member_name(members[i])
        if name ~= nil and taken[name] ~= true then
            by_hash[RaidShareCodec.hash_name(name, _pending.salt)] = name
        end
    end

    local unresolved = 0
    for i = 1, SLOT_COUNT do
        local value = _pending.values[i]
        if value > 0 and layout.slots[SLOT_KEYS[i]] == nil then
            local name = by_hash[value]
            if name ~= nil and taken[name] ~= true then
                layout.slots[SLOT_KEYS[i]] = name
                taken[name] = true
            else
                unresolved = unresolved + 1
            end
        end
    end

    if unresolved == 0 then
        _pending = nil
    end
end

local function _first_empty_slot(slots, named, allow_named)
    for i = 1, SLOT_COUNT do
        if slots[i] == false and (allow_named == true or named[i] ~= true) then
            return i
        end
    end
    return nil
end

-- Resolves the current mode against a roster snapshot. Returns an array
-- 1..24 of member entities, false = empty cell.
function RaidConfig.resolve_slots(snapshot)
    local members = snapshot.members
    local slots = {}

    if RaidConfig.is_manual() ~= true then
        for i = 1, SLOT_COUNT do
            local member = members[i]
            if member == nil then
                member = false
            end
            slots[i] = member
        end
        return slots
    end

    RaidConfig.resolve_pending(snapshot)

    local layout = _layout()
    local by_name = {}
    for i = 1, #members do
        local name = _member_name(members[i])
        if name ~= nil then
            by_name[name] = members[i]
        end
    end

    local used = {}
    local named = {}
    for i = 1, SLOT_COUNT do
        slots[i] = false
        local name = layout.slots[SLOT_KEYS[i]]
        named[i] = name ~= nil
        if name ~= nil then
            local entity = by_name[name]
            if entity ~= nil and used[name] ~= true then
                slots[i] = entity
                used[name] = true
            end
        end
    end

    -- Newcomers fill nameless cells first; cells reserved for an absent
    -- member are display-filled only as a last resort (their assignment is
    -- not overwritten).
    for i = 1, #members do
        local member = members[i]
        local name = _member_name(member)
        if name ~= nil and used[name] ~= true then
            local target = _first_empty_slot(slots, named, false)
            if target == nil then
                target = _first_empty_slot(slots, named, true)
            end
            if target ~= nil then
                slots[target] = member
                used[name] = true
            end
        end
    end

    return slots
end

-- Window/share view: array 1..24 of { name, entity } (entity nil for an
-- assigned-but-absent member), false = empty cell.
function RaidConfig.display_slots(snapshot)
    local entities = RaidConfig.resolve_slots(snapshot)
    local layout = _layout()
    local manual = layout.manual == true
    local display = {}
    for i = 1, SLOT_COUNT do
        local entity = entities[i]
        if entity ~= false then
            display[i] = {
                name = _member_name(entity),
                entity = entity,
            }
        elseif manual == true and layout.slots[SLOT_KEYS[i]] ~= nil then
            display[i] = {
                name = layout.slots[SLOT_KEYS[i]],
                entity = nil,
            }
        else
            display[i] = false
        end
    end
    return display
end
