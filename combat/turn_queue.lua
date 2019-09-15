local turn_queue = {}

function turn_queue.init_state(state)
    state.turn = dict{
        delay = dict(),
        order = list()
    }
end

local function update_order(state, delay)
    local order = delay
        :keys()
        :sort(function(a, b)
            return (delay[a] or 0) < (delay[b] or 0)
        end)

    return state
        :write("turn/delay", delay)
        :write("turn/order", order)
end

local function read_delay_order(state)
    return state:read("turn/delay"), state:read("turn/order")
end

function turn_queue.take_turn(state, args, history)
    local id = args.id
    -- Agi should be 0 - 9
    local agi = state:agility(id)
    local factor = 1 + agi / 9.0
    local d = (args.delay or 0) / factor

    -- Invoke agi echo

    local delay = state:read("turn/delay")
    local order = state:read("turn/initiate")

    delay = delay:set(id, (delay[id] or 0) + d)
    order = order:sort(function(a, b)
        return (delay[a] or 0) < (delay[b] or 0)
    end)

    local next_state = state
        :write("turn/delay", delay)
        :write("turn/order", order)

    history[#history + 1] = make_epoch("take_turn", next_state, dict(args))
    return history
end

function turn_queue.insert(state, args, history)
    local delay = state("turn/delay")
    local order = state("turn/order")

    local next_state = update_order(delay:set(args.id, args.delay))

    local info = dict(args)

    history[#history + 1] = make_epoch("turn_insert", next_state, args)
    return history
end

function turn_queue.remove(state, args, history)
    local delay, order = read_delay_order(state)

    local next_state = update_order(delay:set(args.id))

    local info = dict(args)
    history[#history + 1] = make_epoch("turn_remove", next_state, args)
    return history
end

return turn_queue
