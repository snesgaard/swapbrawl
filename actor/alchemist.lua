local actor = {}

actor.icon = {"art/icons", "alchemist"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "alchemist_idle",
    dash = "alchemist_dash/dash",
    evade = "alchemist_dash/evade",
    idle2chant = "alchemist_item/idle2chant",
    chant = "alchemist_item/chant",
    chant2cast = "alchemist_item/cast",
    cast = "alchemist_item/post_cast",
    cast2idle = "alchemist_item/cast2idle",
}

function actor.basestats()
    return {
        health = 20,
        --stamina = 100,
        agility = 2
    }
end

return actor
