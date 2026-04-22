import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Vitals.effect_icon"
import "LUI.src.Vitals.buff_area"
import "LUI.src.Vitals.debuff_area"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Utils.color"
import "LUI.src.Utils.token_format"
import "LUI.src.Settings.enums"

local function _effect_is_debuff(effect)
    return (effect.IsDebuff ~= nil and effect:IsDebuff()) == true
end

local function _effect_key(effect)
    if effect == nil then
        return 0
    end
    return effect:GetID()
end

local function _effect_ending(effect, now, fallback_start)
    if effect == nil then
        return nil
    end

    local duration = (effect.GetDuration ~= nil and effect:GetDuration()) or 0
    if type(duration) ~= "number" then duration = tonumber(duration) or 0 end
    if duration <= 0 or duration >= 9999 then
        return nil
    end

    local start = (effect.GetStartTime ~= nil and effect:GetStartTime()) or nil
    if type(start) ~= "number" then start = tonumber(start) end

    local t = now
    if type(t) ~= "number" then t = 0 end

    -- Target effect start times can be invalid (often 0), which makes effects look immediately expired.
    -- If the start time looks suspicious, fall back to the last time we saw the effect in the list.
    if start == nil or start <= 0 or (t > 0 and (start > (t + 5) or start < (t - 7200))) then
        start = fallback_start
        if type(start) ~= "number" then
            start = now
        end
    end

    return start + duration
end

local function _text_alignment(value)
    return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
end

local function _apply_label_margin(label, frame_width, margin, alignment)
    local m = margin or 0
    if m < 0 then m = 0 end

    if alignment == LUI_ENUMS.text_alignment.LEFT then
        label:SetPosition(m, 0)
        label:SetSize(frame_width - m, label:GetHeight())
    elseif alignment == LUI_ENUMS.text_alignment.RIGHT then
        label:SetPosition(0, 0)
        label:SetSize(frame_width - m, label:GetHeight())
    else
        label:SetPosition(0, 0)
        label:SetSize(frame_width, label:GetHeight())
    end
end

local _dim_color = lui_dim_color
local _gradient_morale_color = lui_gradient_morale_color
local HUD_KEY_BY_VITAL = {
    self = "self_vitals",
    target = "target_vitals",
    boss = "boss_vitals",
    party = "party_vitals",
}

