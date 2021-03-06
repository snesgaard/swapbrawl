local sfx = {}

function sfx:create()
    local circles = gfx.prerender(26, 26, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.5, h * 0.5)
    end)

    local count = 40
    self.particles = {
        particles{
            image=circles,
            buffer=count,
            rate=0,
            emit=count,
            lifetime={0.25, 0.5},
            color=List.concat(
                gfx.hex2color("ffd541af"),
                gfx.hex2color("f9a31b8f"),
                gfx.hex2color("fa6a0a0f"),
                gfx.hex2color("df3e2300")
            ),
            size={1.2, 3},
            speed={1200, 2400},
            damp = 7,
            spread=math.pi * 0.25,
            area = {"uniform", 7, 0},
            acceleration = {0, -1000},
            pos = {0, -20}
        },
    }
    self.__transform.scale.x = -1
end

function sfx:__update(dt)
    for _, p in ipairs(self.particles) do p:update(dt) end
    for _, p in ipairs(self.particles) do
        if p:getCount() > 0 then
            return
        end
    end
    self:destroy()
end

function sfx:__draw(x, y)
    gfx.setColor(1, 1, 1)
    for _, p in ipairs(self.particles) do
        gfx.draw(p, x, y)
    end
end

return sfx
