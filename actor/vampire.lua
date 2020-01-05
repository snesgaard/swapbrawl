local animation = require "combat.animation"
local buff = require "combat.buff"
local common = require "actor.common"

local actor = {}

actor.icon = {"art/icons", "vampire"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "vampire_idle",
    dash = "vampire_dash/dash",
    evade = "vampire_dash/evade",
    attack = "vampire_dash/attack",
    post_attack = "vampire_dash/post_attack",
    idle2chant = "vampire_cast/idle2chant",
    chant = "vampire_cast/chant",
    chant2cast = "vampire_cast/chant2cast",
    cast = "vampire_cast/cast",
    cast2idle = "vampire_cast/cast2idle",
}

function actor.basestats()
    return {
        health = 20,
        --stamina = 100
        agility = 5,
    }
end

local buffs = {}

buffs.sanguine_shield = {
    name = "Sanguine Shield",
    type = "soul",
    help = "Gain CHARGE whenever you gain SHIELD.",
    ["combat.mechanics:shield"] = function(id, state, info, args)
        if id ~= args.target or not info.shielded then
            return
        end
        return {
            path="combat.mechanics:charge",
            args={target=id}
        }
    end,
}

buffs.regeneration = {
    name = "Regeneration",
    type = "body",
    help = "Light heal on the end of every round.",
    ["combat.turn_queue:end_of_turn"] = function(id, state, info, args)
        return {
            path="combat.mechanics:heal",
            args={target=id, heal=3}
        }
    end
}

buffs.blood_rage = {
    name="Blood Rage",
    type="body",
    help="Take light damage at the end of the round.\nCannot reduce health below 1.",
    ["combat.turn_queue:end_of_turn"] = function(id, state, info, args)
        return {
            path="combat.mechanics:true_damage",
            args={
                user=id,
                target=id,
                damage = function(state, args)
                    local health = state:health(args.target)
                    local base_damage = 4
                    return math.min(base_damage, health - 1)
                end
            }
        }
    end
}

actor.combo = {
    W = {"brace"},
    A = {"rage_strike"},
    S = {"sanguine_strike"},
    D = {"chant_sanguine_shield", "sanguine_shield"}
}

actor.actions = {}

actor.actions.chant_sanguine_shield = common.declare_chant(
    "Chant: Sanguine Shield", "Prepare casting Sanguine Shield."
)

actor.actions.sanguine_shield = {
    name = "Sanguine Shield",
    target = {type="self", side="same"},
    help = "Casts Soul Enchantment: Sanguine Shield.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=target, buff=buffs.sanguine_shield}
        }
    end,
    animation = common.declare_cast_animation()
}

actor.actions.brace = {
    name = "Brace",
    target = {type="self", side="other"},
    help = "Light heal and gain Body Enchantment: Regeneration",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:heal",
            args={user=user, target=user, heal=5}
        }, {
            path = "combat.buff:apply",
            args={target=user, buff=buffs.regeneration}
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

actor.actions.rage_strike = {
    name = "Rage Strike",
    target = {type="single", side="other"},
    help = "Deal light damage and gain Body Enchantment: Blood Rage",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={user=user, target=target, damage=5}
        }, {
            path="combat.buff:apply",
            args={target=user, buff=buffs.blood_rage}
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

actor.actions.sanguine_strike = {
    name = "Sanguine Strike",
    target = {type="single", side="other"},
    help = "Deal medium damage.\nAdditional if you have Body Enchantment: Blood Rage.",
    transform = function(state, user, target)
        local function damage(state, args)
            if buff.has(state, args.user, buffs.blood_rage) then
                return 12
            else
                return 5
            end
        end
        return {
            path="combat.mechanics:damage",
            args={user=user, target=target, damage=damage}
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

actor.actions.minus_strike = {
    name = "Minus Strike",
    target = {type="single", side="other"},
    help = "Deal your missing health in damage.",
    transform = function(state, user, target)
        local function damage(state, args)
            local hp, max_hp = state:health(args.user)
            return max_hp - hp
        end
        return {
            path="combat.mechanics:damage",
            args={user=user, target=target, damage=damage}
        }
    end
}

return actor
