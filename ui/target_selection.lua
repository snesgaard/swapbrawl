local position = require "combat.position"

local marker = require "sfx.marker"

local function get_marker_pos(id, state)
    return position.get_world(state:position(), id) - vec2(0, 75)
end

local function get_side_flag(user, state)
    if not user or state:position(user) * party_flag > 0 then
        return 1
    else
        return -1
    end
end

local function initial_target_sort(state)
    return function(a, b)
        local pa = state:position(a)
        local pb = state:position(b)
        return pa > pb
    end
end

local function find_initial_position(ids, state)
    for i = 2, #ids do
        local a = ids[i]
        local b = ids[i - 1]
        local pa = state:position(a)
        local pb = state:position(b)
        if (pa * pb < 0) then
            return i - 1
        end
    end
    return 0
end

local node = {}

function node:create(ids, state, user, secondary_ids)
    self.ids = ids:sort(initial_target_sort(state))
    local id = self.ids:head()
    self.state = state
    self.secondary_ids = secondary_ids or function() end
    self.marker = self:child(marker)
    self:_setup_visuals()

    self:change_target(find_initial_position(self.ids, state))
end

function node:get_current()
    local s = self.secondary_ids(
        self.state, self.ids:head(), self.ids:erase(1)
    )
    if type(s) == "table" then
        return self.ids:head(), unpack(s)
    else
        return self.ids:head(), s
    end
end

function node:keypressed(key)
    if key == "left" then
        self:change_target(-1)
    elseif key == "right" then
        self:change_target(1)
    elseif key == "tab" then
        self:swap_faction()
    elseif key == "space" and self.on_select then
        self.on_select(self:get_current())
    end
end

function node:swap_faction()
    local current = self.state:position(self:get_current())

    local foes = self.ids
        :filter(function(id)
            return position.is_foe(self.state:position(), id)
        end)
        :sort(function(a, b)
            return self.state:position(a) > self.state:position(b)
        end)
    local party = self.ids
        :filter(function(id)
            return position.is_party(self.state:position(), id)
        end)
        :sort(function(a, b)
            return self.state:position(a) < self.state:position(b)
        end)

    if #party <= 0 or #foes <= 0 then
        return
    end

    if current < 0 then
        self:change_target(party:head())
    else
        self:change_target(foes:head())
    end
end

function node:change_target(arg)
    if type(arg) == "string" then
        local index = self.ids:argfind(arg)
        return self:change_target(index - 1)
    end
    self.ids = self.ids:cycle(arg)
    self:_setup_visuals()
end

function node:_setup_visuals()
    self.marker.__transform.pos = get_marker_pos(
        self:get_current(), self.state
    )
    self.marker:selection()
    self.draw_positions = list(self:get_current())
        :map(function(id)
            local p = position.get_world(self.state:position(), id)
            return p - vec2(0, 75)
        end)
end

function node:__draw()
    self.marker:mass_draw(self.draw_positions:unpack())
end


return node
