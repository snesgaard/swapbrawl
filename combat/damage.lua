local api = {}

api.resistance = {
    weak=2.0, normal=1.0, resist=0.5, immune=0.0, drain=-1.0
}

api.elements = {"physical", "fire", "thunder", "ice"}

api.ailments = require("combat.ailments").ailments

api.charge_multiplier = 2.0

function api.resistance(state, id)

end

function api.is_health_attack(damage_table)
    for _, type in ipairs(api.elements) do
        if damage_table[type] then return true end
    end
    return false
end

function api.is_ailment_attack(damage_table)
    for _, type in ipairs(api.ailments) do
        if damage_table[type] then return true end
    end
    return false
end

function api.health_damage(state, user, target, damage_table)
    local resist = api.read_resistance(state, target)
    local shield = api.read_shield(state, target)
    local charge = api.read_charge(state, user)
    local info = dict{
        shield = shield,
        charge = charge,
        damage = dict{},
        resist = dict{}
    }

    if not api.is_health_attack(damage_table) then return info end


    local function do_damage(type)
        local dmg = damage_table[type]
        if not dmg then return end
        if shield then return 0, "void" end

        local r = resist[type] or "normal"
        local scale = api.resistance[r] or 1.0

        local actual_damage = damage * scale
        if charge then
            actual_damage = api.charge_multiplier * actual_damage
        end
        return math.floor(actual_damage), r
    end

    for _, element in ipairs(api.elements) do
        local e = element
        info.damage[e], info.resist[e] = do_damage(element)
    end

    return info
end


function api.status_damage(staet, user, target, damage_table)
    local info = dict{
        damage = dict(),
        resist = dict(),
        triggered = dict()
    }

    if not api.is_status_damage(damage_table) then return info end

    local shield = api.read_shield(state, target)

    if shield and api.is_health_attack(damage_table) then return info end

    local resist = api.read_resistance(state, target)


    function do_damage(type)
        local dmg = damage_table[type]
        if not dmg then return end
        local r = resist[type]
        local scale = api.resistance[r] or 1.0

        return math.floor(damage * scale), r
    end

    for _, status in ipairs(api.ailments) do
        local s = status
        info.damage[s], info.resist[s] = do_damage(status)
    end

    return info
end

function api.update_health(state, args, damage_table, health_info)
    if not api.is_health_attack(damage_table) then
        return state
    end

    local target = args.target

    local damage = 0

    for _, num in pairs(health_info.damage) do
        -- Clamp negative damage, will be handleded steps
        damage = damage + math.max(num, 0)
    end

    local health, max_health = state:health(target)
    local next_health = math.clamp(health - damage, 0, max_health)
    local actual_damage = health - next_health

    health_info.damage = actual_damage
    return state:write(join("actor/health", target), next_health)
end

function api.update_status(state, args, status_info)
    local target = args.target
    local ailment_duration = require("combat.ailments").ailment_duration

    local function apply_damage(key, damage)
        local resist, prev_damage, duration, increase = api.read_ailment_data(
            state, target
        )
        local next_damage = prev_damage + damage
        local next_resist = resist
        local active = duration > 0
        local activated = next_damage >= resist
        local next_duration = duration

        if active then
            next_damage = 0
        elseif activated then
            next_damage = 0
            next_resist = resist + increase
            next_duration = ailment_duration[key]
        end

        local next_state = api.write_ailment_data(
            next_resist, next_damage, next_duration
        )
        return next_state, activated
    end

    status_info.activated = dict()
    for type, num in pairs(status_info.damage) do
        state, status_info.activated[type] = apply_damage(type, num)
    end

    return state
end

function api.derived_effects(
        state, args, health_info, status_info, post_transforms
)
    local derived_effects = require "combat.derived_effects"

    for name, effect in pairs(derived_effects) do
        local condition = effect.condition or constant()
        local next_transform = effect(state, args, health_info, status_info)
        if next_transform then
            table.insert(post_transforms,
                {
                    event=string.format("derived_effect:%s", name),
                    args=args
                }
            )
            for _, t in ipairs(next_transform) do
                table.insert(post_transforms, t)
            end
        end
    end
end

function api.handle_drain(state, args, health_info, post_transforms)
    local heal = 0
    for _, num in pairs(health_info.damage) do
        if num < 0 then heal = heal - num end
    end
    if heal > 0 then
        table.insert(post_transforms, {
            path="combat.mechanics:heal",
            args={heal=heal, target=args.target}
        })
    end
end

function api.attack(state, args)
    local user = args.user
    local target = args.target
    local damage = args.damage

    local health_info = api.health_damage(state, user, target, damage)
    local status_info = api.status_damage(state, user, target, damage)

    local next_state = state
    next_state = api.update_health(state, args, damage, health_info)
    next_state = api.update_status(state, args, status_info)

    local info = {
        health = health_info,
        ailment = status_info
    }

    local post_transforms = list()

    api.handle_drain(state, args, health_info, post_transforms)
    api.derived_effects(state, args, health_info, status_info, post_transforms)

    return next_state, info, post_transforms
end


return api
