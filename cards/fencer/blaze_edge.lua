local card = {}

card.image = "blaze_edge"
card.text = "+6 Damage\n+2 Burn"
card.name = "Blazing Edge"

card.target = {type="single", side="other"}

function card.transform(state, id, target)
    return {path="combat.mechanics:damage", args={damage=2, user=id, target=target}}
end

return card
