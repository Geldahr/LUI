import "Turbine.UI"
import "Turbine.UI.Lotro"
import "LUI.src.UI.Widgets.image"
import "LUI.src.UI.Widgets.label"

local BASE_BUTTON_W = 89
local BASE_BUTTON_H = 21
local BASE_FONT_SIZE = 12
local BASE_ICON_SIZE = 12
local BASE_BORDER_THICKNESS = 1.5
local ICON_POSITION_LEFT = "left"
local ICON_POSITION_RIGHT = "right"

local function _scaled_size(scale, value)
    return value * scale
end

local function _scaled_int(scale, value)
    return math.floor(_scaled_size(scale, value) + 0.5)
end

local function _scaled_font(scale, name, size)
    local font = FONT_TO_LOTRO(name, _scaled_size(scale, size))
    if font == nil then
        error("Missing scaled font: " .. tostring(name) .. " " .. tostring(_scaled_size(scale, size)))
    end
    return font
end

---@class LuiButton : Turbine.UI.Control
LuiButton = class(Turbine.UI.Control)

LuiButton.icon_position = {
    LEFT = ICON_POSITION_LEFT,
    RIGHT = ICON_POSITION_RIGHT,
}

local function _normalize_icon_position(position)
    if position == ICON_POSITION_LEFT or position == LuiButton.icon_position.LEFT then
        return ICON_POSITION_LEFT
    end
    return ICON_POSITION_RIGHT
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------

function LuiButton:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.Click = nil

    self._scale = 1
    self._uses_default_size = true
    self._uses_default_font = true

    self._enabled = true
    self._active = false
    self._hover = false
    self._pressed = false

    self._border_thickness = BASE_BORDER_THICKNESS
    self._border_color = Turbine.UI.Color(1, 0.35, 0.40, 0.50)

    self._back_normal = Turbine.UI.Color(1, 0.15, 0.15, 0.15)
    self._back_hover = Turbine.UI.Color(1, 0.18, 0.24, 0.34)
    self._back_pressed = Turbine.UI.Color(1, 0.10, 0.14, 0.20)
    self._back_active = Turbine.UI.Color(1, 0.18, 0.30, 0.46)
    self._back_disabled = Turbine.UI.Color(1, 0.10, 0.10, 0.10)

    self._text_normal = Turbine.UI.Color(1, 1, 1, 1)
    self._text_hover = Turbine.UI.Color(1, 1, 1, 1)
    self._text_pressed = Turbine.UI.Color(1, 1, 1, 1)
    self._text_active = Turbine.UI.Color(1, 1, 1, 1)
    self._text_disabled = Turbine.UI.Color(0.55, 0.85, 0.85, 0.85)

    Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_BUTTON_W), _scaled_int(self._scale, BASE_BUTTON_H))
    self:SetMouseVisible(true)

    local initial_border = math.max(0, _scaled_int(self._scale, self._border_thickness))

    self._inner = Turbine.UI.Control()
    self._inner:SetParent(self)
    self._inner:SetMouseVisible(false)
    self._inner:SetPosition(initial_border, initial_border)
    self._inner:SetSize(
        math.max(0, self:GetWidth() - (2 * initial_border)),
        math.max(0, self:GetHeight() - (2 * initial_border))
    )

    self._label = LuiLabel()
    self._label:SetParent(self._inner)
    self._label:SetMouseVisible(false)
    self._label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._label:SetSize(self._inner:GetSize())

    self._right_label = LuiLabel()
    self._right_label:SetParent(self._inner)
    self._right_label:SetMouseVisible(false)
    self._right_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._right_label:SetVisible(false)
    self._right_text = nil
    self._right_width = 0

    self._icon = Image()
    self._icon:SetParent(self._inner)
    self._icon:SetVisible(false)
    self._icon:SetZOrder(6)
    self._icon_normal = nil
    self._icon_hover = nil
    self._icon_pressed = nil
    self._icon_pressed_hover = nil
    self._icon_disabled = nil
    self._icon_width = 0
    self._icon_position = ICON_POSITION_RIGHT

    self.SizeChanged = function()
        self:_layout()
    end

    self.MouseEnter = function()
        if self._enabled ~= true then return end
        self._hover = true
        self:_update_visual_state()
    end

    self.MouseLeave = function()
        self._hover = false
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseDown = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        self._pressed = true
        self:_update_visual_state()
    end

    self.MouseUp = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        self._pressed = false
        self:_update_visual_state()
    end

    self.MouseClick = function(_, args)
        if self._enabled ~= true then return end
        if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then return end
        if type(self.Click) == "function" then
            self:Click()
        end
    end

    self:_apply_default_font()
    self:_update_visual_state()
end

---------------------------------------------------------------------
-- Destructor
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Public functions
---------------------------------------------------------------------

function LuiButton:set_border_thickness(px)
    if type(px) ~= "number" then
        px = tonumber(px)
    end
    if px == nil then
        return
    end
    if px < 0 then px = 0 end
    self._border_thickness = px
    self:_layout()
end

function LuiButton:SetBorderThickness(px)
    self:set_border_thickness(px)
end

