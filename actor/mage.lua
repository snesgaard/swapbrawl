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

actor.combo = {
    A={"chant_mass_shield", "mass_shield"}
}

actor.actions = {}

local actions = actor.actions

actions.chant_mass_shield = {
    name = "Chant: Mass Shield",
    target = {type="self"},
    animation = function(root, epic, user)
        local sprite = get_sprite(root, user)
        sprite:queue{"chant"}
    end
}

return actor
