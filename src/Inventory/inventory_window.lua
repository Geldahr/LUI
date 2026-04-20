import "Turbine.Gameplay"
import "Turbine.UI"

import "LUI.src.UI.Widgets"
import "LUI.src.Inventory.filter"
import "LUI.src.Inventory.slot"
import "LUI.src.Utils.font"
import "LUI.src.Utils.number_abbrev"
import "LUI.src.Settings.enums"

InventoryWindow = class(LuiWindow)

local MARGIN_LEFT = 15
local MARGIN_TOP = 11
local MARGIN_RIGHT = 15
local MARGIN_BOTTOM = 6
local FILTER_H = 21
local BASE_MONEY_H = 24
local MONEY_GAP = 3
local BASE_HINT_GAP = 6
local BASE_HINT_H = 34
-- local ACTION_H = 28 -- Lock/whitelist UI row (disabled for now)
local BAR_GAP = 4
local FILTER_GAP = 4
local CLEAR_W = 52
local MIN_WINDOW_W = 193
local MIN_WINDOW_H = 148
local RESIZE_LEFT = 1
local RESIZE_TOP = 4

local BASE_HINT_FONT_SIZE = 12
local BASE_FILTER_FONT_SIZE = 10

local function _scaled_size(value)
    return value * _G.settings.global.scale
end

local function _scaled_int(value)
    return math.floor(_scaled_size(value) + 0.5)
end

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(size)))
    end
    return font
end

local function _has_resize_dir(mask, dir)
    return math.floor((mask or 0) / dir) % 2 == 1
end

local GOLD_ICON = Turbine.UI.Graphic(0x41007e7b)
local SILVER_ICON = Turbine.UI.Graphic(0x41007e7c)
local COPPER_ICON = Turbine.UI.Graphic(0x41007e7d)

-- Locking is intentionally disabled for now (API is unreliable/missing on some clients).
-- Keep the old code commented for future re-enable.
-- local function _is_locked(item)
--     if item == nil then
--         return false
--     end
--     if item.IsLocked ~= nil then
--         return item:IsLocked() == true
--     end
--     if item.GetLocked ~= nil then
--         return item:GetLocked() == true
--     end
--     return false
-- end
--
-- local function _set_locked(item, locked)
--     if item == nil then
--         return false
--     end
--     if item.SetLocked ~= nil then
--         item:SetLocked(locked == true)
--         return true
--     end
--     if locked == true and item.Lock ~= nil then
--         item:Lock()
--         return true
--     end
--     if locked ~= true and item.Unlock ~= nil then
--         item:Unlock()
--         return true
--     end
--     return false
-- end

local function _get_item_description(item)
    if item == nil then
        return ""
    end

    if item.GetItemInfo ~= nil then
        local ok_info, info = pcall(function()
            return item:GetItemInfo()
        end)
        if ok_info == true and info ~= nil and info.GetDescription ~= nil then
            local ok_desc, desc = pcall(function()
                return info:GetDescription()
            end)
            if ok_desc == true and desc ~= nil then
                desc = tostring(desc)
                if desc ~= "" then
                    return desc
                end
            end
        end
    end

    return ""
end

local function _split_money_copper(total_copper)
    if total_copper == nil then
        return nil
    end

    local gold = math.floor(total_copper / 100000)
    local silver = math.floor(total_copper / 100) - gold * 1000
    local copper = total_copper - gold * 100000 - silver * 100
    return gold, silver, copper
end

