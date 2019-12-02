local actorsetup = require "combat.setup"
local turn = require "combat.turn_queue"
local target = require "combat.target"
local deck = require "combat.deck"
local combo = require "combat.combotree"
local ailments = require "combat.ailments"
require "combat.update_state"

function remap(node)
    node.__remap_handle = dict()

    if not node.remap then return end

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

local function actor_order(a, b)
    local ax = a.__transform.pos.x - (a.priority and 2000 or 0)
    local bx = b.__transform.pos.x - (b.priority and 2000 or 0)
    return ax > bx
end

local function broadcast(root, ...)
    for key, epoch in pairs({...}) do
        event(epoch.id, epoch.state, epoch.info, epoch.args, root)
    end
end

local function update_state(data, ...)
    local state, epic = data.state:transform(...)
    broadcast(data, unpack(epic))
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
    data.actors:set_order(actor_order)
    data.sfx = data:child()
    --root.actors.__transform.scale = vec2(2, 2)
    data.ui = data:child()
    data.ui.number_server = data.ui:child(require "ui.number_server")
    data.ui.target_marker = data:child(require "sfx.marker")

    data.ui.turn = data.ui:child(require "ui.turn_queue")
    data.ui.turn.__transform.pos = vec2(gfx.getWidth() - 400, gfx.getHeight() * 0.25)

    data.ui.command = data.ui:child(require "ui.key_cross")

    data.ui.command.__transform.pos = vec2(gfx.getWidth() * 0.35, 150)

    data.ui.help = data.ui:child(require "ui.helpbox")
    data.ui.help.__transform.pos = vec2(gfx.getWidth() - 400, 50)
    data.ui.help:set_size(350)
    data.ui.help:set_text("This is an attack!")

    remap(data)
    remap(data.ui.turn)
    remap(data.ui.number_server)

    for _, id in ipairs(party_ids + foes_ids) do
        actorsetup.init_actor_visual(data, state, id)
    end

    data.party_ids = party_ids
    data.foes_ids = foes_ids

    data.state = state


end

local pickers = {}


function pickers.action(data, id, opt)
    -- Setup
    while true do
        local key = event:wait("keypressed")
        local u_key = key:upper()
        if opt.combo[key] then return key end
        if opt.combo[u_key] then return u_key end
    end
end


