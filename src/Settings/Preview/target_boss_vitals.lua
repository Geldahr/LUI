local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _dim_color = Common.dim_color
local _require_font = Common.require_font
local _scaled_int = Common.scaled_int
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _sync_preview_holder_height = Common.sync_preview_holder_height
local DEFAULT_GRADIENT_MID_COLOR = Common.default_gradient_mid_color

import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_boss_label(window, bar_key, label_index, label, raw_scale, width, height,
                                          default_font_size, context)
    local controls = window.controls
    local key = "target_boss_" .. bar_key .. "_label" .. tostring(label_index)
    local enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    local text = controls[key .. "_text"].tb:GetText() or ""

    if enabled ~= true or _label_text_is_blank(text) == true then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local text_alignment = controls[key .. "_text_alignment"]:get_value() or LUI_ENUMS.text_alignment.CENTER
    local anchor = controls[key .. "_anchor"]:get_value() or LUI_ENUMS.vitals_label_anchor.CENTER
    local width_mode = controls[key .. "_width_mode"]:get_value() or LUI_ENUMS.vitals_label_width_mode.FILL
    local font_name = controls[key .. "_font_name"]:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_font_size = tonumber(controls[key .. "_font_size"].tb:GetText()) or default_font_size
    local font_size = raw_font_size * raw_scale
    local font_style_enum = controls[key .. "_font_style"]:get_value() or LUI_ENUMS.font_style.OUTLINE
    local rendered_text = lui_format_tokenized(lui_tokenize_format(text), context)

    label:SetFont(_require_font(font_name, font_size))
    label:SetFontStyle(LUI_TO_LOTRO.font_style[font_style_enum])
    label:SetForeColor(_hex_to_color(controls[key .. "_font_color"].tb:GetText()) or Turbine.UI.Color(1, 1, 1))
    label:SetOutlineColor(_hex_to_color(controls[key .. "_font_outline_color"].tb:GetText()) or Turbine.UI.Color(0, 0, 0))
    lui_vitals_layout_label(
        label,
        width,
        height,
        anchor,
        width_mode,
        text_alignment,
        math.floor(((tonumber(controls[key .. "_x_offset"].tb:GetText()) or 0) * raw_scale) + 0.5),
        math.floor(((tonumber(controls[key .. "_y_offset"].tb:GetText()) or 0) * raw_scale) + 0.5),
        font_name,
        font_size,
        rendered_text
    )
    label:SetText(rendered_text)
    label:SetVisible(true)
end

local function _render_preview_boss_labels(window, bar_key, labels, raw_scale, width, height, default_font_size, context)
    for i = 1, #labels do
        _render_preview_boss_label(window, bar_key, i, labels[i], raw_scale, width, height, default_font_size, context)
    end
end

