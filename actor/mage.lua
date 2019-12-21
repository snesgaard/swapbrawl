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
            sprite:queue("idle2chant", "chant")
            event:sleep(0.5)
        end
    }
end

actions.chant_mass_shield = declare_chant("Chant: Mass Shield", "Prepare casting Mass Shield.")
actions.chant_firewall = declare_chant("Chant: Firewall", "Prepare casting Firewall.")

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
    animation = function(root, epic, user)
        local sprite = get_sprite(root, user)
        sprite:queue({"chant2cast", loop=false})
        event:wait(sprite, "finish")
        root:broadcast(unpack(epic))
        sprite:queue("cast")
        event:sleep(0.7)
        sprite:queue("cast2idle", "idle")
    end
}

return actor