local function _format_gold_compact(gold)
    return lui_abbrev_gold(gold)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function InventoryWindow:Constructor()
    LuiWindow.Constructor(self)

    self:set_title(TR["Inventory"])
    self:set_icon(UI.AssetIds.backpack)
    self:set_resizable(LuiWindow.RESIZE_HORIZONTAL)
    self:hide()
    self:SetWantsUpdates(false)

    self.last_update_at = 0
    self.update_every = 1.0 / _G.settings.global.refresh_rate
    self._dirty = true
    self._filter_dirty = true
    self._haystack_dirty = false
    self._display_dirty = true

    self._suppress_size_changed = false

    self.tile_size = 40
    self.cols = 10
    self.rows_visible = 6
    self.margin_left = MARGIN_LEFT
    self.margin_top = MARGIN_TOP
    self.margin_right = MARGIN_RIGHT
    self.margin_bottom = MARGIN_BOTTOM
    self.filter_h = FILTER_H
    self.money_h = BASE_MONEY_H
    self.money_gap = MONEY_GAP
    self.bar_gap = BAR_GAP
    self.filter_gap = FILTER_GAP
    self.clear_w = CLEAR_W
    self.hint_gap = BASE_HINT_GAP
    self.hint_h = BASE_HINT_H
    self.header_h = FILTER_H + BASE_MONEY_H + MONEY_GAP

    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = self.player ~= nil and self.player:GetBackpack() or nil
    self._last_bp_size = nil

    self.filter_groups = {}
    -- self.lock_mode = false -- disabled for now
    self._slot_bind_offset = nil

    local content = self:get_content_host()

    self.header = Turbine.UI.Control()
    self.header:SetParent(content)

    self.g_icon = Image(GOLD_ICON)
    self.g_icon:SetParent(self.header)

    self.s_icon = Image(SILVER_ICON)
    self.s_icon:SetParent(self.header)

    self.c_icon = Image(COPPER_ICON)
    self.c_icon:SetParent(self.header)

    local function make_money_label()
        local l = UI.Widgets.LuiLabel()
        l:SetParent(self.header)
        l:SetMouseVisible(false)
        l:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        l:SetText("--")
        return l
    end

    self.g_label = make_money_label()
    self.s_label = make_money_label()
    self.c_label = make_money_label()

    self._last_money = nil

    self.filter_tb = UI.Widgets.LineEdit()
    self.filter_tb:SetParent(self.header)
    self.filter_tb:SetFont(_scaled_font("Verdana", BASE_FILTER_FONT_SIZE))
    self.filter_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.filter_tb:set_placeholder_text(TR["Search..."])

    self.clear_button = UI.Widgets.LuiButton()
    self.clear_button:SetParent(self.header)
    self.clear_button:set_font(_scaled_font("Verdana", BASE_FILTER_FONT_SIZE))
    self.clear_button:set_text(TR["Clear"])
    self.clear_button.Click = function()
        self.filter_tb:SetText("")
        self:update_filter()
        self.filter_tb:Focus()
    end

    -- Lock mode + whitelist/blacklist actions are intentionally disabled for now.
    -- Keep the old UI construction commented for future re-enable.
    -- self.lock_cb = UI.Widgets.LuiCheckBox()
    -- self.lock_cb:SetParent(self.header)
    -- self.lock_cb:SetFont(LABEL_FONT)
    -- self.lock_cb:SetText(" " .. TR["Lock mode"])
    -- self.lock_cb.CheckedChanged = function()
    --     self:set_lock_mode(self.lock_cb:IsChecked() == true)
    -- end
    --
    -- self.action_bar = Turbine.UI.Control()
    -- self.action_bar:SetParent(self)
    -- self.action_bar:SetVisible(false)
    --
    -- local function make_action(text, fn)
    --     local b = UI.Widgets.LuiButton()
    --     b:SetParent(self.action_bar)
    --     b:SetFont(BUTTON_FONT)
    --     b:SetText(text)
    --     b.Click = fn
    --     return b
    -- end
    --
    -- self.lock_matches = make_action(TR["Lock matches"], function()
    --     self:apply_lock_filter(true, true)
    -- end)
    -- self.unlock_matches = make_action(TR["Unlock matches"], function()
    --     self:apply_lock_filter(true, false)
    -- end)
    -- self.lock_nonmatches = make_action(TR["Lock non-matches"], function()
    --     self:apply_lock_filter(false, true)
    -- end)
    -- self.unlock_nonmatches = make_action(TR["Unlock non-matches"], function()
    --     self:apply_lock_filter(false, false)
    -- end)

    self.list = Turbine.UI.ListBox()
    self.list:SetParent(content)
    self.list:SetOrientation(Turbine.UI.Orientation.Vertical)

    self.hint_label = UI.Widgets.LuiLabel()
    self.hint_label:SetParent(content)
    self.hint_label:SetMouseVisible(false)
    self.hint_label:SetSelectable(false)
    self.hint_label:SetForeColor(Turbine.UI.Color(0.65, 0.65, 0.65))
    self.hint_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.hint_label:SetMultiline(true)
    self.hint_label:SetFont(_scaled_font("Verdana", BASE_HINT_FONT_SIZE))
    self.hint_label:SetText(
        TR["Hint: to lock/unlock an item you can select it using Alt+Left click and then press Ctrl+T to toggle the lock."]
    )

    self.rows = {}
    self.slots = {}

    self.filter_tb.TextChanged = function()
        self:update_filter()
    end

    self.SizeChanged = function()
        LuiWindow._layout(self)
        if self._suppress_size_changed then
            return
        end
        self:handle_user_resize()
    end

    self.VisibleChanged = function()
        local visible = self:IsVisible() == true
        self:SetWantsUpdates(visible)
        if visible then
            self.last_update_at = 0
            self._dirty = true
            self._filter_dirty = true
            self._display_dirty = true
            self:bring_to_front()
        end
    end

    self:hook_backpack_events()
    self:apply_settings()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function InventoryWindow:bring_to_front()
    if self:IsVisible() == true and self.Activate ~= nil then
        self:Activate()
    end
