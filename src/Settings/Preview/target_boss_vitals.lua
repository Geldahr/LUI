local Common = SettingsPreviewCommon
local _dim_color = Common.dim_color
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _preview_scaled_int = Common.preview_scaled_int
local _preview_scaled_border = Common.preview_scaled_border
local _preview_scaled_number = Common.preview_scaled_number
local _scaled_int = Common.scaled_int
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _sync_preview_holder_height = Common.sync_preview_holder_height

import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_boss_label(window, bar_key, label_index, label, raw_scale, width, height,
                                          default_font_size, context)
    local controls = window.controls
    local key = "target_boss_" .. bar_key .. "_label" .. tostring(label_index)
    local enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    local text = controls[key .. "_text"].tb:GetText()

    if enabled ~= true or _label_text_is_blank(text) == true then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local text_alignment = _require_control_enum(controls, key .. "_text_alignment")
    local anchor = _require_control_enum(controls, key .. "_anchor")
    local width_mode = _require_control_enum(controls, key .. "_width_mode")
    local font_name = _require_control_enum(controls, key .. "_font_name")
    local raw_font_size = _require_control_number(controls, key .. "_font_size")
    local font_size = raw_font_size * raw_scale
    local font_style_enum = _require_control_enum(controls, key .. "_font_style")
    local rendered_text = lui_format_tokenized(lui_tokenize_format(text), context)

    label:SetFont(_require_font(font_name, font_size))
    label:SetFontStyle(LUI_TO_LOTRO.font_style[font_style_enum])
    label:SetForeColor(_require_control_color(controls, key .. "_font_color"))
    label:SetOutlineColor(_require_control_color(controls, key .. "_font_outline_color"))
    lui_vitals_layout_label(
        label,
        width,
        height,
        anchor,
        width_mode,
        text_alignment,
        math.floor((_require_control_number(controls, key .. "_x_offset") * raw_scale) + 0.5),
        math.floor((_require_control_number(controls, key .. "_y_offset") * raw_scale) + 0.5),
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

    local raw_scale = _require_positive_scale(self)

    local function timer_style(style_enum)
        local style = LUI_TO_LOTRO.font_style[style_enum]
        if style == nil then
            error("Missing boss preview timer font style: " .. tostring(style_enum))
        end
        return style
    end

    local raw_configured_frame_w = _require_control_number(self.controls, "target_boss_width")
    local raw_configured_power_w = _require_control_number(self.controls, "target_boss_power_width")
    local configured_frame_w = _preview_scaled_int(raw_scale, raw_configured_frame_w)
    local border = _preview_scaled_border(raw_scale, _require_control_number(self.controls, "target_boss_border_width"))
    local morale_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_morale_height"))
    local power_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_power_height"))
    local configured_power_w = _preview_scaled_int(raw_scale, raw_configured_power_w)
    local effects_h = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_effects_height"))
    local buff_size = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_buff_size"))
    local debuff_size = _preview_scaled_int(raw_scale, _require_control_number(self.controls, "target_boss_debuff_size"))
    local power_side = _require_control_enum(self.controls, "target_boss_power_side")
    local power_hidden = self.controls.target_boss_power_hide.cb:IsChecked() == true
    local stacked_effects = power_hidden ~= true and
        (raw_configured_frame_w < 400 or raw_configured_power_w > (raw_configured_frame_w / 2))

    if buff_size < 1 then buff_size = 1 end
    if debuff_size < 1 then debuff_size = 1 end

    local holder = self.controls.target_boss_vitals_preview
    local holder_w = holder.control:GetWidth()
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

    local border_color = _require_control_color(self.controls, "target_boss_border_color")
    local morale_back = _require_control_color(self.controls, "target_boss_morale_background_color")
    local ressource_back_matches_missing =
        self.controls.target_boss_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_back_dimming = _require_control_number(self.controls, "target_boss_ressource_background_dimming")
    local morale_high = _require_control_color(self.controls, "target_boss_morale_color_high")
    local morale_medium = _require_control_color(self.controls, "target_boss_morale_color_medium")
    local morale_low = _require_control_color(self.controls, "target_boss_morale_color_low")
    local morale_critical = _require_control_color(self.controls, "target_boss_morale_color_critical")
    local morale_gradient = self.controls.target_boss_morale_gradient.cb:IsChecked() == true
    local morale_gradient_full = _require_control_color(self.controls, "target_boss_morale_gradient_full")
    local morale_gradient_mid = _require_control_color(self.controls, "target_boss_morale_gradient_mid")
    local morale_gradient_low = _require_control_color(self.controls, "target_boss_morale_gradient_low")
    Common.update_gradient_preview(self, "target_boss_morale_gradient_preview", morale_gradient_full,
        morale_gradient_mid, morale_gradient_low)
    local bubble_color = _require_control_color(self.controls, "target_boss_morale_bubble_color")
    local power_fill = _require_control_color(self.controls, "target_boss_power_color")
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
        local bubble_fmt = self.controls.target_boss_morale_bubble_text.tb:GetText()
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

    local buff_timer_font_name = _require_control_enum(self.controls, "target_boss_buff_timer_font_name")
    local raw_buff_timer_font_size = _require_control_number(self.controls, "target_boss_buff_timer_font_size")
    local buff_timer_font_size = _preview_scaled_number(raw_scale, raw_buff_timer_font_size)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style = timer_style(_require_control_enum(self.controls, "target_boss_buff_timer_font_style"))
    local buff_timer_color = _require_control_color(self.controls, "target_boss_buff_timer_font_color")
    local buff_timer_outline = _require_control_color(self.controls, "target_boss_buff_timer_font_outline_color")

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

    local debuff_timer_font_name = _require_control_enum(self.controls, "target_boss_debuff_timer_font_name")
    local raw_debuff_timer_font_size = _require_control_number(self.controls, "target_boss_debuff_timer_font_size")
    local debuff_timer_font_size = _preview_scaled_number(raw_scale, raw_debuff_timer_font_size)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style = timer_style(_require_control_enum(self.controls, "target_boss_debuff_timer_font_style"))
    local debuff_timer_color = _require_control_color(self.controls, "target_boss_debuff_timer_font_color")
    local debuff_timer_outline = _require_control_color(self.controls, "target_boss_debuff_timer_font_outline_color")

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
