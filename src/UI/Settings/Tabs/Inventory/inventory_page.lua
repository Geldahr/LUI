import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"

local TILE_SIZE_LABELS = {
    TR("Small (32)"),
    TR("Medium (40)"),
    TR("Large (48)"),
}

local TILE_SIZE_VALUES = { 32, 40, 48 }

local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

InventoryPage = class(Turbine.UI.Control)

function InventoryPage:Constructor(window)
    Turbine.UI.Control.Constructor(self)

    self.window = window
    self.show_main_content_border = true
    self:SetMouseVisible(false)

    self.title = UI.Widgets.LuiLabel()
    self.title:SetParent(self)
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.title:SetText(TR("Inventory"))

    self.hr_general = Turbine.UI.Control()
    self.hr_general:SetParent(self)
    self.hr_general:SetMouseVisible(false)
    self.hr_general:SetBackColor(Turbine.UI.Color(0.35, 0.35, 0.35))

    self.general_title = UI.Widgets.LuiLabel()
    self.general_title:SetParent(self)
    self.general_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.general_title:SetText(TR("General"))

    self.enabled = UI.Widgets.LuiCheckBox()
    self.enabled:SetParent(self)
    self.enabled:SetText(TR("Enabled"))

    self.replace = UI.Widgets.LuiCheckBox()
    self.replace:SetParent(self)
    self.replace:SetText(TR("Replace default backpack (I)"))

    self.hr_window = Turbine.UI.Control()
    self.hr_window:SetParent(self)
    self.hr_window:SetMouseVisible(false)
    self.hr_window:SetBackColor(Turbine.UI.Color(0.35, 0.35, 0.35))

    self.window_title = UI.Widgets.LuiLabel()
    self.window_title:SetParent(self)
    self.window_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.window_title:SetText(TR("Window"))

    self.cols_label = UI.Widgets.LuiLabel()
    self.cols_label:SetParent(self)
    self.cols_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.cols_label:SetText(TR("Columns"))

    self.cols_tb = Turbine.UI.Lotro.TextBox()
    self.cols_tb:SetParent(self)
    self.cols_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.hr_tiles = Turbine.UI.Control()
    self.hr_tiles:SetParent(self)
    self.hr_tiles:SetMouseVisible(false)
    self.hr_tiles:SetBackColor(Turbine.UI.Color(0.35, 0.35, 0.35))

    self.tiles_title = UI.Widgets.LuiLabel()
    self.tiles_title:SetParent(self)
    self.tiles_title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.tiles_title:SetText(TR("Tiles"))

    self.tile_size_label = UI.Widgets.LuiLabel()
    self.tile_size_label:SetParent(self)
    self.tile_size_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.tile_size_label:SetText(TR("Tile Size"))

    self.tile_size = UI.Widgets.LuiDropdown()
    self.tile_size:SetParent(self)
    self.tile_size:SetPopupHost(window)
    self.tile_size:SetMappedOptions(TILE_SIZE_LABELS, TILE_SIZE_VALUES)
    self.tile_size:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.SizeChanged = function()
        self:layout()
    end

    self:apply_ui_scale()
end

function InventoryPage:apply_ui_scale()
    local scale = _G.settings.global.scale

    self.title:SetFont(self.window.title_font)
    self.general_title:SetFont(self.window.title_font)
    self.window_title:SetFont(self.window.title_font)
    self.tiles_title:SetFont(self.window.title_font)

    self.cols_label:SetFont(self.window.field_label_font)
    self.tile_size_label:SetFont(self.window.field_label_font)

    self.enabled:SetScale(scale)
    self.enabled:SetFont(self.window.field_label_font)
    self.replace:SetScale(scale)
    self.replace:SetFont(self.window.field_label_font)

    self.cols_tb:SetFont(self.window.input_font)

    self.tile_size:SetScale(scale)
    self.tile_size:SetFont(self.window.input_font)

    self:layout()
end