---@class VitalsBase : LuiHUD
VitalsBase = class(LuiHUD)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function VitalsBase:Constructor(vital_key, entity, title, opts)
    if type(opts) ~= "table" then
        opts = {}
    end

    local hud_key = opts.hud_key or HUD_KEY_BY_VITAL[vital_key]
    LuiHUD.Constructor(self, {
        hud_key = hud_key,
        title = title,
    })

    self.vital_key = vital_key
    self.entity = entity
    self.show_effects = opts.show_effects ~= false
    self.show_moveable = opts.show_moveable ~= false
    self.managed_position = opts.managed_position == true
    self.hud_key = hud_key

    self.events = {
        mmc = nil,
        mc = nil,
        tc = nil,
        mtmc = nil,
        tmc = nil,
        icc = nil,
        wc = nil,
        pc = nil,
        mpc = nil,
        ea = nil,
        er = nil,
        ec = nil,
    }

    self.effects_list = nil
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}

    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width

    local effects_height = self:get_effects_height()
    local lower_bars_height = self:get_lower_bars_height()

    self.width = frame_width - (2 * frame.border_width)
    if self.width < 1 then self.width = 1 end
    self.bubble_width = 1000

    local total_h = effects_height + v.morale.height + lower_bars_height - frame.border_width
    if total_h < 1 then total_h = 1 end
    self:SetSize(frame_width, total_h)
    self:layout_move_chrome()
    self:SetMouseVisible(false)
    if self.managed_position then
        self:SetPosition(0, 0)
    else
        self:apply_hud_position()
    end

    -- self:SetBackColor(Turbine.UI.Color(0.9, 0.3, 0.3))

    ---------------------------------------------------------------------
    -- MORALE
    ---------------------------------------------------------------------
    local effects_above = self.show_effects == true and frame.effects_position ~= LUI_ENUMS.vitals_effects_position
        .BELOW
    local morale_top = effects_above and effects_height or 0

    self.morale_frame = Turbine.UI.Control()
    self.morale_frame:SetParent(self)
    self.morale_frame:SetSize(frame_width, v.morale.height)
    self.morale_frame:SetTop(morale_top)
    self.morale_frame:SetMouseVisible(false)
    self.morale_frame:SetZOrder(2)

    local bw = frame.border_width
    local inner_w = frame_width - (2 * bw)
    local morale_inner_h = v.morale.height - (2 * bw)
    if inner_w < 1 then inner_w = 1 end
    if morale_inner_h < 1 then morale_inner_h = 1 end

    self.morale_border = Turbine.UI.Control()
    self.morale_border:SetParent(self.morale_frame)
    self.morale_border:SetPosition(0, 0)
    self.morale_border:SetSize(frame_width, v.morale.height)
    self.morale_border:SetBackColor(frame.border_color)
    self.morale_border:SetMouseVisible(false)
    self.morale_border:SetZOrder(1)

    self.morale_background = Turbine.UI.Control()
    self.morale_background:SetParent(self.morale_border)
    self.morale_background:SetPosition(bw, bw)
    self.morale_background:SetSize(inner_w, morale_inner_h)
    self.morale_background:SetBackColor(v.morale.color.background)
    self.morale_background:SetMouseVisible(false)
    self.morale_background:SetZOrder(2)

    self.morale_bar = Turbine.UI.Control()
    self.morale_bar:SetParent(self.morale_background)
    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetSize(self.morale_background:GetSize())
    self.morale_bar:SetMouseVisible(false)
    self.morale_bar:SetZOrder(2)

    self.bubble_bar = Turbine.UI.Control()
    self.bubble_bar:SetParent(self.morale_background)
    self.bubble_bar:SetHeight(self.morale_background:GetHeight())
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetWidth(0)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)
    self.bubble_bar:SetMouseVisible(false)
    self.bubble_bar:SetZOrder(3)

    ---------------------------------------------------------------------
    -- POWER (WRATH)
    ---------------------------------------------------------------------
    self.power_frame = Turbine.UI.Control()
    self.power_frame:SetParent(self)
    self.power_frame:SetTop(self.morale_frame:GetTop() + self.morale_frame:GetHeight() - frame.border_width)
    self.power_frame:SetSize(frame_width, v.power.height)
    self.power_frame:SetMouseVisible(false)
    self.power_frame:SetZOrder(3)

    local power_inner_h = v.power.height - (2 * bw)
    if power_inner_h < 1 then power_inner_h = 1 end

    self.power_border = Turbine.UI.Control()
    self.power_border:SetParent(self.power_frame)
    self.power_border:SetPosition(0, 0)
    self.power_border:SetSize(frame_width, v.power.height)
    self.power_border:SetBackColor(frame.border_color)
    self.power_border:SetMouseVisible(false)
    self.power_border:SetZOrder(1)

    self.power_background = Turbine.UI.Control()
    self.power_background:SetParent(self.power_border)
    self.power_background:SetPosition(bw, bw)
    self.power_background:SetSize(inner_w, power_inner_h)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
    self.power_background:SetMouseVisible(false)

    self.power_bar = Turbine.UI.Control()
    self.power_bar:SetParent(self.power_background)
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetSize(self.power_background:GetSize())
    self.power_bar:SetMouseVisible(false)

    ---------------------------------------------------------------------
    -- LABELS
    ---------------------------------------------------------------------
    self.morale_label = UI.Widgets.LuiLabel()
    self.morale_label:SetParent(self.morale_frame)
    self.morale_label:SetSize(self.morale_frame:GetSize())
    self.morale_label:SetPosition(0, 0)
    self.morale_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.morale_label:SetZOrder(50)

    self.power_label = UI.Widgets.LuiLabel()
    self.power_label:SetParent(self.power_frame)
    self.power_label:SetSize(self.power_frame:GetSize())
    self.power_label:SetPosition(0, 0)
    self.power_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.power_label:SetZOrder(50)

    ---------------------------------------------------------------------
    -- Entity control (clickable player frame)
    ---------------------------------------------------------------------
    self.entity_control = Turbine.UI.Lotro.EntityControl()
    self.entity_control:SetParent(self)
    self.entity_control:SetSize(
        math.max(self.morale_frame:GetWidth(), self.power_frame:GetWidth()),
        self.morale_frame:GetHeight() + self.power_frame:GetHeight()
    )
    self.entity_control:SetPosition(self.morale_frame:GetPosition())
    self.entity_control:SetEntity(self.entity)
    self.entity_control:SetZOrder(4)

    ---------------------------------------------------------------------
    -- Effect windows
    ---------------------------------------------------------------------
    if self.show_effects then
        local DebuffAreaClass = DebuffArea
        local BuffAreaClass = BuffArea

        if DebuffAreaClass ~= nil and BuffAreaClass ~= nil then
            self.debuffs = DebuffAreaClass(frame_width, v.effects, frame.effects_height)
            self.debuffs:SetParent(self)

            self.buffs = BuffAreaClass(frame_width, v.effects, frame.effects_height)
            self.buffs:SetParent(self)
            self.buffs.on_height_changed = function()
                self:_layout_effect_windows()
            end
            self:_layout_effect_windows()
        else
            self.debuffs = nil
            self.buffs = nil
        end
    else
        self.debuffs = nil
        self.buffs = nil
    end

    ---------------------------------------------------------------------
    -- Subclass-specific controls
    ---------------------------------------------------------------------
    self:_build_extra_controls()

    self.morale_label:SetVisible(true)
    self.power_label:SetVisible(true)
    self.morale_frame:SetVisible(true)
    self.power_frame:SetVisible(true)
    if is_lui_hud_visible() ~= true then
        self:SetVisible(false)
    elseif self.vital_key == "target" and entity == nil then
        self:SetVisible(false)
    else
        self:SetVisible(true)
    end

    self:apply_fonts()
    self:apply_text_alignment()
    self:set_entity(entity)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function VitalsBase:get_vitals_settings()
    local k = self.vital_key
    if k == "self" or k == "target" then
        return _G.settings[k].vitals
    end
    return _G.settings[k]
