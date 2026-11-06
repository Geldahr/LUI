-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Shared sizes, phases and control helpers of the Bag Order Guide window
-- (bag_order_window / _panel / _list / _marker).

local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Inventory = _G.LUI.Features.Inventory
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
import "Turbine.UI"
import "LUI.src.UI.Widgets"
import "LUI.src.Utils.font"

local Common = {}
Inventory.BagOrderCommon = Common

Common.PHASE_BAGS = "bags"
Common.PHASE_MARKER = "marker"
Common.PHASE_STEPS = "steps"
Common.PHASE_DONE = "done"

-- base sizes, px at scale 1
Common.BASE_MARGIN = 10
Common.BASE_PANEL_W = 300
Common.BASE_GAP = 6
Common.BASE_SEP_GAP = 10
Common.BASE_ICON = 32
Common.BASE_TILE_GAP = 2
Common.BASE_ROW_PAD = 2
Common.BASE_RANGE_W = 56
Common.BASE_CHECK = 12
Common.BASE_HEADER_H = 20
Common.BASE_BOX = 36
Common.BASE_PROGRESS_H = 4
Common.BASE_FONT = 12
Common.BASE_SMALL_FONT = 10
Common.BASE_ACTION_FONT = 14
Common.BASE_TITLE_FONT = 16
Common.BASE_LINE_H = 15
Common.BASE_SMALL_LINE_H = 13
Common.BASE_ACTION_LINE_H = 17
Common.BASE_TITLE_H = 22

function Common.scaled(value)
    return math.floor((value * State.settings.global.scale) + 0.5)
end

function Common.scaled_even(value)
    local size = Common.scaled(value)
    if size % 2 ~= 0 then
        size = size + 1
    end
    return size
end

function Common.font(size)
    local font = FONT_TO_LOTRO("Verdana", size * State.settings.global.scale)
    if font == nil then
        error("Missing scaled font: Verdana " .. tostring(size))
    end
    return font
end

function Common.label(parent, font, color, alignment, multiline)
    local label = UI.Widgets.LuiLabel()
    label:SetParent(parent)
    label:SetMouseVisible(false)
    label:SetSelectable(false)
    label:SetMultiline(multiline == true)
    label:SetFont(font)
    label:SetForeColor(color)
    label:SetTextAlignment(alignment)
    return label
end

-- a colored rectangle; alpha-blended like LuiWindow's own controls, else a
-- transparent color (row bands) erases the window background behind it
function Common.block(parent, color)
    local block = Turbine.UI.Control()
    block:SetParent(parent)
    block:SetMouseVisible(false)
    block:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    block:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    block:SetBackColor(color)
    return block
end

function Common.place(control, x, y, w, h)
    control:SetPosition(x, y)
    control:SetSize(w, h)
    control:SetVisible(true)
end
