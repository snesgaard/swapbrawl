local function _delay_factor(agility)
    return 1.0 - agility / 10.0
end

local function _get_delay(id, agility, delay)
    local a = agility[id]
    local f = _delay_factor(a or 0)
    return delay * f
end

local function _reorder(delays)
    local order = delays
        :keys()
        :sort(function(a, b)
            return delays[a] < delays[b]
        end)

    return order
end

local function _normalize(_delays, order)
    if #order == 0 then
        return _delays
    end

    local min_delay = _delays[order:head()] or 0
    if min_delay <= 0 then
        return _delays
    end

    for id, delay in pairs(_delays) do
        _delays[id] = delay - min_delay
    end

    return _delays
end

local function _future_index(order, delays, id, agility, delay)
    if not delay then
        error("Delay must be set!")
    end

    local next_index = order:argfind(function(key)
        return delays[key] >= delay
    end)

    -- If we did not find anything assume last place
    return next_index or #order + 1
end

local queue = {}
queue.__index = queue

function queue.create(_delays, _order, _action)
    local this = {}
    this._delays = _normalize(
        _delays or dict(), _order or list()
    )
    this._order = _order or _reorder(this._delays)
    this._action = _action or dict()
    this._bias = dict()
    return setmetatable(this, queue)
end

function queue:setup(actors, agility, _action)
    local _actordelay = dict()

    for _, id in ipairs(actors) do
        _actordelay[id] = _get_delay(id, agility, 10)
    end

    return queue.create(_actordelay, nil, _action)
end

function queue:advance(id, agility, delay, action)
    delay = _get_delay(id, agility, delay or 10)
    local prev_delay = self._delays[id] or 0
    delay = delay + prev_delay
    -- remove actor from agility
    local cur_index = self._order:argfind(id)
    -- Remove if present in order list
    _order = cur_index and self._order:erase(cur_index) or self._order
    -- Get future index
    local index = _future_index(_order, self._delays, id, agility, delay)
    return queue.create(
        self._delays:set(id, delay), _order:insert(id, index),
        self._action:set(id, action)
    )
end

function queue:remove(id)
    local cur_index = self._order:argfind(id)
    if cur_index then
        return queue.create(
            self._delays:set(id), self._order:erase(cur_index),
            self._action:set(id)

        )
    else
        return self
    end
end

function queue:promote(id, action)
    local next_action = self._action:set(id, action)
    local index = self._order:argfind(id)
    local next_order = self._order
    if index then
        next_order = next_order:erase(index)
    end
    next_order = next_order:insert(id, 1)
    local next_delay = self._delays:set(id, 0)

    return queue.create(next_delay, next_order, next_action)
end

function queue:next()
    local id = self._order:head()
    return id, self._action[id]
end


return queue