end

function InventoryWindow:capture_geometry()
    local raw = _G.loaded_settings.inventory
    self:capture_window_geometry(raw.window)
    if self:is_maximized() ~= true then
        raw.cols = self.cols
    end
end

function InventoryWindow:persist_geometry()
    self:capture_geometry()
end

function InventoryWindow:get_needed_rows(cols)
    local c = cols
    if type(c) ~= "number" then
        c = tonumber(c)
    end
    if c == nil or c < 1 then
        c = 1
    end
    c = math.floor(c + 0.5)

    local size = 0
    if self.backpack ~= nil and self.backpack.GetSize ~= nil then
        size = self.backpack:GetSize() or 0
    end
    if size < 1 then
        size = 1
    end

    return math.floor((size + c - 1) / c)
end

function InventoryWindow:hook_backpack_events()
    if self.backpack == nil then
        return
    end
    local function dirty()
        self._filter_dirty = true
        self._haystack_dirty = true
        self._display_dirty = true
    end
    self.backpack.ItemAdded = dirty
    self.backpack.ItemRemoved = dirty
    self.backpack.ItemMoved = dirty
    self.backpack.ItemChanged = dirty
end

function InventoryWindow:update_filter()
    local q = self.filter_tb:GetText() or ""
    local groups = parse_query(q)
    self.filter_groups = normalize_groups(groups)

    self._filter_dirty = true
end

function InventoryWindow:get_item(index)
    if self.backpack == nil then
        return nil
    end
    if self.backpack.GetItem ~= nil then
        return self.backpack:GetItem(index)
    end
    return nil
end

function InventoryWindow:layout()
    local w, h = self:get_content_size()
    local min_w = _scaled_int(MIN_WINDOW_W)
    local min_h = _scaled_int(MIN_WINDOW_H)
    if w < min_w then w = min_w end
    if h < min_h then h = min_h end

    self.header:SetPosition(self.margin_left, self.margin_top)
    self.header:SetSize(w - self.margin_left - self.margin_right, self.header_h)

    local money_h = self.money_h
    local icon_size = money_h
    local gap = self.money_gap
    local field_w = icon_size * 2
    local total_w = (icon_size * 3) + (gap * 4) + (field_w * 3)
    local x = math.floor((self.header:GetWidth() - total_w) / 2)
    if x < 0 then x = 0 end
    local y = 0

    self.g_icon:SetPosition(x, y + 1)
    self.g_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.g_label:SetPosition(x, y)
    self.g_label:SetSize(field_w, money_h)
    x = x + field_w + gap

    self.s_icon:SetPosition(x, y + 1)
    self.s_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.s_label:SetPosition(x, y)
    self.s_label:SetSize(field_w, money_h)
    x = x + field_w + gap

    self.c_icon:SetPosition(x, y + 1)
    self.c_icon:set_size(icon_size, icon_size)
    x = x + icon_size + gap
    self.c_label:SetPosition(x, y)
    self.c_label:SetSize(field_w, money_h)

    local clear_w = self.clear_w
    local gap = self.filter_gap

    local filter_y = money_h + self.money_gap

    self.clear_button:SetPosition(self.header:GetWidth() - clear_w, filter_y)
    self.clear_button:SetSize(clear_w, self.filter_h)

    local filter_w = self.header:GetWidth() - clear_w - gap
    if filter_w < _scaled_int(59) then
        filter_w = _scaled_int(59)
    end
    self.filter_tb:SetPosition(0, filter_y)
    self.filter_tb:SetSize(filter_w, self.filter_h)

    local list_y = self.margin_top + self.header_h + self.bar_gap
    local list_h = h - self.margin_bottom - self.hint_h - self.hint_gap - list_y
    if list_h < _scaled_int(30) then list_h = _scaled_int(30) end

    local list_w = w - self.margin_left - self.margin_right
    if list_w < _scaled_int(30) then list_w = _scaled_int(30) end

    self.list:SetPosition(self.margin_left, list_y)
    self.list:SetSize(list_w, list_h)

    self.hint_label:SetPosition(self.margin_left, list_y + list_h + self.hint_gap)
    self.hint_label:SetSize(list_w, self.hint_h)
