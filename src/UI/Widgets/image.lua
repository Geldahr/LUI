import "Turbine.UI"

---@class Image : Turbine.UI.Control
Image = class(Turbine.UI.Control)

local _base_size_cache = {}

local function _round_size(value)
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then
        return nil
    end
    return math.floor(value + 0.5)
end

local function _is_valid_size(width, height)
    return type(width) == "number" and type(height) == "number" and width >= 1 and height >= 1
end

function Image.get_base_size(target)
    if type(target) == "table" then
        local original_w = tonumber(target.original_w)
        local original_h = tonumber(target.original_h)
        if _is_valid_size(original_w, original_h) == true then
            return original_w, original_h
        end
        if target.GetBackground ~= nil then
            target = target:GetBackground()
        else
            target = nil
        end
    end

    if target == nil then
        return nil, nil
    end

    local cached = _base_size_cache[target]
    if cached ~= nil then
        return cached.width, cached.height
    end

    local probe = Turbine.UI.Control()
    probe:SetMouseVisible(false)
    probe:SetBackground(target)
    if probe.SetStretchMode == nil then
        return nil, nil
    end

    probe:SetStretchMode(2)
    local width, height = probe:GetSize()
    if _is_valid_size(width, height) ~= true then
        return nil, nil
    end

    _base_size_cache[target] = {
        width = width,
        height = height,
    }

    return width, height
end

function Image.get_fitted_size(target, max_w, max_h)
    max_w = _round_size(max_w)
    max_h = _round_size(max_h)
    if max_w == nil and max_h == nil then
        return nil, nil
    end
    if max_h == nil then
        max_h = max_w
    elseif max_w == nil then
        max_w = max_h
    end

    if max_w <= 0 or max_h <= 0 then
        return 0, 0
    end

    local base_w, base_h = Image.get_base_size(target)
    if _is_valid_size(base_w, base_h) ~= true then
        local size = math.min(max_w, max_h)
        return size, size
    end

    local scale = math.min(max_w / base_w, max_h / base_h)
    return math.floor((base_w * scale) + 0.5), math.floor((base_h * scale) + 0.5)
end

function Image.get_size_for_height(target, height)
    height = _round_size(height)
    if height == nil or height <= 0 then
        return 0, 0
    end

    local base_w, base_h = Image.get_base_size(target)
    if _is_valid_size(base_w, base_h) ~= true then
        return height, height
    end

    local scale = height / base_h
    return math.floor((base_w * scale) + 0.5), height
end

function Image:Constructor(icon, w, h)
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)
    self:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self:SetBackColorBlendMode(Turbine.UI.BlendMode.Multiply)
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0))
    self._requested_w = nil
    self._requested_h = nil

    if icon ~= nil then
        self:set_icon(icon, w, h)
    elseif w ~= nil then
        self:set_size(w, h)
    end
end

function Image:set_size(w, h)
    w = _round_size(w)
    h = _round_size(h)
    if w == nil then
        return
    end

    self._requested_w = w
    self._requested_h = h

    if h ~= nil then
        if h < 0 then
            h = 0
        end
        if w < 0 then
            w = 0
        end
        Turbine.UI.Control.SetSize(self, w, h)
        return
    end

    if w < 0 then
        w = 0
    end
    local fit_w, fit_h = Image.get_fitted_size(self, w, w)
    Turbine.UI.Control.SetSize(self, fit_w, fit_h)
end

function Image:SetSize(w, h)
    self:set_size(w, h)
end

function Image:set_icon(icon, w, h)
    if icon == nil then
        self.original_w = nil
        self.original_h = nil
        self:SetBackground(nil)
        if w ~= nil then
            self:set_size(w, h)
        elseif self._requested_w ~= nil then
            self:set_size(self._requested_w, self._requested_h)
        end
        return
    end

    self:SetVisible(true)
    Turbine.UI.Control.SetSize(self, 0, 0)
    self:SetBackground(icon)
    self:SetStretchMode(2)
    self.original_w, self.original_h = self:GetSize()

    Turbine.UI.Control.SetSize(self, self.original_w, self.original_h)
    self:SetStretchMode(1)

    if w ~= nil then
        self:set_size(w, h)
    elseif self._requested_w ~= nil then
        self:set_size(self._requested_w, self._requested_h)
    end
end
