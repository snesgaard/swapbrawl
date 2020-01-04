local animation = require "combat.animation"
local target = require "combat.target"
local turn = require "ui.turn_queue"
local golem = {}

golem.icon = {"art/icons", "golem"}

golem.animations = {
    idle = "golem_idle",
    dash = "golem_dash/dash",
    evade = "golem_dash/evade",
    attack = "golem_dash/attack",
    post_attack = "golem_dash/post_attack",
    windup = "golem_dash/windup",
    idle2chant = "golem_cast/idle2chant",
    chant = "golem_cast/chant",
    chant2cast = "golem_cast/chant2cast",
    cast = "golem_cast/cast",
}

golem.atlas = "art/main_actors"

function golem.basestats()
    return {
        health = 200,
        agility = 10,
    }
end

golem.actions = {}

golem.actions.attack = {
    name = "Attack",
    target = {type="single", side="other"},
    transform = function(state, user, target)
        return {
            path="combat.mechanics:damage",
            args={damage=5, user=user, target=target}
        }
    end,
    animation = function(root, epic, user, target)
        local opt = {wait=1.0}
        function opt.on_impact()
            root:broadcast(unpack(epic))
        end
        animation.approach(root, epic[1].state, user, target, {speed=900})
        animation.attack(root, epic[1].state, user, target, opt)
        animation.fallback(root, epic[1].state, user, {speed=900})
    end
}

function golem.ai(state, id)
    local targets = target.init(state, id, golem.actions.attack.target)
    return golem.actions.attack, {targets.foes:shuffle():head()}
end

return golem
