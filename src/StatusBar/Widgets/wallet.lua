import "LUI.src.UI.Widgets"

local S = _G.STATUS_BAR_COMMON

local WalletWidget = class(Turbine.UI.Control)
_G.WalletWidget = WalletWidget

local ITEM_GAP = 6
local MIN_FIELD_W = 20

local function _apply_font(label, font, alignment)
    label:SetMouseVisible(false)
    label:SetVisible(true)
    label:SetTextAlignment(alignment)
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

local function _apply_wallet_icon_background(item, background, from_wallet)
    if item == nil or item.icon == nil or background == nil then
        return false
    end
    if from_wallet == true and item.icon_from_wallet == true then
        return false
    end
    if from_wallet ~= true and item.icon_background == background then
        return false
    end

    item.icon_background = background
    item.icon_from_wallet = from_wallet == true
    prepare_background_stretch_mode_1(item.icon, background)
    return true
end

function WalletWidget:Constructor(widget_w, bar_h, font, content_alignment, items)
    Turbine.UI.Control.Constructor(self)

    self.widget_key = "wallet"
    self.player = Turbine.Gameplay.LocalPlayer.GetInstance()
    self.wallet = nil
    self._last_scan_at = 0
    self._scan_every = 1.0
    self._icon_requested = true
    self._render_use_icons = false
    self._content_alignment = content_alignment or Turbine.UI.ContentAlignment.MiddleRight
    self._entries = S.get_wallet_selection_entries(items)
    self._item_controls = {}
    self._last_values = nil

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self:SetSize(widget_w, bar_h)

    self.placeholder = UI.Widgets.LuiLabel()
    self.placeholder:SetParent(self)
    _apply_font(self.placeholder, font, self._content_alignment)

    for i = 1, #self._entries do
        local entry = self._entries[i]
        local item = {
            name = entry,
            icon = nil,
            icon_background = nil,
            icon_from_wallet = false,
            label = UI.Widgets.LuiLabel(),
        }

        item.label:SetParent(self)
        _apply_font(item.label, font, self._content_alignment)

        if self._icon_requested == true then
            item.icon = Turbine.UI.Control()
            item.icon:SetParent(self)
            item.icon:SetMouseVisible(false)
            item.icon:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
            item.icon:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
            item.icon:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
            if item.icon_background ~= nil then
                _apply_wallet_icon_background(item, item.icon_background, false)
            end
            item.icon:SetVisible(false)
        end

        self._item_controls[#self._item_controls + 1] = item
    end

    self.SizeChanged = function()
        self:_layout()
    end

    self:_layout()
    self:_apply_values(nil)
end

function WalletWidget:update(now)
    if now - self._last_scan_at < self._scan_every then
        return
    end
    self._last_scan_at = now

    self:_ensure_wallet()
    self:_apply_values(self:_scan())
end

function WalletWidget:destroy()
    if self.placeholder ~= nil then
        self.placeholder:SetParent(nil)
    end
    for i = 1, #self._item_controls do
        local item = self._item_controls[i]
        if item ~= nil then
            if item.icon ~= nil then item.icon:SetParent(nil) end
            if item.label ~= nil then item.label:SetParent(nil) end
        end
    end
    self:SetParent(nil)
end

function WalletWidget:_ensure_wallet()
    if self.wallet ~= nil then
        return
    end

    local player = self.player
    if player == nil then
        player = Turbine.Gameplay.LocalPlayer.GetInstance()
        self.player = player
    end

    if player == nil or player.GetWallet == nil then
        return
    end

    self.wallet = player:GetWallet()
end

function WalletWidget:_scan()
    local wallet = self.wallet
    if wallet == nil or wallet.GetSize == nil or wallet.GetItem == nil then
        return nil
    end

    local size = wallet:GetSize() or 0
    if type(size) ~= "number" then
        size = tonumber(size) or 0
    end

    local values = {}
    for i = 1, #self._item_controls do
        values[i] = 0
    end

    local layout_dirty = false

    for i = 1, size do
        local item = wallet:GetItem(i)
        if item ~= nil and item.GetName ~= nil then
            local wallet_name = item:GetName()
            local quantity = item.GetQuantity ~= nil and item:GetQuantity() or 0
            if type(quantity) ~= "number" then
                quantity = tonumber(quantity) or 0
            end

            for j = 1, #self._item_controls do
                if S.wallet_item_matches(self._item_controls[j].name, wallet_name) == true then
                    values[j] = quantity
                    if item.GetImage ~= nil then
                        local image = item:GetImage()
                        if image ~= nil then
                            if _apply_wallet_icon_background(self._item_controls[j], image, true) == true then
                                layout_dirty = true
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    if layout_dirty == true then
        self:_layout()
    end

    return values
end

function WalletWidget:_layout()
    local count = #self._item_controls
    local w, h = self:GetSize()

    self.placeholder:SetPosition(0, 0)
    self.placeholder:SetSize(w, h)

    if count == 0 then
        self._render_use_icons = false
        for i = 1, #self._item_controls do
            local item = self._item_controls[i]
            if item.icon ~= nil then item.icon:SetVisible(false) end
            item.label:SetVisible(false)
        end
        if self._last_values ~= nil then
            self:_apply_values(self._last_values)
        end
        return
    end

    local icon_h = S.get_icon_size(h)
    local use_icons = self._icon_requested == true and icon_h > 0
    local icon_total = 0
    local icon_gap_total = 0
    local icon_widths = {}

    if use_icons == true then
        for i = 1, count do
            local item = self._item_controls[i]
            local icon_w = 0
            if item.icon ~= nil and item.icon_background ~= nil then
                icon_w = S.get_background_icon_w(item.icon_background, icon_h)
                if icon_w > 0 then
                    icon_total = icon_total + icon_w
                    icon_gap_total = icon_gap_total + S.ICON_GAP
                end
            end
            icon_widths[i] = icon_w
        end
    end

    local gap_total = ITEM_GAP * math.max(0, count - 1)
    local label_total = w - gap_total - icon_total - icon_gap_total
    if use_icons == true and label_total < (count * MIN_FIELD_W) then
        use_icons = false
        icon_total = 0
        icon_gap_total = 0
        label_total = w - gap_total
    end

    if label_total < 0 then
        label_total = 0
    end

    self._render_use_icons = use_icons

    local field_w = count > 0 and math.floor(label_total / count) or 0
    local extra = count > 0 and (label_total - (field_w * count)) or 0
    local x = 0
    local icon_y = S.get_centered_icon_y(h, icon_h)

    for i = 1, count do
        local item = self._item_controls[i]
        local icon_w = use_icons == true and (icon_widths[i] or 0) or 0

        if item.icon ~= nil then
            if icon_w > 0 then
                item.icon:SetPosition(x, icon_y)
                item.icon:SetSize(icon_w, icon_h)
                item.icon:SetVisible(true)
                x = x + icon_w + S.ICON_GAP
            else
                item.icon:SetVisible(false)
            end
        end

        local current_w = field_w
        if extra > 0 then
            current_w = current_w + 1
            extra = extra - 1
        end

        item.label:SetPosition(x, 0)
        item.label:SetSize(math.max(0, current_w), h)
        item.label:SetVisible(true)
        x = x + current_w

        if i < count then
            x = x + ITEM_GAP
        end
    end

    if self._last_values ~= nil then
        self:_apply_values(self._last_values)
    end
end

function WalletWidget:_apply_values(values)
    self._last_values = values

    local count = #self._item_controls
    if count == 0 then
        self.placeholder:SetVisible(true)
        self.placeholder:SetText(values == nil and "--" or "")
        return
    end

    self.placeholder:SetVisible(false)

    for i = 1, count do
        local item = self._item_controls[i]
        local text = values ~= nil and S.format_wallet_quantity(values[i]) or "--"
        if self._render_use_icons ~= true or item.icon_background == nil then
            text = item.name .. " " .. text
        end
        item.label:SetText(text)
    end
end
