local Runtime = _G.LUI.Runtime
local Diagnostic = Runtime.Diagnostics
Runtime.Diagnostic = Diagnostic

local MAX_LOG_LINES = 1000
local DIAGNOSTIC_LOG_DATA_KEY = "LUI_DIAGNOSTIC_LOG"

Diagnostic.Level = {
    DISABLED = 0,
    ERROR = 1,
    WARN = 2,
    INFO = 3,
}

local Log = {}
Diagnostic.Log = Log
Runtime.Log = Log

Diagnostic.lines = {}
Diagnostic.level = Diagnostic.Level.INFO

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

    return normalized
end

local function _level_value(level)
    if type(level) == "number" then
        if level < Diagnostic.Level.DISABLED or level > Diagnostic.Level.INFO or math.floor(level) ~= level then
            error("Invalid diagnostic level: " .. tostring(level))
        end

        return level
    end

    local normalized = _normalize_level(level)
    local value = Diagnostic.Level[normalized]
    if value == nil then
        error("Invalid diagnostic level: " .. tostring(level))
    end

    return value
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
    local level = _normalize_level(_level_from_args(level_or_data, has_message))
    if _level_value(level) <= Diagnostic.level then
        local line = "[" .. level .. "] [" .. _timestamp() .. "] - " ..
            _message_from_args(level_or_data, has_message, message)

        lines[#lines + 1] = line
        while #lines > MAX_LOG_LINES do
            table.remove(lines, 1)
        end
    end
end

function Diagnostic.set_level(level)
    Diagnostic.level = _level_value(level)
end

function Diagnostic.configure(config)
    if config.enabled == false then
        Diagnostic.set_level("DISABLED")
    elseif config.level ~= nil then
        Diagnostic.set_level(config.level)
    elseif config.enabled == true and Diagnostic.level == Diagnostic.Level.DISABLED then
        Diagnostic.set_level("INFO")
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
