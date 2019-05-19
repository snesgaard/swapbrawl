local common = require "ability.common"
local card = {}

card.image = "blaze_edge"
card.text = "+6 Damage\n+2 Burn"
card.name = "Blazing Edge"

function card.execute(state, args)
    return mech.execute(
        state,
        "damage", mech.damage, dict{
            target=args.target, damage=6, user=args.user
        },
        "burn", mech.ailment_damage, dict{
            target=args.target, damage=2, ailment="burn"
        }
    )
end

function card.animate(handle, context, epic, args, resolve)
    local function on_hit(handle)
        resolve(unpack(epic))
        handle:wait(0.4)
    end

    local epoch = mech.tail_state(epic)
    common.melee_attack(
        handle, context, epoch.state, args.user, args.target, on_hit
    )
end

return card
