local position = require "combat.position"

local reaction = {}

function reaction.damage_dealt(context, state, info)
    local ui = context.ui.char_bars[info.target]
    if ui then
        ui:set_hp(info.health)
    end
    -- Also spawn damage numbers
    local base_pos = position.get_world(context.state:position(), info.target)
    base_pos = base_pos - vec2(0, 75)
    context.ui.number_server:damage(base_pos, info)
    local sprite = context.sprites[info.target]
    if sprite then sprite:shake() end

    if info.charged then
        reaction.charged(context, state, {removed=true, target=info.user})
    end
    if info.shielded then
        reaction.shielded(context, state, {removed=true, target=info.target})
    end
end

function reaction.stamina_used(context, state, info)
    local ui = context.ui.char_bars[info.user]
    if ui then
        ui:set_stamina(info.stamina)
    end
end

function reaction.healing_done(context, state, info)
    local ui = context.ui.char_bars[info.target]
    if ui then
        ui:set_hp(info.health)
    end

    -- Also spawn damage numbers
    local base_pos = position.get_world(context.state:position(), info.target)
    base_pos = base_pos - vec2(0, 75)
    context.ui.number_server:heal(base_pos, info)
end

function reaction.ailment_damage(context, state, info)
    local ailment = require "combat.ailments"
    ailment.damage_gfx(context, state, info)
end

function reaction.ailment_update(...)
    local ailment = require "combat.ailments"
    ailment.update_gfx(...)
end

function reaction.stamina_healed(context, state, info)
    local ui = context.ui.char_bars[info.target]
    if ui then
        ui:set_stamina(info.stamina)
    end
end

function reaction.shielded(context, state, info)
    local sprite = context.sprites[info.target]
    if info.shielded and not sprite.shield then
        sprite.shield = sprite:child(sfx("shield"))
    elseif info.removed and sprite.shield then
        sprite.shield:halt()
        sprite.shield = nil
    end
end

function reaction.charged(context, state, info)
    local sprite = context.sprites[info.target]

    if info.charged and not sprite.charge then
        sprite.charge = sprite:child(sfx("charge"))
    elseif info.removed and sprite.charge then
        sprite.charge:halt()
        sprite.charge = nil
    end
end

return reaction