function LuiButton:set_border_color(color)
    if color == nil then return end
    self._border_color = color
    self:_update_visual_state()
end

function LuiButton:SetBorderColor(color)
    self:set_border_color(color)
end

function LuiButton:set_right_text(text, width)
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil then
        width = 0
    end
    if width < 0 then width = 0 end

    self._right_text = text
    self._right_width = math.floor(width + 0.5)
    self._icon_width = 0
    self:_layout()
end

function LuiButton:SetRightText(text, width)
    self:set_right_text(text, width)
end

function LuiButton:set_icon(normal, hover, pressed, pressed_hover, disabled, width, position)
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil then
        width = 0
    end
    if width < 0 then width = 0 end

    self._icon_normal = normal
    self._icon_hover = hover
    self._icon_pressed = pressed
    self._icon_pressed_hover = pressed_hover
    self._icon_disabled = disabled
    self._icon_width = math.floor(width + 0.5)
    self._icon_position = _normalize_icon_position(position or self._icon_position)
    self._right_width = 0
    self:_layout()
end

function LuiButton:SetIcon(normal, hover, pressed, pressed_hover, disabled, width, position)
    self:set_icon(normal, hover, pressed, pressed_hover, disabled, width, position)
end

function LuiButton:set_icon_position(position)
    self._icon_position = _normalize_icon_position(position)
    self:_layout()
end

function LuiButton:SetIconPosition(position)
    self:set_icon_position(position)
end

function LuiButton:set_right_icon(normal, hover, pressed, pressed_hover, disabled, width)
    self:set_icon(normal, hover, pressed, pressed_hover, disabled, width, ICON_POSITION_RIGHT)
end

function LuiButton:SetRightIcon(normal, hover, pressed, pressed_hover, disabled, width)
    self:set_right_icon(normal, hover, pressed, pressed_hover, disabled, width)
end

function LuiButton:set_active(active)
    self._active = active == true
    self:_update_visual_state()
end

function LuiButton:SetActive(active)
    self:set_active(active)
end

function LuiButton:is_active()
    return self._active == true
end

function LuiButton:set_enabled(enabled)
    self._enabled = enabled == true
    if self._enabled ~= true then
        self._hover = false
        self._pressed = false
    end
    Turbine.UI.Control.SetEnabled(self, self._enabled)
    self:_update_visual_state()
end

function LuiButton:SetEnabled(enabled)
    self:set_enabled(enabled)
end

function LuiButton:set_text(text)
    if self._label ~= nil then
        self._label:SetText(text or "")
    end
    self:_layout()
end

function LuiButton:SetText(text)
    self:set_text(text)
end

function LuiButton:GetText()
    if self._label == nil then return "" end
    return self._label:GetText()
end

function LuiButton:set_font(font)
    if font == nil then return end
    self._uses_default_font = false
    if self._label ~= nil then
        self._label:SetFont(font)
    end
    if self._right_label ~= nil then
        self._right_label:SetFont(font)
    end
end

function LuiButton:SetFont(font)
    self:set_font(font)
end

function LuiButton:set_scale(scale)
    self._scale = scale

    if self._uses_default_font == true then
        self:_apply_default_font()
    end

    if self._uses_default_size == true then
        Turbine.UI.Control.SetSize(self, _scaled_int(self._scale, BASE_BUTTON_W), _scaled_int(self._scale, BASE_BUTTON_H))
    end

    self:_layout()
end

function LuiButton:SetScale(scale)
    self:set_scale(scale)
end

function LuiButton:set_text_alignment(alignment)
    if self._label ~= nil and alignment ~= nil then
        self._label:SetTextAlignment(alignment)
    end
end

function LuiButton:SetTextAlignment(alignment)
    self:set_text_alignment(alignment)
end

function LuiButton:set_back_color(color)
    if color ~= nil then
        self._back_normal = color; self:_update_visual_state()
    end
end

function LuiButton:set_hover_back_color(color)
    if color ~= nil then
        self._back_hover = color; self:_update_visual_state()
    end
end

function LuiButton:set_pressed_back_color(color)
    if color ~= nil then
        self._back_pressed = color; self:_update_visual_state()
    end
end

function LuiButton:set_active_back_color(color)
    if color ~= nil then
        self._back_active = color; self:_update_visual_state()
    end
end

function LuiButton:set_disabled_back_color(color)
    if color ~= nil then
        self._back_disabled = color; self:_update_visual_state()
    end
end

function LuiButton:set_text_color(color)
    if color ~= nil then
        self._text_normal = color; self:_update_visual_state()
    end
end

function LuiButton:set_hover_text_color(color)
    if color ~= nil then
        self._text_hover = color; self:_update_visual_state()
    end
end

function LuiButton:set_pressed_text_color(color)
    if color ~= nil then
        self._text_pressed = color; self:_update_visual_state()
    end
end

function LuiButton:set_active_text_color(color)
    if color ~= nil then
        self._text_active = color; self:_update_visual_state()
    end
end

function LuiButton:set_disabled_text_color(color)
    if color ~= nil then
        self._text_disabled = color; self:_update_visual_state()
    end
end

