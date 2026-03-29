local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _require_font = Common.require_font

function ConfigWindow:init_cooldowns_preview()
    local holder = self.controls.cooldowns_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.cooldowns_preview ~= nil then
        return
    end

    self.cooldowns_preview = {}
    local p = self.cooldowns_preview
    p.container = holder.control
    p.preview_border_thickness = 1

    p.container.SizeChanged = function()
        self:update_cooldowns_preview()
    end

    local function create_row()
        local row = {}

        row.preview = Turbine.UI.Control()
        row.preview:SetParent(p.container)
        row.preview:SetMouseVisible(false)

        row.preview_top = Turbine.UI.Control()
        row.preview_top:SetParent(row.preview)
        row.preview_top:SetMouseVisible(false)
        row.preview_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_bottom = Turbine.UI.Control()
        row.preview_bottom:SetParent(row.preview)
        row.preview_bottom:SetMouseVisible(false)
        row.preview_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_left = Turbine.UI.Control()
        row.preview_left:SetParent(row.preview)
        row.preview_left:SetMouseVisible(false)
        row.preview_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.preview_right = Turbine.UI.Control()
        row.preview_right:SetParent(row.preview)
        row.preview_right:SetMouseVisible(false)
        row.preview_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

        row.border = Turbine.UI.Control()
        row.border:SetParent(row.preview)
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

        row.separator = Turbine.UI.Control()
        row.separator:SetParent(row.entry)
        row.separator:SetMouseVisible(false)

        row.bar_background = Turbine.UI.Control()
        row.bar_background:SetParent(row.entry)
        row.bar_background:SetMouseVisible(false)

        row.bar_fill = Turbine.UI.Control()
        row.bar_fill:SetParent(row.bar_background)
        row.bar_fill:SetMouseVisible(false)

        row.label = UI.Widgets.LuiLabel()
        row.label:SetParent(row.bar_background)
        row.label:SetMouseVisible(false)
        row.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        row.label:SetText("")

        row.icon_background = Turbine.UI.Control()
        row.icon_background:SetParent(row.entry)
        row.icon_background:SetMouseVisible(false)

        row.icon = Turbine.UI.Control()
        row.icon:SetParent(row.icon_background)
        row.icon:SetMouseVisible(false)
        row.icon:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

        return row
    end

    p.row = create_row()
    self:update_cooldowns_preview()
end

