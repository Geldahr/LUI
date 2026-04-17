import "Turbine.UI"
import "Turbine.UI.Lotro"

import "LUI.src.UI.Widgets.label"
import "LUI.src.UI.Widgets.style"

local DEFAULT_INSET_X = 4
local PLACEHOLDER_CURSOR_GAP = 2
local Style = UI.Widgets.Style

---@class LuiLineEdit : Turbine.UI.Control
LuiLineEdit = class(Turbine.UI.Control)

function LuiLineEdit:Constructor()
    Turbine.UI.Control.Constructor(self)

    self._placeholder_text = ""
    self._placeholder_color = Style.PLACEHOLDER_FOREGROUND
    self._text_alignment = Turbine.UI.ContentAlignment.MiddleLeft

    self.text_box = Turbine.UI.Lotro.TextBox()
    self.text_box:SetParent(self)
    self.text_box:SetZOrder(1)
    self.text_box:SetTextAlignment(self._text_alignment)

    self.placeholder_label = LuiLabel()
    self.placeholder_label:SetParent(self)
    self.placeholder_label:SetZOrder(2)
    self.placeholder_label:SetMouseVisible(false)
    self.placeholder_label:SetSelectable(false)
    self.placeholder_label:SetTextAlignment(self._text_alignment)
    self.placeholder_label:SetForeColor(self._placeholder_color)
    self.placeholder_label:SetText("")
    self.placeholder_label:SetVisible(false)

    self.text_box.MouseEnter = function(sender, args)
        if type(self.MouseEnter) == "function" then
            self.MouseEnter(self, args)
        end
    end
    self.text_box.MouseLeave = function(sender, args)
        if type(self.MouseLeave) == "function" then
            self.MouseLeave(self, args)
        end
    end
    self.text_box.TextChanged = function(sender, args)
        self:_refresh_placeholder()
        if type(self.TextChanged) == "function" then
            self.TextChanged(self, args)
        end
    end
    self.text_box.FocusGained = function(sender, args)
        if type(self.FocusGained) == "function" then
            self.FocusGained(self, args)
        end
    end
    self.text_box.FocusLost = function(sender, args)
        if type(self.FocusLost) == "function" then
            self.FocusLost(self, args)
        end
    end
    self.text_box.KeyDown = function(sender, args)
        if type(self.KeyDown) == "function" then
            self.KeyDown(self, args)
        end
    end
    self.text_box.KeyUp = function(sender, args)
        if type(self.KeyUp) == "function" then
            self.KeyUp(self, args)
        end
    end
end

function LuiLineEdit:_layout()
    local w, h = self:GetSize()
    self.text_box:SetPosition(0, 0)
    self.text_box:SetSize(w, h)

    local inset_x = DEFAULT_INSET_X + PLACEHOLDER_CURSOR_GAP
    self.placeholder_label:SetPosition(inset_x, 0)
    self.placeholder_label:SetSize(math.max(0, w - (inset_x * 2)), h)
end

function LuiLineEdit:_refresh_placeholder()
    local text = self.text_box:GetText() or ""
    self.placeholder_label:SetVisible(self._placeholder_text ~= "" and text == "")
end

function LuiLineEdit:set_placeholder_text(text)
    self._placeholder_text = tostring(text or "")
    self.placeholder_label:SetText(self._placeholder_text)
    self:_refresh_placeholder()
end

function LuiLineEdit:get_placeholder_text()
    return self._placeholder_text
end

function LuiLineEdit:set_placeholder_color(color)
    if color == nil then
        return
    end
    self._placeholder_color = color
    self.placeholder_label:SetForeColor(color)
end

function LuiLineEdit:SetPlaceholderText(text)
    self:set_placeholder_text(text)
end

function LuiLineEdit:GetPlaceholderText()
    return self:get_placeholder_text()
end

function LuiLineEdit:SetPlaceholderColor(color)
    self:set_placeholder_color(color)
end

function LuiLineEdit:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self:_layout()
end

function LuiLineEdit:SetFont(font)
    if font == nil then
        return
    end
    self.text_box:SetFont(font)
    self.placeholder_label:SetFont(font)
end

function LuiLineEdit:SetTextAlignment(alignment)
    if alignment == nil then
        return
    end
    self._text_alignment = alignment
    self.text_box:SetTextAlignment(alignment)
    self.placeholder_label:SetTextAlignment(alignment)
end

function LuiLineEdit:SetForeColor(color)
    if color ~= nil and self.text_box.SetForeColor ~= nil then
        self.text_box:SetForeColor(color)
    end
end

function LuiLineEdit:SetBackColor(color)
    if color == nil then
        return
    end
    Turbine.UI.Control.SetBackColor(self, color)
    if self.text_box.SetBackColor ~= nil then
        self.text_box:SetBackColor(color)
    end
end

function LuiLineEdit:SetMultiline(multiline)
    if self.text_box.SetMultiline ~= nil then
        self.text_box:SetMultiline(multiline)
    end
end

function LuiLineEdit:SetText(text)
    self.text_box:SetText(text or "")
    self:_refresh_placeholder()
end

function LuiLineEdit:GetText()
    return self.text_box:GetText()
end

function LuiLineEdit:SetWantsKeyEvents(wants_key_events)
    if self.text_box.SetWantsKeyEvents ~= nil then
        self.text_box:SetWantsKeyEvents(wants_key_events)
    end
end

function LuiLineEdit:SetSelectable(selectable)
    if self.text_box.SetSelectable ~= nil then
        self.text_box:SetSelectable(selectable)
    end
end

function LuiLineEdit:SetReadOnly(read_only)
    if self.text_box.SetReadOnly ~= nil then
        self.text_box:SetReadOnly(read_only)
    end
end

function LuiLineEdit:SetEnabled(enabled)
    Turbine.UI.Control.SetEnabled(self, enabled)
    if self.text_box.SetEnabled ~= nil then
        self.text_box:SetEnabled(enabled)
    end
end

function LuiLineEdit:Focus()
    self.text_box:Focus()
end

function LuiLineEdit:HasFocus()
    if self.text_box.HasFocus == nil then
        return false
    end
    return self.text_box:HasFocus()
end

function LuiLineEdit:destroy()
    if self.placeholder_label ~= nil then
        self.placeholder_label:SetParent(nil)
    end
    if self.text_box ~= nil then
        self.text_box:SetParent(nil)
    end
    self:SetVisible(false)
end
