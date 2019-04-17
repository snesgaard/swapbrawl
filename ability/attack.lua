local position = require "combat.position"
local common = require "ability.common"

local ability = {}

function ability.execute(state, args)
    return mech.execute(
        state,
        "damage", mech.damage, dict{target=args.target, damage=2}
    )
end

function ability.targets(state, id)
    local function secondary_ids(state, target, others)
        local p = state:position(target)
        return others:filter(
            function(a)
                return p * state:position(a) > 0
            end
        )
    end
    local targets = state
        :position()
        :filter(function(k, v) return type(k) == "number" end)
        :values()
    return targets
end

function ability.animate(handle, context, epic, args, resolve)
    local epoch = epic.damage:tail()

    local pos_target = position.get_world(
        epoch.state:position(), epoch.info.target
    )
    local pos_user = position.get_world(
        epoch.state:position(), args.user
    )
    local sprite_user = context.sprites[args.user]
    local sprite_target = context.sprites[epoch.info.target]

    local offset = sprite_user:offset("attack")
    local attack_pos = pos_target - vec2(offset)

    local speed = 1200.0
    local time = (attack_pos - pos_user):length() / speed
    local tween = timer.tween(
        math.abs(time),
        {
            [sprite_user.__transform.pos] = attack_pos
        }
    ):ease(ease.inOutQuad)
    sprite_user:set_animation("dash")

    handle:wait(tween)

    sprite_user:set_animation("attack")

    local attack_hitbox = common.wait_for_hitbox(
        handle, sprite_user.on_hitbox, "attack", 1.0
    )
    resolve(epic.damage)
    local s = sprite_target:child(sfx("slash"))
    s.__transform.pos.y = -50

    handle:wait(0.45)

    sprite_user:set_animation("evade")

    local tween = timer.tween(
        math.abs(time),
        {
            [sprite_user.__transform.pos] = pos_user
        }
    ):ease(ease.inOutQuad)

    handle:wait(tween)

    sprite_user:set_animation("idle")
end


return ability
