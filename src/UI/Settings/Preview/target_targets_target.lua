local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _dim_color = Common.dim_color
local _require_font = Common.require_font
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local DEFAULT_GRADIENT_MID_COLOR = Common.default_gradient_mid_color

function ConfigWindow:init_target_targets_target_preview()
    local holder = self.controls.target_targets_target_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.target_targets_target_preview ~= nil then
        return
    end

    self.target_targets_target_preview = {
        container = holder.control,
    }

    local p = self.target_targets_target_preview
    p.container:SetMouseVisible(false)

    p.outer = Turbine.UI.Control()
    p.outer:SetParent(p.container)
    p.outer:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.outer)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.outer)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.outer)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.outer)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.outer)
    p.root:SetMouseVisible(false)

    p.background = Turbine.UI.Control()
    p.background:SetParent(p.root)
    p.background:SetMouseVisible(false)

    p.morale = Turbine.UI.Control()
    p.morale:SetParent(p.background)
    p.morale:SetMouseVisible(false)
    p.morale:SetZOrder(1)

    p.bubble = Turbine.UI.Control()
    p.bubble:SetParent(p.background)
    p.bubble:SetMouseVisible(false)
    p.bubble:SetZOrder(2)
    p.bubble:SetVisible(false)

    p.label = UI.Widgets.LuiLabel()
    p.label:SetParent(p.root)
    p.label:SetMouseVisible(false)
    p.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    p.label:SetZOrder(10)
end

