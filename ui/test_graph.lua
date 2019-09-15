local colorstack = colorstack()
local spatialstack = spatialstack()

local color_nodes = {
    add = {}, sub = {}, dot = {}, darken = {}, set = {}
}

function color_nodes.add:begin(...)
    self.color = color.create(...)
end

function color_nodes.add:enter()
    colorstack:map(add, self.color)
end

function color_nodes.sub:begin(...)
    self.color = color.create(...)
end

function color_nodes.sub:enter()
    colorstack:map(sub, self.color)
end

function color_nodes.dot:begin(...)
    self.color = color.create(...)
end

function color_nodes.dot:enter()
    colorstack:map(dot, self.color)
end

function color_nodes.darken:begin(value)
    self.value = value
end

function color_nodes.darken:enter()
    colorstack:map(color.darken, self.value)
end

function color_nodes.set:begin(r, g, b, a)
    self.color = color.create(r, g, b, a)
end

function color_nodes.set:enter()
    local c = colorstack:peek()
    colorstack:set(c:set(unpack(self.color)))
end

for _, node in pairs(color_nodes) do
    function node.memory()
        colorstack:push()
    end

    function node.exit()
        colorstack:pop()
    end
end


local spatial_func = {
    {"set", {"x", "y", "w", "h"}},
    {"left", {"x", "y", "w", "h"}},
    {"right", {"x", "y", "w", "h"}},
    {"up", {"x", "y", "w", "h"}},
    {"down", {"x", "y", "w", "h"}},
    {"upright", {"x", "y", "w", "h"}},
    {"upleft", {"x", "y", "w", "h"}},
    {"downright", {"x", "y", "w", "h"}},
    {"downleft", {"x", "y", "w", "h"}},
    {"expand", {"dx", "dy", "align", "valign"}},
    {"align", {"xself", "xother", "yself", "yother"}}
}

local spatial_nodes = {}

