local sfx = {}

function sfx:create(w, h)
    w = w or 100
    h = h or 100
    local frame = get_icon("boobleA", "art/props")

    local offset = (spatial(frame.quad:getViewport()):size() * 0.5):tolist()
    self.particles = particles{
        image = frame.image,
        quad = frame.quad,
        offset = offset,
        rate = 40,
        emit = 1,
        emission_life = 0.5,
        lifetime = 0.25,
        buffer = 20,
        speed = 40,
        area = {"uniform", w * 0.25, h * 0.25},
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
    self.__transform.pos.y = -h * 0.5
end

function sfx:is_done()
    local p = self.particles
    if not p:isStopped() or p:getCount() > 0 then
        return false
    end
    return true
end

function sfx:__update(dt)
    self.particles:update(dt)
    if self:is_done() then
        self:destroy()
    end
end

function sfx:__draw(x, y)
    gfx.draw(self.particles, x, y)
end

return sfx
