local INNER_RADIUS = 7
local OUTER_RADIUS = 14
local ELLIPSE_RADIUS = 75

local marker = {}

function marker:create()
    self.blur = moon(moon.effects.gaussianblur)
    self.blur.gaussianblur.sigma = 2.5
    self.inner_radius = INNER_RADIUS
    self.outer_radius = OUTER_RADIUS
    self.ellipse_radius = ELLIPSE_RADIUS

    self.primary_color = {0.2, 0.4, 1, 1}
    self.secondary_color = {0.7, 0.8, 0.2, 0.5}
end

function marker:selection()
    if self.__life then
        self:join{self.__life}
    end
    self.__life = self:fork(self.life)
end

function marker:life()
    local function tween_target(s)
        return {
            inner_radius = INNER_RADIUS * s,
            outer_radius = OUTER_RADIUS * s,
            ellipse_radius = ELLIPSE_RADIUS * s
        }
    end

    self:wait(
        timer.tween(
            0.1,
            {
                [self] = tween_target(1.5)
            }
        )
    )

    self:wait(
        timer.tween(
            0.1,
            {
                [self] = tween_target(1.0)
            }
        )
    )

    while true do
        self:wait(
            timer.tween(
                1.0,
                {
                    [self] = tween_target(0.8)
                }
            )
        )
        self:wait(
            timer.tween(
                0.25,
                {
                    [self] = tween_target(1.0)
                }
            )
        )
    end
end

function marker:test()
    self:selection()
end

function marker:mass_draw(...)
    function __do_draw(c, p, ...)
        if not p then return end
        local x, y = p:unpack()
        gfx.setColor(unpack(c))
        gfx.circle("fill", x, y, self.outer_radius)
        gfx.ellipse("fill", x, y, self.ellipse_radius, INNER_RADIUS * 0.75)
        gfx.setColor(1, 1, 1, 1)
        gfx.circle("fill", x, y, self.inner_radius)

        return __do_draw(self.secondary_color, ...)
    end

    gfx.setColor(1, 1, 1)
    self.blur.draw(__do_draw, self.secondary_color, ...)
end

return marker
