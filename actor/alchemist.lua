local actor = {}

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "gunner_idle")
end

function actor.sprite()
    return get_atlas("art/main_actors"), animations
end

function actor.icon()
    return get_atlas("art/icons"):get_animation("alchemist")
end

function actor.basestats()
    return {
        health = 15,
        stamina = 100,
        agility = 2
    }
end

return actor
