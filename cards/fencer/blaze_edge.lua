local animation = require "combat.animation"

local card = {}

card.image = "blaze_edge"
card.text = "+6 Damage\n+2 Burn"
card.name = "Blazing Edge"

card.target = {type="single", side="other"}

function card.transform(state, user, target)
    local t = list(
        {
            path="combat.mechanics:damage",
            args={damage=2, user=user, target=target}
        },
        {
            path="combat.mechanics:charge",
            args={charge=true, target=user}
        },
        {
            path="combat.mechanics:shield",
            args={shield=true, target=user}
        }
    )
    return unpack(t)
end

function card.animation(root, epic, user, target)
    local init_epoch = List.head(epic)

    local opt = {}
    function opt.on_impact(hitbox)
        root:broadcast(unpack(epic))
    end

    animation.melee_attack(root, init_epoch.state, user, opt, target)
end

return card
