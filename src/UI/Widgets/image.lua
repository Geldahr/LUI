import "Turbine.UI"

---@class Image : Turbine.UI.Control
Image = class(Turbine.UI.Control)

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    -- Do not set the size before priming the image for stretch mode 1.
    self:SetBackground(icon)
    self:SetStretchMode(2)
    self.original_w, self.original_h = self:GetSize()

    self:SetSize(self.original_w, self.original_h)
    self:SetStretchMode(1)

    if w ~= nil and h ~= nil then
        self:SetSize(w, h)
    end
end
