import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Widgets.hud"

TargetsTargetVitalsWindow = class(LuiHUD)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:Constructor(owner)
    LuiHUD.Constructor(self, {
        hud_key = "target_target_vitals",
        title = TR["Target's Target"],
    })

    self.owner = owner

    self:SetMouseVisible(false)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))

    self.targets_target_border = Turbine.UI.Control()
    self.targets_target_border:SetParent(self)
    self.targets_target_border:SetMouseVisible(false)

    self.targets_target_background = Turbine.UI.Control()
    self.targets_target_background:SetParent(self.targets_target_border)
    self.targets_target_background:SetMouseVisible(false)

    self.targets_target_morale = Turbine.UI.Control()
    self.targets_target_morale:SetParent(self.targets_target_background)
    self.targets_target_morale:SetMouseVisible(false)
    self.targets_target_morale:SetZOrder(2)

    self.targets_target_bubble = Turbine.UI.Control()
    self.targets_target_bubble:SetParent(self.targets_target_background)
    self.targets_target_bubble:SetMouseVisible(false)
    self.targets_target_bubble:SetZOrder(3)
    self.targets_target_bubble:SetVisible(false)

    self.targets_target_label = UI.Widgets.LuiLabel()
    self.targets_target_label:SetParent(self.targets_target_border)
    self.targets_target_label:SetMouseVisible(false)
    self.targets_target_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.targets_target_label:SetZOrder(50)

    self.targets_control = Turbine.UI.Lotro.EntityControl()
    self.targets_control:SetParent(self)
    self.targets_control:SetMouseVisible(true)
    self.targets_control:SetEntity(nil)
    self.targets_control:SetZOrder(4)

    self:apply_settings()
    self:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetsTargetVitalsWindow:set_move_mode(enabled)
    LuiHUD.set_move_mode(self, enabled)
    if enabled == true then
        self:SetVisible(true)
    end
end

function TargetsTargetVitalsWindow:apply_settings()
    self:apply_native_scaling()

    local v = _G.settings.target.vitals
    local tt = v.targets_target

    local border = tt.border_width
    local frame_w = tt.width
    local h = tt.height

    self:SetSize(frame_w, h)
    self:layout_move_chrome()

    self.targets_target_border:SetSize(frame_w, h)
    self.targets_target_border:SetBackColor(tt.color.border)

    local inner_w = frame_w - (2 * border)
    local inner_h = h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    self.targets_target_background:SetPosition(border, border)
    self.targets_target_background:SetSize(inner_w, inner_h)
    self.targets_target_background:SetBackColor(tt.color.background)

    self.targets_target_morale:SetPosition(0, 0)
    self.targets_target_morale:SetSize(inner_w, inner_h)

    self.targets_target_bubble:SetBackColor(tt.color.bubble)
    self.targets_target_bubble:SetTop(0)
    self.targets_target_bubble:SetHeight(inner_h)

    self.targets_target_label:SetPosition(0, 0)
    self.targets_target_label:SetSize(frame_w, h)

    self.targets_control:SetSize(frame_w, h)
    self.targets_control:SetPosition(0, 0)

    self:apply_hud_position()
end
