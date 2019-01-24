local battle = {}

local new_state = require "combat.state"
local position = require "combat.position"

state = new_state()
ActionQueue = require "combat.action_queue"

function battle:create()
    sprites = self:child()
    action_queue = self:child(ActionQueue)

    local party = {"fencer", "vampire"}

    local foes = {"vampire", "fencer"}
    for i, typename in pairs(party) do
        local id = id_gen.register(typename)
        local typedata = actor(typename)
        -- Init sprite
        local atlas, anime = typedata.sprite()
        sprites[id] = sprites:child(Sprite, atlas, anime)
            :set_animation("idle")
        -- Init positions
        position.set(state, party_flag, id, i)
    end

    for i, typename in pairs(foes) do
        local id = id_gen.register(typename)
        local typedata = actor(typename)
        -- Init sprite
        local atlas, anime = typedata.sprite()
        sprites[id] = sprites:child(Sprite, atlas, anime)
            :set_animation("idle")
        sprites[id].__transform.scale.x = -2
        -- Init positions
        position.set(state, foe_flag, id, i)
    end

    for _, flag in pairs({party_flag, foe_flag}) do
        for i, id in pairs(position.frontline(state, flag)) do
            local pos = position.get_world(state, id)
            sprites[id].__transform.pos = pos
        end
    end
end


function battle:__draw(x, y)


end

return battle
