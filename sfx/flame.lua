local sfx = {}

function sfx:create()
    local circles = gfx.prerender(26, 26, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.5, h * 0.5)
    end)

    self.particles = {
        particles{
            image=circles,
            buffer=20,
            rate=20,
            lifetime={0.75, 1},
            color=List.concat(
                gfx.hex2color("ffd541af"),
                gfx.hex2color("f9a31b8f"),
                gfx.hex2color("fa6a0a0f"),
                gfx.hex2color("df3e2300")
            ),
            size={1.2, 3},
            speed={150, 300},
            damp = 1,
            spread=math.pi * 0.25,
            area = {"uniform", 7, 0},
            acceleration = {0, -1000},
            dir = -math.pi * 0.5,
            pos = {0, -20}
        },
        particles{
            image=circles,
            buffer=35,
            rate=35,
            lifetime={0.75, 1},
            color=List.concat(
                gfx.hex2color("6f3e23cf"),
                gfx.hex2color("6d758d00")
            ),
            size={2, 5},
            speed={150, 300},
            damp = 1,
            spread=math.pi * 0.75,
            area = {"uniform", 15, 0},
            acceleration = {0, -1000},
            dir = -math.pi * 0.5,
            pos = {0, -50}
        },
        particles{
            image=circles,
            buffer=50,
            rate=50,
            lifetime={0.75, 1},
            color=List.concat(
                gfx.hex2color("ffd541af"),
                gfx.hex2color("f9a31b8f"),
                gfx.hex2color("fa6a0a0f"),
                gfx.hex2color("df3e2300")
            ),
            size={1.2, 3},
            speed={150, 300},
            damp = 1,
            spread=math.pi * 0.35,
            area = {"uniform", 10, 0},
            acceleration = {0, -1000},
            dir = -math.pi * 0.5
        },
    }
end

function sfx:stop()
    for _, p in pairs(self.particles) do
        p:stop()
    end

    self:fork(self.monitor_halt)
end

function sfx:monitor_halt()
    local function is_done()
        for _, p in pairs(self.particles) do
            if p:getCount() ~= 0 then
                return false
            end
        end
        return true
    end

    while not is_done() do
        self:wait_update()
    end

    self:destroy()
end

function sfx:__update(dt)
    for _, p in ipairs(self.particles) do p:update(dt) end
end

function sfx:__draw(x, y)
    gfx.setColor(1, 1, 1)
    for _, p in ipairs(self.particles) do
        gfx.draw(p, x, y)
    end
end

return sfx
