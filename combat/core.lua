local state = require "combat.state"
local position = require "combat.position"

local core = {}

function core:create(party, foes)
    self.ui = self:child()
    self.ui.turn = self.ui:child(ui.turn_queue)
    self.ui.turn.__transform.pos = vec2(gfx.getWidth() - 150, 100)
    self.sprites = self:child()
    self.icons = dict()
    self.state = state()

    self.party_ids = list()
    self.foe_ids = list()

    for i, typepath in ipairs(party) do
        self.state, self.party_ids[i] = core.setup_actor_state(
            self.state, i, typepath
        )
        core.setup_actor_gfx(
            self.sprites, self.icons, self.state, self.party_ids[i], typepath
        )
    end
    for i, typepath in ipairs(foes) do
        self.state, self.foe_ids[i] = core.setup_actor_state(
            self.state, -i, typepath
        )
        core.setup_actor_gfx(
            self.sprites, self.icons, self.state, self.foe_ids[i], typepath
        )
    end

    for _, id in ipairs(self.party_ids:concat(self.foe_ids)) do
        self.ui.turn:push_back({icon = self.icons[id]})
    end
    -- Activate dummy battle
end

function core.setup_actor_state(state, index, type)
    local typedata = require("actor." .. type)

    local id = id_gen.register(type)

    local stats = typedata.basestats()

    for key, value in pairs(stats) do
        state = state:write("actor/" .. key .. "/" .. id, value)
    end

    -- set max health and stamina if not set
    state = state
        :write("actor/max_health/" .. id, state:read("actor/health/" .. id))
        :write("actor/max_stamina/" .. id, state:read("actor/stamina/" .. id))
        :map("position", position.set, id, index)

    log.info("Setting up <%s> on index <%i> as <%s>", type, index, id)

    return state, id
end

function core.setup_actor_gfx(sprites, icons, state, id, type)
    local typedata = require("actor." .. type)

    sprites[id] = sprites:child(Sprite, typedata.sprite())
        :set_animation("idle")

    local index = state:read("position/" .. id)

    sprites[id].__transform.pos = position.get_world(
        state:read("position"), id
    )
    icons[id] = typedata.icon()

    if index < 0 then
        sprites[id].__transform.scale.x = -sprites[id].__transform.scale.x
    end
end

return core
