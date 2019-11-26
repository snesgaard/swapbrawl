local position = require "combat.position"
local anime = {}

function anime.approach(root, state, user, target, opt)
    opt = opt or {}
    local su = get_sprite(root, user)
    -- TODO: Add attack offset to this
    local begin_pos = position.get_world(state:position(), user)

    local offset = su:attack_offset() * vec2(1, 0)
    local final_pos = position.get_world(state:position(), target)
    local SPEED = opt.speed or 1500
    local dist = (final_pos - begin_pos):length()
    local time = dist / SPEED

    su:queue{"dash"}
    local t = tween(time, su.__transform.pos, final_pos - offset)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
end

function anime.attack(root, state, user, target, opt)
    opt = opt or {}
    local on_impact = opt.on_impact or identity
    local su = get_sprite(root, user)
    local st = get_sprite(root, target)
    su:queue("attack", "post_attack")

    root:fork(function()
        --if not on_impact then return end
        local hitbox = event:wait(su, "slice/attack")
        on_impact(hitbox, su, st)
    end)

    event:wait(su, "finish")
    event:sleep(opt.wait or 0.4)
end

function anime.fallback(root, state, user, opt)
    opt = opt or {}
    local su = get_sprite(root, user)
    local begin_pos = position.get_world(state:position(), user)
    local SPEED = opt.speed or 1500
    local final_pos = su.__transform.pos
    local dist = (final_pos - begin_pos):length()
    local time = dist / SPEED
    su:queue("evade")
    local t = tween(time, su.__transform.pos, begin_pos)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    su:queue("idle")
end


function anime.melee_attack(root, state, user, opt, target)
    local on_impact = opt.on_impact or identity
    local su = get_sprite(root, user)
    local st = get_sprite(root, target)
    local pt = get_sprite(root, target)
    -- TODO: Add attack offset to this
    local begin_pos = position.get_world(state:position(), user)

    local offset = su:attack_offset() * vec2(1, 0)
    local final_pos = position.get_world(state:position(), target)
    local SPEED = 1500
    local dist = (final_pos - begin_pos):length()
    local time = dist / SPEED

    su:queue{"dash"}
    local t = tween(time, su.__transform.pos, final_pos - offset)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    su:queue("attack", "post_attack")

    root:fork(function()
        --if not on_impact then return end
        local hitbox = event:wait(su, "slice/attack")
        on_impact(hitbox, su, st)
    end)

    event:wait(su, "finish")
    event:sleep(0.4)
    su:queue("evade")
    local t = tween(time, su.__transform.pos, begin_pos)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    su:queue("idle")
end

function anime.cast(root, state, user, opt, ...)
    local targets = list(...)
    local on_cast = opt.on_cast or identity
    local timeout = opt.timeout or 30
    local user_sprite = get_sprite(root, user)
    local target_sprites = targets:map(curry(get_sprite, root))

    -- TODO adjust orientation
    user_sprite:queue("chant2cast", "cast")

    local token = {}

    root:fork(function()
        event:sleep(timeout)
        event(token, "finished")
    end)

    root:fork(function()
        local hitbox = event:wait(user_sprite, "slice/cast")
        on_cast(hitbox, user_sprite, unpack(target_sprites))
        event(token, "finished")
    end)

    event:wait(token, "finished")

    user_sprite:queue("cast2idle", "idle")
end

function anime.throw(root, state, user, opt, ...)
    local targets = list(...)
    local on_cast = opt.on_cast or identity
    local user_sprite = get_sprite(root, user)
    local target_sprites = targets:map(curry(get_sprite, root))

    user_sprite:queue("item", "post_item")

    local token = {}
    local hitbox = event:wait(user_sprite, "slice/cast")
    return hitbox, user_sprite, unpack(target_sprites)
end


function anime.throw_return(root, user)
    local user_sprite = get_sprite(root, user)
    user_sprite:queue("item2idle", "idle")
    event:wait(user_sprite, "finish")
end


function anime.append_attack(frames, animation)
    local index = frames:argfind(function(f)
        return f.slices.attack
    end)
    local time = frames
        :sub(1, index - 1)
        :map(function(f) return f.dt end)
        :reduce(function(a, b) return a + b end, 0)
    animation:track(event, {time}, {"attack"}, {call=true})
end

return anime
