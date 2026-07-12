-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Upkeep = _G.LUI.Features.Upkeep
local Lore = _G.LUI.Data.Lore
local LUI_ENUMS = _G.LUI.Settings.Enums
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.Data.lore_db"
import "LUI.src.Upkeep.upkeep_slot"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"

local add_callback = _G.LUI.Utils.add_callback
local remove_callback = _G.LUI.Utils.remove_callback

-- The Upkeep bar: a pure tracker for maintenance buffs, one drawn skill
-- icon per slot (never a quickslot; native quickslot rendering neither
-- scales/aligns cleanly nor alpha-blends with decorations). The skills DB
-- (Lore.Skills) resolves each bound skill DID to the localized buff names
-- it applies; player effects are matched by those names, cooldowns come
-- live from the trained ActiveSkill.
--
-- Zoomed (stretched) icons render above every control in their own window
-- but below other windows, so the slot decorations (drain, shade, timer)
-- live in a companion overlay window kept just above the HUD, in true
-- pixels. Order is held with the Activate() pattern, never window ZOrder.
local UpkeepWindow = class(UI.Widgets.LuiHUD)
Upkeep.UpkeepWindow = UpkeepWindow

local SKILL_DISCOVER_EVERY = 30.0

local UpkeepOverlay = class(UI.Widgets.LuiBaseWindow)

function UpkeepOverlay:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, { hideable = true })

    self:SetVisible(false)
    self:SetMouseVisible(false)
end

function UpkeepOverlay:destroy()
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function UpkeepWindow:Constructor()
    UI.Widgets.LuiHUD.Constructor(self, {
        hud_key = "upkeep",
        title = TR["Upkeep"],
    })

    self.slots = {}
    self._capacity = 0
    self._bound_count = 0
    -- localized buff name -> array of slot indexes watching it
    self._watch = {}
    -- auto-order working buffers (slot index per display position)
    self._display_order = {}
    self._order_buf = {}
    self._urgency_buf = {}
    self._rank_buf = {}
    -- urgencies all count down at the same rate, so the sort order can
    -- only change on discrete events (effect added/removed, cooldown
    -- reset time changed); those mark it dirty via invalidate_order()
    self._order_dirty = true
    self.last_update_at = 0
    self.update_every = 1.0 / State.settings.global.refresh_rate
    self._skill_discover_due_at = 0

    self._effects_list = nil
    self._events = {}

    self:SetWantsUpdates(true)
    self:SetVisible(false)
    self:SetMouseVisible(false)

    self.overlay = UpkeepOverlay()
    add_callback(self, "PositionChanged", function()
        self:_sync_companion_positions()
    end)
    -- keep the companions above the HUD when the HUD gets activated
    -- (move-mode clicks); they are mouse-invisible and can never steal
    -- activation themselves
    add_callback(self, "Activated", function()
        self:_raise_companions()
    end)

    self:_setup_effect_tracking()
    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

function UpkeepWindow:destroy()
    for i = 1, #self.slots do
        self.slots[i]:destroy()
    end
    if self._effects_list ~= nil then
        remove_callback(self._effects_list, "EffectAdded", self._events.ea)
        remove_callback(self._effects_list, "EffectRemoved", self._events.er)
        remove_callback(self._effects_list, "EffectsCleared", self._events.ec)
        self._events = {}
        self._effects_list = nil
    end
    self.overlay:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:SetParent(nil)
end

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function UpkeepWindow:get_settings()
    return State.settings.self.upkeep
end

-- an urgency input changed (effect set, cooldown reset time); auto order
-- re-sorts on the next tick
function UpkeepWindow:invalidate_order()
    self._order_dirty = true
end

function UpkeepWindow:set_move_mode(enabled)
    UI.Widgets.LuiHUD.set_move_mode(self, enabled)
    for i = 1, self._capacity do
        self.slots[i]:set_move_mode(enabled == true)
    end
    self:refresh_visibility()
end

