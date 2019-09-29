local actor = {}

actor.atlas = "art/main_actors"

actor.icon = {"art/icons", "vampress"}

actor.animations = {
    idle = "vampress_idle",
    dash = "vampress_dash/dash",
    evade = "vampress_dash/evade",
    idle2chant = "vampress_cast/idle2chant",
    chant = "vampress_cast/chant",
    chant2cast = "vampress_cast/chant2cast",
    cast = "vampress_cast/cast",
    cast2idle = "vampress_cast/cast2idle",
}

function actor.basestats()
    return {
        health = 10,
        --stamina = 100,
        agility = 3
    }
end

return actor