end

function VitalsBase:get_loaded_vitals_settings()
    local k = self.vital_key
    if k == "self" or k == "target" then
        return _G.loaded_settings[k].vitals
    end
    return _G.loaded_settings[k]
end

function VitalsBase:get_hud_settings()
    return _G.settings.ui.hud[self.hud_key]
end

function VitalsBase:get_loaded_hud_settings()
    return _G.get_ui_hud_state(self.hud_key)
end

function VitalsBase:morale_color(percent)
    local c = self:get_vitals_settings().morale.color
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
    else
        return c.critical
    end
end

function VitalsBase:dimmed_color(color, dimming)
    return _dim_color(color, dimming)
end

function VitalsBase:resource_background_color(fill_color, static_color)
    local v = self:get_vitals_settings()
    if v.background_matches_missing == true then
        return self:dimmed_color(fill_color, v.background_dimming)
    end
    return static_color
end

function VitalsBase:morale_background_color(fill_color)
    return self:resource_background_color(fill_color, self:get_vitals_settings().morale.color.background)
end

function VitalsBase:power_background_color(fill_color)
    return self:resource_background_color(fill_color, self:get_vitals_settings().morale.color.background)
end

function VitalsBase:Update()
    local due = self.effects_resync_due_at
    if type(due) ~= "number" then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if now < due then
        return
    end

    self:_sync_effects_from_list(now)

    local attempts = self.effects_resync_attempts
    if type(attempts) ~= "number" then attempts = 0 end
    attempts = attempts - 1
    self.effects_resync_attempts = attempts

    if attempts > 0 then
        self.effects_resync_due_at = now + 0.10
    else
        self.effects_resync_due_at = nil
        self:SetWantsUpdates(false)
    end
end

function VitalsBase:get_effects_height()
    if self.show_effects ~= true then
        return 0
    end
    return self:get_vitals_settings().frame.effects_height
end

function VitalsBase:effects_are_below()
    return self:get_vitals_settings().frame.effects_position == LUI_ENUMS.vitals_effects_position.BELOW
end

function VitalsBase:get_lower_bars_height()
    local v = self:get_vitals_settings()
    return v.power.height
end

function VitalsBase:get_empty_morale_text()
    return ""
end

function VitalsBase:apply_fonts()
    local v = self:get_vitals_settings()
    local morale_font = v.morale.font
    self.morale_label:SetFont(morale_font.lotro)
    local morale_style = LUI_TO_LOTRO.font_style[morale_font.style] or Turbine.UI.FontStyle.None
    self.morale_label:SetFontStyle(morale_style)
    if morale_style == Turbine.UI.FontStyle.Outline then
        self.morale_label:SetOutlineColor(morale_font.outline_color)
    end
    self.morale_label:SetForeColor(morale_font.color)

    local power_font = v.power.font
    self.power_label:SetFont(power_font.lotro)
    local power_style = LUI_TO_LOTRO.font_style[power_font.style] or Turbine.UI.FontStyle.None
    self.power_label:SetFontStyle(power_style)
    if power_style == Turbine.UI.FontStyle.Outline then
        self.power_label:SetOutlineColor(power_font.outline_color)
    end
    self.power_label:SetForeColor(power_font.color)
end

function VitalsBase:apply_text_alignment()
    local v = self:get_vitals_settings()
    self.morale_label:SetTextAlignment(_text_alignment(v.morale.text_alignment))
    self.power_label:SetTextAlignment(_text_alignment(v.power.text_alignment))

    local frame_width = v.frame.width
    local bw = v.frame.border_width
    _apply_label_margin(self.morale_label, frame_width, bw + v.morale.text_margin, v.morale.text_alignment)
    _apply_label_margin(self.power_label, frame_width, bw + v.power.text_margin, v.power.text_alignment)
end

function VitalsBase:is_move_mode()
    return self.show_moveable == true and LuiHUD.is_move_mode(self)
end

function VitalsBase:set_move_mode(enabled)
    if self.show_moveable ~= true then
        return
    end
    LuiHUD.set_move_mode(self, enabled)
end

function VitalsBase:persist_position(x, y)
    if self.managed_position then
        return
    end
    LuiHUD.persist_position(self, x, y)
end

function VitalsBase:on_target_changed()
end

function VitalsBase:self_combat_changed()
    local frame = self:get_vitals_settings().frame

    if self.entity ~= nil and self.entity.IsInCombat ~= nil and self.entity:IsInCombat() then
        self:SetOpacity(frame.incombat_opacity)
    else
        self:SetOpacity(frame.outcombat_opacity)
    end
end

