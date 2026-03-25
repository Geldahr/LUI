import "Turbine.UI"

---@class LuiLabel : Turbine.UI.Label
LuiLabel = class(Turbine.UI.Label)

function LuiLabel:Constructor()
    Turbine.UI.Label.Constructor(self)
end

function LuiLabel:SetFont(font)
    Turbine.UI.Label.SetFont(self, font)
    Turbine.UI.Label.SetText(self, self:GetText() or "")
end
