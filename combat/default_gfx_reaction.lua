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
end

return reaction
