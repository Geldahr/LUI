local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _require_font = Common.require_font
local _sync_preview_holder_height = Common.sync_preview_holder_height

local BASE_ROW_PADDING = 4
local BASE_GAP = 6
local BASE_QTY_WIDTH = 46
local BASE_FONT_SIZE = 12
local BASE_SPACING = 0

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

local function _create_row(parent)
    local row = {}

    row.root = Turbine.UI.Control()
    row.root:SetParent(parent)
    row.root:SetMouseVisible(false)

    row.background = Turbine.UI.Control()
    row.background:SetParent(row.root)
    row.background:SetMouseVisible(false)
    _set_alpha_backdrop(row.background)

    row.icon = Turbine.UI.Control()
    row.icon:SetParent(row.root)
    row.icon:SetMouseVisible(false)
    _set_alpha_backdrop(row.icon)

    row.name = UI.Widgets.LuiLabel()
    row.name:SetParent(row.root)
    row.name:SetMouseVisible(false)
    row.name:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    row.qty = UI.Widgets.LuiLabel()
    row.qty:SetParent(row.root)
    row.qty:SetMouseVisible(false)
    row.qty:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    return row
end

function ConfigWindow:init_drops_preview()
    local holder = self.controls.drops_preview
    if holder == nil or holder.control == nil then
        return
    end
    if self.drops_preview ~= nil then
        return
    end

    self.drops_preview = {}
    local p = self.drops_preview
    p.container = holder.control
    p.background = Turbine.UI.Control()
    p.background:SetParent(p.container)
    p.background:SetMouseVisible(false)
    _set_alpha_backdrop(p.background)

    p.rows = {
        _create_row(p.container),
        _create_row(p.container),
        _create_row(p.container),
    }

    p.container.SizeChanged = function()
        self:update_drops_preview()
    end

    self:update_drops_preview()
end

function ConfigWindow:update_drops_preview()
    if self.drops_preview == nil then
        self:init_drops_preview()
    end
    if self.drops_preview == nil then
        return
    end

    local p = self.drops_preview
    local s = _G.loaded_settings
    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then
        raw_scale = 1
    end

    local function scaled_int(raw_value)
        return math.floor((raw_value * raw_scale) + 0.5)
    end

    local width = tonumber(self.controls.drops_width.tb:GetText()) or s.drops.width or 180
    width = scaled_int(width)
    if width < 140 then
        width = 140
    end
    local rows = tonumber(self.controls.drops_rows.tb:GetText()) or s.drops.rows or 4
    rows = math.max(1, math.floor(rows + 0.5))
    local icon_size = self.controls.drops_icon_size.get_value and self.controls.drops_icon_size:get_value() or
        s.drops.icon_size or 32
    local row_pad = scaled_int(BASE_ROW_PADDING)
    local row_h = scaled_int(icon_size) + (2 * row_pad)
    local icon_side = scaled_int(icon_size)
    local gap = scaled_int(BASE_GAP)
    local qty_w = scaled_int(BASE_QTY_WIDTH)
    local spacing = scaled_int(BASE_SPACING)
    local preview_rows = math.min(3, rows)
    local block_h = (preview_rows * row_h) + ((preview_rows - 1) * spacing)

    _sync_preview_holder_height(self, self.controls.drops_preview, block_h + 8)

    local holder_w, holder_h = p.container:GetSize()
    if holder_w < width then
        width = holder_w
    end
    if width < 1 then
        width = 1
    end

    local flow = self.controls.drops_flow.get_value and self.controls.drops_flow:get_value() or s.drops.flow
    local hud_color = _hex_to_color(self.controls.drops_hud_background_color.tb:GetText()) or
        s.drops.hud.background_color or Turbine.UI.Color(1, 0, 0, 0)
    local hud_opacity = tonumber(self.controls.drops_hud_background_opacity.tb:GetText()) or
        s.drops.hud.background_opacity or 0.0
    local item_color = _hex_to_color(self.controls.drops_item_background_color.tb:GetText()) or
        s.drops.item.background_color or Turbine.UI.Color(1, 0, 0, 0)
    local item_opacity = tonumber(self.controls.drops_item_background_opacity.tb:GetText()) or
        s.drops.item.background_opacity or 0.3

    local font = _require_font(LUI_ENUMS.font_name.VERDANA, BASE_FONT_SIZE * raw_scale)
    local y0 = 4
    if flow == LUI_ENUMS.list_flow.BOTTOM_TO_TOP then
        y0 = math.max(0, holder_h - block_h)
    end

    p.background:SetVisible(true)
    p.background:SetPosition(0, y0)
    p.background:SetSize(width, block_h)
    p.background:SetBackColor(_with_alpha(hud_color, hud_opacity))

    local samples = nil
    if flow == LUI_ENUMS.list_flow.TOP_TO_BOTTOM then
        samples = {
            { name = "Exceptional Hide", qty = "1", icon = true },
            { name = "Traveller's Steel-bound Lootbox", qty = "1", icon = false },
            { name = "Calenard Hide", qty = "3", icon = true },
        }
    else
        samples = {
            { name = "Traveller's Steel-bound Lootbox", qty = "1", icon = false },
            { name = "Exceptional Hide", qty = "1", icon = true },
            { name = "Calenard Hide", qty = "3", icon = true },
        }
    end

    for i = 1, #p.rows do
        local row = p.rows[i]
        local sample = samples[i]
        if sample == nil or i > preview_rows then
            row.root:SetVisible(false)
        else
            local y = y0 + ((i - 1) * (row_h + spacing))
            row.root:SetVisible(true)
            row.root:SetPosition(0, y)
            row.root:SetSize(width, row_h)
            row.background:SetPosition(0, 0)
            row.background:SetSize(width, row_h)
            row.background:SetBackColor(_with_alpha(item_color, item_opacity))
            row.icon:SetPosition(row_pad, row_pad)
            row.icon:SetSize(icon_side, icon_side)
            row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))
            row.icon:SetVisible(sample.icon == true)
            row.name:SetFont(font)
            row.name:SetFontStyle(Turbine.UI.FontStyle.Outline)
            row.name:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
            row.name:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
            row.name:SetText(sample.name)
            row.name:SetPosition(row_pad + icon_side + gap, row_pad)
            local qty_x = width - row_pad - qty_w
            row.name:SetSize(math.max(1, qty_x - (row_pad + icon_side + gap) - gap), row_h - (2 * row_pad))
            row.qty:SetFont(font)
            row.qty:SetFontStyle(Turbine.UI.FontStyle.Outline)
            row.qty:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
            row.qty:SetOutlineColor(Turbine.UI.Color(1, 0, 0, 0))
            row.qty:SetText(sample.qty)
            row.qty:SetPosition(qty_x, row_pad)
            row.qty:SetSize(qty_w, row_h - (2 * row_pad))
        end
    end
end
