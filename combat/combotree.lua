local combotree = {}

combotree.default_combo = {W = "pass"}

function combotree.init_state(state)
    state.combo = dict{}
end

function combotree.init(combo, combo_graph)
    return dict{
        state = dict{},
        graph = combo_graph
    }
end

function combotree.update(combo, action_key)
    local prev_state = combo.state[action_key] or 1
    local sequence = combo.graph[action_key]
    if not sequence then
        error(string.format("key %s undefined in combo", action_key))
    end
    local next_state = math.min(#sequence, prev_state + 1)

    -- If we wish to reset the combo
    return combo:set("state", dict{[action_key] = next_state})
end

function combotree.get_actions(state, id)
    local combo = state:read(join("combo", id))
    local graph = combo.graph
    local abilities = dict()
    for key, sequence in pairs(graph) do
        local state = combo.state[key] or 1
        abilities[key] = sequence[state]
    end
    return abilities
end

function combotree.reset(combo)
    return combo:set("state", dict())
end

return combotree
