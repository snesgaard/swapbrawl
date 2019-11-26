local golem = {}

golem.icon = {"art/icons", "golem"}

golem.animations = {
    idle = "golem_idle",
    dash = "golem_dash/dash",
    evade = "golem_dash/evade",
    attack = "golem_dash/attack",
    post_attack = "golem_dash/post_attack",
    windup = "golem_dash/windup",
    idle2chant = "golem_cast/idle2chant",
    chant = "golem_cast/chant",
    chant2cast = "golem_cast/chant2cast",
    cast = "golem_cast/cast",
}

golem.atlas = "art/main_actors"

function golem.basestats()
    return {
        health = 10,
        agility = 10,
    }
end

return golem
