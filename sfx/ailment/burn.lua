local sfx = {}

sfx.image = gfx.prerender(12, 12, function(w, h)
    gfx.ellipse("fill", w / 2, h / 2, w / 2, h / 2)
end)
sfx.blur = moon(moon.effects.gaussianblur)
sfx.blur.gaussianblur.sigma = 3

function sfx:create(color)
    local r, g, b = unpack(color or {1, 1, 1})
    self.particles = particles{
        image = sfx.image,
        buffer = 20,
        rate = 8,
        acceleration={0, -1000},
        damp=4,
        area={"uniform", 100, 100},
        color={
            gfx.hex2color("ffd541af"),
            gfx.hex2color("f9a31b8f"),
            gfx.hex2color("6f3e23cf"),
            gfx.hex2color("6d758d00")
        },
        size={0.5, 2},
        lifetime=0.5
    }
end

function sfx:on_adopted(parent)
    if not parent.shape then return end
    local s = parent:shape()
    self.particles:setEmissionArea("uniform", s.w * 0.5, s.h * 0.5)
    self.particles:setPosition(0, -s.h * 0.5)
end

function sfx:__update(dt)
    self.particles:update(dt)
end

function sfx:__draw()
    gfx.setColor(1, 1, 1)
    sfx.blur(function()
        gfx.draw(self.particles)
    end)
    gfx.draw(self.particles)
end

function sfx:test()

end

return sfx
