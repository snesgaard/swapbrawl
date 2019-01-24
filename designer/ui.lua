function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function love.load(arg)
    nodes = NodeUI.create()
    gfx.setBackgroundColor(0.2, 0.3, 0.4, 1)

    settings = {origin = false}

    local function creation(path)
        local p = path:gsub('.lua', '')
        local t = reload(p)
        return nodes:child(t)
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
end

function love.update(dt)
    lurker:update()
    nodes:update(dt)
    timer.update(dt)
end

function love.draw()
    gfx.setColor(1, 1, 1, 0.5)
    gfx.line(0, gfx.getHeight() / 2, gfx.getWidth(), gfx.getHeight() / 2)
    gfx.line(gfx.getWidth() / 2, 0, gfx.getWidth() / 2, gfx.getHeight())
    nodes:draw(gfx.getWidth() / 2, gfx.getHeight() / 2)
end