end

function InventoryWindow:compute_window_size(cols, rows)
    local grid_w = cols * self.tile_size
    local grid_h = rows * self.tile_size

    local content_w = self.margin_left + self.margin_right + grid_w
    local content_h = self.margin_top + self.margin_bottom + self.header_h + self.bar_gap + self.hint_gap + self.hint_h + grid_h
    return self:get_window_size_for_content(content_w, content_h)
end

function InventoryWindow:minimum_window_size()
    return self:get_window_size_for_content(_scaled_int(MIN_WINDOW_W), _scaled_int(MIN_WINDOW_H))
end

function InventoryWindow:apply_resize_candidate(window_x, window_y, window_w, window_h)
    local content_w = self:get_content_size_for_window(window_w, window_h)
    local list_w = content_w - self.margin_left - self.margin_right

    local cols = math.floor(list_w / self.tile_size)
    if cols < 6 then cols = 6 end
    if cols > 20 then cols = 20 end

    local rows = self:get_needed_rows(cols)
    local raw = _G.loaded_settings.inventory
    local changed = cols ~= self.cols or rows ~= self.rows_visible

    self.cols = cols
    self.rows_visible = rows
    if self:is_maximized() ~= true then
        raw.cols = cols
    end

    local desired_w, desired_h = self:compute_window_size(cols, rows)
    local min_w, min_h = self:minimum_window_size()
    if desired_w < min_w then desired_w = min_w end
    if desired_h < min_h then desired_h = min_h end

    local mask = self._resize_mask or 0
    if _has_resize_dir(mask, RESIZE_LEFT) then
        window_x = window_x + window_w - desired_w
    end
    if _has_resize_dir(mask, RESIZE_TOP) then
        window_y = window_y + window_h - desired_h
    end

    window_x, window_y, desired_w, desired_h = self:_clamp_resize_to_screen(window_x, window_y, desired_w, desired_h)

    local old_suppress = self._suppress_size_changed
    self._suppress_size_changed = true
    self:SetPosition(window_x, window_y)
    self:SetSize(desired_w, desired_h)
    self._suppress_size_changed = old_suppress

    self:layout()
    if changed == true then
        self:build_grid()
    end
    self._dirty = true
    self._filter_dirty = true
    self._display_dirty = true
end

function InventoryWindow:update_money()
    local total = self:_get_total_money()
    if total == self._last_money then
        return
    end
    self._last_money = total
    local gold, silver, copper = _split_money_copper(total)
    if gold == nil then
        self.g_label:SetText("--")
        self.s_label:SetText("--")
        self.c_label:SetText("--")
        return
    end
    self.g_label:SetText(_format_gold_compact(gold))
    self.s_label:SetText(tostring(silver))
    self.c_label:SetText(tostring(copper))
end

