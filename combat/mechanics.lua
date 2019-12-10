local buff = require "combat.buff"

local mech = {}

function mech.identity(id, state, info)
    return make_history(id, state, info)
end

function mech.stamina_heal(state, args)
    local on_stamina_heal = state:read("echo/on_stamina_heal") or {}

    local info = {}

    local stamina = state:read("actor/stamina/" .. args.target)
    local max_stamina = state:read("actor/max_stamina/" .. args.target)

    local actual_heal = math.min(max_stamina - stamina, args.heal)
    local next_stamina = stamina + actual_heal
    local next_state = state:write(
        "actor/stamina/" .. args.target, next_stamina
    )
    local info = {
        heal = actual_heal, target = args.target,
        stamina = next_stamina
    }
    return next_state, info
end

function mech.heal(state, args)
    local on_heal = state:read("echo/on_heal") or {}

    local info = {}

    local health = state:read("actor/health/" .. args.target)
    local max_health = state:read("actor/max_health/" .. args.target)
    local actual_heal = math.min(max_health - health, args.heal)
    local next_health = health + actual_heal
    local next_state = state:write("actor/health/" .. args.target, next_health)
    local info = {
        heal = actual_heal, target = args.target,
        health = next_health
    }
    return next_state, info
end

function mech.damage(state, args)
    if not args.user then
        error("There must be a user defined!")
    end
    -- TODO perform initial stat calculation here
    args = Dictionary.set(args, "real_damage", args.damage or 0)

    -- Final state damage calculation
    local damage = args.damage
    local charged = state:read("actor/charge/" .. args.user)
    local shielded = state:read("actor/shield/" .. args.target)
    local health = state:read("actor/health/" .. args.target) or 0

    local weapon_buff = buff.weapon_buff(state, args.user) or {}

    if weapon_buff.damage then
        local weapon_damage = weapon_buff.damage(state, args.user, args.target)
        damage = damage + weapon_damage
    end

    local post_transforms = list()

    if weapon_buff.effect then
        local effects = list(weapon_buff.effect(state, args.user, args.target))
        post_transforms = post_transforms + effects
    end

    local actual_damage = math.min(health, damage)
    actual_damage = charged and actual_damage * 2 or actual_damage
    actual_damage = shielded and actual_damage * 0 or actual_damage
    local next_health = health - actual_damage

    local info = {
        damage = actual_damage, target = args.target,
        charged = charged, shielded = shielded,
        health = next_health,
        user = args.user,
        weapon_buff = weapon_buff
    }
    state = state:write("actor/health/" .. args.target, next_health)
    state = state:write("actor/shield/" .. args.target, false)
    state = state:write("actor/charge/" .. args.user, false)

    return state, info, post_transforms
end

function mech.true_damage(state, args)
    local history = list()
    local health = state:read("actor/health/" .. args.target)
    local actual_damage = math.min(health, args.damage)
    local next_health = health - actual_damage
    local info = {
        damage = actual_damage, target = args.target,
        health = next_health
    }
    state = state:write("actor/health/" .. args.target, next_health)

    return state, info
end

function mech.end_of_turn()

end

function mech.charge(state, args)
    args.charge = args.charge or true

    local charge = state:read("actor/charge/" .. args.target)
    local next_state = state:write("actor/charge/" .. args.target, args.charge)

    local info = {
        target = args.target,
        charged = not charge and args.charge,
        removed = charge and not args.charge
    }

    return next_state, info
end

function mech.shield(state, args)
    args.shield = args.shield or true

    local shield = state:read("actor/shield/" .. args.target)
    local next_state = state:write("actor/shield/" .. args.target, args.shield)

    local info = {
        target = args.target,
        shielded = not shield and args.shield,
        removed = shield and not args.shield
    }

    return next_state, info
end

function mech.tail_state(epic, state)
    return epic[#epic]:reduce(
        function(a, b)
            return b.state or a
        end, state
    )
end

return mech
