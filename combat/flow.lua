local setup = require "combat.setup"
require "combat.update_state"

local states = {idle={}, setup={}}

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

    for _, id in ipairs(party_ids + foes_ids) do
        setup.init_actor_visual(root, state, id)
    end

    the_thing = {spatial = spatial()}

    event:listen(root.actors.fencer_0001.sprite, "slice/origin", function(s) the_thing.spatial = s end)

    data.root = root
    data.state = state
end



function states.idle:enter(data)

end

local function draw(data)
    if data.root then
        data.root:draw()
    end

    gfx.rectangle("line", the_thing.spatial:unpack())
end

local flow = {
    states = states,
    data = {},
    edges = {
        {from="idle", to="setup", name="begin"},
    },
    draw = draw,
    init = "idle"
}

local container = {}

function container:create()
    self.fsm = self:child(fsm, flow)
end

function container:test(settings)
    settings.origin = true
    self.fsm:begin(list("fencer", "alchemist"), list("fencer", "fencer"))
end

function love.keypressed(key)
end


return container
