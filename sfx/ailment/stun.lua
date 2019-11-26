local sfx = {}

function sfx:create()
    local atlas = get_atlas("art/props")
    self.image = atlas:get_frame("star")
    self.time = 0
    self.freq = 5
    self.amp_x = 40
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
    local function get_draw_args(phase)
        local dx = math.cos(phase) * self.amp_x
        local dy = -math.sin(phase) * self.amp_y
        local scale = 1.5 + math.cos(phase + math.pi * 0.5) * 0.3
        local color = 1 + math.min(0, -math.sin(phase) * 0.8)
        return dx, dy, scale, color
    end

    local function do_draw(dx, dy, scale, color)
        gfx.setColor(color, color, color)
        local _, _, w, h = self.image.quad:getViewport()
        gfx.draw(
            self.image.image, self.image.quad, dx, dy, 0, scale, scale,
            w / 2, h / 2
        )
    end

    local p = self.time * self.freq

    local args = {
        {get_draw_args(p)},
        {get_draw_args(p + math.pi * 1.0 / 2.0)},
        {get_draw_args(p + math.pi * 2.0 / 2.0)},
        {get_draw_args(p + math.pi * 3.0 / 2.0)},
    }

    table.sort(args, function(a, b)
        return a[3] < b[3]
    end)

    for _, arg in ipairs(args) do
        do_draw(unpack(arg))
    end
end

return sfx
