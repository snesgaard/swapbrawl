local sfx = {}

function sfx:create()
    local atlas = get_atlas("art/props")
    self.image = atlas:get_animation("star")
    self.time = 0
    self.freq = 5
    self.amp_x = 20
    self.amp_y = 5
end

function sfx:__update(dt)
    self.time = self.time + dt
end

function sfx:on_attach(sprite)
    self.__transform.scale = vec2(0.75, 0.75)
    self.__transform.pos.y = -sprite:height() - 10
end

function sfx:__draw(x, y)
    local function do_draw(phase)
        local dx = math.cos(phase) * self.amp_x
        local dy = -math.sin(phase) * self.amp_y
        local s = 1 + math.cos(phase + math.pi * 0.5) * 0.3
        local c = 1 + math.min(0, -math.sin(phase) * 0.8)
        gfx.setColor(c, c, c)
        gfx.draw(self.image.image, self.image.quad, dx, dy, 0, s, s)
    end

    local p = self.time * self.freq
    do_draw(p)
    do_draw(p + math.pi * 2.0 / 3.0)
    do_draw(p + math.pi * 4.0 / 3.0)
end

return sfx
