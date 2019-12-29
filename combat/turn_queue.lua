local turn_queue = {}

function turn_queue.init_state(state)
    state.turn = dict{
        pending = list(),
        order = list(),
        done = list(),
        number = 0
    }
end

local function is_valid(state, id)
    local health = state:health(id)
    local place = state:position(id)
    return health > 0 and math.abs(place) <= 3
end

function turn_queue.new_turn(state, args)
    -- TODO Filter based on HP values
    local function isnt_number(val) return type(val) ~= "number" end
    local function is_number(val) return not isnt_number(val) end
    local position = state:position()
    local actors = position
        :values()
        :filter(isnt_number)
        :filter(curry(is_valid, state))
    local seeds = {}
    for _, id in ipairs(actors) do
        -- TODO: Propery scaled RNG
        seeds[id] = state:agility(id) + rng()
    end
    local order = actors:sort(
        function(a, b)
            return seeds[a] < seeds[b]
        end
    )
    return state
        :write("turn/pending", order)
        :write("turn/order", list())
        :write("turn/done", list())
        :map("turn/number", function(n) return n + 1 end)
end

function turn_queue.end_of_turn(state, args)
    return state
end

function turn_queue.pending(state, args)
    return state:read("turn/pending")
end

function turn_queue.next_pending(state)
    return (state:read("turn/pending") or list()):head()
end

function turn_queue.push(state, args)
    local action, target, key = args.action, args.target, args.key
    local pending = state:read("turn/pending")
    local order = state:read("turn/order")
    local id = pending:head()
    -- Queue has been exhausted
    if not id then return state end
    local data = dict({action=action, target=target, id=id, key=key})
    return state
        :write("turn/pending", pending:body())
        :write("turn/order", order:insert(data, 1)), data
end

function turn_queue.next_action(state)
    return (state:read("turn/order") or list()):head()
end

function turn_queue.pop(state, args)
    local order = state:read("turn/order")
    local done = state:read("turn/done")
    return state
        :write("turn/order", order:body())
        :write("turn/done", done:insert(order:head()))
end

return turn_queue
