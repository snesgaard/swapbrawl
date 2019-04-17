local slash = {}

function slash:create()
    self.length = 60
    self.width = 0
    self.progress = 0
    self.hlength = 25
    self.hpos = -self.length + self.hlength
    self.blur = moon(moon.effects.gaussianblur)
    self.blur.gaussianblur.sigma = 1.5
    self:fork(self.life)
    self.pos = vec2(0, 0)
    self.on_finish = event()
end

function slash:set_pos(pos)
    self.pos = pos
    return self
end

function slash:__draw(x, y)
    x = (x or 0) + self.pos.x
    y = (y or 0) + self.pos.y
    gfx.setColor(1, 1, 1)

    local function draw_center()
        gfx.push()
        gfx.translate(x, y)
        gfx.rotate(math.pi * 0.25)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", 0, 0, self.length, self.width)
        gfx.pop()
    end

    local function do_draw()
        gfx.push()
        gfx.translate(x, y)
        gfx.rotate(math.pi * 0.25)
        gfx.setColor(0.8, 0.2, 0.2)
        gfx.ellipse("fill", self.hpos, 0, self.hlength, self.width * 5.0)
        gfx.ellipse("fill", 0, 0, self.length + 10, self.width * 3.0)
        gfx.setColor(1, 1, 1)
        gfx.ellipse("fill", 0, 0, self.length, self.width)
        gfx.pop()
    end

    self.blur.draw(do_draw)
    draw_center()
end

function slash:life()
    local t = 0.125
    local tween = timer.tween(
        t,
        {
            [self] = {width = 3, hpos = 0}
        }
    )
    self:wait(tween)
    local tween = timer.tween(
        t,
        {
            [self] = {width = 0, hpos = self.length - self.hlength}
        }
    )
    self:wait(tween)
    self.on_finish()
    self:destroy()
end

return slash
