local node = {}

function node:create()
    local part = gfx.prerender(15, 15, function(w, h)
        gfx.setColor(1, 1, 1)
        local rx, ry = w * 0.5, h * 0.5
        gfx.ellipse("fill", rx, ry, rx, ry)
    end)

    self.particles = list(
        particles{
            image=part,
            buffer=100,
            rate=100,
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
            image=part,
            buffer=300,
            rate=300,
            lifetime={0.75, 1},
            color=List.concat(
                gfx.hex2color("ffd541af"),
                gfx.hex2color("f9a31b8f"),
                gfx.hex2color("fa6a0a0f"),
                gfx.hex2color("df3e2300")
            ),
            size={1.2, 2},
            speed={150, 300},
            damp = 1,
            spread=math.pi * 0.25,
            area = {"uniform", 7, 0},
            acceleration = {0, -300},
            dir = -math.pi * 0.5
            --pos = {0, -20}
        },
        particles{
            image=part,
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
        }
    )

    self:fork(self.animate)
end

function node:animate()
    self:wait(
        tween(0.1, vec2(-95, -40), vec2(95, 40))
            :set(function(pos)
                for _, p in pairs(self.particles) do
                    p:moveTo(pos.x, pos.y)
                end
            end)
    )
    for _, p in pairs(self.particles) do
        p:stop()
    end

    local function is_dead()
        for _, p in pairs(self.particles) do
            if p:getCount() > 0 then return false end
        end
        return true
    end

    while not is_dead() do self:wait_update() end
    self:destroy()
end

function node:__update(dt)
    for _, p in pairs(self.particles) do
        p:update(dt)
    end
end

function node:__draw(x, y)
    gfx.setColor(1, 1, 1)
    for _, p in pairs(self.particles) do
        gfx.draw(p, x, y)
    end
end

return node
