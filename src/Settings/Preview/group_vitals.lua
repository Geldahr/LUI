import "LUI.src.UI.Widgets"
import "LUI.src.Utils.vitals_labels"
import "LUI.src.Vitals.group_layout"

SettingsGroupVitalsPreview = SettingsGroupVitalsPreview or {}

local Preview = SettingsGroupVitalsPreview
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

local function _render_preview_vital_label(window, prefix, label_index, label, raw_scale, targets, context)
    local controls = window.controls
    local key = prefix .. "_label" .. tostring(label_index)
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

local function _render_preview_vital_labels(window, prefix, labels, raw_scale, targets, context)
    for i = 1, #labels do
        _render_preview_vital_label(window, prefix, i, labels[i], raw_scale, targets, context)
    end
end

function Preview.init(window, spec)
    local holder = window.controls[spec.holder_key]
    if window[spec.state_key] ~= nil then
        return
    end

    local state = {
        container = holder.control,
        members = {},
        max_members = spec.max_members,
    }
    window[spec.state_key] = state

    state.container:SetMouseVisible(false)

    state.border_top = Turbine.UI.Control()
    state.border_top:SetParent(state.container)
    state.border_top:SetMouseVisible(false)
    state.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    state.border_bottom = Turbine.UI.Control()
    state.border_bottom:SetParent(state.container)
    state.border_bottom:SetMouseVisible(false)
    state.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    state.border_left = Turbine.UI.Control()
    state.border_left:SetParent(state.container)
    state.border_left:SetMouseVisible(false)
    state.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    state.border_right = Turbine.UI.Control()
    state.border_right:SetParent(state.container)
    state.border_right:SetMouseVisible(false)
    state.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))

    state.root = Turbine.UI.Control()
    state.root:SetParent(state.container)
    state.root:SetMouseVisible(false)

    for i = 1, state.max_members do
        local member = {}

        member.root = Turbine.UI.Control()
        member.root:SetParent(state.root)
        member.root:SetMouseVisible(false)

        member.class_icon = Image()
        member.class_icon:SetParent(member.root)
        member.class_icon:SetZOrder(9)
        member.class_icon:SetVisible(false)

        member.leader_icon = Image()
        member.leader_icon:SetParent(member.root)
        member.leader_icon:SetZOrder(10)
        member.leader_icon:SetVisible(false)

        member.morale_border = Turbine.UI.Control()
        member.morale_border:SetParent(member.root)
        member.morale_border:SetMouseVisible(false)

        member.morale_background = Turbine.UI.Control()
        member.morale_background:SetParent(member.morale_border)
        member.morale_background:SetMouseVisible(false)

        member.morale_bar = Turbine.UI.Control()
        member.morale_bar:SetParent(member.morale_background)
        member.morale_bar:SetMouseVisible(false)
        member.morale_bar:SetZOrder(1)

        member.bubble_bar = Turbine.UI.Control()
        member.bubble_bar:SetParent(member.morale_background)
        member.bubble_bar:SetMouseVisible(false)
        member.bubble_bar:SetZOrder(2)

        member.power_border = Turbine.UI.Control()
        member.power_border:SetParent(member.root)
        member.power_border:SetMouseVisible(false)

        member.power_background = Turbine.UI.Control()
        member.power_background:SetParent(member.power_border)
        member.power_background:SetMouseVisible(false)

        member.power_bar = Turbine.UI.Control()
        member.power_bar:SetParent(member.power_background)
        member.power_bar:SetMouseVisible(false)

        member.labels = {}
        for j = 1, 4 do
            local label = UI.Widgets.LuiLabel()
            label:SetParent(j <= 2 and member.morale_border or member.power_border)
            label:SetMouseVisible(false)
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            label:SetMultiline(true)
            label:SetZOrder(9 + j)
            member.labels[j] = label
        end

        member.info_border = Turbine.UI.Control()
        member.info_border:SetParent(member.root)
        member.info_border:SetMouseVisible(false)

        member.info_background = Turbine.UI.Control()
        member.info_background:SetParent(member.info_border)
        member.info_background:SetMouseVisible(false)

        table.insert(state.members, member)
    end
