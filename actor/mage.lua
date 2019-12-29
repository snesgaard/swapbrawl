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
    S={"chant_empower", "empower"},
    D={"chant_lifedrain", "lifedrain"}
}

local buffs = {}

buffs.lifedrain = {
    type = "weapon",
    ["combat.mechanics:damage"] = function(id, state, info, args)
        if id ~= args.user then return end
        return {
            path="combat.mechanics:heal",
            args={
                heal=4,
                user=args.user,
                target=args.user
            }
        }
    end,
    icon = function(x, y, w, h)
        gfx.setColor(0, 0, 0)
        gfx.rectangle("fill", x, y, w, h, 5)
    end,
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
        local damage = {
            path="combat.mechanics:damage", args={
                user=user, target=target, damage=10
            }
        }
        return damage, damage, damage
    end,
    animation = declare_animation(function(root, epic, user, target)
        local target_sprite = get_sprite(root, target)
        local sfx = target_sprite:child(require "sfx.flame")
        for _, epoch in ipairs(epic) do
            root:broadcast(epoch)
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
    help = "Weapon enchantment.\n\nHeals on every attack.",
    transform = function(state, user, target)
        return {
            path="combat.buff:apply",
            args={target=target, buff=buffs.lifedrain}
        }
    end,
    animation = declare_animation()
}

return actor
