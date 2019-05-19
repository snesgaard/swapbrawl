local initialize = {}
local idle = {}
local target_select = {}
local sleep = {}

function initialize.enter(fsm, context, level, state)
    context.ui = context:child(require "ui.card_hand")
    context.ui.__transform.pos = vec2(330, 600)
    return fsm:swap(idle)
end

function idle.enter(fsm, context, level)

end

function idle.keypressed(fsm, context, level, key)
    if key == "left" then
        context.ui:left()
    elseif key == "right" then
        context.ui:right()
    elseif key == "space" then
        return fsm:swap(target_select)
    end
end

function target_select.enter(fsm, context, level)

end

local states = {
    initialize = initialize,
    idle = idle,
    target_select = target_select,
    card_select = card_select
}

return states
