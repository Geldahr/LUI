import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Turbine.Gameplay"

import "LUI.src.Vitals.vitals_base"
import "LUI.src.Vitals.target_effect_manager"
import "LUI.src.Settings.enums"

---@class BossVitals : VitalsBase
BossVitals = class(VitalsBase)

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function BossVitals:Constructor(entity)
    self.em = nil
    self.em_added_event = nil
    self.em_removed_event = nil
    self._layout_busy = false
    self._power_fill_width = 0

    VitalsBase.Constructor(self, "boss", entity, TR["Boss Vitals"])

    if self.buffs ~= nil then
        self.buffs.on_height_changed = function()
            self:_layout_effect_windows()
        end
    end
    if self.debuffs ~= nil then
        self.debuffs:set_dynamic_height(true)
        self.debuffs.on_height_changed = function()
            self:_layout_effect_windows()
        end
    end

    self:resize()
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function BossVitals:get_vitals_settings()
    return _G.settings.target.boss_vitals
end

function BossVitals:get_loaded_vitals_settings()
    return _G.loaded_settings.target.boss_vitals
end

function BossVitals:set_entity(entity)
    if self.em ~= nil and self.entity ~= entity then
        self:_detach_effect_manager()
    end

    VitalsBase.set_entity(self, entity)

    if entity == nil and self.em ~= nil then
        self:_detach_effect_manager()
    end

    if entity == nil then
        self.power_bar:SetWidth(self._power_fill_width or 0)
    end
end

function BossVitals:Update()
    if self.em ~= nil then
        self.em:poll()
    end

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

function BossVitals:get_lower_bars_height()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        return 0
    end
    return v.power.height
end

function BossVitals:effects_are_below()
    return true
end

function BossVitals:get_empty_morale_text()
    return "No Target"
end

function BossVitals:use_stacked_effects_layout()
    local raw = self:get_loaded_vitals_settings()
    if raw == nil or raw.power.hide == true then
        return false
    end

    local raw_frame_width = raw.frame.width or 0
    local raw_power_width = raw.power.width or 0
    return raw_frame_width < 400 or raw_power_width > (raw_frame_width / 2)
end

function BossVitals:apply_text_alignment()
    local v = self:get_vitals_settings()

    self.morale_label:SetTextAlignment(LUI_TO_LOTRO.text_alignment[v.morale.text_alignment] or
        Turbine.UI.ContentAlignment.MiddleLeft)
    self.power_label:SetTextAlignment(LUI_TO_LOTRO.text_alignment[v.power.text_alignment] or
        Turbine.UI.ContentAlignment.MiddleLeft)

    local frame_width = v.frame.width
    local morale_margin = v.frame.border_width + v.morale.text_margin
    local power_margin = v.frame.border_width + v.power.text_margin

    local function apply_margin(label, width, margin, alignment)
        if width < 1 then
            width = 1
        end
        if alignment == LUI_ENUMS.text_alignment.LEFT then
            label:SetPosition(margin, 0)
            label:SetSize(math.max(1, width - margin), label:GetHeight())
        elseif alignment == LUI_ENUMS.text_alignment.RIGHT then
            label:SetPosition(0, 0)
            label:SetSize(math.max(1, width - margin), label:GetHeight())
        else
            label:SetPosition(0, 0)
            label:SetSize(width, label:GetHeight())
        end
    end

    apply_margin(self.morale_label, frame_width, morale_margin, v.morale.text_alignment)
    apply_margin(self.power_label, self.power_frame:GetWidth(), power_margin, v.power.text_alignment)
end

function BossVitals:set_move_mode(enabled)
    VitalsBase.set_move_mode(self, enabled)
    self:_layout_effect_windows()
    if self:get_loaded_vitals_settings().enabled ~= true or is_lui_hud_visible() ~= true then
        self:SetVisible(false)
    elseif enabled == true then
        self:SetVisible(true)
    elseif self.entity == nil then
        self:SetVisible(false)
    end
end

function BossVitals:self_power_changed()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self.power_label:SetText("")
        self.power_bar:SetWidth(0)
        return
    end
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
    local maxp = self.entity:GetMaxPower() or 0
    local p = self.entity:GetPower() or 0
    local is_wrath = self.entity.GetClass ~= nil and self.entity:GetClass() == Turbine.Gameplay.Class.Beorning
    local fill_width = self._power_fill_width or 0

    if maxp > 0 then
        self.power_border:SetVisible(true)
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

        self.power_bar:SetWidth(math.floor((fill_width * percent) + 0.5))
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    else
        self.power_border:SetVisible(true)
        self.power_label:SetText("")
        self.power_bar:SetWidth(fill_width)
        local fill_color = is_wrath and v.power.color.wrath or v.power.color.power
        self.power_bar:SetBackColor(fill_color)
        self.power_background:SetBackColor(self:power_background_color(fill_color))
    end