function VitalsBase:self_bubble_changed()
    if self.entity == nil or self.entity.GetMaxMorale == nil or self.entity.GetMaxTemporaryMorale == nil then
        return
    end
    local frame = self:get_vitals_settings().frame
    local b = self.entity:GetTemporaryMorale() or 0

    if b <= 0 then
        self.bubble_bar:SetVisible(false)
        return
    end

    local maxm = self.entity:GetMaxMorale() or 0
    if maxm <= 0 then
        self.bubble_bar:SetVisible(false)
        return
    end

    local bubble_w = math.floor(((b / maxm) * self.width) + 0.5)
    if bubble_w <= 0 then
        self.bubble_bar:SetVisible(false)
        return
    end
    if bubble_w > self.width then bubble_w = self.width end

    local morale_w = 0
    if self.morale_bar ~= nil and self.morale_bar.GetWidth ~= nil then
        morale_w = self.morale_bar:GetWidth() or 0
    end
    if morale_w < 0 then morale_w = 0 end
    if morale_w > self.width then morale_w = self.width end
    morale_w = math.floor(morale_w + 0.5)

    local max_left = self.width - bubble_w
    if max_left < 0 then max_left = 0 end

    -- Attach bubble to the right of the current morale fill if it fits,
    -- otherwise keep it right-aligned within the bar (overlapping morale).
    local left_inner = morale_w
    if left_inner > max_left then
        left_inner = max_left
    end

    self.bubble_bar:SetTop(0)
    self.bubble_bar:SetHeight(self.morale_bar:GetHeight())
    self.bubble_bar:SetLeft(left_inner)
    self.bubble_bar:SetWidth(bubble_w)
    self.bubble_bar:SetVisible(true)
end

function VitalsBase:self_morale_changed()
    if self.entity == nil or self.entity.GetMaxMorale == nil or self.entity.GetMorale == nil then
        return
    end

    local v = self:get_vitals_settings()
    local maxm = self.entity:GetMaxMorale()
    local m = self.entity:GetMorale()
    if maxm == nil then maxm = 0 end
    if m == nil then m = 0 end

    if maxm > 0 then
        self._no_morale = false
        local percent = m / maxm
        local pct = math.floor((percent * 100) + 0.5)

        local fmt = v.morale.string_tokens
        local bubble_fmt = v.morale.bubble_tokens

        local level = ""
        if self.entity.GetLevel ~= nil then
            level = tostring(self.entity:GetLevel() or "")
        end

        local bubble = 0
        if self.entity.GetTemporaryMorale ~= nil then
            bubble = self.entity:GetTemporaryMorale() or 0
        end
        local bubble_text = ""
        if bubble > 0 then
            bubble_text = lui_abbrev_number(bubble)
        end

        local ctx = {
            c = lui_abbrev_number(m),
            t = lui_abbrev_number(maxm),
            p = tostring(pct) .. "%",
            b = bubble_text,
            B = "",
            name = self.entity:GetName(),
            level = level,
        }

        if bubble > 0 and #bubble_fmt > 0 then
            ctx.B = lui_format_tokenized(bubble_fmt, { b = ctx.b })
        end

        self.morale_label:SetText(lui_format_tokenized(fmt, ctx))

        local fill_color = self:morale_color(percent)
        self.morale_bar:SetBackColor(fill_color)
        local fill_w = math.floor((self.width * percent) + 0.5)
        if fill_w < 0 then fill_w = 0 end
        if fill_w > self.width then fill_w = self.width end
        self.morale_bar:SetWidth(fill_w)
        self.morale_background:SetBackColor(self:morale_background_color(fill_color))
        self:self_bubble_changed()
    else
        self._no_morale = true
        local name = ""
        if self.entity.GetName ~= nil then
            name = tostring(self.entity:GetName() or "")
        end
        self.morale_label:SetText(name)
        self.morale_bar:SetWidth(self.width)
        self.morale_bar:SetBackColor(v.morale.color.neutral)
        self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))
        if self.bubble_bar ~= nil then
            self.bubble_bar:SetVisible(false)
        end
        if self.power_border ~= nil then
            self.power_border:SetVisible(false)
        end
        if self.power_label ~= nil then
            self.power_label:SetText("")
        end
    end
end

function VitalsBase:self_power_changed()
    if self.entity == nil or self.entity.GetMaxPower == nil or self.entity.GetPower == nil then
        return
    end
    if self._no_morale == true then
        if self.power_border ~= nil then
            self.power_border:SetVisible(false)
        end
        if self.power_label ~= nil then
            self.power_label:SetText("")
        end
        if self.power_bar ~= nil then
            self.power_bar:SetWidth(0)
        end
        return
    end
    local v = self:get_vitals_settings()
    local maxp = self.entity:GetMaxPower()
    local p = self.entity:GetPower()
    if maxp == nil then maxp = 0 end
    if p == nil then p = 0 end
    local is_wrath = false
    if self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning then
        is_wrath = true
    end

    if maxp > 0 then
        if self.power_border ~= nil then
            self.power_border:SetVisible(true)
        end
        local percent = p / maxp
        local pct = math.floor((percent * 100) + 0.5)
        local fmt = v.power.string_tokens
        local fmt_text = v.power.string_format

        if string.len((fmt_text:gsub("%s+", ""))) == 0 then
            self.power_label:SetText("")
        else
            local level = ""
            if self.entity.GetLevel ~= nil then
                level = tostring(self.entity:GetLevel() or "")
            end

            self.power_label:SetText(lui_format_tokenized(fmt, {
                c = lui_abbrev_number(p),
                t = lui_abbrev_number(maxp),
                p = tostring(pct) .. "%",
                name = self.entity:GetName(),
                level = level,
            }))
        end
        self.power_bar:SetWidth(self.width * percent)
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    else
        if self.power_border ~= nil then
            self.power_border:SetVisible(true)
        end
        self.power_label:SetText("")
        self.power_bar:SetWidth(self.width)
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    end
end

