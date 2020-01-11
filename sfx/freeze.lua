local freeze = {}

local blur = moon(moon.effects.gaussianblur)
blur.gaussianblur.sigma = 3.0

freeze.image = gfx.prerender(100, 100, function(w, h)
    local rx, ry = w / 4.0, h / 4.0
    blur(function()
        gfx.ellipse("fill", w / 2, h / 2, rx, ry)
    end)
end)

local function get_shape(parent)
    if not parent.shape then
        return vec2(100, 100)
    else
        return parent:shape()
    end
end

function freeze:create()
    self.particles = {}
    for i= 1, 4 do
        local p = particles{
            image=freeze.image,
            buffer=10,
            rate=3,
            size={0.5, 1.0},
            lifetime=2.0,
            acceleration={0, 40},
            color = {
                1, 1, 1, 0,
                0.7, 0.7, 0.7, 0.25,
                0.7, 0.7, 0.7, 0.25,
                0.5, 0.5, 0.5, 0.0,
            },
            dir=math.pi * 0.5,
            speed={10},
            spread=math.pi * 0.2
        }

        self.particles[#self.particles + 1] = p
    end
end

function freeze:on_adopted(parent)
    local shape = get_shape(parent)

    local function get_x(i)
        if i % 2 == 0 then
            return -shape.x * 0.5, 0
        else
            return 0, shape.x * 0.5
        end
    end

    local function get_y(i)
        if i < 3 then
            return shape.y * 0.5, shape.y
        else
            return 0, shape.y * 0.5
        end
    end

    for i, p in ipairs(self.particles) do
        local x = love.math.random(get_x(i))
        local y = love.math.random(get_y(i))
        p:setPosition(x, y)
    end

end

function freeze:__update(dt)
    for _, p in ipairs(self.particles) do
        p:update(dt)
    end
end

function freeze:__draw()
    local mode = gfx.getBlendMode()
    gfx.setBlendMode("add")
    for _, p in ipairs(self.particles) do
        gfx.draw(p)
    end
    gfx.setBlendMode(mode)
end

return freeze
