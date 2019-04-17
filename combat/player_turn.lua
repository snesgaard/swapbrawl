local position = require "combat.position"

local function create_default_cross(self)
    local keys = {
        up = "W",
        down = "S",
        left = "A",
        right = "D"
    }

    local name = {
        up = "Magick",
        left = "Attack",
        right = "Defend",
        down = "Item"
    }

    local icons = {
        left = "attack_bw",
        up = "magick_bw",
        down = "item_bw",
        right = "defend_bw"
    }

    local cross = self:child(require "ui.action_cross")
    cross:set_keys(keys)
    cross:set_texts(name)
    cross:set_icons(icons)
    return cross
end

local states = {}

local pick_action = {}

local swap_partner = {}

local pick_target = {}

function pick_action.enter(fsm, context, level, id)
    level.ui = create_default_cross(level)
    level.id = id
    local pos = position.get_world(context.state:position(), id)
    level.ui.__transform.pos = pos - vec2(0, 300)
end

function pick_action.draw(context, level, ...)
    level:draw(...)
end

function pick_action.keypressed(fsm, context, level, key)
    if key == "a" then
        level.ui:set_selection("left")
        return fsm:push(states.pick_target, level.id, require "ability.attack")
    end
end

function pick_action.poped(fsm, context, level, ability, ...)
    if ability then
        return fsm:pop(ability, ...)
    else
        level.ui:set_selection()
    end
end

function pick_target.enter(fsm, context, level, id, ability)
    local ui = require "ui.target_selection"

    local targets, secondary_targets = ability.targets(
        context.state, id
    )
    level.target_select = level:child(
        ui, targets, context.state, id, secondary_targets
    )
    level.ability = ability
end

function pick_target.draw(context, level, ...)
    level:draw(...)
end

function pick_target.keypressed(fsm, context, level, key)
    level.target_select:keypressed(key)

    if key == "backspace" then
        return fsm:pop()
    elseif key == "space" then
        return fsm:pop(level.ability, level.target_select:get_current())
    end
end

states.pick_action = pick_action
states.pick_target = pick_target

return states
