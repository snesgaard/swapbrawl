function Sprite:get_color_stack()
    if not self.color_stack then
        self.color_stack = dict()
    end
    return self.color_stack
end

function Sprite:compute_color()
    local c = color.create(1, 1, 1, 1)
    for _, c2 in pairs(self.color_stack) do
        c = c * c2
    end
    return c
end

function Sprite:update_color()
    self.graph:data("color").color = self:compute_color()
    return self
end

function Sprite:death()
    local cs = self:get_color_stack()
    cs.death = color.create(1, 1, 1, 1)

    local function animate_death()
        local t = tween(0.2, cs.death, color.create(1, 0.2, 0.1, 1))
            :call(function() self:update_color() end)
        event:wait(t, "finish")
        local t = tween(0.2, cs.death, color.create(0, 0, 0, 0))
            :call(function() self:update_color() end)
        event:wait(t, "finish")
    end

    self:fork(animate_death)
end

function Sprite:alive()
    local cs = self:get_color_stack()
    cs.death = cs.death or color.create(1, 1, 1, 1)
    tween(0.4, cs.death, color.create(1, 1, 1, 1))
        :call(function() self:update_color() end)
end

local TestSprite = {}

function TestSprite:create()
end

return TestSprite
