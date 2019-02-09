local BASE = ...

local handle = {}
--handle.__index = handle

function handle.__newindex(t, k, v)
    -- Just ignore setting
end

function handle.__index(t, k)
    return require(BASE .. "." .. k)
end

function draw_holder(x, y, w, h)
    local part = get_atlas("art/ui"):get_animation("holderA")
    part:draw(x - 2, y - 2, 0, 2, 2)
    part:draw(x + w + 2, y - 2, math.pi * 0.5, 2, 2)
    part:draw(x + w + 2, y + 2 + h, math.pi, 2, 2)
    part:draw(x - 2, y + 2 + h, math.pi * 1.5, 2, 2)
end

return setmetatable(handle, handle)