end

function Preview.update(window, spec)
    if window[spec.state_key] == nil then
        Preview.init(window, spec)
    end

    local raw_scale = _require_positive_scale(window)
    lui_set_number_abbrev_preview_settings(_preview_number_abbrev_settings(window))

    local prefix = spec.prefix
    local rows = _require_control_number(window.controls, prefix .. "_rows")
    if rows < 1 then rows = 1 end

    local spacing_x = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_spacing_x"))
    local spacing_y = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_spacing_y"))
    if spacing_x < 0 then spacing_x = 0 end
    if spacing_y < 0 then spacing_y = 0 end

    local frame_w = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_width"))
    local border = _preview_scaled_border(raw_scale, _require_control_number(window.controls, prefix .. "_border_width"))
    if frame_w < 40 then frame_w = 40 end
    if border < 0 then border = 0 end
    if border > math.floor(frame_w / 4) then
        border = math.floor(frame_w / 4)
    end

    local morale_h = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_morale_height"))
    local power_h = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_power_height"))
    local info_enabled = window.controls[prefix .. "_info_enabled"].cb:IsChecked() == true
    local info_h = info_enabled == true and
        _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_info_height")) or 0
    if morale_h < 10 then morale_h = 10 end
    if power_h < 10 then power_h = 10 end
    if info_h < 0 then info_h = 0 end

    local icon_enabled = window.controls[prefix .. "_class_icon_enabled"].cb:IsChecked() == true
    local icon_size = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_class_icon_size"))
    local icon_x = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_class_icon_x"))
    local icon_y = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_class_icon_y"))
    if icon_size < 16 then icon_size = 16 end
    if icon_size > 50 then icon_size = 50 end

    local leader_enabled = window.controls[prefix .. "_leader_icon_enabled"].cb:IsChecked() == true
    local leader_size = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_leader_icon_size"))
    local leader_x = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_leader_icon_x"))
    local leader_y = _preview_scaled_int(raw_scale, _require_control_number(window.controls, prefix .. "_leader_icon_y"))
    if leader_size < 16 then leader_size = 16 end
    if leader_size > 50 then leader_size = 50 end

    local power_y = morale_h - border
    local info_y = power_y + power_h - border
    local member_h = morale_h + power_h - border
    if info_h > 0 then
        member_h = member_h + info_h - border
    end
    if member_h < 1 then member_h = 1 end

    local morale_bg = _require_control_color(window.controls, prefix .. "_morale_background_color")
    local border_color = _require_control_color(window.controls, prefix .. "_border_color")
    local info_bg = _require_control_color(window.controls, prefix .. "_info_background_color")
    local info_opacity = _require_control_number(window.controls, prefix .. "_info_opacity")
    local bubble_color = _require_control_color(window.controls, prefix .. "_morale_bubble_color")
    local neutral_color = _require_control_color(window.controls, prefix .. "_morale_color_neutral")
    local high_color = _require_control_color(window.controls, prefix .. "_morale_color_high")
    local med_color = _require_control_color(window.controls, prefix .. "_morale_color_medium")
    local low_color = _require_control_color(window.controls, prefix .. "_morale_color_low")
    local crit_color = _require_control_color(window.controls, prefix .. "_morale_color_critical")
    local morale_gradient = window.controls[prefix .. "_morale_gradient"].cb:IsChecked() == true
    local gradient_full = _require_control_color(window.controls, prefix .. "_morale_gradient_full")
    local gradient_mid = _require_control_color(window.controls, prefix .. "_morale_gradient_mid")
    local gradient_low = _require_control_color(window.controls, prefix .. "_morale_gradient_low")
    Common.update_gradient_preview(window, prefix .. "_morale_gradient_preview", gradient_full, gradient_mid, gradient_low)
    local resource_bg_matches_missing = window.controls[prefix .. "_ressource_background_matches_missing"].cb:IsChecked() ==
        true
    local resource_bg_dimming = _require_control_number(window.controls, prefix .. "_ressource_background_dimming")
    local power_color = _require_control_color(window.controls, prefix .. "_power_color")
    local wrath_color = _require_control_color(window.controls, prefix .. "_wrath_color")

    local bubble_fmt = window.controls[prefix .. "_morale_bubble_text"].tb:GetText()
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)

    local preview_count = spec.get_preview_count(window)
    local total_w, total_h = GroupLayout.compute_size(preview_count, rows, spacing_x, spacing_y, frame_w, member_h)

    local holder = window.controls[spec.holder_key]
    local preview_border = 1
    local desired_height = total_h + 12 + (2 * preview_border)
    if desired_height < 80 then desired_height = 80 end
    _sync_preview_holder_height(window, holder, desired_height)

    local state = window[spec.state_key]
    local outer_w = total_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local container_w = state.container:GetWidth() or outer_w
    local container_h = state.container:GetHeight() or outer_h
    local off_x = math.max(0, math.floor((container_w - outer_w) / 2))
    local off_y = math.max(0, math.floor((container_h - outer_h) / 2))
    state.root:SetPosition(off_x + preview_border, off_y + preview_border)
    state.root:SetSize(total_w, total_h)
    _apply_preview_border(state, outer_w, outer_h, off_x, off_y)

    local root_windows = {}
    for i = 1, #state.members do
        root_windows[i] = state.members[i].root
    end
    GroupLayout.apply_positions(root_windows, preview_count, rows, spacing_x, spacing_y, frame_w, member_h)

    local icon_classes = _G.CLASS_ICON_CLASSES
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

    for i = 1, #state.members do
        local member = state.members[i]
        if i > preview_count then
            member.root:SetVisible(false)
        else
            member.root:SetVisible(true)
            member.root:SetSize(frame_w, member_h)

            if icon_enabled == true and icon_size > 0 then
                member.class_icon:SetVisible(true)
                local icon = _G.get_class_icon(icon_classes[((i - 1) % #icon_classes) + 1], icon_size)
                if icon ~= nil then
                    member.class_icon:SetPosition(icon_x, icon_y)
                    member.class_icon:set_icon(icon, icon_size, icon_size)
                else
                    member.class_icon:SetVisible(false)
                end
            else
                member.class_icon:SetVisible(false)
            end

            if leader_enabled == true and leader_size > 0 and i == spec.leader_slot then
                member.leader_icon:SetVisible(true)
                local icon = _G.get_party_leader_icon()
                if icon ~= nil then
                    member.leader_icon:SetPosition(leader_x, leader_y)
                    member.leader_icon:set_icon(icon, leader_size, leader_size)
                else
                    member.leader_icon:SetVisible(false)
                end
            else
                member.leader_icon:SetVisible(false)
            end

            member.morale_border:SetPosition(0, 0)
            member.morale_border:SetSize(frame_w, morale_h)
            member.morale_border:SetBackColor(border_color)

            local inner_w = frame_w - (2 * border)
            local inner_morale_h = morale_h - (2 * border)
            if inner_w < 1 then inner_w = 1 end
            if inner_morale_h < 1 then inner_morale_h = 1 end

            member.morale_background:SetPosition(border, border)
            member.morale_background:SetSize(inner_w, inner_morale_h)
            member.morale_background:SetBackColor(morale_bg)

            member.morale_bar:SetPosition(0, 0)
            member.morale_bar:SetSize(inner_w, inner_morale_h)

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
            member.morale_background:SetBackColor(_preview_resource_background(resource_bg_matches_missing,
                resource_bg_dimming, morale_bg, fill_color))
            member.morale_bar:SetBackColor(fill_color)
            member.morale_bar:SetWidth(morale_fill_w)

            local bubble_percent = 0
            if bubble_cur > 0 then
                bubble_percent = bubble_cur / morale_max
                if bubble_percent < 0 then bubble_percent = 0 end
                if bubble_percent > 1 then bubble_percent = 1 end
            end
            local bubble_w = math.floor((inner_w * bubble_percent) + 0.5)
            if bubble_w < 0 then bubble_w = 0 end
            if bubble_w > inner_w then bubble_w = inner_w end
            if bubble_w > 0 then
                member.bubble_bar:SetVisible(true)
                member.bubble_bar:SetTop(0)
                member.bubble_bar:SetHeight(inner_morale_h)
                member.bubble_bar:SetWidth(bubble_w)
                local max_left = inner_w - bubble_w
                if max_left < 0 then max_left = 0 end
                local left_inner = morale_fill_w
                if left_inner > max_left then left_inner = max_left end
                member.bubble_bar:SetLeft(left_inner)
                member.bubble_bar:SetBackColor(bubble_color)
            else
                member.bubble_bar:SetVisible(false)
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
                name = spec.is_self_slot(i, preview_count) == true and "You" or TR["Player "] .. tostring(i),
                level = "150",
            }

            if bubble_cur > 0 and string.len(bubble_fmt) > 0 then
                label_context.B = lui_format_tokenized(bubble_fmt_tokens, { b = label_context.b })
            end

            local label_targets = {
                [LUI_ENUMS.vitals_label_link.MORALE] = {
                    parent = member.morale_border,
                    width = frame_w,
                    height = morale_h,
                },
                [LUI_ENUMS.vitals_label_link.POWER] = {
                    parent = member.power_border,
                    width = frame_w,
                    height = power_h,
                },
                [LUI_ENUMS.vitals_label_link.INFO] = info_h > 0 and {
                    parent = member.info_border,
                    width = frame_w,
                    height = info_h,
                } or nil,
            }

            member.power_border:SetPosition(0, power_y)
            member.power_border:SetSize(frame_w, power_h)
            member.power_border:SetBackColor(border_color)

            local inner_power_h = power_h - (2 * border)
            if inner_power_h < 1 then inner_power_h = 1 end

            member.power_background:SetPosition(border, border)
            member.power_background:SetSize(inner_w, inner_power_h)

            member.power_bar:SetPosition(0, 0)
            member.power_bar:SetSize(inner_w, inner_power_h)

            local power_percent = 0.66 - ((i - 1) * 0.08)
            if power_percent < 0.08 then power_percent = 0.08 end
            if spec.is_self_slot(i, preview_count) == true then
                power_percent = 1.0
            end
            local power_fill_w = math.floor((inner_w * power_percent) + 0.5)
            if power_fill_w < 0 then power_fill_w = 0 end
            if power_fill_w > inner_w then power_fill_w = inner_w end

            member.power_bar:SetWidth(power_fill_w)
            local power_fill_color = (i % 3) == 0 and wrath_color or power_color
            member.power_bar:SetBackColor(power_fill_color)
            member.power_background:SetBackColor(_preview_resource_background(resource_bg_matches_missing,
                resource_bg_dimming, morale_bg, power_fill_color))

            local power_max = 30000
            local power_cur = math.floor(power_max * power_percent + 0.5)
            label_context.pc = lui_abbrev_number(power_cur)
            label_context.pt = lui_abbrev_number(power_max)
            label_context.pp = tostring(math.floor(power_percent * 100 + 0.5)) .. "%"
            _render_preview_vital_labels(window, prefix, member.labels, raw_scale, label_targets, label_context)

            member.info_border:SetVisible(info_h > 0)
            member.info_background:SetVisible(info_h > 0)
            if info_h > 0 then
                local inner_info_h = info_h - (2 * border)
                if inner_info_h < 1 then inner_info_h = 1 end
                member.info_border:SetPosition(0, info_y)
                member.info_border:SetSize(frame_w, info_h)
                member.info_border:SetBackColor(border_color)
                member.info_background:SetPosition(border, border)
                member.info_background:SetSize(inner_w, inner_info_h)
                member.info_background:SetBackColor(lui_apply_opacity_to_color(info_bg, info_opacity))
            end
        end
    end

    lui_clear_number_abbrev_preview_settings()
end
