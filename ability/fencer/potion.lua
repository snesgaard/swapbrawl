local animation = require "combat.animation"
local ability = {}

ability.name = "Potion"
ability.target = {type="single", side="same"}

function ability.transform(state, user, target)
    return {
        path="combat.mechanics:heal",
        args={heal=5, user=user, target=target}
    }
end

function ability.animation(root, epic, user, target)
    local hitbox, user_sprite, target_sprite = animation.throw(
        root, state, user, {}, target
    )
    local start_pos = hitbox:center()
    local s = target_sprite:shape()
    local stop_pos = target_sprite.__transform.pos - vec2(0, s.h / 2)

    local anime = {
        normal="potion_red/idle",
        impact="potion_red/break"
    }

    local sfx_node = root.sfx:child(require "sfx/ballistic", anime, "art/props")

    local opt = {}
    function opt.on_impact()
        root:broadcast(unpack(epic))
    end

    sfx_node:travel(start_pos, stop_pos, opt)
    event:wait(sfx_node, "finish")

    animation.throw_return(root, user)
end

return ability
