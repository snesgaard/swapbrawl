local function get_default_params()
    return {
        margin = vec2(5, 5),
        size = vec2(40, 40),
    }
end

local function get_rel_motion(prev_order, next_order)
    local from = dict()
    local to = dict()
    local all = dict()

    for index, id in ipairs(prev_order._order) do
        from[id] = index
        all[id] = true
    end

    for index, id in ipairs(next_order._order) do
        to[id] = index
        all[id] = true
    end

    return from, to, all
end

local function get_spatial(index, params)
    params = params or get_default_params()
    local margin = params.margin
    local size = params.size
    return vec2(
        margin.x * (index - 1),
        (size.y + margin.y) * (index - 1)
    )
end

local function motion_tween(from, to, params)
    -- TODO
    -- There should be some conditional here checking for upwards or downwards
    -- motion
    local from_pos = get_spatial(from, params)
    local to_pos = get_spatial(to, params)
    if from >= to then
        return function(s)
            return ease.linear(s, from_pos, to_pos - from_pos, 1)
        end
    else
        local p0 = from_pos
        local p1 = from_pos - vec2(50, 0)
        local p2 = to_pos - vec2(50, 0)
        local p3 = to_pos
        return function(s)
            if s < 0.15 then
                return ease.linear(s, p0, p1 - p0, 0.15)
            elseif s > 0.85 then
                return ease.linear(
                    s - 0.85, p2, p3 - p2, 0.15
                )
            else
                return ease.linear(
                    s - 0.15,
                    p1,
                    p2 - p1,
                    0.7
                )
            end
        end
    end
end

local function leave_tween(from, params)
    from = get_spatial(from, params)
    local to = from + vec2(400, 0)
    -- MOVE offset screen
    return function(s)
        return ease.linear(s, from, vec2(400, 0), 1)
    end
end

local function enter_tween(to, params)
    to = get_spatial(to, params)
    local from = to + vec2(400, 0)
    return function(s)
        return ease.linear(s, from, to - from, 1)
    end
end

local function get_tween(from, to, params)
    if from and to then
        return motion_tween(from, to, params)
    elseif from and not to then
        return leave_tween(from, params)
    elseif not from and to then
        return enter_tween(to, params)
    else
        log.warn('Got nil from and to')
    end
end

local function get_next_tweens(prev_order, next_order)
    local from, to, all = get_rel_motion(prev_order, next_order)

    local tween_table = {}
    local layout = dict()
    for id, _ in pairs(all) do
        local tween_func = get_tween(from[id], to[id])
        tween_table[id] = tween_func
        layout[id] = tween_func(0)
    end

    return layout, tween_table
end

local action_queue = require("combat.action_queue")
local turn_queue = require("combat.turn_queue")

local ui = {}

function ui:create()
    self._icons = dict()
    self._turn_order = turn_queue.create()
    self._turn_icons = dict()
    self._layout = dict()

    self._action_queue = self:child(action_queue)
end

function ui:register_icon(id, icon)
    self._icons[id] = icon
end

function ui:setup(turn_order)

end

function ui:advance(next_turn_order)
    local layout, tween_table = get_next_tweens(
        self._turn_order, next_turn_order
    )
    self._turn_order = next_turn_order
    self._action_queue:submit(function(handle)
        self._layout = layout
        local duration = 0.4
        local time = duration -- duration
        while time > 0 do
            local dt = handle:wait_update()
            time = time - dt
            for id, func in pairs(tween_table) do
                self._layout[id] = func(1 - time / duration)
            end
        end
        -- Final pass for final layout
        for id, func in pairs(tween_table) do
            self._layout[id] = func(1)
        end
    end)
end

function ui:show_next_turn()

end

local function draw_icon(icon, spatial)
    gfx.setColor(1, 1, 1)
    if not icon then
        gfx.rectangle("fill", spatial:unpack())
    else
        icon:draw(spatial.x, spatial.y, 0, 2, 2)
    end
end

function ui:__draw(x, y)
    for id, spatial in pairs(self._layout) do
        local icon = self._icons[id]
        draw_icon(icon, spatial)
    end
end

return ui