function InventoryWindow:apply_settings()
    LuiWindow.apply_settings(self)

    local s = _G.settings.inventory
    self.update_every = 1.0 / _G.settings.global.refresh_rate
    self.tile_size = s.tile_size
    self.cols = s.cols
    self.rows_visible = self:get_needed_rows(self.cols)

    self.margin_left = _scaled_int(MARGIN_LEFT)
    self.margin_top = _scaled_int(MARGIN_TOP)
    self.margin_right = _scaled_int(MARGIN_RIGHT)
    self.margin_bottom = _scaled_int(MARGIN_BOTTOM)
    self.filter_h = _scaled_int(FILTER_H)
    self.money_gap = _scaled_int(MONEY_GAP)
    self.bar_gap = _scaled_int(BAR_GAP)
    self.filter_gap = _scaled_int(FILTER_GAP)
    self.clear_w = _scaled_int(CLEAR_W)
    local scale = _G.settings.global.scale
    self.money_h = math.floor((BASE_MONEY_H * scale) + 0.5)
    self.hint_gap = math.floor((BASE_HINT_GAP * scale) + 0.5)
    self.hint_h = math.floor((BASE_HINT_H * scale) + 0.5)
    self.header_h = self.filter_h + self.money_h + self.money_gap

    local sb_font = _G.settings.status_bar.font
    local money_font_size = BASE_MONEY_H * _G.settings.global.scale
    local money_font = FONT_TO_LOTRO(sb_font.name, money_font_size)
    local font_style = LUI_TO_LOTRO.font_style[sb_font.style] or Turbine.UI.FontStyle.None

    self.g_label:SetFont(money_font)
    self.s_label:SetFont(money_font)
    self.c_label:SetFont(money_font)
    self.g_label:SetFontStyle(font_style)
    self.s_label:SetFontStyle(font_style)
    self.c_label:SetFontStyle(font_style)
    self.g_label:SetForeColor(sb_font.color)
    self.s_label:SetForeColor(sb_font.color)
    self.c_label:SetForeColor(sb_font.color)
    self.g_label:SetOutlineColor(sb_font.outline_color)
    self.s_label:SetOutlineColor(sb_font.outline_color)
    self.c_label:SetOutlineColor(sb_font.outline_color)

    local filter_font = _scaled_font("Verdana", BASE_FILTER_FONT_SIZE)
    self.filter_tb:SetFont(filter_font)
    self.clear_button:set_font(filter_font)

    local hint_font_size = math.floor((BASE_HINT_FONT_SIZE * scale) + 0.5)
    local hint_font = FONT_TO_LOTRO("Verdana", hint_font_size)
    self.hint_label:SetFont(hint_font)

    local raw = _G.loaded_settings.inventory
    self:SetPosition(raw.window.left, raw.window.top)

    local w, h = self:compute_window_size(self.cols, self.rows_visible)
    local min_w, min_h = self:minimum_window_size()
    self:set_minimum_size(min_w, min_h)
    if w < min_w then w = min_w end
    if h < min_h then h = min_h end
    self._suppress_size_changed = true
    self:SetSize(w, h)
    self._suppress_size_changed = false
    if raw.window.maximized == true then
        raw.window.width = w
        raw.window.height = h
    end
    self:apply_maximize_state(raw.window)

    self:layout()
    self:build_grid()
    self:update_money()
    self._dirty = true
    self._filter_dirty = true
    self._display_dirty = true
end

function InventoryWindow:handle_user_resize()
    local window_w, window_h = self:GetSize()
    local window_x, window_y = self:GetPosition()
    self:apply_resize_candidate(window_x, window_y, window_w, window_h)
end

function InventoryWindow:_apply_resize_bounds(x, y, w, h, region, args)
    self:apply_resize_candidate(x, y, w, h)
end

