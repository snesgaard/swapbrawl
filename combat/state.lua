local function traverse(dir, parts, combo)
    if #parts < 1 then
        return combo
    end
    if not dir then
        return
    end
    local k = parts:head()
    local v = dir[k]
    if v then
        return traverse(
            v, parts:body(), (combo or list(dir)):insert(v)
        )
    end
end

local state = {}
state.__index = state

function state:__tostring()
    return tostring(self.root)
end

function state.create(root)
    local this = {}

    this.root = root or dict{
        actor = dict{
            health = dict{},
            max_health = dict{},
            stamina = dict{},
            max_stamina = dict{},
            type = dict{},
        },
        position = dict{
            -- Convention : abs(1-3) is frontline. abs(3-) is reserve
            -- Negative numbers are foes, positve are players
        },
        echo = dict{
            on_attack = dict{},
            on_damage = dict{},
            on_heal = dict{},
        },
        event = dict{

        }
    }

    if not root then
        for _, d in pairs(this.root.echo) do
            d.order = list()
            d.func = dict()
        end
        for _, d in pairs(this.root.event) do
            d.order = list()
            d.func = dict()
        end
    end
    return setmetatable(this, state)
end

function state:read(path)
    local parts = string.split(path, '/')

    local t = traverse(self.root, parts)
    if t then return t:tail() end
end

function state:map(path, m, ...)
    local v = self:get(path)
    if not v then return end
    return self:set(path, m(v, ...))
end

function state:write(path, value)
    local parts = string.split(path, '/')
    local dirs = traverse(self.root, parts:erase())

    if not dirs then
        log.warn("Path <%s> not valid", path)
        return
    end

    for i = #parts, 1, -1 do
        local d = dirs[i]
        local p = parts[i]
        value = d:set(p, value)
    end

    return state.create(value)
end

function state:print()
    print(self)
    return self
end

local function valid_echo(d)
    return d.order and d.func
end

function state:set_echo(path, f)
    local parts = string.split(path, '/')
    local dirs = traverse(self.root, parts:erase())

    if not dirs or not valid_echo(dirs:tail()) then
        log.warn("Echo path <%s> not valid", path)
        return
    end

    local echo = dirs:tail()
    local func = echo.func
    local order = echo.order
    local id = parts:tail()

    func = func:set(id, f)

    local index = order:argfind(id)

    if not f then
        order = order:erase(index)
    elseif not index then
        order = order:insert(id)
    end

    echo = echo
        :set("func", func)
        :set("order", order)

    for i = #parts - 1, 1, -1 do
        echo = dirs[i]:set(parts[i], echo)
    end

    return state.create(echo)
end

function state:echo(path, data)
    local parts = string.split("echo/" .. path, '/')
    local dirs = traverse(self.root, parts:erase())

    if not dirs or not valid_echo(dirs:tail()) then
        log.warn("Echo path <%s> not valid", path)
        return
    end

    local echo = dirs:tail()

    local state = self
    local new_state

    for _, id in ipairs(echo.order) do
        local f = echo.func[id]
        data, new_state = f(id, state, data)
        state = new_state or state
    end

    return data, state
end

function state:event(path, data)
    local parts = string.split("echo/" .. path, '/')
    local dirs = traverse(self.root, parts:erase())

    if not dirs or not valid_echo(dirs:tail()) then
        log.warn("Echo path <%s> not valid", path)
        return
    end

    local echo = dirs:tail()

    local state = self
    local new_state

    for _, id in ipairs(echo.order) do
        local f = echo.func[id]
        new_state = f(id, state, data)
        state = new_state or state
    end

    return state
end

return function()
    return state.create()
end
