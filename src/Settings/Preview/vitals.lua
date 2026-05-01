local Common = SettingsPreviewCommon
local _hex_to_color = Common.hex_to_color
local _require_font = Common.require_font
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
local DEFAULT_GRADIENT_MID_COLOR = Common.default_gradient_mid_color

import "LUI.src.Utils.vitals_labels"

local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_vital_label(window, prefix, bar_key, label_index, label, raw_scale, width, height,
                                           default_font_size, context)
    local controls = window.controls
    local key = prefix .. "_" .. bar_key .. "_label" .. tostring(label_index)
    local enabled = controls[key .. "_enabled"].cb:IsChecked() == true
    local text = controls[key .. "_text"].tb:GetText() or ""

    if enabled ~= true or _label_text_is_blank(text) == true then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local text_alignment = controls[key .. "_text_alignment"]:get_value()
    if type(text_alignment) ~= "number" then
        text_alignment = LUI_ENUMS.text_alignment.CENTER
    end

    local anchor = controls[key .. "_anchor"]:get_value()
    if type(anchor) ~= "number" then
        anchor = LUI_ENUMS.vitals_label_anchor.CENTER
    end

    local width_mode = controls[key .. "_width_mode"]:get_value()
    if type(width_mode) ~= "number" then
        width_mode = LUI_ENUMS.vitals_label_width_mode.FILL
    end

    local font_name = controls[key .. "_font_name"]:get_value()
    if type(font_name) ~= "number" then
        font_name = LUI_ENUMS.font_name.VERDANA
    end

    local font_size = _preview_scaled_number(raw_scale, controls[key .. "_font_size"].tb:GetText(), default_font_size)
    local font_style_enum = controls[key .. "_font_style"]:get_value()
    if type(font_style_enum) ~= "number" then
        font_style_enum = LUI_ENUMS.font_style.OUTLINE
    end

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
        _preview_scaled_int(raw_scale, controls[key .. "_x_offset"].tb:GetText(), 0),
        _preview_scaled_int(raw_scale, controls[key .. "_y_offset"].tb:GetText(), 0),
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

function ConfigWindow:init_self_vitals_preview()
    self:_init_vitals_preview("self_vitals_preview", false)
end

function ConfigWindow:_ensure_gradient_preview(control_key)
    return Common.ensure_gradient_preview(self, control_key)
end

function ConfigWindow:_update_gradient_preview(control_key, full_color, mid_color, low_color)
    return Common.update_gradient_preview(self, control_key, full_color, mid_color, low_color)
end

function ConfigWindow:init_target_vitals_preview()
    self:_init_vitals_preview("target_vitals_preview", false)
end

function ConfigWindow:update_self_vitals_preview()
    self:_update_vitals_preview("self")
end

function ConfigWindow:update_target_vitals_preview()
    self:_update_vitals_preview("target")
end