function UpkeepWindow:apply_settings()
    self:apply_native_scaling()

    local s = self:get_settings()
    self.update_every = 1.0 / State.settings.global.refresh_rate

    self:apply_hud_position()

    local count = s.count
    local size = s.icon_size
    local spacing = s.spacing
    local vertical = s.orientation == LUI_ENUMS.orientation.VERTICAL

    local main = (count * size) + ((count - 1) * spacing)
    if vertical then
        self:SetSize(size, main)
        self.overlay:SetSize(size, main)
    else
        self:SetSize(main, size)
        self.overlay:SetSize(main, size)
    end
    self:layout_move_chrome()

    for i = 1, count do
        if self.slots[i] == nil then
            local slot = Upkeep.UpkeepSlot(self.overlay, self)
            slot:SetParent(self)
            slot:SetVisible(false)
            self.slots[i] = slot
        end
    end
    -- surplus slots from a lowered count: unbind fully and hide
    for i = count + 1, #self.slots do
        self.slots[i]:set_skill(nil)
        self.slots[i]:set_binding(nil, nil)
        self.slots[i]:set_move_mode(false)
        self.slots[i]:SetVisible(false)
    end
    self._capacity = count

    self._watch = {}
    self._bound_count = 0
    local move_mode = self:is_move_mode()
    for i = 1, count do
        local slot = self.slots[i]
        slot:apply_settings()
        self:_place_slot(slot, i)
        -- invalidate the cached order so auto order re-places (with its
        -- anchor applied) on the next tick
        self._display_order[i] = 0

        local did_text = s.slots[i]
        local record = nil
        if type(did_text) ~= "string" or tonumber(did_text) == nil then
            did_text = nil
        else
            record = Lore.Skills.buffs_of(tonumber(did_text))
        end
        slot:set_binding(did_text, record)
        slot:set_move_mode(move_mode)

        if did_text ~= nil then
            self._bound_count = self._bound_count + 1
            if record ~= nil then
                local effects = record.effects
                for k = 1, #effects do
                    local name = effects[k].name
                    local bucket = self._watch[name]
                    if bucket == nil then
                        bucket = {}
                        self._watch[name] = bucket
                    end
                    bucket[#bucket + 1] = i
                end
            end
        end
    end

    self:_sync_companion_positions()
    self:invalidate_order()
    self:_rescan_effects()
    self:_discover_skills(true)
    self:refresh_visibility()
end

function UpkeepWindow:refresh_visibility()
    local s = self:get_settings()
    local move_mode = self:is_move_mode()
    local show = s.enabled == true and (self._bound_count > 0 or move_mode)
    self:SetVisible(show)
    -- in move mode the companions would draw over the move chrome; the
    -- placeholders in the HUD show the footprint while dragging
    local companions_show = show and move_mode ~= true
    local was_visible = self.overlay:IsVisible() == true
    self.overlay:SetVisible(companions_show)
    for i = 1, self._capacity do
        self.slots[i]:sync_shown(companions_show)
    end
    if companions_show and was_visible ~= true then
        self:_raise_companions()
    end
end

function UpkeepWindow:Update()
    local s = self:get_settings()
    if s.enabled ~= true then
        self:refresh_visibility()
        return
    end

    local now = Turbine.Engine.GetGameTime()
    if (now - self.last_update_at) < self.update_every then
        return
    end
    self.last_update_at = now

    if now >= (self._skill_discover_due_at or 0) then
        self:_discover_skills(false)
    end

    if self:is_move_mode() == true then
        return
    end

    for i = 1, self._capacity do
        self.slots[i]:update(now)
    end

    if s.auto_order == true and self._order_dirty == true then
        self:_apply_auto_order(now)
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

-- cell geometry for one display position (1-based, from the start of the bar)
function UpkeepWindow:_place_slot(slot, position)
    local s = self:get_settings()
    local offset = (position - 1) * (s.icon_size + s.spacing)
    if s.orientation == LUI_ENUMS.orientation.VERTICAL then
        slot:place(0, offset)
    else
        slot:place(offset, 0)
    end
end

-- auto order: sort the slots by urgency (next skill to reactivate first)
-- and re-place them when the order changes; the anchor picks which end of
-- the bar holds the most urgent slot. Runs only on ticks where an urgency
-- input changed (see invalidate_order), never on quiet ticks.
function UpkeepWindow:_apply_auto_order(now)
    self._order_dirty = false
    local count = self._capacity
    local order = self._order_buf
    local urgency = self._urgency_buf
    local rank = self._rank_buf
    for i = 1, count do
        order[i] = i
        urgency[i] = self.slots[i]:urgency(now)
        rank[i] = i
    end
    for i = count + 1, #order do
        order[i] = nil
        urgency[i] = nil
        rank[i] = nil
    end
    -- ties keep their current on-screen position instead of snapping to
    -- binding order, so ready slots (urgency 0) don't reshuffle as each
    -- cooldown ends; right after apply_settings the cached order is
    -- invalidated (all 0) and the rank falls back to the slot index
    for k = 1, count do
        local slot_index = self._display_order[k]
        if slot_index ~= 0 then
            rank[slot_index] = k
        end
    end
    table.sort(order, function(a, b)
        if urgency[a] ~= urgency[b] then
            return urgency[a] < urgency[b]
        end
        return rank[a] < rank[b]
    end)

    local changed = false
    for k = 1, count do
        if self._display_order[k] ~= order[k] then
            changed = true
            break
        end
    end
    if changed ~= true then
        return
    end

    local reverse = self:get_settings().auto_order_anchor == LUI_ENUMS.side.RIGHT
    for k = 1, count do
        self._display_order[k] = order[k]
        local position = reverse and (count - k + 1) or k
        self:_place_slot(self.slots[order[k]], position)
    end
    self:_sync_companion_positions()
end

-- the icon windows sit at the HUD position plus their cell offset; the
-- decoration overlay covers the whole bar
function UpkeepWindow:_sync_companion_positions()
    local x, y = self:GetPosition()
    self.overlay:SetPosition(x, y)
    for i = 1, self._capacity do
        local slot = self.slots[i]
        slot.icon_window:SetPosition(x + slot._x, y + slot._y)
    end
end

-- layering bottom-up: HUD, then the icon windows, then the decoration
-- overlay; held with the Activate() pattern (never window ZOrder)
function UpkeepWindow:_raise_companions()
    for i = 1, self._capacity do
        local slot = self.slots[i]
        if slot.icon_window:IsVisible() == true then
            slot.icon_window:Activate()
        end
    end
    if self.overlay:IsVisible() == true then
        self.overlay:Activate()
    end
end

function UpkeepWindow:_setup_effect_tracking()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if player == nil or player.GetEffects == nil then
        return
    end
    local list = player:GetEffects()
    if list == nil then
        return
    end

    self._effects_list = list
    self._events.ea = add_callback(list, "EffectAdded", function(sender, args)
        local idx = args ~= nil and args.Index or nil
        if idx == nil or sender == nil or sender.Get == nil then
            return
        end
        self:_on_effect_added(sender:Get(idx))
    end)
    self._events.er = add_callback(list, "EffectRemoved", function(_, args)
        local effect = args ~= nil and args.Effect or nil
        if effect ~= nil and effect.GetID ~= nil then
            self:_on_effect_removed(effect:GetID())
        else
            self:_rescan_effects()
        end
    end)
    self._events.ec = add_callback(list, "EffectsCleared", function()
        self:_rescan_effects()
    end)
end

function UpkeepWindow:_on_effect_added(effect)
    if effect == nil or effect.GetName == nil then
        return
    end
    local targets = self._watch[effect:GetName()]
    if targets == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    for i = 1, #targets do
        self.slots[targets[i]]:add_active(effect, now)
    end
    self:invalidate_order()
end

function UpkeepWindow:_on_effect_removed(id)
    local removed = false
    for i = 1, self._capacity do
        if self.slots[i]:remove_active(id) then
            removed = true
        end
    end
    if removed then
        self:invalidate_order()
    end
end

function UpkeepWindow:_rescan_effects()
    for i = 1, self._capacity do
        self.slots[i]:clear_active()
    end
    self:invalidate_order()

    local list = self._effects_list
    if list == nil or list.GetCount == nil then
        return
    end
    for i = 1, (list:GetCount() or 0) do
        self:_on_effect_added(list:Get(i))
    end
end

function UpkeepWindow:_discover_skills(force)
    local now = Turbine.Engine.GetGameTime()
    if force ~= true and now < (self._skill_discover_due_at or 0) then
        return
    end
    self._skill_discover_due_at = now + SKILL_DISCOVER_EVERY

    -- localized skill name (from the skills DB) -> slot indexes to resolve
    local wanted = {}
    local wanted_any = false
    for i = 1, self._capacity do
        local record = self.slots[i].binding
        if record ~= nil then
            local bucket = wanted[record.name]
            if bucket == nil then
                bucket = {}
                wanted[record.name] = bucket
                wanted_any = true
            end
            bucket[#bucket + 1] = i
        end
    end

    local found = {}
    if wanted_any then
        local player = Turbine.Gameplay.LocalPlayer.GetInstance()
        if player ~= nil and player.GetTrainedSkills ~= nil then
            local list = player:GetTrainedSkills()
            if list ~= nil and list.GetCount ~= nil and list.GetItem ~= nil then
                for i = 1, (list:GetCount() or 0) do
                    local skill = list:GetItem(i)
                    if skill ~= nil and skill.GetSkillInfo ~= nil and skill.GetResetTime ~= nil then
                        local info = skill:GetSkillInfo()
                        if info ~= nil and info.GetName ~= nil then
                            local bucket = wanted[info:GetName()]
                            if bucket ~= nil then
                                for k = 1, #bucket do
                                    found[bucket[k]] = skill
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = 1, self._capacity do
        self.slots[i]:set_skill(found[i])
    end
end
