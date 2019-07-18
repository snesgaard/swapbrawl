local position = require "combat.position"

local function create_default_cross(self)
    local keys = {
        up = "W",
        down = "S",
        left = "A",
        right = "D"
    }

    local name = {
        up = "Magick",
        left = "Attack",
        right = "Defend",
        down = "Item"
    }

    local icons = {
        left = "attack_bw",
        up = "magick_bw",
        down = "item_bw",
        right = "defend_bw"
    }

    local cross = self:child(require "ui.action_cross")
    cross:set_keys(keys)
    cross:set_texts(name)
    cross:set_icons(icons)
    return cross
end

local init = {}
local idle = {}
local action = {}
local target = {}
local submit = {}

local on_epoch_sub = {}

function on_epoch_sub.card_draw(fsm, context, level, state, info)
    if info.id ~= context.id then return end
    if not context.ui.card_hand then return end

    context.ui.card_hand:insert(state, unpack(info.cards))
    context.ui.card_hand:remove(unpack(info.discards))
    action.set_card_selection(
        context, math.clamp(
            context.select or 1, 1, math.max(1, #context.hand)
        )
    )
end

function on_epoch_sub.discard_card(fsm, context, level, state, info)
    if info.id ~= context.id then return end
    if not context.ui.card_hand then return end

    context.ui.card_hand:remove(unpack(info.discards))
    if context.select then
        action.set_card_selection(
            context, math.clamp(
                context.select, 1, math.max(1, #context.hand)
            )
        )
    end
end

local function on_epoch(fsm, context, level, id, state, info)
    local f = on_epoch_sub[id]
    if f then f(fsm, context, level, state, info) end
end

function init.enter(fsm, context, level)
    context.ui = context:child()
    context.ui.card_hand = context.ui:child(require "ui.card_hand")
    context.ui.card_hand.__transform.pos = vec2(325, 600)
    -- PATCH GFX Handlers

    return fsm:swap(idle)
end

function idle.enter(fsm, context, level)
end

function idle.on_next_turn(fsm, context, level, state, id)
    context.state = state
    context.id = id

    -- Setup hand
    context.hand = context.state:read("deck/hand/" .. id)
    context.ui.card_hand:insert(state, unpack(context.hand))

    action.set_card_selection(context, 1)
    return fsm:swap(action, state, id)
end

function action.set_card_selection(context, index)
    if not index or #context.hand <= 0 then
        context.ui.card_hand:select()
        context.select = nil
        return
    end
    index = math.clamp(index, 1, math.max(1, #context.hand))
    index = math.cycle(index, 1, #context.hand)
    local cardid = context.hand[index]

    context.select = index
    -- TODO check whether selection has actually arrived on screen
    context.ui.card_hand:select(cardid)
end


local function search_card_forward(context, select)
    if not select then return end
    local hand = context.hand
    for i = select + 1, #hand do
        local id = hand[i]
        if context.ui.card_hand:is_present(id) then return i end
    end
    for i = 1, select do
        local id = hand[i]
        if context.ui.card_hand:is_present(id) then return i end
    end
end

local function search_card_inverse(context, select)
    if not select then return end
    local hand = context.hand
    for i = select - 1, 1, -1 do
        local id = hand[i]
        if context.ui.card_hand:is_present(id) then return i end
    end
    for i = #hand, select, -1 do
        local id = hand[i]
        if context.ui.card_hand:is_present(id) then return i end
    end
end

function action.enter(fsm, context, level, state, id)
    context.ui.card_hand:fallback()
    context.state = state or context.state
    context.id = id or context.id
    context.hand = context.state:read("deck/hand/" .. id)
    context.select = context.select or search_card_forward(context, 0)
    action.set_card_selection(context, context.select)
end

local function get_id(context)
    return context.hand[context.select]
end

function action.keypressed(fsm, context, level, key)
    if key == "left" then
        local next = search_card_inverse(context, context.select)
        action.set_card_selection(context, next)
    elseif key == "right" then
        local next = search_card_forward(context, context.select)
        action.set_card_selection(context, next)
    elseif key == "space" and context.select then
        context.ui.card_hand:trigger()
        return fsm:swap(target, get_id(context))
    end
end

local function get_targets(state, id, ability)
    if ability.targets then
        return ability.targets(state, id)
    else
        return state
            :position()
            :filter(function(k, v) return type(k) == "number" end)
            :values()
    end
end

function target.enter(fsm, context, level, cardid)
    local cardtype = context.state:read("card/type/" .. cardid)
    context.ability = cardtype or require "ability.attack"
    context.cardid = cardid
    local target, second = get_targets(context.state, context.id, context.ability)
    context.ui.target_select = context.ui:child(
        require "ui.target_selection", target, context.state, context.id,
        second
    )
end

function target.keypressed(fsm, context, level, key, ...)
    context.ui.target_select:keypressed(key, ...)

    if key == "backspace" then
        return fsm:swap(action, context.state, context.id)
    elseif key == "space" then
        local targets = {context.ui.target_select:get_current()}
        return fsm:swap(submit, context.ability, targets)
    end
end

function target.exit(fsm, context, level)
    context.ui.target_select:destroy()
end

function submit.find_select(prev_hand, next_hand, prev_select)
    -- BUG When you discard and redraw a card from hand!!
    print(prev_hand, next_hand)
    -- Search backwards
    for i = prev_select - 1, 1, -1 do
        local index = next_hand:argfind(prev_hand[i])
        if index then return index end
    end

    for i = prev_select + 1, #prev_hand do
        local index = next_hand:argfind(prev_hand[i])
        if index then return index end
    end

    print("didnt get any more")
    return nil
end

function submit.enter(fsm, context, level, ability, targets)
    --context.ui.card_hand:select()
    --local _, state = fsm.submit_action(context.id, context.ability, targets)
    local token, state = fsm.play_card(
        context.id, context.cardid, unpack(targets)
    )
    if token then
        context.ui.card_hand:remove(context.cardid)
        context.select = submit.find_select(
            context.hand, state:read("deck/hand/" .. context.id), context.select
        )
    end

    return fsm:swap(action, state, context.id)
end

for _, t in pairs({target, submit, action}) do
    t.on_epoch = on_epoch
end
-- We need to be prepared for state changes?

return init
