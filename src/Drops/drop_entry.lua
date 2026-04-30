import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.UI.Widgets.base_window"

local BASE_ROW_PADDING = 4
local BASE_GAP = 6
local BASE_QTY_WIDTH = 46
local BASE_FONT_SIZE = 12

local function _scaled_font(name, size)
    local font = FONT_TO_LOTRO(name, size * _G.settings.global.scale)
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(size * _G.settings.global.scale))
    end
    return font
end

local function _with_alpha(color, alpha)
    if color == nil then
        return Turbine.UI.Color(alpha, 1, 1, 1)
    end
    return Turbine.UI.Color(alpha, color.R, color.G, color.B)
end

local function _set_alpha_backdrop(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

DropEntry = class(LuiBaseWindow)

function DropEntry:Constructor()
    LuiBaseWindow.Constructor(self, { hideable = true })

    self.record = nil
    self._item_bound = nil
    self._opacity = 1
    self._row_height = 0
    self._icon_side = 0
    self._padding = 0
    self._gap = 0
    self._qty_width = 0
    self._width = 0

    self:SetZOrder(0)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetMouseVisible(false)
    self:SetVisible(false)

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetMouseVisible(false)
    _set_alpha_backdrop(self.background)

    self.icon_host = Turbine.UI.Control()
    self.icon_host:SetParent(self)
    self.icon_host:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_host:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_host:SetMouseVisible(false)

    self.item_control = Turbine.UI.Lotro.ItemControl()
    self.item_control:SetParent(self.icon_host)
    self.item_control:SetVisible(false)
    self.item_control:SetMouseVisible(false)
    self.item_control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.item_control:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    if self.item_control.SetStretchMode ~= nil then
        self.item_control:SetStretchMode(1)
    end
    if self.item_control.SetAllowDrop ~= nil then
        self.item_control:SetAllowDrop(false)
    end

    self.name_label = UI.Widgets.LuiLabel()
    self.name_label:SetParent(self)
    self.name_label:SetMouseVisible(false)
    self.name_label:SetSelectable(false)
    self.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    self.qty_label = UI.Widgets.LuiLabel()
    self.qty_label:SetParent(self)
    self.qty_label:SetMouseVisible(false)
    self.qty_label:SetSelectable(false)
    self.qty_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    self:apply_settings()
end

function DropEntry:apply_settings()
    local s = _G.settings.drops
    self._padding = lui_scaled_int(BASE_ROW_PADDING)
    self._row_height = s.icon_size + (2 * self._padding)
    self._icon_side = s.icon_size
    self._gap = lui_scaled_int(BASE_GAP)
    self._qty_width = lui_scaled_int(BASE_QTY_WIDTH)
    self._width = s.width

    self:SetSize(self._width, self._row_height)
    self.background:SetPosition(0, 0)
    self.background:SetSize(self._width, self._row_height)
    self.background:SetBackColor(_with_alpha(s.item.background_color, s.item.background_opacity))

    self.icon_host:SetPosition(self._padding, self._padding)
    self.icon_host:SetSize(self._icon_side, self._icon_side)

    self.item_control:SetPosition(0, 0)
    self.item_control:SetSize(self._icon_side + 1, self._icon_side + 1)

    local font = _scaled_font("Verdana", BASE_FONT_SIZE)
    self.name_label:SetFont(font)
    self.name_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.name_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    self.name_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    self.qty_label:SetFont(font)
    self.qty_label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.qty_label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    self.qty_label:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))

    local content_h = self._row_height - (2 * self._padding)
    local qty_x = self._width - self._padding - self._qty_width
    self.qty_label:SetPosition(qty_x, self._padding)
    self.qty_label:SetSize(self._qty_width, content_h)

    local text_x = self._padding + self._icon_side + self._gap
    local text_w = qty_x - text_x - self._gap
    if text_w < 1 then
        text_w = 1
    end
    self.name_label:SetPosition(text_x, self._padding)
    self.name_label:SetSize(text_w, content_h)

    self:_apply_record()
end

function DropEntry:set_record(record)
    self.record = record
    self:_apply_record()
end

function DropEntry:set_live_item(item)
    if self.record == nil then
        return
    end
    self.record.live_item = item
    self:_apply_item()
end

function DropEntry:set_opacity(opacity)
    self._opacity = opacity

    self:SetOpacity(opacity)
end

function DropEntry:destroy()
    self:set_record(nil)
    self:unregister_hideable()
    self:SetVisible(false)
    self:SetParent(nil)
end

function DropEntry:_apply_record()
    local record = self.record
    if record == nil then
        self.name_label:SetText("")
        self.qty_label:SetText("")
        self:_bind_item(nil)
        self:SetVisible(false)
        return
    end

    self:SetVisible(true)
    self.name_label:SetText(record.name)
    self.qty_label:SetText(tostring(record.quantity or 1))
    self:set_opacity(self._opacity)
    self:_apply_item()
end

function DropEntry:_apply_item()
    local record = self.record
    if record == nil then
        self:_bind_item(nil)
        return
    end
    self:_bind_item(record.live_item)
end

function DropEntry:_bind_item(item)
    if self._item_bound == item then
        return
    end

    self._item_bound = item

    if item == nil then
        self:SetMouseVisible(false)
        self.icon_host:SetMouseVisible(false)
        self.item_control:SetMouseVisible(false)
        self.item_control:SetVisible(false)
        -- LotRO item handles can go stale while the row is still visible.
        pcall(function()
            self.item_control:SetItem(nil)
        end)
        return
    end

    self:SetMouseVisible(true)
    self.icon_host:SetMouseVisible(true)
    self.item_control:SetMouseVisible(true)
    self.item_control:SetVisible(true)
    -- Bind through the game control directly so hover/tooltip behavior matches inventory.
    pcall(function()
        self.item_control:SetItem(item)
    end)
end