function ConfigWindow:_init_vitals_preview(holder_key, include_targets_target)
    local holder = self.controls[holder_key]
    if holder == nil or holder.control == nil then
        return nil
    end

    local state_key = holder_key
    if self[state_key] ~= nil then
        return self[state_key]
    end

    local p = {}
    self[state_key] = p

    p.container = holder.control
    p.container:SetMouseVisible(false)

    p.outer = Turbine.UI.Control()
    p.outer:SetParent(p.container)
    p.outer:SetMouseVisible(false)

    p.info_label = UI.Widgets.LuiLabel()
    p.info_label:SetParent(p.container)
    p.info_label:SetMouseVisible(false)
    p.info_label:SetMultiline(true)
    p.info_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.outer)
    p.root:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.outer)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_top:SetVisible(false)

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.outer)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_bottom:SetVisible(false)

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.outer)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_left:SetVisible(false)

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.outer)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    p.border_right:SetVisible(false)

    p.effects_debuffs = Turbine.UI.Control()
    p.effects_debuffs:SetParent(p.root)
    p.effects_debuffs:SetMouseVisible(false)
    p.effects_debuffs:SetBackColor(Turbine.UI.Color(0.32, 0.14, 0.14))

    p.effects_debuffs_label = UI.Widgets.LuiLabel()
    p.effects_debuffs_label:SetParent(p.effects_debuffs)
    p.effects_debuffs_label:SetMouseVisible(false)
    p.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    p.debuff_icons = {}
    for i = 1, 2 do
        local icon = {}

        icon.root = Turbine.UI.Control()
        icon.root:SetParent(p.effects_debuffs)
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

        p.debuff_icons[i] = icon
    end

    p.effects_buffs = Turbine.UI.Control()
    p.effects_buffs:SetParent(p.root)
    p.effects_buffs:SetMouseVisible(false)
    p.effects_buffs:SetBackColor(Turbine.UI.Color(0.14, 0.18, 0.32))

    p.effects_buffs_label = UI.Widgets.LuiLabel()
    p.effects_buffs_label:SetParent(p.effects_buffs)
    p.effects_buffs_label:SetMouseVisible(false)
    p.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)

    p.buff_icons = {}
    for i = 1, 2 do
        local icon = {}

        icon.root = Turbine.UI.Control()
        icon.root:SetParent(p.effects_buffs)
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

        p.buff_icons[i] = icon
    end

    p.morale_border = Turbine.UI.Control()
    p.morale_border:SetParent(p.root)
    p.morale_border:SetMouseVisible(false)

    p.morale_background = Turbine.UI.Control()
    p.morale_background:SetParent(p.morale_border)
    p.morale_background:SetMouseVisible(false)

    p.morale_bar = Turbine.UI.Control()
    p.morale_bar:SetParent(p.morale_background)
    p.morale_bar:SetMouseVisible(false)
    p.morale_bar:SetZOrder(1)

    p.bubble_bar = Turbine.UI.Control()
    p.bubble_bar:SetParent(p.morale_background)
    p.bubble_bar:SetMouseVisible(false)
    p.bubble_bar:SetZOrder(2)

    p.morale_labels = {}
    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(p.morale_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.morale_labels[i] = label
    end

    p.power_border = Turbine.UI.Control()
    p.power_border:SetParent(p.root)
    p.power_border:SetMouseVisible(false)

    p.power_background = Turbine.UI.Control()
    p.power_background:SetParent(p.power_border)
    p.power_background:SetMouseVisible(false)

    p.power_bar = Turbine.UI.Control()
    p.power_bar:SetParent(p.power_background)
    p.power_bar:SetMouseVisible(false)

    p.power_labels = {}
    for i = 1, 2 do
        local label = UI.Widgets.LuiLabel()
        label:SetParent(p.power_border)
        label:SetMouseVisible(false)
        label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        label:SetMultiline(true)
        label:SetZOrder(9 + i)
        p.power_labels[i] = label
    end

    p.include_targets_target = include_targets_target == true
    if p.include_targets_target then
        p.targets_target_background = Turbine.UI.Control()
        p.targets_target_background:SetParent(p.root)
        p.targets_target_background:SetMouseVisible(false)

        p.targets_target_bar = Turbine.UI.Control()
        p.targets_target_bar:SetParent(p.targets_target_background)
        p.targets_target_bar:SetMouseVisible(false)
        p.targets_target_bar:SetZOrder(1)

        p.targets_target_bubble = Turbine.UI.Control()
        p.targets_target_bubble:SetParent(p.targets_target_background)
        p.targets_target_bubble:SetMouseVisible(false)
        p.targets_target_bubble:SetZOrder(2)
        p.targets_target_bubble:SetVisible(false)

        p.targets_target_label = UI.Widgets.LuiLabel()
        p.targets_target_label:SetParent(p.targets_target_background)
        p.targets_target_label:SetMouseVisible(false)
        p.targets_target_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        p.targets_target_label:SetZOrder(10)
    end

    return p
end

function ConfigWindow:_update_vitals_preview(kind)
    local is_target = kind == "target"

    local p = is_target and self.target_vitals_preview or self.self_vitals_preview
    if p == nil then
        if is_target then
            self:init_target_vitals_preview()
            p = self.target_vitals_preview
        else
            self:init_self_vitals_preview()
            p = self.self_vitals_preview
        end
    end
    if p == nil then
        return
    end

    local raw_scale = tonumber(self.controls.scale.tb:GetText()) or 1
    if raw_scale <= 0 then raw_scale = 1 end

    local prefix = is_target and "target" or "self"

    local raw_frame_w = tonumber(self.controls[prefix .. "_width"].tb:GetText()) or 250
    local raw_border = tonumber(self.controls[prefix .. "_border_width"].tb:GetText()) or 1
    local frame_w = _preview_scaled_int(raw_scale, raw_frame_w, 250)
    local border = _preview_scaled_border(raw_scale, raw_border, 1)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_morale_h = tonumber(self.controls[prefix .. "_morale_height"].tb:GetText()) or 50
    local raw_power_h = tonumber(self.controls[prefix .. "_power_height"].tb:GetText()) or 26
    local morale_h = _preview_scaled_int(raw_scale, raw_morale_h, 50)
    local power_h = _preview_scaled_int(raw_scale, raw_power_h, 26)
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end

    local raw_effects_h = tonumber(self.controls[prefix .. "_effects_height"].tb:GetText()) or 200
    local effects_height = _preview_scaled_int(raw_scale, raw_effects_h, 200)
    local effects_half = effects_height / 2

    local raw_effects_position = self.controls[prefix .. "_effects_position"]:get_value()
    raw_effects_position = tonumber(raw_effects_position) or LUI_ENUMS.vitals_effects_position.ABOVE
    local effects_below = raw_effects_position == LUI_ENUMS.vitals_effects_position.BELOW

    local raw_buff_size = tonumber(self.controls[prefix .. "_buff_size"].tb:GetText()) or 32
    local raw_debuff_size = tonumber(self.controls[prefix .. "_debuff_size"].tb:GetText()) or 36
    local buff_icon = _preview_scaled_int(raw_scale, raw_buff_size, 32)
    local debuff_icon = _preview_scaled_int(raw_scale, raw_debuff_size, 36)
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

    local label_font = self.field_label_font
    local info_h = _scaled_int(46)
    local preview_border = 1
    local root_inner_h = effects_height + morale_h + power_h - border
    if root_inner_h < 1 then root_inner_h = 1 end
    local desired_h_inner = info_h + root_inner_h + _scaled_int(9)
    local desired_h = desired_h_inner + (2 * preview_border)
    local holder = self.controls[is_target and "target_vitals_preview" or "self_vitals_preview"]
    _sync_preview_holder_height(self, holder, desired_h)

    local cw, ch = p.container:GetSize()
    local root_outer_h = root_inner_h + (2 * preview_border)
    local outer_w = frame_w + (2 * preview_border)
    local x = math.floor((cw - outer_w) / 2)
    if x < 0 then x = 0 end
    local y = _scaled_int(4)
    if y < 0 then y = 0 end

    if p.info_label ~= nil then
        local info_w = cw
        if info_w == nil or info_w < 1 then
            info_w = frame_w
        end
        local info_font = _scaled_font(LUI_ENUMS.font_name.VERDANA, 13)
        p.info_label:SetPosition(0, y)
        p.info_label:SetSize(info_w, info_h)
        p.info_label:SetFont(info_font)
        p.info_label:SetForeColor(Turbine.UI.Color(0.85, 0.85, 0.85))
        p.info_label:SetText(
            TR["Buffs area auto-resizes to the number of rows, up to the max height. Debuffs fill the remaining effects height. Effects can be placed above Morale or below Power."]
        )
    end

    y = y + info_h
    p.outer:SetPosition(x, y)
    p.outer:SetSize(outer_w, root_outer_h)
    p.root:SetPosition(preview_border, preview_border)
    p.root:SetSize(frame_w, root_inner_h)
    _apply_preview_border(p, outer_w, root_outer_h)

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
        p.effects_buffs:SetPosition(0, effects_top)
        p.effects_buffs:SetSize(frame_w, buff_area_h)
        p.effects_debuffs:SetPosition(0, effects_top + buff_area_h)
        p.effects_debuffs:SetSize(frame_w, debuff_area_h)
    else
        p.effects_debuffs:SetPosition(0, effects_top)
        p.effects_debuffs:SetSize(frame_w, debuff_area_h)
        p.effects_buffs:SetPosition(0, effects_top + debuff_area_h)
        p.effects_buffs:SetSize(frame_w, buff_area_h)
    end

    local debuff_label_h = 16
    if debuff_label_h > debuff_area_h then
        debuff_label_h = debuff_area_h
    end
    local buff_label_h = 16
    if buff_label_h > buff_area_h then
        buff_label_h = buff_area_h
    end

    p.effects_debuffs_label:SetFont(label_font)
    p.effects_debuffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    p.effects_debuffs_label:SetPosition(0, 0)
    p.effects_debuffs_label:SetSize(frame_w, debuff_label_h)
    p.effects_debuffs_label:SetText(string.format(TR["Debuffs: max %d (%dx%d)"], max_debuffs, debuff_cols, debuff_rows))

    p.effects_buffs_label:SetFont(label_font)
    p.effects_buffs_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
    p.effects_buffs_label:SetPosition(0, 0)
    p.effects_buffs_label:SetSize(frame_w, buff_label_h)
    p.effects_buffs_label:SetText(string.format(TR["Buffs: max %d (%dx%d)"], max_buffs, buff_cols, buff_rows))

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
        return LUI_TO_LOTRO.font_style[style_enum] or Turbine.UI.FontStyle.None
    end

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local buff_timer_font_name = self.controls[prefix .. "_buff_timer_font_name"]:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_buff_timer_font_size = tonumber(self.controls[prefix .. "_buff_timer_font_size"].tb:GetText()) or 12
    local buff_timer_font_size = _preview_scaled_number(raw_scale, raw_buff_timer_font_size, 12)
    local buff_timer_font = _require_font(buff_timer_font_name, buff_timer_font_size)
    local buff_timer_style_enum = self.controls[prefix .. "_buff_timer_font_style"]:get_value() or
        LUI_ENUMS.font_style.OUTLINE
    local buff_timer_style = _timer_style(buff_timer_style_enum)
    local buff_timer_color = _hex_to_color(self.controls[prefix .. "_buff_timer_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local buff_timer_outline = _hex_to_color(self.controls[prefix .. "_buff_timer_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local debuff_timer_font_name = self.controls[prefix .. "_debuff_timer_font_name"]:get_value() or
        LUI_ENUMS.font_name.VERDANA
    local raw_debuff_timer_font_size = tonumber(self.controls[prefix .. "_debuff_timer_font_size"].tb:GetText()) or 25
    local debuff_timer_font_size = _preview_scaled_number(raw_scale, raw_debuff_timer_font_size, 25)
    local debuff_timer_font = _require_font(debuff_timer_font_name, debuff_timer_font_size)
    local debuff_timer_style_enum = self.controls[prefix .. "_debuff_timer_font_style"]:get_value() or
        LUI_ENUMS.font_style.OUTLINE
    local debuff_timer_style = _timer_style(debuff_timer_style_enum)
    local debuff_timer_color = _hex_to_color(self.controls[prefix .. "_debuff_timer_font_color"].tb:GetText())
        or Turbine.UI.Color(1, 1, 1)
    local debuff_timer_outline = _hex_to_color(self.controls[prefix .. "_debuff_timer_font_outline_color"].tb:GetText())
        or Turbine.UI.Color(0, 0, 0)

    local function layout_icons(icons, area_w, area_h, icon_size, cols, times, font, style, color, outline,
                                reverse_fill_enabled)
        if icons == nil then
            return
        end
        local columns = cols
        if columns < 1 then columns = 1 end
        for i = 1, #icons do
            local icon = icons[i]
            if icon ~= nil and icon.root ~= nil and icon.timer ~= nil then
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

                local preview_border = 1
                local inner_size = size - (2 * preview_border)
                if inner_size < 1 then inner_size = 1 end
                if icon.inner ~= nil then
                    icon.inner:SetPosition(preview_border, preview_border)
                    icon.inner:SetSize(inner_size, inner_size)
                end

                icon.timer:SetPosition(0, 0)
                icon.timer:SetSize(size, size)
                icon.timer:SetFont(font)
                icon.timer:SetFontStyle(style)
                icon.timer:SetForeColor(color)
                icon.timer:SetOutlineColor(outline)
                icon.timer:SetText(_timer_text(times[i]))
            end
        end
    end

    local debuff_times = { 8.4, 2.6 }
    if p.debuff_icons ~= nil then
        layout_icons(p.debuff_icons, frame_w, debuff_area_h, debuff_icon, debuff_cols, debuff_times, debuff_timer_font,
            debuff_timer_style, debuff_timer_color, debuff_timer_outline, reverse_fill)
    end

    local buff_times = { 6.2, 1.8 }
    if p.buff_icons ~= nil then
        layout_icons(p.buff_icons, frame_w, buff_area_h, buff_icon, buff_cols, buff_times, buff_timer_font,
            buff_timer_style, buff_timer_color, buff_timer_outline, reverse_fill)
    end

    local morale_bg = _hex_to_color(self.controls[prefix .. "_morale_background_color"].tb:GetText()) or
        Turbine.UI.Color(0, 0, 0)
    local ressource_bg_matches_missing = self.controls[prefix .. "_ressource_background_matches_missing"].cb:IsChecked() ==
        true
    local ressource_bg_dimming = tonumber(self.controls[prefix .. "_ressource_background_dimming"].tb:GetText()) or 0.75
    local border_color = _hex_to_color(self.controls[prefix .. "_border_color"].tb:GetText()) or morale_bg
    local bubble_color = _hex_to_color(self.controls[prefix .. "_morale_bubble_color"].tb:GetText()) or
        Turbine.UI.Color(0.53, 0.8, 0.98)
    local high_color = _hex_to_color(self.controls[prefix .. "_morale_color_high"].tb:GetText()) or
        Turbine.UI.Color(0.290196, 0.639216, 0.286275)
    local med_color = _hex_to_color(self.controls[prefix .. "_morale_color_medium"].tb:GetText()) or
        Turbine.UI.Color(0.650980, 0.803922, 0.196078)
    local low_color = _hex_to_color(self.controls[prefix .. "_morale_color_low"].tb:GetText()) or
        Turbine.UI.Color(0.87, 0.55, 0)
    local crit_color = _hex_to_color(self.controls[prefix .. "_morale_color_critical"].tb:GetText()) or
        Turbine.UI.Color(0.87, 0.11, 0)
    local morale_gradient = self.controls[prefix .. "_morale_gradient"].cb:IsChecked() == true
    local gradient_full = _hex_to_color(self.controls[prefix .. "_morale_gradient_full"].tb:GetText()) or high_color
    local gradient_mid = _hex_to_color(self.controls[prefix .. "_morale_gradient_mid"].tb:GetText()) or
        DEFAULT_GRADIENT_MID_COLOR
    local gradient_low = _hex_to_color(self.controls[prefix .. "_morale_gradient_low"].tb:GetText()) or crit_color
    self:_update_gradient_preview(prefix .. "_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)

    local inner_w = frame_w - (2 * border)
    local inner_morale_h = morale_h - (2 * border)
    local inner_power_h = power_h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_morale_h < 1 then inner_morale_h = 1 end
    if inner_power_h < 1 then inner_power_h = 1 end

    local morale_percent = 0.67
    local bubble_percent = 0.20
    local power_percent = 0.55

    p.morale_border:SetPosition(0, morale_top)
    p.morale_border:SetSize(frame_w, morale_h)
    p.morale_border:SetBackColor(border_color)

    p.morale_background:SetPosition(border, border)
    p.morale_background:SetSize(inner_w, inner_morale_h)
    local morale_fill_color = _morale_color_preview(morale_percent, morale_gradient, gradient_full, gradient_mid,
        gradient_low, high_color, med_color, low_color, crit_color)
    p.morale_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing, ressource_bg_dimming,
        morale_bg, morale_fill_color))

    local morale_fill_w = math.floor(inner_w * morale_percent + 0.5)
    if morale_fill_w < 0 then morale_fill_w = 0 end
    if morale_fill_w > inner_w then morale_fill_w = inner_w end

    p.morale_bar:SetPosition(0, 0)
    p.morale_bar:SetSize(morale_fill_w, inner_morale_h)
    p.morale_bar:SetBackColor(morale_fill_color)

    local bubble_w = math.floor(inner_w * bubble_percent + 0.5)
    if bubble_w < 0 then bubble_w = 0 end
    if bubble_w > inner_w then bubble_w = inner_w end

    if bubble_w > 0 then
        p.bubble_bar:SetVisible(true)
        p.bubble_bar:SetTop(0)
        p.bubble_bar:SetHeight(inner_morale_h)
        p.bubble_bar:SetWidth(bubble_w)

        local max_left = inner_w - bubble_w
        if max_left < 0 then max_left = 0 end
        local left_inner = morale_fill_w
        if left_inner > max_left then left_inner = max_left end
        p.bubble_bar:SetLeft(left_inner)
        p.bubble_bar:SetBackColor(bubble_color)
    else
        p.bubble_bar:SetVisible(false)
    end

    local bubble_fmt = self.controls[prefix .. "_morale_bubble_text"].tb:GetText() or ""
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)

    local morale_max = 10000
    local morale_cur = math.floor(morale_max * morale_percent + 0.5)
    local bubble_max = math.floor(morale_max * bubble_percent + 0.5)
    local morale_pct_text = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%"

    local name = is_target and TR["Target"] or TR["Player"]
    local level = is_target and "150" or ""
    local bubble_text = ""
    if bubble_max > 0 then
        bubble_text = lui_abbrev_number(bubble_max)
    end

    local bubble_formatted = ""
    if bubble_max > 0 and string.len(bubble_fmt) > 0 then
        bubble_formatted = lui_format_tokenized(bubble_fmt_tokens, { b = bubble_text })
    end

    _render_preview_vital_labels(self, prefix, "morale", p.morale_labels, raw_scale, frame_w, morale_h, 16, {
        name = name,
        level = level,
        c = lui_abbrev_number(morale_cur),
        t = lui_abbrev_number(morale_max),
        p = morale_pct_text,
        b = bubble_text,
        B = bubble_formatted,
    })

    p.power_border:SetPosition(0, power_top)
    p.power_border:SetSize(frame_w, power_h)
    p.power_border:SetBackColor(border_color)

    p.power_background:SetPosition(border, border)
    p.power_background:SetSize(inner_w, inner_power_h)
    local power_color = _hex_to_color(self.controls[prefix .. "_power_color"].tb:GetText()) or
        Turbine.UI.Color(0.2, 0.6, 0.98)
    p.power_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing, ressource_bg_dimming,
        morale_bg, power_color))
    p.power_bar:SetPosition(0, 0)
    p.power_bar:SetSize(math.floor(inner_w * power_percent + 0.5), inner_power_h)
    p.power_bar:SetBackColor(power_color)

    local power_max = 30000
    local power_cur = math.floor(power_max * power_percent + 0.5)
    local power_pct_text = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"

    _render_preview_vital_labels(self, prefix, "power", p.power_labels, raw_scale, frame_w, power_h, 14, {
        name = name,
        level = level,
        c = lui_abbrev_number(power_cur),
        t = lui_abbrev_number(power_max),
        p = power_pct_text,
    })
    if p.include_targets_target and p.targets_target_background ~= nil then
        p.targets_target_background:SetVisible(false)
    end

    lui_clear_number_abbrev_preview_settings()
end
