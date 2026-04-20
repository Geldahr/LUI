local function _scaled_int(value)
    return math.floor((value * _G.settings.global.scale) + 0.5)
end

function ConfigWindow:get_geometry_state()
    if _G.loaded_settings == nil then
        return nil
    end

    if _G.loaded_settings.global == nil then
        _G.loaded_settings.global = {}
    end

    if _G.loaded_settings.global.config_window == nil then
        _G.loaded_settings.global.config_window = {}
    end

    return _G.loaded_settings.global.config_window
end

function ConfigWindow:update_saved_geometry()
    local state = self:get_geometry_state()
    if state == nil then
        return
    end

    self:capture_window_geometry(state)
end

function ConfigWindow:persist_geometry()
    self:update_saved_geometry()
end

function ConfigWindow:apply_saved_geometry()
    local default_width = _scaled_int(459)
    local default_height = _scaled_int(385)

    local display_width, display_height = Turbine.UI.Display.GetSize()

    local state = nil
    if _G.loaded_settings ~= nil then
        if _G.loaded_settings.global ~= nil then
            state = _G.loaded_settings.global.config_window
        end
    end

    local width = default_width
    local height = default_height
    if state ~= nil and type(state.width) == "number" and type(state.height) == "number" then
        width = state.width
        height = state.height
    end

    if width > display_width then width = display_width end
    if height > display_height then height = display_height end
    if width < _scaled_int(222) then width = _scaled_int(222) end
    if height < _scaled_int(185) then height = _scaled_int(185) end

    self:SetSize(width, height)

    local left = math.floor((display_width - width) / 2)
    local top = math.floor((display_height - height) / 2)
    if state ~= nil and type(state.left) == "number" and type(state.top) == "number" then
        left = state.left
        top = state.top
    end

    if left < 0 then left = 0 end
    if top < 0 then top = 0 end
    if left > (display_width - _scaled_int(37)) then
        left = display_width - _scaled_int(37)
    end
    if top > (display_height - _scaled_int(37)) then
        top = display_height - _scaled_int(37)
    end

    self:SetPosition(left, top)

    self:apply_maximize_state(state)
    self:update_saved_geometry()
end
