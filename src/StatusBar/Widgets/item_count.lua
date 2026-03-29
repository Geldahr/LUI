import "LUI.src.UI.Widgets"

local S = _G.STATUS_BAR_COMMON

local ItemCountWidget = class(Turbine.UI.Control)
_G.ItemCountWidget = ItemCountWidget

local BASE_ICON_SIZE = 32
local ITEM_ICON_GAP = 8
local ITEM_ICON_INSET = 2

local function _sanitize_image_id(value)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil or value == 0 then
        return nil
    end
    return value
end

local function _apply_font(label, font)
    label:SetMouseVisible(false)
    label:SetVisible(true)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    if font ~= nil then
        if font.lotro ~= nil then
            label:SetFont(font.lotro)
        end
        if font.style ~= nil then
            label:SetFontStyle(LUI_TO_LOTRO.font_style[font.style] or Turbine.UI.FontStyle.None)
        end
        if font.color ~= nil then
            label:SetForeColor(font.color)
        end
        if font.outline_color ~= nil then
            label:SetOutlineColor(font.outline_color)
        end
    end
end

function ItemCountWidget:Constructor(item_name, widget_w, bar_h, font, icon_image_id)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "item"
    self.item_name = S.normalize_status_bar_item_name(item_name) or ""
    self.item_key = S.make_status_bar_item_registry_key(self.item_name)
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.backpack = nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._last_quantity = nil
    self._icon_image_id = nil
    self._background_image_id = nil

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetSize(widget_w, bar_h)

    self.icon_back = Turbine.UI.Control()
    self.icon_back:SetParent(self)
    self.icon_back:SetMouseVisible(false)
    self.icon_back:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_back:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon_back:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self.icon_back:SetVisible(false)

    self.icon_fallback = Turbine.UI.Control()
    self.icon_fallback:SetParent(self.icon_back)
    self.icon_fallback:SetMouseVisible(false)
    self.icon_fallback:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.icon_fallback:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self.icon_fallback:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self.icon_fallback:SetVisible(false)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self)
    _apply_font(self.label, font)

    self.SizeChanged = function()
        self:_layout()
    end

    self:_set_icon(icon_image_id)
    self:_layout()
    self:_apply_quantity(0)
end

function ItemCountWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    self:_ensure_backpack()
    local quantity, icon_image_id, background_image_id = self:_scan()
    if icon_image_id ~= nil then
        self:_set_icon(icon_image_id)
    end
    if background_image_id ~= nil then
        self:_set_background(background_image_id)
    end
    self:_apply_quantity(quantity or 0)
end

function ItemCountWidget:destroy()
    self:SetVisible(false)
    if self.icon_fallback ~= nil then self.icon_fallback:SetVisible(false) end
    if self.icon_back ~= nil then self.icon_back:SetVisible(false) end
    if self.label ~= nil then self.label:SetVisible(false) end
    if self.icon_fallback ~= nil then self.icon_fallback:SetParent(nil) end
    if self.icon_back ~= nil then self.icon_back:SetParent(nil) end
    if self.label ~= nil then self.label:SetParent(nil) end
    self:SetParent(nil)
end

function ItemCountWidget:_ensure_backpack()
    if self.backpack ~= nil then
        return
    end

    local player = self.player
    if player == nil then
        player = Turbine.Gameplay.LocalPlayer.GetInstance()
        self.player = player
    end

    if player == nil or player.GetBackpack == nil then
        return
    end

    self.backpack = player:GetBackpack()
end

function ItemCountWidget:_item_matches(item_name)
    if item_name == nil or self.item_key == nil then
        return false
    end
    return S.make_status_bar_item_registry_key(item_name) == self.item_key
end

function ItemCountWidget:_scan()
    local backpack = self.backpack
    if backpack == nil or backpack.GetSize == nil or backpack.GetItem == nil then
        return 0, nil, nil
    end

    local total = 0
    local icon_image_id = nil
    local background_image_id = nil
    local size = backpack:GetSize() or 0

    for i = 1, size do
        local item = backpack:GetItem(i)
        if item ~= nil then
            local name = item.GetName ~= nil and item:GetName() or nil
            local current_item_info = item.GetItemInfo ~= nil and item:GetItemInfo() or nil
            if (name == nil or name == "") and current_item_info ~= nil and current_item_info.GetName ~= nil then
                name = current_item_info:GetName()
            end

            if self:_item_matches(name) == true then
                local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 1
                if type(quantity) ~= "number" then
                    quantity = tonumber(quantity) or 0
                end
                if quantity > 0 then
                    total = total + quantity
                end

                if current_item_info ~= nil then
                    if icon_image_id == nil and current_item_info.GetIconImageID ~= nil then
                        icon_image_id = _sanitize_image_id(current_item_info:GetIconImageID())
                    end
                    if background_image_id == nil and current_item_info.GetBackgroundImageID ~= nil then
                        background_image_id = _sanitize_image_id(current_item_info:GetBackgroundImageID())
                    end
                    if background_image_id == nil and current_item_info.GetQualityImageID ~= nil then
                        background_image_id = _sanitize_image_id(current_item_info:GetQualityImageID())
                    end
                end
            end
        end
    end

    return total, icon_image_id, background_image_id
end

function ItemCountWidget:_set_icon(icon_image_id)
    local icon = _sanitize_image_id(icon_image_id)
    if icon == self._icon_image_id then
        return
    end

    self._icon_image_id = icon
    self.icon_fallback:SetBackground(icon)
    self:_layout()
end

function ItemCountWidget:_set_background(background_image_id)
    local background = _sanitize_image_id(background_image_id)
    if background == self._background_image_id then
        return
    end

    self._background_image_id = background
    self.icon_back:SetBackground(background)
    self:_layout()
end

function ItemCountWidget:_apply_quantity(quantity)
    if quantity == self._last_quantity then
        return
    end
    self._last_quantity = quantity
    self.label:SetText(S.format_wallet_quantity(quantity))
end

function ItemCountWidget:_layout()
    local w, h = self:GetSize()
    local icon_size = h - ITEM_ICON_INSET
    if icon_size < 0 then
        icon_size = 0
    end

    local show_icon = (self._icon_image_id ~= nil or self._background_image_id ~= nil) and icon_size > 0

    if show_icon == true then
        self.icon_back:SetPosition(0, S.get_centered_icon_y(h, icon_size))
        if self.icon_back.SetStretchMode ~= nil then
            self.icon_back:SetStretchMode(0)
        end
        self.icon_back:SetSize(BASE_ICON_SIZE, BASE_ICON_SIZE)
        if self.icon_back.SetStretchMode ~= nil and icon_size ~= BASE_ICON_SIZE then
            self.icon_back:SetStretchMode(1)
        end
        self.icon_back:SetSize(icon_size, icon_size)
        self.icon_back:SetVisible(true)

        self.icon_fallback:SetPosition(0, 0)
        self.icon_fallback:SetSize(BASE_ICON_SIZE, BASE_ICON_SIZE)
        self.icon_fallback:SetBlendMode(self._background_image_id ~= nil and Turbine.UI.BlendMode.Overlay or Turbine.UI.BlendMode.AlphaBlend)
        self.icon_fallback:SetVisible(self._icon_image_id ~= nil)
    else
        self.icon_back:SetVisible(false)
        self.icon_fallback:SetVisible(false)
    end

    local text_x = 0
    if show_icon == true then
        text_x = icon_size + ITEM_ICON_GAP
    end

    self.label:SetPosition(text_x, 0)
    self.label:SetSize(math.max(0, w - text_x), h)
end
