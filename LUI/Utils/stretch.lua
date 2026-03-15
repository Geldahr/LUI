import "Turbine.UI"

local background_base_size = {}

local function _is_valid_size(width, height)
    return type(width) == "number" and type(height) == "number" and width >= 1 and height >= 1
end

_G.get_background_base_size = function(background)
    if background == nil then
        return nil, nil
    end

    local cached = background_base_size[background]
    if cached ~= nil then
        return cached.width, cached.height
    end

    local probe = Turbine.UI.Control()
    probe:SetMouseVisible(false)
    probe:SetBackground(background)
    if probe.SetStretchMode == nil then
        return nil, nil
    end

    probe:SetStretchMode(2)

    local width, height = probe:GetSize()
    if _is_valid_size(width, height) ~= true then
        return nil, nil
    end

    background_base_size[background] = {
        width = width,
        height = height,
    }

    return width, height
end

_G.prepare_background_stretch_mode_1 = function(control, background)
    if control == nil or control.SetStretchMode == nil or control.SetSize == nil then
        return nil, nil
    end

    local bg = background
    if bg == nil and control.GetBackground ~= nil then
        bg = control:GetBackground()
    end
    if bg == nil then
        return nil, nil
    end

    if background ~= nil and control.SetBackground ~= nil then
        control:SetBackground(background)
    end

    local left, top = 0, 0
    if control.GetPosition ~= nil then
        left, top = control:GetPosition()
    end

    local target_w, target_h = nil, nil
    if control.GetSize ~= nil then
        target_w, target_h = control:GetSize()
        if _is_valid_size(target_w, target_h) ~= true then
            target_w = nil
            target_h = nil
        end
    end

    local base_w, base_h = get_background_base_size(bg)
    if _is_valid_size(base_w, base_h) ~= true then
        return nil, nil
    end

    control:SetSize(base_w, base_h)
    control:SetStretchMode(1)

    if target_w ~= nil and target_h ~= nil then
        control:SetSize(target_w, target_h)
    end

    if control.SetPosition ~= nil then
        control:SetPosition(left, top)
    end

    return base_w, base_h
end

_G.refresh_stretch_mode_1_from_current_content = function(control)
    if control == nil or control.SetStretchMode == nil or control.GetSize == nil or control.SetSize == nil then
        return nil, nil
    end

    local left, top = 0, 0
    if control.GetPosition ~= nil then
        left, top = control:GetPosition()
    end

    local target_w, target_h = control:GetSize()
    if _is_valid_size(target_w, target_h) ~= true then
        target_w = nil
        target_h = nil
    end

    control:SetStretchMode(2)

    local base_w, base_h = control:GetSize()
    if _is_valid_size(base_w, base_h) ~= true then
        if target_w ~= nil and target_h ~= nil then
            control:SetSize(target_w, target_h)
        end
        if control.SetPosition ~= nil then
            control:SetPosition(left, top)
        end
        return nil, nil
    end

    control:SetSize(base_w, base_h)
    control:SetStretchMode(1)

    if target_w ~= nil and target_h ~= nil then
        control:SetSize(target_w, target_h)
    end

    if control.SetPosition ~= nil then
        control:SetPosition(left, top)
    end

    return base_w, base_h
end
