import "LUI.src.Utils.timed_row_layout"

local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _require_font = Common.require_font
local _sync_preview_holder_height = Common.sync_preview_holder_height

local LABEL_PAD = 3
local EFFECT_TIME_FORMAT = lui_timed_row_time_format.AUTO

local function _truncate_name(name, max_chars)
    local value = tostring(name or "")
    local m = max_chars
    if type(m) ~= "number" then
        m = tonumber(m)
    end
    if m == nil or m <= 0 then
        return value
    end

    m = math.floor(m + 0.5)
    if m < 1 then
        return ""
    end
    if string.len(value) <= m then
        return value
    end
    if m >= 4 then
        return string.sub(value, 1, m - 3) .. "..."
    end
    return string.sub(value, 1, m)
end

local function _create_row(container)
    local row = {}

    row.border = Turbine.UI.Control()
    row.border:SetParent(container)
    row.border:SetMouseVisible(false)

    row.border_top = Turbine.UI.Control()
    row.border_top:SetParent(row.border)
    row.border_top:SetMouseVisible(false)
    row.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_bottom = Turbine.UI.Control()
    row.border_bottom:SetParent(row.border)
    row.border_bottom:SetMouseVisible(false)
    row.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_left = Turbine.UI.Control()
    row.border_left:SetParent(row.border)
    row.border_left:SetMouseVisible(false)
    row.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.border_right = Turbine.UI.Control()
    row.border_right:SetParent(row.border)
    row.border_right:SetMouseVisible(false)
    row.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    row.entry = Turbine.UI.Control()
    row.entry:SetParent(row.border)
    row.entry:SetMouseVisible(false)

    row.bar_border = Turbine.UI.Control()
    row.bar_border:SetParent(row.entry)
    row.bar_border:SetMouseVisible(false)

    row.bar_background = Turbine.UI.Control()
    row.bar_background:SetParent(row.bar_border)
    row.bar_background:SetMouseVisible(false)

    row.bar_fill = Turbine.UI.Control()
    row.bar_fill:SetParent(row.bar_background)
    row.bar_fill:SetMouseVisible(false)

    row.name_label = UI.Widgets.LuiLabel()
    row.name_label:SetParent(row.bar_background)
    row.name_label:SetMouseVisible(false)
    row.name_label:SetMultiline(true)
    row.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    row.name_label:SetText("")

    row.time_label = UI.Widgets.LuiLabel()
    row.time_label:SetParent(row.bar_background)
    row.time_label:SetMouseVisible(false)
    row.time_label:SetMultiline(false)
    row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    row.time_label:SetText("")

    row.icon_border = Turbine.UI.Control()
    row.icon_border:SetParent(row.entry)
    row.icon_border:SetMouseVisible(false)

    row.icon_background = Turbine.UI.Control()
    row.icon_background:SetParent(row.icon_border)
    row.icon_background:SetMouseVisible(false)

    row.icon = Turbine.UI.Control()
    row.icon:SetParent(row.icon_background)
    row.icon:SetMouseVisible(false)
    row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

    return row
end

function ConfigWindow:init_expiring_effects_preview()
    local holder = self.controls.expiring_effects_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.expiring_effects_preview ~= nil then
        return
    end

    self.expiring_effects_preview = {}
    local p = self.expiring_effects_preview
    p.container = holder.control
    p.buff = _create_row(p.container)
    p.debuff_curable = _create_row(p.container)
    p.debuff_noncurable = _create_row(p.container)

    self:update_expiring_effects_preview()
end

