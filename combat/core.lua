local state = require "combat.state"
local position = require "combat.position"
local turn_queue = require "combat.turn_queue"
local default_gfx_reaction = require "combat.default_gfx_reaction"
local number_server = require "ui.number_server"
local action_queue = require "combat.action_queue"

ability = require "ability"
mech = require "combat.mechanics"
sfx = require "sfx"

local function setup_actor_state(state, index, type)
    local typedata = require("actor." .. type)

    local id = id_gen.register(type)

    local stats = typedata.basestats()

    for key, value in pairs(stats) do
        state = state:write("actor/" .. key .. "/" .. id, value)
    end

    -- set max health and stamina if not set
    state = state
        :write("actor/max_health/" .. id, state:read("actor/health/" .. id))
        :write("actor/max_stamina/" .. id, state:read("actor/stamina/" .. id))
        :write("actor/type/" .. id, type)
        :map("position", position.set, id, index)

    log.info("Setting up <%s> on index <%i> as <%s>", type, index, id)

    return state, id
end

local function setup_stat_gfx(ui, state, index, id, type)
    local typedata = require("actor." .. type)
    local c = ui:child(require "ui.char_bar")
        :set_icon(typedata.icon and typedata.icon())
        :set_hp(state:health(id))
        :set_stamina(state:stamina(id))
    --c.__transform.pos = vec2(100 + (index - 1) * 250, 700)
    c.__transform.pos = vec2(100, 625 + (index - 1) * 80)
    ui.char_bars[id] = c
end

local function setup_actor_gfx(sprites, turnui, state, id, type)
    local typedata = require("actor." .. type)

    sprites[id] = sprites:child(Sprite, typedata.sprite())
        :set_animation("idle")

    local index = state:read("position/" .. id)

    sprites[id].__transform.pos = position.get_world(
        state:read("position"), id
    )
    if typedata.icon then
        turnui:register_icon(id, typedata.icon())
    end
    if index < 0 then
        sprites[id].__transform.scale.x = -sprites[id].__transform.scale.x
    end
end

local states = {}

local initialize = {}
local next_action = {}
local pick_action = {}
local wait_for_ui = {}
local run_script = {}
local execute_action = {}

local function sprite_order(a, b)
    return (a.priority or 0) < (b.priority or 0)
end

function initialize.setup_battle(context, party, foes)
    context.sprites = context:child()
    context.sprites:set_order(sprite_order)
    context.sfx = context:child()
    context.ui = context:child()
    context.ui.turn = context.ui:child(ui.turn_queue)
    context.ui.turn.__transform.pos = vec2(gfx.getWidth() - 100, 15)
    context.ui.char_bars = dict()
    context.ui.number_server = context.ui:child(number_server)
    context.icons = dict()
    context.state = state()
    context.anime_queue = context:child(action_queue)

    context.party_ids = list()
    context.foe_ids = list()

    for i, typepath in ipairs(party) do
        context.state, context.party_ids[i] = setup_actor_state(
            context.state, i, typepath
        )
        setup_actor_gfx(
            context.sprites, context.ui.turn, context.state,
            context.party_ids[i], typepath
        )
        setup_stat_gfx(
            context.ui, context.state, i, context.party_ids[i], typepath
        )
    end

    for i, typepath in ipairs(foes) do
        context.state, context.foe_ids[i] = setup_actor_state(
            context.state, -i, typepath
        )
        setup_actor_gfx(
            context.sprites, context.ui.turn, context.state,
            context.foe_ids[i], typepath
        )
    end

    context.turn_queue = turn_queue.create()
        :setup(
            context.party_ids + context.foe_ids,
            context.state:read("actor/agility")
        )

    context.ui.turn:advance(context.turn_queue)
end

function initialize.enter(fsm, context, level, party, foes)
    initialize.setup_battle(context, party, foes)
    --return fsm:swap(next_action)
end

function initialize.begin(fsm, context, level, player_stack)
    context.player_stack = player_stack
    return fsm:swap(next_action)
end

function next_action.enter(fsm, context, level)
    local id, action = context.turn_queue:next()
    -- TODO CHeck if actually valid actor: Alive, not stunned etc
    if not action or action.type == "ui" then
        return fsm:swap(wait_for_ui, id, action)
    elseif action.type == "script" then
        return fsm:swap(script_action, id, action)
    end
end

function wait_for_ui.enter(fsm, context, level, id, action)
    context.player_stack:invoke(
        "on_next_turn", id, context.state
    )
end

function wait_for_ui.on_action_select(fsm, context, level, id, action, ...)
    return fsm:swap(id, action, ...)
end

local function find_epoch_handler(context, ability, epoch)
    local id = epoch.id
    local a = ability[id]
    local f = default_gfx_reaction[id]
    return a or f
end

function execute_action.post_action(context, id)
    local state = context.state
    --Resolve poison
    local ailments = require "combat.ailments"
    return ailments.update(state, id)
end

function execute_action.execute(context, id, ability, ...)
    -- TODO This functions hould probably be split into two parts
    -- One that resolves the data and one that resovles teh animations
    local targets = list(...)
    local args = dict{
        target = #targets > 1 and targets or targets[1],
        user = id
    }
    local epic = ability.execute(
        context.state, args
    )

    context.state = epic[#epic]:reduce(
        function(a, b)
            return b.state or a
        end, context.state
    )

    local post_history = execute_action.post_action(context, id)
    -- TODO Might need rewriting if changed to EPIC format
    if #post_history > 0 then
        context.state = post_history:tail().state
    end

    -- TODO: Cache for making sure that every history has been resolved
    local function resolve(history, ...)
        if not history then return end

        for _, epoch in ipairs(history) do
            local f = find_epoch_handler(context, ability, epoch)
            if f then f(context, epoch.state, epoch.info) end
        end

        return resolve(...)
    end

    local turn_queue = context.turn_queue

    local function action(handle, context)
        context.ui.turn:advance(turn_queue)
        context.sprites[id].priority = 1
        context.sprites:__make_order()
        ability.animate(handle, context, epic, args, resolve)
        context.sprites[id].priority = nil
        context.sprites:__make_order()

        resolve(post_history)
    end

    return context.anime_queue:submit(action, context)
end

function execute_action.enter(fsm, context, level, id, ability, ...)
    -- TODO Update with actual ability delay here
    context.turn_queue = context.turn_queue:advance(
        id, context.state:agility(), 10
    )

    function context.anime_queue.on_handle_end()
        fsm:swap(next_action)
    end

    execute_action.execute(context, id, ability, ...)
end

states.initialize = initialize
states.pick_action = pick_action
states.execute_action = execute_action

return states
