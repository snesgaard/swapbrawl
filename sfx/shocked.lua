local sfx = {}

sfx.blur = moon(moon.effects.gaussianblur)
sfx.blur.gaussianblur.sigma = 5

function sfx:create()
    self.color = {0.2, 0.7, 0.7, 1}
    self.line = {}
    self.shape = spatial(0, 0, 100, 100)
    self.scale = 1
    self:fork(self.life)
end

function sfx:on_adopted(parent)
    if not parent.shape then return end
    self.shape = parent:shape()
end

local function create_jagged_line(src, dst, sway)
    sway = sway or 80
    jaggedness = 1.0 / sway
    local tangent = dst - src
    local length = tangent:length()
    local normal = vec2(-tangent.y, tangent.x):normalize()
    local positions = list(0, 1)
    for i = 0, math.floor(length / 10) do
        table.insert(positions, love.math.random())
    end
    table.sort(positions)
    local prev_point = src
    local prev_displacement = 0
    local line = list()
    for i = 2, #positions do
        local pos = positions[i]
        local scale = (length * jaggedness) * (pos - positions[i - 1])
        local envelope = pos > 0.95 and 20 * (1 - pos) or 1
        local displacement = love.math.random(-sway, sway)
        displacement = displacement - (displacement - prev_displacement) * (1 - scale);
        displacement = displacement * envelope;
        local point = src + tangent * pos + normal * displacement;
        table.insert(line, point.x)
        table.insert(line, point.y)
        -- TODO ADd thickness later
        prev_point = point;
        prev_displacement = displacement;
    end
    return line
end

local function random_pos(shape)
    local rng = love.math.random
    return vec2(
        rng(-shape.w * 0.5, shape.w * 0.5),
        rng(-shape.h * 0.5, shape.h * 0.5)
    )
end

function sfx:life()
    while true do
        self.color[4] = 1
        self.scale = 1
        self.line = create_jagged_line(
            random_pos(self.shape), random_pos(self.shape)
        )
        local t = tween(0.15, self.color, {[4]=0}, self, {scale=1.2})
        gfx.setLineWidth(4)
        event:wait(t, "finish")
    end
end

--function sfx:life()
--    self.color = {1, 1, 1, 1}-
--    self.line = create_jagged_line(vec2(-100, 0), vec2(100, 0))
--end

function sfx:__draw()
    if #self.line then
        gfx.push()
        gfx.translate(0, -self.shape.h * 0.5)
        gfx.scale(self.scale)

        gfx.setLineWidth(16)
        gfx.setColor(0.2, 0.7, 0.7, 0.4)
        sfx.blur(function()
            gfx.line(unpack(self.line))
        end)
        gfx.setLineWidth(3)
        gfx.setColor(unpack(self.color))
        gfx.line(unpack(self.line))

        gfx.pop()
    end
end

return sfx
