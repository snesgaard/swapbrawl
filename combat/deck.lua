local MAX_HAND_SIZE = 7

local deck = {}

function deck.create(state, card)
    local function get_name()
        if not card.name then return "NoName" end
        return type(card.name) == "function" and card:name() or card.name
    end

    local id = id_gen.register(get_name())

    if card.state then
        state = card.initstate(state, id)
    end
    state = state:write("card/type/" .. id, card)
    return state, id
end

function deck.draw_card(state, args)
    local id = args.id
    local draw = state:read("deck/draw/" .. id) or list()
    local hand = state:read("deck/hand/" .. id) or list()
    local discard = state:read("deck/discard/" .. id) or list()

    if #draw <= 0 then
        local info = {
            desired_draw = args.cards,
            cards = list(),
            reason = "empty_draw",
            id = args.id
        }
        list(mech.make_epoch("draw_card", state, info))
    end

    if args.cards > #draw then
        draw = draw + discard:shuffle()
        discard = list()
    end

    local actual_draw = math.min(args.cards, #draw)

    local cards_drawn = draw:sub(1, actual_draw)
    local remain_draw = draw:sub(actual_draw + 1 , #draw)

    hand = hand + cards_drawn
    local to_discard = math.max(0, #hand - MAX_HAND_SIZE)
    local discarded_cards = list()

    if to_discard > 0 then
        discarded_cards = hand:sub(1, to_discard)
        discard = discard + discarded_cards
        hand = hand:sub(to_discard + 1, #hand)
    end


    local info = {
        desired_draw = args.cards,
        cards = cards_drawn,
        discards = discarded_cards,
        id = args.id
    }

    local next_state = state
        :write("deck/draw/" .. id, remain_draw)
        :write("deck/discard/" .. id, discard)
        :write("deck/hand/" .. id, hand)

    return list(mech.make_epoch("card_draw", next_state, info))
end

function deck.discard_hand(state, args)
    local id = args.target
    local hand = state:read("deck/hand/" .. id) or list()
    return deck.discard_card(state, {id = id, discard = #hand})
end

function deck.discard_card(state, args)
    local id = args.id
    local hand = state:read("deck/hand/" .. id) or list()
    local discard = state:read("deck/discard/" .. id) or list()

    local info = {
        desired_discard = args.discard,
        id = args.id
    }

    if #hand <= 0 then
        info.cards = list()
        return list(mech.make_epoch("discard_card", state, info))
    end

    local actual_discard = math.min(#hand, args.discard)

    local indices = list().range(#hand)
        :shuffle()
        :sub(1, actual_discard)
        :sort()

    -- Delete in reverse order to ensure index validity
    local discarded_ids = list()
    for i = #indices, 1, -1 do
        local index = indices[i]
        local id = hand[index]
        hand = hand:erase(index)
        discard = discard:insert(id)
        discarded_ids[#discarded_ids + 1] = id
    end

    info.indices = indices
    info.discards = discarded_ids

    local next_state = state
        :write("deck/hand/" .. id, hand)
        :write("deck/discard/" .. id, discard)

    return list(mech.make_epoch("discard_card", next_state, info))
end

function deck.reset(state, args)
    local id = args.id
    local draw = state:read("deck/draw/" .. id) or list()
    local hand = state:read("deck/hand/" .. id) or list()
    local discard = state:read("deck/discard/" .. id) or list()

    local info = {id = args.id}

    local next_state = state
        :write("deck/hand/" .. id, list())
        :write("deck/discard/" .. id, list())
        :write("deck/draw/" .. id, (draw + hand + discard):shuffle())

    return list(mech.make_epoch("reset_card", state, info))
end

return deck
