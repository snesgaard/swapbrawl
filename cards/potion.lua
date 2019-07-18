local common = require "ability.common"
local deck = require "combat.deck"
local card = {}

card.image = "tri_potion_green"
card.text = "+10 Health\n\nDiscard hand"
card.name = "Potion"

function card.execute(state, args)
    return mech.execute(
        state, mech.heal, {heal=10, target=args.target},
        deck.discard_hand, {target=args.target},
        deck.draw_card, {id=args.target, cards=5}
    )
end

function card.animate(handle, context, epic, args, resolve)
    local function on_hit()
        resolve(unpack(epic))
    end
    local epoch = mech.tail_state(epic)
    common.ballistic(
        handle, context, epoch.state, {
            user=args.user, target=args.target, proj_idle="potion_blue/idle",
            proj_break="potion_blue/break"
        },
        on_hit
    )
end

return card
