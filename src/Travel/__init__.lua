Travel = Travel or {}

import "LUI.src.Travel.travel_data"
import "LUI.src.Travel.travel_store"
import "LUI.src.Travel.travel_window"

local _shared_store = nil

local function _is_enabled()
    return _G.settings.travel.enabled == true
end

function Travel.is_enabled()
    return _is_enabled()
end

function Travel.get_shared_store()
    if _G.LUI_IS_UNLOADING == true then
        return nil
    end
    if _is_enabled() ~= true then
        error("Travel is disabled in settings.")
    end

    if _shared_store == nil then
        _shared_store = TravelStore()
        _G.TRAVEL_STORE = _shared_store
    end

    return _shared_store
end

function Travel.destroy_shared_store()
    if _shared_store ~= nil then
        _shared_store:destroy()
    end
    _shared_store = nil
    _G.TRAVEL_STORE = nil
end

Travel.TravelStore = TravelStore
Travel.TravelWindow = TravelWindow
