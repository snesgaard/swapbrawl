local state = require "combat.state"
local position = require "combat.position"

local core = {}

function core:create(actor, foes)
    self.ui = self:child()
    self.ui.turn = self.ui:child(ui.turn_queue)
    self.ui.turn.__transform.pos = vec2(gfx.getWidth() - 150, 100)
    self.sprites = self:child()
    self.state = state()
    -- Activate dummy battle
end

function core.setup_actor_state(state, index, type)
    local typedata = require("actor." .. type)

    local id = id_gen.register(type)

    local stats = typedata.basestats()

    for key, value in pairs(stats) do
        state = state:set("actor/" .. key .. "/" .. id, value)
    end

    -- set max health and stamina if not set
    state
        :set("actor/max_health" .. id, state:get("actor/health" .. id))
        :set("actor/max_stamina" .. id, state:get("actor/stamina" .. id))
        :map("position", position.set, id, index)

    return state, id
end

function core.setup_actor_gfx(sprites, state, id, type)
    local id = id_gen.register(type)
    local typedata = require("actor." .. type)

    sprites[id] = sprites:child(Sprite, typedata.sprite())

    local index = state:get("position/" .. id)

    sprites[id].__transform.pos = position.get_world(state, id)

    if index < 0 then
        sprites[id].__transform.scale.x = -sprites[id].__transform.scale.x
    end
end

return core
