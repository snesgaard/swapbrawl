local position = require "combat.position"
local projectile = require "combat.projectile"

local common = {}

function common.wait_for_hitbox(handle, topic, name, timeout)
    timeout = timeout or 3
    local pre = love.timer.getTime()
    local event_args = handle:wait(topic, timeout)
    if event_args.event == "timeout" then
        log.warn("Animation waiting timed out")
        return
    end
    local hitboxes = event_args[1]
    local dt = love.timer.getTime() - pre
    if not hitboxes[name] then
        return common.wait_for_hitbox(handle, topic, name, timeout - dt)
    else
        return hitboxes[name], hitboxes
    end
end

function common.turn_towards(state, id, target)
    if target then
        local pos_target = position.get_world(
            state:position(), target
        )
        local pos_id = position.get_world(
            state:position(), id
        )

        return pos_target.x < pos_id.x and -1 or 1
    else
        local index = state:position(id)
        return index > 0 and 1 or -1
    end
end

function common.melee_attack(
        handle, context, state, user, target, on_hit, opt
)
    opt = opt or {}
    local pos_target = position.get_world(state:position(), target)
    local pos_user = position.get_world(state:position(), user)
    local sprite_user = context.sprites[user]
    local sprite_target = context.sprites[target]

    local offset = sprite_user:offset("attack")
    local mirror = common.turn_towards(state, user, target)
    sprite_user.mirror = mirror
    local attack_pos = pos_target - vec2(offset * mirror)


    local speed = opt.speed or 1200.0
    local time = (attack_pos - pos_user):length() / speed
    local t = tween(
        math.abs(time), sprite_user.__transform.pos, attack_pos
    ):ease(ease.inOutQuad)
    sprite_user:set_animation("dash")

    handle:wait(t)

    sprite_user:set_animation("attack")

    local attack_hitbox = common.wait_for_hitbox(
        handle, sprite_user.on_hitbox, "attack", 1.0
    )
    print(attack_hitbox)

    on_hit(
        handle, attack_hitbox,
        {user = sprite_user, target = sprite_target, context = context, state},
        opt
    )

    sprite_user:set_animation("evade")

    local t = tween(
        math.abs(time), sprite_user.__transform.pos, pos_user
    ):ease(ease.inOutQuad)

    handle:wait(t)

    sprite_user:set_animation("idle")
    handle:wait(0.1)
    sprite_user.mirror = common.turn_towards(state, user)
end

function common.same_faction(state, target, others)
    local p = state:position(target)
    return others:filter(
        function(a)
            return p * state:position(a) > 0
        end
    )
end

function common.is_number(k, v)
    return type(k) == "number"
end

function common.ballistic(handle, context, state, opt, on_hit)
    local s = context.sprites[opt.user]

    s:set_animation("use")
    local mirror = common.turn_towards(state, opt.user, opt.target)
    s.mirror = mirror

    local cast_hitbox = common.wait_for_hitbox(
        handle, s.on_hitbox, "cast", 2.0
    )

    local potion_node = context.sfx:child(
        projectile.sprite, cast_hitbox:center(), opt.proj_idle,
        opt.proj_break
    )
    local pos_target = position.get_world(
        state:position(), opt.target
    )
    local st = context.sprites[opt.target]
    local h = st:height()
    handle:wait(
        projectile.ballistic(potion_node, -200, 0.7, pos_target - vec2(0, h))
    )
    potion_node.sprite:set_animation("impact")

    --resolve(unpack(epic))
    on_hit(handle)
    handle:wait(0.5)
    s:set_animation("idle")
    handle:wait(0.2)
    s.mirror = common.turn_towards(state, opt.user)
end

return common
