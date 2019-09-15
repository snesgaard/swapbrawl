local function printf(text, space, align, valign, ...)
    local font = gfx.getFont()
    local fh = font:getHeight()
    local x, y, w, h = space:unpack()
    if valign == "center" then
        y = y + (h - fh) / 2
    elseif valign == "bottom" then
        y = y + h - fh - 2
    end
    gfx.printf(text, x, y, w, align, ...)
end

local turn_queue = {}

function turn_queue:create()
    self._spatials = dict()
    self._offset = dict()
    self._color = color.create()
    self._order = list()
    self._color_stack = colorstack()
    self._icon = dict()
    self._action = list()

    self.ICON_SIZE = vec2(20, 20) * 2
    self.ICON_MARGIN = vec2(4, 4)
    self.ACTION_SIZE = vec2(200, self.ICON_SIZE.y)
    self.BG_COLOR = color.create()
    self.MARGIN = vec2(7, 7)
    self.INTRO_DELAY = 0.1
    self.INTRO_DUR = 0.5

    self._server = self:child(action_queue)
end

function turn_queue:test()
    self:appear(list("foo", "bar", "baz"))
    self:push("yes1")
    self:push("yes2")
    self:push("yes3")
    self:push("yes4")
    self:pop()
end

function turn_queue:icon(id, texture, quad)

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
    local barid = self:bar_id(id)
    local s = self._spatials[self:icon_id(id)]
    s = s:right(self.MARGIN.x, 0, self.ACTION_SIZE.x)

    self._action[id] = action
    self._offset[barid] = vec2(0, -1000)
    self._spatials[barid] = s

    local t = tween(self.INTRO_DUR, self._offset[barid], vec2())
    event:wait(t, "finish")
end

function turn_queue:push(action)
    self._server:add(push, self, action)
end

local function pop(server, self)
    local id = self._order:head()
    if not id then return end

    local iconid = self:icon_id(id)
    local t = tween(
        self.INTRO_DUR,
        self._offset[iconid], vec2(500, 0),
        self._color[id], {[4]=0}
    )
    event:wait(t, "finish")
    self._action[id] = nil
    self._order = self._order:body()
end

function turn_queue:pop()
    self._server:add(pop, self)
end

function turn_queue:icon_id(id)
    return join(id, "icon")
end

function turn_queue:bar_id(id)
    return join(id, "bar")
end

local function appear(server, self, order)
    self._order = order
    local s = spatial(
        0, 0, (self.ICON_SIZE + self.ICON_MARGIN):unpack()
    )
    for _, id in pairs(order) do
        local icon = self:icon_id(id)
        self._spatials[icon] = s
        self._offset[icon] = vec2(500, 0)
        self._action[id] = nil
        self._color[id] = color.create(1, 1, 1, 0)
        s = s:down(0, self.MARGIN.y)
    end

    local function intro(server, id, iconid, delay)
        event:sleep(delay)
        local t = tween(
            self.INTRO_DUR,
            self._offset[iconid], vec2(),
            self._color[id], {[4]=1}
        )
        event:wait(t, "finish")
        event(server, "appear_done", iconid)
    end

    for i, id in ipairs(order) do
        server:fork(intro, id, self:icon_id(id), self.INTRO_DELAY * i)
    end

    for i, id in ipairs(order) do
        print("got event", event:wait(server, "appear_done"))
    end
end

local function hide(server, self)
    local function do_hiding(server, iconid, delay)
        event:sleep(delay)
        local t = tween(self.INTRO_DUR, self._offset[iconid], vec2(500, 0))
        event:wait(t, "finish")
        event(server, "hide_done")
    end

    for i, id in ipairs(self._order) do
        server:fork(do_hiding, self:icon_id(id), self.INTRO_DELAY * i)
    end

    for _, id in ipairs(self._order) do
        event:wait(server, "hide_done")
    end
end

function turn_queue:appear(order)
    self._server:add(appear, self, order)
end

function turn_queue:hide()
    self._server:add(hide, self)
end

function turn_queue:_draw_icon(id, space, color_stack, icon)
    color_stack:push()
    gfx.rectangle("fill", space:unpack())
    color_stack:map(dot, color.create(0.5, 0.5, 0.5, 0.5))
    local line_width = self.ICON_MARGIN.x
    gfx.setLineWidth(line_width)
    gfx.rectangle(
        "line", space:expand(-line_width, -line_width):unpack()
    )
    color_stack:pop()
end

function turn_queue:__draw(x, y)
    for _, id in pairs(self._order) do
        local iconid = self:icon_id(id)
        local barid = self:bar_id(id)
        local text = self._action[id]

        self._color_stack:clear()
        self._color_stack:map(dot, self._color[id])
        gfx.push()
        gfx.translate(self._offset[iconid]:unpack())
        --gfx.rectangle("fill", self._spatials[iconid]:unpack())
        self:_draw_icon(id, self._spatials[iconid], self._color_stack)
        if text then
            gfx.translate(self._offset[barid]:unpack())
            gfx.rectangle("fill", self._spatials[barid]:unpack())
            gfx.setColor(0, 0, 0)
            gfx.setFont(font(20))
            printf(text, self._spatials[barid], "center", "center")
        end
        gfx.pop()
    end
end

return turn_queue
