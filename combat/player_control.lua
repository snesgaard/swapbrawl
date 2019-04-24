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

local init = {}
local idle = {}
local ability = {}
local card = {}
local target = {}
local submit = {}

function init.enter(fsm, context, level)
    context.ui = context:child()
    context.ui.card_hand = context.ui:child(require "ui.card_hand")
    context.ui.card_hand.__transform.pos = vec2(325, 600)
end

function init.begin(fsm, context, level, core)
    context.core = core
    return fsm:swap(idle)
end

function idle.enter(fsm, context, level)
    context.ui.card_hand:activate(true)
    context.ui.card_hand:fallback():highlight(true)

    if context.ui.cross then
        context.ui.cross:set_selection()
        context.ui:adopt(context.ui.cross)
    end
end

function idle.on_state_change(fsm, context, level)

end

function idle.on_next_turn(fsm, context, level, id, state)
    context.id = id
    context.state = state
    -- Should retrieve abilities from the state
    context.ui.cross = create_default_cross(context.ui)
    local pos = position.get_world(state:position(), id)
    context.ui.cross.__transform.pos = pos - vec2(0, 300)
end


local function exit_card(fsm, context, level)
    context.ui.card_hand:trigger()
    context.ui.cross:orphan()
    return fsm:swap(target)
end

local function exit_ability(fsm, context, level)
    context.ui.card_hand:highlight(false)
    return fsm:swap(target)
end

function idle.keypressed(fsm, context, level, key)
    if key == "left" then
        context.ui.card_hand:left()
    elseif key == "right" then
        context.ui.card_hand:right()
    elseif key == "space" then
        return exit_card(fsm, context, level)
    end
    if context.ui.cross then
        if key == "a" then
            context.ui.cross:set_selection("left")
            return exit_ability(fsm, context, level)
        elseif key == "s" then
            context.ui.cross:set_selection("down")
            return exit_ability(fsm, context, level)
        elseif key == "w" then
            context.ui.cross:set_selection("up")
            return exit_ability(fsm, context, level)
        elseif key == "d" then
            context.ui.cross:set_selection("right")
            return exit_ability(fsm, context, level)
        end
    end
end

function target.enter(fsm, context, level, id, ability)
    -- NOTE Either use target_selection directly
    local a = require "ability.attack"
    local target, second = a.targets(context.state, context.id)
    context.ui.target_selection = context.ui:child(
        require "ui.target_selection", target, context.state, context.id,
        second
    )
end

function target.on_state_change(fsm, context, level)

end

function target.on_next_turn(fsm, context, level)

end

function target.keypressed(fsm, context, level, key)
    if key == "backspace" then
        return fsm:swap(idle)
    elseif key == "left" then
        context.ui.target_selection:change_target(-1)
    elseif key == "right" then
        context.ui.target_selection:change_target(1)
    elseif key == "tab" then
        context.ui.target_selection:swap_faction()
    end
end

function target.exit(fsm, context, level)
    context.ui.target_selection:destroy()
    context.ui.target_selection = nil
end

function submit.enter(fsm, context, level, id, ability, ...)

end


return init
