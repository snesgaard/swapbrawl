local sfx = {}

function sfx:create()
    local part = gfx.prerender(15, 15, function(w, h)
        gfx.setColor(1, 1, 1)
        local rx, ry = w * 0.5, h * 0.5
        gfx.ellipse("fill", rx, ry, rx, ry)
    end)

    self.particles = particles{
        image=part,
        buffer=30,
        rate=30,
        lifetime={0.75, 1},
        color=List.concat(
            gfx.hex2color("ffd541af"),
            gfx.hex2color("f9a31b8f"),
            gfx.hex2color("6f3e23cf"),
            gfx.hex2color("6d758d00")
        ),
        size={0.6, 1.5},
        speed={150, 300},
        damp = 1,
        spread=math.pi * 0.25,
        area = {"uniform", 50, 50},
        acceleration = {0, -100},
        dir = -math.pi * 0.5,
        pos = {0, -20}
    }
    self.__transform.scale = vec2(0.5, 0.5)
end

function sfx:__update(dt)
    self.particles:update(dt)
end

function sfx:on_attach(sprite)
    local w, h = sprite:size()
    self.particles:setEmissionArea("uniform", w, h * 0.5)

    return self
end

function sfx:__draw(x, y)
    gfx.setColor(1, 1, 1)
    gfx.draw(self.particles, x, y)
end

return sfx
