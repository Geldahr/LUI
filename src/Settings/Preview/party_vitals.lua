import "LUI.src.UI.Widgets"
import "LUI.src.Utils.vitals_labels"

local Common = SettingsPreviewCommon
local _require_font = Common.require_font
local _require_control_color = Common.require_control_color
local _require_control_enum = Common.require_control_enum
local _require_control_number = Common.require_control_number
local _require_positive_scale = Common.require_positive_scale
local _apply_preview_border = Common.apply_preview_border
local _preview_number_abbrev_settings = Common.preview_number_abbrev_settings
local _morale_color_preview = Common.morale_color_preview
local _preview_scaled_int = Common.preview_scaled_int
local _preview_scaled_border = Common.preview_scaled_border
local _preview_scaled_number = Common.preview_scaled_number
local _preview_resource_background = Common.preview_resource_background
local _sync_preview_holder_height = Common.sync_preview_holder_height
local function _label_text_is_blank(text)
    return type(text) ~= "string" or string.len((text:gsub("%s+", ""))) == 0
end

local function _render_preview_vital_label(window, prefix, bar_key, label_index, label, raw_scale, targets, context)
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
    local link_to = _require_control_enum(controls, key .. "_link_to")
    local font_name = _require_control_enum(controls, key .. "_font_name")
    local font_size = _preview_scaled_number(raw_scale, _require_control_number(controls, key .. "_font_size"))
    local font_style_enum = _require_control_enum(controls, key .. "_font_style")
    local target = targets[link_to]

    if target == nil then
        label:SetText("")
        label:SetVisible(false)
        return
    end

    local rendered_text = lui_format_tokenized(lui_tokenize_format(text), context)

    if label:GetParent() ~= target.parent then
        label:SetParent(target.parent)
    end
    label:SetFont(_require_font(font_name, font_size))
    label:SetFontStyle(LUI_TO_LOTRO.font_style[font_style_enum])
    label:SetForeColor(_require_control_color(controls, key .. "_font_color"))
    label:SetOutlineColor(_require_control_color(controls, key .. "_font_outline_color"))

    lui_vitals_layout_label(
        label,
        target.width,
        target.height,
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

local function _render_preview_vital_labels(window, prefix, bar_key, labels, raw_scale, targets, context)
    for i = 1, #labels do
        _render_preview_vital_label(window, prefix, bar_key, i, labels[i], raw_scale, targets, context)
    end
end

function ConfigWindow:init_party_vitals_preview()
    local holder = self.controls.party_vitals_preview

    if self.party_vitals_preview ~= nil then
        return
    end

    self.party_vitals_preview = {
        container = holder.control,
        members = {},
        max_members = 24,
    }

    local p = self.party_vitals_preview
    p.container:SetMouseVisible(false)

    p.border_top = Turbine.UI.Control()
    p.border_top:SetParent(p.container)
    p.border_top:SetMouseVisible(false)
    p.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_bottom = Turbine.UI.Control()
    p.border_bottom:SetParent(p.container)
    p.border_bottom:SetMouseVisible(false)
    p.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_left = Turbine.UI.Control()
    p.border_left:SetParent(p.container)
    p.border_left:SetMouseVisible(false)
    p.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.border_right = Turbine.UI.Control()
    p.border_right:SetParent(p.container)
    p.border_right:SetMouseVisible(false)
    p.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    p.root = Turbine.UI.Control()
    p.root:SetParent(p.container)
    p.root:SetMouseVisible(false)

    for i = 1, p.max_members do
        local m = {}

        m.root = Turbine.UI.Control()
        m.root:SetParent(p.root)
        m.root:SetMouseVisible(false)

        m.class_icon = Image()
        m.class_icon:SetParent(m.root)
        m.class_icon:SetZOrder(9)
        m.class_icon:SetVisible(false)

        m.leader_icon = Image()
        m.leader_icon:SetParent(m.root)
        m.leader_icon:SetZOrder(10)
        m.leader_icon:SetVisible(false)

        m.morale_border = Turbine.UI.Control()
        m.morale_border:SetParent(m.root)
        m.morale_border:SetMouseVisible(false)

        m.morale_background = Turbine.UI.Control()
        m.morale_background:SetParent(m.morale_border)
        m.morale_background:SetMouseVisible(false)

        m.morale_bar = Turbine.UI.Control()
        m.morale_bar:SetParent(m.morale_background)
        m.morale_bar:SetMouseVisible(false)
        m.morale_bar:SetZOrder(1)

        m.bubble_bar = Turbine.UI.Control()
        m.bubble_bar:SetParent(m.morale_background)
        m.bubble_bar:SetMouseVisible(false)
        m.bubble_bar:SetZOrder(2)

        m.morale_labels = {}
        for j = 1, 2 do
            local label = UI.Widgets.LuiLabel()
            label:SetParent(m.morale_border)
            label:SetMouseVisible(false)
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            label:SetMultiline(true)
            label:SetZOrder(9 + j)
            m.morale_labels[j] = label
        end

        m.power_border = Turbine.UI.Control()
        m.power_border:SetParent(m.root)
        m.power_border:SetMouseVisible(false)

        m.power_background = Turbine.UI.Control()
        m.power_background:SetParent(m.power_border)
        m.power_background:SetMouseVisible(false)

        m.power_bar = Turbine.UI.Control()
        m.power_bar:SetParent(m.power_background)
        m.power_bar:SetMouseVisible(false)

        m.power_labels = {}
        for j = 1, 2 do
            local label = UI.Widgets.LuiLabel()
            label:SetParent(m.power_border)
            label:SetMouseVisible(false)
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            label:SetMultiline(true)
            label:SetZOrder(9 + j)
            m.power_labels[j] = label
        end

        m.info_border = Turbine.UI.Control()
        m.info_border:SetParent(m.root)
        m.info_border:SetMouseVisible(false)

        m.info_background = Turbine.UI.Control()
        m.info_background:SetParent(m.info_border)
        m.info_background:SetMouseVisible(false)

        table.insert(p.members, m)
    end

    self:update_party_vitals_preview()
end

function ConfigWindow:update_party_vitals_preview()
    if self.party_vitals_preview == nil then
        self:init_party_vitals_preview()
    end

    local raw_scale = _require_positive_scale(self)

    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(self))

    local raw_rows = _require_control_number(self.controls, "party_rows")
    local rows = raw_rows
    if rows < 1 then rows = 1 end

    local raw_spacing_x = _require_control_number(self.controls, "party_spacing_x")
    local raw_spacing_y = _require_control_number(self.controls, "party_spacing_y")
    local spacing_x = _preview_scaled_int(raw_scale, raw_spacing_x)
    local spacing_y = _preview_scaled_int(raw_scale, raw_spacing_y)
    if spacing_x < 0 then spacing_x = 0 end
    if spacing_y < 0 then spacing_y = 0 end

    local raw_frame_w = _require_control_number(self.controls, "party_width")
    local raw_border = _require_control_number(self.controls, "party_border_width")
    local frame_w = _preview_scaled_int(raw_scale, raw_frame_w)
    local border = _preview_scaled_border(raw_scale, raw_border)
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local raw_morale_h = _require_control_number(self.controls, "party_morale_height")
    local raw_power_h = _require_control_number(self.controls, "party_power_height")
    local morale_h = _preview_scaled_int(raw_scale, raw_morale_h)
    local power_h = _preview_scaled_int(raw_scale, raw_power_h)
    local info_enabled = self.controls.party_info_enabled.cb:IsChecked() == true
    local info_h = info_enabled == true and
        _preview_scaled_int(raw_scale, _require_control_number(self.controls, "party_info_height")) or 0
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end
    if info_h < 0 then info_h = 0 end

    local icon_enabled = self.controls.party_class_icon_enabled.cb:IsChecked()

    local raw_icon_size = _require_control_number(self.controls, "party_class_icon_size")
    local raw_icon_x = _require_control_number(self.controls, "party_class_icon_x")
    local raw_icon_y = _require_control_number(self.controls, "party_class_icon_y")
    local icon_size = _preview_scaled_int(raw_scale, raw_icon_size)
    local icon_x = _preview_scaled_int(raw_scale, raw_icon_x)
    local icon_y = _preview_scaled_int(raw_scale, raw_icon_y)
    if icon_size < 16 then icon_size = 16 end
    if icon_size > 50 then icon_size = 50 end

    local leader_enabled = self.controls.party_leader_icon_enabled.cb:IsChecked()

    local raw_leader_size = _require_control_number(self.controls, "party_leader_icon_size")
    local raw_leader_x = _require_control_number(self.controls, "party_leader_icon_x")
    local raw_leader_y = _require_control_number(self.controls, "party_leader_icon_y")
    local leader_size = _preview_scaled_int(raw_scale, raw_leader_size)
    local leader_x = _preview_scaled_int(raw_scale, raw_leader_x)
    local leader_y = _preview_scaled_int(raw_scale, raw_leader_y)
    if leader_size < 16 then leader_size = 16 end
    if leader_size > 50 then leader_size = 50 end

    local power_y = morale_h - border
    local info_y = power_y + power_h - border
    local member_h = morale_h + power_h - border
    if info_h > 0 then
        member_h = member_h + info_h - border
    end
    if member_h < 1 then member_h = 1 end

    local morale_bg = _require_control_color(self.controls, "party_morale_background_color")
    local border_color = _require_control_color(self.controls, "party_border_color")
    local info_bg = _require_control_color(self.controls, "party_info_background_color")
    local info_opacity = _require_control_number(self.controls, "party_info_opacity")
    local bubble_color = _require_control_color(self.controls, "party_morale_bubble_color")
    local neutral_color = _require_control_color(self.controls, "party_morale_color_neutral")
    local high_color = _require_control_color(self.controls, "party_morale_color_high")
    local med_color = _require_control_color(self.controls, "party_morale_color_medium")
    local low_color = _require_control_color(self.controls, "party_morale_color_low")
    local crit_color = _require_control_color(self.controls, "party_morale_color_critical")
    local morale_gradient = self.controls.party_morale_gradient.cb:IsChecked() == true
    local gradient_full = _require_control_color(self.controls, "party_morale_gradient_full")
    local gradient_mid = _require_control_color(self.controls, "party_morale_gradient_mid")
    local gradient_low = _require_control_color(self.controls, "party_morale_gradient_low")
    Common.update_gradient_preview(self, "party_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)
    local ressource_bg_matches_missing = self.controls.party_ressource_background_matches_missing.cb:IsChecked() == true
    local ressource_bg_dimming = _require_control_number(self.controls, "party_ressource_background_dimming")

    local power_color = _require_control_color(self.controls, "party_power_color")
    local wrath_color = _require_control_color(self.controls, "party_wrath_color")

    local bubble_fmt = self.controls.party_morale_bubble_text.tb:GetText()
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)

    local preview_count = 24
    local columns = math.ceil(preview_count / rows)
    if columns < 1 then columns = 1 end

    local used_rows = preview_count
    if used_rows > rows then used_rows = rows end
    if used_rows < 1 then used_rows = 1 end

    local total_w = (columns * frame_w) + ((columns - 1) * spacing_x)
    local total_h = (used_rows * member_h) + ((used_rows - 1) * spacing_y)

    local holder = self.controls.party_vitals_preview
    local preview_border = 1
    local desired_height = total_h + 12 + (2 * preview_border)
    if desired_height < 80 then desired_height = 80 end
    _sync_preview_holder_height(self, holder, desired_height)

    local p = self.party_vitals_preview
    local outer_w = total_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local container_w = p.container:GetWidth() or outer_w
    local container_h = p.container:GetHeight() or outer_h
    local off_x = math.max(0, math.floor((container_w - outer_w) / 2))
    local off_y = math.max(0, math.floor((container_h - outer_h) / 2))
    if p.root ~= nil then
        p.root:SetPosition(off_x + preview_border, off_y + preview_border)
        p.root:SetSize(total_w, total_h)
    end
    _apply_preview_border(p, outer_w, outer_h, off_x, off_y)

    local icon_classes = _G.CLASS_ICON_CLASSES

    for i = 1, #p.members do
        local m = p.members[i]
        if m == nil then
            -- skip
        elseif i > preview_count then
            m.root:SetVisible(false)
        else
            m.root:SetVisible(true)

            local idx = i - 1
            local col = math.floor(idx / rows)
            local row = idx - (col * rows)
            local x = col * (frame_w + spacing_x)
            local y = row * (member_h + spacing_y)
            m.root:SetPosition(x, y)
            m.root:SetSize(frame_w, member_h)

            if icon_enabled == true and icon_size > 0 then
                m.class_icon:SetVisible(true)
                local icon = _G.get_class_icon(icon_classes[((i - 1) % #icon_classes) + 1], icon_size)
                if icon ~= nil then
                    m.class_icon:SetPosition(icon_x, icon_y)
                    m.class_icon:set_icon(icon, icon_size, icon_size)
                else
                    m.class_icon:SetVisible(false)
                end
            else
                m.class_icon:SetVisible(false)
            end

            if leader_enabled == true and leader_size > 0 and i == 1 then
                m.leader_icon:SetVisible(true)
                local icon = _G.get_party_leader_icon ~= nil and _G.get_party_leader_icon() or nil
                if icon ~= nil then
                    m.leader_icon:SetPosition(leader_x, leader_y)
                    m.leader_icon:set_icon(icon, leader_size, leader_size)
                else
                    m.leader_icon:SetVisible(false)
                end
            else
                m.leader_icon:SetVisible(false)
            end

            m.morale_border:SetPosition(0, 0)
            m.morale_border:SetSize(frame_w, morale_h)
            m.morale_border:SetBackColor(border_color)

            local inner_w = frame_w - (2 * border)
            local inner_morale_h = morale_h - (2 * border)
            if inner_w < 1 then inner_w = 1 end
            if inner_morale_h < 1 then inner_morale_h = 1 end

            m.morale_background:SetPosition(border, border)
            m.morale_background:SetSize(inner_w, inner_morale_h)
            m.morale_background:SetBackColor(morale_bg)

            m.morale_bar:SetPosition(0, 0)
            m.morale_bar:SetSize(inner_w, inner_morale_h)

            local morale_samples = {
                { max = 9999, cur = 9999, bubble = 0 },
                { max = 200000, cur = 101234, bubble = 0 },
                { max = 150000, cur = 120345, bubble = 25000 },
                { max = 120000, cur = 120000, bubble = 15000 },
                { max = 250000, cur = 123456, bubble = 40000 },
                { max = 999, cur = 875, bubble = 0 },
                { max = 12345, cur = 9876, bubble = 0 },
                { max = 54321, cur = 23456, bubble = 0 },
                { max = 100000, cur = 99999, bubble = 0 },
                { max = 250000, cur = 123456, bubble = 0 },
                { max = 999999, cur = 888888, bubble = 0 },
                { max = 10000, cur = 4321, bubble = 0 },
                { max = 99999, cur = 54321, bubble = 0 },
                { max = 600000, cur = 499999, bubble = 0 },
                { max = 45000, cur = 12345, bubble = 0 },
            }

            local sample = morale_samples[((i - 1) % #morale_samples) + 1]
            local morale_max = sample.max
            local morale_cur = sample.cur
            local bubble_cur = sample.bubble

            if morale_max <= 0 then morale_max = 1 end
            if morale_cur < 0 then morale_cur = 0 end
            if bubble_cur < 0 then bubble_cur = 0 end
            if morale_cur > morale_max then
                morale_cur = morale_max
            end

            local morale_percent = morale_cur / morale_max
            if morale_percent < 0 then morale_percent = 0 end
            if morale_percent > 1 then morale_percent = 1 end
            local morale_fill_w = math.floor((inner_w * morale_percent) + 0.5)
            if morale_fill_w < 0 then morale_fill_w = 0 end
            if morale_fill_w > inner_w then morale_fill_w = inner_w end
            local fill_color = _morale_color_preview(morale_percent, morale_gradient, gradient_full, gradient_mid,
                gradient_low, high_color, med_color, low_color, crit_color)
            m.morale_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing,
                ressource_bg_dimming, morale_bg, fill_color))
            m.morale_bar:SetBackColor(fill_color)
            m.morale_bar:SetWidth(morale_fill_w)

            local bubble_percent = 0.0
            if bubble_cur > 0 then
                bubble_percent = bubble_cur / morale_max
                if bubble_percent < 0 then bubble_percent = 0 end
                if bubble_percent > 1 then bubble_percent = 1 end
            end
            local bubble_w = math.floor((inner_w * bubble_percent) + 0.5)
            if bubble_w < 0 then bubble_w = 0 end
            if bubble_w > inner_w then bubble_w = inner_w end
            if bubble_w > 0 then
                m.bubble_bar:SetVisible(true)
                m.bubble_bar:SetTop(0)
                m.bubble_bar:SetHeight(inner_morale_h)
                m.bubble_bar:SetWidth(bubble_w)
                local max_left = inner_w - bubble_w
                if max_left < 0 then max_left = 0 end
                local left_inner = morale_fill_w
                if left_inner > max_left then left_inner = max_left end
                m.bubble_bar:SetLeft(left_inner)
                m.bubble_bar:SetBackColor(bubble_color)
            else
                m.bubble_bar:SetVisible(false)
            end

            local bubble_text = ""
            if bubble_cur > 0 then
                bubble_text = lui_abbrev_number(bubble_cur)
            end
            local morale_pct_text = tostring(math.floor(morale_percent * 100 + 0.5)) .. "%"
            local label_context = {
                mc = lui_abbrev_number(morale_cur),
                mt = lui_abbrev_number(morale_max),
                mp = morale_pct_text,
                b = bubble_text,
                B = "",
                pc = "-",
                pt = "-",
                pp = "-",
                name = TR["Player "] .. tostring(i),
                level = "150",
            }

            if bubble_cur > 0 and string.len(bubble_fmt) > 0 then
                label_context.B = lui_format_tokenized(bubble_fmt_tokens, { b = label_context.b })
            end

            local label_targets = {
                [LUI_ENUMS.vitals_label_link.MORALE] = {
                    parent = m.morale_border,
                    width = frame_w,
                    height = morale_h,
                },
                [LUI_ENUMS.vitals_label_link.POWER] = {
                    parent = m.power_border,
                    width = frame_w,
                    height = power_h,
                },
                [LUI_ENUMS.vitals_label_link.INFO] = info_h > 0 and {
                    parent = m.info_border,
                    width = frame_w,
                    height = info_h,
                } or nil,
            }
            m.power_border:SetPosition(0, power_y)
            m.power_border:SetSize(frame_w, power_h)
            m.power_border:SetBackColor(border_color)

            local inner_power_h = power_h - (2 * border)
            if inner_power_h < 1 then inner_power_h = 1 end

            m.power_background:SetPosition(border, border)
            m.power_background:SetSize(inner_w, inner_power_h)

            m.power_bar:SetPosition(0, 0)
            m.power_bar:SetSize(inner_w, inner_power_h)

            local power_percent = 0.66 - ((i - 1) * 0.08)
            if power_percent < 0.08 then power_percent = 0.08 end
            if i == 1 then
                power_percent = 1.0
            end
            local power_fill_w = math.floor((inner_w * power_percent) + 0.5)
            if power_fill_w < 0 then power_fill_w = 0 end
            if power_fill_w > inner_w then power_fill_w = inner_w end

            m.power_bar:SetWidth(power_fill_w)
            local power_fill_color = (i % 3) == 0 and wrath_color or power_color
            m.power_bar:SetBackColor(power_fill_color)
            m.power_background:SetBackColor(_preview_resource_background(ressource_bg_matches_missing,
                ressource_bg_dimming, morale_bg, power_fill_color))

            local power_max = 30000
            local power_cur = math.floor(power_max * power_percent + 0.5)
            local power_pct_text = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"
            label_context.pc = lui_abbrev_number(power_cur)
            label_context.pt = lui_abbrev_number(power_max)
            label_context.pp = power_pct_text
            _render_preview_vital_labels(self, "party", "morale", m.morale_labels, raw_scale, label_targets,
                label_context)
            _render_preview_vital_labels(self, "party", "power", m.power_labels, raw_scale, label_targets,
                label_context)

            m.info_border:SetVisible(info_h > 0)
            m.info_background:SetVisible(info_h > 0)
            if info_h > 0 then
                local inner_info_h = info_h - (2 * border)
                if inner_info_h < 1 then inner_info_h = 1 end
                m.info_border:SetPosition(0, info_y)
                m.info_border:SetSize(frame_w, info_h)
                m.info_border:SetBackColor(border_color)
                m.info_background:SetPosition(border, border)
                m.info_background:SetSize(inner_w, inner_info_h)
                m.info_background:SetBackColor(lui_apply_opacity_to_color(info_bg, info_opacity))
            end
        end
    end

    lui_clear_number_abbrev_preview_settings()
end
