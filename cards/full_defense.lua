local common = require "ability.common"
local card = {}

card.image = "defend_sigil"
card.text = "Targets Party\n\n+Shield"
card.name = "Sigil"

function card.targets(state, id)
    local p = state:position(id)
    local targets = state:position()
        :filter(common.is_number)
        :filter(function(k, v) return k * p > 0 end)
        :values()

    return targets, common.same_faction
end

function card.execute(state, args)
    local call_args = args.target
        :map(function(id)
            return list(mech.shield, {target = id})
        end)
        :reduce()
    return mech.execute(state, unpack(call_args))
end

function card.animate(handle, context, epic, args, resolve)
    resolve(unpack(epic))
end

return card
