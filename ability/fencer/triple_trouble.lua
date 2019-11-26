local animation = require "combat.animation"
local ability = {}

ability.name = "Triple Trouble"
ability.target = {type="single", side="other"}

function ability.transform(state, user, target)
    return {
        path="combat.mechanics:damage",
        args={damage=2, user=user, target=target}
    }, {
        path="combat.mechanics:damage",
        args={damage=2, user=user, target=target}
    }, {
        path="combat.mechanics:damage",
        args={damage=2, user=user, target=target}
    }
end

function ability.animation(root, epic, user, target)
    function make_opt(epoch, wait)
        local opt = {wait=wait}
        function opt.on_impact()
            root:broadcast(epoch)
        end
        return opt
    end
    --animation.melee_attack(root, epic[1].state, user, opt, target)
    animation.approach(root, epic[1].state, user, target)
    animation.attack(root, epic[1].state, user, target, make_opt(epic[1], 0.1))
    animation.attack(root, epic[1].state, user, target, make_opt(epic[2], 0.2))
    animation.attack(root, epic[1].state, user, target, make_opt(epic[3], 0.5))
    animation.fallback(root, epic[1].state, user)
end

return ability
