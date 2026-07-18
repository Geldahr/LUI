-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Deed completion view-store: a read-only mirror of the DeedTracker
-- plugin's per-character save file. LUI never writes deed data —
-- completion state (detection and manual checking) is owned by
-- DeedTracker, and the Deeds view re-reads its file whenever the view
-- is opened. Without DeedTracker data every deed simply shows as not
-- completed.

local Encyclopedia = _G.LUI.Features.Encyclopedia

local Deeds = {}
Encyclopedia.Deeds = Deeds

-- completed map keyed by stringified deed game id -> { w = timestamp };
-- nil until the first refresh
local _completed = nil
-- bumped when a refresh actually changed the set; consumers fold it into
-- their cache signatures so unchanged files keep cached lists valid
local _revision = 1

-- DeedTracker saves one Server-scope file per character:
-- "DeedTracker_CharData_<name>", leading "~" stripped, "-" -> "_"
local function _file_key()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetName == nil then
        return nil
    end
    local name = player:GetName()
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if name:sub(1, 1) == "~" then
        name = name:sub(2)
    end
    return "DeedTracker_CharData_" .. name:gsub("-", "_")
end

-- the file is saved through the Vindar number patch: numbers (ids,
-- methods) arrive as plain decimal strings, and other strings may carry
-- a leading "#" marker
local function _plain(value)
    if type(value) ~= "string" then
        return tostring(value)
    end
    if value:sub(1, 1) == "#" then
        return value:sub(2)
    end
    return value
end

-- re-read the file (read-only; foreign data, so failures and unexpected
-- shapes degrade to an empty set)
function Deeds.refresh()
    local completed = {}
    local key = _file_key()
    if key ~= nil then
        local ok, loaded = pcall(Turbine.PluginData.Load, Turbine.DataScope.Server, key)
        if ok == true and type(loaded) == "table" and type(loaded.DEEDS) == "table" then
            for id, entry in pairs(loaded.DEEDS) do
                if type(entry) == "table" and entry.W ~= nil then
                    completed[_plain(id)] = { w = _plain(entry.W) }
                end
            end
        end
    end

    local changed = _completed == nil
    if changed ~= true then
        local old_count, new_count = 0, 0
        for _ in pairs(_completed) do
            old_count = old_count + 1
        end
        for id, entry in pairs(completed) do
            new_count = new_count + 1
            local old = _completed[id]
            if old == nil or old.w ~= entry.w then
                changed = true
            end
        end
        if old_count ~= new_count then
            changed = true
        end
    end

    _completed = completed
    if changed == true then
        _revision = _revision + 1
    end
end

-- completion entry ({ w = timestamp }) or nil
function Deeds.completed_entry(deed_id)
    if _completed == nil then
        Deeds.refresh()
    end
    return _completed[tostring(deed_id)]
end

function Deeds.revision()
    return _revision
end
