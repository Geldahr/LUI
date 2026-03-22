local S = _G.STATUS_BAR_COMMON
local WidgetBase = _G.StatusBarWidgetBase

local TimeLocalWidget = class(WidgetBase)
_G.TimeLocalWidget = TimeLocalWidget

function TimeLocalWidget:Constructor(widget_w, bar_h, font, icon_path, content_alignment)
    WidgetBase.Constructor(self, "time_local", widget_w, bar_h, font,
        content_alignment or Turbine.UI.ContentAlignment.MiddleCenter, icon_path)
end

function TimeLocalWidget:update(now)
    self:set_text(S.format_hhmm(Turbine.Engine.GetDate()))
end
