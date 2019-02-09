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

    --[[
    local cross = root:child(require "ui.action_cross")

    cross.__transform.pos = vec2(500, 150)

    local keys = {
        up = "W",
        down = "S",
        left = "A",
        right = "D"
    }

    local name = {
        up = "Magick",
        left = "Attack",
        right = "Defend",
        down = "Item"
    }

    local icons = {
        left = "attack_bw",
        up = "magick_bw",
        down = "item_bw",
        right = "defend_bw"
    }

    cross:set_keys(keys)
    cross:set_texts(name)
    cross:set_icons(icons)
    ]]--
end

function love.update(dt)
    lurker:update()
    root:update(dt)
    timer.update(dt)
end

function love.draw()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
    root:draw(0, 0)

    --stack:draw(0, 0)
end
