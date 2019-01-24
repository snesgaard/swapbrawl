local ui = {}

function ui:create()
    self.__layout = dict{
        items = dict()
    }
    self.__dress = suit.new()
    self.__items = {}
    self.__queue = list()
    self.__animations = list()

    self.__layout_spec = {}
end

function ui:padding()
    return 5, 5
end

function ui:pos()
    return gfx.getWidth() - 150, 50
end

function ui.item_size()
    return 40, 40
end

function ui:draw_item(x, y, w, h, item)
    local frame = get_atlas("art/icons"):get_animation("fencer_icon")

    --atlas:draw("fencer_icon", x, y, 0, 2, 2)
    frame:draw(x, y, 0, 2, 2)
end

function ui:__draw(x, y)
    self.__dress:draw()
    for _, s in pairs(self.__layout.items) do
        self:draw_item(s:unpack())
    end
end

function ui:__update(dt)
    local s = self.__layout.text or spatial(0, 0, 300, 20)
    self.__dress:Label("Turn Order", {align="left"}, s:unpack())
end

function ui:push_back(item)
    self:insert(item)
end

function ui:push_front(item)
    self:insert(item, 1)
end

function ui:insert(item, index)
    local queue = self.__queue:insert(item, index)
    self.__queue = queue

    local function action(self)
        local old_layout = self.__layout
        local pos = self:pos()
        local size = self:item_size()
        local base = spatial()
            :set_position(self:pos())
            :set_size(self:item_size())

        old_layout.text = base:set_size(300, 20)
        local new_layout = {items = {}}
        local tween = {}
        for index, i in ipairs(queue) do
            base = base:down(self:padding())
            new_layout.items[i] = base
        end

        old_layout.items[item] = new_layout.items[item]:move(200, 0)

        local tween = {}
        for index, i in ipairs(queue) do
            local o = old_layout.items[i]
            local n = new_layout.items[i]
            tween[o] = n
        end

        self:wait(timer.tween(0.15, tween))
    end

    self:__submit_animation(action)
end

function ui:remove(item)
    local function index_n_item()
        if type(item) == "number" then
            return item, self.__queue[item]
        else
            return self.__queue:argfind(item), item
        end
    end

    local index, item = index_n_item()

    if not index or not item then return end

    local old_queue = self.__queue
    local queue = self.__queue:erase(index)
    self.__queue = queue

    local function action(self)
        local t = type(get_index)
        local index = t == "function" and get_index(self) or get_index
        self.__queue = self.__queue:erase(index)

        local old_layout = self.__layout

        local pos = self:pos()
        local size = self:item_size()
        local base = spatial()
            :set_position(self:pos())
            :set_size(self:item_size())

        old_layout.text = base:set_size(300, 20)
        local new_layout = {items = {}}
        local tween = {}
        for index, i in ipairs(queue) do
            base = base:down(self:padding())
            new_layout.items[i] = base
        end

        new_layout.items[item] = old_layout.items[item]:move(200, 0)

        local tween = {}
        for index, i in ipairs(old_queue) do
            local o = old_layout.items[i]
            local n = new_layout.items[i]
            tween[o] = n
        end

        self:wait(timer.tween(0.15, tween))

        old_layout.items[item] = nil
    end

    self:__submit_animation(action)
end

function ui:pop()
    self:remove(1)
end

function ui:__submit_animation(f)
    self.__animations[#self.__animations + 1] = f
    if not self.__active_handler then
        self.__active_handler = self:fork(self.__handle_animation)
    end
end

function ui:__handle_animation()
    while #self.__animations > 0 do
        local a = self.__animations:head()
        self.__animations = self.__animations:body()
        a(self)
    end
    self.__active_handler = nil
end

return ui
