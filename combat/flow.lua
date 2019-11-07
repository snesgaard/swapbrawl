local actorsetup = require "combat.setup"
local turn = require "combat.turn_queue"
local target = require "combat.target"
require "combat.update_state"

local function remap(node)
    node.__remap_handle = dict()

    for key, func in pairs(node.remap or {}) do
        local function f(...) return func(node, ...) end
        node.__remap_handle[key] = event:listen(key, f)
    end

    local f = node.on_destroyed or identity

    function node.on_destroyed(self)
        for _, handle in ipairs(self.__remap_handle) do
            event:clear(handle)
        end
        return f(self)
    end
end

local function broadcast(...)
    for key, epoch in pairs({...}) do
        event(epoch.id, epoch.state, epoch.info, epoch.args)
    end
end

local function update_state(data, ...)
    local state, epic = data.state:transform(...)
    broadcast(unpack(epic))
    data.state = state
    return state, epic
end

local function setup(data, party, foes)
    local party_ids = party:map(id_gen.register)
    local foes_ids = foes:map(id_gen.register)

    local state = state.create()

    for index, id in ipairs(party_ids) do
        state = actorsetup.init_actor_state(state, id, index, party[index])
    end

    for index, id in ipairs(foes_ids) do
        state = actorsetup.init_actor_state(state, id, -index, foes[index])
    end

    --Node.draw_origin = true
    data.actors = data:child()
    --root.actors.__transform.scale = vec2(2, 2)
    data.ui = data:child()
    data.ui.target_marker = data:child(require "sfx.marker")

    data.ui.turn = data.ui:child(require "ui.turn_queue")
    data.ui.turn.__transform.pos = vec2(gfx.getWidth() - 300, 500)

    data.ui.card_hand = data.ui:child(require "ui.card_hand")
    data.ui.card_hand.__transform.pos = vec2(50, gfx.getHeight() * 0.5 + 100)

    remap(data.ui.turn)

    for _, id in ipairs(party_ids + foes_ids) do
        actorsetup.init_actor_visual(data, state, id)
    end

    data.state = state
end

local pickers = {}


function pickers.action(data, id, opt)
    -- Setup
    local hand = opt.hand
    if not opt.action_index then
        data.ui.card_hand:insert(data.state, unpack(hand))
    end
    local index = opt.action_index or 1
    data.ui.card_hand:fallback()
    data.ui.card_hand:select(index)
    while true do
        local key = event:wait("inputpressed")
        if key == "left" then
            index = index <= 1 and #hand or index - 1
            data.ui.card_hand:select(index)
        elseif key == "right" then
            index = index >= #hand and 1 or index + 1
            data.ui.card_hand:select(index)
        elseif key == "confirm" then
            data.ui.card_hand:trigger(true)
            -- Transition
            --return pick_target(data, action)
            return index
        end
    end
end


function pickers.target(data, user)
    local target_data_dummy = {type="self", side="other"}
    local actor_data = target.init(data.state, user, target_data_dummy)
    data.ui.target_marker:positions_from_actor(
        data.state, target.read_all(actor_data)
    )

    -- Setup
    while true do
        local key = event:wait("inputpressed")
        if key == "left" then
            actor_data.target = target.left(target_data_dummy, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "right" then
            actor_data.target = target.right(target_data_dummy, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "swap" then
            actor_data.target = target.jump(target_data_dummy, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "confirm" then
            -- Teardown
            data.ui.target_marker:clear()
            return 1
        elseif key == "abort" then
            -- Teardown
            data.ui.target_marker:clear()
            return
        end
    end
end



local function turn(data)
    local next_id = require("combat.turn_queue").next_pending(data.state)
    if not next_id then return end

    -- TODO Need to call pick_action later
    local action = "foo"
    local target = {"bar", "baz"}
    local opt = {
        action_index = nil,
        targets = nil,
        hand = data.state:read(join("deck/draw_pile", next_id))
    }

    while not opt.targets do
        opt.action_index = pickers.action(data, next_id, opt)
        opt.targets = pickers.target(data, next_id, opt)
    end

    data.ui.card_hand:clear()

    local card = data.state:read(join("cards/type", opt.hand[opt.action_index]))

    local args = {action=card.name, target=target}
    log.info("Action picked %s", next_id)
    update_state(data, {path="combat.turn_queue:push", args=args})
    return turn(data)
end



local function execute(data)
    local next_action = require("combat.turn_queue").next_action(data.state)
    if not next_action then return end

    log.info("Executing action %s", next_action.id)
    update_state(data, {path="combat.turn_queue:pop"})

    return execute(data)
end

local function round(data)
    -- setup new round
    update_state(data, {path="combat.turn_queue:new_turn"})
    -- Select actions
    turn(data)
    execute(data)
end

local flow = {}

function flow:create()
    local party = list("fencer", "alchemist", "mage")
    local foes = list("vampire", "vampress")
    self.data = Node.create()
    setup(self.data, party, foes)
    self:fork(self.combat)
end

function flow:combat()
    round(self.data)
end

function flow:__update(dt)
    self.data:update(dt)
end

function flow:__draw(x, y)
    self.data:draw(x, y)
end

function flow:test(settings)
    settings.origin = true
    settings.disable_navigation = true
end

return flow
