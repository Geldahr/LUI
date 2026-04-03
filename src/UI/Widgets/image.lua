import "Turbine.UI"

---@class Image : Turbine.UI.Control
Image = class(Turbine.UI.Control)

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

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self._requested_w = nil
    self._requested_h = nil
    self._align = nil

    if icon ~= nil then
        self:set_icon(icon, w, h)
    elseif w ~= nil then
        self:set_size(w, h)
    end
end

function Image:set_size(w, h)
    if w == nil then
        return
    end
    w = _round_size(w)
    h = _round_size(h)

    self._requested_w = w
    self._requested_h = h

    if w ~= nil and h ~= nil then
        self:SetSize(w, h)
        self:set_alignment(self._align)
        return
    end

    -- If only w is set we assume that we want to size it so it keeps
    -- the aspect ration but the image can fit in a square w x w
    if w < 0 then
        w = 0
    end

    local new_w
    local new_h
    if self.original_w > self.original_h then
        new_w = w
        new_h = w * self.original_h / self.original_w
    else
        new_h = w
        new_w = w * self.original_w / self.original_h
    end

    self:SetSize(new_w, new_h)
    self:set_alignment(self._align)
end

function Image:set_width(w)
    w = _round_size(w)
    if w == nil then
        return
    end

    self._requested_w = w
    self._requested_h = nil

    if self.original_w == nil or self.original_h == nil then
        return
    end

    if w < 0 then
        w = 0
    end

    local new_h = w * self.original_h / self.original_w

    self:SetSize(w, new_h)
    self:set_alignment(self._align)
end

function Image:set_height(h)
    h = _round_size(h)
    if h == nil then
        return
    end

    self._requested_w = nil
    self._requested_h = h

    if self.original_h == nil or self.original_w == nil then
        return
    end

    if h < 0 then
        h = 0
    end

    local new_w = h * self.original_w / self.original_h

    self:SetSize(new_w, h)
    self:set_alignment(self._align)
end

function Image:set_icon(icon, w, h)
    if icon == nil then
        self.original_w = nil
        self.original_h = nil
        self:SetBackground(nil)
        if w ~= nil then
            self:set_size(w, h)
        end
        self:set_alignment(self._align)
        return
    end

    self:SetVisible(true)
    self:SetSize(0, 0)
    self:SetBackground(icon)
    self:SetStretchMode(2)
    self.original_w, self.original_h = self:GetSize()

    self:SetSize(self.original_w, self.original_h)
    self:SetStretchMode(1)

    if w ~= nil then
        self:set_size(w, h)
    end

    self:set_alignment(self._align)
end

Image.CENTER = 0x01
Image.MIDDLE = 0x02

function Image:set_alignment(align)
    self._align = align
    if align == nil or self:GetParent() == nil then
        -- Keep current position
        return
    end

    local parent = self:GetParent()
    if parent == nil then
        self:SetPosition(0, 0)
        return
    end

    if _has_flag(align, Image.CENTER) then
        local pw = parent:GetWidth()
        local w = self:GetWidth()
        self:SetLeft(math.floor((pw - w) / 2))
    else
        self:SetLeft(0)
    end

    if _has_flag(align, Image.MIDDLE) then
        local ph = self:GetParent():GetHeight()
        local h = self:GetHeight()
        self:SetTop(math.floor((ph - h) / 2))
    else
        self:SetTop(0)
    end
end
