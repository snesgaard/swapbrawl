local sfx = {}

function sfx:create()

    local frame = get_icon("boobleA", "art/props")

    local offset = (spatial(frame.quad:getViewport()):size() * 0.5):tolist()
    self.particles = particles{
        image = frame.image,
        quad = frame.quad,
        offset = offset,
        rate = 2.5,
        emit = 1,
        lifetime = 2.0,
        buffer = 10,
        speed = 40,
        area = {"uniform", 10, 2},
        spread = math.pi * 0.2,
        dir = -math.pi * 0.5,
        size = {0.2, 2, 1.0},
        color = {
            0.8, 0.3, 0.9, 0.5,
            0.8, 0.3, 0.9, 1.0,
            0.8, 0.3, 0.9, 0.5,
            0.8, 0.3, 0.9, 0,
        }
    }
end

function sfx:__update(dt)
    self.particles:update(dt)
end

function sfx:__draw(x, y)
    gfx.draw(self.particles, x, y)
end

return sfx
