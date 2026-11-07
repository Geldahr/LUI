-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- LuiWindow's header bar between the icon and the header buttons: the menu
-- bar, the drag regions and the title. A narrow window degrades in two
-- steps: the title hides when it no longer fits, centered, clear of the
-- menus and the buttons; when even the menus do not fit, they collapse into
-- a single "Menu" (and the title comes back if it fits beside it).
-- Imported by window.lua once LuiWindow exists.

local Utils = _G.LUI.Utils
local UI = _G.LUI.UI
import "LUI.src.Utils.text_width"

local LuiWindow = UI.Widgets.LuiWindow

-- the title's drawn width, measured again only when its text or font changes
function LuiWindow:_title_width()
    local text = self._title_label:GetText()
    local font = self._title_font
    if text ~= self._title_w_text or font ~= self._title_w_font then
        self._title_w_text = text
        self._title_w_font = font
        if text == "" then
            self._title_w = 0
        else
            -- +2: glyph edges, as the menus measure their titles
            self._title_w = Utils.measure_text_width_in_font(text, font) + 2
        end
    end
    return self._title_w
end

-- left_x: right of the icon; actions_x: left of the title buttons
function LuiWindow:_layout_header_bar(inner_w, header_h, gap, left_x, actions_x)
    local bar = self._menu_bar
    local free_w = math.max(0, actions_x - gap - left_x)
    bar:set_collapsed(bar:expanded_width() > free_w)
    local menu_w = math.min(bar:preferred_width(), free_w)
    bar:SetPosition(left_x, 0)
    bar:SetSize(menu_w, header_h)
    bar:SetZOrder(20)
    bar:SetVisible(menu_w > 0)

    self._header_drag_left:SetPosition(0, 0)
    self._header_drag_left:SetSize(math.max(0, left_x), header_h)

    local drag_body_x = left_x + menu_w + gap
    self._header_drag_body:SetPosition(drag_body_x, 0)
    self._header_drag_body:SetSize(math.max(0, actions_x - gap - drag_body_x), header_h)

    local clear_left = left_x
    if menu_w > 0 then
        clear_left = drag_body_x
    end
    local title_w = self:_title_width()
    local title_x = math.floor((inner_w - title_w) / 2)
    self._title_label:SetPosition(0, 0)
    self._title_label:SetSize(inner_w, header_h)
    self._title_label:SetVisible(title_w > 0 and title_x >= clear_left and title_x + title_w <= actions_x - gap)
end
