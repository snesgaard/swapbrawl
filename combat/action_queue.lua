local queue = {}

function queue:create()
    self.__queue = list()
    self.__active_handler = nil
end

function queue:submit(f, ...)
    self.__queue[#self.__queue + 1] = {...}
    if not self.__active_handler then
        self:fork(self.handle)
    end
end

function queue:handle()
    local function invoke(f, ...)
        if self.on_action_begin then
            self.on_action_begin(f, ...)
        end
        f(self, ...)
        if self.on_action_end then
            self.on_action_end(f, ...)
        end
    end

    while #self.__queue > 0 do
        local arg = self.__queue:head()
        self.__queue = self.__queue:body()
        invoke(unpack(arg))
    end
end

return queue
