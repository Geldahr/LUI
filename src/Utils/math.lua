local Utils = _G.LUI.Utils

function Utils.round(val, decimal)
    if (decimal) then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end
