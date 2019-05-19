local common = require "ability.common"
local card = {}

card.image = "armor_pierce"
card.text = "+6 Damage\n+Fragile\n\nIgnores Shield"
card.name = "Shield Pierce"

function card.execute(state, args)
    return mech.execute(
        state,
        mech.damage, dict{target=args.target, damage=6, user=args.user}
        -- TODO Insert weakened status
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
