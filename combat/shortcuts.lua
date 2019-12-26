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

function start_chant(root, id)
    local sprite = get_sprite(root, id)
    if not sprite.chant then
        sprite.chant = sprite:child(require "sfx.chant")
    end
end

function stop_chant(root, id)
    local sprite = get_sprite(root, id)
    if not sprite.chant then return false end
    sprite.chant:halt()
    sprite.chant = nil
    return true
end

function interrupt_chant(root, id)
    local sprite = get_sprite(root, id)
    if stop_chant(root, id) then
        sprite:queue("idle")
    end
end
