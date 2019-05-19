local charge = {}

function charge:create(pos)
    local charge_part = get_icon("charge_part", "art/props")
    local r, g, b = 1, 0.4, 0.2
    self.particles = particles{
        image = charge_part.image,
        quad = charge_part.quad,
        offset = frame_offset(charge_part),
        buffer = 15,
        lifetime = 1.25,
        rate = 5,
        speed = 200,
        dir = -math.pi * 0.5,
        size = {1, 4, 3, 1},
        color = {
            r, g, b, 0,
            r, g, b, 0.10,
            r, g, b, 0.10,
            r, g, b, 0,
        }
    }
    local aura_part = get_icon("part2", "art/props")
    self.aura_particles = particles{
        image = aura_part.image,
        quad = aura_part.quad,
        offset = frame_offset(aura_part),
        buffer = 40,
        lifetime = 0.35,
        rate = 40,
        speed = 400,
        dir = -math.pi * 0.5,
        area = {"uniform", 70, 40},
        size = 0.45,
        color = {
            1, 1, 1, 0,
            r, g * 2, b * 2, 0.35,
            r, g, b, 0.35,
            r, g, b, 0.0,
        }
    }
    self.on_empty = event()
    self.__transform.scale = vec2(0.5, 0.5)
end

function charge:halt()
    self.aura_particles:stop()
    self.particles:stop()
    self.__do_halt = true
end

function charge:__update(dt)
    self.aura_particles:update(dt)
    self.particles:update(dt)

    local c1 = self.particles:getCount()
    local c2 = self.aura_particles:getCount()

    if c1 == 0 and c2 == 0 and self.__do_halt then
        self:destroy()
    end
end

function charge:__draw(x, y)
    y = (y or 0) + 10
    gfx.setColor(1, 1, 1)
    gfx.draw(self.particles, x, y)
    gfx.draw(self.aura_particles, x, y - 40)
end

return charge
