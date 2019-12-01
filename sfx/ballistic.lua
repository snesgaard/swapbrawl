local ballistic = {}

function ballistic:create(animations, atlas)
    self:init(animations, atlas)
end

function ballistic:init(animations, atlas)
    if animations then
        self.sprite = self:child(Sprite, animations, atlas)
    end
end

local function calculate_curve(start_pos, end_pos, gravity)
    local x1, y1 = start_pos:unpack()
    local x2, y2 = end_pos:unpack()
    local dx = x2 - x1
    local a = -gravity / 2
    local b = (y2 - y1) + gravity / 2
    local c = y1
    return a, b, c
end

function ballistic:ballistic_travel(start_pos, end_pos, opt)
    local x1, x2 = start_pos.x, end_pos.x
    local a, b, c, dur = calculate_curve(
        start_pos, end_pos, opt.gravity or -2000
    )
    local angular_speed = opt.angular_speed or 20
    local duration = opt.time or 0.85
    local time = duration

    while time > 0 do
        local dt = event:wait("update")
        time = time - dt
        local s = 1 - time / duration
        local x = x1 * (1 - s) + x2 * s
        local y = a * s * s + b * s + c
        self.__transform.pos.x = x
        self.__transform.pos.y = y
        self.__transform.angle = self.__transform.angle + angular_speed * dt
    end
end

function ballistic:linear_travel(start_pos, end_pos, opt)
    local x1, x2 = start_pos.x, end_pos.x
    local y1, y2 = start_pos.y, end_pos.y
    local angular_speed = opt.angular_speed or 20
    local duration = opt.time or 0.15
    local time = duration

    while time > 0 do
        local dt = event:wait("update")
        time = time - dt
        local s = 1 - time / duration
        local x = x1 * (1 - s) + x2 * s
        local y = y1 * (1 - s) + y2 * s
        self.__transform.pos.x = x
        self.__transform.pos.y = y
        self.__transform.angle = self.__transform.angle + angular_speed * dt
    end
end

function ballistic:_travel(start_pos, end_pos, opt)
    opt = opt or {}
    self.sprite:queue("normal")
    if opt.is_linear then
        self:linear_travel(start_pos, end_pos, opt)
    else
        self:ballistic_travel(start_pos, end_pos, opt)
    end

    self.__transform.angle = 0
    local has_impact = self.sprite:get_animation("impact")
    if has_impact then
        self.sprite:queue({"impact", loop=false})
    else
        self.sprite:hide()
    end
    if opt.on_impact then
        opt.on_impact()
    end
    event(self, "finish")
    if has_impact then
        event:wait(self.sprite, "finish")
    end
    self:destroy()
end

function ballistic:travel(startpos, endpos, opt)
    self:fork(self._travel, startpos, endpos, opt)
end

function ballistic:test()
    local anime = {
        normal="potion_red/idle",
        impact="potion_red/break"
    }
    self:init(anime, "art/props")

    self:travel(vec2(400, 0), vec2(500, 10))
end

return ballistic
