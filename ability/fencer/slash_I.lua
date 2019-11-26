local animation = require "combat.animation"
local ability = {}

ability.name = "Slash I"
ability.target = {type="single", side="other"}

function ability.transform(state, user, target)
    return {
        path="combat.mechanics:damage",
        args={damage=2, user=user, target=target}
    }
end

function ability.animation(root, epic, user, target)
    local opt = {}
    function opt.on_impact()
        root:broadcast(unpack(epic))
    end
    --animation.melee_attack(root, epic[1].state, user, opt, target)
    animation.approach(root, epic[1].state, user, target)
    animation.attack(root, epic[1].state, user, target, opt)
    animation.fallback(root, epic[1].state, user)
end

return ability