function ConfigWindow:update_target_targets_target_preview()
    if self.active_tab ~= "target_targets_target" then
        return
    end

    local p = self.target_targets_target_preview
    if p == nil then
        self:init_target_targets_target_preview()
        p = self.target_targets_target_preview
    end
    if p == nil then
        return
    end

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local function scaled_int(raw_value, fallback)
        local n = tonumber(raw_value)
        if n == nil then
            n = fallback or 0
        end
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
        if n == nil then
            n = fallback or 0
        end
        return n * raw_scale
    end

    local function text_align(value)
        return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local frame_w = scaled_int(tonumber(self.controls.target_targets_target_width.tb:GetText()), 250)
    local border = scaled_border(tonumber(self.controls.target_targets_target_border_width.tb:GetText()), 1)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_h = tonumber(self.controls.target_targets_target_height.tb:GetText()) or 26
    local bar_h = scaled_int(raw_h, 26)
    if bar_h < 10 then bar_h = 10 end

    local preview_border = 1
    local outer_w = frame_w + (2 * preview_border)
    local outer_h = bar_h + (2 * preview_border)
    local desired_h = bar_h + 24 + (2 * preview_border)
    local holder = self.controls.target_targets_target_preview
    if holder ~= nil and holder.height ~= desired_h then
        holder.height = desired_h
        self:layout()
    end

    local cw, ch = p.container:GetSize()
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = math.floor((ch - outer_h) / 2)
    if y < 0 then y = 0 end

    p.outer:SetPosition(x, y)
    p.outer:SetSize(outer_w, outer_h)
    p.root:SetPosition(preview_border, preview_border)
    p.root:SetSize(frame_w, bar_h)
    _apply_preview_border(p, outer_w, outer_h)

    local morale_bg = _hex_to_color(self.controls.target_targets_target_background_color.tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local ressource_bg_matches_missing =
        self.controls.target_targets_target_background_matches_missing.cb:IsChecked() == true
    local ressource_bg_dimming = tonumber(self.controls.target_targets_target_background_dimming.tb:GetText()) or 0.75
    local border_color = _hex_to_color(self.controls.target_targets_target_border_color.tb:GetText()) or morale_bg
    local bubble_color = _hex_to_color(self.controls.target_targets_target_bubble_color.tb:GetText()) or
        Turbine.UI.Color(0.2, 0.8, 1.0)
    local gradient_enabled = self.controls.target_targets_target_color_gradient.cb:IsChecked() == true
    local high = _hex_to_color(self.controls.target_targets_target_color_high.tb:GetText()) or
        Turbine.UI.Color(0.290196, 0.639216, 0.286275)
    local medium = _hex_to_color(self.controls.target_targets_target_color_medium.tb:GetText()) or
        Turbine.UI.Color(1, 0.650980, 0.803922, 0.196078)
    local low = _hex_to_color(self.controls.target_targets_target_color_low.tb:GetText()) or
        Turbine.UI.Color(1, 0.5, 0)
    local critical = _hex_to_color(self.controls.target_targets_target_color_critical.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0)
    local gradient_full = _hex_to_color(self.controls.target_targets_target_color_gradient_full.tb:GetText()) or high
    local gradient_mid = _hex_to_color(self.controls.target_targets_target_color_gradient_mid.tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local gradient_low = _hex_to_color(self.controls.target_targets_target_color_gradient_low.tb:GetText()) or critical
    Common.update_gradient_preview(self, "target_targets_target_color_gradient_preview", gradient_full, gradient_mid,
        gradient_low)

    local function morale_color(percent)
        return _morale_color_preview(percent, gradient_enabled, gradient_full, gradient_mid, gradient_low, high,
            medium, low, critical)
    end

    local function resource_background(fill_color)
        if ressource_bg_matches_missing == true then
            return _dim_color(fill_color, ressource_bg_dimming)
        end
        return morale_bg
    end

    p.root:SetBackColor(border_color)

    local inner_w = frame_w - (2 * border)
    local inner_h = bar_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    local percent = 0.72
    local fill_color = morale_color(percent)

    p.background:SetPosition(border, border)
    p.background:SetSize(inner_w, inner_h)
    p.background:SetBackColor(resource_background(fill_color))

    local fill_w = math.floor(inner_w * percent + 0.5)
    if fill_w < 0 then fill_w = 0 end
    if fill_w > inner_w then fill_w = inner_w end

    p.morale:SetPosition(0, 0)
    p.morale:SetSize(fill_w, inner_h)
    p.morale:SetBackColor(fill_color)

    local bubble_percent = 0.20
    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        p.bubble:SetVisible(true)
        p.bubble:SetBackColor(bubble_color)
        p.bubble:SetTop(0)
        p.bubble:SetHeight(inner_h)
        p.bubble:SetWidth(bubble_w)
        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = fill_w
        if left_inner > max_left then left_inner = max_left end
        p.bubble:SetLeft(left_inner)
    else
        p.bubble:SetVisible(false)
    end

    local tt_font_name = self.controls.target_targets_target_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_tt_font_size = tonumber(self.controls.target_targets_target_font_size.tb:GetText()) or 14
    local tt_font_size = scaled_number(raw_tt_font_size, 14)
    local tt_font = _require_font(tt_font_name, tt_font_size)
    local tt_style_enum = self.controls.target_targets_target_font_style:get_value() or LUI_ENUMS.font_style.OUTLINE
    local tt_font_style = LUI_TO_LOTRO.font_style[tt_style_enum] or Turbine.UI.FontStyle.None
    local tt_font_color = _hex_to_color(self.controls.target_targets_target_font_color.tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local tt_outline_color = _hex_to_color(self.controls.target_targets_target_font_outline_color.tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    p.label:SetFont(tt_font)
    p.label:SetFontStyle(tt_font_style)
    p.label:SetForeColor(tt_font_color)
    p.label:SetOutlineColor(tt_outline_color)

    local tt_align_text = self.controls.target_targets_target_text_alignment:get_value() or
        LUI_ENUMS.text_alignment.CENTER
    p.label:SetTextAlignment(text_align(tt_align_text))

    do
        local raw_margin = tonumber(self.controls.target_targets_target_text_margin.tb:GetText()) or 4
        local m = border + scaled_int(raw_margin, 4)
        if tt_align_text == LUI_ENUMS.text_alignment.LEFT then
            p.label:SetPosition(m, 0)
            p.label:SetSize(frame_w - m, bar_h)
        elseif tt_align_text == LUI_ENUMS.text_alignment.RIGHT then
            p.label:SetPosition(0, 0)
            p.label:SetSize(frame_w - m, bar_h)
        else
            p.label:SetPosition(0, 0)
            p.label:SetSize(frame_w, bar_h)
        end
    end

    local tt_fmt = self.controls.target_targets_target_text.tb:GetText() or ""
    local tt_bubble_fmt = self.controls.target_targets_target_bubble_text.tb:GetText() or ""
    local tt_fmt_tokens = lui_tokenize_format(tt_fmt)
    local tt_bubble_tokens = lui_tokenize_format(tt_bubble_fmt)

    local tt_max = 10000
    local tt_cur = math.floor(tt_max * percent + 0.5)
    local tt_bubble = math.floor(tt_max * bubble_percent + 0.5)
    local tt_pct_text = tostring(math.floor(percent * 100 + 0.5)) .. "%"

    local tt_bubble_text = ""
    if tt_bubble > 0 then
        tt_bubble_text = lui_abbrev_number(tt_bubble)
    end

    local tt_bubble_formatted = ""
    if tt_bubble > 0 and string.len(tt_bubble_fmt) > 0 then
        tt_bubble_formatted = lui_format_tokenized(tt_bubble_tokens, { b = tt_bubble_text })
    end

    p.label:SetText(lui_format_tokenized(tt_fmt_tokens, {
        name = TR("Target's Target"),
        level = "150",
        c = lui_abbrev_number(tt_cur),
        t = lui_abbrev_number(tt_max),
        p = tt_pct_text,
        b = tt_bubble_text,
        B = tt_bubble_formatted,
    }))

    lui_clear_number_abbrev_preview_settings()
end
