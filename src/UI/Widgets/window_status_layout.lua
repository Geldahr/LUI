-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- LuiWindow's status bar, placing its items (window_status_bar.lua builds
-- them). Too narrow: the center group hides first; then the left label
-- that no longer fits ends with "..." (its full text as a hint) and the
-- left items after it hide; right items hide only when the right group
-- alone is wider than the bar.

local Utils = _G.LUI.Utils
local Widgets = _G.LUI.UI.Widgets
import "LUI.src.Utils.text_width"

local LuiWindow = Widgets.LuiWindow

-- bar edge to the first / last item
local BASE_PAD_X = 6
-- between two items of a group
local BASE_ITEM_GAP = 8

local function _scaled_int(scale, value)
    return math.floor((value * scale) + 0.5)
end


-- called by LuiWindow:_layout: the bar at the bottom of the inner area,
-- returns the height it takes (0 when hidden)
function LuiWindow:_layout_status_bar(inner_w, inner_h, content_y)
    if self._status_visible ~= true then
        return 0
    end
    local bar_h = math.min(self:_header_bar_h(), math.max(0, inner_h - content_y))
    self._status_bar:SetPosition(0, inner_h - bar_h)
    self._status_bar:SetSize(inner_w, bar_h)
    self._status_line:SetPosition(0, 0)
    self._status_line:SetSize(inner_w, math.min(self:_status_line_h(), bar_h))
    self:_layout_status_items()
    return bar_h
end

function LuiWindow:_status_item_width(item)
    local kind = item._kind
    if kind == "label" then
        return item._text_w
    end
    if kind == "icon" then
        return self:_status_icon_size()
    end
    if kind == "separator" then
        return self:_status_line_h()
    end
    return _scaled_int(self._scale, item._base_w)
end

function LuiWindow:_show_status_text(item, text)
    if item._shown_text ~= text then
        item._shown_text = text
        item.control:SetText(text)
    end
end

-- a label in `room` px: whole, or cut with "..." (hinting its full text);
-- returns its right edge, or x when not even one character fits (hidden)
function LuiWindow:_place_status_label(item, x, room, item_y, item_h)
    local text = item._text
    local width = item._text_w
    if width > room then
        text = Utils.ellipsize_in_font(item._text, self._status_font, room - 2)
        if text == "" then
            item.control:SetVisible(false)
            return x
        end
        width = room
    end
    self:_show_status_text(item, text)
    item.control:SetPosition(x, item_y)
    item.control:SetSize(width, item_h)
    item.control:SetVisible(true)
    return x + width
end

function LuiWindow:_place_status_item(item, x, width, item_y, item_h)
    local kind = item._kind
    local control = item.control
    if kind == "label" then
        self:_place_status_label(item, x, width, item_y, item_h)
        return
    end
    local inset = self:_status_inset()
    if kind == "icon" then
        control:SetPosition(x, item_y + math.floor((item_h - width) / 2))
    elseif kind == "separator" then
        control:SetPosition(x, item_y + inset)
        control:SetSize(width, math.max(0, item_h - (2 * inset)))
    elseif kind == "progress" then
        control:SetPosition(x, item_y + inset)
        control:SetSize(width, math.max(0, item_h - (2 * inset)))
        self:_fill_status_progress(item)
    else
        control:SetPosition(x, item_y)
        control:SetSize(width, item_h)
    end
    control:SetVisible(true)
end

local function _hide_all(list)
    for i = 1, #list do
        list[i].control:SetVisible(false)
    end
end

-- places the items in the bar as it is now; an item change lays out the
-- bar only, never the window
function LuiWindow:_layout_status_items()
    if self._status_visible ~= true then
        return
    end

    local bar_w, bar_h = self._status_bar:GetSize()
    local line_h = self:_status_line_h()
    local item_y = line_h
    local item_h = math.max(0, bar_h - line_h)
    local pad = _scaled_int(self._scale, BASE_PAD_X)
    local gap = _scaled_int(self._scale, BASE_ITEM_GAP)

    local groups = { left = {}, center = {}, right = {} }
    local items = self._status_items
    for i = 1, #items do
        local item = items[i]
        if item._visible == true then
            local group = groups[item._align]
            group[#group + 1] = item
        else
            item.control:SetVisible(false)
        end
    end

    -- right: packed against the right edge, in insertion order
    local right = groups.right
    local limit = bar_w - pad
    local x = bar_w - pad
    for i = #right, 1, -1 do
        local item = right[i]
        local width = self:_status_item_width(item)
        if x - width < pad then
            for j = i, 1, -1 do
                right[j].control:SetVisible(false)
            end
            break
        end
        x = x - width
        self:_place_status_item(item, x, width, item_y, item_h)
        limit = x - gap
        x = limit
    end

    -- left (or the message in its place)
    local left = groups.left
    local left_end = nil
    local message = self._status_message
    if message._text ~= nil then
        _hide_all(left)
        local end_x = self:_place_status_label(message, pad, limit - pad, item_y, item_h)
        if end_x > pad then
            left_end = end_x
        end
    else
        x = pad
        for i = 1, #left do
            local item = left[i]
            local width = self:_status_item_width(item)
            local room = limit - x
            local placed = false
            if width <= room then
                self:_place_status_item(item, x, width, item_y, item_h)
                left_end = x + width
                x = x + width + gap
                placed = true
            elseif item._kind == "label" then
                local end_x = self:_place_status_label(item, x, room, item_y, item_h)
                if end_x > x then
                    left_end = end_x
                end
            else
                item.control:SetVisible(false)
            end
            if placed ~= true then
                for j = i + 1, #left do
                    left[j].control:SetVisible(false)
                end
                break
            end
        end
    end

    -- center: whole group centered on the bar, or hidden
    local center = groups.center
    local total = 0
    for i = 1, #center do
        if i > 1 then
            total = total + gap
        end
        total = total + self:_status_item_width(center[i])
    end
    x = math.floor((bar_w - total) / 2)
    local clear = pad
    if left_end ~= nil then
        clear = left_end + gap
    end
    if x < clear or x + total > limit then
        _hide_all(center)
        return
    end
    for i = 1, #center do
        local item = center[i]
        local width = self:_status_item_width(item)
        self:_place_status_item(item, x, width, item_y, item_h)
        x = x + width + gap
    end
end
