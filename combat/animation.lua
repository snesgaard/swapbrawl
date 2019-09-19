local anime = {}

function anime.melee_attack(root, state, user, target, on_impact)
    local su = get_sprite(root, user)
    local pu = get_player(root, user)
    local st = get_sprite(root, target)
    local pt = get_sprite(root, target)
    -- TODO: Add attack offset to this
    local begin_pos = combat.position.get_world(state:position(), user)

    local offset = vec2(state:read(join("actor/offset", user)) or 0, 0)
    local final_pos = combat.position.get_world(state:position(), target)
    local SPEED = 500
    local dist = (final_pos - begin_pos):length()
    local time = dist / SPEED

    pu:play{"dash", loop=true}
    local t = tween(time, su.__transform.pos, final_pos - offset)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    pu:play{"attack", "post_attack", loop=true}

    root:fork(function()
        --if not on_impact then return end
        local yes = event:wait(pu, "attack")
        print("ah shit, here we go")
    end)

    event:wait(pu, "finish")
    event:sleep(0.4)
    pu:play{"evade", loop=true}
    local t = tween(time, su.__transform.pos, begin_pos)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    pu:play{"idle", loop=true}
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
