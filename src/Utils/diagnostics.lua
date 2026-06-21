local Runtime = _G.LUI.Runtime
local Diagnostic = Runtime.Diagnostics
Runtime.Diagnostic = Diagnostic

local MAX_LOG_LINES = 1000
local DIAGNOSTIC_LOG_DATA_KEY = "LUI_DIAGNOSTIC_LOG"

local Log = {}
Diagnostic.Log = Log
Runtime.Log = Log

Diagnostic.lines = {}

local function _timestamp()
    if os ~= nil and os.date ~= nil then
        return os.date("%Y-%m-%d %H:%M:%S")
    end

    return string.format("%.3f", Turbine.Engine.GetGameTime())
end

local function _normalize_level(level)
    local normalized = string.upper(tostring(level))
    if normalized == "WARNING" then
        return "WARN"
    end

    if normalized ~= "WARN" and normalized ~= "ERROR" and normalized ~= "INFO" then
        return "INFO"
    end

    return normalized
end

local function _message_from_args(level_or_data, has_message, message)
    if has_message then
        return tostring(message)
    end

    if type(level_or_data) == "table" then
        if level_or_data.message ~= nil then
            return tostring(level_or_data.message)
        end

        if level_or_data.text ~= nil then
            return tostring(level_or_data.text)
        end
    end

    return tostring(level_or_data)
end

local function _level_from_args(level_or_data, has_message)
    if has_message then
        return level_or_data
    end

    if type(level_or_data) == "table" and level_or_data.level ~= nil then
        return level_or_data.level
    end

    return "INFO"
end

function Diagnostic.push(level_or_data, ...)
    local lines = Diagnostic.lines
    local has_message = select("#", ...) > 0
    local message = select(1, ...)
    local line = "[" .. _normalize_level(_level_from_args(level_or_data, has_message)) .. "] [" .. _timestamp() .. "] - " ..
        _message_from_args(level_or_data, has_message, message)

    lines[#lines + 1] = line
    while #lines > MAX_LOG_LINES do
        table.remove(lines, 1)
    end
end

function Diagnostic.save()
    Turbine.PluginData.Save(Turbine.DataScope.Character, DIAGNOSTIC_LOG_DATA_KEY, {
        log = Diagnostic.lines,
    })
end

function Log.warn(message)
    Diagnostic.push("WARN", message)
end

function Log.error(message)
    Diagnostic.push("ERROR", message)
end

function Log.info(message)
    Diagnostic.push("INFO", message)
end
