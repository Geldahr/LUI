import "LUI.src.StatusBar.api_command_parser"

_G.LUI_PENDING_STATUS_BAR_API_ITEMS = _G.LUI_PENDING_STATUS_BAR_API_ITEMS or {}
_G.LUI_STATUS_BAR_API_CHAT = _G.LUI_STATUS_BAR_API_CHAT or {}

local Chat = _G.LUI_STATUS_BAR_API_CHAT
local Parser = _G.STATUS_BAR_API_COMMAND_PARSER
local PENDING_STATUS_BAR_API_ITEMS = _G.LUI_PENDING_STATUS_BAR_API_ITEMS

local function _log_status_bar_api_chat(message)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#33C1FF>LUI StatusBar</rgb>: " .. tostring(message or ""))
    end
end

local function _register_status_bar_api_item(spec)
    if _G.STATUS_BAR_COMMON == nil or _G.STATUS_BAR_COMMON.register_status_bar_api_item == nil then
        return nil, "Status bar API is not available yet."
    end

    return _G.STATUS_BAR_COMMON.register_status_bar_api_item(spec)
end

function Chat.flush_pending_items()
    if _G.STATUS_BAR == nil or _G.STATUS_BAR_COMMON == nil or _G.STATUS_BAR_COMMON.register_status_bar_api_item == nil then
        return
    end
    if #PENDING_STATUS_BAR_API_ITEMS == 0 then
        return
    end

    while #PENDING_STATUS_BAR_API_ITEMS > 0 do
        local spec = table.remove(PENDING_STATUS_BAR_API_ITEMS, 1)
        local _, err = _register_status_bar_api_item(spec)
        if err ~= nil then
            _log_status_bar_api_chat("Status bar push failed: " .. tostring(err))
        end
    end
end

function Chat.push_item(spec)
    if _G.STATUS_BAR ~= nil and _G.STATUS_BAR_COMMON ~= nil and _G.STATUS_BAR_COMMON.register_status_bar_api_item ~= nil then
        local _, err = _register_status_bar_api_item(spec)
        if err ~= nil then
            _log_status_bar_api_chat("Status bar push failed: " .. tostring(err))
        end
        return
    end

    PENDING_STATUS_BAR_API_ITEMS[#PENDING_STATUS_BAR_API_ITEMS + 1] = spec
    Chat.flush_pending_items()
end

function Chat.handle_chat_message(args)
    if args.ChatType ~= Turbine.ChatType.Standard then
        return
    end

    local message = Parser.strip_chat_timestamp(args ~= nil and args.Message or nil)
    local command_text = message:match("^/[Ll][Uu][Ii]%s+(.+)$")
    if command_text == nil then
        return
    end

    local list = Parser.tokenize_command_arguments(command_text)
    local start_index = Parser.get_status_bar_api_start_index(list)
    if start_index == nil then
        return
    end

    local spec, err = Parser.parse_status_bar_api_spec(list, start_index)
    if spec == nil then
        _log_status_bar_api_chat("Ignored invalid /lui " .. tostring(command_text) .. ": " .. tostring(err))
        return
    end

    Chat.push_item(spec)
end

function Chat.install_callback()
    if _G.LUI_STATUS_BAR_API_CHAT_CALLBACK ~= nil then
        return
    end

    _G.LUI_STATUS_BAR_API_CHAT_CALLBACK = add_callback(Turbine.Chat, "Received", function(_, args)
        Chat.handle_chat_message(args)
    end)
end

function Chat.uninstall_callback()
    if _G.LUI_STATUS_BAR_API_CHAT_CALLBACK == nil then
        return
    end

    remove_callback(Turbine.Chat, "Received", _G.LUI_STATUS_BAR_API_CHAT_CALLBACK)
    _G.LUI_STATUS_BAR_API_CHAT_CALLBACK = nil
end
