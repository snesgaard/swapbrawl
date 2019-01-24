function love.load(arg)
    nodes = Node.create()
    nodes:child(require("combat.turn_queue"))
    nodes.sfx = nodes:child()

    gfx.setBackgroundColor(0.2, 0.3, 0.4, 1)


    for _, path in ipairs(arg) do
        local f = require(path:gsub('.lua', ''))
        nodes.core = nodes:child(require "combat.core", f.args())
    end

    function reload_scene()
        love.load(arg)
    end

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload(f:gsub('.lua', ''))
        reload_scene()
    end
end

function love.update(dt)
    lurker:update()
    nodes:update(dt)
    timer.update(dt)
end

function love.draw()
    nodes:draw(0, 0)
end