end

function BossVitals:self_wrath_changed()
    local v = self:get_vitals_settings()
    if v.power.hide == true then
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self.power_label:SetText("")
        self.power_bar:SetWidth(0)
        return
    end
    if self.entity == nil or self.entity.GetClassAttributes == nil or self.entity:GetClassAttributes().GetWrath == nil then
        return
    end

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

    self.power_bar:SetWidth(math.floor((self._power_fill_width * percent) + 0.5))
    self.power_bar:SetBackColor(v.power.color.wrath)
    self.power_background:SetBackColor(self:power_background_color(v.power.color.wrath))
end

function BossVitals:resize()
    local v = self:get_vitals_settings()
    local frame = v.frame
    local frame_width = frame.width
    local border = frame.border_width
    local morale_h = v.morale.height
    local effects_h = self.show_effects == true and frame.effects_height or 0
    local power_hidden = v.power.hide == true
    local stacked_effects = self:use_stacked_effects_layout()

    self.width = frame_width - (2 * border)
    if self.width < 1 then self.width = 1 end

    self.morale_frame:SetPosition(0, 0)
    self.morale_frame:SetSize(frame_width, morale_h)
    self.morale_border:SetSize(frame_width, morale_h)
    self.morale_border:SetBackColor(frame.border_color)

    local morale_inner_h = morale_h - (2 * border)
    if morale_inner_h < 1 then morale_inner_h = 1 end
    self.morale_background:SetPosition(border, border)
    self.morale_background:SetSize(self.width, morale_inner_h)
    self.morale_background:SetBackColor(self:morale_background_color(v.morale.color.neutral))
    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetPosition(0, 0)
    self.bubble_bar:SetHeight(morale_inner_h)
    self.bubble_bar:SetBackColor(v.morale.color.bubble)
    self.morale_label:SetPosition(0, 0)
    self.morale_label:SetSize(frame_width, morale_h)

    local power_width = power_hidden == true and 0 or v.power.width
    if power_width < 0 then power_width = 0 end
    if power_width > frame_width then
        power_width = frame_width
    end
    if stacked_effects ~= true and power_width >= frame_width then
        power_width = frame_width - 1
    end
    local effects_width = stacked_effects == true and frame_width or (frame_width - power_width)
    if effects_width < 1 then effects_width = 1 end

    self._power_frame_width = power_width
    self._effects_width = effects_width
    self._effects_height = effects_h
    self._stacked_effects = stacked_effects

    self:_layout_effect_windows()
    self:apply_fonts()
    self:apply_text_alignment()
    self:update()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function BossVitals:_build_extra_controls()
    self.effects_top_border = Turbine.UI.Control()
    self.effects_top_border:SetParent(self)
    self.effects_top_border:SetMouseVisible(false)
    self.effects_top_border:SetVisible(false)
    self.effects_top_border:SetZOrder(3)
end

function BossVitals:_setup_effect_tracking()
    if self.show_effects ~= true then
        return
    end

    if self.em ~= nil then
        self:_detach_effect_manager()
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

    if self.entity == nil or self.entity.GetEffects == nil or self.entity:GetEffects() == nil then
        self:SetWantsUpdates(false)
        return
    end

    self.em = TargetEffectManager.acquire(Turbine.Gameplay.LocalPlayer.GetInstance(), self.entity)
    self.em_added_event = self.em:register_added_event(function(effect)
        self:_upsert_effect(effect)
    end)
    self.em_removed_event = self.em:register_removed_event(function(effect)
        self:_remove_effect(effect)
        self:_request_effects_resync(0.05, 6)
    end)

    self:SetWantsUpdates(true)
end

function BossVitals:_detach_effect_manager()
    if self.em == nil then
        self.em_added_event = nil
        self.em_removed_event = nil
        return
    end

    if self.em_added_event ~= nil and self.em.unregister_added_event ~= nil then
        self.em:unregister_added_event(self.em_added_event)
        self.em_added_event = nil
    end
    if self.em_removed_event ~= nil and self.em.unregister_removed_event ~= nil then
        self.em:unregister_removed_event(self.em_removed_event)
        self.em_removed_event = nil
    end

    self.em:delete()
    self.em = nil
end

