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
        agility = 20,
    }
end

fencer.combo = {
    root = {
        W = "blunt_strike_I",
        D = "slash_I",
        A = "potion",
        up = "toxic_oil",
        left = "power_oil",
        right = "blast_oil"
    },
    blunt_strike_I = {
        W = "blunt_strike_II",
        A = "potion",
        S = "backhop"
    },
    slash_I = {
        W = "blunt_strike_I",
        D = "cross_cut",
        A = "potion",
        S = "backhop"
    },
    cross_cut = {
        W = "blunt_strike_I",
        D = "brilliant_blade",
        S = "backhop",
        A = "potion"
    },
    brilliant_blade = {
        W = "blunt_strike_I",
        S = "backhop"
    },
    blunt_strike_II = {
        A = "potion",
        S = "backhop"
    },
    backhop = {
        A = "triple_trouble",
        D = "lunge"
    }
}

fencer.actions = dict()

local actions = fencer.actions

local animation = require "combat.animation"

actions.lunge = {
    name = "Lunge",
    target = {type="single", side="other"},
    help = "Deal heavy damage.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=15, user=user, target=target}
        }
    end
}

actions.blunt_strike_I = {
    name = "Blunt Strike I",
    target = {type="single", side="other"},
    help = "Deal light damage and stun.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
        }, {
            path="combat.ailments:stun_damage",
            args={damage=1, user=user, target=target},
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

actions.blunt_strike_II = {
    name = "Heavy Blunt Strike",
    target = {type="single", side="other"},
    help = "Deal medium damage and stun.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=8, user=user, target=target},
        }, {
            path="combat.ailments:stun_damage",
            args={damage=1, user=user, target=target},
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
    name = "Slash",
    target = {type="single", side="other"},
    help = "Deal light damage.",
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

actions.cross_cut = {
    name = "Cross Cut",
    target = {type="single", side="other"},
    help = "Attack twice, dealing light damage.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
            tag="first"
        }, {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
            tag="second"
        }
    end,
    animation = function(root, epic, user, target)
        local opt1 = {
            on_impact = function()
                for i = epic.first, epic.second - 1 do
                    root:broadcast(epic[i])
                end
            end,
            wait = 0.1
        }
        local opt2 = {
            on_impact = function()
                for i = epic.second, #epic do
                    root:broadcast(epic[i])
                end
            end
        }
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(root, epic[1].state, user, target, opt1)
        animation.attack(root, epic[1].state, user, target, opt2)
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


actions.brilliant_blade = {
    name = "Brilliant Blade",
    target = {type="single", side="other"},
    help = "Deal medium damage and heal yourself.",
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
    help = "Gain SHIELD.",
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
    help = "Light healing.",
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

actions.flash_bang = {
    name = "Flash Bang",
    target = {type="single", side="other"},

    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=3, user=user, target=target}
        }, {
            path="combat.ailments:stun_damage",
            args={damage=2, target = target}
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
            normal="flashbang/normal"
        }

        local sfx_node = root.sfx:child(require "sfx/ballistic", anime, "art/props")

        local opt = {}
        function opt.on_impact()
            local n = root.sfx:child(require "sfx.explosion")
            n.__transform.pos = stop_pos
            root:broadcast(unpack(epic))
        end

        sfx_node:travel(start_pos, stop_pos, opt)
        event:wait(sfx_node, "finish")

        animation.throw_return(root, user)
    end
}

actions.flash_burn = {
    name = "Flash & Burn",
    target = {type="single", side="other"},

    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target},
            tag="bang_dmg"
        }, {
            path="combat.ailments:stun_damage",
            args={damage=2, target = target},
            tag="bang_stun"
        }, {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target},
            tag="burn_dmg"
        }, {
            path="combat.ailments:burn_damage",
            args={damage=2, target = target},
            tag="burn_burn"
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
            normal="flashbang/normal"
        }
        local flash_opt = {
            on_impact = function()
                local n = root.sfx:child(require "sfx.explosion")
                n.__transform.pos = stop_pos
                root:broadcast(epic[epic.bang_dmg], epic[epic.bang_stun])
            end
        }
        local burn_opt = {
            is_linear = true,
            on_impact = function()
                local n = root.sfx:child(require "sfx.flame_gust")
                n.__transform.pos = stop_pos
                for i = epic.burn_dmg, #epic do
                    root:broadcast(epic[i])
                end
            end
        }

        local sfx_node = root.sfx:child(
            require "sfx/ballistic", anime, "art/props"
        )
        sfx_node:travel(start_pos, stop_pos, flash_opt)
        event:wait(sfx_node, "finish")
        local hitbox, user_sprite, target_sprite = animation.throw(
            root, state, user, {}, target
        )
        local sfx_node = root.sfx:child(
            require "sfx/ballistic", anime, "art/props"
        )
        sfx_node:travel(start_pos, stop_pos, burn_opt)
        event:wait(sfx_node, "finish")
        event:sleep(0.4)

        animation.throw_return(root, user)
    end
}

actions.triple_trouble = {
    name = "Triple Trouble",
    target = {type="single", side="other"},
    help = "Attack thrice, dealing light damage.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
            tag="first"
        }, {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
            tag="second"
        }, {
            path="combat.mechanics:damage",
            args={damage=4, user=user, target=target},
            tag="third"
        }
    end,

    animation = function(root, epic, user, target)
        function make_opt(init, stop, wait)
            local opt = {wait=wait}
            function opt.on_impact()
                for i = init, stop do
                    root:broadcast(epic[i])
                end
            end
            return opt
        end
        --animation.melee_attack(root, epic[1].state, user, opt, target)
        animation.approach(root, epic[1].state, user, target)
        animation.attack(
            root, epic[1].state, user, target,
            make_opt(epic.first, epic.second - 1, 0.1)
        )
        animation.attack(
            root, epic[1].state, user, target,
            make_opt(epic.second, epic.third - 1, 0.2)
        )
        animation.attack(
            root, epic[1].state, user, target, make_opt(epic.third, #epic, 0.5)
        )
        animation.fallback(root, epic[1].state, user)
    end
}

actions.toxic_oil = {
    name = "Toxic Oil",
    target = {type="self", side="same"},
    help = "Weapon attacks will deal poison damage.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=target, buff=fencer.buffs.toxic_oil}
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


fencer.buffs = {}
local buffs = fencer.buffs

buffs.toxic_oil = {
    type = "weapon",
    effect = function(state, user, target)
        print("yeeee")
        return {path="combat.ailments:poison_damage", args={target=target}}
    end
}

buffs.power_oil = {
    type = "weapon",
    damage = function(state, user, target)
        return 5
    end
}

buffs.blast_oil = {
    type = "weapon",
    effect = function(state, user, target)
        return {path="combat.ailments:burn_damage", args={target=target}}
    end
}



return fencer
