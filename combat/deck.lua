local MAX_HAND_SIZE = 10

local deck = {}

function deck.draw_card(state, args)
    local draw = state:read("deck/draw")
    local hand = state:read("deck/hand")

    if #draw <= 0 then
        local info = {
            desired_draw = args.cards,
            cards = list(),
            reason = "empty_draw"
        }
        list(mech.make_epoch("draw_card"), state, info))
    end



    local actual_draw = math.min(#draw, args.cards, MAX_HAND_SIZE - #hand)

    local cards_drawn = draw:sub(actual_draw)
    local remain_draw = draw:sub(actual_draw, #draw)

    hand = hand + cards_drawn

    local info = {
        desired_draw = args.cards,
        cards = cards_drawn,
    }

    local next_state = state
        :write("deck/draw", remain_draw)
        :write("deck/hand", hand)

    return list(mech.make_epoch("card_draw", next_state, info))
end

function deck.discard_card(state, args)
    local hand = state:read("deck/draw")
    local discard = state:read("deck/discard")

    local info = {
        desired_discard = args.discard
    }

    if #hand <= 0 then
        info.cards = list()
        return list(mech.make_epoch("discard_card"), state, info)
    end

    local actual_discard = math.min(#hand, args.discard)
    local indices = list().range(#hand)
        :shuffle()
        :sub(actual_discard)
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
    info.cards = discarded_ids

    local next_state = state
        :write("deck/hand", hand)
        :write("deck/discard", discard)

    return list(mech.make_epoch("discard_card"), state, info)
end

return deck