function pickers.target(data, user, opt)
    local action = opt.combo[opt.action]
    if not action or not action.target then
        error("Action unknown or no target data")
    end

    local target_data = action.target
    local actor_data = target.init(data.state, user, target_data)
    data.ui.target_marker:positions_from_actor(
        data.state, target.read_all(actor_data)
    )

    -- Setup
    while true do
        local key = event:wait("inputpressed")
        if key == "left" then
            actor_data.target = target.left(target_data, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "right" then
            actor_data.target = target.right(target_data, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "swap" then
            actor_data.target = target.jump(target_data, actor_data)
            data.ui.target_marker:positions_from_actor(
                data.state, target.read_all(actor_data)
            )
        elseif key == "confirm" then
            -- Teardown
            data.ui.target_marker:clear()
            return target.read_all(actor_data)
        elseif key == "abort" then
            -- Teardown
            data.ui.target_marker:clear()
            return
        end
    end
end

local function default_ability(path)
    local parts = string.split(path, '.')
    return {
        name=parts[#parts], target={type="single", side="other"}
    }
end

local function load_ability(type_info, path)
    if not type_info then
        return default_ability(path)
    end
    local actions = type_info.actions or {}
    return actions[path] or default_ability(path)
end

local function stunned_ability()
    return default_ability("**Stunned**")
end

local function ai_turn(data, next_id)
    local ai = require "combat.ai"
    local next_ai_state, action, targets = ai.update(data.state, next_id)
    data.state = ai.write_state(data.state, next_id, next_ai_state)
    action = load_ability(data.state:type(next_id), action)
    local args = {action=action, target=targets}
    log.info(
        "Action picked %s %s %s", next_id, action.name, tostring(targets)
    )
    update_state(data, {path="combat.turn_queue:push", args=args})
end

local function stunned_turn(data, next_id)
    local args = {action=stunned_ability()}
    log.info("User <%s> is stunned", next_id)
    update_state(data, {path="combat.turn_queue:push", args=args})
end

local function player_turn(data, next_id)
    -- TODO Need to call pick_action later
    local action = "foo"
    local target = {"bar", "baz"}
    local opt = {
        action_index = nil,
        targets = nil,
        hand = data.state:read(join("deck/draw_pile", next_id)),
    }

    local type_info = data.state:type(next_id)
    local combo_path = dict(combo.get_actions(data.state, next_id))

    opt.combo = combo_path:map(curry(load_ability, type_info))

    local combo_text = opt.combo
        :map(function(data)
            return data.name or "FooBar"
        end)
    data.ui.command:set_text(combo_text)
    data.ui.command:show()

    while not opt.targets do
        data.ui.help:set_text()
        data.ui.command:select()
        opt.action = pickers.action(data, next_id, opt)
        local help = opt.combo[opt.action].help
        data.ui.help:set_text(help)
        data.ui.command:select(opt.action)
        opt.targets = pickers.target(data, next_id, opt)
    end

    data.ui.help:set_text()
    data.ui.command:select()
    data.ui.command:hide()
    local action = opt.combo[opt.action]

    local args = {action=action, target=opt.targets, key=opt.action}
    log.info("Action picked %s %s %s", next_id, action.name, tostring(opt.targets))
    update_state(data, {path="combat.turn_queue:push", args=args})
end

local function turn(data)
    local next_id = require("combat.turn_queue").next_pending(data.state)
    if not next_id then return end
    local place =  data.state:position(next_id)
    if ailments.is_stunned(data.state, next_id) then
        stunned_turn(data, next_id)
    elseif place > 0 then
        player_turn(data, next_id)
    else
        ai_turn(data, next_id)
    end
    return turn(data)
end


local function execute(data, action, user, targets, key)
    if key then
        data.state = data.state:map(join("combo", user), combo.traverse, key)
    end
    if not action.transform then return end

    log.info("Executing %s for %s -> %s", action.name, user, key)
    local t = action.transform
    local next_state, epic = data.state:transform(
        t(data.state, user, unpack(targets))
    )
    if next_state and epic then
        data.state = next_state
        if action.animation then
            data:focus_actor(user)
            action.animation(data, epic, user, unpack(targets))
        else
            data:broadcast(unpack(epic))
        end
    end
    log.info("Execution completed")
end

local function execute_queue(data)
    local next_action = require("combat.turn_queue").next_action(data.state)
    if not next_action then return end

    -- TODO retargeting
    -- TODO Transform action
    log.info("Executing action %s", next_action.id)
    execute(
        data, next_action.action, next_action.id, next_action.target,
        next_action.key
    )

    update_state(data, {path="combat.turn_queue:pop"})

    return execute_queue(data)
end

local function end_of_round(data)
    local actors = data.state:read("turn/done")
        :map(function(v) return v.id end)

    for _, id in pairs(actors) do
        local args = {target=id}
        update_state(data, {path="combat.ailments:end_of_round", args=args})
    end

end

local function round(data)
    -- setup new round
    update_state(data, {path="combat.turn_queue:new_turn"})
    -- Select actions
    turn(data)
    --event:sleep(1.0)
    execute_queue(data)
    end_of_round(data)
end

local flow = {}

function flow:create(party, foes)
    party = party or list("fencer")
    foes = foes or list("golem")
    setup(self, party, foes)
end

function flow:combat()
    while true do
        round(self)
    end
end

function flow:execute(action, user, targets)
    if not targets then
        targets = target.random(self.state, user, action.target)
    end
    return self:fork(execute, action, user, targets)
end

flow.broadcast = broadcast

function flow:focus_actor(id)
    local n = self.actors[id]
    if not n then
        log.warn("No actor name %s", id)
        return
    end
    for _, node in pairs(self.actors) do
        -- TODO could probably be faster
        if type(node) == "table" then
            node.priority = nil
        end
    end
    n.priority = true
    self.actors:__make_order()
end

function flow:test(settings)
    settings.origin = true
    settings.disable_navigation = true
    self:fork(self.combat)
end

flow.remap = {}

flow.remap["combat.mechanics:damage"] = function(self, state, info, args)
    local sprite = get_sprite(self, info.target)
    sprite:shake()

    if info.shielded and sprite.shield then
        sprite.shield:halt()
        sprite.shield = nil
    end

    local sprite = get_sprite(self, args.user)
    if info.charged and sprite.charge then
        sprite.charge:halt()
        sprite.charge = nil
    end
end

flow.remap["combat.mechanics:true_damage"] = function(self, state, info, args)
    local sprite = get_sprite(self, info.target)
    sprite:shake()
end

flow.remap["combat.mechanics:shield"] = function(self, state, info, args)
    local sprite = get_sprite(self, info.target)
    if info.shielded and not sprite.shield then
        sprite.shield = sprite:child(require "sfx.shield")
    end
    if info.removed and sprite.shield then
        sprite.shield:halt()
        sprite.shield = nil
    end
end


flow.remap["combat.mechanics:charge"] = function(self, state, info, args)
    local sprite = get_sprite(self, info.target)
    if info.charged and not sprite.charge then
        sprite.charge = sprite:child(require "sfx.charge")
    end
    if info.remove and sprite.charge then
        sprite.charge:halt()
        sprite.charge = nil
    end
end

flow.remap["combat.ailments:stun_damage"] = function(self, state, info, args)
    local sprite = get_sprite(self, args.target)
    local shape = sprite:shape()
    local x, y = 0, -shape.h - 20
    if info.activated and not sprite.stun then
        sprite.stun = sprite:child(require "sfx.ailment.stun")
        sprite.stun.__transform.pos = vec2(x, y)
    end
end

flow.remap["combat.ailments:poison_damage"] = function(self, state, info, args)
    local sprite = get_sprite(self, args.target)
    local shape = sprite:shape()
    local x, y = 0, -shape.h - 20
    if info.activated and not sprite.poison then
        sprite.poison = sprite:child(require "sfx.ailment.poison")
        sprite.poison.__transform.pos = vec2(x, y)
    end

    sprite:child(require "sfx.ailment.poison_damage", shape.w, shape.h)
end

flow.remap["combat.ailments:burn_damage"] = function(self, state, info, args)
    local sprite = get_sprite(self, args.target)
    local shape = sprite:shape()
    local x, y = 0, -shape.h * 0.5

    local n = sprite:child(require "sfx.ailment.burn_damage", shape.w, shape.h)
    n.__transform.pos.y = y

    if info.activated then
        local n = sprite:child(require "sfx.explosion")
        n.__transform.pos.y = y
    end

end

flow.remap["combat.ailments:end_of_round"] = function(self, state, info, args)
    local sprite = get_sprite(self, args.target)
    for key, finished in pairs(info.finished) do
        if sprite[key] and finished then
            sprite[key]:destroy()
            sprite[key] = nil
        end
    end
end

return flow
