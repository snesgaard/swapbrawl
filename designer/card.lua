local state = require "combat.state"
local deck = require "combat.deck"

function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function love.load(arg)
    nodes = Node.create()
    nodes.state = state()
    gfx.setBackgroundColor(0.2, 0.3, 0.4, 1)

    settings = {origin = false}

    local function creation(path)
        local p = path:gsub('.lua', '')
        local card = require "ui.card"
        local t = reload(p)

        nodes.state, cardid = deck.create(nodes.state, t)

        return nodes:child(card, nodes.state, cardid)
    end

    for _, path in ipairs(arg) do
        local n = creation(path)
        if n.test then
            n:fork(n.test, settings)
        end
    end

    function reload_scene()
        love.load(arg)
    end

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload_scene()
    end

    dress = suit.new()
    --gfx.setBackgroundColor(0.5, 0.5, 0.5)
end

local combo = {value = 1, items = {'A', 'B', 'C'}}

local slider_state = {value=75, min=0, max=100, step=20}

function love.update(dt)
   --dress:Input(input, dress.layout:row())
   nodes:update(dt)
   lurker:update(dt)
end

function love.draw()
    nodes:draw(gfx.getWidth() / 2, gfx.getHeight() / 2)
    gfx.setColor(1, 1, 1)
    dress:draw()
end
