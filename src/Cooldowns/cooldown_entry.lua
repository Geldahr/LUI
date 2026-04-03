import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets"
import "LUI.src.Settings.enums"
import "LUI.src.Utils.time_format"
import "LUI.src.Utils.token_format"

CooldownEntry = class(Turbine.UI.Control)

local function _text_alignment(value)
    return LUI_TO_LOTRO.text_alignment[value] or Turbine.UI.ContentAlignment.MiddleLeft
end

local function _truncate_name(name, max_chars)
    if type(name) ~= "string" then
        name = tostring(name or "")
    end

    local m = max_chars
    if m <= 0 then
        return name
    end

    m = math.floor(m + 0.5)
    if m < 1 then
        return ""
    end

    if string.len(name) <= m then
        return name
    end

    if m >= 4 then
        return string.sub(name, 1, m - 3) .. "..."
    end

    return string.sub(name, 1, m)
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function CooldownEntry:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.skill = nil
    self.expired_event = nil
    self._expired_sent = false
    self._ctx = {}
    self.bar_inner_w = 0
    self.bar_anchor_right = false
    self._icon_size = nil

    self:SetMouseVisible(false)

    self.border_top = Turbine.UI.Control()
    self.border_top:SetParent(self)
    self.border_top:SetMouseVisible(false)

    self.border_bottom = Turbine.UI.Control()
    self.border_bottom:SetParent(self)
    self.border_bottom:SetMouseVisible(false)

    self.border_left = Turbine.UI.Control()
    self.border_left:SetParent(self)
    self.border_left:SetMouseVisible(false)

    self.border_right = Turbine.UI.Control()
    self.border_right:SetParent(self)
    self.border_right:SetMouseVisible(false)

    self.separator = Turbine.UI.Control()
    self.separator:SetParent(self)
    self.separator:SetMouseVisible(false)

    self.bar_background = Turbine.UI.Control()
    self.bar_background:SetParent(self)
    self.bar_background:SetMouseVisible(false)

    self.bar_fill = Turbine.UI.Control()
    self.bar_fill:SetParent(self.bar_background)
    self.bar_fill:SetMouseVisible(false)

    self.label = UI.Widgets.LuiLabel()
    self.label:SetParent(self.bar_background)
    self.label:SetMouseVisible(false)
    self.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.label:SetText("")

    self.icon_background = Turbine.UI.Control()
    self.icon_background:SetParent(self)
    self.icon_background:SetMouseVisible(false)

    self.icon = Image()
    self.icon:SetParent(self.icon_background)
    self.icon:SetVisible(false)
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function CooldownEntry:apply_settings()
    local s = _G.settings.self.cooldowns
    local bw = s.border_width

    local w = s.item_w
    local h = s.item_h
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end

    self:SetSize(w, h)

    local border = bw
    if type(border) ~= "number" then
        border = 0
    end
    border = math.floor(border + 0.5)
    if border < 0 then border = 0 end
    if border * 2 >= w then border = math.floor((w - 1) / 2) end
    if border * 2 >= h then border = math.floor((h - 1) / 2) end
    if border < 0 then border = 0 end

    local bc = s.color.border
    self.border_top:SetBackColor(bc)
    self.border_bottom:SetBackColor(bc)
    self.border_left:SetBackColor(bc)
    self.border_right:SetBackColor(bc)

    self.border_top:SetPosition(0, 0)
    self.border_top:SetSize(w, border)
    self.border_bottom:SetPosition(0, h - border)
    self.border_bottom:SetSize(w, border)
    self.border_left:SetPosition(0, 0)
    self.border_left:SetSize(border, h)
    self.border_right:SetPosition(w - border, 0)
    self.border_right:SetSize(border, h)

    local inner_w = w - (2 * border)
    local inner_h = h - (2 * border)
    if inner_w < 1 then inner_w = 1 end
    if inner_h < 1 then inner_h = 1 end

    local sep_w = border
    if sep_w < 0 then sep_w = 0 end
    if sep_w >= inner_w then sep_w = inner_w - 1 end
    if sep_w < 0 then sep_w = 0 end

    local icon_size = inner_h
    local max_icon = inner_w - sep_w - 1
    if max_icon < 1 then max_icon = 1 end
    if icon_size > max_icon then
        icon_size = max_icon
    end
    self._icon_size = icon_size

    local bar_width = inner_w - icon_size - sep_w
    if bar_width < 1 then bar_width = 1 end
    self.bar_inner_w = bar_width

    local icon_left = LUI_ENUMS.side_is_left[s.icon_side] == true

    local back = s.color.background
    self.separator:SetBackColor(s.color.border)
    self.separator:SetVisible(sep_w > 0)

    if icon_left then
        self.icon_background:SetPosition(border, border)
        self.icon_background:SetSize(icon_size, icon_size)
        self.icon_background:SetBackColor(back)

        self.separator:SetPosition(border + icon_size, border)
        self.separator:SetSize(sep_w, inner_h)

        self.bar_background:SetPosition(border + icon_size + sep_w, border)
    else
        self.bar_background:SetPosition(border, border)
        self.separator:SetPosition(border + bar_width, border)
        self.separator:SetSize(sep_w, inner_h)

        self.icon_background:SetPosition(border + bar_width + sep_w, border)
        self.icon_background:SetSize(icon_size, icon_size)
        self.icon_background:SetBackColor(back)
    end

    self.bar_background:SetSize(bar_width, inner_h)
    self.bar_background:SetBackColor(back)

    -- The background should be exactly the content size (no extra inner border).
    self.bar_fill:SetPosition(0, 0)
    self.bar_fill:SetSize(bar_width, inner_h)
    self.bar_fill:SetBackColor(s.color.bar)

    local pad = s.text_margin
    self.label:SetPosition(pad, 0)
    local label_width = bar_width - (2 * pad)
    if label_width < 1 then label_width = 1 end
    self.label:SetSize(label_width, inner_h)
    self.label:SetFont(s.font.lotro)
    self.label:SetFontStyle(LUI_TO_LOTRO.font_style[s.font.style] or Turbine.UI.FontStyle.None)
    self.label:SetTextAlignment(_text_alignment(s.text_alignment))
    self.label:SetOutlineColor(s.font.outline_color)
    self.label:SetForeColor(s.font.color)

    self.icon:SetPosition(0, 0)
    self.icon:set_size(icon_size, icon_size)
    if self.skill ~= nil and self.skill.icon ~= nil then
        self.icon:set_icon(self.skill.icon, icon_size, icon_size)
    end

    local towards_right = s.bar_expire_towards == LUI_ENUMS.side.RIGHT
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        self.bar_anchor_right = towards_right ~= true
    else
        self.bar_anchor_right = towards_right
    end
