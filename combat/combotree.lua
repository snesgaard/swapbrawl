local combotree = {}

combotree.default_combo = {W = "pass"}

function combotree.init_state(state)
    state.combo = dict{}
end

function combotree.init(combo, combo_graph)
    return dict{
        state = combo_graph.__init__ or "root",
        graph = combo_graph
    }
end

function combotree.traverse(combo, action)
    local edges = combo.graph[combo.state]
    local default_state = combo.graph.__init__ or "root"

    if not edges then
        return combo:set("state", default_state)
    else
        local next_state = edges[action] or combo.graph.__init__
        -- TODO: Find a better way of etting the key from the path
        local parts = string.split(next_state, '.')
        local key = parts[#parts]
        -- Check if state is defined, else go back to root state
        local e = combo.graph[key]
        return combo:set("state", e and key or default_state)
    end
end

function combotree.get_actions(state, id)
    local combo = state:read(join("combo", id))
    local root = combo.graph.__init__ or "root"
    local next = combo.graph[combo.state] or combo.graph[root]
    return next or combotree.default_combo
end

function combotree.reset(combo)
    return combo:set("state", combo[combo.graph.__init__ or "root"])
end

return combotree
