-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Font calibration window (not loaded by the plugin). To recalibrate: copy
-- to src/UI/, import it from src/UI/__init__.lua, add a `/lui fontcal`
-- command calling UI.FontCalibration.toggle() in src/Utils/cli.lua, then
-- screenshot every page and run tools/fonts/measure_fonts.py.
-- Every LotRO font LUI can resolve, every character: one blue cell per
-- character showing "|" .. char x reps .. "|". A screenshot script measures
-- the ink width of each cell; (cell - "||" reference cell) / reps gives the
-- exact advance of the character. The layout is deterministic for a given
-- page size (shown in the header) so the analysis rebuilds the same order.

local LUI = _G.LUI
local UI = LUI.UI

local FontCal = {}
UI.FontCalibration = FontCal

-- same families and sizes as Utils.FONT_TO_LOTRO
local FONTS = {
    { "Verdana", { 10, 12, 14, 16, 18, 20, 22, 23 } },
    { "VerdanaBold", { 16 } },
    { "Arial", { 12 } },
    { "BookAntiqua", { 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36 } },
    { "BookAntiquaBold", { 12, 14, 18, 19, 22, 24 } },
    { "TrajanPro", { 13, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 28 } },
    { "TrajanProBold", { 16, 22, 24, 25, 30, 36 } },
    { "FixedSys", { 15 } },
    { "LucidaConsole", { 12 } },
}

