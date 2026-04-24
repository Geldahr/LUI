_G.LUI_POPUP_STATE = _G.LUI_POPUP_STATE or {}

local PopupState = _G.LUI_POPUP_STATE

function PopupState.close_dropdowns()
    if LuiDropdown ~= nil and LuiDropdown._active ~= nil and LuiDropdown._active.Close ~= nil then
        LuiDropdown._active:Close()
    end
    if LuiCheckDropdown ~= nil and LuiCheckDropdown._active ~= nil and LuiCheckDropdown._active.Close ~= nil then
        LuiCheckDropdown._active:Close()
    end
end

function PopupState.close_menus()
    if LuiMenu ~= nil and LuiMenu._active_root ~= nil and LuiMenu._active_root.close ~= nil then
        LuiMenu._active_root:close()
    end
end

function PopupState.close_all()
    PopupState.close_dropdowns()
    PopupState.close_menus()
end
