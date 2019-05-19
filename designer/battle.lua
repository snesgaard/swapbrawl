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
        root.player_control:keypressed(...)
    end

    --[[
    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload(f:gsub('.lua', ''))
        reload_scene()
    end
    ]]--


    root.core = root:child(require "combat.core")
    root.player_control = Stack.create()
    root.player_control:push(require "combat.player_control")

    function root.player_control.submit_action(user, ability, targets)
        return root.core:execute(user, ability, unpack(targets))
    end
    function root.player_control.play_card(...)
        return root.core:play_card(...)
    end

    root.core.on_epoch:listen(function(...)
        root.player_control:invoke("on_epoch", ...)
    end)

    function root.core.on_player_turn(state, id)
        root.player_control:invoke("on_next_turn", state, id)
    end

    --player_stack = Stack.create()

    local p = arg:head()
    if p then
        local f = require(p:gsub('.lua', ''))
        root.core:setup_battle(f.args())

        root.core:next_turn()
        --player_stack:push(require "combat.player_control")

        --player_stack:invoke("begin", core_stack)
        --core_stack:invoke("begin", player_stack)
    end
end

function love.update(dt)
    lurker:update()
    root:update(dt)
    timer.update(dt)
    root.player_control:update(dt)
end

function love.draw()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    root:draw(0, 0)
    root.player_control:draw(0, 0)
end
