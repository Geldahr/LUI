-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- TEMPORARY review window for the tinted icon set: /lui icondemo.
-- A real LuiWindow (title buttons, menu bar with sub-menus and checkable
-- items) plus real dropdowns and checkboxes, all using the migrated icons;
-- the remaining rows preview icons not migrated yet and the token search bar.
-- Remove once the icon migration is reviewed.

local LUI = _G.LUI
local UI = LUI.UI
local Widgets = UI.Widgets
local Style = Widgets.Style
local Icons = Widgets.Icons
local State = LUI.Settings.State
local LuiButton = Widgets.LuiButton
local LuiLabel = Widgets.LuiLabel
local Image = Widgets.Image
local FONT_TO_LOTRO = LUI.Utils.FONT_TO_LOTRO
local estimate_text_width = LUI.Utils.lui_timed_row_estimate_text_width

local IconDemo = {}
UI.IconDemo = IconDemo

local WEIGHTED = {
    "dropdown_arrow", "submenu_arrow", "chevron_down", "chevron_up", "chevron_left", "chevron_right",
    "plus", "minus", "check", "search", "resize_corner", "star", "star_filled", "locate",
    "map_pin", "level", "family",
}

-- keyword chips show an icon instead of "key:"
local CHIP_KEYWORDS = {
    loc = "map_pin",
    lvl = "level",
    gen = "family",
}

-- same blending as LuiLineEdit, so backgrounds are drawn instead of
-- showing the 3D world through the control
local function _set_alpha_blend(control)
    control:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    control:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
end

local function _scale()
    return State.settings.global.scale
end

local function _s(value)
    return math.floor(value * _scale() + 0.5)
end

local function _font(size)
    local font = FONT_TO_LOTRO(Style.CONTROL_FONT_NAME, size * _scale())
    if font == nil then
        error("Missing scaled font: " .. tostring(Style.CONTROL_FONT_NAME) .. " " .. tostring(size))
    end
    return font
end

local function _label(parent, text, x, y, w, h, color, size)
    local label = LuiLabel()
    label:SetParent(parent)
    label:SetPosition(x, y)
    label:SetSize(w, h)
    label:SetFont(_font(size or Style.CONTROL_FONT_SIZE))
    label:SetForeColor(color or Style.FOREGROUND)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    label:SetText(text)
    label:SetMouseVisible(false)
    return label
end

local function _tinted_image(parent, path, size, x, y, color)
    local image = Image(path, size)
    image:SetParent(parent)
    image:SetPosition(x, y)
    image:set_tint(color)
    return image
end

local function _button(parent, x, y, w, h, icon, icon_size)
    local button = LuiButton()
    button:SetParent(parent)
    button:set_scale(_scale())
    button:SetPosition(x, y)
    button:SetSize(w, h)
    button:set_tinted_icon(Icons.path(icon), icon_size)
    return button
end

local function _flat_button(parent, x, y, size, icon, icon_size)
    local button = _button(parent, x, y, size, size, icon, icon_size)
    Style.apply_transparent_button(button)
    button:set_hover_back_color(Style.ACCENT_BACKGROUND_DISABLED)
    return button
end

local function _section(parent, y, title)
    _label(parent, title, 0, y, _s(700), _s(18), Style.ALTERNATE_FOREGROUND)
    return y + _s(20)
end

---------------------------------------------------------------------
-- token search bar prototype
---------------------------------------------------------------------

-- base sizes (scaled with _s): LARGE is the 30px token bar, COMPACT matches
-- the 21px search fields used by the other windows
local BAR_LARGE = {
    bar = 30, chip = 22, gap = 5, chip_pad = 6, search = 16, search_x = 7, chips_x = 28,
    marker_w = 34, marker_icon = 12, chip_icon = 14, chip_icon_w = 18,
    close_btn = 16, close_icon = 9, close_w = 20, clear_btn = 24, clear_icon = 12, clear_w = 32,
    text_h = 20, font = 1,
}
local BAR_COMPACT = {
    bar = 21, chip = 17, gap = 4, chip_pad = 5, search = 13, search_x = 5, chips_x = 22,
    marker_w = 30, marker_icon = 10, chip_icon = 11, chip_icon_w = 15,
    close_btn = 13, close_icon = 7, close_w = 16, clear_btn = 19, clear_icon = 10, clear_w = 24,
    text_h = 17, font = 0,
}

