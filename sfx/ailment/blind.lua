local sfx = {}

sfx.blur = moon(moon.effects.gaussianblur)
sfx.blur.gaussianblur.sigma = 4

sfx.image = gfx.prerender(70, 70, function(w, h)
    sfx.blur(function()
        gfx.ellipse("fill", w / 2, h / 2, w / 4, h / 4)
    end)
end)

function sfx:create()
    self.particles = particles{
        image=sfx.image,
        buffer=20,
        rate=4,
        speed=100,
        dir=-math.pi*0.5,
        color={
            0, 0, 0, 0,
            0, 0, 0, 1,
            0, 0, 0, 1,
            0, 0, 0, 0,
        },
        size={1.0, 2.0},
        lifetime=1.0,
    }
end

function sfx:on_adopted(parent)
    if not parent.shape then return end
    local s = parent:shape()
    self.__transform.pos = vec2(0, s.y * 0.7)
end

function sfx:__update(dt)
    self.particles:update(dt)
end

function sfx:__draw()
    gfx.draw(self.particles)
end

return sfx