-- "" = reference cell "||"; then printable ASCII; then accents and the
-- extra keys of European keyboards
local EXTRA = {
    "à", "á", "â", "ä", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ñ", "ò", "ó", "ô", "ö",
    "ù", "ú", "û", "ü", "ý", "À", "Á", "Â", "Ä", "Ç", "È", "É", "Ê", "Ë", "Í", "Î", "Ó", "Ô",
    "Ö", "Ú", "Û", "Ü", "ß", "æ", "œ", "€", "£", "§", "°", "²", "µ", "¤", "¨",
}
local CHARS = { "" }
for code = 32, 126 do
    CHARS[#CHARS + 1] = string.char(code)
end
for i = 1, #EXTRA do
    CHARS[#CHARS + 1] = EXTRA[i]
end

local HEADER = 16
local GAP = 3
local MARGIN = 10
local NAV_H = 30

local function _reps(size)
    if size <= 14 then
        return 8
    elseif size <= 22 then
        return 5
    end
    return 4
end

local function _cell_size(family, size)
    local factor = 1.15
    if string.sub(family, 1, 6) == "Trajan" then
        factor = 1.4
    end
    return math.floor((_reps(size) + 2) * factor * size) + 10, size + 6
end

-- pages[i] = list of { kind = "header"|"cell", x, y, w, h, family, size, char }
local function _layout(page_w, page_h)
    local pages = { {} }
    local y = 0
    local function new_page()
        pages[#pages + 1] = {}
        y = 0
    end
    for _, spec in ipairs(FONTS) do
        local family = spec[1]
        for _, size in ipairs(spec[2]) do
            local cw, ch = _cell_size(family, size)
            local cols = math.max(1, math.floor(page_w / (cw + GAP)))
            if y + HEADER + ch + GAP > page_h then
                new_page()
            end
            local page = pages[#pages]
            page[#page + 1] = { kind = "header", x = 0, y = y, w = page_w, h = HEADER,
                text = family .. " " .. size .. "  (reps " .. _reps(size) .. ")" }
            y = y + HEADER
            local col = 0
            for i = 1, #CHARS do
                if col == 0 and y + ch + GAP > page_h then
                    new_page()
                end
                page = pages[#pages]
                page[#page + 1] = { kind = "cell", x = col * (cw + GAP), y = y, w = cw, h = ch,
                    family = family, size = size, char = CHARS[i] }
                col = col + 1
                if col >= cols then
                    col = 0
                    y = y + ch + GAP
                end
            end
            if col ~= 0 then
                y = y + ch + GAP
            end
        end
    end
    return pages
end

local function _show_page(state, index)
    for i = 1, #state.controls do
        -- a detached control is still drawn at the screen origin: hide first
        state.controls[i]:SetVisible(false)
        state.controls[i]:SetParent(nil)
    end
    state.controls = {}
    state.index = index

    for _, item in ipairs(state.pages[index]) do
        if item.kind == "header" then
            local label = Turbine.UI.Label()
            label:SetParent(state.area)
            label:SetPosition(item.x, item.y)
            label:SetSize(item.w, item.h)
            label:SetFont(Turbine.UI.Lotro.Font.Verdana12)
            label:SetForeColor(Turbine.UI.Color(1, 0.9, 0.75, 0.3))
            label:SetMultiline(false)
            label:SetText(item.text)
            state.controls[#state.controls + 1] = label
        else
            local box = Turbine.UI.Control()
            box:SetParent(state.area)
            box:SetPosition(item.x, item.y)
            box:SetSize(item.w, item.h)
            box:SetBackColor(Turbine.UI.Color(1, 0, 0, 0.45))
            local label = Turbine.UI.Label()
            label:SetParent(box)
            label:SetPosition(4, 0)
            label:SetSize(item.w - 8, item.h)
            label:SetFont(Turbine.UI.Lotro.Font[item.family .. tostring(item.size)])
            label:SetForeColor(Turbine.UI.Color(1, 1, 1, 1))
            label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
            label:SetMultiline(false)
            label:SetText("|" .. string.rep(item.char, _reps(item.size)) .. "|")
            label:SetMouseVisible(false)
            state.controls[#state.controls + 1] = box
        end
    end
    state.page_label:SetText("Page " .. index .. " / " .. #state.pages
        .. "    area " .. state.page_w .. " x " .. state.page_h
        .. "    (game screenshot key on every page)")
end

local function _build()
    local display_w, display_h = Turbine.UI.Display.GetSize()
    local page_w = math.min(1880, display_w - 60)
    local page_h = math.min(1000, display_h - 60 - NAV_H)

    local window = Turbine.UI.Window()
    window:SetPosition(20, 20)
    window:SetSize(page_w + 2 * MARGIN, page_h + 2 * MARGIN + NAV_H)
    window:SetBackColor(Turbine.UI.Color(1, 0, 0, 0))
    window:SetZOrder(5000)

    local area = Turbine.UI.Control()
    area:SetParent(window)
    area:SetPosition(MARGIN, MARGIN)
    area:SetSize(page_w, page_h)

    local state = {
        window = window, area = area, controls = {}, index = 1,
        page_w = page_w, page_h = page_h, pages = _layout(page_w, page_h),
    }

    local nav_y = MARGIN + page_h + 4
    local function nav_button(text, x, delta)
        local button = Turbine.UI.Lotro.Button()
        button:SetParent(window)
        button:SetPosition(x, nav_y)
        button:SetSize(80, 20)
        button:SetText(text)
        button.Click = function()
            local target = state.index + delta
            if target >= 1 and target <= #state.pages then
                _show_page(state, target)
            end
        end
    end
    nav_button("< Prev", MARGIN, -1)
    nav_button("Next >", MARGIN + 90, 1)
    local close = Turbine.UI.Lotro.Button()
    close:SetParent(window)
    close:SetPosition(MARGIN + page_w - 80, nav_y)
    close:SetSize(80, 20)
    close:SetText("Close")
    close.Click = function()
        window:SetVisible(false)
    end

    state.page_label = Turbine.UI.Label()
    state.page_label:SetParent(window)
    state.page_label:SetPosition(MARGIN + 190, nav_y)
    state.page_label:SetSize(page_w - 290, 20)
    state.page_label:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    state.page_label:SetForeColor(Turbine.UI.Color(1, 0.9, 0.9, 0.9))
    state.page_label:SetMultiline(false)

    _show_page(state, 1)
    return state
end

function FontCal.toggle()
    if FontCal.state == nil then
        FontCal.state = _build()
        FontCal.state.window:SetVisible(true)
        return
    end
    FontCal.state.window:SetVisible(not FontCal.state.window:IsVisible())
end
