combat = require "combat"
require "combat.shortcuts"

function love.load(arg)
    function reload_scene()
        love.load(arg)
    end

    root = combat.setup({"fencer", "fencer"}, {"fencer"})
    root:fork(
        combat.animation.melee_attack, root:read(),
        "fencer_0001", "fencer_0003"
    )
end

function love.update(dt)
    lurker:update()
    root:update(dt)
    tween.update(dt)
    event:update(dt)
    event:spin()
end

function love.draw()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    root:draw(0, 0)
end
