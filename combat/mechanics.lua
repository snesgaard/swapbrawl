local function make_epoch(id, state, info)
    return dict{id = id, state = state, info = info}
end

local mech = {}

mech.make_epoch = make_epoch

function mech.make_history(...)
    return list(make_epoch(...))
end

function mech.execute(state, ...)
    local function get_opts(tag, f, args, ...)
        if type(tag) == "function" then
            return nil, tag, f
        else
            return tag, f, args
        end
    end

    local function get_recur(tag, f, args, ...)
        if type(tag) == "function" then
            return args, ...
        else
            return ...
        end
    end

    local function inner_action(epic, state, ...)
        local tag, f, args = get_opts(...)

        if not f then
            return epic
        end

        local history = f(state, args)
        epic[#epic + 1] = history

        if tag and type(tag) ~= "number" then
            if not epic[tag] then
                epic[tag] = history
            else
                log.warn("Tag <%s> was already taken", tostring(tag))
            end
        end

        return inner_action(
            epic, history:tail().state, get_recur(...)
        )
    end

    return inner_action(dict(), state, ...)
end

function mech.identity(id, state, info)
    return mech.make_history(id, state, info)
end

function mech.heal(state, args)
    local on_heal = state:read("echo/on_heal") or {}

    local history = list()
    local info

    for i, id in ipairs(on_heal.order or {}) do
        local f = on_heal.func[id]
        args, info, state = f(state, id, args)
        history[#history + 1] = make_epoch(id, state, info)
    end

    local health = state:read("actor/health/" .. args.target)
    local max_health = state:read("actor/max_health/" .. args.target)
    local actual_heal = math.min(max_health - health, args.heal)
    local next_health = health + actual_heal
    local next_state = state:write("actor/health/")
    local info = {
        heal = actual_heal, target = args.target,
        health = next_health
    }
    history[#history + 1] = mech.make_epoch("healing_done", next_state, info)
    return history
end

function mech.damage(state, args)
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

    local health = state:read("actor/health/" .. args.target)
    local actual_damage = math.min(health, args.real_damage)
    local next_health = health - actual_damage
    local info = {
        damage = actual_damage, target = args.target,
        health = next_health
    }
    state = state:write("actor/health/" .. args.target, next_health)

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

return mech
