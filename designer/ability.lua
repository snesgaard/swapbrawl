local core = require "combat.core"

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

function love.load(arg)
    gfx.setBackgroundColor(0, 0, 0, 0)
    nodes = Node.create()
    nodes.battle = nodes:child()

    local ability_path = arg[1]

    local ability = require(ability_path:gsub('.lua', ''))

    core.initialize.setup_battle(
        nodes.battle,
        {"fencer", "vampire", "vampress"},
        {"mage", "alchemist"}
    )

    local state = nodes.battle.state

    local user = pick_user(ability, state)

    local target_list, secondary = get_target_list(ability, state, user)

    secondary = secondary or function() end

    local target = pick_target(ability, state, user, target_list)



    local s = secondary(
        state, target,
        target_list:filter(function(id) return id ~= target end)
    )

    if type(s) == "table" then
        core.execute_action.execute(
            nodes.battle, user, ability, target, unpack(s)
        )
    else
        core.execute_action.execute(nodes.battle, user, ability, target, s)
    end
end

function love.update(dt)
    timer.update(dt)
    nodes:update(dt)
end

function love.draw()
    nodes:draw()
end
