local actor = {}

actor.icon = {"art/icons", "vampire"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "vampire_idle",
    dash = "vampire_dash/dash",
    evade = "vampire_dash/evade",
    attack = "vampire_dash/attack",
    post_attack = "vampire_dash/post_attack",
    idle2chant = "vampire_dash/idle2chant",
    chant = "vampire_dash/chant",
    chant2cast = "vampire_dash/chant2cast",
    cast = "vampire_dash/cast",
    cast2idle = "vampire_dash/cast2idle",
}

function actor.basestats()
    return {
        health = 20,
        --stamina = 100
    }
end

return actor
