-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local RaidLayout = _G.LUI.Utils.RaidLayout
local GroupLayout = _G.LUI.Features.Vitals.GroupLayout
local TR = _G.LUI.Locale.TR
local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
local lui_format_tokenized = _G.LUI.Utils.lui_format_tokenized
local lui_format_timeout = _G.LUI.Utils.lui_format_timeout
local lui_vitals_layout_label = _G.LUI.Utils.lui_vitals_layout_label
local lui_apply_opacity_to_color = _G.LUI.Utils.lui_apply_opacity_to_color
local lui_abbrev_number = _G.LUI.Utils.lui_abbrev_number
local lui_set_number_abbrev_preview_settings = _G.LUI.Utils.lui_set_number_abbrev_preview_settings
local lui_clear_number_abbrev_preview_settings = _G.LUI.Utils.lui_clear_number_abbrev_preview_settings
local CLASS_ICON_CLASSES = _G.LUI.Utils.CLASS_ICON_CLASSES
local get_class_icon = _G.LUI.Utils.get_class_icon
local get_party_leader_icon = _G.LUI.Utils.get_party_leader_icon
local LUI_TO_LOTRO = _G.LUI.Settings.ToLotro
local LUI_ENUMS = _G.LUI.Settings.Enums
local SettingsPreview = _G.LUI.Settings.Preview
local UI = _G.LUI.UI
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.color"
import "LUI.src.Utils.raid_layout"
import "LUI.src.Utils.vitals_labels"

local Preview = SettingsPreview.GroupVitals or {}
SettingsPreview.GroupVitals = Preview
local Common = SettingsPreview.Common
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
local _preview_power_max = Common.preview_power_max
local _sync_preview_holder_height = Common.sync_preview_holder_height
local PREVIEW_WRATH_MAX = Common.PREVIEW_WRATH_MAX
local RAID_GROUP_SIZE = 6
local RAID_GROUP_KEYS = { "a", "b", "c", "d" }
local EFFECT_BOX_COLOR = Turbine.UI.Color(1, 0.10, 0.10, 0.10)
local EFFECT_BUFF_COLOR = Turbine.UI.Color(1, 0.40, 0.78, 0.42)
local EFFECT_CURABLE_COLOR = Turbine.UI.Color(1, 0.85, 0.30, 0.30)
local EFFECT_NONCURABLE_COLOR = Turbine.UI.Color(1, 0.90, 0.58, 0.20)
local EFFECT_PREVIEW_ICON_COUNT = 3
local EFFECT_LABEL_HEIGHT = 14

local function _new_preview_effect_icon(parent)
    local icon = {}

    icon.root = Turbine.UI.Control()
    icon.root:SetParent(parent)
    icon.root:SetMouseVisible(false)
    icon.root:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))
    icon.root:SetVisible(false)

    icon.inner = Turbine.UI.Control()
    icon.inner:SetParent(icon.root)
    icon.inner:SetMouseVisible(false)

    icon.timer = UI.Widgets.LuiLabel()
    icon.timer:SetParent(icon.root)
    icon.timer:SetMouseVisible(false)
    icon.timer:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    icon.timer:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
    icon.timer:SetOutlineColor(Turbine.UI.Color(0, 0, 0, 1))
    icon.timer:SetZOrder(1)

    return icon
end

