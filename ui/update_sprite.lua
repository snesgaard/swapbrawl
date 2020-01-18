function Sprite:get_color_stack()
    if not self.color_stack then
        self.color_stack = dict()
    end
    return self.color_stack
end

function Sprite:get_speed_stack()
    if not self.speed_stack then
        self.speed_stack = dict()
    end
    return self.speed_stack
end

function Sprite:add_sfx(key, path, ...)
    self.sfx_table = self.sfx_table or dict()
    if not self.sfx_table[key] then
        self.sfx_table[key] = self:child(require(path), ...)
    end
end

function Sprite:remove_sfx(key)
    self.sfx_table = self.sfx_table or dict()
    if self.sfx_table[key] then
        self.sfx_table[key]:destroy()
        self.sfx_table[key] = nil
    end
end

function Sprite:compute_color()
    local c = color.create(1, 1, 1, 1)
    for _, c2 in pairs(self.color_stack) do
        c = c * c2
    end
    return c
end

function Sprite:compute_speed()
    local s = 1
    for _, s2 in pairs(self:get_speed_stack()) do
        s = s * s2
    end
    return s
end

function Sprite:update_color()
    self.graph:data("color").color = self:compute_color()
    return self
end

function Sprite:update_speed()
    self.speed = self:compute_speed()
    return self
end

function Sprite:death()
    local cs = self:get_color_stack()
    cs.death = color.create(1, 1, 1, 1)

    local function animate_death()
        local t = tween(0.2, cs.death, color.create(1, 0.2, 0.1, 1))
            :call(function() self:update_color() end)
        event:wait(t, "finish")
        local t = tween(0.2, cs.death, color.create(0, 0, 0, 0))
            :call(function() self:update_color() end)
        event:wait(t, "finish")
    end

    self:fork(animate_death)
end

function Sprite:freeze(active)
    if active then
        self:get_color_stack().freeze = color.create(0.2, 0.3, 1)
        self:get_speed_stack().freeze = 0
        self:add_sfx("freeze", "sfx.freeze")
    else
        self:get_color_stack().freeze = nil
        self:get_speed_stack().freeze = nil
        self:removesfx("freeze")
    end
    self:update_color():update_speed()
    return self
end

function Sprite:oil(active)
    if active then
        self:get_color_stack().oil = color.create(0.1, 0.1, 0.1)
        self:add_sfx("oil", "sfx.drops", {0.1, 0.1, 0.1})
    else
        self:get_color_stack().oil = nil
        self:remove_sfx("oil")
    end
    self:update_color()
    return self
end

function Sprite:wet(active)
    if active then
        self:get_color_stack().wet = color.create(0.2, 0.7, 0.9)
        self:add_sfx("wet", "sfx.drops", {0.2, 0.2, 0.9})
    else
        self:get_color_stack().wet = nil
        self:remove_sfx("wet")
    end
    self:update_color()
    return self
end

function Sprite:alive()
    local cs = self:get_color_stack()
    cs.death = cs.death or color.create(1, 1, 1, 1)
    tween(0.4, cs.death, color.create(1, 1, 1, 1))
        :call(function() self:update_color() end)
end

local TestSprite = {}

function TestSprite:create()
end

function TestSprite:test()
    local fencer = require "actor.fencer"
    local atlas = get_atlas("art/main_actors")
    local sprite = self:child(Sprite, fencer.animations, fencer.atlas)
    sprite:queue{"idle"}
    sprite:child(require "sfx.shocked")
end

return TestSprite
