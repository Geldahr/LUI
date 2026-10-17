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

-- autocomplete entries: keyword, icon, hint, extra words that also match
local KEYWORDS = {
    { key = "loc", icon = "map_pin", hint = "Location: region or area", aliases = { "location", "area", "region", "zone" } },
    { key = "lvl", icon = "level", hint = "Level: 50, >100, 50-60", aliases = { "level" } },
    { key = "gen", icon = "family", hint = "Family: genus or subcategory", aliases = { "family", "genus", "type" } },
}

-- DEMO sample: the real region > area list will be baked into the bestiary
-- pack (pre-ordered, per language)
local SAMPLE_LOCATIONS = {
    { region = "Bree-land", areas = { "Bree-town", "Buckland", "Chetwood", "Midgewater Marsh", "Old Forest", "South Bree-fields" } },
    { region = "Ered Luin", areas = { "Gondamon", "Rath Teraig", "Thorin's Gate" } },
    { region = "Evendim", areas = { "Annúminas", "Men Erain", "Tinnudir" } },
    { region = "Lone-lands", areas = { "Agamaur", "Nain Enidh", "Ost Guruth", "Weathertop" } },
    { region = "North Downs", areas = { "Esteldín", "Fields of Fornost", "Meluinen", "Trestlebridge" } },
    { region = "The Shire", areas = { "Hobbiton", "Michel Delving", "Stock", "Thistle Brook" } },
}

-- keyword chips show an icon instead of "key:"
local CHIP_KEYWORDS = {
    loc = "map_pin",
    lvl = "level",
    gen = "family",
}


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
    -- one line: a too-narrow label must clip, never wrap
    label:SetMultiline(false)
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
-- token search bar: Widgets.TokenInput fed by the demo callbacks
---------------------------------------------------------------------

local function _trim(text)
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

-- chips: "loc:Bree" -> map pin + "Bree"
local function _format_token(_, token)
    local key, value = string.match(token, "^(%a+):(.+)$")
    local icon = key ~= nil and CHIP_KEYWORDS[string.lower(key)] or nil
    if icon == nil then
        return nil, token
    end
    return icon, value
end

local function _keyword_items(typed)
    local out = {}
    for _, entry in ipairs(KEYWORDS) do
        local hit = typed == "" or string.sub(entry.key, 1, #typed) == typed
        for _, alias in ipairs(entry.aliases) do
            if string.sub(alias, 1, #typed) == typed then
                hit = true
            end
        end
        if hit == true then
            -- keyword rows show the chip's icon; value rows (regions, areas) none
            out[#out + 1] = { icon = entry.icon, text = entry.key .. ":", hint = entry.hint, value = entry.key .. ":" }
        end
    end
    return out
end

local function _region_items(typed)
    local out = {}
    for _, location in ipairs(SAMPLE_LOCATIONS) do
        if typed == "" or string.find(string.lower(location.region), typed, 1, true) ~= nil then
            -- replaces only the part after "loc:" (range returned below)
            out[#out + 1] = { text = location.region, hint = #location.areas .. " areas",
                value = location.region .. " > " }
        end
    end
    return out
end

local function _area_items(location, typed)
    local out = {}
    if typed == "" then
        out[1] = { text = "All of " .. location.region, value = "loc:" .. location.region, final = true }
    end
    for _, area in ipairs(location.areas) do
        if string.lower(area) == typed then
            return {} -- already complete
        end
        if typed == "" or string.find(string.lower(area), typed, 1, true) ~= nil then
            out[#out + 1] = { text = area, value = "loc:" .. location.region .. " > " .. area, final = true }
        end
    end
    return out
end

-- keyword (whole text), then (loc:) region (range after "loc:"), then area
-- (whole text, so "All of <region>" can drop the "> " part)
local function _suggestions(_, text)
    local typed = string.lower(_trim(text))
    local key, rest = string.match(typed, "^(%a+):(.*)$")
    if key == nil then
        return _keyword_items(typed)
    end
    if key ~= "loc" then
        return {}
    end
    local region_part, area_part = string.match(rest, "^(.-)%s*>%s*(.*)$")
    if region_part == nil then
        return _region_items(_trim(rest)), string.find(text, ":", 1, true) + 1
    end
    for _, location in ipairs(SAMPLE_LOCATIONS) do
        if string.lower(location.region) == _trim(region_part) then
            return _area_items(location, _trim(area_part))
        end
    end
    return {}
end

local function _build_token_input(parent, x, y, w, variant, host)
    local input = Widgets.TokenInput()
    input:SetParent(parent)
    input:set_popup_host(host)
    input:set_scale(_scale())
    input:set_variant(variant)
    input:set_leading_icon("search")
    input:set_placeholder("Search tokens...")
    input.FormatToken = _format_token
    input.Suggestions = _suggestions
    input:SetPosition(x, y)
    input:SetSize(w)
    input:set_tokens({ "loc:Bree-land > Chetwood", "lvl:50-60", "gen:Troll", "fell beast" })
    return input
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

    y = _section(content, y, "TokenInput (large, compact): type, Enter adds a chip, x removes, double-click lists")
    local large = _build_token_input(content, 0, y, W - _s(20), Widgets.TokenInput.LARGE, window)
    y = y + large:get_height() + _s(8)
    local compact = _build_token_input(content, 0, y, W - _s(20), Widgets.TokenInput.COMPACT, window)
    y = y + compact:get_height() + _s(10)

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
