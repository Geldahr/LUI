import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Turbine.Gameplay"

import "Geldahr.LUI.Vitals.vitals_base"
import "Geldahr.LUI.Vitals.target_effect_manager"
import "Geldahr.LUI.Vitals.targets_target_vitals_window"
import "Geldahr.LUI.Utils.color"
import "Geldahr.LUI.Settings.enums"

local function _text_alignment(value)
    return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
end

local function _target_is_player(target)
    if type(target.IsPlayer) ~= "function" then
        return false
    end
    return target:IsPlayer() == true
end

local _gradient_morale_color = lui_gradient_morale_color

---@class TargetVitals : VitalsBase
TargetVitals = class(VitalsBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function TargetVitals:Constructor(entity)
    self.tt = nil
    self.targets_events = { mmc = nil, mc = nil, mtmc = nil, tmc = nil }
    self.em = nil

    VitalsBase.Constructor(self, "target", entity, TR("Target Vitals"))

    self.entity_control:SetMouseVisible(true)
    self.entity_control.MouseDoubleClick = function(_, args)
        self:_on_entity_control_double_click(args)
    end
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function TargetVitals:set_entity(entity)
    if self.em ~= nil and self.entity ~= entity then
        self.em:delete()
        self.em = nil
    end

    VitalsBase.set_entity(self, entity)

    if entity == nil and self.em ~= nil then
        self.em:delete()
        self.em = nil
    end
end

function TargetVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end

    -- NOTE: Kind of strange it is required if target is self and you switch in and out while having a specific buff.
    if self.show_effects == true and self.effects_ending_at ~= nil and self.effects_objects ~= nil then
        local now = Turbine.Engine.GetGameTime()
        local expired = nil
        for key, ending in pairs(self.effects_ending_at) do
            if type(ending) == "number" and now >= ending then
                local eff = self.effects_objects[key]
                if eff ~= nil then
                    expired = expired or {}
                    expired[#expired + 1] = eff
                end
            end
        end
        if expired ~= nil then
            for i = 1, #expired do
                self:_remove_effect(expired[i])
            end
        end
    end

    VitalsBase.Update(self)
end

function TargetVitals:get_lower_bars_height()
    local v = self:get_vitals_settings()
    return v.power.height
end

function TargetVitals:get_empty_morale_text()
    return "No Target"
end

function TargetVitals:apply_text_alignment()
    VitalsBase.apply_text_alignment(self)
    local v = self:get_vitals_settings()

    local function apply_targets_target_alignment(label)
        if label == nil then
            return
        end
        label:SetTextAlignment(_text_alignment(v.targets_target.text_alignment))
        local w = v.targets_target.width
        local m = v.targets_target.border_width + v.targets_target.text_margin
        local a = v.targets_target.text_alignment
        if a == LUI_ENUMS.text_alignment.LEFT then
            label:SetPosition(m, 0)
            label:SetSize(w - m, label:GetHeight())
        elseif a == LUI_ENUMS.text_alignment.RIGHT then
            label:SetPosition(0, 0)
            label:SetSize(w - m, label:GetHeight())
        else
            label:SetPosition(0, 0)
            label:SetSize(w, label:GetHeight())
        end
    end

    apply_targets_target_alignment(self.targets_target_window ~= nil and self.targets_target_window.targets_target_label or
    nil)
end

function TargetVitals:apply_fonts()
    VitalsBase.apply_fonts(self)

    local v = self:get_vitals_settings()
    local font = v.targets_target.font

    local function apply_targets_target_font(label)
        if label == nil then
            return
        end
        label:SetFont(font.lotro)
        local style = LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None
        label:SetFontStyle(style)
        if style == Turbine.UI.FontStyle.Outline then
            label:SetOutlineColor(font.outline_color)
        end
        label:SetForeColor(font.color)
    end

    apply_targets_target_font(self.targets_target_window ~= nil and self.targets_target_window.targets_target_label or
    nil)
end

function TargetVitals:on_target_changed()
    self:update_targets_target()
end

function TargetVitals:set_move_mode(enabled)
    VitalsBase.set_move_mode(self, enabled)
    if is_lui_hud_visible() ~= true then
        self:SetVisible(false)
    elseif enabled == true then
        self:SetVisible(true)
    elseif self.entity == nil then
        self:SetVisible(false)
    end

    if self.targets_target_window ~= nil then
        self.targets_target_window:set_move_mode(enabled)
        if is_lui_hud_visible() ~= true or (enabled ~= true and self.tt == nil) then
            self.targets_target_window:SetVisible(false)
        end
    end
end

function TargetVitals:targets_morale_changed()
    if self.tt == nil or self.tt.GetMaxMorale == nil or self.tt.GetMorale == nil then
        return
    end

    local v = self:get_vitals_settings()
    local w = self.targets_target_widgets
    local inner_w = self.targets_target_inner_w
    local maxm = self.tt:GetMaxMorale()
    local m = self.tt:GetMorale()
    if maxm == nil then maxm = 0 end
    if m == nil then m = 0 end
    if maxm > 0 then
        local percent = m / maxm
        local fill_color = self:targets_target_morale_color(percent)
        w.morale:SetBackColor(fill_color)
        local fill_w = math.floor((inner_w * percent) + 0.5)
        if fill_w < 0 then fill_w = 0 end
        if fill_w > inner_w then fill_w = inner_w end
        w.morale:SetWidth(fill_w)
        if w.background ~= nil then
            w.background:SetBackColor(self:targets_target_background_color(fill_color))
        end
        w.label:SetText(self:get_targets_target_text())
    else
        w.morale:SetWidth(inner_w)
        w.morale:SetBackColor(v.targets_target.color.neutral)
        if w.background ~= nil then
            w.background:SetBackColor(self:targets_target_background_color(v.targets_target.color.neutral))
        end
        w.label:SetText(self:get_targets_target_text())
    end

    self:targets_bubble_changed()
end

function TargetVitals:targets_bubble_changed()
    local w = self.targets_target_widgets
    if w == nil or w.bubble == nil then
        return
    end
    if self.tt == nil or self.tt.GetMaxMorale == nil or self.tt.GetTemporaryMorale == nil then
        w.bubble:SetVisible(false)
        w.label:SetText(self:get_targets_target_text())
        return
    end

    local v = self:get_vitals_settings()
    local inner_w = self.targets_target_inner_w
    local maxm = self.tt:GetMaxMorale() or 0
    if maxm <= 0 then
        w.bubble:SetVisible(false)
        w.label:SetText(self:get_targets_target_text())
        return
    end

    local b = self.tt:GetTemporaryMorale() or 0
    if b <= 0 then
        w.bubble:SetVisible(false)
        w.label:SetText(self:get_targets_target_text())
        return
    end

    local bubble_w = math.floor(((b / maxm) * inner_w) + 0.5)
    if bubble_w <= 0 then
        w.bubble:SetVisible(false)
        w.label:SetText(self:get_targets_target_text())
        return
    end
    if bubble_w > inner_w then bubble_w = inner_w end

    local morale_w = 0
    if w.morale ~= nil and w.morale.GetWidth ~= nil then
        morale_w = w.morale:GetWidth() or 0
    end
    if morale_w < 0 then morale_w = 0 end
    if morale_w > inner_w then morale_w = inner_w end
    morale_w = math.floor(morale_w + 0.5)

    local max_left = inner_w - bubble_w
    if max_left < 0 then max_left = 0 end

    local left_inner = morale_w
    if left_inner > max_left then
        left_inner = max_left
    end

    w.bubble:SetTop(0)
    w.bubble:SetHeight(w.morale:GetHeight())
    w.bubble:SetLeft(left_inner)
    w.bubble:SetWidth(bubble_w)
    w.bubble:SetBackColor(v.targets_target.color.bubble)
    w.bubble:SetVisible(true)

    w.label:SetText(self:get_targets_target_text())
end

function TargetVitals:targets_target_morale_color(percent)
    local c = self:get_vitals_settings().targets_target.color
    if c.gradient == true then
        return _gradient_morale_color(percent, c.gradient_full or c.high, c.gradient_mid or c.medium,
            c.gradient_low or c.critical)
    end
    if percent > 0.75 then
        return c.high
    elseif percent > 0.5 then
        return c.medium
    elseif percent > 0.25 then
        return c.low
    end
    return c.critical
end

function TargetVitals:targets_target_background_color(fill_color)
    local tt = self:get_vitals_settings().targets_target
    if tt.background_matches_missing == true then
        return self:dimmed_color(fill_color, tt.background_dimming)
    end
    return tt.color.background
end

function TargetVitals:get_targets_target_text()
    local v = self:get_vitals_settings()
    local fmt = v.targets_target.text_tokens
    local bubble_fmt = v.targets_target.bubble_tokens

    local name = ""
    local level = ""
    if self.tt ~= nil then
        if self.tt.GetName ~= nil then
            name = self.tt:GetName() or ""
        end
        if self.tt.GetLevel ~= nil then
            level = tostring(self.tt:GetLevel() or "")
        end
    end

    local maxm = (self.tt ~= nil and self.tt.GetMaxMorale ~= nil) and (self.tt:GetMaxMorale() or 0) or 0
    local m = (self.tt ~= nil and self.tt.GetMorale ~= nil) and (self.tt:GetMorale() or 0) or 0
    if maxm < 0 then maxm = 0 end
    if m < 0 then m = 0 end

    local percent_text = ""
    if maxm > 0 then
        local pct = math.floor(((m / maxm) * 100) + 0.5)
        if pct < 0 then pct = 0 end
        if pct > 100 then pct = 100 end
        percent_text = tostring(pct) .. "%"
    end

    local bubble = (self.tt ~= nil and self.tt.GetTemporaryMorale ~= nil) and (self.tt:GetTemporaryMorale() or 0) or 0
    if bubble < 0 then bubble = 0 end

    local bubble_text = ""
    if bubble > 0 then
        bubble_text = lui_abbrev_number(bubble)
    end

    local ctx = {
        c = lui_abbrev_number(m),
        t = lui_abbrev_number(maxm),
        p = percent_text,
        b = bubble_text,
        B = "",
        name = name,
        level = level,
    }

    if bubble > 0 and #bubble_fmt > 0 then
        ctx.B = lui_format_tokenized(bubble_fmt, { b = ctx.b })
    end

    return lui_format_tokenized(fmt, ctx)
end

function TargetVitals:update_targets_target()
    if self.tt ~= nil then
        remove_callback(self.tt, "MaxMoraleChanged", self.targets_events.mmc)
        self.targets_events.mmc = nil
        remove_callback(self.tt, "MoraleChanged", self.targets_events.mc)
        self.targets_events.mc = nil
        remove_callback(self.tt, "MaxTemporaryMoraleChanged", self.targets_events.mtmc)
        self.targets_events.mtmc = nil
        remove_callback(self.tt, "TemporaryMoraleChanged", self.targets_events.tmc)
        self.targets_events.tmc = nil
    end

    self.tt = nil

    local w = self.targets_target_widgets

    if self.entity ~= nil and self.entity.GetTarget ~= nil and self.entity:GetTarget() ~= nil then
        self.tt = self.entity:GetTarget()
        if w ~= nil and w.set_entity ~= nil then
            w.set_entity(self.tt)
        end
        if w ~= nil and w.label ~= nil then
            w.label:SetText(self:get_targets_target_text())
        end
        if w ~= nil and w.set_visible ~= nil then
            w.set_visible(true)
        end

        self.targets_events.mmc = add_callback(self.tt, "MaxMoraleChanged", function() self:targets_morale_changed() end)
        self.targets_events.mc = add_callback(self.tt, "MoraleChanged", function() self:targets_morale_changed() end)
        self.targets_events.mtmc = add_callback(self.tt, "MaxTemporaryMoraleChanged",
            function() self:targets_bubble_changed() end)
        self.targets_events.tmc = add_callback(self.tt, "TemporaryMoraleChanged",
            function() self:targets_bubble_changed() end)

        self:targets_morale_changed()
        self:targets_bubble_changed()
    else
        if w ~= nil and w.set_entity ~= nil then
            w.set_entity(self.tt)
        end
        if w ~= nil and w.set_visible ~= nil then
            w.set_visible(false)
        end
        if w ~= nil and w.bubble ~= nil then
            w.bubble:SetVisible(false)
        end
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function TargetVitals:_setup_effect_tracking()
    if self.show_effects ~= true then
        return
    end

    if self.em ~= nil then
        self.em:delete()
        self.em = nil
    end

    if self.debuffs ~= nil then self.debuffs:clear_effects() end
    if self.buffs ~= nil then self.buffs:clear_effects() end

    self.effects_list = nil
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}

    if self.entity == nil or self.entity.GetEffects == nil then
        self:SetWantsUpdates(false)
        return
    end

    if self.entity:GetEffects() == nil then
        self:SetWantsUpdates(false)
        return
    end

    self.em = TargetEffectManager(Turbine.Gameplay.LocalPlayer.GetInstance())
    self.em:register_added_event(function(effect)
        self:_upsert_effect(effect)
        -- self:_request_effects_resync(0.05, 6)
    end)
    self.em.removed_event = function(effect)
        self:_remove_effect(effect)
        self:_request_effects_resync(0.05, 6)
    end

    self:SetWantsUpdates(true)
end

function TargetVitals:_build_extra_controls()
    local v = self:get_vitals_settings()
    local bw = v.targets_target.border_width
    local inner_w = v.targets_target.width - (2 * bw)
    if inner_w < 1 then inner_w = 1 end

    self.targets_target_window = TargetsTargetVitalsWindow(self)
    self.targets_target_inner_w = inner_w
    self.targets_target_widgets = {
        frame = self.targets_target_window,
        background = self.targets_target_window.targets_target_background,
        morale = self.targets_target_window.targets_target_morale,
        bubble = self.targets_target_window.targets_target_bubble,
        label = self.targets_target_window.targets_target_label,
        control = self.targets_target_window.targets_control,
        set_visible = function(visible)
            self.targets_target_window:SetVisible(
                is_lui_hud_visible() == true and
                (visible == true or self.targets_target_window:is_move_mode())
            )
        end,
        set_entity = function(entity)
            self.targets_target_window.targets_control:SetEntity(entity)
        end,
    }
end

function TargetVitals:_on_entity_control_double_click(args)
    if args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end
    if self.entity == nil or _target_is_player(self.entity) == true then
        return
    end

    BESTIARY_CARD:toggle_for_target(self.entity, self)
end

function TargetVitals:_resize_extra_controls()
    local v = self:get_vitals_settings()
    local bw = v.targets_target.border_width
    local inner_w = v.targets_target.width - (2 * bw)
    if inner_w < 1 then inner_w = 1 end
    self.targets_target_inner_w = inner_w

    if self.targets_target_window ~= nil and self.targets_target_window.apply_settings ~= nil then
        self.targets_target_window:apply_settings()
    end

    self:apply_fonts()
    self:apply_text_alignment()
    self:update_targets_target()
end