function ConfigWindow:update_expiring_effects_preview()
    if self.expiring_effects_preview == nil then
        self:init_expiring_effects_preview()
    end
    if self.expiring_effects_preview == nil then
        return
    end

    local s = _G.loaded_settings

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or s.global.scale or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return math.floor((n * raw_scale) + 0.5)
    end

    local function scaled_border(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
        if n <= 0 then
            return 0
        end
        local out = math.floor(n * raw_scale)
        if out < 1 then out = 1 end
        return out
    end

    local function scaled_number(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then n = fallback or 0 end
        return n * raw_scale
    end

    local raw_border = tonumber(self.controls.expiring_effects_border_width.tb:GetText()) or
        s.self.expiring_effects.border_width or 1
    local border = scaled_border(raw_border, 1)
    if border < 0 then border = 0 end

    local raw_bar_width = tonumber(self.controls.expiring_effects_bar_width.tb:GetText()) or
        s.self.expiring_effects.bar_width or 180
    local raw_bar_height = tonumber(self.controls.expiring_effects_bar_height.tb:GetText()) or
        s.self.expiring_effects.bar_height or 22
    local bar_width = scaled_int(raw_bar_width, 180)
    local bar_height = scaled_int(raw_bar_height, 22)
    if bar_width < 10 then bar_width = 10 end
    if bar_height < 10 then bar_height = 10 end
    local max_border = math.floor(math.min(bar_width, bar_height) / 2)
    if border > max_border then border = max_border end

    local background_color = _hex_to_color(self.controls.expiring_effects_background_color.tb:GetText())
        or (s.self.expiring_effects.color and s.self.expiring_effects.color.background)
        or Turbine.UI.Color(0, 0, 0)
    local border_color = _hex_to_color(self.controls.expiring_effects_border_color.tb:GetText())
        or (s.self.expiring_effects.color and s.self.expiring_effects.color.border)
        or background_color
    local buff_bar_color = _hex_to_color(self.controls.expiring_effects_bar_color.tb:GetText())
        or (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_buff or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.7, 0.2)
    local curable_debuff_bar_color = _hex_to_color(self.controls.expiring_effects_debuff_curable_bar_color.tb:GetText())
        or
        (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_debuff_curable or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)
    local noncurable_debuff_bar_color = _hex_to_color(self.controls.expiring_effects_debuff_noncurable_bar_color.tb
            :GetText())
        or
        (s.self.expiring_effects.color and (s.self.expiring_effects.color.bar_debuff_noncurable or s.self.expiring_effects.color.bar))
        or Turbine.UI.Color(0.9, 0.25, 0.25)

    local icon_side = self.controls.expiring_effects_icon_side.get_value and
        self.controls.expiring_effects_icon_side:get_value() or nil
    if type(icon_side) ~= "number" then
        icon_side = s.self.expiring_effects.icon_side or LUI_ENUMS.side.RIGHT
    end
    local icon_left = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = self.controls.expiring_effects_bar_expire_towards.get_value and
        self.controls.expiring_effects_bar_expire_towards:get_value() or nil
    if type(bar_expire_towards) ~= "number" then
        bar_expire_towards = s.self.expiring_effects.bar_expire_towards or LUI_ENUMS.side.RIGHT
    end
    local expire_towards_right = bar_expire_towards == LUI_ENUMS.side.RIGHT

    local name_max_chars = tonumber(self.controls.expiring_effects_name_max_chars and
            self.controls.expiring_effects_name_max_chars.tb and
            self.controls.expiring_effects_name_max_chars.tb:GetText() or
            "")
        or s.self.expiring_effects.name_max_chars
        or 10

    local font_name = self.controls.expiring_effects_font_name.get_value and
        self.controls.expiring_effects_font_name:get_value() or nil
    if type(font_name) ~= "number" then
        font_name = s.self.expiring_effects.font.name or LUI_ENUMS.font_name.VERDANA
    end
    local raw_font_size = tonumber(self.controls.expiring_effects_font_size.tb:GetText()) or
        s.self.expiring_effects.font.size or 14
    local font_size = scaled_number(raw_font_size, 14)
    local font = _require_font(font_name, font_size)

    local style_enum = self.controls.expiring_effects_font_style.get_value and
        self.controls.expiring_effects_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
    local font_style = LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None

    local font_color = _hex_to_color(self.controls.expiring_effects_font_color.tb:GetText()) or Turbine.UI.Color(1, 1, 1)
    local outline_color = _hex_to_color(self.controls.expiring_effects_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)

    local threshold = tonumber(self.controls.expiring_effects_threshold.tb:GetText()) or
        s.self.expiring_effects.threshold or 5
    if threshold <= 0 then threshold = 5 end
    local remaining = threshold / 2

    local min_bar_width = lui_timed_row_min_timed_bar_width(
        border,
        LABEL_PAD,
        font_name,
        font_size,
        threshold,
        EFFECT_TIME_FORMAT
    )
    if bar_width < min_bar_width then
        bar_width = min_bar_width
    end

    local icon_size = bar_height
    local entry_width = bar_width + icon_size
    local entry_height = bar_height
    local preview_border = 1
    if border > 1 then
        preview_border = 2
    end

    local holder = self.controls.expiring_effects_preview
    local row_spacing = scaled_int(6, 6)
    local bw = entry_width + (2 * preview_border)
    local bh = entry_height + (2 * preview_border)

    local desired_height = (3 * bh) + (2 * row_spacing) + 12
    if desired_height < 80 then desired_height = 80 end
    _sync_preview_holder_height(self, holder, desired_height)

    local time_width = lui_timed_row_time_label_width(font_name, font_size, threshold, EFFECT_TIME_FORMAT)
    local text_gap = lui_timed_row_text_gap(font_size)

    local function apply_row(row, x, y, effect_name, row_bar_color)
        row.border:SetSize(bw, bh)
        row.border:SetPosition(x, y)

        row.entry:SetPosition(preview_border, preview_border)
        row.entry:SetSize(entry_width, entry_height)

        row.border_top:SetPosition(0, 0)
        row.border_top:SetSize(bw, preview_border)
        row.border_bottom:SetPosition(0, bh - preview_border)
        row.border_bottom:SetSize(bw, preview_border)
        row.border_left:SetPosition(0, 0)
        row.border_left:SetSize(preview_border, bh)
        row.border_right:SetPosition(bw - preview_border, 0)
        row.border_right:SetSize(preview_border, bh)

        row.bar_border:SetPosition(icon_left and icon_size or 0, 0)
        row.bar_border:SetSize(bar_width, bar_height)
        row.bar_border:SetBackColor(border_color)

        row.icon_border:SetPosition(icon_left and 0 or bar_width, 0)
        row.icon_border:SetSize(icon_size, icon_size)
        row.icon_border:SetBackColor(border_color)

        local inner_width = bar_width - (2 * border)
        local inner_height = bar_height - (2 * border)
        if inner_width < 1 then inner_width = 1 end
        if inner_height < 1 then inner_height = 1 end

        local bar_inner_w = bar_width - border
        if bar_inner_w < 1 then bar_inner_w = 1 end

        local preview_fill_width = math.floor(inner_width * 0.5 + 0.5)
        if preview_fill_width < 0 then preview_fill_width = 0 end
        if preview_fill_width > inner_width then preview_fill_width = inner_width end
        local bar_bg_x = icon_left and 0 or border
        row.bar_background:SetPosition(bar_bg_x, border)
        row.bar_background:SetSize(bar_inner_w, inner_height)
        row.bar_background:SetBackColor(background_color)

        if expire_towards_right then
            row.bar_fill:SetPosition(bar_inner_w - preview_fill_width, 0)
        else
            row.bar_fill:SetPosition(0, 0)
        end
        row.bar_fill:SetSize(preview_fill_width, inner_height)
        row.bar_fill:SetBackColor(row_bar_color)

        local title_width = bar_inner_w - (2 * LABEL_PAD) - time_width - text_gap
        if title_width < 1 then title_width = 1 end
        local time_x = LABEL_PAD + title_width + text_gap

        row.name_label:SetPosition(LABEL_PAD, 0)
        row.name_label:SetSize(title_width, inner_height)
        row.name_label:SetFont(font)
        row.name_label:SetFontStyle(font_style)
        row.name_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        row.name_label:SetForeColor(font_color)
        row.name_label:SetOutlineColor(outline_color)
        row.name_label:SetText(_truncate_name(effect_name, name_max_chars))

        row.time_label:SetPosition(time_x, 0)
        row.time_label:SetSize(time_width, inner_height)
        row.time_label:SetFont(font)
        row.time_label:SetFontStyle(font_style)
        row.time_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
        row.time_label:SetForeColor(font_color)
        row.time_label:SetOutlineColor(outline_color)
        row.time_label:SetText(lui_timed_row_format_time(remaining, EFFECT_TIME_FORMAT))

        local icon_inner = icon_size - (2 * border)
        if icon_inner < 1 then icon_inner = 1 end
        row.icon_background:SetPosition(border, border)
        row.icon_background:SetSize(icon_inner, icon_inner)
        row.icon_background:SetBackColor(background_color)

        row.icon:SetPosition(0, 0)
        row.icon:SetSize(icon_inner, icon_inner)
    end

    local p = self.expiring_effects_preview
    local cw, ch = p.container:GetSize()
    local group_height = (3 * bh) + (2 * row_spacing)
    local x = math.floor((cw - bw) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - group_height) / 2)
    if y < 0 then y = 0 end

    apply_row(p.buff, x, y, TR["Buff"], buff_bar_color)
    apply_row(p.debuff_curable, x, y + bh + row_spacing, TR["Curable Debuff"], curable_debuff_bar_color)
    apply_row(p.debuff_noncurable, x, y + (2 * (bh + row_spacing)), TR["Non-curable Debuff"], noncurable_debuff_bar_color)
end
