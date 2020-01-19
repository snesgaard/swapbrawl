
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
    return string.split(path, ':')
end

local function load(arg)
    gfx.setBackgroundColor(0, 0, 0, 0)
    nodes = Node.create()


    function actor(t)
        return {type = t}
    end

    local paths = split_path(arg[1])
    local actor_path = paths[1]

    nodes.battle = nodes:child(
        require("combat.flow"),
        list(actor_path, "vampire", "vampress"),
        list("mage", "alchemist")
    )

    local type_info = require("actor." .. actor_path)

    local actions = type_info.actions or {}

    local co = coroutine.create(function()
        for i = 2, #paths do
            local action = actions[paths[i]]
            if action then
                nodes.battle:execute(action, nodes.battle.party_ids:head())
                event:wait(nodes.battle, "exection_complete")
            end
        end
    end)
    coroutine.resume(co)
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
    gfx.setColor(0.1, 0.4, 0.4)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    gfx.setColor(1, 1, 1)
    nodes:draw()
end
