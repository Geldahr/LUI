local Common = SettingsPreviewCommon
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _scaled_int = Common.scaled_int
local _scaled_font = Common.scaled_font
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _preview_scaled_int = Common.preview_scaled_int
local _preview_scaled_border = Common.preview_scaled_border
local _preview_scaled_number = Common.preview_scaled_number
local _preview_resource_background = Common.preview_resource_background
local _sync_preview_holder_height = Common.sync_preview_holder_height
import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_vital_label(window, prefix, bar_key, label_index, label, raw_scale, width, height,
                                           default_font_size, context)
    local controls = window.controls
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)
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
    local font_size = _preview_scaled_number(raw_scale, _require_control_number(controls, key .. "_font_size"))
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
        _preview_scaled_int(raw_scale, _require_control_number(controls, key .. "_x_offset")),
        _preview_scaled_int(raw_scale, _require_control_number(controls, key .. "_y_offset")),
        font_name,
        font_size,
        rendered_text
    )
    label:SetText(rendered_text)
    label:SetVisible(true)
end

local function _render_preview_vital_labels(window, prefix, bar_key, labels, raw_scale, width, height,
                                            default_font_size, context)
    for i = 1, #labels do
        _render_preview_vital_label(window, prefix, bar_key, i, labels[i], raw_scale, width, height,
            default_font_size, context)
    end
end

local function _new_preview_border_control(parent)
    local control = Turbine.UI.Control()
    control:SetParent(parent)
    control:SetMouseVisible(false)
    control:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    control:SetVisible(false)
    return control
end

local function _new_preview_icon(parent)
    local icon = {}

    icon.root = Turbine.UI.Control()
    icon.root:SetParent(parent)
    icon.root:SetMouseVisible(false)
    icon.root:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))

    icon.inner = Turbine.UI.Control()
    icon.inner:SetParent(icon.root)
    icon.inner:SetMouseVisible(false)
    icon.inner:SetBackColor(Turbine.UI.Color(1, 0.65, 0.65, 0.65))

    icon.timer = UI.Widgets.LuiLabel()
    icon.timer:SetParent(icon.root)
    icon.timer:SetMouseVisible(false)
    icon.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    icon.timer:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    icon.timer:SetOutlineColor(Turbine.UI.Color(0, 0, 0, 1))
    icon.timer:SetFontStyle(Turbine.UI.FontStyle.Outline)

    return icon
end

local function _new_preview_vital_label(parent, z_order)
    local label = UI.Widgets.LuiLabel()
    label:SetParent(parent)
    label:SetMouseVisible(false)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    label:SetMultiline(true)
    label:SetZOrder(z_order)
    return label
end

local StandardVitalsPreview = class()

