local ailments = {}

ailments.ailments = {
    "poison", "burn", "bleed", "blast", "stun", "frozen", "blind", "shocked",
    "wet", "oil", "plague"
}

ailments.duration = {
    poison=3,
    burn=3,
    bleed=3,
    stun=1,
    blind=3,
    shocked=3,
    wet=3,
    oil=3,
    plague=3
}

function ailments.init_state(state)
    state.ailment = dict()
    for _, name in ipairs(ailment_names) do
        state.ailment[name] = dict{
            damage = dict(),
            duration = dict(),
            resistance = dict(),
            increase = dict()
        }
    end
end

local function format_path(entry, type, id)
    return join("ailment", type, entry, id)
end

function ailments.read_ailment_data(state, type, id)
    local resist = state:read(format_path("resistance", type, id)) or 1
    local damage = state:read(format_path("damage", type, id)) or 0
    local duration = state:read(format_path("duration", type, id))
    local increase = state:read(format_path("increase", type, id)) or 1
    return resist, damage, duration, increase
end

function ailments.write_ailment_data(
        state, type, id,
        resist, damage, duration, increase
)
    if resist then
        state = state:write(format_path("resistance", type, id), resist)
    end
    if damage then
        state = state:write(format_path("damage", type, id), damage)
    end
    if duration then
        state = state:write(format_path("duration", type, id), duration)
    end
    if increase then
        state = state:write(format_path("increase", type, id), increase)
    end
    return state
end

ailments.poison = {
    damage_ratio = 0.025,
    ["combat.turn:end_of_round"] = function(id, state, info, args)
        local _, max_health = state:health(id)
        local damage = math.floor(ailments.poison.damage_ratio * max_health)
        return {
            path="combat.damage:true_damage",
            args={target=id, damage=damage}
        }
    end
}

ailments.blast = {
    damage=10
    ["immediate"] = function(state, args)
        return {
            path="combat.damage:true_damage",
            args={target=args.target, damage=ailments.blast.damage}
        }
    end
}



return ailments
