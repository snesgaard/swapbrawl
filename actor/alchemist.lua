local actor = {}

local animations = {}

function animations.idle(sprite, dt, prev)
    if prev == animations.cast then
        sprite:play(dt, "alchemist_item/cast2idle")
    end
    sprite:loop(dt, "alchemist_idle")
end

function animations.cast(sprite, dt, prev)
    sprite:play(dt, "alchemist_item/cast")
    sprite:loop(dt, "alchemist_item/post_cast")
end

function animations.chant(sprite, dt, prev)
    sprite:play(dt, "alchemist_item/idle2chant")
    sprite:loop(dt, "alchemist_item/chant")
end

function actor.sprite()
    return get_atlas("art/main_actors"), animations
end

function actor.icon()
    return get_atlas("art/icons"):get_animation("alchemist")
end

function actor.basestats()
    return {
        health = 20,
        --stamina = 100,
        agility = 2
    }
end

return actor