-- Placeholder effect icons inside a member's effect box. Colors mock the
-- enabled kinds (buff / curable / non-curable), sample timers exercise the
-- configured timer font, and a capacity label reports how many effects fit.
local function _render_preview_effect_box(member, area_x, area_y, frame_w, member_h, icon_size, show_buffs,
                                          show_curable, show_noncurable, timer_font, timer_style, label_font)
    local box = member.effect_box
    box:SetPosition(area_x, area_y)
    box:SetSize(frame_w, member_h)
    box:SetVisible(true)
    box:SetBackColor(EFFECT_BOX_COLOR)

    local cols = math.floor(frame_w / icon_size)
    if cols < 1 then cols = 1 end
    local rows = math.floor(member_h / icon_size)
    if rows < 1 then rows = 1 end
    local max_effects = cols * rows

    local label_h = EFFECT_LABEL_HEIGHT
    if label_h > member_h then label_h = member_h end
    member.effect_label:SetFont(label_font)
    member.effect_label:SetPosition(0, 0)
    member.effect_label:SetSize(frame_w, label_h)
    member.effect_label:SetText(string.format(TR["Effects: max %d (%dx%d)"], max_effects, cols, rows))
    member.effect_label:SetVisible(true)

    local kinds = {}
    if show_buffs == true then
        kinds[#kinds + 1] = { color = EFFECT_BUFF_COLOR, time = 8.4 }
    end
    if show_curable == true then
        kinds[#kinds + 1] = { color = EFFECT_CURABLE_COLOR, time = 5.1 }
    end
    if show_noncurable == true then
        kinds[#kinds + 1] = { color = EFFECT_NONCURABLE_COLOR, time = 2.6 }
    end

    local size = icon_size
    local available_h = member_h - label_h
    if size > available_h then size = available_h end
    if size < 1 then size = 1 end

    for j = 1, #member.effect_icons do
        local icon = member.effect_icons[j]
        if j <= #kinds and j <= EFFECT_PREVIEW_ICON_COUNT then
            local kind = kinds[j]
            icon.root:SetPosition((j - 1) * size, label_h)
            icon.root:SetSize(size, size)
            icon.root:SetVisible(true)

            local border = 1
            local inner = size - (2 * border)
            if inner < 1 then inner = 1 end
            icon.inner:SetPosition(border, border)
            icon.inner:SetSize(inner, inner)
            icon.inner:SetBackColor(kind.color)

            icon.timer:SetPosition(0, 0)
            icon.timer:SetSize(size, size)
            icon.timer:SetFont(timer_font)
            icon.timer:SetFontStyle(timer_style)
            icon.timer:SetText(lui_format_timeout(kind.time))
            icon.timer:SetVisible(true)
        else
            icon.root:SetVisible(false)
        end
    end
end

local function _preview_compute_grid_size(member_count, rows, spacing_x, spacing_y, member_width, member_height)
    local normalized_count = member_count
    if normalized_count < 0 then
        normalized_count = 0
    end

    local columns = 1
    if normalized_count > 0 then
        columns = math.ceil(normalized_count / rows)
        if columns < 1 then
            columns = 1
        end
    end

    local used_rows = normalized_count
    if used_rows > rows then
        used_rows = rows
    end
    if used_rows < 1 then
        used_rows = 1
    end

    local total_width = (columns * member_width) + ((columns - 1) * spacing_x)
    local total_height = (used_rows * member_height) + ((used_rows - 1) * spacing_y)
    if total_width < member_width then
        total_width = member_width
    end
    if total_height < member_height then
        total_height = member_height
    end

    return total_width, total_height
end

local function _preview_apply_grid_positions(member_windows, member_count, rows, spacing_x, spacing_y, member_width,
                                             member_height)
    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local index = i - 1
            local column = math.floor(index / rows)
            local row = index - (column * rows)
            local x = column * (member_width + spacing_x)
            local y = row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end



local function _preview_compute_size_from_cells(cells, member_count, spacing_x, spacing_y, member_width, member_height)
    local normalized_count = member_count
    if normalized_count < 0 then
        normalized_count = 0
    end

    local used = normalized_count
    if used < 1 then
        used = 1
    end

    local max_column = 0
    local max_row = 0
    for i = 1, used do
        local cell = cells[i]
        if cell.column > max_column then
            max_column = cell.column
        end
        if cell.row > max_row then
            max_row = cell.row
        end
    end

    local total_width = ((max_column + 1) * member_width) + (max_column * spacing_x)
    local total_height = ((max_row + 1) * member_height) + (max_row * spacing_y)
    if total_width < member_width then
        total_width = member_width
    end
    if total_height < member_height then
        total_height = member_height
    end

    return total_width, total_height
end

local function _preview_apply_positions_from_cells(member_windows, cells, member_count, spacing_x, spacing_y, member_width,
                                                   member_height)
    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local cell = cells[i]
            local x = cell.column * (member_width + spacing_x)
            local y = cell.row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end


local function _preview_compute_raid_group_size(member_count, layout_mode, spacing_x, spacing_y, member_width, member_height)
    return _preview_compute_size_from_cells(RaidLayout.group_shape_cells(layout_mode), member_count, spacing_x, spacing_y,
        member_width, member_height)
end

local function _preview_compute_raid_outer_size(member_count, layout_mode, spacing_x, spacing_y, member_width,
                                                member_height, group_border_width)
    local normalized_count = member_count
    if normalized_count < 0 then
        normalized_count = 0
    end

    local group_size = RaidLayout.group_size()
    local full_group_width, full_group_height = _preview_compute_raid_group_size(group_size, layout_mode, spacing_x,
        spacing_y, member_width, member_height)
    local group_slot_width = full_group_width + (2 * group_border_width)
    local group_slot_height = full_group_height + (2 * group_border_width)
    local occupied_groups = math.ceil(normalized_count / group_size)

    if occupied_groups < 1 then
        occupied_groups = 1
    end

    local max_right = group_slot_width
    local max_bottom = group_slot_height

    for group_index = 1, occupied_groups do
        local group_first_member = ((group_index - 1) * group_size) + 1
        local group_member_count = normalized_count - group_first_member + 1
        if group_member_count > group_size then
            group_member_count = group_size
        end
        if group_member_count < 1 then
            group_member_count = 1
        end

        local group_width, group_height = _preview_compute_raid_group_size(group_member_count, layout_mode, spacing_x,
            spacing_y, member_width, member_height)
        local tile = RaidLayout.group_tile_position(layout_mode, group_index)
        local right = (tile.column * group_slot_width) + group_width + (2 * group_border_width)
        local bottom = (tile.row * group_slot_height) + group_height + (2 * group_border_width)

        if right > max_right then
            max_right = right
        end
        if bottom > max_bottom then
            max_bottom = bottom
        end
    end

    return max_right, max_bottom
end


local function _preview_apply_raid_group_positions(member_windows, member_count, layout_mode, spacing_x, spacing_y,
                                                   member_width, member_height)
    _preview_apply_positions_from_cells(member_windows, RaidLayout.group_shape_cells(layout_mode), member_count, spacing_x,
        spacing_y, member_width, member_height)
end

local function _hide_preview_border(border)
    border.border_top:SetVisible(false)
    border.border_bottom:SetVisible(false)
    border.border_left:SetVisible(false)
    border.border_right:SetVisible(false)
end

local function _set_preview_border_color(border, color)
    border.border_top:SetBackColor(color)
    border.border_bottom:SetBackColor(color)
    border.border_left:SetBackColor(color)
    border.border_right:SetBackColor(color)
end

local function _apply_preview_group_border(border, x, y, width, height, thickness)
    if thickness <= 0 or width <= 0 or height <= 0 then
        _hide_preview_border(border)
        return
    end

    border.border_top:SetVisible(true)
    border.border_top:SetZOrder(999)
    border.border_top:SetPosition(x, y)
    border.border_top:SetSize(width, thickness)

    border.border_bottom:SetVisible(true)
    border.border_bottom:SetZOrder(999)
    border.border_bottom:SetPosition(x, y + height - thickness)
    border.border_bottom:SetSize(width, thickness)

    border.border_left:SetVisible(true)
    border.border_left:SetZOrder(999)
    border.border_left:SetPosition(x, y)
    border.border_left:SetSize(thickness, height)

    border.border_right:SetVisible(true)
    border.border_right:SetZOrder(999)
    border.border_right:SetPosition(x + width - thickness, y)
    border.border_right:SetSize(thickness, height)
end

local function _new_preview_border(parent)
    local border = {}

    border.border_top = Turbine.UI.Control()
    border.border_top:SetParent(parent)
    border.border_top:SetMouseVisible(false)
    border.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    border.border_top:SetVisible(false)

    border.border_bottom = Turbine.UI.Control()
    border.border_bottom:SetParent(parent)
    border.border_bottom:SetMouseVisible(false)
    border.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    border.border_bottom:SetVisible(false)

    border.border_left = Turbine.UI.Control()
    border.border_left:SetParent(parent)
    border.border_left:SetMouseVisible(false)
    border.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    border.border_left:SetVisible(false)

    border.border_right = Turbine.UI.Control()
    border.border_right:SetParent(parent)
    border.border_right:SetMouseVisible(false)
    border.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
    border.border_right:SetVisible(false)

    return border
end

local function _preview_group_border_color(group_index, colors)
    return colors[RAID_GROUP_KEYS[group_index]]
end

local function _sync_preview_member_parents(state, split_by_group)
    if split_by_group == true then
        for i = 1, #state.members do
            local member = state.members[i]
            local group_window = state.group_windows[RaidLayout.member_group_index(i)]
            if member.root:GetParent() ~= group_window.root then
                member.root:SetParent(group_window.root)
            end
            if member.effect_box:GetParent() ~= group_window.root then
                member.effect_box:SetParent(group_window.root)
            end
        end
        return
    end

    for i = 1, #state.members do
        local member = state.members[i]
        if member.root:GetParent() ~= state.root then
            member.root:SetParent(state.root)
        end
        if member.effect_box:GetParent() ~= state.root then
            member.effect_box:SetParent(state.root)
        end
    end
end

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

    state.group_windows = {}
    for i = 1, #RAID_GROUP_KEYS do
        local group_window = {}

        group_window.border_top = Turbine.UI.Control()
        group_window.border_top:SetParent(state.container)
        group_window.border_top:SetMouseVisible(false)
        group_window.border_top:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
        group_window.border_top:SetVisible(false)

        group_window.border_bottom = Turbine.UI.Control()
        group_window.border_bottom:SetParent(state.container)
        group_window.border_bottom:SetMouseVisible(false)
        group_window.border_bottom:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
        group_window.border_bottom:SetVisible(false)

        group_window.border_left = Turbine.UI.Control()
        group_window.border_left:SetParent(state.container)
        group_window.border_left:SetMouseVisible(false)
        group_window.border_left:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
        group_window.border_left:SetVisible(false)

        group_window.border_right = Turbine.UI.Control()
        group_window.border_right:SetParent(state.container)
        group_window.border_right:SetMouseVisible(false)
        group_window.border_right:SetBackColor(Turbine.UI.Color(1, 1, 1, 1))
        group_window.border_right:SetVisible(false)

        group_window.root = Turbine.UI.Control()
        group_window.root:SetParent(state.container)
        group_window.root:SetMouseVisible(false)
        group_window.root:SetVisible(false)

        state.group_windows[i] = group_window
    end

    for i = 1, state.max_members do
        local member = {}

        member.root = Turbine.UI.Control()
        member.root:SetParent(state.root)
        member.root:SetMouseVisible(false)

        member.class_icon = UI.Widgets.Image()
        member.class_icon:SetParent(member.root)
        member.class_icon:SetZOrder(9)
        member.class_icon:SetVisible(false)

        member.leader_icon = UI.Widgets.Image()
        member.leader_icon:SetParent(member.root)
        member.leader_icon:SetZOrder(10)
        member.leader_icon:SetVisible(false)

        member.select_border = _new_preview_border(member.root)

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

        member.effect_box = Turbine.UI.Control()
        member.effect_box:SetParent(state.root)
        member.effect_box:SetMouseVisible(false)
        member.effect_box:SetVisible(false)

        member.effect_label = UI.Widgets.LuiLabel()
        member.effect_label:SetParent(member.effect_box)
        member.effect_label:SetMouseVisible(false)
        member.effect_label:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter)
        member.effect_label:SetZOrder(2)

        member.effect_icons = {}
        for j = 1, EFFECT_PREVIEW_ICON_COUNT do
            member.effect_icons[j] = _new_preview_effect_icon(member.effect_box)
        end

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
    local rows = nil
    if spec.raid_layout_mode_control_key == nil then
        rows = _require_control_number(window.controls, prefix .. "_rows")
        if rows < 1 then rows = 1 end
    end

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
    local select_enabled = window.controls[prefix .. "_select_enabled"].cb:IsChecked() == true
    local select_border_width = _preview_scaled_border(raw_scale,
        _require_control_number(window.controls, prefix .. "_select_border_width"))
    local select_border_color = _require_control_color(window.controls, prefix .. "_select_border_color")
    local info_bg = _require_control_color(window.controls, prefix .. "_info_background_color")
    local info_opacity = _require_control_number(window.controls, prefix .. "_info_opacity")
    local bubble_color = _require_control_color(window.controls, prefix .. "_morale_bubble_color")
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
    local background_opacity = _require_control_number(window.controls, prefix .. "_background_opacity")
    local power_color = _require_control_color(window.controls, prefix .. "_power_color")
    local wrath_color = _require_control_color(window.controls, prefix .. "_wrath_color")

    local bubble_fmt = window.controls[prefix .. "_morale_bubble_text"].tb:GetText()
    local bubble_fmt_tokens = lui_tokenize_format(bubble_fmt)

    local state = window[spec.state_key]
    local preview_count = spec.get_preview_count(window)
    local selected_preview_slot = preview_count >= 2 and 2 or 1

    local ge_enabled = window.controls[prefix .. "_group_effects_enabled"].cb:IsChecked() == true
    local ge_buffs = window.controls[prefix .. "_group_effects_buffs"].cb:IsChecked() == true
    local ge_curable = window.controls[prefix .. "_group_effects_curable"].cb:IsChecked() == true
    local ge_noncurable = window.controls[prefix .. "_group_effects_noncurable"].cb:IsChecked() == true
    local ge_side = _require_control_enum(window.controls, prefix .. "_group_effects_side")
    local ge_icon_size = _preview_scaled_int(raw_scale,
        _require_control_number(window.controls, prefix .. "_group_effects_size"))
    if ge_icon_size < 8 then ge_icon_size = 8 end
    local ge_timer_font_name = _require_control_enum(window.controls, prefix .. "_group_effects_timer_font_name")
    local ge_timer_font = _require_font(ge_timer_font_name,
        _preview_scaled_number(raw_scale, _require_control_number(window.controls, prefix .. "_group_effects_timer_font_size")))
    local ge_timer_style = LUI_TO_LOTRO.font_style[_require_control_enum(window.controls,
        prefix .. "_group_effects_timer_font_style")] or Turbine.UI.FontStyle.Outline
    -- Effects are previewed only for the fellowship layout; the raid split
    -- preview path is left unchanged.
    local fellowship_effects = ge_enabled == true and spec.raid_layout_mode_control_key == nil
        and (ge_buffs == true or ge_curable == true or ge_noncurable == true)
    local total_w = nil
    local total_h = nil
    local raid_layout_mode = nil
    local raid_group_border_width = nil
    local split_by_group = false
    local raid_group_border_colors = nil
    if spec.raid_layout_mode_control_key ~= nil then
        raid_layout_mode = window.controls[spec.raid_layout_mode_control_key]:get_value()
        raid_group_border_width = _preview_scaled_border(raw_scale,
            _require_control_number(window.controls, prefix .. "_group_border_width"))
        total_w, total_h = _preview_compute_raid_outer_size(preview_count, raid_layout_mode, spacing_x, spacing_y,
            frame_w, member_h, raid_group_border_width)
        raid_group_border_colors = {
            a = _require_control_color(window.controls, prefix .. "_group_a_border_color"),
            b = _require_control_color(window.controls, prefix .. "_group_b_border_color"),
            c = _require_control_color(window.controls, prefix .. "_group_c_border_color"),
            d = _require_control_color(window.controls, prefix .. "_group_d_border_color"),
        }
        if spec.split_by_group_control_key ~= nil then
            split_by_group = window.controls[spec.split_by_group_control_key].cb:IsChecked() == true
        end
    else
        for group_index = 1, #state.group_windows do
            local group_window = state.group_windows[group_index]
            group_window.root:SetVisible(false)
            _hide_preview_border(group_window)
        end

        if fellowship_effects == true then
            local rows_grid = math.min(rows, preview_count)
            if rows_grid < 1 then rows_grid = 1 end
            local cols = math.ceil(preview_count / rows)
            if cols < 1 then cols = 1 end
            local max_col = 0
            local max_row = 0
            for i = 1, preview_count do
                local index = i - 1
                local column = math.floor(index / rows)
                local r = index - (column * rows)
                if column > max_col then max_col = column end
                if r > max_row then max_row = r end
            end
            total_w, total_h = GroupLayout.effect_grid_size(max_col, max_row, cols, rows_grid, spacing_x, spacing_y,
                frame_w, member_h)
        else
            total_w, total_h = _preview_compute_grid_size(preview_count, rows, spacing_x, spacing_y, frame_w, member_h)
        end
    end
    _sync_preview_member_parents(state, split_by_group)

    local holder = window.controls[spec.holder_key]
    local preview_border = 1
    local desired_height = total_h + 12 + (2 * preview_border)
    if desired_height < 80 then desired_height = 80 end
    _sync_preview_holder_height(window, holder, desired_height)

    local outer_w = total_w + (2 * preview_border)
    local outer_h = total_h + (2 * preview_border)
    local container_w = state.container:GetWidth() or outer_w
    local container_h = state.container:GetHeight() or outer_h
    local off_x = math.max(0, math.floor((container_w - outer_w) / 2))
    local off_y = math.max(0, math.floor((container_h - outer_h) / 2))
    state.root:SetPosition(off_x + preview_border, off_y + preview_border)
    state.root:SetSize(total_w, total_h)
    _apply_preview_border(state, outer_w, outer_h, off_x, off_y)
    state.root:SetVisible(split_by_group ~= true)

    local icon_classes = CLASS_ICON_CLASSES
    local root_windows = {}
    for i = 1, #state.members do
        root_windows[i] = state.members[i].root
        if fellowship_effects ~= true then
            state.members[i].effect_box:SetVisible(false)
        end
    end

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
            _hide_preview_border(member.select_border)
        else
            member.root:SetVisible(true)
            member.root:SetSize(frame_w, member_h)

            if icon_enabled == true and icon_size > 0 then
                member.class_icon:SetVisible(true)
                local icon = get_class_icon(icon_classes[((i - 1) % #icon_classes) + 1], icon_size)
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
                local icon = get_party_leader_icon()
                if icon ~= nil then
                    member.leader_icon:SetPosition(leader_x, leader_y)
                    member.leader_icon:set_icon(icon, leader_size, leader_size)
                else
                    member.leader_icon:SetVisible(false)
                end
            else
                member.leader_icon:SetVisible(false)
            end

            if select_enabled == true and i == selected_preview_slot then
                _set_preview_border_color(member.select_border, select_border_color)
                _apply_preview_group_border(member.select_border, 0, 0, frame_w, member_h, select_border_width)
            else
                _hide_preview_border(member.select_border)
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
            member.morale_background:SetBackColor(lui_apply_opacity_to_color(
                _preview_resource_background(resource_bg_matches_missing, resource_bg_dimming, morale_bg, fill_color),
                background_opacity))
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
            local is_wrath = (i % 3) == 0
            local power_fill_color = is_wrath == true and wrath_color or power_color
            member.power_bar:SetBackColor(power_fill_color)
            member.power_background:SetBackColor(lui_apply_opacity_to_color(
                _preview_resource_background(resource_bg_matches_missing, resource_bg_dimming, morale_bg,
                    power_fill_color),
                background_opacity))

            local power_max = is_wrath == true and PREVIEW_WRATH_MAX or _preview_power_max(morale_max)
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

    if spec.raid_layout_mode_control_key ~= nil then
        if split_by_group == true then
            local full_group_w, full_group_h = _preview_compute_raid_group_size(RaidLayout.group_size(), raid_layout_mode,
                spacing_x, spacing_y, frame_w, member_h)
            local group_slot_width = full_group_w + (2 * raid_group_border_width)
            local group_slot_height = full_group_h + (2 * raid_group_border_width)
            for group_index = 1, #state.group_windows do
                local group_window = state.group_windows[group_index]
                local group_tile = RaidLayout.group_tile_position(raid_layout_mode, group_index)
                local group_x = off_x + preview_border + (group_tile.column * group_slot_width)
                local group_y = off_y + preview_border + (group_tile.row * group_slot_height)
                local group_first_member = ((group_index - 1) * RAID_GROUP_SIZE) + 1
                local group_member_count = preview_count - group_first_member + 1
                if group_member_count > RAID_GROUP_SIZE then
                    group_member_count = RAID_GROUP_SIZE
                end
                if group_member_count < 0 then
                    group_member_count = 0
                end
                local group_w, group_h = _preview_compute_raid_group_size(group_member_count, raid_layout_mode, spacing_x,
                    spacing_y, frame_w, member_h)
                local group_outer_w = group_w + (2 * raid_group_border_width)
                local group_outer_h = group_h + (2 * raid_group_border_width)

                group_window.root:SetVisible(true)
                group_window.root:SetPosition(group_x, group_y)
                group_window.root:SetSize(group_outer_w, group_outer_h)
                _apply_preview_group_border(group_window, group_x, group_y, group_outer_w, group_outer_h,
                    raid_group_border_width)
                _set_preview_border_color(group_window, _preview_group_border_color(group_index, raid_group_border_colors))

                local group_member_windows = {}
                local group_start = ((group_index - 1) * RAID_GROUP_SIZE) + 1
                for member_offset = 0, RAID_GROUP_SIZE - 1 do
                    local member_index = group_start + member_offset
                    local member = state.members[member_index]
                    group_member_windows[#group_member_windows + 1] = member.root
                end

                _preview_apply_raid_group_positions(group_member_windows, #group_member_windows, raid_layout_mode, spacing_x,
                    spacing_y, frame_w, member_h)
                for i = 1, #group_member_windows do
                    local member_window = group_member_windows[i]
                    local x, y = member_window:GetPosition()
                    member_window:SetPosition(x + raid_group_border_width, y + raid_group_border_width)
                end
            end
        else
            local full_group_width, full_group_height = _preview_compute_raid_group_size(RaidLayout.group_size(),
                raid_layout_mode, spacing_x, spacing_y, frame_w, member_h)
            local group_slot_width = full_group_width + (2 * raid_group_border_width)
            local group_slot_height = full_group_height + (2 * raid_group_border_width)
            for group_index = 1, #state.group_windows do
                local group_window = state.group_windows[group_index]
                local group_x = nil
                local group_y = nil
                local group_first_member = ((group_index - 1) * RAID_GROUP_SIZE) + 1
                local group_member_count = preview_count - group_first_member + 1
                if group_member_count > RAID_GROUP_SIZE then
                    group_member_count = RAID_GROUP_SIZE
                end
                if group_member_count < 0 then
                    group_member_count = 0
                end

                group_window.root:SetVisible(false)

                if group_member_count <= 0 then
                    _hide_preview_border(group_window)
                else
                    local group_width, group_height = _preview_compute_raid_group_size(group_member_count, raid_layout_mode,
                        spacing_x, spacing_y, frame_w, member_h)
                    local group_tile = RaidLayout.group_tile_position(raid_layout_mode, group_index)
                    group_x = off_x + preview_border + (group_tile.column * group_slot_width)
                    group_y = off_y + preview_border + (group_tile.row * group_slot_height)
                    _apply_preview_group_border(group_window, group_x, group_y, group_width + (2 * raid_group_border_width),
                        group_height + (2 * raid_group_border_width),
                        raid_group_border_width)
                    _set_preview_border_color(group_window, _preview_group_border_color(group_index, raid_group_border_colors))
                end
            end

            local shape_cells = RaidLayout.group_shape_cells(raid_layout_mode)
            local full_group_width, full_group_height = _preview_compute_raid_group_size(RaidLayout.group_size(),
                raid_layout_mode, spacing_x, spacing_y, frame_w, member_h)
            local group_slot_width = full_group_width + (2 * raid_group_border_width)
            local group_slot_height = full_group_height + (2 * raid_group_border_width)
            for i = 1, #root_windows do
                local member_window = root_windows[i]
                if i <= preview_count then
                    local group_index = RaidLayout.member_group_index(i)
                    local tile = RaidLayout.group_tile_position(raid_layout_mode, group_index)
                    local cell = shape_cells[((i - 1) % RaidLayout.group_size()) + 1]
                    local x = (tile.column * group_slot_width) + raid_group_border_width +
                        (cell.column * (frame_w + spacing_x))
                    local y = (tile.row * group_slot_height) + raid_group_border_width +
                        (cell.row * (member_h + spacing_y))
                    member_window:SetPosition(x, y)
                else
                    member_window:SetPosition(0, 0)
                end
            end
        end
    else
        if fellowship_effects == true then
            local rows_grid = math.min(rows, preview_count)
            if rows_grid < 1 then rows_grid = 1 end
            local cols = math.ceil(preview_count / rows)
            if cols < 1 then cols = 1 end
            for i = 1, #root_windows do
                if i <= preview_count then
                    local index = i - 1
                    local column = math.floor(index / rows)
                    local r = index - (column * rows)
                    local bar_x, bar_y, area_x, area_y = GroupLayout.place_with_effects(column, r, cols, rows_grid,
                        ge_side, spacing_x, spacing_y, frame_w, member_h)
                    root_windows[i]:SetPosition(bar_x, bar_y)
                    _render_preview_effect_box(state.members[i], area_x, area_y, frame_w, member_h, ge_icon_size,
                        ge_buffs, ge_curable, ge_noncurable, ge_timer_font, ge_timer_style, window.field_label_font)
                else
                    root_windows[i]:SetPosition(0, 0)
                    state.members[i].effect_box:SetVisible(false)
                end
            end
        else
            _preview_apply_grid_positions(root_windows, preview_count, rows, spacing_x, spacing_y, frame_w, member_h)
        end
    end

    lui_clear_number_abbrev_preview_settings()
end
