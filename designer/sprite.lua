function love.load(arg)
    nodes = Node.create()
    gfx.setBackgroundColor(0.2, 0.3, 0.4, 1)

    local sprite_path = arg[1]
    local animation_name = arg[2]

    local typedata = require(sprite_path:gsub('.lua', ''))

    local sprite = nodes:child(Sprite, typedata.sprite())
    sprite:set_animation(animation_name or "idle")
    sprite.on_hitbox:listen(print)
end

function love.update(dt)
   nodes:update(dt)
end

function love.draw()
    local x, y = gfx.getWidth() / 2, gfx.getHeight() / 2
    nodes:draw(x, y)
    gfx.rectangle("fill", x - 1, y - 1, 3, 3)
end
