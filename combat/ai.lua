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
        return dict{}, "pass", {id}
    end
    local next_ai_state, action, targets = actor_type.ai(state, ai_state, id)
    return next_ai_state, action, targets
end

function ai.write_state(state, id, next_ai_state)
    return state:write(join("ai", id), next_ai_state)
end

return ai
