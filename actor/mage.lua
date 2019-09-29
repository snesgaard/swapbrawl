local actor = {}

actor.icon = {"art/icons", "mage"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "mage_idle",
    evade = "mage_dash/evade",
    dash = "mage_dash/dash",
    idle2chant = "mage_cast/idle2chant",
    chant = "mage_cast/chant",
    chant2cast = "mage_cast/chant2cast",
    cast = "mage_cast/cast",
    cast2idle = "mage_cast/cast2idle",
}

function actor.basestats()
    return {
        health = 10,
        --stamina = 100,
        agility = 3
    }
end

return actor
