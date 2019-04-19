local card = {}

function card:create()
    local atlas = get_atlas("art/props")
    self.shape = spatial(atlas:get_animation("card").quad:getViewport())
    self.shape = self.shape
    self.stack = DrawStack.create()
        :reset()
        :stack(atlas:get_animation("card"))
        :within(
            function(x, y, w, h)
                gfx.setColor(0, 0, 0, 0.55)
                gfx.setFont(font(18))
                gfx.printf("Awaken", x, y, w, "center")
            end,
            "name"
        )
        :with(
            atlas:get_animation("awaken"),
            "image"
        )
        :within(
            draw_holder,
            "image"
        )
        :within(
            function(x, y, w, h)
                gfx.setColor(0.7, 0.8, 0.8)
                gfx.rectangle("fill", x, y, w, h)
            end,
            "text"
        )
        :within(
            function(x, y, w, h)
                gfx.setFont(font(11))
                gfx.setColor(0, 0, 0)
                local text = "Gain charge, shield and empower.\nReduce health to 1."
                gfx.printf(
                    text, x + 5, y + 5, w - 10
                )
            end,
            "text"
        )
        :within(
            draw_holder,
            "text"
        )

    self.blur = moon(moon.effects.gaussianblur)
    self.blur.sigma = 3

    local im = gfx.prerender(20, 20, function(w, h)
        gfx.setColor(1, 1, 1)
        gfx.circle("fill", w * 0.5, h * 0.5, w * 0.5)
    end)

    self.particles = particles{
        image = im,
        buffer = 320,
        lifetime = 0.75,
        emit = 0,
        rate = 320,
        area = {"borderrectangle", self.shape.w - 7, self.shape.h - 7, 0, true},
        color = {
            1, 1, 0.2, 0,
            1, 1, 0.7, 0.4,
            0.2, 0.2, 1, 0,
        },
        speed = {1, 30}
    }
end

function card:highlight(do_it)
    self.highlighted = do_it
    return self
end

function card:__draw(x, y)
    gfx.setColor(1, 1, 1)
    if self.highlighted then
        gfx.setBlendMode("add")
        self.blur.draw(function()
            gfx.draw(self.particles, x + self.shape.w, y + self.shape.h)
        end)
        gfx.setBlendMode("alpha")
    end

    self.stack:draw(x, y)
end

function card:__update(dt)
    if self.highlighted then
        self.particles:update(dt)
    end
end

return card
