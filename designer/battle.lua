function love.load(arg)
    root = Node.create()
    root.sfx = root:child()

    --gfx.setBackgroundColor(0.2, 0.3, 0.4, 0)
    gfx.setBackgroundColor(0, 0, 0, 0)

    for _, path in ipairs(arg) do
        local f = require(path:gsub('.lua', ''))
        root.core = root:child(require "combat.core", f.args())
    end

    function reload_scene()
        love.load(arg)
    end

    function root.keypressed(...)
        root.core:keypressed(...)
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
    root:update(dt)
    timer.update(dt)
end

function love.draw()
    root:draw(0, 0)
end
