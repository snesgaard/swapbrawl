local animation = require "combat.animation"

local actor = {}

actor.icon = {"art/icons", "vampire"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "vampire_idle",
    dash = "vampire_dash/dash",
    evade = "vampire_dash/evade",
    attack = "vampire_dash/attack",
    post_attack = "vampire_dash/post_attack",
    idle2chant = "vampire_dash/idle2chant",
    chant = "vampire_dash/chant",
    chant2cast = "vampire_dash/chant2cast",
    cast = "vampire_dash/cast",
    cast2idle = "vampire_dash/cast2idle",
}

function actor.basestats()
    return {
        health = 15,
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

actor.combo = {
    W = {"full_offensive"},
    A = {"minus_strike"},
    S = {"sanguine_shield"}
}

actor.actions = {}

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
}

actor.actions.full_offensive = {
    name = "Full Offensive",
    target = {type="single", side="other"},
    help = "Deal light damage and gain Body Enchantment: Regeneration",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={user=user, target=target, damage=5}
        }, {
            path = "combat.buff:apply",
            args={target=user, buff=buffs.regeneration}
        }
    end
}

return actor
