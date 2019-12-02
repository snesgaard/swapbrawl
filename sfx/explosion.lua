local sfx = {}

function sfx:create()
    self.flash_circle = {
        image = gfx.prerender(200, 200, function(w, h)
            gfx.setColor(1, 1, 1)
            gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.5, h * 0.5)
        end),
        color = {1, 1, 1, 1}
    }

    local circles = gfx.prerender(26, 26, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.5, h * 0.5)
    end)

    local spark = gfx.prerender(20, 6, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.5, h * 0.5)
    end)

    self.particles = {
        particles{
            image=circles,
            buffer=40,
            rate=0,
            emit=40,
            lifetime={0.35, 0.75},
            color=List.concat(
                gfx.hex2color("ffd541af"),
                gfx.hex2color("f9a31b8f"),
                gfx.hex2color("fa6a0a0f"),
                gfx.hex2color("df3e2300")
            ),
            size={1, 2},
            speed={300, 600},
            acceleration={0, -600},
            damp=5,
            area={"ellipse", 20, 20, 0, true}
        },
        particles{
            image=circles,
            buffer=40,
            rate=0,
            emit=40,
            lifetime={0.35, 0.75},
            color=List.concat(
                gfx.hex2color("6f3e23cf"),
                gfx.hex2color("6d758d00")
            ),
            size={0.5, 1},
            speed={50, 600},
            acceleration={0, -600},
            damp=5,
            area={"ellipse", 20, 20, 0, true}
        }
    }

    self:fork(self.life)
end


function sfx:life()
    local t = tween(0.1, self.flash_circle.color, {1, 1, 1, 0})
    event:wait(t, "finish")

    local function is_done()
        for _, p in ipairs(self.particles) do
            if p:getCount() > 0 then return false end
        end
        return true
    end

    while not is_done() do event:wait("update") end

    self:destroy()
end

function sfx:__update(dt)
    for _, p in ipairs(self.particles) do p:update(dt) end
end

function sfx:__draw()
    gfx.setColor(self.flash_circle.color)
    local im = self.flash_circle.image
    gfx.draw(im, -im:getWidth() * 0.5, -im:getHeight() * 0.5)
    gfx.setColor(1, 1, 1)
    for _, p in ipairs(self.particles) do
        gfx.draw(p, 0, 0)
    end
end




return sfx