function InventoryPage:close_all_dropdowns()
    if self.tile_size ~= nil then
        self.tile_size:Close()
    end
end

function InventoryPage:on_selected()
    self:layout()
    if self.cols_tb ~= nil then
        self.cols_tb:SetText(self.cols_tb:GetText() or "")
    end
end

function InventoryPage:load(inv)
    if inv == nil then
        return
    end

    self.enabled:SetChecked(inv.enabled == true)
    self.replace:SetChecked(inv.replace == true)
    self.cols_tb:SetText(tostring(inv.cols))
    self.tile_size:set_value(inv.tile_size)
end

function InventoryPage:apply(inv)
    if inv == nil then
        return
    end

    inv.enabled = self.enabled:IsChecked() == true
    inv.replace = self.replace:IsChecked() == true

    local cols = tonumber(self.cols_tb:GetText())
    if cols ~= nil then
        inv.cols = cols
    end

    inv.tile_size = self.tile_size:get_value()
end

function InventoryPage:load_from_settings(s)
    self:load(s.inventory)
end

function InventoryPage:apply_to_settings(s)
    self:apply(s.inventory)
end

function InventoryPage:layout()
    local w, h = self:GetSize()
    if w == nil or h == nil or w < 1 or h < 1 then
        return
    end

    local pad = self.window.content_padding
    local col_gap = self.window.col_gap
    local row_h = self.window.row_height
    local inner_gap = self.window.inner_gap
    local field_label_h = self.window.field_label_height
    local input_h = self.window.input_height
    local dropdown_y = self.window.dropdown_y_offset
    local title_h = _scaled_int(22)
    local title_gap = _scaled_int(24)
    local hr_top = _scaled_int(3)
    local hr_gap = _scaled_int(6)
    local form_pad = _scaled_int(4)

    local inner_w = w - (pad * 2)
    if inner_w < _scaled_int(74) then
        inner_w = _scaled_int(74)
    end

    local col_w = math.floor((inner_w - col_gap) / 2)
    local label_w = math.floor(col_w * 0.55)
    local input_w = col_w - label_w - inner_gap
    local right_col_x = pad + col_w + col_gap

    local y = form_pad

    self.title:SetPosition(pad, y)
    self.title:SetSize(inner_w, title_h)
    y = y + title_gap

    self.hr_general:SetPosition(pad, y + hr_top)
    self.hr_general:SetSize(inner_w, 1)
    y = y + hr_gap

    self.general_title:SetPosition(pad, y)
    self.general_title:SetSize(inner_w, title_h)
    y = y + title_gap

    self.enabled:SetPosition(pad, y)
    self.enabled:SetSize(col_w, field_label_h)
    self.replace:SetPosition(right_col_x, y)
    self.replace:SetSize(col_w, field_label_h)
    y = y + row_h

    self.hr_window:SetPosition(pad, y + hr_top)
    self.hr_window:SetSize(inner_w, 1)
    y = y + hr_gap

    self.window_title:SetPosition(pad, y)
    self.window_title:SetSize(inner_w, title_h)
    y = y + title_gap

    self.cols_label:SetPosition(pad, y)
    self.cols_label:SetSize(label_w, field_label_h)
    self.cols_tb:SetPosition(pad + label_w + inner_gap, y + math.floor((field_label_h - input_h) / 2))
    self.cols_tb:SetSize(input_w, input_h)
    y = y + row_h

    self.hr_tiles:SetPosition(pad, y + hr_top)
    self.hr_tiles:SetSize(inner_w, 1)
    y = y + hr_gap

    self.tiles_title:SetPosition(pad, y)
    self.tiles_title:SetSize(inner_w, title_h)
    y = y + title_gap

    self.tile_size_label:SetPosition(pad, y)
    self.tile_size_label:SetSize(label_w, field_label_h)
    self.tile_size:SetPosition(pad + label_w + inner_gap, y + math.floor((field_label_h - input_h) / 2) + dropdown_y)
    self.tile_size:SetSize(input_w, input_h)
end
