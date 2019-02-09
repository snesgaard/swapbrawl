local position = require "combat.position"

local function create_default_cross(self)
    local keys = {
        up = "W",
        down = "S",
        left = "A",
        right = "D"
    }

    local name = {
        up = "Magick",
        left = "Attack",
        right = "Defend",
        down = "Item"
    }

    local icons = {
        left = "attack_bw",
        up = "magick_bw",
        down = "item_bw",
        right = "defend_bw"
    }

    local cross = self:child(require "ui.action_cross")
    cross:set_keys(keys)
    cross:set_texts(name)
    cross:set_icons(icons)
    return cross
end

local node = {}

function node:create(id, state)
    self.id = id
    self.state = state

    self.cross = create_default_cross(self)
    local pos = position.get_world(self.state:position(), id)
    self.cross.__transform.pos = pos - vec2(0, 300)

    self.options = {
        a = "attack", w = "magick", d = "defend", s = "item"
    }
end

function node:keypressed(key)
    local o = self.options[key]
    if o and self.action_picked then
        self.action_picked(o)
    end
end

return node
