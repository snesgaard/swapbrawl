local setup = require "combat.setup"
local turn = require "combat.turn_queue"
require "combat.update_state"

local function remap(node)
    node.__remap_handle = dict()

    for key, func in pairs(node.remap or {}) do
        local function f(...) return func(node, ...) end
        node.__remap_handle[key] = event:listen(key, f)
    end

    local f = node.on_destroyed or identity

    function node.on_destroyed(self)
        for _, handle in ipairs(self.__remap_handle) do
            event:clear(handle)
        end
        return f(self)
    end
end

local states = {idle={}, setup={}, begin_turn={}}

function states.setup:enter(data, party, foes)
    local party_ids = party:map(id_gen.register)
    local foes_ids = foes:map(id_gen.register)

    local state = state.create()

    for index, id in ipairs(party_ids) do
        state = setup.init_actor_state(state, id, index, party[index])
    end

    for index, id in ipairs(foes_ids) do
        state = setup.init_actor_state(state, id, -index, foes[index])
    end

    local root = self:child()
    root.actors = root:child()
    --root.actors.__transform.scale = vec2(2, 2)
    root.ui = root:child()

    root.ui.turn = root.ui:child(require "ui.turn_queue")
    root.ui.turn.__transform.pos = vec2(gfx.getWidth() - 400, 100)

    remap(root.ui.turn)

    for _, id in ipairs(party_ids + foes_ids) do
        setup.init_actor_visual(root, state, id)
    end


    data.root = root
    data.state = state
    return self:enter_combat()
end

function states.begin_turn:enter(data)
    local state, epic = data.state:transform(
        {path="combat.turn_queue:new_turn"}
    )
    self:broadcast(unpack(epic))
    data.state = state
end

function states.idle:enter(data)

end

local function draw(self, data, x, y)
    if data.root then
        data.root:draw(x, y)
    end
end

local function broadcast(self, data, ...)
    for key, epoch in pairs({...}) do
        event(epoch.id, epoch.state, epoch.info, epoch.args)
    end
end

local flow = {
    states = states,
    data = {},
    edges = {
        {from="idle", to="setup", name="begin"},
        {from="setup", to="begin_turn", name="enter_combat"}
    },
    methods = {__draw=draw, broadcast = broadcast},
    init = "idle"
}

local container = {}

function container:create()
    self.fsm = self:child(fsm, flow)
end

function container:test(settings)
    settings.origin = true
    self.fsm:begin(list("fencer", "alchemist", "mage"), list("vampire", "vampress"))
end


return container
