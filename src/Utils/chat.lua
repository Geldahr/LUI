local Utils = _G.LUI.Utils

function Utils.lui_chat_type_names(chat_type)
    if type(Turbine.ChatType) ~= "table" then
        return tostring(chat_type)
    end

    local names = {}
    for name, value in pairs(Turbine.ChatType) do
        if value == chat_type then
            names[#names + 1] = tostring(name)
        end
    end

    if #names == 0 then
        return tostring(chat_type)
    end

    table.sort(names)
    return table.concat(names, ", ")
end
