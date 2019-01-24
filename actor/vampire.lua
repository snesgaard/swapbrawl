local actor = {}

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "vampire_idle")
end

function actor.sprite()
    return get_atlas("art/main_actors"), animations
end

function actor.icon()
    return get_atlas("art/icons"):get_animation("vampire")
end

function actor.basestats()
    return {
        health = 20,
        stamina = 100
    }
end

return actor
