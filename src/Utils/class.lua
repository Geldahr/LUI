local Core = _G.LUI.Core

function Core.class(parent)
    local cls = {}
    cls.__index = cls
    cls.super = parent

    -- class(...) creates an instance and calls :Constructor(...)
    setmetatable(cls, {
        __index = parent,                           -- inheritance: methods missing in cls are looked up in parent
        __call = function(class_tbl, ...)
            local obj = setmetatable({}, class_tbl) -- instance metatable is the class
            local ctor = obj.Constructor            -- resolved via __index chain
            if ctor then
                ctor(obj, ...)
            end
            return obj
        end
    })

    return cls
end
