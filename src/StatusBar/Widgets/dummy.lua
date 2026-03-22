local WidgetBase = _G.StatusBarWidgetBase
local DummyWidget = class(WidgetBase)
_G.DummyWidget = DummyWidget

function DummyWidget:Constructor(widget_key, widget_w, bar_h, font, content_alignment, icon_path)
    WidgetBase.Constructor(self, widget_key, widget_w, bar_h, font, content_alignment, icon_path)
end

function DummyWidget:update(now)
    self:set_text("--")
end