function InventoryWindow:build_grid()
    if self.backpack == nil or self.backpack.GetSize == nil then
        return
    end

    local size = self.backpack:GetSize() or 0
    if size < 0 then size = 0 end

    local cols = self.cols
    if cols < 1 then cols = 1 end
    local row_count = math.floor((size + cols - 1) / cols)
    if row_count < 1 then
        row_count = 1
    end

    local grid_w = cols * self.tile_size

    while #self.rows > row_count do
        local row = table.remove(self.rows)
        if row ~= nil then
            self.list:RemoveItem(row)
        end
    end

    while #self.rows < row_count do
        local row = Turbine.UI.Control()
        row:SetSize(grid_w, self.tile_size)
        row:SetMouseVisible(true)
        table.insert(self.rows, row)
        self.list:AddItem(row)
    end

    for r = 1, #self.rows do
        local row = self.rows[r]
        row:SetSize(grid_w, self.tile_size)
    end

    for i = 1, size do
        local slot = self.slots[i]
        if slot == nil then
            slot = InventorySlot(i, nil, function(dest_index, drag_drop_info, args)
                self:perform_drop(dest_index, drag_drop_info, args)
            end)
            self.slots[i] = slot
        end

        slot:set_tile(self.tile_size)
        -- slot:set_lock_mode(self.lock_mode) -- disabled for now

        local r = math.floor((i - 1) / cols) + 1
        local c = ((i - 1) % cols) + 1

        local parent = self.rows[r]
        slot:SetParent(parent)
        if slot.set_grid_edges ~= nil then
            slot:set_grid_edges(r == 1, c == 1)
        end
        slot:SetPosition((c - 1) * self.tile_size, 0)
    end

    for i = size + 1, #self.slots do
        local slot = self.slots[i]
        if slot ~= nil then
            slot:SetParent(nil)
        end
    end
end

function InventoryWindow:perform_drop(dest_index, drag_drop_info, args)
    if self.backpack == nil or drag_drop_info == nil then
        return
    end
    if drag_drop_info.GetShortcut == nil or self.backpack.PerformShortcutDrop == nil then
        return
    end

    local ok, shortcut = pcall(function()
        return drag_drop_info:GetShortcut()
    end)
    if not ok or shortcut == nil then
        return
    end

    local split = false
    if args ~= nil then
        if args.ShiftKeyDown ~= nil then
            split = args.ShiftKeyDown == true
        elseif args.Shift ~= nil then
            split = args.Shift == true
        end
    end
    if split ~= true and Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Control ~= nil and Turbine.UI.Control.IsShiftKeyDown ~= nil then
        pcall(function()
            split = Turbine.UI.Control.IsShiftKeyDown() == true
        end)
    end

    pcall(function()
        self.backpack:PerformShortcutDrop(shortcut, dest_index, split == true)
    end)

    -- local offset = self._drop_index_offset
    -- if offset == 0 or offset == -1 then
    --     pcall(function()
    --         self.backpack:PerformShortcutDrop(shortcut, dest_index + offset)
    --     end)
    -- else
    --     local ok1 = pcall(function()
    --         self.backpack:PerformShortcutDrop(shortcut, dest_index)
    --     end)
    --     if ok1 == true then
    --         self._drop_index_offset = 0
    --     elseif type(dest_index) == "number" and dest_index > 0 then
    --         local ok0 = pcall(function()
    --             self.backpack:PerformShortcutDrop(shortcut, dest_index - 1)
    --         end)
    --         if ok0 == true then
    --             self._drop_index_offset = -1
    --         end
    --     end
    -- end

    self._filter_dirty = true
    self._haystack_dirty = true
    self._display_dirty = true
end