function VitalsBase:self_wrath_changed()
    if self.entity == nil or self.entity.GetClassAttributes == nil or self.entity:GetClassAttributes().GetWrath == nil then
        return
    end
    local v = self:get_vitals_settings()
    local maxw = 100
    local w = self.entity:GetClassAttributes():GetWrath()

    local percent = w / maxw
    local pct = math.floor((percent * 100) + 0.5)
    local fmt = v.power.string_tokens
    local fmt_text = v.power.string_format

    if string.len((fmt_text:gsub("%s+", ""))) == 0 then
        self.power_label:SetText("")
    else
        local level = ""
        if self.entity.GetLevel ~= nil then
            level = tostring(self.entity:GetLevel() or "")
        end

        self.power_label:SetText(lui_format_tokenized(fmt, {
            c = lui_abbrev_number(w),
            t = lui_abbrev_number(maxw),
            p = tostring(pct) .. "%",
            name = self.entity:GetName(),
            level = level,
        }))
    end
    self.power_bar:SetWidth(self.width * percent)
    self.power_bar:SetBackColor(v.power.color.wrath)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.wrath))
end

function VitalsBase:update()
    self:on_target_changed()
    self:self_morale_changed()
    self:self_bubble_changed()
    self:self_combat_changed()

    if self.entity ~= nil and self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning then
        if self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil and self.entity:GetClassAttributes().GetWrath ~= nil then
            self:self_wrath_changed()
        else
            self:self_power_changed()
        end
    else
        self:self_power_changed()
    end
end

function VitalsBase:set_entity(entity)
    -- Avoid redundant churn, but don't skip the initial binding during construction.
    if self.entity == entity and self.events ~= nil and self.events.mmc ~= nil then
        return
    end

    if self.entity ~= nil and self.entity ~= entity then
        remove_callback(self.entity, "MaxMoraleChanged", self.events.mmc)
        self.events.mmc = nil
        remove_callback(self.entity, "MoraleChanged", self.events.mc)
        self.events.mc = nil
        remove_callback(self.entity, "TargetChanged", self.events.tc)
        self.events.tc = nil
        remove_callback(self.entity, "MaxTemporaryMoraleChanged", self.events.mtmc)
        self.events.mtmc = nil
        remove_callback(self.entity, "TemporaryMoraleChanged", self.events.tmc)
        self.events.tmc = nil
        remove_callback(self.entity, "InCombatChanged", self.events.icc)
        self.events.icc = nil

        if self.events.wc ~= nil and self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil then
            remove_callback(self.entity:GetClassAttributes(), "WrathChanged", self.events.wc)
            self.events.wc = nil
        end

        remove_callback(self.entity, "MaxPowerChanged", self.events.mpc)
        self.events.mpc = nil
        remove_callback(self.entity, "PowerChanged", self.events.pc)
        self.events.pc = nil
    end

    self:_clear_effect_callbacks()

    self.entity = entity
    self.entity_control:SetEntity(self.entity)

    if self.entity == nil then
        local v = self:get_vitals_settings()

        self.power_border:SetVisible(true)
        self.bubble_bar:SetVisible(false)

        self.morale_label:SetText(self:get_empty_morale_text())
        self.power_label:SetText("")

        self.morale_bar:SetWidth(self.width)
        self.morale_bar:SetBackColor(v.morale.color.neutral)
        self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))

        self.power_bar:SetWidth(self.width)
        self.power_bar:SetBackColor(v.power.color.power)
        self.power_background:SetBackColor(self:power_background_color(v.power.color.power))

        if self.show_effects then
            if self.buffs ~= nil then self.buffs:clear_effects() end
            if self.debuffs ~= nil then self.debuffs:clear_effects() end
            self:_layout_effect_windows()
        end

        self:_reset_effect_state()

        self:on_target_changed()

        return
    end

    if self.entity ~= nil and self.entity.GetMaxMorale == nil then
        self.morale_bar:SetWidth(0)
        self.power_bar:SetWidth(0)
        self.bubble_bar:SetWidth(0)
        self.morale_label:SetText(self.entity:GetName())
        self.power_label:SetText("")
        self.power_border:SetVisible(false)

        if self.show_effects then
            if self.buffs ~= nil then self.buffs:clear_effects() end
            if self.debuffs ~= nil then self.debuffs:clear_effects() end
            self:_layout_effect_windows()
        end

        self:_reset_effect_state()

        self:on_target_changed()
        return
    end

    self.power_border:SetVisible(true)

    self.events.mmc = add_callback(self.entity, "MaxMoraleChanged", function() self:self_morale_changed() end)
    self.events.mc = add_callback(self.entity, "MoraleChanged", function() self:self_morale_changed() end)
    self.events.tc = add_callback(self.entity, "TargetChanged", function() self:on_target_changed() end)
    self.events.mtmc = add_callback(self.entity, "MaxTemporaryMoraleChanged", function() self:self_bubble_changed() end)
    self.events.tmc = add_callback(self.entity, "TemporaryMoraleChanged", function() self:self_bubble_changed() end)
    self.events.icc = add_callback(self.entity, "InCombatChanged", function() self:self_combat_changed() end)

    if self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning and self.entity.GetClassAttributes ~= nil and self.entity:GetClassAttributes() ~= nil and self.entity:GetClassAttributes().GetWrath ~= nil then
        self.events.wc = add_callback(self.entity:GetClassAttributes(), "WrathChanged",
            function() self:self_wrath_changed() end)
    else
        self.events.mpc = add_callback(self.entity, "MaxPowerChanged", function() self:self_power_changed() end)
        self.events.pc = add_callback(self.entity, "PowerChanged", function() self:self_power_changed() end)
    end

    if self.show_effects then
        self:_setup_effect_tracking()
    end

    self:update()