function StandardVitalsPreview:Constructor(window, holder_key, prefix, name_text, level_text)
    self.window = window
    self.holder_key = holder_key
    self.prefix = prefix
    self.name_text = name_text
    self.level_text = level_text

    self.holder = window.controls[holder_key]
    self.container = self.holder.control
    self.container:SetMouseVisible(false)

    self.outer = Turbine.UI.Control()
    self.outer:SetParent(self.container)
    self.outer:SetMouseVisible(false)

    self.info_label = UI.Widgets.LuiLabel()
    self.info_label:SetParent(self.container)
    self.info_label:SetMouseVisible(false)
    self.info_label:SetMultiline(true)
    self.info_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)

    self.root = Turbine.UI.Control()
    self.root:SetParent(self.outer)
    self.root:SetMouseVisible(false)

    self.border_top = _new_preview_border_control(self.outer)
    self.border_bottom = _new_preview_border_control(self.outer)
    self.border_left = _new_preview_border_control(self.outer)
    self.border_right = _new_preview_border_control(self.outer)

    self.effects_debuffs = Turbine.UI.Control()
    self.effects_debuffs:SetParent(self.root)
    self.effects_debuffs:SetMouseVisible(false)
    self.effects_debuffs:SetBackColor(Turbine.UI.Color(0.32, 0.14, 0.14))

    self.effects_debuffs_label = UI.Widgets.LuiLabel()
    self.effects_debuffs_label:SetParent(self.effects_debuffs)
    self.effects_debuffs_label:SetMouseVisible(false)
    self.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.debuff_icons = {}
    for i = 1, 2 do
        self.debuff_icons[i] = _new_preview_icon(self.effects_debuffs)
    end

    self.effects_buffs = Turbine.UI.Control()
    self.effects_buffs:SetParent(self.root)
    self.effects_buffs:SetMouseVisible(false)
    self.effects_buffs:SetBackColor(Turbine.UI.Color(0.14, 0.18, 0.32))

    self.effects_buffs_label = UI.Widgets.LuiLabel()
    self.effects_buffs_label:SetParent(self.effects_buffs)
    self.effects_buffs_label:SetMouseVisible(false)
    self.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    self.buff_icons = {}
    for i = 1, 2 do
        self.buff_icons[i] = _new_preview_icon(self.effects_buffs)
    end

    self.morale_border = Turbine.UI.Control()
    self.morale_border:SetParent(self.root)
    self.morale_border:SetMouseVisible(false)

    self.morale_background = Turbine.UI.Control()
    self.morale_background:SetParent(self.morale_border)
    self.morale_background:SetMouseVisible(false)

    self.morale_bar = Turbine.UI.Control()
    self.morale_bar:SetParent(self.morale_background)
    self.morale_bar:SetMouseVisible(false)
    self.morale_bar:SetZOrder(1)

    self.bubble_bar = Turbine.UI.Control()
    self.bubble_bar:SetParent(self.morale_background)
    self.bubble_bar:SetMouseVisible(false)
    self.bubble_bar:SetZOrder(2)

    self.morale_labels = {}
    for i = 1, 2 do
        self.morale_labels[i] = _new_preview_vital_label(self.morale_border, 9 + i)
    end

    self.power_border = Turbine.UI.Control()
    self.power_border:SetParent(self.root)
    self.power_border:SetMouseVisible(false)

    self.power_background = Turbine.UI.Control()
    self.power_background:SetParent(self.power_border)
    self.power_background:SetMouseVisible(false)

    self.power_bar = Turbine.UI.Control()
    self.power_bar:SetParent(self.power_background)
    self.power_bar:SetMouseVisible(false)

    self.power_labels = {}
    for i = 1, 2 do
        self.power_labels[i] = _new_preview_vital_label(self.power_border, 9 + i)
    end
end

