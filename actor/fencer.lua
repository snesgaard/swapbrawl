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
    item = "fencer_attack/item_use",
    post_item = "fencer_attack/post_item",
    item2idle = "fencer_attack/item2idle"
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
        agility = 10,
    }
end

fencer.combo = {
    root = {
        W = "pommel_strike_I",
        D = "slash_I",
        A = "potion",
    },
    slash_I = {
        W = "pommel_strike_I",
        D = "slash_II",
        S = "backhop",
        A = "potion",
    },
    slash_II = {
        W = "pommel_strike_I",
        D = "solar_slash",
        S = "backhop",
        A = "potion"
    },
    solar_slash = {
        S = "backhop"
    },
    pommel_strike_I = {
        W = "pommel_strike_II",
        S = "backhop",
        A = "potion"
    },
    pommel_strike_II = {
        W = "kick",
        S = "backhop",
        A = "potion"
    },
    kick = {
        S = "backhop"
    },
    backhop = {
        A = "triple_trouble",
        D = "flying_kick"
    },
}

fencer.actions = dict()

local actions = fencer.actions

local animation = require "combat.animation"

actions.pommel_strike_I = {
    name = "Pommel Strike I",
    target = {type="single", side="other"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target},
        }, {
            path="combat.ailments:stun_damage",
            args={damage=2, user=user, target=target},
        }
    end,
    animation = function(root, epic, user, target)
        local opt = {}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, opt)
        animation.fallback(root, epic[1].state, user)
    end
}

actions.slash_I = {
    name = "Slash I",
    target = {type="single", side="other"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target}
        }
    end,
    animation = function(root, epic, user, target)
        local opt = {}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, opt)
        animation.fallback(root, epic[1].state, user)
    end
}

actions.slash_II = {
    name = "Slash II",
    target = {type="single", side="other"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=8, user=user, target=target}
        }
    end,
    animation = function(root, epic, user, target)
        local opt = {}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, opt)
        animation.fallback(root, epic[1].state, user)
    end
}


actions.solar_slash = {
    name = "Brilliant Blade",
    target = {type="single", side="other"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=10, user=user, target=target}
        }, {
            path="combat.mechanics:heal",
            args={heal=5, user=user, target=user}
        }
    end,
    animation = function(root, epic, user, target)
        local opt = {}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, opt)
        animation.fallback(root, epic[1].state, user)
    end
}

actions.backhop = {
    name = "Backhop",
    target = {type="self", side="same"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:shield",
            args={target=target}
        }
    end
}

actions.potion = {
    name = "Potion",
    target = {type="single", side="same"},

    transform = function(state, user, target)
        return {
            path="combat.mechanics:heal",
            args={heal=5, user=user, target=target}
        }
    end,

    animation = function(root, epic, user, target)
        local hitbox, user_sprite, target_sprite = animation.throw(
            root, state, user, {}, target
        )
        local start_pos = hitbox:center()
        local s = target_sprite:shape()
        local stop_pos = target_sprite.__transform.pos - vec2(0, s.h / 2)

        local anime = {
            normal="potion_red/idle",
            impact="potion_red/break"
        }

        local sfx_node = root.sfx:child(require "sfx/ballistic", anime, "art/props")

        local opt = {}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end

        sfx_node:travel(start_pos, stop_pos, opt)
        event:wait(sfx_node, "finish")

        animation.throw_return(root, user)
    end
}

actions.triple_trouble = {
    name = "Triple Trouble",
    target = {type="single", side="other"},

    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target}
        }, {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target}
        }, {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target}
        }
    end,

    animation = function(root, epic, user, target)
        function make_opt(epoch, wait)
            local opt = {wait=wait}
            function opt.on_impact()
                root:broadcast(epoch)
            end
            return opt
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, make_opt(epic[1], 0.1))
        animation.attack(root, epic[1].state, user, target, make_opt(epic[2], 0.2))
        animation.attack(root, epic[1].state, user, target, make_opt(epic[3], 0.5))
        animation.fallback(root, epic[1].state, user)
    end
}


return fencer
