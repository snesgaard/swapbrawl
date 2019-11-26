local shield = {}

function shield:create()
    local shield_part = get_icon("part", "art/props")
    self.radius = dict{x = 0, y = 0}
    self.final_radius = dict{x = 125, y = 210}

    self.border_particles = particles{
        image = shield_part.image,
        quad = shield_part.quad,
        offset = frame_offset(shield_part),
        image = "art/part.png",
        buffer = 100,
        rate = 75,
        lifetime = 0.75,
        area = {
            "borderellipse", self.final_radius.x, self.final_radius.y, 0, true
        },
        acceleration = {0, -30},
        size = 0.7,
        speed = 50,
        color = {
            0.5, 0.6, 1, 0.5,
            1, 1, 1, 0
        },
    }

    self.inner_thicc = 15

    self.blur = moon(moon.effects.gaussianblur)

    self:fork(self.life)
    self.__transform.scale = vec2(0.5, 0.5)
end

function shield:__update(dt)
    self.border_particles:update(dt)
    self.blur.gaussianblur.sigma = 2.5
    self.inner_thicc = 15 + math.sin(love.timer.getTime() * 2.5)
end

function shield:life()
    local t = tween(0.3, self.radius, self.final_radius):ease(ease.outBounce)
    event:wait(t, "finish")
    if not self.is_halted then
        event:wait(self, "halt")
    end
    self.border_particles:stop()
    local t = tween(0.1, self.radius, {x = 0, y = 0})
    event:wait(t, "finish")
    while self.border_particles:getCount() > 0 do
        self:wait_update()
    end
    self:destroy()
end

function shield:halt()
    self.is_halted = true
    event(self, "halt")
end

function shield:__draw(x, y)
    x = (x or 0)
    y = (y or 0) - self.final_radius.y + 30
    gfx.setColor(1, 1, 1, 1)
    gfx.draw(self.border_particles, x, y)
    local function circle_draw()
        gfx.setColor(0.5, 0.6, 1, 0.15)
        gfx.ellipse("fill", x, y, self.radius.x, self.radius.y)
        gfx.setLineWidth(self.inner_thicc)
        gfx.setColor(0.5, 0.6, 1, 1)
        gfx.ellipse("line", x, y, self.radius.x, self.radius.y)
        gfx.setLineWidth(2)
        gfx.setColor(1, 1, 1, 0.5)
        gfx.ellipse("line", x, y, self.radius.x, self.radius.y)
    end
    self.blur(circle_draw)
end

return shield
