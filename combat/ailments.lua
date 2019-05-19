-- The actual mechanics of the effect of each ailment
local update = {}

function update.poison(history, state, id)
    -- TODO Perform proper calculation here instead
    local damage = 5
    return history + mech.true_damage(
        state, {target = id, damage = damage}
    )
end

function update.generic(history, state, id, key)
    local dur_path = string.format("ailment/%s/duration/", key)
    local dur = state:read(dur_path .. id) or 0
    if dur < 1 then
        return history
    end

    -- Maybe just be paranoid should this occur before or after specific
    -- updaters
    local next_dur = math.max(dur - 1, 0)

    local u = update[key]

    if u then
        history = u(history, state, id)
        state = history:tail().state
    end

    local post_state = state:write(dur_path .. id, next_dur)

    local info = {
        id = id, cleared = next_dur <= 0 and dur > 0,
        ailment = key
    }

    history[#history + 1] = mech.make_epoch(
        "ailment_update", post_state, info
    )

    return history
end

local ailments = {}

function ailments.update(state, id)
    local ailments = {"poison"}

    local history = list()
    local next_state = state

    for _, key in ipairs(ailments) do
        history = update.generic(history, state, id, key)
        next_state = #history > 0 and history:tail().state or next_state
    end

    return history
end

local function sprite_key(ailment)
    return "ailment_" .. ailment
end

function ailments.update_gfx(context, state, info)
    local id = info.id
    local sprite = context.sprites[id]

    -- First clear any particles the sprite might have
    if sprite and info.cleared then
        local k = sprite_key(info.ailment)
        local sfx = sprite[k]
        if sfx and sfx.fade then
            sfx:fade()
        elseif sfx then
            sfx:destroy()
        end
        sprite[k] = nil
    end
end

function ailments.damage_gfx(context, state, info)
    if info.success and info.ailment ~= "burn" then
        local sprite = context.sprites[info.target]
        local sfx = sfx("ailment." .. info.ailment)
        local key = sprite_key(info.ailment)
        if sprite and not sprite[key] then
            sprite[key] = sprite:child(sfx)
            sprite[key].__transform.pos.y = -sprite:height()
        end
    end
end

return ailments
