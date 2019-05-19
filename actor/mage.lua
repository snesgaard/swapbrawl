local actor = {}

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "mage_idle")
end

function actor.sprite()
    return get_atlas("art/main_actors"), animations
end

function actor.icon()
    return get_atlas("art/icons"):get_animation("mage")
end

function actor.basestats()
    return {
        health = 10,
        --stamina = 100,
        agility = 3
    }
end

return actor
