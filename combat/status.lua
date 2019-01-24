local status = {}

local keys = {"stun", "poison", "blind"}

function status:create()
    self.duration = dict()
    self.resistance = dict()
    self.damage = dict()
    self.active = dict()
end

function status:damage(arg)
    local s = arg.status

    if self.duration[s] then return end

    local r = self.resistance[s] or 1
    local d = (self.damage[s] or 0) + (arg.damage or 1)
    if d >= r then
        -- Apply status
        self.active[s] = self:child(s, arg)
        -- TODO probe for default duration
        self.duration[s] = arg.duration or 3
        self.damage[s] = 0
    else
        self.damage[s] = d
    end

    return self
end

function status:on_turn_end()
    for t, d in pairs(self.duration) do
        if d >= 1 then
            local a = self.active[t]
            a:destroy()
            
            self.active[t] = nil
            self.duration[t] = nil
            self.resistance[t] = (self.resistance[t] or 1) * 2
        else
            self.duration[t] = d - 1
        end
    end
end

return status
