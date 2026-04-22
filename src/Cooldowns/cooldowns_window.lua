import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.Cooldowns.cooldown_entry"
import "LUI.src.UI.Widgets.hud"
import "LUI.src.Utils.callbacks"

---@class RecoveringSkill
---@field key string
---@field name string
---@field name_key string
---@field is_white boolean
---@field skill Turbine.Gameplay.Skill
---@field reset_time number
---@field cooldown_seconds number
---@field enter_at number
---@field icon Turbine.UI.Graphic
---@field cb_reset function
RecoveringSkill = class()

function RecoveringSkill:Constructor(skill, name_key, name, white_listed)
    self.key = name_key
    self.name = name
    self.name_key = name_key
    self.is_white = white_listed
    self.skill = skill
    self.reset_time = nil
    self.cooldown_seconds = 0
    self.enter_at = nil
    self.icon = nil
    self.cb_reset = nil
end

CooldownsWindow = class(LuiHUD)

local SKILL_DISCOVER_EVERY = 30.0

local function _trim(s)
    if type(s) ~= "string" then
        return ""
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _parse_name_filter(text)
    local set = {}
    local prefixes = {}
    if type(text) ~= "string" or text == "" then
        return set, prefixes
    end

    local prefix_seen = {}
    for token in string.gmatch(text, "[^,\n\r]+") do
        local t = string.lower(_trim(token))
        if t ~= "" then
            if string.sub(t, -1) == "*" then
                local prefix = _trim(string.sub(t, 1, -2))
                if prefix ~= "" and prefix_seen[prefix] ~= true then
                    prefix_seen[prefix] = true
                    prefixes[#prefixes + 1] = prefix
                end
            else
                set[t] = true
            end
        end
    end

    return set, prefixes
end

local function _matches_name_filter(set, prefixes, name_key)
    if set[name_key] == true then
        return true
    end

    for i = 1, #prefixes do
        local prefix = prefixes[i]
        if string.sub(name_key, 1, #prefix) == prefix then
            return true
        end
    end

    return false
end

local function _clear_array(list)
    for i = #list, 1, -1 do
        list[i] = nil
    end
end

local function _insert_sorted(list, value, compare)
    local count = #list
    for i = 1, count do
        if compare(value, list[i]) then
            table.insert(list, i, value)
            return
        end
    end

    list[count + 1] = value
end

local function _remove_value(list, value)
    for i = 1, #list do
        if list[i] == value then
            table.remove(list, i)
            return true
        end
    end

    return false
end

local function _compare_active(a, b)
    local r1 = a ~= nil and a.reset_time or 0
    local r2 = b ~= nil and b.reset_time or 0
    if r1 ~= r2 then
        return r1 < r2
    end

    local k1 = a ~= nil and a.name_key or ""
    local k2 = b ~= nil and b.name_key or ""
    return k1 < k2
end

local function _compare_pending(a, b)
    local e1 = a ~= nil and a.enter_at or 0
    local e2 = b ~= nil and b.enter_at or 0
    if e1 ~= e2 then
        return e1 < e2
    end

    local w1 = a ~= nil and a.is_white == true
    local w2 = b ~= nil and b.is_white == true
    if w1 ~= w2 then
        return w1
    end

    local r1 = a ~= nil and a.reset_time or 0
    local r2 = b ~= nil and b.reset_time or 0
    if r1 ~= r2 then
        return r1 < r2
    end

    local k1 = a ~= nil and a.name_key or ""
    local k2 = b ~= nil and b.name_key or ""
    return k1 < k2
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function CooldownsWindow:Constructor()
    LuiHUD.Constructor(self, {
        hud_key = "cooldowns",
        title = TR["Cooldowns"],
    })

    self.slots = {}
    self.last_update_at = 0
    self.update_every = 1.0 / _G.settings.global.refresh_rate

    self._skill_discover_due_at = 0
    self._skills = {}
    self._active_white = {}
    self._active_other = {}
    self._active_order = {}
    self._pending = {}
    self._active_order_dirty = false
    self._is_updating_entries = false
    self._process_structure_pending = false

    self._wl_set = {}
    self._wl_prefixes = {}
    self._bl_set = {}
    self._bl_prefixes = {}

    self:SetWantsUpdates(true)
    self:SetVisible(false)
    self:SetMouseVisible(false)
    self:SetZOrder(20)

    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function CooldownsWindow:get_settings()
    return _G.settings.self.cooldowns
end

function CooldownsWindow:set_move_mode(enabled)
    LuiHUD.set_move_mode(self, enabled)
    self:refresh_visibility()
end

function CooldownsWindow:destroy()
    self:_clear_skill_callbacks()
    self:SetParent(nil)
end

function CooldownsWindow:apply_settings()
    self:apply_native_scaling()

    local s = self:get_settings()

    self.update_every = 1.0 / _G.settings.global.refresh_rate

    self:apply_hud_position()

    local cols = s.columns
    local rows = s.rows
    local spacing = s.spacing

    local entry_width = s.item_w
    local entry_height = s.item_h
    if entry_width < 1 then entry_width = 1 end
    if entry_height < 1 then entry_height = 1 end

    local width = (cols * entry_width) + ((cols - 1) * spacing)
    local height = (rows * entry_height) + ((rows - 1) * spacing)
    self:SetSize(width, height)
    self:layout_move_chrome()

    local capacity = cols * rows
    for i = 1, capacity do
        if self.slots[i] == nil then
            local entry = CooldownEntry()
            entry:SetParent(self)
            entry:SetVisible(false)
            entry:SetZOrder(10)
            self.slots[i] = entry
        end

        self.slots[i].expired_event = function()
            self:_process_structure_changes(Turbine.Engine.GetGameTime())
        end
        self.slots[i]:apply_settings()

        local x, y = self:get_slot_position(i, cols, entry_width, entry_height, spacing)
        self.slots[i]:SetPosition(x, y)
    end

    for i = capacity + 1, #self.slots do
        if self.slots[i] ~= nil then
            self.slots[i]:SetVisible(false)
        end
    end

    self:_refresh_filter_sets()
    self:_discover_skills(true)
    self:refresh_visibility()
end

function CooldownsWindow:get_slot_position(slot_index, cols, entry_width, entry_height, spacing)
    local zero = slot_index - 1
    local row = math.floor(zero / cols)
    local col = zero % cols
    local x = col * (entry_width + spacing)
    local y = row * (entry_height + spacing)
    return x, y
end

function CooldownsWindow:refresh_visibility()
    local s = self:get_settings()
    if s.enabled ~= true or is_lui_hud_visible() ~= true then
        self:SetVisible(false)
        return
    end

    local cols = s.columns
    local rows = s.rows
    local capacity = cols * rows

    local any_visible = false
    for i = 1, capacity do
        local e = self.slots[i]
        if e ~= nil and e:IsVisible() then
            any_visible = true
            break
        end
    end

    self:SetVisible(any_visible or self:is_move_mode())
end

function CooldownsWindow:_draw_entries(now, threshold)
    local s = self:get_settings()
    local capacity = s.columns * s.rows
    local invert = s.flow == LUI_ENUMS.list_flow.BOTTOM_TO_TOP

    self._is_updating_entries = true
    for i = 1, capacity do
        local slot_index = invert and (capacity - i + 1) or i
        local e = self.slots[slot_index]
        local rec = self._active_order[i]

        if rec ~= nil then
            local remaining = rec.reset_time - now
            local base_seconds = rec.cooldown_seconds
            if base_seconds <= 0 then
                base_seconds = remaining
            end
            if base_seconds > threshold then
                base_seconds = threshold
            end

            e:set_skill(rec)
            e:update_remaining(remaining, base_seconds)
        else
            e:set_skill(nil)
        end
    end
    self._is_updating_entries = false
end

function CooldownsWindow:Update()
    local s = self:get_settings()
    if s.enabled ~= true then
        self:SetVisible(false)
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

    local threshold = s.threshold
    if threshold <= 0 then
        for i = 1, #self.slots do
            local e = self.slots[i]
            if e ~= nil then
                e:set_skill(nil)
                e:SetVisible(false)
            end
        end
        self:refresh_visibility()
        return
    end

    local pending = self._pending[1]
    if pending ~= nil and pending.enter_at <= now then
        self:_process_structure_changes(now)
    end

    self:_draw_entries(now, threshold)

    if self._process_structure_pending == true then
        self:_process_structure_changes(now)
        self:_draw_entries(now, threshold)
    end

    self:refresh_visibility()
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function CooldownsWindow:_refresh_filter_sets()
    local s = self:get_settings()
    self._wl_set, self._wl_prefixes = _parse_name_filter(s.whitelist)
    self._bl_set, self._bl_prefixes = _parse_name_filter(s.blacklist)
end

function CooldownsWindow:_clear_runtime_lists()
    _clear_array(self._active_white)
    _clear_array(self._active_other)
    _clear_array(self._active_order)
    _clear_array(self._pending)
    self._active_order_dirty = false
    self._process_structure_pending = false
end

function CooldownsWindow:_rebuild_active_order()
    local out = self._active_order
    local n = 0

    local white = self._active_white
    for i = 1, #white do
        n = n + 1
        out[n] = white[i]
    end

    local other = self._active_other
    for i = 1, #other do
        n = n + 1
        out[n] = other[i]
    end

    for i = n + 1, #out do
        out[i] = nil
    end

    self._active_order_dirty = false
end

function CooldownsWindow:_remove_skill_from_runtime(rec)
    if rec == nil then
        return false
    end

    local removed = false
    if _remove_value(self._pending, rec) then
        removed = true
    end

    local active = rec.is_white == true and self._active_white or self._active_other
    if _remove_value(active, rec) then
        removed = true
    end

    rec.enter_at = nil
    return removed
end

function CooldownsWindow:_insert_active_skill(rec)
    local active = rec.is_white == true and self._active_white or self._active_other
    _insert_sorted(active, rec, _compare_active)
end

function CooldownsWindow:_insert_pending_skill(rec, threshold)
    rec.enter_at = rec.reset_time - threshold
    _insert_sorted(self._pending, rec, _compare_pending)
end

function CooldownsWindow:_update_skill_runtime(rec)
    if rec == nil then
        return
    end

    local changed = self:_remove_skill_from_runtime(rec)

    local threshold = self:get_settings().threshold
    if threshold > 0 and rec.reset_time ~= nil then
        local now = Turbine.Engine.GetGameTime()
        local remaining = rec.reset_time - now
        if remaining > 0 then
            if remaining <= threshold then
                self:_insert_active_skill(rec)
            else
                self:_insert_pending_skill(rec, threshold)
            end
            changed = true
        end
    end

    if changed then
        self._active_order_dirty = true
        self:_process_structure_changes(Turbine.Engine.GetGameTime())
    end
end

function CooldownsWindow:_process_structure_changes(now)
    if self._is_updating_entries == true then
        self._process_structure_pending = true
        return
    end

    self._process_structure_pending = false
    local threshold = self:get_settings().threshold
    local changed = self._active_order_dirty

    while #self._pending > 0 do
        local rec = self._pending[1]
        if rec == nil then
            table.remove(self._pending, 1)
            changed = true
        else
            local enter_at = rec.enter_at
            if enter_at == nil then
                table.remove(self._pending, 1)
                changed = true
            elseif enter_at > now then
                break
            else
                table.remove(self._pending, 1)
                rec.enter_at = nil

                if rec.reset_time ~= nil then
                    local remaining = rec.reset_time - now
                    if remaining > 0 then
                        if remaining <= threshold then
                            self:_insert_active_skill(rec)
                        else
                            self:_insert_pending_skill(rec, threshold)
                        end
                    end
                end

                changed = true
            end
        end
    end

    local function prune_active(list)
        local removed = false

        while #list > 0 do
            local rec = list[1]
            if rec ~= nil and rec.reset_time > now then
                break
            end

            table.remove(list, 1)
            removed = true
        end

        return removed
    end

    if prune_active(self._active_white) then
        changed = true
    end
    if prune_active(self._active_other) then
        changed = true
    end

    if changed then
        self:_rebuild_active_order()
    end
end

function CooldownsWindow:_clear_skill_callbacks()
    local skills = self._skills
    for i = 1, #skills do
        local rec = skills[i]
        if rec ~= nil and rec.skill ~= nil and rec.cb_reset ~= nil then
            remove_callback(rec.skill, "ResetTimeChanged", rec.cb_reset)
            rec.cb_reset = nil
        end
    end
end

function CooldownsWindow:_refresh_skill_state(rec)
    if rec == nil or rec.skill == nil or rec.skill.GetResetTime == nil then
        return
    end

    local now = Turbine.Engine.GetGameTime()
    local reset_time = rec.skill:GetResetTime()
    rec.reset_time = reset_time
    rec.cooldown_seconds = 0

    if reset_time == nil then
        return
    end

    local remaining = reset_time - now
    if remaining <= 0 then
        return
    end

    local cooldown_seconds = rec.skill.GetCooldown ~= nil and rec.skill:GetCooldown() or nil
    if cooldown_seconds == nil or cooldown_seconds <= 0 then
        cooldown_seconds = remaining
    elseif cooldown_seconds < remaining then
        cooldown_seconds = remaining
    end

    rec.cooldown_seconds = cooldown_seconds
end

function CooldownsWindow:_discover_skills(force)
    local now = Turbine.Engine.GetGameTime()
    if force ~= true and now < (self._skill_discover_due_at or 0) then
        return
    end

    self._skill_discover_due_at = now + SKILL_DISCOVER_EVERY

    self:_clear_skill_callbacks()
    self:_clear_runtime_lists()
    self._skills = {}

    local wl = self._wl_set
    local wl_prefixes = self._wl_prefixes
    local bl = self._bl_set
    local bl_prefixes = self._bl_prefixes
    local settings = self:get_settings()
    local threshold = settings.threshold
    local min_base_cooldown = settings.min_base_cooldown or 0

    local lp = Turbine.Gameplay.LocalPlayer.GetInstance()
    if lp == nil or lp.GetTrainedSkills == nil then
        return
    end

    local list = lp:GetTrainedSkills()
    if list == nil or list.GetCount == nil or list.GetItem == nil then
        return
    end

    local out = {}
    local out_len = 0

    local count = list:GetCount() or 0
    for i = 1, count do
        local skill = list:GetItem(i)
        ---@cast skill Turbine.Gameplay.ActiveSkill
        if skill ~= nil and skill.GetSkillInfo ~= nil and skill.GetResetTime ~= nil then
            local info = skill:GetSkillInfo()
            if info ~= nil and info.GetName ~= nil then
                local name = info:GetName()
                if name ~= "" then
                    local name_key = string.lower(name)
                    if _matches_name_filter(bl, bl_prefixes, name_key) ~= true then
                        local base_cooldown_seconds = skill.GetCooldown ~= nil and skill:GetCooldown() or nil
                        local passes_min_base = true
                        if min_base_cooldown > 0 and base_cooldown_seconds ~= nil and base_cooldown_seconds > 0 then
                            passes_min_base = base_cooldown_seconds >= min_base_cooldown
                        end

                        if passes_min_base then
                            out_len = out_len + 1
                            local rec = RecoveringSkill(
                                skill,
                                name_key,
                                name,
                                _matches_name_filter(wl, wl_prefixes, name_key)
                            )

                            if info.GetIconImageID ~= nil then
                                local icon_id = info:GetIconImageID()
                                if icon_id ~= nil then
                                    rec.icon = Turbine.UI.Graphic(icon_id)
                                end
                            end

                            self:_refresh_skill_state(rec)

                            if threshold > 0 and rec.reset_time ~= nil then
                                local remaining = rec.reset_time - now
                                if remaining > 0 then
                                    if remaining <= threshold then
                                        self:_insert_active_skill(rec)
                                    else
                                        self:_insert_pending_skill(rec, threshold)
                                    end
                                end
                            end

                            rec.cb_reset = add_callback(skill, "ResetTimeChanged", function()
                                self:_refresh_skill_state(rec)
                                self:_update_skill_runtime(rec)
                            end)

                            out[out_len] = rec
                        end
                    end
                end
            end
        end
    end

    self._skills = out
    self:_rebuild_active_order()
end
