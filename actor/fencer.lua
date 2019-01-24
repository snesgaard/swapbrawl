local fencer = {}

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "fencer_idle")
end

function animations.evade(sprite, dt)
    sprite:loop(dt, "fencer_dash/evade")
end

function fencer.sprite()
    return get_atlas("art/main_actors"), animations
end

return fencer
