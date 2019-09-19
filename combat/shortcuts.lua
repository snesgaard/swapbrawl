function get_sprite(root, id)
    local a = root.actors[id]
    if not a then
        log.warn("actor <%s> not defined", id)
        return
    end
    return a.sprite
end

function get_player(root, id)
    local a = root.actors[id]
    if not a then
        log.warn("actor <%s> not defined", id)
        return
    end
    return a.player
end

function get_actor(root, id)
    return root.actors[id]
end

function default_animation_graph()
    local graph = Node.create(animation_graph)
    graph:link{"idle", "idle2chant", "chant"}
    graph:link{"chant", "chant2cast", "cast"}
    graph:link{"cast", "cast2idle", "idle"}
    graph:link{"idle", "idle2item", "item"}
    graph:link{"item", "item2idle", "idle"}
    return graph
end
