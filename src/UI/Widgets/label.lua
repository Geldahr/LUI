import "Turbine.UI"

---@class LuiLabel : Turbine.UI.Label
LuiLabel = class(Turbine.UI.Label)

function LuiLabel:Constructor()
    Turbine.UI.Label.Constructor(self)
    self._scale = 1
end

function LuiLabel:SetFont(font)
    Turbine.UI.Label.SetFont(self, font)
    Turbine.UI.Label.SetText(self, self:GetText() or "")
end

function LuiLabel:set_scale(scale)
    if type(scale) ~= "number" then
        scale = tonumber(scale)
    end
    if scale == nil or scale <= 0 then
        scale = 1
    end
    self._scale = scale
end
