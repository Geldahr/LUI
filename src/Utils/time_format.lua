local Utils = _G.LUI.Utils

local function _format_m_ss(total_seconds)
    local total = math.floor(total_seconds)
    local minutes = math.floor(total / 60)
    local seconds = total - (minutes * 60)
    return string.format("%d:%02d", minutes, seconds)
end

local function lui_format_timeout(seconds)
    if seconds <= 0 then
        return "0.0s"
    end
    if seconds >= 60 then
        return _format_m_ss(seconds)
    end
    if seconds < 10 then
        return string.format("%.1fs", seconds)
    end
    return string.format("%ds", math.floor(seconds))
end
Utils.lui_format_timeout = lui_format_timeout

local function lui_format_timeout_seconds(seconds)
    if seconds <= 0 then
        return "0s"
    end

    local total = math.floor(seconds)
    if total >= 60 then
        return _format_m_ss(total)
    end
    return tostring(total) .. "s"
end
Utils.lui_format_timeout_seconds = lui_format_timeout_seconds
