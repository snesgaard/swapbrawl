local function get_user_card(state, id)
    local hand = state:read(join("deck/hand", id)) or list()
    local draw = state:read(join("deck/draw_pile", id)) or list()
    local discard = state:read(join("deck/discard_pile", id)) or list()
    return hand, draw, discard
end

local function set_user_card(state, id, hand, draw, discard)
    hand = hand or state:read(join("deck/hand", id))
    draw = draw or state:read(join("deck/draw_pile", id))
    discard = discard or state:read(join("deck/discard_pile", id))
    return state
        :write(join("deck/hand", id), hand)
        :write(join("deck/draw_pile", id), draw)
        :write(join("deck/discard_pile", id), discard)
end

local deck = {}

function deck.init_state(state)
    state.deck = dict{
        hand = dict{},
        discard_pile = dict{},
        draw_pile = dict{}
    }
    state.cards = dict{
        type = dict{}
    }
end

function deck.get(state, id)
    return state:read(join("cards/type", id))
end

function deck.create(state, card_type)
    local id = id_gen.register(card_type.name)
    local next_state = state:write(join("cards/type", id), card_type)
    return next_state, id
end

function deck.draw(state, args)
    local user = args.user
    local count = args.count
    local hand, draw, discard = get_user_card(state, user)

    count = math.min(count, #draw + #discard)

    local next_discard = discard
    if count > #draw then
        draw = draw + discard:shuffle()
        next_discard = list()
    end

    local drawn_cards = draw:sub(1, count)
    local next_draw = draw:sub(count, #draw)
    local next_hand = hand + drawn_cards

    local info = {drawn_cards = drawn_cards}
    return set_user_card(
        state, user, next_hand, next_draw, next_discard
    ), info
end

function deck.discard(state, args)
    local user = args.user
    local ids = args.ids
    local count = args.count

    local hand, draw, discard = get_user_card(state, user)

    if not ids then
        count = math.min(#hand, count)
        ids = hand:shuffle():sub(1, count)
    end

    -- Make sure ids are in
    ids = list(type(ids) == "table" and unpack(ids) or ids)

    local next_hand = hand
    local next_discard = discard
    local was_discard = list()
    for _, id in ipairs(ids) do
        local index = next_hand:argfind(id)
        if index then
            next_hand = next_hand:erase(index)
            next_discard = next_discard:insert(id)
            was_discard[#was_discard + 1] = id
        end
    end

    local info = {was_discarded = was_discard}
    return set_user_card(state, user, next_hand, draw, next_discard)
end

function deck.add(state, args)
    local user = args.user
    local cards = args.cards
    local dest = args.dest
    local order = args.order or "bottom"
    cards = list(type(cards) == "table" and unpack(cards) or cards)
    local next_state = state
    local hand, draw, discard = get_user_card(state, user)

    local card_ids = cards:map(function(c)
        -- If already instantiated then just return the id
        if type(c) == "string" then return end

        local id
        next_state, id = deck.create(next_state, c)
        return id
    end)

    local function insert_action(pile)
        if order == "top" then
            return card_ids + pile
        elseif order == "bottom" then
            return pile + card_ids
        elseif order == "shuffle" then
            return (pile + card_ids):shuffle()
        else
            local msg = string.format("Order unknown <%s>", dest)
            error(msg)
        end
    end

    local function get_state()
        if dest == "hand" then
            local next_hand = insert(hand)
            return set_user_card(next_state, user, next_hand, draw, discard)
        elseif dest == "discard" then
            local next_discard = insert(discard)
            return set_user_card(next_state, user, hand, draw, next_discard)
        elseif dest == "draw" then
            local next_draw = insert(draw)
            return set_user_card(next_state, user, hand, next_draw, discard)
        else
            local msg = string.format("Dest unknown <%s>", dest)
            error(msg)
        end
    end

    next_state = get_pile()

    return next_state, {card_ids=card_ids}
end

function deck.remove(state, args)
    local user = args.user
    local card_ids = args.card_ids
    card_ids = list(type(card_ids) == "table" and unpack(card_ids) or card_ids)
    local piles = {}
    piles.hand, piles.draw, piles.discard = get_user_card(state, user)

    local function do_remove(pile, id)
        local index = pile:argfind(id)
        if not index then return pile end
        return pile:erase(index)
    end

    local function remove_from_deck(id)
        for key, pile in pairs(piles) do
            piles[key] = do_remove(pile, id)
        end
    end

    for _, id in pairs(card_ids) do
        remove_from_deck(id)
    end

    local next_state = set_user_card(
        state, user, piles.hand, piles.draw, piles.discard
    )
    local info={removed=card_ids}
    return next_state, info
end

function deck.setup(state, args)
    local user = args.user
    local cards = args.cards

    local hand, draw, discard = get_user_card(state, user)

    for _, id in ipairs(hand + draw + discard) do
        id_gen.unregister(id)
    end

    local next_draw = list()

    local next_state = state

    cards = List.map(cards, function(p)
        return require("cards." .. p)
    end)

    for _, card in ipairs(cards) do
        next_state, next_draw[#next_draw + 1] = deck.create(next_state, card)
    end

    local info = {draw_pile = next_draw}
    next_state = set_user_card(
        next_state, user, list(), next_draw, list()
    )

    return next_state, info
end

return deck
