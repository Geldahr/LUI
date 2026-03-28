local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _require_font = Common.require_font

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

    row.label = UI.Widgets.LuiLabel()
    row.label:SetParent(row.bar_background)
    row.label:SetMouseVisible(false)
    row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

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

    local text_template = self.controls.expiring_effects_text_template and
        self.controls.expiring_effects_text_template.tb and self.controls.expiring_effects_text_template.tb:GetText() or
        nil
    if type(text_template) ~= "string" then
        text_template = s.self.expiring_effects.text_template or "%n  %t"
    end
    if string.len(text_template) == 0 then
        text_template = "%n  %t"
    end
    local text_template_tokens = lui_tokenize_format(text_template)
    local text_alignment = self.controls.expiring_effects_text_alignment.get_value and
        self.controls.expiring_effects_text_alignment:get_value() or nil
    if type(text_alignment) ~= "number" then
        text_alignment = s.self.expiring_effects.text_alignment or LUI_ENUMS.text_alignment.LEFT
    end

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
    if holder.height ~= desired_height then
        holder.height = desired_height
        self:layout()
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    local function truncate_name(name, max_chars)
        local n = tostring(name or "")
        local m = max_chars
        if type(m) ~= "number" then
            m = tonumber(m)
        end
        if m == nil or m <= 0 then
            return n
        end
        m = math.floor(m + 0.5)
        if m < 1 then
            return ""
        end
        if string.len(n) <= m then
            return n
        end
        if m >= 4 then
            return string.sub(n, 1, m - 3) .. "..."
        end
        return string.sub(n, 1, m)
    end

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

        local label_pad = 3
        local label_width = bar_inner_w - (2 * label_pad)
        if label_width < 1 then label_width = 1 end
        row.label:SetPosition(label_pad, 0)
        row.label:SetSize(label_width, inner_height)
        row.label:SetFont(font)
        row.label:SetFontStyle(font_style)
        row.label:SetTextAlignment(text_align(text_alignment))
        row.label:SetForeColor(font_color)
        row.label:SetOutlineColor(outline_color)
        local truncated = truncate_name(effect_name, name_max_chars)
        row.label:SetText(lui_format_tokenized(text_template_tokens, { n = truncated, t = lui_format_timeout(remaining) }))

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

    apply_row(p.buff, x, y, TR("Buff"), buff_bar_color)
    apply_row(p.debuff_curable, x, y + bh + row_spacing, TR("Curable Debuff"), curable_debuff_bar_color)
    apply_row(p.debuff_noncurable, x, y + (2 * (bh + row_spacing)), TR("Non-curable Debuff"), noncurable_debuff_bar_color)
end
