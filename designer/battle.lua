function love.load(arg)
    root = Node.create()
    root.sfx = root:child()

    --gfx.setBackgroundColor(0.2, 0.3, 0.4, 0)

    function reload_scene()
        love.load(arg)
    end

    function root.keypressed(...)
        stack:keypressed(...)
    end

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload(f:gsub('.lua', ''))
        reload_scene()
    end

    stack = Stack.create()

    local p = arg:head()
    if p then
        local f = require(p:gsub('.lua', ''))
        local c = require "combat.core"
        stack:push(c.initialize, f.args())
    end
end

function love.update(dt)
    lurker:update()
    root:update(dt)
    timer.update(dt)
    stack:update(dt)
end

function love.draw()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    root:draw(0, 0)
    stack:draw(0, 0)
    --stack:draw(0, 0)
end
