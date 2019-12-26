local function build_border_rect(graph)
    graph
    :leaf(gfx_nodes.draw_rect, "fill")
    :branch(gfx_nodes.color.darken, 0.5)
    :branch(gfx_nodes.line_width, 4)
    :branch(gfx_nodes.spatial.border_expand)
    :leaf(gfx_nodes.draw_rect, "line")
end

local function build_icon_bar(graph, id, icons)
    local function get_icon()
        local atlas, image = unpack(icons[id] or {})
        if not atlas or not image then return end
        return get_atlas(atlas):get_animation(image):head()
    end

    graph
    :branch(join(id, "base_color"), gfx_nodes.color.set, 1, 1, 1, 1)
    :branch(join(id, "icon_spatial"), gfx_nodes.spatial.set, nil, nil, 40, 40)
    :branch(join(id, "icon_transform"), gfx_nodes.transform)
        :map(build_border_rect)
    :back(join(id,"icon_transform"))
    :leaf(
        join(id, "icon_sprite"), gfx_nodes.sprite, get_icon()
    )
    :branch(join(id, "bar_color"), gfx_nodes.color.dot, 1, 1, 1, 1)
    :branch(join(id, "bar_spatial"), gfx_nodes.spatial.right, 20, 0, 250)
    :branch(join(id, "bar_transform"), gfx_nodes.transform)
        :map(build_border_rect)
        :branch(gfx_nodes.color.set, 0.5, 0.5, 0.5, nil)
        :leaf(
            join(id, "bar_text"), gfx_nodes.text, nil,
            "center", "center", font(20)
        )
    :back(join(id, "icon_spatial"))
end

local test = {}

function test:icon(id, atlas, image)
    self._icons[id] = {atlas, image}
    local anime = get_atlas(atlas):get_animation(image)
    if not anime or #anime == 0 then
        error(string.format("Animation undefined %s:%s", atlas, image))
    end
    print(dict(anime:head()))
    self._graph:reset(
        join(id, "icon_sprite"), anime:head()
    )
    return self
end

function test:create()
    self._graph = graph.create()
    self._order = list()
    self._action = dict()
    self._icons = dict()

    self._anime = self:child(action_queue)
end


local function appear(server, self, ...)
    self._order = list(...)
    self._graph = graph.create()
    self._action = dict()
    local tweens = {}
    for i, id in ipairs(self._order) do
        -- TODO consider refactoring to an individual graph
        -- pr actor instead of a single combined graph
        -- Might be easier to handle if e.g. popping middle bars
        -- Turns out to be relevant
        self._graph
            :map(build_icon_bar, id, self._icons)
            :branch(join(id, "link"), gfx_nodes.spatial.down, 0, 20)

        local n = self._graph:data(id, "icon_transform")
        local c = self._graph:data(id, "base_color")
        n.x = 500
        c.color[4] = 0
        tweens[i] = tween(
            0.25, n, {x=0, y=0}, c.color, {[4] = 1}
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
    print("appear")
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
    local btxt = self._graph:data(id, "bar_text")
    btxt.text = action
    bt.x, bt.y = 0, -1000
    local t = tween(
        0.25, bt, {x=0, y=0}, bc.color, {[4]=1}
    )
    event:wait(t, "finish")
    event(self, "push_done", action)
end

function test:push(action)
    print("push")
    self._anime:add(push, self, action)
end

local function pop(server, self)
    local id = self._order:head()

    if not id then return end

    self._order = self._order:body()
    local it = self._graph:data(id, "icon_transform")
    local bc = self._graph:data(id, "base_color")
    local t = tween(
        0.5, it, {x=500, y=0}, bc.color, {[4]=0}
    )
    event:wait(t, "finish")
end

function test:pop()
    self._anime:add(pop, self)
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
    self._order = list()
    self._graph = graph.create()
end

function test:hide()
    self._anime:add(hide, self)
end

function test:test()
    self:icon("foo", "art/icons", "fencer_icon")
    self:icon("bar", "art/icons", "alchemist")
    self:icon("baz", "art/icons", "vampire")
    self:icon("sponge", "art/icons", "vampress")
    self:appear("foo", "bar", "baz", "sponge")
    self:push("Level Drain")
    self:push("Reap")
    self:push("Fireball")
    self:push("Parry")
    self._anime:add(function()
        while event:wait("keypressed") ~= "space" do end
    end)
    self:pop()
    self:pop()
    self:pop()
    self:pop()
    self:hide()
end

function test:__draw()
    colorstack:clear()
    spatialstack:clear()
    self._graph:traverse()
end

test.remap = {}

test.remap["combat.turn_queue:new_turn"] = function(self, state, info)
    local order = state:read("turn/pending")
    -- We want to push the reverse order as pending is given in order of action
    -- picking, not execution
    self:appear(unpack(order:reverse()))
end

test.remap["combat.turn_queue:push"] = function(self, state, info)
    self:push(info.action.name)
end

test.remap["combat.turn_queue:pop"] = function(self, state, info)
    --self:pop()
end

test.remap["turn:pop_now"] = function(self)
    self:pop()
end

return test
