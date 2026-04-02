import "Turbine.UI"

---@class Image : Turbine.UI.Control
Image = class(Turbine.UI.Control)

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    if icon ~= nil then
        self:set_icon(icon, w, h)
    end

    if w ~= nil and h ~= nil then
        self.w = w
        self.h = h
    else
        self.w = nil
        self.h = nil
    end
end

function Image:set_icon(icon, w, h)
    if icon == nil then
        self.original_w = nil
        self.original_h = nil
        self:SetBackground(nil)
        if w ~= nil and h ~= nil then
            self:SetSize(w, h)
        end
        return
    end

    self:SetVisible(true)
    self:SetSize(0, 0)
    self:SetBackground(icon)
    self:SetStretchMode(2)
    self.original_w, self.original_h = self:GetSize()

    self:SetSize(self.original_w, self.original_h)
    self:SetStretchMode(1)

    if w ~= nil and h ~= nil then
        self.w = w
        self.h = h
        self:SetSize(w, h)
    elseif self.w ~= nil and self.h ~= nil then
        self:SetSize(self.w, self.h)
    end
end
