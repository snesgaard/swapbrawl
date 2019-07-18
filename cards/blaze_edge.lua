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
    local function on_hit(handle, area, data)
        local sfx = context.sfx:child(require "sfx.flame_slash")
        sfx.__transform.pos = area:center()

        if data.user.__transform.pos.x > data.target.__transform.pos.x then
            sfx.__transform.scale.x = -1
        end

        local sfx = Node.create(require "sfx.ailment.stun")
        data.target:adopt(sfx)
        sfx:on_attach(data.target)

        resolve(unpack(epic))
        handle:wait(0.4)
    end

    local epoch = mech.tail_state(epic)
    common.melee_attack(
        handle, context, epoch.state, args.user, args.target, on_hit
    )
end

return card
