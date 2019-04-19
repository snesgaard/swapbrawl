local effect = {}

function effect:create(dx, dy, color)
    dx = dx or 40
    dy = dy or 40
    color = color or {1, 1, 1}
    local r, g, b = unpack(color)

    rate_pr_area = 0.007

    area = dx * dy

    local im = gfx.prerender(7, 7, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.circle("fill", w * 0.5, h * 0.5, w * 0.5)
    end)

    self.particles = particles{
        image = im,
        buffer = rate_pr_area * area,
        rate = rate_pr_area * area,
        area = {"uniform", dx, dy},
        lifetime = 0.80,
        acceleration = {0, 200},
        color = {
            r, g, b, 0,
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 0
        }
    }

end

function effect:__update(dt)
    self.particles:update(dt)
end

function effect:__draw(x, y)
    gfx.draw(self.particles, x, y)
end

return effect
