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

function mech.damage(state, args)
    -- TODO perform initial stat calculation here
    args = args:set("real_damage", args.damage)

    local on_damage = state:read("echo/on_damage")

    local history = list()
    local info
    -- Reactions goes here
    for i, id in ipairs(on_damage) do
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

return mech
