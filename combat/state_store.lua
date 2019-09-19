function make_epoch()
    return dict{id = id, state = state, info = info}
end

function make_history(...)
    return list(make_epoch(...))
end

local store = {}

function store:create()
    self._state = state.create()
    self.event = event_server()
end

function store:read()
    return self._state
end

-- Write this as mutator
function store:commit(state)
    self._state = state
end

function store:mutate(...)
    local function get_opts(tag, f, args, ...)
        if type(tag) == "function" then
            return nil, tag, f
        else
            return tag, f, args
        end
    end

    local function get_recur(tag, f, args, ...)
        if type(tag) == "function" then
            return args, ...
        else
            return ...
        end
    end

    local function inner_action(epic, state, ...)
        local tag, f, args = get_opts(...)

        if not f then
            return epic
        end

        -- Maybe add an event for args, in case something wants to change
        -- this
        local epoch = f(state, args)
        epic[#epic + 1] = epoch

        if tag and type(tag) ~= "number" then
            if not epic[tag] then
                epic[tag] = #epic
            else
                log.warn("Tag <%s> was already taken", tostring(tag))
            end
        end

        self.event(
            "/state_change/" .. epoch.id, epoch.state, epoch.info
        )
        local history, state = event:spin(epoch.state, epic)

        return inner_action(
            epic, state, get_recur(...)
        )
    end

    local epic = inner_action(dict(), state, ...)

    return epic:tail().state, epic
end

return store