end

function CooldownEntry:set_skill(skill)
    if skill == nil then
        self.skill = nil
        self._expired_sent = false
        if self._icon_size ~= nil then
            self.icon:set_icon(nil, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(nil)
        end
        self.icon:SetVisible(false)
        self.label:SetText("")
        self.bar_fill:SetWidth(0)
        self:SetVisible(false)
        return
    end

    if skill == self.skill then
        return
    end

    self.skill = skill
    self._expired_sent = false
    self:SetVisible(true)

    if skill.icon ~= nil then
        if self._icon_size ~= nil then
            self.icon:set_icon(skill.icon, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(skill.icon)
        end
        self.icon:SetVisible(true)
    else
        if self._icon_size ~= nil then
            self.icon:set_icon(nil, self._icon_size, self._icon_size)
        else
            self.icon:set_icon(nil)
        end
        self.icon:SetVisible(false)
    end
end

function CooldownEntry:update_remaining(remaining_seconds, base_seconds)
    local s = _G.settings.self.cooldowns

    if self.skill == nil then
        self.label:SetText("")
        self.bar_fill:SetWidth(0)
        return
    end

    if remaining_seconds <= 0 then
        if not self._expired_sent then
            self._expired_sent = true
            if self.expired_event ~= nil then
                self.expired_event()
            end
        end
    else
        self._expired_sent = false
    end

    local inner_width = self.bar_inner_w

    local base = base_seconds
    if base <= 0 then
        base = remaining_seconds
    end

    local ratio = remaining_seconds / base
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local percent = ratio
    if s.bar_mode == LUI_ENUMS.bar_mode.LOAD then
        percent = 1 - ratio
    end

    local fill_width = math.floor(inner_width * percent + 0.5)
    if fill_width < 0 then fill_width = 0 end
    if fill_width > inner_width then fill_width = inner_width end

    if self.bar_anchor_right then
        self.bar_fill:SetPosition(inner_width - fill_width, 0)
    else
        self.bar_fill:SetPosition(0, 0)
    end
    self.bar_fill:SetWidth(fill_width)

    local name = _truncate_name(self.skill.name or "", s.name_max_chars)
    local ctx = self._ctx
    ctx.name = name
    ctx.t = lui_format_timeout(remaining_seconds)
    ctx.s = lui_format_timeout_seconds(remaining_seconds)
    -- Also provide short aliases (no compatibility logic needed; just extra keys).
    ctx.n = name
    ctx.ts = ctx.s
    self.label:SetText(lui_format_tokenized(s.text_tokens, ctx))
end
