local animation = require "combat.animation"

local card = {}

card.image = "blaze_edge"
card.text = "+6 Damage\n+2 Burn"
card.name = "Blazing Edge"

card.target = {type="single", side="other"}

function card.transform(state, user, target)
    return {path="combat.mechanics:damage", args={damage=2, user=user, target=target}}
end

function card.animation(root, broadcast, epic, user, target)
    local init_epoch = List.head(epic)
    print(root)
    animation.melee_attack(root, init_epoch.state, user, target)
end

return card