end

function VitalsBase:resize()
    self:apply_native_scaling()

    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width
    local effects_height = self:get_effects_height()
    local lower_bars_height = self:get_lower_bars_height()

    self.width = frame_width - (2 * frame.border_width)
    if self.width < 1 then self.width = 1 end

    local total_h = effects_height + v.morale.height + lower_bars_height - frame.border_width
    if total_h < 1 then total_h = 1 end
    self:SetSize(frame_width, total_h)
    self:layout_move_chrome()
    if not self.managed_position then
        self:apply_hud_position()
    end

    self.morale_frame:SetSize(frame_width, v.morale.height)
    local effects_above = self.show_effects == true and frame.effects_position ~= LUI_ENUMS.vitals_effects_position
        .BELOW
    local morale_top = effects_above and effects_height or 0
    self.morale_frame:SetTop(morale_top)

    local bw = frame.border_width
    local inner_w = frame_width - (2 * bw)
    local morale_inner_h = v.morale.height - (2 * bw)
    local power_inner_h = v.power.height - (2 * bw)
    if inner_w < 1 then inner_w = 1 end
    if morale_inner_h < 1 then morale_inner_h = 1 end
    if power_inner_h < 1 then power_inner_h = 1 end

    self.morale_border:SetSize(frame_width, v.morale.height)
    self.morale_border:SetBackColor(frame.border_color)

    self.morale_background:SetPosition(bw, bw)
    self.morale_background:SetSize(inner_w, morale_inner_h)
    self.morale_background:SetBackColor(v.morale.color.background)

    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetSize(inner_w, morale_inner_h)

    self.bubble_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)
    self.bubble_bar:SetZOrder(3)

    self.power_frame:SetTop(self.morale_frame:GetTop() + self.morale_frame:GetHeight() - frame.border_width)
    self.power_frame:SetSize(frame_width, v.power.height)

    self.power_border:SetSize(frame_width, v.power.height)
    self.power_border:SetBackColor(frame.border_color)

    self.power_background:SetPosition(bw, bw)
    self.power_background:SetSize(inner_w, power_inner_h)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetSize(inner_w, power_inner_h)

    self.morale_label:SetSize(self.morale_frame:GetSize())
    self.power_label:SetSize(self.power_frame:GetSize())
    self:apply_fonts()
    self:apply_text_alignment()

    self.entity_control:SetSize(
        math.max(self.morale_frame:GetWidth(), self.power_frame:GetWidth()),
        self.morale_frame:GetHeight() + self.power_frame:GetHeight()
    )
    self.entity_control:SetPosition(self.morale_frame:GetPosition())

    if self.show_effects and self.debuffs ~= nil and self.debuffs.apply_settings ~= nil then
        self.debuffs:apply_settings(frame_width, v.effects, frame.effects_height)
    end
    if self.show_effects and self.buffs ~= nil and self.buffs.apply_settings ~= nil then
        self.buffs:apply_settings(frame_width, v.effects, frame.effects_height)
    end
    self:_layout_effect_windows()

    self:_resize_extra_controls()
    self:update()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function VitalsBase:_layout_effect_windows()
    if self.show_effects ~= true then
        return
    end
    if self.debuffs == nil or self.buffs == nil then
        return
    end

    local v = self:get_vitals_settings()
    local effects_height = self:get_effects_height()

    local below = self:effects_are_below()
    local reverse_fill = below ~= true
    self.buffs:set_reverse_fill(reverse_fill)
    self.debuffs:set_reverse_fill(reverse_fill)

    local buffs_h = self.buffs:GetHeight()
    if type(buffs_h) ~= "number" then
        buffs_h = 0
    end
    if buffs_h < 0 then
        buffs_h = 0
    end
    if type(effects_height) == "number" and buffs_h > effects_height then
        buffs_h = effects_height
    end

    local debuffs_h = effects_height - buffs_h
    if debuffs_h < 0 then
        debuffs_h = 0
    end
    if self.debuffs.set_max_height ~= nil then
        self.debuffs:set_max_height(debuffs_h)
    end

    if below == true then
        local effects_top = self.power_frame:GetTop() + self.power_frame:GetHeight()
        self.buffs:SetTop(effects_top)
        self.debuffs:SetTop(effects_top + buffs_h)
    else
        local effects_top = 0
        local bottom = self.morale_frame:GetTop()
        if type(bottom) ~= "number" then
            bottom = effects_top + effects_height
        end
        local buffs_top = bottom - buffs_h
        if buffs_top < effects_top then
            buffs_top = effects_top
        end
        self.buffs:SetTop(buffs_top)
        self.debuffs:SetTop(effects_top)
    end
