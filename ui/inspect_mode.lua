local buff = require "combat.buff"

local inspect_mode = {}

function inspect_mode:create()
    self.index = 1
end

function inspect_mode:find_root()
    local node = self.__parent
    while not node or not node.state do
        node = node.__parent
    end
    return node
end

function inspect_mode:enter()
    local parent = self:find_root()
    if not parent then return end

    self.inspectables = self:get_inspectable()
    parent.ui.help:push("")
    self.active = true
    self.index = math.clamp(self.index, 1, math.max(#self.inspectables, 1))
    self:update_ui()
end

function inspect_mode:left()
    if self.index == 1 then
        self.index = self:size()
    else
        self.index = self.index - 1
    end
    self:update_ui()
end

function inspect_mode:right()
    if self.index >= self:size() then
        self.index = 1
    else
        self.index = self.index + 1
    end
    self:update_ui()
end

function inspect_mode:valid_state()
    return self:find_root() and #self.inspectables > 0
end

function inspect_mode:size()
    return #self.inspectables
end

function inspect_mode:update_ui(initial)
    if not self:valid_state() then return end

    local parent = self:find_root()

    local index = math.clamp(self.index, 1, #self.inspectables)
    local id, buff_name = unpack(self.inspectables[index])
    local buff_data = buff.read(parent.state, buff_name, id)
    buff_data = buff_data or {}
    local text = buff_data.help or "No help"
    local char_ui = parent.ui[id]
    event("ui:buff_highlight", buff_name, id)
    -- We assume text has already been pushed upon entering
    parent.ui.help:swap(text)
    -- Still needs to do other stuff here
end

function inspect_mode:exit()
    local parent = self:find_root()
    if parent then
        parent.ui.help:pop()
    end
    event("ui:buff_highlight")
    self.active = false
end

function inspect_mode:get_inspectable()
    local parent = self:find_root()
    if not parent then return end

    local inspectables = list()
    local pos = parent.state:position()

    for i = 1, 3 do
        local id = pos[i]
        if id then
            for _, key in ipairs{"weapon", "body", "aura"} do
                if buff.read(parent.state, key, id) then
                    inspectables[#inspectables + 1] = list(id, key)
                end
            end
        end
    end



    return inspectables
end

function inspect_mode:__draw()
    if self.active then
        gfx.setColor(0, 0, 0, 0.3)
        gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    end
end

return inspect_mode
