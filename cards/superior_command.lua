local common = require "ability.common"

local card = {}

card.image = "command_offensive"
card.text = "+Charge\n+Shield\n+5 Health"
card.name = "Superior Order"

function card.execute(state, args)
    return mech.execute(
        state,
        mech.charge, {target = args.target},
        mech.shield, {target = args.target}
    )
end

function card.targets(state, id)
    local p = state:position(id)
    local targets = state
        :position()
        :filter(function(k, v) return type(k) == "number" end)
        :filter(function(k, v) return k * p > 0 end)
        :values()
    return targets
end

function card.animate(handle, context, epic, args, resolve)
    local epoch = mech.tail_state(epic)
    local sprite_user = context.sprites[args.user]
    sprite_user:set_animation("use")
    sprite_user.mirror = common.turn_towards(
        epoch.state, args.user, args.target
    )
    common.wait_for_hitbox(handle, sprite_user.on_hitbox, "cast")

    resolve(unpack(epic))
    handle:wait(0.7)
    sprite_user:set_animation("idle")
    handle:wait(sprite_user.on_loop)
    handle:wait(0.1)
    sprite_user.mirror = common.turn_towards(
        epoch.state, args.user
    )
end

return card
