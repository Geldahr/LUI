import "LUI.src.StatusBar.api_command_parser"

local Parser = _G.STATUS_BAR_API_COMMAND_PARSER
local PENDING_STATUS_BAR_API_ITEMS = {}
local status_bar_api_chat_callback = nil

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

local function flush_pending_items()
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

local function push_item(spec)
    if _G.STATUS_BAR ~= nil and _G.STATUS_BAR_COMMON ~= nil and _G.STATUS_BAR_COMMON.register_status_bar_api_item ~= nil then
        local _, err = _register_status_bar_api_item(spec)
        if err ~= nil then
            _log_status_bar_api_chat("Status bar push failed: " .. tostring(err))
        end
        return
    end

    PENDING_STATUS_BAR_API_ITEMS[#PENDING_STATUS_BAR_API_ITEMS + 1] = spec
    flush_pending_items()
end

local function handle_chat_message(args)
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

    push_item(spec)
end

function _G.LUI_STATUS_BAR_API_FLUSH_PENDING_ITEMS()
    flush_pending_items()
end

function _G.LUI_STATUS_BAR_API_INSTALL_CHAT_CALLBACK()
    if status_bar_api_chat_callback ~= nil then
        return
    end

    status_bar_api_chat_callback = add_callback(Turbine.Chat, "Received", function(_, args)
        handle_chat_message(args)
    end)
end

function _G.LUI_STATUS_BAR_API_UNINSTALL_CHAT_CALLBACK()
    if status_bar_api_chat_callback == nil then
        return
    end

    remove_callback(Turbine.Chat, "Received", status_bar_api_chat_callback)
    status_bar_api_chat_callback = nil
end
