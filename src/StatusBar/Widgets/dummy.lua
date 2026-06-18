local StatusBarWidgets = _G.LUI.Features.StatusBar.Widgets
local class = _G.LUI.Core.class
local WidgetBase = _G.LUI.Features.StatusBar.WidgetBase
local DummyWidget = class(WidgetBase)
StatusBarWidgets.DummyWidget = DummyWidget

function DummyWidget:Constructor(widget_key, widget_w, bar_h, font, content_alignment, icon_path)
    WidgetBase.Constructor(self, widget_key, widget_w, bar_h, font, content_alignment, icon_path)
end

function DummyWidget:update(now)
    self:set_text("--")
end
