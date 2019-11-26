local ability = {}

ability.name = "Backhop"
ability.target = {type="self", side="same"}

function ability.transform(state, user, target)
    return {
        path="combat.mechanics:shield",
        args={target=target}
    }
end

return ability
