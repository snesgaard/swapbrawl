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
    A={"chant_mass_shield", "mass_shield"},
    W={"chant_firewall", "firewall"},
    S={"mirror_soul"},
    D={"lifedrain"}
}

local buffs = {}

buffs.lifedrain = {
    name = "Lifedrain",
    type = "weapon",
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

buffs.blood_rage = {
    name="Blood Rage",
    type="body",
    help="Take light damage at the end of the round.",
    ["combat.turn_queue:end_of_round"] = function(id, state, info, args)
        return {
            path="combat.mechanics:true_damage",
            args={
                target=id,
                damage=4
            }
        }
    end
}

actor.actions = {}

local actions = actor.actions

local function declare_chant(name, help)
    return {
        name=name,
        help=help,
        target={type="self"},
        animation = function(root, epic, user)
            local sprite = get_sprite(root, user)
            if not sprite.chant then
                sprite.chant = sprite:child(require "sfx.chant")
            end
            sprite:queue("idle2chant", "chant")
            event:sleep(0.5)
        end
    }
end

actions.chant_mass_shield = declare_chant("Chant: Mass Shield", "Prepare casting Mass Shield.")
actions.chant_firewall = declare_chant("Chant: Firewall", "Prepare casting Firewall.")
actions.chant_empower = declare_chant("Chant: Empower", "Prepare casting Empower.")
actions.chant_lifedrain = declare_chant("Chant: Lifedrain", "Prepare casting Lifedrain.")
actions.chant_mirror_soul = declare_chant("Chant: Mirror Soul", "Prepare casting mirror soul.")

local function declare_animation(casting_func)
    return function(root, epic, user, ...)
        local sprite = get_sprite(root, user)
        sprite:queue({"chant2cast", loop=false})
        event:wait(sprite, "finish")
        sprite:queue("cast")

        if casting_func then
            casting_func(root, epic, user, ...)
        else
            root:broadcast(unpack(epic))
            event:sleep(0.7)
        end

        if sprite.chant then
            sprite.chant:halt()
            sprite.chant = nil
        end
        sprite:queue("cast2idle", "idle")
    end
end

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
    animation = declare_animation()
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
    animation = declare_animation()
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
    animation = declare_animation(function(root, epic, user, target)
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
    animation = declare_animation()
}

actions.lifedrain = {
    name = "Lifedrain",
    target = {type="single", side="same"},
    help = "Cast Weapon Enchantment: Lifedrain.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=target, buff=buffs.lifedrain}
        }
    end,
    animation = declare_animation()
}

return actor
