local BASE = ...

local handle = {}
--handle.__index = handle

function handle.__newindex(t, k, v)
    -- Just ignore setting
end

function handle.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(handle, handle)