---------------------------------------------------------------------
-- Private functions
---------------------------------------------------------------------

function LuiButton:_current_back_color()
    if self._enabled ~= true then return self._back_disabled end
    if self._pressed == true then return self._back_pressed end
    if self._active == true then return self._back_active end
    if self._hover == true then return self._back_hover end
    return self._back_normal
end

function LuiButton:_current_text_color()
    if self._enabled ~= true then return self._text_disabled end
    if self._pressed == true then return self._text_pressed end
    if self._active == true then return self._text_active end
    if self._hover == true then return self._text_hover end
    return self._text_normal
end

function LuiButton:_current_icon()
    if self._enabled ~= true then
        return self._icon_disabled or self._icon_normal
    end
    if self._pressed == true then
        if self._hover == true then
            return self._icon_pressed_hover or self._icon_pressed or self._icon_hover or
                self._icon_normal
        end
        return self._icon_pressed or self._icon_normal
    end
    if self._hover == true then
        return self._icon_hover or self._icon_normal
    end
    return self._icon_normal
end

function LuiButton:_apply_default_font()
    local font = _scaled_font(self._scale, "Verdana", BASE_FONT_SIZE)
    if self._label ~= nil then
        self._label:SetFont(font)
    end
    if self._right_label ~= nil then
        self._right_label:SetFont(font)
    end
end

function LuiButton:_update_visual_state()
    self:SetBackColor(self._border_color)
    if self._inner ~= nil then
        self._inner:SetBackColor(self:_current_back_color())
    end
    if self._label ~= nil then
        self._label:SetForeColor(self:_current_text_color())
    end
    if self._right_label ~= nil then
        self._right_label:SetForeColor(self:_current_text_color())
    end
    if self._icon ~= nil and self._icon:IsVisible() then
        local icon_w, icon_h = self._icon:GetSize()
        self._icon:set_icon(self:_current_icon(), icon_w, icon_h)
    end
end

function LuiButton:_layout()
    local w, h = self:GetSize()
    local t = math.max(0, _scaled_int(self._scale, self._border_thickness or BASE_BORDER_THICKNESS))
    if t < 0 then t = 0 end

    if self._inner ~= nil then
        self._inner:SetPosition(t, t)
        self._inner:SetSize(math.max(0, w - (2 * t)), math.max(0, h - (2 * t)))
    end

    local inner_w = self._inner ~= nil and self._inner:GetWidth() or w
    local inner_h = self._inner ~= nil and self._inner:GetHeight() or h

    local right_text_w = _scaled_int(self._scale, self._right_width or 0)
    if right_text_w < 0 then right_text_w = 0 end
    if right_text_w > inner_w then right_text_w = inner_w end

    local use_icon = (self._icon_width or 0) > 0 and self._icon_normal ~= nil
    local icon_slot_w = _scaled_int(self._scale, self._icon_width or 0)
    if icon_slot_w < 0 then icon_slot_w = 0 end
    if icon_slot_w > inner_w then icon_slot_w = inner_w end

    local label_text = self._label ~= nil and tostring(self._label:GetText() or "") or ""
    local has_text = label_text ~= ""

    if self._right_label ~= nil then
        if right_text_w > 0 and use_icon ~= true then
            self._right_label:SetVisible(true)
            self._right_label:SetText(tostring(self._right_text or ""))
            self._right_label:SetPosition(inner_w - right_text_w, 0)
            self._right_label:SetSize(right_text_w, inner_h)
        else
            self._right_label:SetVisible(false)
        end
    end

    if self._icon ~= nil then
        if use_icon == true then
            self._icon:SetVisible(true)
            local icon_size = math.min(_scaled_int(self._scale, BASE_ICON_SIZE), inner_h)
            if icon_slot_w > 0 then
                icon_size = math.min(icon_size, icon_slot_w)
            end

            local py = math.floor((inner_h - icon_size) / 2)
            local px

            if has_text ~= true then
                px = math.floor((inner_w - icon_size) / 2)
            elseif self._icon_position == ICON_POSITION_LEFT then
                px = math.floor((icon_slot_w - icon_size) / 2)
            else
                px = inner_w - icon_slot_w + math.floor((icon_slot_w - icon_size) / 2)
            end

            self._icon:SetPosition(px, py)
            self._icon:set_icon(self:_current_icon(), icon_size, icon_size)
        else
            self._icon:SetVisible(false)
        end
    end

    if self._label ~= nil then
        local label_x = 0
        local label_w = inner_w

        if use_icon == true and has_text == true then
            if self._icon_position == ICON_POSITION_LEFT then
                label_x = icon_slot_w
                label_w = inner_w - icon_slot_w
            else
                label_w = inner_w - icon_slot_w
            end
        elseif right_text_w > 0 then
            label_w = inner_w - right_text_w
        end

        if label_w < 0 then label_w = 0 end
        self._label:SetPosition(label_x, 0)
        self._label:SetSize(label_w, inner_h)
    end

    self:_update_visual_state()
end

function LuiButton:SetSize(w, h)
    self._uses_default_size = false
    Turbine.UI.Control.SetSize(self, w, h)
end
