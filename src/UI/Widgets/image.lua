-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local class = _G.LUI.Core.class
import "Turbine.UI"
import "LUI.src.UI.Widgets.style"

local Widgets = _G.LUI.UI.Widgets
local Style = Widgets.Style

---@class Image : Turbine.UI.Control
local Image = class(Turbine.UI.Control)
Widgets.Image = Image

local function _round_size(value)
    if value == nil then
        return nil
    end
    return math.floor(value + 0.5)
end

local function _has_flag(value, flag)
    if value == nil then
        return false
    end
    return math.floor(value / flag) % 2 == 1
end

local _native_sizes = {}
local EDGE_PROPORTIONAL = Turbine.UI.EdgeAttachmentType.Proportional
local Control = Turbine.UI.Control

-- Native sizes are measured on a throwaway control: since U49.6 a control that
-- has been in stretch mode 2 keeps the image size and ignores later SetSize.
local function _native_size(icon)
    local size = _native_sizes[icon]
    if size == nil then
        local probe = Turbine.UI.Control()
        probe:SetBackground(icon)
        probe:SetStretchMode(2)
        local w, h = probe:GetSize()
        size = { w, h }
        _native_sizes[icon] = size
    end
    return size[1], size[2]
end

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    -- Since U49.6 a stretched control ignores SetSize; it only rescales when
    -- its parent resizes and its edges are attached. The picture therefore
    -- lives on a child that fills this control, and this control is the one
    -- that gets sized and positioned.
    self._img = Control()
    self._img:SetParent(self)
    self._img:SetMouseVisible(false)

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._scale = 1
    self._requested_w = nil
    self._requested_h = nil
    self._requested_side = nil
    self._align = nil

    self._real_w = nil
    self._real_h = nil

    if icon ~= nil then
        self:set_icon(icon, w, h)
    elseif w ~= nil then
        self:set_size(w, h)
    end
end

function Image:SetBackground(background)
    self._img:SetBackground(background)
end

function Image:GetBackground()
    return self._img:GetBackground()
end

function Image:SetStretchMode(mode)
    self._img:SetStretchMode(mode)
end

function Image:GetStretchMode()
    return self._img:GetStretchMode()
end

function Image:SetBlendMode(mode)
    self._img:SetBlendMode(mode)
end

function Image:SetBackColor(color)
    self._img:SetBackColor(color)
end

function Image:GetBackColor()
    return self._img:GetBackColor()
end

function Image:SetBackColorBlendMode(mode)
    self._img:SetBackColorBlendMode(mode)
end

function Image:SetOpacity(opacity)
    self._img:SetOpacity(opacity)
end

function Image:GetOpacity()
    return self._img:GetOpacity()
end

function Image:_store_size_request(w, h)
    w = _round_size(w)
    h = _round_size(h)

    if w ~= nil and h == nil then
        self._requested_side = w
        self._requested_w = nil
        self._requested_h = nil
    elseif w ~= nil or h ~= nil then
        self._requested_w = w
        self._requested_h = h
        self._requested_side = nil
    end

    return w, h
end

function Image:set_size(w, h)
    if w == nil then
        return nil
    end
    w, h = self:_store_size_request(w, h)

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if w ~= nil and h ~= nil then
        self._real_w = w
        self._real_h = h
        self:SetSize(w, h)
        self:set_alignment(self._align)
        return w, h
    end

    -- If only w is set we assume that we want to size it so it keeps
    -- the aspect ration but the image can fit in a square w x w
    if w < 0 then
        w = 0
    end

    local new_w = 0
    local new_h = 0
    if self.original_w > self.original_h then
        new_w = w
        new_h = w * self.original_h / self.original_w
    else
        new_h = w
        new_w = w * self.original_w / self.original_h
    end

    self:SetSize(new_w, new_h)
    self:set_alignment(self._align)

    self._real_w = new_w
    self._real_h = new_h

    return new_w, new_h
end

function Image:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
end

function Image:set_width(w)
    w = _round_size(w)
    if w == nil then
        return nil
    end

    self._requested_side = nil
    self._requested_w = w
    self._requested_h = nil

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if w < 0 then
        w = 0
    end

    local new_h = w * self.original_h / self.original_w

    self._real_w = w
    self._real_h = new_h

    self:SetSize(w, new_h)
    self:set_alignment(self._align)

    return w, new_h
end

function Image:set_height(h)
    h = _round_size(h)
    if h == nil then
        return
    end

    self._requested_side = nil
    self._requested_w = nil
    self._requested_h = h

    if self.original_h == nil or self.original_w == nil then
        return
    end

    if h < 0 then
        h = 0
    end

    local new_w = h * self.original_w / self.original_h

    self._real_w = new_w
    self._real_h = h

    self:SetSize(new_w, h)
    self:set_alignment(self._align)

    return new_w, h
end

function Image:get_width()
    return self._real_w
end

function Image:get_height()
    return self._real_h
end

function Image:get_size()
    return self._real_w, self._real_h
end

function Image:_set_size(w, h)
    if w ~= nil or h ~= nil then
        self:_store_size_request(w, h)
    end

    if self.original_w == nil or self.original_h == nil then
        return nil
    end

    if self._requested_side ~= nil then
        return self:set_size(self._requested_side)
    elseif self._requested_w ~= nil and self._requested_h ~= nil then
        return self:set_size(self._requested_w, self._requested_h)
    elseif self._requested_w ~= nil then
        return self:set_width(self._requested_w)
    elseif self._requested_h ~= nil then
        return self:set_height(self._requested_h)
    end
end

function Image:set_icon(icon, w, h)
    if icon == nil then
        self.original_w = nil
        self.original_h = nil
        self._real_w = nil
        self._real_h = nil
        self:SetBackground(nil)
        if w ~= nil or h ~= nil then
            self:_store_size_request(w, h)
        end
        return
    end

    self:SetVisible(true)
    self.original_w, self.original_h = _native_size(icon)
    self._real_w = self.original_w
    self._real_h = self.original_h

    -- Stretch mode 1 scales relative to the size the control has when the
    -- mode is set, so both controls must be at the native size at that moment.
    local img = self._img
    self:SetSize(self.original_w, self.original_h)
    img:SetStretchMode(0)
    img:SetBackground(icon)
    img:SetPosition(0, 0)
    img:SetSize(self.original_w, self.original_h)
    img:SetStretchMode(1)
    img:AttachEdges(EDGE_PROPORTIONAL, EDGE_PROPORTIONAL, EDGE_PROPORTIONAL, EDGE_PROPORTIONAL)

    if self:_set_size(w, h) == nil then
        self:set_alignment(self._align)
    end
end

Image.CENTER = 0x01
Image.MIDDLE = 0x02

function Image:set_alignment(align)
    self._align = align
    local parent = self:GetParent()
    if align == nil or parent == nil or self._real_w == nil or self._real_h == nil then
        -- Keep current position
        return
    end

    if _has_flag(align, Image.CENTER) then
        local pw = parent:GetWidth()
        local w = self._real_w
        self:SetLeft(math.floor((pw - w) / 2))
    end

    if _has_flag(align, Image.MIDDLE) then
        local ph = parent:GetHeight()
        local h = self._real_h
        self:SetTop(math.floor((ph - h) / 2))
    end
end
