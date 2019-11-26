local ailment_names = {
    "poison", "burn", "petrify", "frozen", "bleed", "stun"
}

local ailment_duration = {
    poison = 3,
    burn = nil,
    petrify = 2,
    frozen = 4,
    bleed = 3,
    stun = 1,
}

local function format_path(ailment_type, dst, target)
    return string.format("ailment/%s/%s/%s", ailment_type, dst, target)
end

local function damage_path(ailment, target)
    return format_path(ailment, "damage", target)
end

local function duration_path(ailment, target)
    return format_path(ailment, "duration", target)
end

local function resistance_path(ailment, target)
    return format_path(ailment, "resistance", target)
end

local function increase_path(ailment, target)
    return format_path(ailment, "increase", target)
end

local ailments = {}

function ailments.damage(state, args)
    local target = args.target
    local args_damage = args.damage
    local ailment_type = args.type

    local duration = state:read(duration_path(ailment_type, target))
    local res = state:read(resistance_path(ailment_type, target))
    local damage = state:read(damage_path(ailment_type, target))
    local increase = state:read(increase_path(state, ailment_type, target))
    duration = duration or 0
    res = res or 1
    damage = damage or 0
    local active = duration > 0
    local next_damage = active and (damage + args_damage) or 0
    local activated = next_damage >= res
    next_damage = activated and 0 or next_damage
    local next_res = res + (activated and increase or 0)

    local info = {
        damage = next_damage,
        activated = activated,
        resistance = next_res,
        active = active
    }

    local next_state = state
        :write(damage_path(ailment_type, target), next_damage)
        :write(resistance_path(ailment_type, target), next_res)

    return next_state, info
end

local function declare_damage(ailment_type)
    return function(state, args)
        args = dict(args)
        args.type = ailment_type
        return ailments.damage(state, args)
    end
end

for _, name in ipairs(ailment_names) do
    ailments[name .. "_damage"] = declare_damage(name)
end


return ailments
