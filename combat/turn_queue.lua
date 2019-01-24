local function invoke(id, f, ...)
    return f(id, ...)
end

local queue = {}

function queue:create()
    self._queue = list()
    self._on_action_begin = event()
    self._on_action_end = event()
end

function queue:add(id, func, ...)
    self._queue[#self._queue + 1] = {id, func, ...}
    return self:awake()
end

function queue:_awake()
    if not self._handler_co then
        self._handler_co = self:fork(self._handler)
    end
    return self
end

function queue:_handler()
    if #self._queue == 0 then return end

    while #self._queue > 0 do
        local action = self._queue:head()
        self._queue = self._queue:body()

        self._on_action_begin(unpack(action))
        invoke(unpack(action))
        self._on_action_end(unpack(action))
    end

    self._handler_co = nil
end

return queue