function StandardVitalsPreview:update()
    local window = self.window
    local controls = window.controls
    local prefix = self.prefix
    local raw_scale = _require_positive_scale(window)

    local raw_frame_w = _require_control_number(controls, prefix .. "_width")
    local raw_border = _require_control_number(controls, prefix .. "_border_width")
    local frame_w = _preview_scaled_int(raw_scale, raw_frame_w)
    local border = _preview_scaled_border(raw_scale, raw_border)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_morale_h = _require_control_number(controls, prefix .. "_morale_height")
    local raw_power_h = _require_control_number(controls, prefix .. "_power_height")
    local morale_h = _preview_scaled_int(raw_scale, raw_morale_h)
    local power_h = _preview_scaled_int(raw_scale, raw_power_h)
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end

    local raw_effects_h = _require_control_number(controls, prefix .. "_effects_height")
    local effects_height = _preview_scaled_int(raw_scale, raw_effects_h)
    local effects_half = effects_height / 2

    local raw_effects_position = _require_control_enum(controls, prefix .. "_effects_position")
    local effects_below = raw_effects_position == LUI_ENUMS.vitals_effects_position.BELOW

    local raw_buff_size = _require_control_number(controls, prefix .. "_buff_size")
    local raw_debuff_size = _require_control_number(controls, prefix .. "_debuff_size")
    local buff_icon = _preview_scaled_int(raw_scale, raw_buff_size)
    local debuff_icon = _preview_scaled_int(raw_scale, raw_debuff_size)
    if buff_icon < 1 then buff_icon = 1 end
    if debuff_icon < 1 then debuff_icon = 1 end

    local buff_cols = math.floor(frame_w / buff_icon)
    if buff_cols < 1 then buff_cols = 1 end
    local debuff_cols = math.floor(frame_w / debuff_icon)
    if debuff_cols < 1 then debuff_cols = 1 end

    local buff_rows = math.floor(effects_half / buff_icon)
    if buff_rows < 1 then buff_rows = 1 end
    local debuff_rows = math.floor(effects_half / debuff_icon)
    if debuff_rows < 1 then debuff_rows = 1 end

    local max_buffs = buff_cols * buff_rows
    local max_debuffs = debuff_cols * debuff_rows

    local label_font = window.field_label_font
    local info_h = _scaled_int(46)
    local preview_border = 1
    local root_inner_h = effects_height + morale_h + power_h - border
    if root_inner_h < 1 then root_inner_h = 1 end
    local desired_h_inner = info_h + root_inner_h + _scaled_int(9)
    local desired_h = desired_h_inner + (2 * preview_border)
    _sync_preview_holder_height(window, self.holder, desired_h)

    local cw = self.container:GetWidth()
    local root_outer_h = root_inner_h + (2 * preview_border)
    local outer_w = frame_w + (2 * preview_border)
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = _scaled_int(4)
    if y < 0 then y = 0 end

    local info_w = cw
    if info_w < 1 then
        info_w = frame_w
    end
    local info_font = _scaled_font(LUI_ENUMS.font_name.VERDANA, 13)
    self.info_label:SetPosition(0, y)
    self.info_label:SetSize(info_w, info_h)
    self.info_label:SetFont(info_font)
    self.info_label:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.85))
    self.info_label:SetText(
        TR["Buffs area auto-resizes to the number of rows, up to the max height. Debuffs fill the remaining effects height. Effects can be placed above Morale or below Power."]
    )

    y = y + info_h
    self.outer:SetPosition(x, y)
    self.outer:SetSize(outer_w, root_outer_h)
    self.root:SetPosition(preview_border, preview_border)
    self.root:SetSize(frame_w, root_inner_h)
    _apply_preview_border(self, outer_w, root_outer_h)

    local reverse_fill = effects_below ~= true
    local effects_top = 0
    local morale_top = effects_height
    if effects_below == true then
        morale_top = 0
    end
    local power_top = morale_top + morale_h - border
    if effects_below == true then
        effects_top = power_top + power_h
    end

    local buff_area_h = effects_half
    local debuff_area_h = effects_half

    if effects_below == true then
        self.effects_buffs:SetPosition(0, effects_top)
        self.effects_buffs:SetSize(frame_w, buff_area_h)
        self.effects_debuffs:SetPosition(0, effects_top + buff_area_h)
        self.effects_debuffs:SetSize(frame_w, debuff_area_h)
    else
        self.effects_debuffs:SetPosition(0, effects_top)
        self.effects_debuffs:SetSize(frame_w, debuff_area_h)
        self.effects_buffs:SetPosition(0, effects_top + debuff_area_h)
        self.effects_buffs:SetSize(frame_w, buff_area_h)
    end

    local debuff_label_h = 16
    if debuff_label_h > debuff_area_h then
        debuff_label_h = debuff_area_h
    end
    local buff_label_h = 16
    if buff_label_h > buff_area_h then
        buff_label_h = buff_area_h
    end

    self.effects_debuffs_label:SetFont(label_font)
    self.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.effects_debuffs_label:SetPosition(0, 0)
    self.effects_debuffs_label:SetSize(frame_w, debuff_label_h)
    self.effects_debuffs_label:SetText(string.format(TR["Debuffs: max %d (%dx%d)"], max_debuffs, debuff_cols, debuff_rows))

    self.effects_buffs_label:SetFont(label_font)
    self.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    self.effects_buffs_label:SetPosition(0, 0)
    self.effects_buffs_label:SetSize(frame_w, buff_label_h)
    self.effects_buffs_label:SetText(string.format(TR["Buffs: max %d (%dx%d)"], max_buffs, buff_cols, buff_rows))

    local function _timer_text(time_left)
        local t = tonumber(time_left)
        if t == nil then return "" end
        if t < 0 then
            return ""
        end
        if t < 9 then
            return lui_format_timeout(t)
        end
        return ""
    end

    local function _timer_style(style_enum)
        local style = LUI_TO_LOTRO.font_style[style_enum]
        if style == nil then
            error("Missing timer font style: " .. tostring(style_enum))
        end
        return style
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(window))

    local buff_timer_font_name = _require_control_enum(controls, prefix .. "_buff_timer_font_name")
    local raw_buff_timer_font_size = _require_control_number(controls, prefix .. "_buff_timer_font_size")
    local buff_timer_font_size = _preview_scaled_number(raw_scale, raw_buff_timer_font_size)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style_enum = _require_control_enum(controls, prefix .. "_buff_timer_font_style")
    local buff_timer_style = _timer_style(buff_timer_style_enum)
    local buff_timer_color = _require_control_color(controls, prefix .. "_buff_timer_font_color")
    local buff_timer_outline = _require_control_color(controls, prefix .. "_buff_timer_font_outline_color")

    local debuff_timer_font_name = _require_control_enum(controls, prefix .. "_debuff_timer_font_name")
    local raw_debuff_timer_font_size = _require_control_number(controls, prefix .. "_debuff_timer_font_size")
    local debuff_timer_font_size = _preview_scaled_number(raw_scale, raw_debuff_timer_font_size)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style_enum = _require_control_enum(controls, prefix .. "_debuff_timer_font_style")
    local debuff_timer_style = _timer_style(debuff_timer_style_enum)
    local debuff_timer_color = _require_control_color(controls, prefix .. "_debuff_timer_font_color")
    local debuff_timer_outline = _require_control_color(controls, prefix .. "_debuff_timer_font_outline_color")

    local function layout_icons(icons, area_w, area_h, icon_size, cols, times, font, style, color, outline,
                                reverse_fill_enabled)
        local columns = cols
        if columns < 1 then columns = 1 end
        for i = 1, #icons do
            local icon = icons[i]
            local size = icon_size
            if size > area_h then
                size = area_h
            end
            if size < 1 then
                size = 1
            end

            local idx = i - 1
            local x = 0
            local y = 0
            if reverse_fill_enabled == true then
                local col_from_right = idx % columns
                local row_from_bottom = math.floor(idx / columns)
                x = area_w - ((col_from_right + 1) * size)
                y = area_h - ((row_from_bottom + 1) * size)
            else
                local col = idx % columns
                local row = math.floor(idx / columns)
                x = col * size
                y = row * size
            end
            if x < 0 then x = 0 end
            if y < 0 then y = 0 end

            icon.root:SetPosition(x, y)
            icon.root:SetSize(size, size)

            local icon_border = 1
            local inner_size = size - (2 * icon_border)
            if inner_size < 1 then inner_size = 1 end
            icon.inner:SetPosition(icon_border, icon_border)
            icon.inner:SetSize(inner_size, inner_size)

            icon.timer:SetPosition(0, 0)
            icon.timer:SetSize(size, size)
            icon.timer:SetFont(font)
            icon.timer:SetFontStyle(style)
            icon.timer:SetForeColor(color)
            icon.timer:SetOutlineColor(outline)
            icon.timer:SetText(_timer_text(times[i]))
        end
    end

    local debuff_times = { 8.4, 2.6 }
    layout_icons(self.debuff_icons, frame_w, debuff_area_h, debuff_icon, debuff_cols, debuff_times, debuff_timer_font,
        debuff_timer_style, debuff_timer_color, debuff_timer_outline, reverse_fill)

    local buff_times = { 6.2, 1.8 }
    layout_icons(self.buff_icons, frame_w, buff_area_h, buff_icon, buff_cols, buff_times, buff_timer_font,
        buff_timer_style, buff_timer_color, buff_timer_outline, reverse_fill)

    local morale_bg = _require_control_color(controls, prefix .. "_morale_background_color")
    local ressource_bg_matches_missing = controls[prefix .. "_ressource_background_matches_missing"].cb:IsChecked() == true
    local ressource_bg_dimming = _require_control_number(controls, prefix .. "_ressource_background_dimming")
    local border_color = _require_control_color(controls, prefix .. "_border_color")
    local bubble_color = _require_control_color(controls, prefix .. "_morale_bubble_color")
    local high_color = _require_control_color(controls, prefix .. "_morale_color_high")
    local med_color = _require_control_color(controls, prefix .. "_morale_color_medium")
    local low_color = _require_control_color(controls, prefix .. "_morale_color_low")
    local crit_color = _require_control_color(controls, prefix .. "_morale_color_critical")
    local morale_gradient = controls[prefix .. "_morale_gradient"].cb:IsChecked() == true
    local gradient_full = _require_control_color(controls, prefix .. "_morale_gradient_full")
    local gradient_mid = _require_control_color(controls, prefix .. "_morale_gradient_mid")
    local gradient_low = _require_control_color(controls, prefix .. "_morale_gradient_low")
    window:_update_gradient_preview(prefix .. "_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)

    local inner_w = frame_w - (2 * border)
    local inner_morale_h = morale_h - (2 * border)
    local inner_power_h = power_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_morale_h < 1 then inner_morale_h = 1 end
    if inner_power_h < 1 then inner_power_h = 1 end

    local morale_percent = 0.67
    local bubble_percent = 0.20
    local power_percent = 0.55

    self.morale_border:SetPosition(0, morale_top)
    self.morale_border:SetSize(frame_w, morale_h)
    self.morale_border:SetBackColor(border_color)

    self.morale_background:SetPosition(border, border)
    self.morale_background:SetSize(inner_w, inner_morale_h)
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, gradient_full, gradient_mid,
        gradient_low, high_color, med_color, low_color, crit_color)
    self.morale_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing, ressource_bg_dimming,
        morale_bg, morale_fill_color))

    local morale_fill_w = math.floor(inner_w * morale_percent + 0.5)
    if morale_fill_w < 0 then morale_fill_w = 0 end
    if morale_fill_w > inner_w then morale_fill_w = inner_w end

    self.morale_bar:SetPosition(0, 0)
    self.morale_bar:SetSize(morale_fill_w, inner_morale_h)
    self.morale_bar:SetBackColor(morale_fill_color)

    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        self.bubble_bar:SetVisible(true)
        self.bubble_bar:SetTop(0)
        self.bubble_bar:SetHeight(inner_morale_h)
        self.bubble_bar:SetWidth(bubble_w)

        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = morale_fill_w
        if left_inner > max_left then left_inner = max_left end
        self.bubble_bar:SetLeft(left_inner)
        self.bubble_bar:SetBackColor(bubble_color)
    else
        self.bubble_bar:SetVisible(false)
    end

    local bubble_fmt = controls[prefix .. "_morale_bubble_text"].tb:GetText()
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)

    local morale_max = 10000
    local morale_cur = math.floor(morale_max * morale_percent + 0.5)
    local bubble_max = math.floor(morale_max * bubble_percent + 0.5)
    local morale_pct_text = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%"

    local bubble_text = ""
    if bubble_max > 0 then
        bubble_text = lui_abbrev_number(bubble_max)
    end

    local bubble_formatted = ""
    if bubble_max > 0 and string.len(bubble_fmt) > 0 then
        bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
    end

    _render_preview_vital_labels(window, prefix, "morale", self.morale_labels, raw_scale, frame_w, morale_h, 16, {
        name = self.name_text,
        level = self.level_text,
        c = lui_abbrev_number(morale_cur),
        t = lui_abbrev_number(morale_max),
        p = morale_pct_text,
        b = bubble_text,
        B = bubble_formatted,
    })

    self.power_border:SetPosition(0, power_top)
    self.power_border:SetSize(frame_w, power_h)
    self.power_border:SetBackColor(border_color)

    self.power_background:SetPosition(border, border)
    self.power_background:SetSize(inner_w, inner_power_h)
    local power_color = _require_control_color(controls, prefix .. "_power_color")
    self.power_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing, ressource_bg_dimming,
        morale_bg, power_color))
    self.power_bar:SetPosition(0, 0)
    self.power_bar:SetSize(math.floor(inner_w * power_percent + 0.5), inner_power_h)
    self.power_bar:SetBackColor(power_color)

    local power_max = 30000
    local power_cur = math.floor(power_max * power_percent + 0.5)
    local power_pct_text = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"

    _render_preview_vital_labels(window, prefix, "power", self.power_labels, raw_scale, frame_w, power_h, 14, {
        name = self.name_text,
        level = self.level_text,
        c = lui_abbrev_number(power_cur),
        t = lui_abbrev_number(power_max),
        p = power_pct_text,
    })

    lui_clear_number_abbrev_preview_settings()
end

function ConfigWindow:_update_gradient_preview(control_key, full_color, mid_color, low_color)
    return Common.update_gradient_preview(self, control_key, full_color, mid_color, low_color)
end

function ConfigWindow:init_self_vitals_preview()
    if self.self_vitals_preview == nil then
        self.self_vitals_preview = StandardVitalsPreview(self, "self_vitals_preview", "self", TR["Player"], "")
    end
    return self.self_vitals_preview
end

function ConfigWindow:init_target_vitals_preview()
    if self.target_vitals_preview == nil then
        self.target_vitals_preview = StandardVitalsPreview(self, "target_vitals_preview", "target", TR["Target"], "150")
    end
    return self.target_vitals_preview
end

function ConfigWindow:update_self_vitals_preview()
    self:init_self_vitals_preview():update()
end

function ConfigWindow:update_target_vitals_preview()
    self:init_target_vitals_preview():update()
end
