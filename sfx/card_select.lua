local flash = {}

function flash:create(shape, color)
    color = {unpack(color)}
    color[4] = 1
    self.shape = shape
    self.scale = vec2(1, 1)
    self.color = color
    self.rect = vec2(self.shape:unpack())
    self.__transform.pos = shape
    self:fork(self.life)
end

function flash:life()
    local t = tween(0.2,
            self.rect, self.rect * 7,
            self.scale, vec2(2, 0),
            self.color, {[4] = 0}
    ):ease(ease.inOutQuad)
    event:wait(t, "finish")
    self:destroy()
end

function flash:__draw(x, y)
    local w, h = self.shape:unpack()
    local sx, sy = self.scale:unpack()
    local rw, rh = self.rect:unpack()
    gfx.setLineWidth(3)
    gfx.setColor(unpack(self.color))
    gfx.ellipse("fill", 0, 0, w * sx, h * sx)
    --gfx.ellipse("fill", 0, 0, w * sy, h * sx)
end

local sfx = {}

local green = {0.3, 1, 0.3}
local gold = {1, 1, 0.3}

function sfx:create(w, h)
    w = w or 50
    h = h or 80
    local im = gfx.prerender(w, h, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.rectangle("fill", 0, 0, w, h, 10)
    end)

    self.particles = particles{
        image = im,
        buffer = 20,
        lifetime = 1,
        emit = 0,
        rate = 4,
        --area = {"borderrectangle", 5, self.shape.h - 7, 0, true},
        color = {
            1, 1, 1, 1,
            0.5, 0.5, 0.5, 0.4,
            0.5, 0.5, 0.5, 0,
        },
        size = {2, 2.3},
    }

    self.color = {0.3, 1, 0.3}
    self.shape = vec2(w, h)
end

function sfx:__update(dt)
    self.particles:update(dt)
end

function sfx:__draw(x, y)
    local w, h = self.shape:unpack()
    gfx.setColor(unpack(self.color))
    gfx.draw(self.particles, x + w, y + h)
end

function sfx:trigger()
    if self.flash then
        self.flash:destroy()
    end
    self.color = gold
    self.flash = self:child(flash, self.shape, gold)
    return self
end

function sfx:fallback()
    if self.flash then
        self.flash:destroy()
    end
    self.color = green
    self.flash = nil
    return self
end

function sfx:test()
    self:trigger()
end

return sfx
