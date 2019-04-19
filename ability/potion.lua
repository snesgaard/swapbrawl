local position = require "combat.position"
local common = require "ability.common"
local projectile = require "combat.projectile"

local potion = {}

function potion.__user_type()
    return "alchemist"
end

function potion.execute(state, args)
    return mech.execute(
        state,
        "heal", mech.heal, dict{target=args.target, heal=5}
    )
end

function potion.targets(state, id)
    return state
        :position()
        :filter(function(k, v) return type(k) == "number" end)
        :values()
end

function potion.animate(handle, context, epic, args, resolve)
    local s = context.sprites[args.user]

    s:set_animation("cast")
    local cast_hitbox = common.wait_for_hitbox(handle, s.on_hitbox, "cast", 2.0)

    local potion_node = context.sfx:child(
        projectile.sprite, cast_hitbox:center(), "potion_red/idle",
        "potion_red/break"
    )
    local epoch = epic.heal:tail()
    local pos_target = position.get_world(
        epoch.state:position(), epoch.info.target
    )
    local st = context.sprites[epoch.info.target]
    local h = st:height()
    handle:wait(
        projectile.ballistic(potion_node, -200, 0.7, pos_target - vec2(0, h))
    )
    potion_node.sprite:set_animation("impact")

    resolve(unpack(epic))
    handle:wait(0.5)
    s:set_animation("idle")
end

return potion
