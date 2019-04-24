function love.load(arg)
    root = Node.create()
    root.sfx = root:child()
    --root.hand = root:child(require "ui.card_hand")
    --root.__transform.pos = vec2(330, 600)

    --gfx.setBackgroundColor(0.2, 0.3, 0.4, 0)

    function reload_scene()
        love.load(arg)
    end

    function root.keypressed(...)
        core_stack:keypressed(...)
        player_stack:keypressed(...)
    end

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload(f:gsub('.lua', ''))
        reload_scene()
    end

    core_stack = Stack.create()

    player_stack = Stack.create()

    local p = arg:head()
    if p then
        local f = require(p:gsub('.lua', ''))
        local c = require "combat.core"
        core_stack:push(c.initialize, f.args())

        player_stack:push(require "combat.player_control")
        
        player_stack:invoke("begin", core_stack)
        core_stack:invoke("begin", player_stack)
    end
end

function love.update(dt)
    lurker:update()
    root:update(dt)
    timer.update(dt)
    core_stack:update(dt)
    player_stack:update(dt)
end

function love.draw()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    root:draw(0, 0)
    core_stack:draw(0, 0)
    player_stack:draw(0, 0)
end
