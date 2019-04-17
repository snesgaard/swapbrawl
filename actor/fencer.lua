local fencer = {}

local animations = {}

local offset = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "fencer_idle")
end

function animations.evade(sprite, dt)
    sprite:loop(dt, "fencer_dash/evade")
end

function animations.dash(sprite, dt)
    sprite:loop(dt, "fencer_dash/dash")
end

function animations.attack(sprite, dt)
    sprite:play(dt, "fencer_attack/attack")
    sprite:loop(dt, "fencer_attack/post_attack")
end

offset.attack = "fencer_attack/attack"

function fencer.sprite()
    return get_atlas("art/main_actors"), animations, offset
end

function fencer.icon()
    return get_atlas("art/icons"):get_animation("fencer_icon")
end

function fencer.basestats()
    return {
        health = 10,
        stamina = 100,
        agility = 4,
    }
end

return fencer