function ConfigWindow:update_cooldowns_preview()
    if self.cooldowns_preview == nil then
        self:init_cooldowns_preview()
    end
    if self.cooldowns_preview == nil then
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

    local cd = s.self.cooldowns

    local raw_item_w = tonumber(self.controls.cd_item_w.tb:GetText()) or cd.item_w or 150
    local raw_item_h = tonumber(self.controls.cd_item_h.tb:GetText()) or cd.item_h or 26
    local item_w = scaled_int(raw_item_w, 150)
    local item_h = scaled_int(raw_item_h, 26)
    if item_w < 10 then item_w = 10 end
    if item_h < 10 then item_h = 10 end

    local bg = _hex_to_color(self.controls.cd_bg_color.tb:GetText())
        or (cd.color and cd.color.background)
        or Turbine.UI.Color(0, 0, 0)
    local bar = _hex_to_color(self.controls.cd_bar_color.tb:GetText())
        or (cd.color and cd.color.bar)
        or Turbine.UI.Color(1, 0.0, 0.545098, 0.545098)
    local border_color = _hex_to_color(self.controls.cd_border_color.tb:GetText())
        or (cd.color and cd.color.border)
        or Turbine.UI.Color(1, 0, 0, 0)

    local raw_border_w = tonumber(self.controls.cd_border_width.tb:GetText()) or cd.border_width or 1
    local border = scaled_border(raw_border_w, 1)
    if border < 0 then border = 0 end

    local icon_side = self.controls.cd_icon_side.get_value and self.controls.cd_icon_side:get_value() or nil
    if type(icon_side) ~= "number" then
        icon_side = cd.icon_side or LUI_ENUMS.side.RIGHT
    end
    local icon_left = LUI_ENUMS.side_is_left[icon_side] == true

    local bar_expire_towards = self.controls.cd_bar_expire_towards.get_value and
        self.controls.cd_bar_expire_towards:get_value() or nil
    if type(bar_expire_towards) ~= "number" then
        bar_expire_towards = cd.bar_expire_towards or LUI_ENUMS.side.RIGHT
    end

    local bar_mode = self.controls.cd_bar_mode.get_value and self.controls.cd_bar_mode:get_value() or nil
    if type(bar_mode) ~= "number" then
        bar_mode = cd.bar_mode or LUI_ENUMS.bar_mode.UNLOAD
    end

    local text_template = self.controls.cd_text_template.tb:GetText()
    if type(text_template) ~= "string" or text_template == "" then
        text_template = cd.text_template or "%name% - %t"
    end
    local text_template_tokens = lui_tokenize_format(text_template)

    local text_alignment = self.controls.cd_text_alignment.get_value and self.controls.cd_text_alignment:get_value() or nil
    if type(text_alignment) ~= "number" then
        text_alignment = cd.text_alignment or LUI_ENUMS.text_alignment.CENTER
    end

    local raw_text_margin = tonumber(self.controls.cd_text_margin.tb:GetText()) or cd.text_margin or 4
    local text_margin = scaled_int(raw_text_margin, 4)
    if text_margin < 0 then text_margin = 0 end

    local font_name = self.controls.cd_font_name.get_value and self.controls.cd_font_name:get_value() or nil
    if type(font_name) ~= "number" then
        font_name = cd.font.name or LUI_ENUMS.font_name.VERDANA
    end
    local raw_font_size = tonumber(self.controls.cd_font_size.tb:GetText()) or cd.font.size or 14
    local font_size = scaled_number(raw_font_size, 14)
    local font = _require_font(font_name, font_size)

    local font_style = self.controls.cd_font_style.get_value and self.controls.cd_font_style:get_value() or nil
    if type(font_style) ~= "number" then
        font_style = cd.font.style or LUI_ENUMS.font_style.OUTLINE
    end
    local font_style_lotro = LUI_TO_LOTRO.font_style[font_style] or Turbine.UI.FontStyle.None

    local font_color = _hex_to_color(self.controls.cd_font_color.tb:GetText())
        or (cd.font and cd.font.color)
        or Turbine.UI.Color(1, 1, 1, 1)
    local outline_color = _hex_to_color(self.controls.cd_font_outline_color.tb:GetText())
        or (cd.font and cd.font.outline_color)
        or Turbine.UI.Color(1, 0, 0, 0)

    local row = self.cooldowns_preview.row
    local p = self.cooldowns_preview

    local outer_bw = p.preview_border_thickness or 1
    if outer_bw < 1 then outer_bw = 1 end

    local pw, ph = p.container:GetSize()

    local show_w = item_w
    local show_h = item_h

    local max_show_w = pw - (2 * outer_bw)
    local max_show_h = ph - (2 * outer_bw)
    if max_show_w < 1 then max_show_w = 1 end
    if max_show_h < 1 then max_show_h = 1 end

    if show_w > max_show_w then show_w = max_show_w end
    if show_h > max_show_h then show_h = max_show_h end
    if show_w < 1 then show_w = 1 end
    if show_h < 1 then show_h = 1 end

    local bw_draw = border
    if bw_draw * 2 >= show_w then bw_draw = math.floor((show_w - 1) / 2) end
    if bw_draw * 2 >= show_h then bw_draw = math.floor((show_h - 1) / 2) end
    if bw_draw < 0 then bw_draw = 0 end

    local preview_w = show_w + (2 * outer_bw)
    local preview_h = show_h + (2 * outer_bw)

    local off_x = math.max(0, math.floor((pw - preview_w) / 2))
    local off_y = math.max(0, math.floor((ph - preview_h) / 2))

    row.preview:SetPosition(off_x, off_y)
    row.preview:SetSize(preview_w, preview_h)

    row.preview_top:SetPosition(0, 0)
    row.preview_top:SetSize(preview_w, outer_bw)
    row.preview_bottom:SetPosition(0, preview_h - outer_bw)
    row.preview_bottom:SetSize(preview_w, outer_bw)
    row.preview_left:SetPosition(0, 0)
    row.preview_left:SetSize(outer_bw, preview_h)
    row.preview_right:SetPosition(preview_w - outer_bw, 0)
    row.preview_right:SetSize(outer_bw, preview_h)

    row.border:SetPosition(outer_bw, outer_bw)
    row.border:SetSize(show_w, show_h)

    row.border_top:SetBackColor(border_color)
    row.border_bottom:SetBackColor(border_color)
    row.border_left:SetBackColor(border_color)
    row.border_right:SetBackColor(border_color)

    row.border_top:SetPosition(0, 0)
    row.border_top:SetSize(show_w, bw_draw)
    row.border_bottom:SetPosition(0, show_h - bw_draw)
    row.border_bottom:SetSize(show_w, bw_draw)
    row.border_left:SetPosition(0, 0)
    row.border_left:SetSize(bw_draw, show_h)
    row.border_right:SetPosition(show_w - bw_draw, 0)
    row.border_right:SetSize(bw_draw, show_h)

    local inner_x = bw_draw
    local inner_y = bw_draw
    local inner_w = show_w - (2 * bw_draw)
    local inner_h = show_h - (2 * bw_draw)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    row.entry:SetPosition(inner_x, inner_y)
    row.entry:SetSize(inner_w, inner_h)

    local sep_w = bw_draw
    if sep_w < 0 then sep_w = 0 end
    if sep_w >= inner_w then sep_w = inner_w - 1 end
    if sep_w < 0 then sep_w = 0 end

    local icon_size = inner_h
    local max_icon = inner_w - sep_w - 1
    if max_icon < 1 then max_icon = 1 end
    if icon_size > max_icon then
        icon_size = max_icon
    end

    local bar_width = inner_w - icon_size - sep_w
    if bar_width < 1 then bar_width = 1 end

    row.separator:SetBackColor(border_color)
    row.separator:SetVisible(sep_w > 0)

    if icon_left then
        row.icon_background:SetPosition(0, 0)
        row.icon_background:SetSize(icon_size, icon_size)
        row.icon_background:SetBackColor(bg)

        row.separator:SetPosition(icon_size, 0)
        row.separator:SetSize(sep_w, inner_h)

        row.bar_background:SetPosition(icon_size + sep_w, 0)
    else
        row.bar_background:SetPosition(0, 0)

        row.separator:SetPosition(bar_width, 0)
        row.separator:SetSize(sep_w, inner_h)

        row.icon_background:SetPosition(bar_width + sep_w, 0)
        row.icon_background:SetSize(icon_size, icon_size)
        row.icon_background:SetBackColor(bg)
    end

    row.bar_background:SetSize(bar_width, inner_h)
    row.bar_background:SetBackColor(bg)

    local bar_inner_w = bar_width
    local bar_inner_h = inner_h

    local threshold = tonumber(self.controls.cd_threshold.tb:GetText()) or cd.threshold or 30
    if threshold <= 0 then threshold = 30 end

    local total = threshold * 1.4
    if total < 3 then total = 3 end

    local base = total
    if base > threshold then
        base = threshold
    end

    local remaining = base * 0.6
    local ratio = remaining / base
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local percent = ratio
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - ratio
    end

    local fill_width = math.floor(bar_inner_w * percent + 0.5)
    if fill_width < 0 then fill_width = 0 end
    if fill_width > bar_inner_w then fill_width = bar_inner_w end

    local towards_right = bar_expire_towards == LUI_ENUMS.side.RIGHT
    local anchor_right = towards_right
    if bar_mode == LUI_ENUMS.bar_mode.LOAD then
        anchor_right = towards_right ~= true
    end

    if anchor_right then
        row.bar_fill:SetPosition(bar_inner_w - fill_width, 0)
    else
        row.bar_fill:SetPosition(0, 0)
    end
    row.bar_fill:SetSize(fill_width, bar_inner_h)
    row.bar_fill:SetBackColor(bar)

    row.label:SetFont(font)
    row.label:SetFontStyle(font_style_lotro)
    row.label:SetForeColor(font_color)
    row.label:SetOutlineColor(outline_color)
    row.label:SetTextAlignment(LUI_TO_LOTRO.text_alignment[text_alignment] or Turbine.UI.ContentAlignment.MiddleCenter)

    row.label:SetPosition(text_margin, 0)
    row.label:SetSize(math.max(1, bar_inner_w - (2 * text_margin)), inner_h)

    row.icon:SetPosition(0, 0)
    row.icon:SetSize(icon_size, icon_size)

    local time_t = lui_format_timeout(remaining)
    local time_s = lui_format_timeout_seconds(remaining)
    local ctx = {
        name = TR("Example skill"),
        t = time_t,
        s = time_s,
        n = TR("Example skill"),
        ts = time_s,
    }

    row.label:SetText(lui_format_tokenized(text_template_tokens, ctx))
end