end

function VitalsBase:_upsert_effect(effect, now)
    if effect == nil or effect.IsDebuff == nil then
        return
    end
    if self.show_effects ~= true or self.debuffs == nil or self.buffs == nil then
        return
    end

    local t = now
    if type(t) ~= "number" then
        t = Turbine.Engine.GetGameTime()
    end

    local key = _effect_key(effect)
    self.effects_seen_at[key] = t

    local started = self.effects_started_at[key]
    if type(started) ~= "number" then
        started = t
        self.effects_started_at[key] = started
    end

    local ending = _effect_ending(effect, t, started)
    if type(ending) == "number" then
        self.effects_ending_at[key] = ending
    end

    local existing = self.effects_objects[key]
    if existing == nil then
        self.effects_objects[key] = effect
        if effect:IsDebuff() then
            self.debuffs:add_effect(effect)
        else
            self.buffs:add_effect(effect)
        end
        self:_layout_effect_windows()
    elseif existing ~= effect then
        self.effects_objects[key] = effect
        if effect:IsDebuff() then
            if self.debuffs.add_effect ~= nil then
                self.debuffs:add_effect(effect)
            end
        else
            if self.buffs.add_effect ~= nil then
                self.buffs:add_effect(effect)
            end
        end
    end
end

function VitalsBase:_clear_effect_callbacks()
    if self.show_effects and self.effects_list ~= nil then
        remove_callback(self.effects_list, "EffectAdded", self.events.ea)
        self.events.ea = nil
        remove_callback(self.effects_list, "EffectRemoved", self.events.er)
        self.events.er = nil
        remove_callback(self.effects_list, "EffectsCleared", self.events.ec)
        self.events.ec = nil
    end
    self.effects_list = nil
end

function VitalsBase:_reset_effect_state()
    self.effects_resync_due_at = nil
    self.effects_resync_attempts = 0
    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}
    self:SetWantsUpdates(false)
end

-- Default implementation: track effects directly from entity:GetEffects() callbacks.
-- IMPORTANT: ONLY WORKS FOR LOCAL PLAYER, use TargetEventManager alternative
-- for targets.
function VitalsBase:_setup_effect_tracking_default()
    if self.show_effects ~= true then
        return
    end
    if self.debuffs ~= nil then self.debuffs:clear_effects() end
    if self.buffs ~= nil then self.buffs:clear_effects() end
    self:_layout_effect_windows()

    if self.entity == nil or self.entity.GetEffects == nil or self.debuffs == nil or self.buffs == nil then
        return
    end

    self.effects_list = self.entity:GetEffects()
    local bound_effects = self.effects_list
    if bound_effects == nil then
        return
    end

    self.effects_seen_at = {}
    self.effects_started_at = {}
    self.effects_ending_at = {}
    self.effects_objects = {}
    self:_request_effects_resync(0.05, 4)

    self.events.ea = add_callback(bound_effects, "EffectAdded", function(sender, args)
        if self.effects_list ~= bound_effects then
            return
        end
        local idx = args ~= nil and args.Index or nil
        local eff = nil
        if idx ~= nil and sender ~= nil and sender.Get ~= nil then
            eff = sender:Get(idx)
        end
        self:_upsert_effect(eff)
        self:_request_effects_resync(0.05, 6)
    end)

    self.events.er = add_callback(bound_effects, "EffectRemoved", function(sender, args)
        if self.effects_list ~= bound_effects then
            return
        end
        local eff = args ~= nil and args.Effect or nil
        if eff ~= nil then
            self:_remove_effect(eff)
        end
        self:_request_effects_resync(0.05, 6)
    end)

    self.events.ec = add_callback(bound_effects, "EffectsCleared", function()
        if self.effects_list ~= bound_effects then
            return
        end
        self:_request_effects_resync(0.10, 8)
    end)
end

-- Override in child classes when effect sync differs.
function VitalsBase:_setup_effect_tracking()
    self:_setup_effect_tracking_default()
end

function VitalsBase:_request_effects_resync(delay_seconds, attempts)
    if self.show_effects ~= true then
        return
    end
    if self.effects_list == nil then
        return
    end

    local delay = delay_seconds
    if type(delay) ~= "number" then
        delay = 0.10
    end
    if delay < 0 then delay = 0 end

    local a = attempts
    if type(a) ~= "number" then
        a = 1
    end
    if a < 1 then a = 1 end
    a = math.floor(a + 0.5)
    if a > 10 then a = 10 end
    if type(self.effects_resync_attempts) ~= "number" or self.effects_resync_attempts < a then
        self.effects_resync_attempts = a
    end

    self.effects_resync_due_at = Turbine.Engine.GetGameTime() + delay
    self:SetWantsUpdates(true)
