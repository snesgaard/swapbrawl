local drops = {}

drops.image = gfx.prerender(12, 12, function(w, h)
    gfx.ellipse("fill", w / 2, h / 2, w / 2, h / 2)
end)

function drops:create(color)
    local r, g, b = unpack(color or {1, 1, 1})
    self.particles = particles{
        image = drops.image,
        buffer = 20,
        rate = 4,
        acceleration={0, 1000},
        area={"uniform", 100, 100},
        color={
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 0,
        },
        lifetime=0.5
    }
end

function drops:on_adopted(parent)
    if not parent.shape then return end
    local s = parent:shape()
    self.particles:setEmissionArea("uniform", s.w * 0.5, s.h * 0.5)
    self.particles:setPosition(0, -s.h * 0.5)
end

function drops:__update(dt)
    self.particles:update(dt)
end

function drops:__draw()
    gfx.draw(self.particles)
end

return drops
