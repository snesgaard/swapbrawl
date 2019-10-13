local combat_position = require "combat.position"

local function is_number(key, val)
    return type(key) == "number"
end

local function get_init_target(target_data, actors)
    local same_side = target_data.side == "same"
    local foes = actors.foes
    local friends = actors.friends
    local is_foe = actors.user_place < 0
    local friend_init = is_foe and friends:head() or friends:tail()
    local foe_init = is_foe and foes:tail() or friends:head()
    if target_data.type == "self" then
        return actors.user
    elseif target_data.type == "single" then
        return same_side and friend_init or foe_init
    elseif target_data.type == "side" then
        return same_side and friend_init or foe_init
    elseif target_data.type == "all" then
        return same_side and friend_init or foe_init
    else
        error(string.format("unknown type %s", target_data.type))
    end
end


local function get_subtargets(target_data, actors)
    local subtargets = {}

    local function f(id, friends, foes)
        if target_data.type == "self" then
            return list()
        elseif target_data.type == "single" then
            return list()
        elseif target_data.type == "side" then
            return friends:erase(friends:argfind(id))
        elseif target_data.type == "all" then
            local all = friends + foes
            return all:erase(all:argfind(id))
        else
            error(string.format("unknown type %s", target_data.type))
        end
    end

    for _, id in ipairs(actors.friends) do
        subtargets[id] = f(id, actors.friends, actors.foes)
    end

    for _, id in ipairs(actors.foes) do
        subtargets[id] = f(id, actors.foes, actors.friends)
    end

    return subtargets
end

local target = {}

function target.init(state, user, target_data)
    local position = state:position()
    local user_place = position[user]

    if not user_place then
        error(string.format("User %s not in position", user))
    end

    local friends = position
        :filter(is_number)
        :filter(function(place)
            return place * user_place > 0
        end)
        :values()
        :sort(function(a, b) return position[a] > position[b] end)

    local foes = position
        :filter(is_number)
        :filter(function(place)
            return place * user_place < 0
        end)
        :values()
        :sort(function(a, b) return position[a] > position[b] end)

    local actors = dict{
        friends=friends, foes=foes, user=user, user_place=user_place
    }

    actors.target = get_init_target(target_data, actors)
    actors.subtargets = get_subtargets(target_data, actors)

    return actors
end

local function swap(a, b) return b, a end

local function shift_target(target_data, actors, shift)
    local friend_index = actors.friends:argfind(actors.target)
    local foe_index = actors.foes:argfind(actors.target)

    local active = foe_index and actors.foes or actors.friends
    local inactive = foe_index and actors.friends or actors.foes

    local index = friend_index or foe_index

    local next_index = index + shift

    if next_index < 1 then
        next_index = #inactive
        active, inactive = swap(active, inactive)
    elseif #active < next_index then
        next_index = 1
        active, inactive = swap(active, inactive)
    end

    return active[next_index]
end

function target.left(target_data, actors)
    local id = actors.target

    if target_data.type == "self" then return id end

    return shift_target(target_data, actors, -1)
end

function target.jump(target_data, actors)
    local friends = actors.friends
    local foes = actors.foes
    local friend_index = friends:argfind(actors.target)
    local foe_index = foes:argfind(actors.target)

    local is_foe = actors.user_place < 0
    local friend_init = is_foe and friends:head() or friends:tail()
    local foe_init = is_foe and foes:tail() or friends:head()

    return foe_index and friend_init or foe_init
end

function target.right(target_data, actors)
    local id = actors.target

    if target_data.type == "self" then return id end

    return shift_target(target_data, actors, 1)
end

function target.read(actors)
    return target_data.target
end

function target.read_all(actors)
    local id = actors.target
    local s = actors.subtargets[id] or list()
    return list(id, unpack(s))
end


return target