-- size for an item centred in `area`: same parity, so the space above and
-- below is identical (no 1px/2px split)
local function _fit(value, area)
    if (area - value) % 2 ~= 0 then
        return value - 1
    end
    return value
end

local function _build_search_bar(parent, x, y, w, size)
    -- even height: the 1px border leaves an even inner area
    local h = _s(size.bar)
    if h % 2 ~= 0 then
        h = h + 1
    end
    local small_font = Style.CONTENT_SMALL_FONT_SIZE + size.font
    local bar = Turbine.UI.Control()
    bar:SetParent(parent)
    bar:SetPosition(x, y)
    bar:SetSize(w, h)
    _set_alpha_blend(bar)
    bar:SetBackColor(Style.CONTROL_BORDER)

    local inner = Turbine.UI.Control()
    inner:SetParent(bar)
    inner:SetPosition(1, 1)
    inner:SetSize(w - 2, h - 2)
    _set_alpha_blend(inner)
    inner:SetBackColor(Style.ALTERNATE_BACKGROUND)
    inner:SetMouseVisible(false)

    local search_size = _fit(_s(size.search), h)
    _tinted_image(bar, Icons.path("search"), search_size, _s(size.search_x), (h - search_size) / 2, Style.ICON_FOREGROUND)

    local chip_layer = Turbine.UI.Control()
    chip_layer:SetParent(bar)
    chip_layer:SetPosition(0, 0)
    chip_layer:SetSize(w, h)
    chip_layer:SetMouseVisible(false)

    local CHIP_H = _fit(_s(size.chip), h)
    local CHIP_GAP = _s(size.gap)
    local MARKER_W = _s(size.marker_w)

    -- "< +N" markers for chips scrolled out on either side: chip-sized,
    -- borderless button look
    local function make_marker(icon)
        local marker = Turbine.UI.Control()
        marker:SetParent(bar)
        marker:SetSize(MARKER_W, CHIP_H)
        marker:SetMouseVisible(true)
        _set_alpha_blend(marker)
        marker:SetBackColor(Style.TRANSPARENT_BACKGROUND)
        local icon_size = _fit(_s(size.marker_icon), CHIP_H)
        marker.icon = _tinted_image(marker, Icons.path(icon), icon_size, _s(5), (CHIP_H - icon_size) / 2, Style.ICON_FOREGROUND)
        marker.label = _label(marker, "", _s(5) + icon_size, 0, MARKER_W - _s(5) - icon_size, CHIP_H, Style.CONTROL_FOREGROUND, small_font)
        marker:SetVisible(false)
        return marker
    end
    local left_marker = make_marker("chevron_left")
    local right_marker = make_marker("chevron_right")
    local popup_side = nil

    local function paint_marker(marker, side)
        if popup_side == side then
            marker:SetBackColor(Style.CONTROL_BACKGROUND_ACTIVE)
        elseif marker._hover == true then
            marker:SetBackColor(Style.CONTROL_BACKGROUND_HOVER)
        else
            marker:SetBackColor(Style.TRANSPARENT_BACKGROUND)
        end
    end
    local function paint_markers()
        paint_marker(left_marker, "left")
        paint_marker(right_marker, "right")
    end
    for _, spec in ipairs({ { left_marker, "left" }, { right_marker, "right" } }) do
        local marker, side = spec[1], spec[2]
        marker.MouseEnter = function()
            marker._hover = true
            paint_marker(marker, side)
        end
        marker.MouseLeave = function()
            marker._hover = false
            paint_marker(marker, side)
        end
    end

    local text_box = Turbine.UI.TextBox()
    text_box:SetParent(bar)
    _set_alpha_blend(text_box)
    text_box:SetFont(_font(Style.CONTROL_FONT_SIZE))
    text_box:SetForeColor(Style.CONTROL_FOREGROUND)
    -- same color as the bar; a transparent TextBox shows the 3D world
    text_box:SetBackColor(Style.ALTERNATE_BACKGROUND)
    text_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    local hint = _label(bar, "Search tokens...", 0, 0, _s(380), h,
        Style.PLACEHOLDER_FOREGROUND, small_font)

    local clear_size = _fit(_s(size.clear_btn), h)
    local clear = _flat_button(bar, w - clear_size - _s(4), (h - clear_size) / 2,
        clear_size, "window_close", size.clear_icon)

    local chips = {}
    -- children receive mouse events themselves, so they all forward the wheel
    local on_wheel
    local function wheel(_, args)
        on_wheel(args)
    end
    local chip_controls = {}
    local layout

    local CHIPS_X = _s(size.chips_x)
    local CHIP_ICON_W = _s(size.chip_icon_w)
    local CHIP_CLOSE_W = _s(size.close_w)
    local CHIP_PAD = _s(size.chip_pad)
    local MIN_TEXT_W = _s(100)
    local CLEAR_W = _s(size.clear_w)
    local chip_font_size = small_font * _scale()

    -- nil = follow the newest chip; a number = first visible chip index
    local first_visible = nil
    -- first chip index shown by the last layout
    local shown_first = 1

    local function chip_parts(text)
        local key, value = string.match(text, "^(%a+):(.+)$")
        local icon = key ~= nil and CHIP_KEYWORDS[string.lower(key)] or nil
        if icon == nil then
            value = text
        end
        local text_w = estimate_text_width(value, Style.CONTENT_SMALL_FONT_NAME, chip_font_size)
        local icon_w = icon ~= nil and CHIP_ICON_W or 0
        return icon, value, text_w, CHIP_PAD + icon_w + text_w + CHIP_CLOSE_W
    end

    local function make_chip(index, parent_control, cx, cy, full_width)
        local text = chips[index]
        local icon, value, text_w, cw = chip_parts(text)
        if full_width ~= nil then
            cw = full_width
        end

        local chip = Turbine.UI.Control()
        chip:SetParent(parent_control)
        chip:SetPosition(cx, cy)
        chip:SetSize(cw, CHIP_H)
        _set_alpha_blend(chip)
        chip:SetBackColor(Style.CONTROL_BACKGROUND)

        local tx = CHIP_PAD
        if icon ~= nil then
            local chip_icon = _fit(_s(size.chip_icon), CHIP_H)
            _tinted_image(chip, Icons.path(icon), chip_icon, tx, (CHIP_H - chip_icon) / 2, Style.ICON_FOREGROUND)
            tx = tx + CHIP_ICON_W
        end
        _label(chip, value, tx, 0, text_w, CHIP_H, Style.CONTROL_FOREGROUND, small_font)
        local close = _fit(_s(size.close_btn), CHIP_H)
        local remove = _flat_button(chip, cw - close - _s(3), (CHIP_H - close) / 2, close, "window_close", size.close_icon)
        if parent_control == chip_layer then
            chip.MouseWheel = wheel
            remove.MouseWheel = wheel
        end
        remove.Click = function()
            table.remove(chips, index)
            layout()
        end
        return chip
    end

    -- overflow list: hidden chips of one side, each removable
    local popup = Turbine.UI.Window()
    UI.NativeScaling.apply_window(popup)
    popup:SetVisible(false)
    popup:SetZOrder(3000)
    _set_alpha_blend(popup)
    popup:SetBackColor(Style.CONTROL_BORDER)
    local popup_inner = Turbine.UI.Control()
    popup_inner:SetParent(popup)
    popup_inner:SetPosition(1, 1)
    _set_alpha_blend(popup_inner)
    popup_inner:SetBackColor(Style.PANEL_BACKGROUND)
    popup_inner:SetMouseVisible(false)
    local popup_chips = {}
    local hidden = { left = {}, right = {} }
    local refresh_popup

    local function close_popup()
        for i = 1, #popup_chips do
            popup_chips[i]:SetVisible(false)
            popup_chips[i]:SetParent(nil)
        end
        popup_chips = {}
        popup_side = nil
        popup:SetVisible(false)
        paint_markers()
    end

    refresh_popup = function()
        local side = popup_side
        local indexes = side ~= nil and hidden[side] or {}
        if side == nil or #indexes == 0 then
            close_popup()
            return
        end
        for i = 1, #popup_chips do
            popup_chips[i]:SetVisible(false)
            popup_chips[i]:SetParent(nil)
        end
        popup_chips = {}
        local pad = _s(5)
        local width = 0
        for k = 1, #indexes do
            local _, _, _, cw = chip_parts(chips[indexes[k]])
            width = math.max(width, cw)
        end
        for k = 1, #indexes do
            popup_chips[#popup_chips + 1] = make_chip(indexes[k], popup_inner, pad, pad + (k - 1) * (CHIP_H + CHIP_GAP), width)
        end
        local inner_w = width + 2 * pad
        local inner_h = #indexes * CHIP_H + (#indexes - 1) * CHIP_GAP + 2 * pad
        popup_inner:SetSize(inner_w, inner_h)
        popup:SetSize(inner_w + 2, inner_h + 2)
        local marker = side == "left" and left_marker or right_marker
        local sx, sy = marker:PointToScreen(0, CHIP_H + _s(6))
        popup:SetPosition(sx, sy)
        popup:SetVisible(true)
        paint_markers()
    end

    bar.MouseWheel = wheel
    text_box.MouseWheel = wheel
    left_marker.MouseWheel = wheel
    right_marker.MouseWheel = wheel
    clear.MouseWheel = wheel

    left_marker.MouseClick = function()
        popup_side = popup_side ~= "left" and "left" or nil
        refresh_popup()
    end
    right_marker.MouseClick = function()
        popup_side = popup_side ~= "right" and "right" or nil
        refresh_popup()
    end

    -- chips from `first` that fit in `space`, plus the width they use
    local function fit_from(first, widths, space)
        local used = 0
        local last = first - 1
        for i = first, #widths do
            local add = widths[i] + (i > first and CHIP_GAP or 0)
            if used + add > space and i > first then
                break
            end
            used = used + add
            last = i
        end
        return last, used
    end

    layout = function()
        for i = 1, #chip_controls do
            -- a detached control is still drawn at the screen origin: hide first
            chip_controls[i]:SetVisible(false)
            chip_controls[i]:SetParent(nil)
        end
        chip_controls = {}

        local widths = {}
        for i = 1, #chips do
            local _, _, _, cw = chip_parts(chips[i])
            widths[i] = cw
        end

        local space = w - CHIPS_X - CLEAR_W - MIN_TEXT_W
        local first = 1
        local last, used = fit_from(1, widths, space)
        if last < #chips then
            -- not everything fits: room for both markers, then pick the window
            local window_space = space - (2 * (MARKER_W + CHIP_GAP))
            if first_visible == nil then
                -- newest chips, walking back from the end
                first = #chips
                local total = widths[first]
                while first > 1 and total + CHIP_GAP + widths[first - 1] <= window_space do
                    first = first - 1
                    total = total + CHIP_GAP + widths[first]
                end
            else
                first = math.max(1, math.min(first_visible, #chips))
            end
            last, used = fit_from(first, widths, window_space)
        end

        shown_first = first
        local cx = CHIPS_X
        left_marker:SetVisible(first > 1)
        if first > 1 then
            left_marker:SetPosition(cx, math.floor((h - CHIP_H) / 2))
            left_marker.label:SetText("+" .. tostring(first - 1))
            cx = cx + MARKER_W + CHIP_GAP
        end
        for i = first, last do
            chip_controls[#chip_controls + 1] = make_chip(i, chip_layer, cx, math.floor((h - CHIP_H) / 2))
            cx = cx + widths[i] + CHIP_GAP
        end
        hidden.left = {}
        for i = 1, first - 1 do
            hidden.left[#hidden.left + 1] = i
        end
        hidden.right = {}
        for i = last + 1, #chips do
            hidden.right[#hidden.right + 1] = i
        end
        right_marker:SetVisible(last < #chips)
        if last < #chips then
            right_marker:SetPosition(cx, math.floor((h - CHIP_H) / 2))
            right_marker.label:SetText("+" .. tostring(#chips - last))
            cx = cx + MARKER_W
        end

        local tx = cx + _s(2)
        local tw = math.max(0, w - tx - CLEAR_W)
        local text_h = _fit(_s(size.text_h), h)
        text_box:SetPosition(tx, (h - text_h) / 2)
        text_box:SetSize(tw, text_h)
        hint:SetPosition(tx, 0)
        hint:SetVisible(#chips == 0 and (text_box:GetText() or "") == "")
        if popup_side ~= nil then
            refresh_popup()
        end
    end

    -- mouse wheel scrolls through the chips
    on_wheel = function(args)
        if #hidden.left == 0 and #hidden.right == 0 then
            return
        end
        local current = shown_first - args.Direction
        first_visible = math.max(1, math.min(current, #chips))
        layout()
    end

    text_box.TextChanged = function()
        local text = text_box:GetText() or ""
        if string.find(text, "\n", 1, true) ~= nil then
            local value = string.gsub(string.gsub(text, "\n", ""), "^%s*(.-)%s*$", "%1")
            text_box:SetText("")
            if value ~= "" then
                chips[#chips + 1] = value
                first_visible = nil
            end
            layout()
            return
        end
        hint:SetVisible(#chips == 0 and text == "")
    end

    bar.MouseClick = function()
        text_box:Focus()
    end

    clear.Click = function()
        chips = {}
        first_visible = nil
        close_popup()
        text_box:SetText("")
        layout()
    end

    chips = { "loc:Bree-land > Chetwood", "lvl:50-60", "gen:Troll", "fell beast" }
    layout()
    return bar
end

---------------------------------------------------------------------
-- window
---------------------------------------------------------------------

local function _build_menus(window)
    local bar = window:get_menu_bar()
    local file = bar:add_menu("File")
    file:add_action({ text = "New" })
    file:add_action({ text = "Open" })
    file:add_separator()
    file:add_action({ text = "Show grid", checkable = true, checked = true })
    file:add_action({ text = "Snap to grid", checkable = true, checked = false })
    file:add_separator()
    local export = file:add_menu("Export")
    export:add_action({ text = "As PNG" })
    export:add_action({ text = "As TGA" })
    local more = export:add_menu("More formats")
    more:add_action({ text = "As SVG" })
    more:add_action({ text = "Disabled format", enabled = false })
    file:add_action({ text = "Disabled item", enabled = false })

    local view = bar:add_menu("View")
    local size = view:add_menu("Tile size")
    size:add_action({ text = "Small", checkable = true, checked = false })
    size:add_action({ text = "Medium", checkable = true, checked = true })
    size:add_action({ text = "Large", checkable = true, checked = false })
    view:add_action({ text = "Group by category", checkable = true, checked = true })
end

local function _build_content(window, content)
    local W = _s(820)
    local y = 0

    -- real widgets
    y = _section(content, y, "Real widgets (migrated): dropdown, check dropdown, checkbox")
    local dd = Widgets.LuiDropdown()
    dd:SetParent(content)
    dd:set_scale(_scale())
    dd:SetPopupHost(window)
    dd:SetFont(_font(Style.CONTROL_FONT_SIZE))
    dd:SetMappedOptions({ "Bree-land", "Lone-lands", "North Downs", "Evendim" }, { 1, 2, 3, 4 })
    dd:SetPosition(0, y)
    dd:SetSize(_s(180), _s(24))

    local cdd = Widgets.LuiCheckDropdown()
    cdd:SetParent(content)
    cdd:set_scale(_scale())
    cdd:SetPopupHost(window)
    cdd:SetFont(_font(Style.CONTROL_FONT_SIZE))
    cdd:SetMappedOptions({ "Beast", "Troll", "Orc", "Spider" }, { 1, 2, 3, 4 })
    cdd:SetPosition(_s(196), y)
    cdd:SetSize(_s(180), _s(24))

    local dd_off = Widgets.LuiDropdown()
    dd_off:SetParent(content)
    dd_off:set_scale(_scale())
    dd_off:SetPopupHost(window)
    dd_off:SetFont(_font(Style.CONTROL_FONT_SIZE))
    dd_off:SetMappedOptions({ "Disabled" }, { 1 })
    dd_off:SetPosition(_s(392), y)
    dd_off:SetSize(_s(180), _s(24))
    dd_off:SetEnabled(false)
    y = y + _s(32)

    local cx = 0
    for _, spec in ipairs({ { "Enabled", true, true }, { "Unchecked", false, true }, { "Disabled", true, false } }) do
        local box = Widgets.LuiCheckBox()
        box:SetParent(content)
        box:set_scale(_scale())
        box:SetFont(_font(Style.CONTROL_FONT_SIZE))
        box:SetText(spec[1])
        box:SetChecked(spec[2])
        box:SetEnabled(spec[3])
        box:SetPosition(cx, y)
        box:SetSize(_s(140), _s(20))
        cx = cx + _s(150)
    end
    y = y + _s(32)

    -- not migrated yet: previews on plain tinted buttons
    y = _section(content, y, "Preview (not migrated yet): spin box, pager, tab scroll, + disabled")
    cx = 0
    for _, name in ipairs({ "chevron_up", "chevron_down", "plus", "minus", "chevron_left", "chevron_right" }) do
        _button(content, cx, y, _s(24), _s(24), name, 14)
        cx = cx + _s(30)
    end
    cx = cx + _s(20)
    for _, name in ipairs({ "chevron_up", "chevron_down", "plus", "minus" }) do
        _button(content, cx, y, _s(24), _s(24), name, 14):set_enabled(false)
        cx = cx + _s(30)
    end
    y = y + _s(34)

    y = _section(content, y, "Token search bar prototype: click it, type, Enter adds a chip, x removes")
    _build_search_bar(content, 0, y, W - _s(20), BAR_LARGE)
    y = y + _s(38)
    _build_search_bar(content, 0, y, W - _s(20), BAR_COMPACT)
    y = y + _s(31)

    y = _section(content, y, "Favourite star (click), bestiary current area, resize corner")
    local star = _flat_button(content, 0, y, _s(28), "star", 18)
    star._favorite = false
    star.Click = function(sender)
        sender._favorite = not sender._favorite
        if sender._favorite == true then
            sender:set_icon(Icons.path("star_filled"), nil, nil, nil, 18)
            sender:set_icon_tint(Style.ICON_ACCENT, Style.ICON_ACCENT, Style.ICON_ACCENT, Style.ICON_FOREGROUND_DISABLED)
        else
            sender:set_tinted_icon(Icons.path("star"), 18)
        end
    end
    _button(content, _s(40), y, _s(28), _s(28), "locate", 18)
    _tinted_image(content, Icons.path("resize_corner"), _s(14), _s(84), y + _s(14), Style.ICON_FOREGROUND)
    y = y + _s(40)

    y = _section(content, y, "Line weights (setting: " .. Style.ICON_WEIGHT .. "): thin vs bold, 20 px and 14 px")
    for _, weight in ipairs(Icons.WEIGHTS) do
        _label(content, weight, 0, y, _s(44), _s(24), Style.ALTERNATE_FOREGROUND)
        local gx = _s(44)
        for _, name in ipairs(WEIGHTED) do
            local path = Icons.path_for_weight(name, weight)
            _tinted_image(content, path, _s(20), gx, y + _s(2), Style.ICON_FOREGROUND)
            _tinted_image(content, path, _s(14), gx + _s(21), y + _s(5), Style.ICON_FOREGROUND)
            gx = gx + _s(44)
        end
        y = y + _s(30)
    end

    y = _section(content, y + _s(4), "Tint colors (Global > UI > Colors > Icons)")
    local sx = 0
    for _, spec in ipairs({ { "ICON_FOREGROUND", "icon" }, { "ICON_FOREGROUND_HOVER", "hover" },
        { "ICON_FOREGROUND_PRESSED", "pressed" }, { "ICON_FOREGROUND_DISABLED", "disabled" },
        { "ICON_ACCENT", "accent" } }) do
        _tinted_image(content, Icons.path("star_filled"), _s(20), sx, y, Style[spec[1]])
        _label(content, spec[2], sx + _s(24), y, _s(100), _s(20), Style.ALTERNATE_FOREGROUND)
        sx = sx + _s(120)
    end
    y = y + _s(28)

    return W, y
end

local function _build()
    local window = Widgets.LuiWindow()
    window:set_scale(_scale())
    window:set_title("LUI icon demo")
    window:enable_maximize(true)
    window:set_resizable(Widgets.LuiWindow.RESIZE_BOTH)
    _build_menus(window)

    local content = Turbine.UI.Control()
    window:set_central_widget(content)
    local w, h = _build_content(window, content)
    window:SetSize(w + _s(20), h + _s(80))
    window:SetPosition(120, 120)
    return window
end

function IconDemo.toggle()
    if IconDemo.window == nil then
        IconDemo.window = _build()
        IconDemo.window:show()
        return
    end
    IconDemo.window:toggle()
end