for _, data in ipairs(spatial_func) do
    local name, args_name = unpack(data)
    local node = {}

    function node:begin(...)
        local function do_call(index, val, ...)
            if index > #args_name then return end
            self[args_name[index]] = val
            return do_call(index + 1, ...)
        end

        do_call(1, ...)
    end

    function node:memory()
        spatialstack:push()
    end

    function node:enter()
        local f = Spatial[name]

        function do_call(index, ...)
            if index <= 0 then
                return spatialstack:map(f, ...)
            end
            local key = args_name[index]
            return do_call(index - 1, self[key], ...)
        end

        do_call(#args_name)
    end

    function node:exit()
        spatialstack:pop()
    end

    spatial_nodes[name] = node
end

spatial_nodes.border_expand = {}

function spatial_nodes.border_expand:memory()
    spatialstack:push()
end

function spatial_nodes.border_expand:enter()
    local lw = gfx.getLineWidth()
    spatialstack:map(Spatial.expand, lw, lw)
end

function spatial_nodes.border_expand:exit()
    spatialstack:pop()
end

local line_width_node = {}

function line_width_node.begin(self, w)
    self.w = w
end

line_width_node.memory = gfx.getLineWidth

function line_width_node:enter()
    gfx.setLineWidth(self.w)
end

function line_width_node:exit(w)
    gfx.setLineWidth(w)
end

local text_node = {}

function text_node:begin(text, align, valign, font, ...)
    self.font = font
    self.text = text
    self.align = align
    self.valign = valign
    self.args = {...}
end

text_node.memory = gfx.getFont

function text_node:enter()
    if not self.text then return end
    gfx.setFont(self.font)
    local font = self.font or gfx.getFont()
    local fh = font:getHeight()
    local space = spatialstack:peek()
    local x, y, w, h = space:unpack()
    if self.valign == "center" then
        y = y + (h - fh) / 2
    elseif self.valign == "bottom" then
        y = y + h - fh - 2
    end
    gfx.printf(text, x, y, w, self.align, unpack(self.args))
end

function text_node:exit(font)
    gfx.setFont(font)
end


local transform_node = {}

function transform_node:begin(x, y, r, sx, sy)
    self.x = x or 0
    self.y = y or 0
    self.r = r or 0
    self.sx = sx or 1
    self.sy = sy or 1
end

function transform_node:memory()
    gfx.push()
end

function transform_node:enter()
    gfx.translate(self.x, self.y)
    gfx.rotate(self.r)
    gfx.scale(self.sx, self.sy)
end

function transform_node:exit()
    gfx.pop()
end

local function draw_rect(mode)
    local spatial = spatialstack:peek()
    gfx.rectangle(mode, spatial:unpack())
end

local function build_border_rect(graph)
    graph
    :leaf(draw_rect, "fill")
    :branch(color_nodes.darken, 0.5)
    :branch(line_width_node, 4)
    :branch(spatial_nodes.border_expand)
    :leaf(draw_rect, "line")
end

local function build_icon_bar(graph, id)
    graph
    :branch(join(id, "base_color"), color_nodes.set, 1, 1, 1, 1)
    :branch(join(id, "icon_spatial"), spatial_nodes.set, nil, nil, 40, 40)
    :branch(join(id, "icon_transform"), transform_node)
        :map(build_border_rect)
    :back(join(id,"icon_transform"))
    :branch(join(id, "bar_color"), color_nodes.dot, 1, 1, 1, 1)
    :branch(join(id, "bar_spatial"), spatial_nodes.right, 20, 0, 200)
    :branch(join(id, "bar_transform"), transform_node)
        :map(build_border_rect)
    :back(join(id, "icon_spatial"))
end

local test = {}

function test:create()
    self._graph = graph.create()
    self._order = list()
    self._action = dict()

    self._anime = self:child(action_queue)
end


local function appear(server, self, ...)
    self._order = {...}
    self._graph = graph.create()
    self._action = dict()
    local tweens = {}
    for i, id in ipairs(self._order) do
        self._graph:map(build_icon_bar, id)
        :branch(join(id, "link"), spatial_nodes.down, 0, 20)

        local n = self._graph:data(id, "icon_transform")
        local c = self._graph:data(id, "base_color")
        n.x = 500
        c.color[4] = 0
        tweens[i] = tween(
            0.5, n, {x=0, y=0}, c.color, {[4] = 1}
        )
            :delay(0.1 * i)
        local cb = self._graph:data(id, "bar_color")
        cb.color[4] = 0
    end

    -- Note this structure only works due to the time difference
    for _, t in ipairs(tweens) do
        event:wait(t, "finish")
    end
end

function test:appear(...)
    return self._anime:add(appear, self, ...)
end

local function push(server, self, action)
    local function get_id()
        for i = #self._order, 1, -1 do
            local id = self._order[i]
            if not self._action[id] then return id end
        end
    end

    local id = get_id()

    if not id then return end

    self._action[id] = action

    local bt = self._graph:data(id, "bar_transform")
    local bc = self._graph:data(id, "bar_color")
    bt.x, bt.y = 0, -1000
    local t = tween(
        0.25, bt, {x=0, y=0}, bc.color, {[4]=1}
    )
    event:wait(t, "finish")
    -- TODO add text functionality
end

function test:push(action)
    self._anime:add(push, self, action)
end

function test:pop(action)

end

local function hide(server, self)
    local tweens = {}

    for i, id in ipairs(self._order) do
        local n = self._graph:data(id, "icon_transform")
        local c = self._graph:data(id, "base_color")
        tweens[i] = tween(
            0.5, n, {x=500, y=0}, c.color, {[4] = 0}
        )
            :delay(0.1 * i)
    end

    for _, t in ipairs(tweens) do
        event:wait(t, "finish")
    end
    self._graph = graph.create()
end

function test:hide()
    self._anime:add(hide, self)
end

function test:test()
    self:appear("foo", "bar", "baz")
    self:push("yes")
    self:push("yes2")
    self:push("yes3")
    --self:hide()
end

function test:__draw()
    colorstack:clear()
    spatialstack:clear()
    self._graph:traverse()
end

return test