function ConfigWindow:init_target_boss_vitals_preview()
    local holder = self.controls.target_boss_vitals_preview
    if holder == nil or holder.control == nil then
        return
    end

    if self.target_boss_vitals_preview ~= nil then
        return
    end

    self.target_boss_vitals_preview = {
        root = Turbine.UI.Control(),
        border_top = Turbine.UI.Control(),
        border_bottom = Turbine.UI.Control(),
        border_left = Turbine.UI.Control(),
        border_right = Turbine.UI.Control(),
        effects_top_border = Turbine.UI.Control(),
        morale_border = Turbine.UI.Control(),
        morale_back = Turbine.UI.Control(),
        morale_fill = Turbine.UI.Control(),
        morale_bubble = Turbine.UI.Control(),
        morale_labels = {},
        power_border = Turbine.UI.Control(),
        power_back = Turbine.UI.Control(),
        power_fill = Turbine.UI.Control(),
        power_labels = {},
        buffs = {},
        debuffs = {},
    }

    local p = self.target_boss_vitals_preview
    local all = {
        p.root,
        p.border_top, p.border_bottom, p.border_left, p.border_right,
        p.effects_top_border,
        p.morale_border, p.morale_back, p.morale_fill, p.morale_bubble,
        p.power_border, p.power_back, p.power_fill,
    }

    for i = 1, #all do
        all[i]:SetParent(holder.control)
        all[i]:SetMouseVisible(false)
    end

    p.morale_back:SetParent(p.morale_border)
    p.morale_fill:SetParent(p.morale_back)
    p.morale_bubble:SetParent(p.morale_back)
    p.power_back:SetParent(p.power_border)
    p.power_fill:SetParent(p.power_back)

    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(p.morale_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.morale_labels[i] = label
    end

    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(p.power_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.power_labels[i] = label
    end

    for i = 1, 12 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = UI.Widgets.LuiLabel()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.buffs[i] = { root = icon, label = label }
    end

    for i = 1, 16 do
        local icon = Turbine.UI.Control()
        icon:SetParent(holder.control)
        icon:SetMouseVisible(false)
        local label = UI.Widgets.LuiLabel()
        label:SetParent(icon)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
        p.debuffs[i] = { root = icon, label = label }
    end
end

function ConfigWindow:update_target_boss_vitals_preview()
    local p = self.target_boss_vitals_preview
    if p == nil then
        self:init_target_boss_vitals_preview()
        p = self.target_boss_vitals_preview
    end
    if p == nil then
        return
    end

    local raw_scale = _G.loaded_settings.global.scale

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

    local function timer_style(style_enum)
        return LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None
    end

    local raw_configured_frame_w = tonumber(self.controls.target_boss_width.tb:GetText()) or 520
    local raw_configured_power_w = tonumber(self.controls.target_boss_power_width.tb:GetText()) or 140
    local configured_frame_w = scaled_int(raw_configured_frame_w, 520)
    local border = scaled_border(self.controls.target_boss_border_width.tb:GetText(), 1)
    local morale_h = scaled_int(self.controls.target_boss_morale_height.tb:GetText(), 50)
    local power_h = scaled_int(self.controls.target_boss_power_height.tb:GetText(), 26)
    local configured_power_w = scaled_int(raw_configured_power_w, 140)
    local effects_h = scaled_int(self.controls.target_boss_effects_height.tb:GetText(), 132)
    local buff_size = scaled_int(self.controls.target_boss_buff_size.tb:GetText(), 22)
    local debuff_size = scaled_int(self.controls.target_boss_debuff_size.tb:GetText(), 31)
    local power_side = self.controls.target_boss_power_side:get_value() or LUI_ENUMS.side.LEFT
    local power_hidden = self.controls.target_boss_power_hide.cb:IsChecked() == true
    local stacked_effects = power_hidden ~= true and
        (raw_configured_frame_w < 400 or raw_configured_power_w > (raw_configured_frame_w / 2))

    if buff_size < 1 then buff_size = 1 end
    if debuff_size < 1 then debuff_size = 1 end

    local holder = self.controls.target_boss_vitals_preview
    local holder_w = holder.control:GetWidth() or configured_frame_w
    local preview_border = 1
    local frame_w = math.min(configured_frame_w, math.max(1, holder_w - (2 * preview_border)))
    local power_w = power_hidden == true and 0 or configured_power_w

    if power_w > frame_w then
        power_w = frame_w
    end
    if stacked_effects ~= true and power_w >= frame_w then
        power_w = frame_w - 1
    end
    if power_w < 0 then
        power_w = 0
    end

    local effects_w = stacked_effects == true and frame_w or (frame_w - power_w)
    if effects_w < 1 then effects_w = 1 end

    local effects_content_h = math.max(0, effects_h - border)
    local buff_cols = math.max(1, math.floor(effects_w / buff_size))
    local buff_count = 6
    local buff_rows = math.ceil(buff_count / buff_cols)
    local buffs_h = math.min(effects_content_h, buff_rows * buff_size)

    local debuff_cols = math.max(1, math.floor(effects_w / debuff_size))
    local debuff_count = 10
    local debuff_rows = math.ceil(debuff_count / debuff_cols)
    local debuffs_h = math.min(math.max(0, effects_content_h - buffs_h), debuff_rows * debuff_size)

    local effects_total_h = buffs_h + debuffs_h
    local lower_top = morale_h - border
    local reserved_effects_h = math.max(border + effects_total_h, border)
    local lower_h
    local effects_top
    if power_hidden == true then
        lower_h = reserved_effects_h
        effects_top = lower_top
    elseif stacked_effects == true then
        lower_h = power_h + reserved_effects_h
        effects_top = lower_top + power_h - border
    else
        lower_h = math.max(power_h, reserved_effects_h)
        effects_top = lower_top
    end
    local total_h = lower_top + lower_h
    local outer_w = frame_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local holder_extra_h = _scaled_int(9)
    _sync_preview_holder_height(self, holder, outer_h + holder_extra_h)

    local off_x = math.max(0, math.floor((holder_w - outer_w) / 2))
    local outer_y = _scaled_int(4)

    p.root:SetPosition(off_x + preview_border, outer_y + preview_border)
    p.root:SetSize(frame_w, total_h)
    _apply_preview_border({
        border_top = p.border_top,
        border_bottom = p.border_bottom,
        border_left = p.border_left,
        border_right = p.border_right,
    }, outer_w, outer_h)

    local border_color = _hex_to_color(self.controls.target_boss_border_color.tb:GetText()) or Turbine.UI.Color(1, 0, 0,
        0)
    local morale_back = _hex_to_color(self.controls.target_boss_morale_background_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)
    local ressource_back_matches_missing =
        self.controls.target_boss_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_back_dimming = tonumber(self.controls.target_boss_ressource_background_dimming.tb:GetText()) or 0.75
    local morale_high = _hex_to_color(self.controls.target_boss_morale_color_high.tb:GetText()) or
        Turbine.UI.Color(1, 0.290196, 0.639216, 0.286275)
    local morale_medium = _hex_to_color(self.controls.target_boss_morale_color_medium.tb:GetText()) or
        Turbine.UI.Color(1, 0.650980, 0.803922, 0.196078)
    local morale_low = _hex_to_color(self.controls.target_boss_morale_color_low.tb:GetText()) or
        Turbine.UI.Color(1, 0.87, 0.55, 0)
    local morale_critical = _hex_to_color(self.controls.target_boss_morale_color_critical.tb:GetText()) or
        Turbine.UI.Color(1, 0.87, 0.11, 0)
    local morale_gradient = self.controls.target_boss_morale_gradient.cb:IsChecked() == true
    local morale_gradient_full = _hex_to_color(self.controls.target_boss_morale_gradient_full.tb:GetText()) or
        morale_high
    local morale_gradient_mid = _hex_to_color(self.controls.target_boss_morale_gradient_mid.tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local morale_gradient_low = _hex_to_color(self.controls.target_boss_morale_gradient_low.tb:GetText()) or
        morale_critical
    Common.update_gradient_preview(self, "target_boss_morale_gradient_preview", morale_gradient_full,
        morale_gradient_mid, morale_gradient_low)
    local bubble_color = _hex_to_color(self.controls.target_boss_morale_bubble_color.tb:GetText()) or
        Turbine.UI.Color(1, 0.5, 0.8, 1)
    local power_fill = _hex_to_color(self.controls.target_boss_power_color.tb:GetText()) or
        Turbine.UI.Color(1, 0.2, 0.6, 0.98)
    local buff_colors = {
        Turbine.UI.Color(1, 0.15, 0.55, 0.55),
        Turbine.UI.Color(1, 0.20, 0.45, 0.72),
        Turbine.UI.Color(1, 0.33, 0.62, 0.28),
        Turbine.UI.Color(1, 0.58, 0.42, 0.76),
        Turbine.UI.Color(1, 0.72, 0.54, 0.20),
        Turbine.UI.Color(1, 0.24, 0.64, 0.44),
    }
    local debuff_colors = {
        Turbine.UI.Color(1, 0.70, 0.35, 0.18),
        Turbine.UI.Color(1, 0.76, 0.20, 0.24),
        Turbine.UI.Color(1, 0.52, 0.24, 0.68),
        Turbine.UI.Color(1, 0.78, 0.48, 0.14),
        Turbine.UI.Color(1, 0.60, 0.18, 0.46),
        Turbine.UI.Color(1, 0.84, 0.30, 0.10),
    }
    local morale_percent = 0.72
    local bubble_percent = 0.08
    local power_percent = 0.55

    local function resource_background(fill_color)
        if ressource_back_matches_missing == true then
            return _dim_color(fill_color, ressource_back_dimming)
        end
        return morale_back
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    p.border_top:SetBackColor(border_color)
    p.border_bottom:SetBackColor(border_color)
    p.border_left:SetBackColor(border_color)
    p.border_right:SetBackColor(border_color)
    p.effects_top_border:SetBackColor(border_color)
    p.border_top:SetPosition(off_x, outer_y)
    p.border_bottom:SetPosition(off_x, outer_y + outer_h - preview_border)
    p.border_left:SetPosition(off_x, outer_y)
    p.border_right:SetPosition(off_x + outer_w - preview_border, outer_y)

    p.morale_border:SetPosition(off_x + preview_border, outer_y + preview_border)
    p.morale_border:SetSize(frame_w, morale_h)
    p.morale_border:SetBackColor(border_color)
    p.morale_back:SetPosition(border, border)
    p.morale_back:SetSize(frame_w - (2 * border), morale_h - (2 * border))
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, morale_gradient_full,
        morale_gradient_mid, morale_gradient_low, morale_high, morale_medium, morale_low, morale_critical)
    p.morale_back:SetBackColor(resource_background(morale_fill_color))
    p.morale_fill:SetPosition(0, 0)
    p.morale_fill:SetSize(math.floor((frame_w - (2 * border)) * morale_percent + 0.5), morale_h - (2 * border))
    p.morale_fill:SetBackColor(morale_fill_color)
    p.morale_bubble:SetPosition(p.morale_fill:GetWidth(), 0)
    p.morale_bubble:SetSize(math.floor((frame_w - (2 * border)) * bubble_percent + 0.5), morale_h - (2 * border))
    p.morale_bubble:SetBackColor(bubble_color)

    do
        local bubble_fmt = self.controls.target_boss_morale_bubble_text.tb:GetText() or ""
        local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)
        local morale_max = 600000
        local morale_cur = math.floor(morale_max * morale_percent + 0.5)
        local bubble_value = math.floor(morale_max * bubble_percent + 0.5)
        local bubble_text = bubble_value > 0 and lui_abbrev_number(bubble_value) or ""
        local bubble_formatted = ""
        if bubble_value > 0 and string.len(bubble_fmt) > 0 then
            bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
        end

        _render_preview_boss_labels(self, "morale", p.morale_labels, raw_scale, frame_w, morale_h, 16, {
            name = "The Watcher in the Water",
            level = "150",
            c = lui_abbrev_number(morale_cur),
            t = lui_abbrev_number(morale_max),
            p = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%",
            b = bubble_text,
            B = bubble_formatted,
        })
    end

    local power_left = 0
    local effects_left = stacked_effects == true and 0 or power_w
    if stacked_effects ~= true and power_side == LUI_ENUMS.side.RIGHT then
        power_left = frame_w - power_w
        effects_left = 0
    elseif stacked_effects == true and power_side == LUI_ENUMS.side.RIGHT then
        power_left = frame_w - power_w
    end

    p.effects_top_border:SetPosition(off_x + preview_border + effects_left, outer_y + preview_border + effects_top)
    p.effects_top_border:SetSize(effects_w, border)
    p.power_border:SetVisible(power_hidden ~= true)
    p.power_back:SetVisible(power_hidden ~= true)
    p.power_fill:SetVisible(power_hidden ~= true)
    if power_hidden ~= true then
        p.power_border:SetPosition(off_x + preview_border + power_left, outer_y + preview_border + lower_top)
        p.power_border:SetSize(power_w, power_h)
        p.power_border:SetBackColor(border_color)
        p.power_back:SetPosition(border, border)
        p.power_back:SetSize(power_w - (2 * border), power_h - (2 * border))
        p.power_back:SetBackColor(resource_background(power_fill))
        p.power_fill:SetPosition(0, 0)
        p.power_fill:SetSize(math.floor((power_w - (2 * border)) * 0.55 + 0.5), power_h - (2 * border))
        p.power_fill:SetBackColor(power_fill)

        local power_max = 120000
        local power_cur = math.floor(power_max * power_percent + 0.5)
        _render_preview_boss_labels(self, "power", p.power_labels, raw_scale, power_w, power_h, 14, {
            name = "The Watcher in the Water",
            level = "150",
            c = lui_abbrev_number(power_cur),
            t = lui_abbrev_number(power_max),
            p = tostring(math.floor(power_percent * 100 + 0.5)) .. "%",
        })
    else
        for i = 1, #p.power_labels do
            p.power_labels[i]:SetText("")
            p.power_labels[i]:SetVisible(false)
        end
    end

    local buff_timer_font_name = self.controls.target_boss_buff_timer_font_name:get_value() or LUI_ENUMS.font_name.VERDANA
    local raw_buff_timer_font_size = tonumber(self.controls.target_boss_buff_timer_font_size.tb:GetText()) or 12
    local buff_timer_font_size = scaled_number(raw_buff_timer_font_size, 12)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style = timer_style(self.controls.target_boss_buff_timer_font_style:get_value() or
        LUI_ENUMS.font_style.OUTLINE)
    local buff_timer_color = _hex_to_color(self.controls.target_boss_buff_timer_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1, 1)
    local buff_timer_outline = _hex_to_color(self.controls.target_boss_buff_timer_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)

    local buffs_top = effects_top + border
    for i = 1, #p.buffs do
        local icon = p.buffs[i]
        if i <= buff_count then
            local idx = i - 1
            local col = idx % buff_cols
            local row = math.floor(idx / buff_cols)
            icon.root:SetVisible(true)
            icon.root:SetPosition(
                off_x + preview_border + effects_left + (col * buff_size),
                outer_y + preview_border + buffs_top + (row * buff_size)
            )
            icon.root:SetSize(buff_size, buff_size)
            icon.root:SetBackColor(buff_colors[((i - 1) % #buff_colors) + 1])
            icon.label:SetPosition(0, 0)
            icon.label:SetSize(buff_size, buff_size)
            icon.label:SetFont(buff_timer_font)
            icon.label:SetFontStyle(buff_timer_style)
            icon.label:SetForeColor(buff_timer_color)
            icon.label:SetOutlineColor(buff_timer_outline)
            icon.label:SetText(i == 1 and lui_format_timeout(6) or (i == 2 and lui_format_timeout(2.4) or ""))
        else
            icon.root:SetVisible(false)
        end
    end

    local debuff_timer_font_name = self.controls.target_boss_debuff_timer_font_name:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_debuff_timer_font_size = tonumber(self.controls.target_boss_debuff_timer_font_size.tb:GetText()) or 25
    local debuff_timer_font_size = scaled_number(raw_debuff_timer_font_size, 25)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style = timer_style(self.controls.target_boss_debuff_timer_font_style:get_value() or
        LUI_ENUMS.font_style.OUTLINE)
    local debuff_timer_color = _hex_to_color(self.controls.target_boss_debuff_timer_font_color.tb:GetText()) or
        Turbine.UI.Color(1, 1, 1, 1)
    local debuff_timer_outline = _hex_to_color(self.controls.target_boss_debuff_timer_font_outline_color.tb:GetText()) or
        Turbine.UI.Color(1, 0, 0, 0)

    local debuffs_top = buffs_top + buffs_h
    for i = 1, #p.debuffs do
        local icon = p.debuffs[i]
        if i <= debuff_count then
            local idx = i - 1
            local col = idx % debuff_cols
            local row = math.floor(idx / debuff_cols)
            icon.root:SetVisible(true)
            icon.root:SetPosition(
                off_x + preview_border + effects_left + (col * debuff_size),
                outer_y + preview_border + debuffs_top + (row * debuff_size)
            )
            icon.root:SetSize(debuff_size, debuff_size)
            icon.root:SetBackColor(debuff_colors[((i - 1) % #debuff_colors) + 1])
            icon.label:SetPosition(0, 0)
            icon.label:SetSize(debuff_size, debuff_size)
            icon.label:SetFont(debuff_timer_font)
            icon.label:SetFontStyle(debuff_timer_style)
            icon.label:SetForeColor(debuff_timer_color)
            icon.label:SetOutlineColor(debuff_timer_outline)
            icon.label:SetText(i == 1 and lui_format_timeout(7) or (i == 2 and lui_format_timeout(2.2) or ""))
        else
            icon.root:SetVisible(false)
        end
    end

    lui_clear_number_abbrev_preview_settings()
end
