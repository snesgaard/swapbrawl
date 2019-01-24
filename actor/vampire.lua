local actor = {}

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "vampire_idle")
end

function actor.sprite()
    return get_atlas("art/main_actors"), animations
end

return actor
