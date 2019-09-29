local fencer = {}

local animations = {}

local offset = {}

fencer.attack_offset = "fencer_attack/attack"

function fencer.sprite()
    return get_atlas("art/main_actors"), animations, offset
end

fencer.icon = {"art/icons", "fencer_icon"}

fencer.animations = {
    idle = "fencer_idle",
    dash = "fencer_dash/dash",
    evade = "fencer_dash/evade",
    attack = "fencer_attack/attack",
    post_attack = "fencer_attack/post_attack",
    cast = "fencer_attack/item_use",
    post_cast = "fencer_attack/post_item",
    cast2idle = "fencer_attack/item2idle"
}

fencer.atlas = "art/main_actors"

local animation_post = {}
fencer.post_animation = animation_post

function animation_post.attack(api, frames, animation)
    api.append_attack(frames, animation)
end



function fencer.basestats()
    return {
        health = 10,
        --stamina = 100,
        agility = 4,
    }
end

return fencer
