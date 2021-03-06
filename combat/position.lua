local position = {}

local function get_default_center()
    return vec2(gfx.getWidth() / 2 - 200, gfx.getHeight() / 2 + 125)
end

local function get_default_offset()
    return vec2(145, 0)
end

function position.is_party(state, arg)
    local id, place = position.pairget(state, arg)
    return place > 0
end

function position.is_foe(state, arg)
    local id, place = position.pairget(state, arg)
    return place < 0
end

function position.pairget(state, arg)
    local res = state[arg]

    if not res then
        return
    elseif type(arg) == "string" then
        return arg, res
    else
        return res, arg
    end
end


function position.set(state, id, place)
    if state[place] then
        log.warn("Place %i was already taken", place)
        return state
    end

    local prev_place = state[id]
    if prev_place then
        state = state:set(id)
    end

    return state:set(id, place):set(place, id)
end

function position.remove(state, arg)
    local id, place = self.pairget(state, arg)

    if not id then
        log.warn("%s was not found", tostring(arg))
        return state
    end

    return state:set(id):set(value)
end

function position.swap(state, arg1, arg2)
    local id1, place1 = self:pairget(arg1)
    local id2, place2 = self:pairget(arg2)

    if not id1 or id2 then
        log.warn("Unknown pair %s %s", tostring(arg1), tostring(arg2))
        log.warn(
            "Details %s/%s  %s/%s", tostring(id1), tostring(place1),
            tostring(id2), tostring(place2)
        )
        return state
    end

    return state
        :set(id1, place2)
        :set(place2, id1)
        :set(id2, place1)
        :set(place1, id2)
end

function position.get_world(state, arg, opt)
    local opt = opt or {}
    local id, place = position.pairget(state, arg)

    local offset = opt.offset or get_default_offset()
    local center = opt.center or get_default_center()

    if not place then
        error(string.format("Id <%s> was not found", id))
        return
    end
    local offset = offset * place
    return center - offset
end

return position
