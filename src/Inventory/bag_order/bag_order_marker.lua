-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Bag Order Guide window, the marker: picked by a drop on the marker box or
-- a click in the list, refused when not unique (name or icon), then moved
-- into the current row's first slot through the inventory window's
-- operation slot. One move at a time: clicks made meanwhile only change the
-- step, and the finished move asks again, so fast clicking ends in a single
-- move to the latest row.

local TR = _G.LUI.Locale.TR
local Inventory = _G.LUI.Features.Inventory
local Windows = _G.LUI.Runtime.Windows
import "LUI.src.Inventory.operations"
import "LUI.src.Inventory.bag_order.bag_order_model"
import "LUI.src.Inventory.bag_order.bag_order_common"
import "LUI.src.Inventory.bag_order.marker_move"
import "LUI.src.Inventory.bag_order.bag_order_window"

local Operations = Inventory.Operations
local Model = Inventory.BagOrderModel
local Common = Inventory.BagOrderCommon
local MarkerMove = Inventory.MarkerMove
local BagOrderWindow = Inventory.BagOrderWindow

local MOVE_RETRY_SECONDS = 0.5

function BagOrderWindow:_problem_text(name, problem)
    if problem == nil then
        return nil
    end
    if problem.kind == "duplicate" then
        return string.format(TR["You have %s %d times. Pick an item you have only once."], name, problem.count)
    end
    return string.format(TR["%s looks like %s. Pick an item that stands out."], name, problem.name)
end

function BagOrderWindow:_drop_marker(info)
    if info == nil or info.GetShortcut == nil then
        return
    end
    -- game drag data: anything can be dropped here, skills included
    local ok, item = pcall(function()
        local shortcut = info:GetShortcut()
        if shortcut == nil or shortcut.GetItem == nil then
            return nil
        end
        return shortcut:GetItem()
    end)
    self:_read_entries()
    if ok ~= true or item == nil then
        self:_refuse_marker(TR["Only items can be markers. Drag an item from your bags."])
        return
    end
    local slot = Model.first_with_key(self.entries, Operations.entry_for_item(item).merge_key)
    if slot == nil then
        self:_refuse_marker(TR["This item is not in your bags. Drag an item from your bags."])
        return
    end
    self:_pick_slot(slot)
end

function BagOrderWindow:_refuse_marker(text)
    self.marker = nil
    self.marker_error = text
    self:_refresh_view()
end

function BagOrderWindow:_pick_slot(slot)
    local entry = self.entries[slot]
    if entry.empty == true then
        return
    end
    local problem = Model.marker_problem(self.entries, slot)
    if problem ~= nil then
        self:_refuse_marker(self:_problem_text(entry.name, problem))
        return
    end
    self.marker = {
        merge_key = entry.merge_key,
        name = entry.name,
        icon_id = entry.icon_id,
        background_id = entry.background_id,
        slot = slot,
        home = slot,
    }
    self.marker_error = nil
    self.move_error = nil
    self.put_back = false
    self:_refresh_view()
    self:_request_marker_move()
end

function BagOrderWindow:_clear_marker()
    self.marker = nil
    self.marker_error = nil
    self.move_error = nil
    self:_refresh_view()
end

-- where the marker should be now, nil when it stays put
function BagOrderWindow:_wanted_marker_slot()
    if self.marker == nil or self.marker.slot == nil then
        return nil
    end
    if self.phase == Common.PHASE_STEPS then
        local step = self.steps[self.step_index]
        if step.kind == "add" then
            return Model.first_slot(step.row)
        end
    elseif self.phase == Common.PHASE_DONE and self.put_back == true then
        return self.marker.home
    end
    return nil
end

function BagOrderWindow:_request_marker_move()
    self._move_wanted = false
    self.waiting = false
    local target = self:_wanted_marker_slot()
    if self.closed == true or self.moving == true or self.marker_error ~= nil or self.move_error ~= nil or
        self.size_error ~= nil or target == nil or target == self.marker.slot then
        self:_sync_updates()
        self:_refresh_status()
        return
    end
    local operation = MarkerMove.create(self.backpack, self.marker.slot, target)
    operation.on_done = function(result)
        self:_move_done(result)
    end
    if Windows.inventory:run_inventory_operation(operation, TR["Moving the bag order marker..."]) == true then
        self.moving = true
        self.moving_to = target
    else
        -- a Sort or Merge is running: ask again shortly
        self.waiting = true
        self._move_wanted = true
        self._retry_at = Turbine.Engine.GetGameTime() + MOVE_RETRY_SECONDS
    end
    self:_sync_updates()
    self:_refresh_status()
end

function BagOrderWindow:_move_done(result)
    self.moving = false
    if self.closed == true then
        return
    end
    if result.failed == true then
        self.move_error = TR[result.message_key]
    end
    self:_read_entries()
    self:_refresh_tiles()
    self:_refresh_view()
    self:_request_marker_move()
end
