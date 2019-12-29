local sfx = {}

local blur = moon(moon.effects.gaussianblur)
blur.gaussianblur.sigma = 2.0

local ellipse_im = gfx.prerender(6 * 2, 20 * 3, function(w, h)
    blur(function()
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.25, h * 0.25)
    end)
end)

blur.gaussianblur.sigma = 15.0

local cloud_im = gfx.prerender(50 * 2, 50 * 2, function(w, h)
    blur(function()
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", w * 0.5, h * 0.5, w * 0.25, h * 0.25)
    end)
end)

function sfx:create()
    self.particles = list(
        particles{
            image = ellipse_im,
            buffer = 40,
            rate = 7,
            lifetime = 1.3,
            damp = 1.0,
            speed = {200, 300},
            color = {
                0.2, 0.5, 0.9, 1.0,
                0.2, 0.5, 0.9, 1.0,
                0.2, 0.5, 0.9, 0.0
            },
            dir = -math.pi * 0.5,
            area = {"uniform", 100, 30}
        },
        particles{
            image = cloud_im,
            buffer = 60,
            rate = 13,
            lifetime = 3.0,
            speed = 30,
            color = {
                0.2, 0.5, 0.9, 0.0,
                0.2, 0.5, 0.9, 0.3,
                0.2, 0.5, 0.9, 0.5,
                0.2, 0.5, 0.9, 0.0
            },
            dir = -math.pi * 0.5,
            area = {"normal", 40, 10}
        }
    )
    self.offset = {
        vec2(0, -30),
        vec2(0, 20)
    }
    self.timescale = {
        2, 1
    }
end

function sfx:is_done()
    for _, p in ipairs(self.particles) do
        if p:getCount() > 0 then return false end
    end
    return true
end

function sfx:halt()
    local function do_halt(self)
        for i, p in ipairs(self.particles) do
            p:stop()
        end
        while not self:is_done() do
            event:wait("update")
        end
        self:destroy()
    end
    self:fork(do_halt)
end

function sfx:__update(dt)
    for i, p in ipairs(self.particles) do
        p:update(dt * (self.timescale[i] or 1))
    end
end

function sfx:__draw()
    gfx.setBlendMode("add")
    for i, p in ipairs(self.particles) do
        gfx.draw(p, self.offset[i]:unpack())
    end
    gfx.setBlendMode("alpha")
end

return sfx
