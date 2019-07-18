local battle = {}

local function default_deck()
    --[[
    return list(
        "deep_cut", "full_defense", "superior_command", "superior_command",
        "potion", "pierce", "blaze_edge",
        "full_defense", "pierce", "blaze_edge"
    )
    ]]--
    return list(
        "lost_soul", "lost_soul","lost_soul","lost_soul","lost_soul",
        "potion", "potion","potion","potion","potion",
        "blaze_edge", "blaze_edge","blaze_edge","blaze_edge","blaze_edge"
    )
end

local function actor(type, deck)
    return {type = type, deck = deck or default_deck()}
end

function battle.args()

    local party = list(
        "fencer", "vampire", "vampress"
    )

    local foes = list("mage", "alchemist")
    return party:map(actor), foes:map(actor)
end


function battle:__draw(x, y)


end

return battle
