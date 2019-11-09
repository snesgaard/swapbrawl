local position = require "combat.position"
local anime = {}

function anime.melee_attack(root, state, user, target, on_impact)
    local su = get_sprite(root, user)
    local st = get_sprite(root, target)
    local pt = get_sprite(root, target)
    -- TODO: Add attack offset to this
    local begin_pos = position.get_world(state:position(), user)

    local offset = vec2(state:read(join("actor/offset", user)) or 0, 0)
    local final_pos = position.get_world(state:position(), target)
    local SPEED = 500
    local dist = (final_pos - begin_pos):length()
    local time = dist / SPEED

    su:queue{"dash"}
    local t = tween(time, su.__transform.pos, final_pos - offset)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    su:queue{"attack", "post_attack"}

    root:fork(function()
        --if not on_impact then return end
        local yes = event:wait(su, "slice/attack")
        print("ah shit, here we go")
    end)

    root:fork(function()
        while false do
            print(event:wait(su, "loop"))
        end
    end)

    event:wait(su, "finish")
    event:sleep(0.4)
    su:play{"evade"}
    local t = tween(time, su.__transform.pos, begin_pos)
        :ease(ease.sigmoid)
    event:wait(t, "finish")
    pu:play{"idle"}
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
