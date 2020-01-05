local common = require "actor.common"
local buff = require "combat.buff"

local actor = {}

actor.icon = {"art/icons", "mage"}

actor.atlas = "art/main_actors"

actor.animations = {
    idle = "mage_idle",
    evade = "mage_dash/evade",
    dash = "mage_dash/dash",
    idle2chant = "mage_cast/idle2chant",
    chant = "mage_cast/chant",
    chant2cast = "mage_cast/chant2cast",
    cast = "mage_cast/cast",
    cast2idle = "mage_cast/cast2idle",
}

function actor.basestats()
    return {
        health = 10,
        --stamina = 100,
        agility = 3
    }
end

actor.combo = {
    A={"chant_aegis", "aegis"},
    W={"chant_firewall", "firewall"},
    S={"chant_mirror_of_body", "mirror_of_body"},
    D={"lifedrain"}
}

local buffs = {}

buffs.lifedrain = {
    name = "Lifedrain",
    type = "body",
    help = "Heals light damage on every attack.",
    ["combat.mechanics:damage"] = function(id, state, info, args)
        if id ~= args.user then return end
        return {
            path="combat.mechanics:heal",
            args={
                heal=1,
                user=args.user,
                target=args.user
            }
        }
    end,
    icon = "art/ui:buff_icons/lifedrain",
}

buffs.mirror_soul = {
    name="Soul Mirror",
    type="soul",
    help="Whenever an ally gains a weapon or body enchantment, clone it.",
    ["combat.buff:apply"] = function(id, state, info, args)
        if id == args.target or args.mirror_soul then
            return
        end
        if state:position(id) * state:position(args.target) < 0 then
            return
        end
        if args.buff.type ~= "weapon" and args.buff.type ~= "body" then
            return
        end


        return {
            path="combat.buff:apply",
            args={
                buff=args.buff,
                target=id,
                mirror_soul=true
            }
        }
    end
}

actor.actions = {}

local actions = actor.actions

actions.chant_mass_shield = common.declare_chant(
    "Chant: Mass Shield", "Prepare casting Mass Shield."
)
actions.chant_firewall = common.declare_chant(
    "Chant: Firewall", "Prepare casting Firewall."
)
actions.chant_empower = common.declare_chant(
    "Chant: Empower", "Prepare casting Empower."
)
actions.chant_lifedrain = common.declare_chant(
    "Chant: Lifedrain", "Prepare casting Lifedrain."
)
actions.chant_mirror_soul = common.declare_chant(
    "Chant: Mirror Soul", "Prepare casting mirror soul."
)

actions.mirror_soul = {
    name = "Soul Mirror",
    target = {type="single", side="same"},
    help = "Casts Soul Enchantment: Soul Mirror.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=target, buff=buffs.mirror_soul}
        }
    end,
    animation = common.declare_cast_animation()
}

actions.mass_shield = {
    name = "Mass Shield",
    target = {type="side", side="same"},
    help = "Grants SHIELD to all allies.",
    transform = function(state, user, ...)
        local actions = list(...)
            :map(function(target)
                return  {
                    path="combat.mechanics:shield",
                    args={target=target}
                }
            end)
        return unpack(actions)
    end,
    animation = common.declare_cast_animation()
}

actions.firewall = {
    name = "Firewall",
    target = {type="single", side="other"},
    help = "Deal medium damage thrice.",
    transform = function(state, user, target)
        local function damage(tag)
            return {
                path="combat.mechanics:damage", args={
                    user=user, target=target, damage=10
                }, tag=tag
            }
        end
        return damage("A"), damage("B"), damage("C")
    end,
    animation = common.declare_cast_animation(function(root, epic, user, target)
        local target_sprite = get_sprite(root, target)
        local sfx = target_sprite:child(require "sfx.flame")
        local tags = {"A", "B", "C"}
        for i, tag in ipairs(tags) do
            local init = epic[tag]
            local stop = epic[tags[i + 1]]  or (#epic + 1)
            List.iter(
                epic,
                function(epoch) root:broadcast(epoch) end,
                init, stop - 1
            )
            event:sleep(0.35)
        end
        sfx:stop()
    end)
}

actions.empower = {
    name = "Empower",
    target = {type="single", side="same"},
    help = "Grants CHARGE.",
    transform = function(state, user, target)
        return {
            path = "combat.mechanics:charge", args={target=target}
        }
    end,
    animation = common.declare_cast_animation()
}

actions.lifedrain = {
    name = "Lifedrain",
    target = {type="single", side="same"},
    help = "Cast Weapon Enchantment: Lifedrain.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=user, buff=buffs.lifedrain}
        }
    end,
    animation = common.declare_cast_animation()
}

actions.chant_aegis = common.declare_chant(
    "Chant: Aegis", "Prepare casting Aegis."
)

actions.aegis = {
    name = "Aegis",
    target = {type="single", side="same"},
    help = "Light heal and grant SHIELD.",
    transform = function(state, user, target)
        return {
            path="combat.mechanics:heal",
            args={target=target, user=user, heal=5}
        }, {
            path="combat.mechanics:shield",
            args={target=target}
        }
    end,
    animation = common.declare_cast_animation()
}

actions.chant_mirror_of_body = common.declare_chant(
    "Chant: Mirror of Body", "Prepare casting Mirror of Body."
)

actions.mirror_of_body = {
    name = "Mirror of Body",
    target = {type="single", side="same"},
    help = "Dispel Body Enchantment from target.\nTarget's ally gains the Enchantment.",
    transform = function(state, user, target)
        local body_buff = buff.read(state, "body", target)
        if not body_buff then return end

        local allies = state:allies(target)
        local transforms = {
            {
                path="combat.buff:remove",
                args={target=target, type="body"}
            }
        }
        for _, id in pairs(allies) do
            transforms[#transforms + 1] = {
                path="combat.buff:apply",
                args={target=id, buff=body_buff}
            }
        end

        return unpack(transforms)
    end
}

return actor