function BossVitals:_layout_effect_windows()
    if self._layout_busy == true then
        return
    end
    self._layout_busy = true

    local v = self:get_vitals_settings()
    local frame = v.frame
    local border = frame.border_width
    local frame_width = frame.width
    local power_width = self._power_frame_width or math.floor(frame_width * 0.28)
    local effects_width = self._effects_width or math.max(1, frame_width - power_width)
    local effects_max_h = self._effects_height or 0
    local power_hidden = v.power.hide == true
    local stacked_effects = self._stacked_effects == true and power_hidden ~= true
    local reverse_fill = self:effects_are_below() ~= true
    local effects_content_h = math.max(0, effects_max_h - border)
    local lower_top = self.morale_frame:GetTop() + self.morale_frame:GetHeight() - border

    self.buffs:set_reverse_fill(reverse_fill)
    self.debuffs:set_reverse_fill(reverse_fill)

    local buffs_h = 0
    local debuffs_h = 0

    if self.show_effects == true and self.buffs ~= nil and self.debuffs ~= nil then
        self.buffs:apply_settings(effects_width, v.effects, effects_content_h)
        self.buffs:set_max_height(effects_content_h)
        buffs_h = self.buffs:GetHeight() or 0

        self.debuffs:apply_settings(effects_width, v.effects, effects_content_h)
        self.debuffs:set_dynamic_height(true)
        self.debuffs:set_max_height(math.max(0, effects_content_h - buffs_h))
        debuffs_h = self.debuffs:GetHeight() or 0
    else
        if self.buffs ~= nil then
            self.buffs:SetSize(effects_width, 0)
        end
        if self.debuffs ~= nil then
            self.debuffs:SetSize(effects_width, 0)
        end
    end

    local power_h = v.power.height
    if power_h < 1 then power_h = 1 end

    local effects_total_h = buffs_h + debuffs_h
    local reserved_effects_h = border + effects_total_h
    if self:is_move_mode() == true then
        reserved_effects_h = math.max(reserved_effects_h, effects_max_h)
    end
    local lower_h
    local effects_top
    if power_hidden == true then
        lower_h = math.max(reserved_effects_h, border)
        effects_top = lower_top
    elseif stacked_effects == true then
        lower_h = power_h + math.max(reserved_effects_h, border)
        effects_top = lower_top + power_h - border
    else
        lower_h = math.max(power_h, reserved_effects_h, border)
        effects_top = lower_top
    end
    local total_h = lower_top + lower_h
    if total_h < 1 then total_h = 1 end

    self:SetSize(frame_width, total_h)
    if not self.managed_position then
        self:SetPosition(v.window.left, v.window.top)
    end

    local power_left = 0
    local effects_left = stacked_effects == true and 0 or power_width
    if stacked_effects ~= true and v.power.side == LUI_ENUMS.side.RIGHT then
        power_left = frame_width - power_width
        effects_left = 0
    elseif stacked_effects == true and v.power.side == LUI_ENUMS.side.RIGHT then
        power_left = frame_width - power_width
    end

    if power_hidden == true then
        self._power_fill_width = 0
        self.power_frame:SetVisible(false)
        self.power_border:SetVisible(false)
        self.power_label:SetText("")
        self.power_bar:SetWidth(0)
    else
        self.power_frame:SetVisible(true)
        self.power_frame:SetPosition(power_left, lower_top)
        self.power_frame:SetSize(power_width, power_h)
        self.power_border:SetVisible(true)
        self.power_border:SetSize(power_width, power_h)
        self.power_border:SetBackColor(frame.border_color)

        local power_inner_w = power_width - (2 * border)
        local power_inner_h = power_h - (2 * border)
        if power_inner_w < 1 then power_inner_w = 1 end
        if power_inner_h < 1 then power_inner_h = 1 end
        self._power_fill_width = power_inner_w

        self.power_background:SetPosition(border, border)
        self.power_background:SetSize(power_inner_w, power_inner_h)
        self.power_background:SetBackColor(self:power_background_color(v.power.color.power))
        self.power_bar:SetPosition(0, 0)
        self.power_bar:SetHeight(power_inner_h)
        self.power_label:SetPosition(0, 0)
        self.power_label:SetSize(power_width, power_h)
    end

    if self.effects_top_border ~= nil then
        if self.show_effects == true then
            self.effects_top_border:SetVisible(true)
            self.effects_top_border:SetPosition(effects_left, effects_top)
            self.effects_top_border:SetSize(effects_width, border)
            self.effects_top_border:SetBackColor(frame.border_color)
        else
            self.effects_top_border:SetVisible(false)
        end
    end

    if self.show_effects == true and self.buffs ~= nil and self.debuffs ~= nil then
        self.buffs:SetPosition(effects_left, effects_top + border)
        self.debuffs:SetPosition(effects_left, effects_top + border + buffs_h)
    end

    self.entity_control:SetPosition(0, 0)
    self.entity_control:SetSize(frame_width, total_h)

    self._layout_busy = false
end
