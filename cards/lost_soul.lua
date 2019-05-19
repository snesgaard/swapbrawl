local common = require "ability.common"
local card = {}

card.image = "lost_soul"
card.text = "+1 Card\n+2 Stamina\n\nTarget self"
card.name = "Lost Soul"

function card.targets(state, id)
    return list(id)
end

function card.execute(state, args)
    return mech.execute(
        state,
        deck.draw_card, {id=args.target, cards=1},
        mech.stamina_heal, {target=args.target, heal=2}
    )
end

function card.animate(handle, context, epic, args, resolve)
    resolve(unpack(epic))
end

return card
