local function invoke(self, f, ...)
    if self.on_action_begin then
        self.on_action_begin(f, ...)
    end
    f(self, ...)
    if self.on_action_end then
        self.on_action_end(f, ...)
    end
end

local queue = {}

function queue:create()
    self.__queue = list()
    self.__active_handler = nil
end

function queue:submit(f, ...)
    local bundle = {f, ...}
    self.__queue[#self.__queue + 1] = bundle
    if not self.__active_handler then
        self.__active_handler = self:fork(self.handle)
    end
    return bundle
end

function queue:handle()
    if self.on_handle_begin then
        self.on_handle_begin(self.__queue)
    end

    while #self.__queue > 0 do
        local arg = self.__queue:head()
        self.__queue = self.__queue:body()
        invoke(self, unpack(arg))
    end
    self.__active_handler = nil

    if self.on_handle_end then
        self.on_handle_end()
    end
end

return queue
