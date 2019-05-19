local state = require "combat.state"
local position = require "combat.position"
local turn_queue = require "combat.turn_queue"
local default_gfx_reaction = require "combat.default_gfx_reaction"
local number_server = require "ui.number_server"
local action_queue = require "combat.action_queue"
deck = require "combat.deck"

ability = require "ability"
mech = require "combat.mechanics"
sfx = require "sfx"

local tail_state = mech.tail_state

local function find_epoch_handler(context, ability, epoch)
    local id = epoch.id
    local a = ability[id]
    local f = default_gfx_reaction[id]
    return (a or c) or f
end

-- TODO: Cache for making sure that every history has been resolved
local function resolve(context, ability, history, ...)
    if not history then return end

    for _, epoch in ipairs(history) do
        local f = find_epoch_handler(context, ability, epoch)
        if f then f(context, epoch.state, epoch.info) end
        context.on_epoch(epoch.id, epoch.state, epoch.info)
    end

    return resolve(context, ability, ...)
end

local function setup_actor_state(state, index, actor)
    local type = actor.type
    local typedata = require("actor." .. type)

    local id = id_gen.register(type)

    local stats = typedata.basestats()

    for key, value in pairs(stats) do
        state = state:write("actor/" .. key .. "/" .. id, value)
    end

    state = state:write("actor/stamina/" .. id, 0)
    -- set max health and stamina if not set
    state = state
        :write("actor/max_health/" .. id, state:read("actor/health/" .. id))
        :write("actor/max_stamina/" .. id, 5)
        :write("actor/type/" .. id, type)
        :map("position", position.set, id, index)
    -- Setup deck
    local actor_deck = actor.deck or list()
    actor_deck = actor_deck:map(
        function(d)
            return require("cards." .. d)
        end
    )
    local cardids = list()
    for _, c in ipairs(actor_deck) do
        state, cardids[#cardids + 1] = deck.create(state, c)
    end
    state = state
        :write("deck/draw/" .. id, cardids:shuffle())
        :write("deck/discard/" .. id, list())
        :write("deck/hand/" .. id, list())

    log.info("Setting up <%s> on index <%i> as <%s>", type, index, id)

    return state, id
end

local function setup_stat_gfx(ui, state, index, id, actor)
    local type = actor.type
    local typedata = require("actor." .. type)
    local c = ui:child(require "ui.char_bar")
        :set_icon(typedata.icon and typedata.icon())
        :set_hp(state:health(id))
        :set_stamina(state:stamina(id))
    --c.__transform.pos = vec2(100 + (index - 1) * 250, 700)
    c.__transform.pos = vec2(100, 625 + (index - 1) * 80)
    ui.char_bars[id] = c
end

local function setup_actor_gfx(sprites, turnui, state, id, actor)
    local type = actor.type
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

local core = {}

local function sprite_order(a, b)
    return (a.priority or 0) < (b.priority or 0)
end

function core.create(context)
    context.on_state_change = event()
    context.on_animation_begin = event()
    context.on_animation_end = event()
    context.on_player_turn = event()
    context.on_epoch = event()
end

function core.setup_battle(context, party, foes, gfx_reactions)
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
    context.gfx_reactions = gfx_reactions

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

    for _, id in ipairs(context.party_ids) do
        local epic = mech.execute(
            context.state,
            deck.draw_card, {id=id, cards=5}
        )
        resolve(context, {}, unpack(epic))
        context.state = tail_state(epic, context.state)
    end

    --[[
    context.turn_queue = turn_queue.create()
        :setup(
            context.party_ids + context.foe_ids,
            context.state:read("actor/agility")
        )

    context.ui.turn:advance(context.turn_queue)

    ]]--
end

function core.get_state(context)
    return context.state
end

function post_action(context, id)
    local state = context.state
    --Resolve poison
    local ailments = require "combat.ailments"
    return ailments.update(state, id)
end

function core.play_card(context, user, cardid, ...)
    local stamina = context.state:read("actor/stamina/" .. user) or 0

    if stamina <= 0 then
        log.warn(
            "User <%s> cannot play card <%s> with stamina <%i>",
            user, cardid, stamina
        )
        return nil, context.state
    end


    local type = context.state:read("card/type/" .. cardid)
    local hand = context.state:read("deck/hand/" .. user)
    local discard = context.state:read("deck/discard/" .. user)

    stamina = stamina - 1

    context.state = context.state
        :write(
            "deck/hand/" .. user,
            hand:filter(function(id) return id ~= cardid end)
        )
        :write(
            "deck/discard/" .. user,
            discard:insert(cardid)
        )
        :write(
            "actor/stamina/" .. user,
            stamina
        )

    default_gfx_reaction.stamina_used(
        context, context.state, {user=user, stamina = stamina}
    )

    return core.execute(context, user, type, ...)
end

function core.execute(context, id, ability, ...)
    if not ability.execute then
        return {}, context.state
    end
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

    local post_history = post_action(context, id)
    -- TODO Might need rewriting if changed to EPIC format
    if #post_history > 0 then
        context.state = post_history:tail().state
    end

    context.on_state_change(context.state)

    local turn_queue = context.turn_queue

    local token = {}

    function curry_resolve(...)
        return resolve(context, ability, ...)
    end

    local function action(handle, context)
        context.on_animation_begin(token, id, ability, unpack(targets))
        context.sprites[id].priority = 1
        context.sprites:__make_order()
        ability.animate(handle, context, epic, args, curry_resolve)
        context.sprites[id].priority = nil
        context.sprites:__make_order()

        curry_resolve(post_history)

        context.on_animation_end(token, id, ability, unpack(targets))
    end

    context.anime_queue:submit(action, context)
    return token, context.state
end

function core.next_turn(context)
    if not context.turn_queue then
        -- Not initialized, build and then proceed
        context.turn_queue = turn_queue.create()
            :setup(
                context.party_ids + context.foe_ids,
                context.state:read("actor/agility")
            )

        context.ui.turn:advance(context.turn_queue)
    else
        local id = context.turn_queue:next()
        context.turn_queue = context.turn_queue:advance(
            id, context.state:agility(), 10
        )

    end

    -- TODO Resolve any post turn effects. E.g. poison
    -- Draw hand if palyer character
    local next = context.turn_queue:next()

    local epic = mech.execute(
        context.state,
        mech.stamina_heal, {target=next, heal=1, no_echo=true},
        deck.draw_card, {id=next, cards=1}
    )


    local final_state = epic[#epic]:reduce(
        function(a, b)
            return b.state or a
        end, context.state
    )
    context.state = final_state

    resolve(context, {}, unpack(epic))

    local function animate(handle)
        context.ui.turn:advance(context.turn_queue)
        -- Invoke next turn event here
        context.on_player_turn(final_state, next)
    end

    context.anime_queue:submit(animate)
end

return core
