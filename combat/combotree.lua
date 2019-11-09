local combotree = {}

function combotree.update_state(state)
    state.combo = dict{}
end

function combotree.init(combo, graph)
    return dict{
        current = base.root,
        root = base.root,
        graph = base.graph
    }
end

function combotree.traverse(combo, action)
    local edges = combo.root[combo.current]

    if not edges then
        error("Edges of %s undefined", combo.current)
    end

    if not List.find(edges, action) then
        error("No edges between %s and %s", combo.current, action)
    end

    return combo:set("current", action)
end

function combotree.get_actions(state, id)
    local combo = state:read(join("combo", id))
    return combo.graph[combo.current]
end

function combotree.reset(combo)
    return combo:set("current", combo.root)
end

return combotree
