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

local function _build_search_bar(parent, x, y, w)
    local h = _s(30)
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

    _tinted_image(bar, Icons.path("search"), _s(16), _s(7), math.floor((h - _s(16)) / 2), Style.ICON_FOREGROUND)

    local chip_layer = Turbine.UI.Control()
    chip_layer:SetParent(bar)
    chip_layer:SetPosition(_s(28), 0)
    chip_layer:SetMouseVisible(false)

    local text_box = Turbine.UI.TextBox()
    text_box:SetParent(bar)
    _set_alpha_blend(text_box)
    text_box:SetFont(_font(Style.CONTROL_FONT_SIZE))
    text_box:SetForeColor(Style.CONTROL_FOREGROUND)
    -- same color as the bar; a transparent TextBox shows the 3D world
    text_box:SetBackColor(Style.ALTERNATE_BACKGROUND)
    text_box:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)

    local hint = _label(bar, "Search tokens...", 0, 0, _s(380), h,
        Style.PLACEHOLDER_FOREGROUND, Style.CONTENT_SMALL_FONT_SIZE + 1)

    local clear = _flat_button(bar, w - _s(28), math.floor((h - _s(24)) / 2), _s(24), "window_close", 12)

    local chips = {}
    local chip_controls = {}
    local layout

    local function make_chip(text, cx)
        local key, value = string.match(text, "^(%a+):(.+)$")
        local icon = key ~= nil and CHIP_KEYWORDS[string.lower(key)] or nil
        if icon == nil then
            value = text
        end
        local ch = _s(22)
        local text_w = _s(10 + 7 * string.len(value))
        local icon_w = icon ~= nil and _s(18) or 0
        local cw = _s(6) + icon_w + text_w + _s(20)

        local chip = Turbine.UI.Control()
        chip:SetParent(chip_layer)
        chip:SetPosition(cx, math.floor((h - ch) / 2))
        chip:SetSize(cw, ch)
        _set_alpha_blend(chip)
        chip:SetBackColor(Style.CONTROL_BACKGROUND)

        local tx = _s(6)
        if icon ~= nil then
            _tinted_image(chip, Icons.path(icon), _s(14), tx, math.floor((ch - _s(14)) / 2), Style.ICON_FOREGROUND)
            tx = tx + icon_w
        end
        _label(chip, value, tx, 0, text_w, ch, Style.CONTROL_FOREGROUND, Style.CONTENT_SMALL_FONT_SIZE + 1)
        local remove = _flat_button(chip, cw - _s(19), math.floor((ch - _s(16)) / 2), _s(16), "window_close", 9)
        remove.Click = function()
            for i = 1, #chips do
                if chips[i] == text then
                    table.remove(chips, i)
                    break
                end
            end
            layout()
        end
        return chip, cw
    end

    layout = function()
        for i = 1, #chip_controls do
            -- a detached control is still drawn at the screen origin: hide first
            chip_controls[i]:SetVisible(false)
            chip_controls[i]:SetParent(nil)
        end
        chip_controls = {}
        local cx = 0
        for i = 1, #chips do
            local chip, cw = make_chip(chips[i], cx)
            chip_controls[#chip_controls + 1] = chip
            cx = cx + cw + _s(5)
        end
        chip_layer:SetSize(cx, h)
        local tx = _s(28) + cx + _s(4)
        local tw = math.max(_s(100), w - tx - _s(32))
        text_box:SetPosition(tx, math.floor((h - _s(20)) / 2))
        text_box:SetSize(tw, _s(20))
        hint:SetPosition(tx, 0)
        hint:SetVisible(#chips == 0 and (text_box:GetText() or "") == "")
    end

    text_box.TextChanged = function()
        local text = text_box:GetText() or ""
        if string.find(text, "\n", 1, true) ~= nil then
            local value = string.gsub(string.gsub(text, "\n", ""), "^%s*(.-)%s*$", "%1")
            text_box:SetText("")
            if value ~= "" then
                chips[#chips + 1] = value
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
    dd:SetMappedOptions({ "Bree-land", "Lone-lands", "North Downs", "Evendim" }, { 1, 2, 3, 4 })
    dd:SetPosition(0, y)
    dd:SetSize(_s(180), _s(24))

    local cdd = Widgets.LuiCheckDropdown()
    cdd:SetParent(content)
    cdd:set_scale(_scale())
    cdd:SetPopupHost(window)
    cdd:SetMappedOptions({ "Beast", "Troll", "Orc", "Spider" }, { 1, 2, 3, 4 })
    cdd:SetPosition(_s(196), y)
    cdd:SetSize(_s(180), _s(24))

    local dd_off = Widgets.LuiDropdown()
    dd_off:SetParent(content)
    dd_off:set_scale(_scale())
    dd_off:SetPopupHost(window)
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
    _build_search_bar(content, 0, y, W - _s(20))
    y = y + _s(40)

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
