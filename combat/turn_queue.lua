local turn_queue = {}

function turn_queue.init_state(state)
    state.turn = dict{
        pending = list(),
        order = list(),
        done = list(),
    }
end

function turn_queue.new_turn(state, args)
    -- TODO Filter based on HP values
    local function isnt_number(val) return type(val) ~= "number" end
    local actors = state:position():values():filter(isnt_number)
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
end

function turn_queue.next_actor(state)
    return (state:read("turn/pending") or list()):head()
end

function turn_queue.push(state, args)
    local action, target = args.action, args.target
    local pending = state:read("turn/pending")
    local order = state:read("turn/order")
    local id = pending:head()
    -- Queue has been exhausted
    if not id then return state end
    local data = {action=action, target=target, id=id}
    return state
        :write("turn/pending", pending:body())
        :write("turn/order", order:insert(1, data))
end

function turn_queue.pop(state, args)
    local order = state:read("turn/order")
    local done = state:read("turn/done")
    return state
        :write("turn/order", order:body())
        :write("turn/done", done:insert(oder:head()))
end

return turn_queue
