local ailment_names = {
    "poison", "burn", "petrify", "frozen", "bleed", "stun"
}

local ailment_duration = {
    poison = 4,
    burn = 0,
    petrify = 2,
    frozen = 4,
    bleed = 3,
    stun = 2,
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

function ailments.damage(state, args)
    local target = args.target
    local args_damage = args.damage or 1
    local ailment_type = args.type

    local duration = state:read(duration_path(ailment_type, target))
    local res = state:read(resistance_path(ailment_type, target))
    local damage = state:read(damage_path(ailment_type, target))
    local increase = state:read(increase_path(state, ailment_type, target))
    duration = duration or 0
    res = res or 1
    damage = damage or 0
    increase = increase or 3
    local active = duration > 0
    local next_damage = not active and (damage + args_damage) or 0
    local activated = next_damage >= res
    next_damage = activated and 0 or next_damage
    local next_res = res + (activated and increase or 0)

    local info = {
        damage = next_damage,
        activated = activated,
        resistance = next_res,
        active = active
    }

    local post_transforms = {}

    if ailment_type == "burn" and activated then
        post_transforms[#post_transforms +1] = {
            path="combat.mechanics:true_damage", args={target=target, damage=10}
        }
    elseif ailment_type == "stun" and activated then
        post_transforms[#post_transforms + 1] = {
            path="combat.combotree:reset_combo", args={target=target}
        }
    end

    local next_state = state
        :write(damage_path(ailment_type, target), next_damage)
        :write(resistance_path(ailment_type, target), next_res)

    if activated then
        next_state = next_state
            :write(
                duration_path(ailment_type, target),
                ailment_duration[ailment_type]
            )
    end

    return next_state, info, post_transforms
end

function ailments.end_of_round(state, args)
    local target = args.target
    local info = {
        duration = {},
        finished = {},
    }

    local next_state = state
    for _, name in ipairs(ailment_names) do
        local duration = state:read(duration_path(name, target)) or 0
        local next_duration = math.max(duration - 1, 0)
        next_state = next_state:write(
            duration_path(name, target), next_duration
        )
        info.duration[name] = next_duration
        info.finished[name] = next_duration <= 0
    end
    local post_transforms = {}
    if info.duration.poison > 0 then
        local health, max_health = state:health(target)
        local damage = math.floor(max_health / 20)
        post_transforms[#post_transforms + 1] = {
            path="combat.mechanics:true_damage", args={
                target=target, damage=damage
            }
        }
    end

    return next_state, info, post_transforms
end

function ailments.is_stunned(state, id)
    local duration = state:read(duration_path("stun", id)) or 0
    return duration > 0
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