end

function VitalsBase:_sync_effects_from_list(now)
    if self.show_effects ~= true then
        return
    end
    if self.debuffs == nil or self.buffs == nil then
        return
    end
    if self.effects_list == nil or self.effects_list.GetCount == nil or self.effects_list.Get == nil then
        return
    end

    local t = now
    if type(t) ~= "number" then
        t = Turbine.Engine.GetGameTime()
    end

    local sticky_target = self.vital_key == "target"
    local missing_grace = sticky_target and 999999 or 2.5
    local missing_grace_indef = sticky_target and 30.0 or 10.0

    local seen = {}
    local layout_dirty = false
    local count = self.effects_list:GetCount() or 0
    for i = 1, count do
        local effect = self.effects_list:Get(i)
        if effect ~= nil and effect.IsDebuff ~= nil then
            local key = _effect_key(effect)

            local started = self.effects_started_at[key]
            if type(started) ~= "number" then
                started = t
                self.effects_started_at[key] = started
            end

            local ending = _effect_ending(effect, t, started)
            if type(ending) == "number" then
                self.effects_ending_at[key] = ending
            else
                ending = self.effects_ending_at[key]
            end
            if type(ending) == "number" and t >= ending then
                -- Some effects linger in the effect list after expiration; prune them so they don't stick at 0s.
                local obj = self.effects_objects[key] or effect
                if _effect_is_debuff(obj) then
                    self.debuffs:remove_effect(obj, key)
                else
                    self.buffs:remove_effect(obj, key)
                end
                layout_dirty = true
                self.effects_objects[key] = nil
                self.effects_seen_at[key] = nil
                self.effects_started_at[key] = nil
                self.effects_ending_at[key] = nil
            else
                seen[key] = true
                self.effects_seen_at[key] = t

                local existing = self.effects_objects[key]
                if existing == nil then
                    self.effects_objects[key] = effect
                    if effect:IsDebuff() then
                        self.debuffs:add_effect(effect)
                    else
                        self.buffs:add_effect(effect)
                    end
                    layout_dirty = true
                elseif existing ~= effect then
                    -- Same key but different wrapper (e.g., refreshed effects). Update icon binding/timer.
                    self.effects_objects[key] = effect
                    if effect:IsDebuff() then
                        if self.debuffs.add_effect ~= nil then
                            self.debuffs:add_effect(effect)
                        end
                    else
                        if self.buffs.add_effect ~= nil then
                            self.buffs:add_effect(effect)
                        end
                    end
                end
            end
        end
    end

    for key, effect in pairs(self.effects_objects) do
        if seen[key] ~= true then
            local last = self.effects_seen_at[key]
            if type(last) ~= "number" then last = 0 end
            if effect == nil then
                self.effects_objects[key] = nil
                self.effects_seen_at[key] = nil
                self.effects_started_at[key] = nil
                self.effects_ending_at[key] = nil
            else
                local ending = _effect_ending(effect, t, last)
                if type(ending) == "number" then
                    self.effects_ending_at[key] = ending
                else
                    ending = self.effects_ending_at[key]
                end

                if type(ending) == "number" and t >= ending then
                    if _effect_is_debuff(effect) then
                        self.debuffs:remove_effect(effect, key)
                    else
                        self.buffs:remove_effect(effect, key)
                    end
                    layout_dirty = true
                    self.effects_objects[key] = nil
                    self.effects_seen_at[key] = nil
                    self.effects_started_at[key] = nil
                    self.effects_ending_at[key] = nil
                else
                    if sticky_target and type(ending) == "number" then
                        -- For target vitals, the effect list frequently drops active debuffs.
                        -- Keep effects until their own duration ends.
                    else
                        local grace = (type(ending) == "number") and missing_grace or missing_grace_indef
                        if (t - last) > grace then
                            if _effect_is_debuff(effect) then
                                self.debuffs:remove_effect(effect, key)
                            else
                                self.buffs:remove_effect(effect, key)
                            end
                            layout_dirty = true
                            self.effects_objects[key] = nil
                            self.effects_seen_at[key] = nil
                            self.effects_started_at[key] = nil
                            self.effects_ending_at[key] = nil
                        end
                    end
                end
            end
        end
    end

    if layout_dirty then
        self:_layout_effect_windows()
    end
end

function VitalsBase:_remove_effect(effect)
    if effect == nil or self.show_effects ~= true then
        return
    end
    if self.debuffs == nil or self.buffs == nil then
        return
    end

    local key = _effect_key(effect)
    if _effect_is_debuff(effect) then
        self.debuffs:remove_effect(effect, key)
    else
        self.buffs:remove_effect(effect, key)
    end
    self.effects_objects[key] = nil
    self.effects_seen_at[key] = nil
    self.effects_started_at[key] = nil
    self.effects_ending_at[key] = nil

    self:_layout_effect_windows()
end

function VitalsBase:_build_extra_controls()
end

function VitalsBase:_resize_extra_controls()
end
