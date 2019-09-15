local function get_image(card, state, id)
    if not card then
        return "awaken", "art/props"
    end

    if type(card.image) == "string" then
        return card.image, "art/props"
    elseif type(card.image) == "table" then
        local im, atlas = unpack(card.image)
        return im, atlas or "art/props"
    elseif type(card.image) == "function" then
        -- TODO Pass state here
        local im, atlas = card:image(state, id)
        return im, atlas or "art/props"
    else
        log.warn("Unsupported image type <%>", type(card.image))
    end
end

local function get_text(card, state, id)
    local default_text = "No text"
    if not card then return default_text end
    local c = card
    local text = type(c.text) == "function" and c:text(state, id) or c.text
    return text or default_text
end

local function get_name(card, state, id)
    local default_text = "Undefined"
    if not card then return default_text end
    local c = card
    local text = type(c.name) == "function" and c:text(state, id) or c.name
    return text or default_text
end

local function get_type(state, id)
    if not state or not id then return end
    return state:read("card/type/" .. id)
end

local card = {}

function card:create(state, id)
    local card = get_type(state, id)
    local im, atlas = get_image(card, state, id)
    local text = get_text(card, state, id)
    local name = get_name(card, state, id)
    local atlas = get_atlas(atlas or "art/props")
    self.shape = spatial(atlas:get_animation("card").quad:getViewport())
    self.shape = self.shape
    self.stack = DrawStack.create()
        :reset()
        :stack(atlas:get_animation("card"))
        :within(
            function(x, y, w, h)
                gfx.setColor(0, 0, 0, 0.55)
                gfx.setFont(font(18))
                gfx.printf(name, x, y, w, "center")
            end,
            "name"
        )
        :with(
            atlas:get_animation(im),
            "image"
        )
        --:within(
        --    draw_holder,
        --    "image"
        --)
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
                --local text = "Deal minor damage and bleed."
                gfx.printf(
                    text, x + 5, y + 5, w - 10
                )
            end,
            "text"
        )
        --:within(
        --    draw_holder,
        --    "text"
        --)

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
        size = {1, 1, 1, 0},
        speed = {1, 30}
    }
end

function card:highlight(do_it, green)
    self.highlighted = do_it
    return self
end

function card:green(green)
    self.__green = green
    return self
end

function card:__draw(x, y)
    if self.highlighted then
        if self.__green then
            gfx.setColor(0.1, 1, 0.2)
        end
        gfx.setBlendMode("add")
        --self.blur.draw(function()
            --gfx.draw(self.particles, x + self.shape.w, y + self.shape.h)
        --end)
        gfx.setBlendMode("alpha")
    end

    gfx.setColor(1, 1, 1)
    self.stack:draw(x, y)
end

function card:__update(dt)
    if self.highlighted then
        self.particles:update(dt)
    end
end

return card
