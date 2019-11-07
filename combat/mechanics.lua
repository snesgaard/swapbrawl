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
    args = args:set("real_damage", args.damage)

    local on_damage = state:read("echo/on_damage")

    local history = list()
    local info
    -- Reactions goes here
    for i, id in ipairs(on_damage.order or {}) do
        local f = on_damage.func[id]
        args, info, state = f(state, id, args)
        history[#history + 1] = make_epoch(id, state, info)
    end

    -- Final state damage calculation

    local charged = state:read("actor/charge/" .. args.user)
    local shielded = state:read("actor/shield/" .. args.target)

    local health = state:read("actor/health/" .. args.target)
    local actual_damage = math.min(health, args.real_damage)
    actual_damage = charged and actual_damage * 2 or actual_damage
    actual_damage = shielded and actual_damage * 0 or actual_damage
    local next_health = health - actual_damage

    local info = {
        damage = actual_damage, target = args.target,
        charged = charged, shielded = shielded,
        health = next_health,
        user = args.user
    }
    state = state:write("actor/health/" .. args.target, next_health)
    state = state:write("actor/shield/" .. args.target, false)
    state = state:write("actor/charge/" .. args.user, false)

    history[#history + 1] = make_epoch("damage_dealt", state, info)

    return history
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
    history[#history + 1] = make_epoch("damage_dealt", state, info)

    return history
end

function mech.ailment_damage(state, args)
    local on_ailment_damage = state:read("echo/on_ailment_damage") or {}

    local history = list()
    -- Reactions goes here
    for i, id in ipairs(on_ailment_damage) do
        local f = on_ailment_damage.func[id]
        args, info, state = f(state, id, args)
        history[#history + 1] = make_epoch(id, state, info)
    end

    local target = args.target
    local ailment = args.ailment
    local dmg = args.damage

    local function format_path(target, dst)
        return string.format("ailment/%s/%s/%s", ailment, dst, target)
    end

    local res = state:read(format_path(target, "resistance")) or 1
    local damage = state:read(format_path(target, "damage")) or 0

    local function handle_damage()
        damage = damage + dmg
        if damage >= res then
            local duration = args.duration or 3
            -- Increase resistance (consider doubling instead maybe)
            res = res + 1
            local next_state = state
                :write(format_path(target, "resistance"), res)
                :write(format_path(target, "damage"), 0)
                :write(format_path(target, "duration"), duration)
            local info = dict{
                target = args.target, ailment = args.ailment, success = true,
            }
            return next_state, info
        else
            local next_state = state:write(
                format_path(target, "damage"), damage
            )

            local info = dict{
                target = args.target, ailment = args.ailment, success = false,
            }
            return next_state, info
        end
    end

    history[#history + 1] = make_epoch("ailment_damage", handle_damage())

    -- Insert reactions after this
    return history
end

function mech.charge(state, args)
    args.charge = args.charge or true
    local state, history = mech.invoke_echo(state, args, "echo/on_charge")

    local charge = state:read("actor/charge/" .. args.target)
    local next_state = state:write("actor/charge/" .. args.target, args.charge)

    local info = {
        target = args.target,
        charged = not charge and args.charge,
        removed = charge and not args.charge
    }

    history[#history + 1] = make_epoch("charged", next_state, info)

    return history
end

function mech.shield(state, args)
    args.shield = args.shield or true
    local state, history = mech.invoke_echo(state, args, "echo/on_shield")

    local shield = state:read("actor/shield/" .. args.target)
    local next_state = state:write("actor/shield/" .. args.target, args.shield)

    local info = {
        target = args.target,
        shielded = not shield and args.shield,
        removed = shield and not args.shield
    }

    history[#history + 1] = make_epoch("shielded", next_state, info)

    return history
end

function mech.tail_state(epic, state)
    return epic[#epic]:reduce(
        function(a, b)
            return b.state or a
        end, state
    )
end

return mech
