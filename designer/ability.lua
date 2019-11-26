
local function default_pick_user(state)
    return state:position()
        :filter(function(key) return type(key) == "number" end)
        :values()
        :head()
end

local function pick_user(ability, state)
    if ability.pick_user then
        return ability.__pick_user(state)
    else
        return default_pick_user(state)
    end
end

local function get_target_list(ability, state, user)
    if ability.targets then
        return ability.targets(state, user)
    else
        -- Just get all ids
        return state:position()
            :filter(function(key) return type(key) == "number" end)
            :values()
    end
end

local function pick_target(ability, state, user, target_list)
    if ability.__pick_target then
        return ability.__pick_target(state, user, target_list)
    else
        return target_list:shuffle():head()
    end
end

local function load_ability(ability_path)
    if not ability_path then return end

    return require(ability_path:gsub('.lua', ''))
end

local function split_path(path)
    return unpack(string.split(path, ':'))
end

local function load(arg)
    gfx.setBackgroundColor(0, 0, 0, 0)
    nodes = Node.create()


    function actor(t)
        return {type = t}
    end

    local actor_path, action_name = split_path(arg[1])

    nodes.battle = nodes:child(
        require("combat.flow"),
        list(actor_path, "vampire", "vampress"),
        list("mage", "alchemist")
    )

    if not action_name then return end

    local type_info = require("actor." .. actor_path)

    local actions = type_info.actions or {}
    local action = actions[action_name]

    if not action then return end

    nodes.battle:execute(action, nodes.battle.party_ids:head())
end

function love.load(arg)
    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end

    function lurker.postswap(f)
        load(arg)
    end
    load(arg)
end

function love.update(dt)
    require("lovebird").update()
    tween.update(dt)
    nodes:update(dt)
    lurker:update(dt)
    event:update(dt)
    event:spin()
end

function love.draw()
    nodes:draw()
end