function InventoryWindow:update_slots()
    if self.backpack == nil or self.backpack.GetSize == nil then
        return
    end

    local size = self.backpack:GetSize() or 0
    local groups = self.filter_groups
    local need_filter = groups ~= nil and #groups > 0
    local force_filter = self._filter_dirty == true
    local force_haystack = self._haystack_dirty == true
    local force_display = self._display_dirty == true
    local any_change = false

    for i = 1, size do
        local slot = self.slots[i]
        if slot ~= nil then
            local item = self:get_item(i)
            local qty = 1
            if item ~= nil and item.GetQuantity ~= nil then
                qty = item:GetQuantity() or 1
            end
            if qty < 1 then
                item = nil
                qty = 0
                -- local is_empty = false
                -- if item == nil or item.GetName == nil then
                --     is_empty = true
                -- else
                --     local ok_name, name = pcall(function() return item:GetName() end)
                --     if ok_name ~= true or name == nil or name == "" then
                --         is_empty = true
                --     end
                -- end
                -- if is_empty then
                --     item = nil
                --     qty = 0
                -- else
                --     qty = 1
                -- end
            end
            local item_changed = item ~= slot.item
            if item_changed then
                slot.item = item
                slot.qty = nil
                slot.haystack_lower = nil
                any_change = true
            end

            if (force_display or item_changed or slot._display_bound ~= true) and slot.item_control ~= nil and slot.item_control.SetItem ~= nil then
                pcall(function()
                    slot.item_control:SetItem(item)
                end)
                slot._display_bound = true
            end

            if qty ~= (slot.qty or 1) then
                slot.qty = qty
                any_change = true
            end

            local matched = true
            if need_filter then
                if item == nil then
                    matched = false
                else
                    local need_rebuild = slot.haystack_lower == nil or item_changed or force_haystack
                    if need_rebuild then
                        local name = (item.GetName ~= nil) and (item:GetName() or "") or ""
                        local desc = _get_item_description(item)
                        slot.haystack_lower = string.lower(name .. "\n" .. desc)
                    end
                    if force_filter or need_rebuild then
                        matched = matches_groups(groups, slot.haystack_lower or "")
                    else
                        matched = slot.matched == true
                    end
                end
            end
            if matched ~= (slot.matched == true) then
                slot.matched = matched
                slot:set_matched(matched)
                any_change = true
            end

            -- Dimming/clearing is done via icon opacity (more reliable than an overlay).
            -- Also prevents stale icon artifacts after SetItem(nil).
            if slot.item_control ~= nil and slot.item_control.SetOpacity ~= nil then
                local target_opacity
                if item == nil then
                    target_opacity = 0.001
                elseif matched ~= true then
                    target_opacity = 0.25
                else
                    target_opacity = 1
                end
                if slot._icon_opacity ~= target_opacity then
                    slot._icon_opacity = target_opacity
                    slot.item_control:SetOpacity(target_opacity)
                end
            end
        end
    end

    self._filter_dirty = false
    self._haystack_dirty = false
    self._display_dirty = false
end

function InventoryWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    if (now - (self.last_update_at or 0)) < self.update_every then
        return
    end
    self.last_update_at = now

    if self._dirty then
        self:build_grid()
        self._filter_dirty = true
        self._dirty = false
    end
    self:update_slots()
    self:update_money()
end

function InventoryWindow:open()
    self:show()
end

function InventoryWindow:toggle()
    LuiWindow.toggle(self)
    if self:IsVisible() then
        self._dirty = true
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function InventoryWindow:_get_total_money()
    local p = self.player
    if p == nil or p.GetAttributes == nil then
        return nil
    end
    local a = p:GetAttributes()
    if a == nil or a.GetMoney == nil then
        return nil
    end
    return a:GetMoney()
end

-- Locking is intentionally disabled for now (API is unreliable/missing on some clients).
-- Keep the old code commented for future re-enable.
--
-- function InventoryWindow:set_lock_mode(enabled)
--     self.lock_mode = enabled == true
--     for i = 1, #self.slots do
--         local slot = self.slots[i]
--         if slot ~= nil then
--             slot:set_lock_mode(self.lock_mode)
--         end
--     end
-- end
--
-- function InventoryWindow:toggle_lock(index)
--     local item = self:get_item(index)
--     if item == nil then
--         return
--     end
--     local locked = _is_locked(item)
--     if _set_locked(item, not locked) then
--         self._display_dirty = true
--     end
-- end
--
-- function InventoryWindow:apply_lock_filter(want_match, locked)
--     local q = self.filter_tb:GetText() or ""
--     if string.len((q:gsub("%s+", ""))) == 0 then
--         return
--     end
--
--     self:update_slots()
--
--     for i = 1, #self.slots do
--         local slot = self.slots[i]
--         if slot ~= nil then
--             local is_match = slot.matched == true
--             if (want_match and is_match) or ((not want_match) and (not is_match)) then
--                 local item = self:get_item(i)
--                 if item ~= nil then
--                     _set_locked(item, locked == true)
--                 end
--             end
--         end
--     end
--     self._dirty = true
--     self._display_dirty = true
-- end
