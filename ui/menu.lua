local function get_default_config()
    return {
        size = vec2(100, 20),
        margin = vec2(5, 5),
        outer_margin = vec2(10, 10),
    }
end

local function get_shape(index, config)
    config = config or get_default_config()
    local size = config.size
    local margin = config.margin
    return spatial(
        margin.x * (index - 1),
        (size.y + margin.y) * (index - 1),
        size.x, size.y
    )
end

local node = {}

function node:create()

end

function node._build_layout(items, config)
    config = config or get_default_config()

    local layout = {}

    layout.items = {}

    for i = 1, items do
        layout.items[i] = get_shape(i, config)
    end

    local up_item = get_shape(0, config)
    local down_item = get_shape(items + 1, config)

    local om = config.outer_margin

    local up_left = up_item:move(-om.x, -om.y)
    local up_right = up_item:right():move(om.x, -om.y)
    local down_left = down_item:down():move(-om.x, om.y)
    local down_right = down_item:down():right():move(om.x, om.y)

    layout.bound = {
        up_left.x, up_left.y,
        up_right.x, up_right.y,
        down_right.x, down_right.y,
        down_left.x, down_left.y,
    }

    return layout
end

function node:test()
    self.layout = node._build_layout(6)
end

function node:__draw()
    if not self.layout then return end

    gfx.polygon("fill", self.layout.bound)
end

return node
