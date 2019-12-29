local ai = {}

function ai.init_state(state)
    state.ai = dict{}
end

function ai.read_state(state, id)
    return state:read(join("ai", id))
end

function ai.update(state, id)
    local actor_type = state:type(id)
    local ai_state = ai.read_state(state, id)

    if not actor_type.ai then
        return "pass", {id}, dict{}
    end

    local action, targets, next_ai_state = actor_type.ai(state, id, ai_state)

    if not action then
        return "pass", {id}, dict{}
    end

    return action, targets, next_ai_state
end

function ai.write_state(state, id, next_ai_state)
    return state:write(join("ai", id), next_ai_state)
end

return ai
