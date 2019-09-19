function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function love.load(arg)
    nodes = Node.create()
    --gfx.setBackgroundColor(0.2, 0.3, 0.4, 1)
    gfx.setBackgroundColor(0, 0, 0, 0)

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

    dress = suit.new()
    --gfx.setBackgroundColor(0.5, 0.5, 0.5)

end

local combo = {value = 1, items = {'A', 'B', 'C'}}

local slider_state = {value=75, min=0, max=100, step=20}

function love.update(dt)
   --dress:Input(input, dress.layout:row())
   tween.update(dt)
   nodes:update(dt)
   lurker:update(dt)
   event:update(dt)
   event:spin()
end

function love.draw()
    local w, h = gfx.getWidth(), gfx.getHeight()
    gfx.setColor(0.2, 0.3, 0.4, 1)
    gfx.rectangle("fill", 0, 0, w, h)
    gfx.setColor(1, 1, 1)
    gfx.line(0, h / 2, w, h / 2)
    gfx.line(w / 2, 0, w / 2, h)
    if not settings.origin then
        nodes:draw(w / 2, h / 2)
    else
        nodes:draw(0, 0)
    end
    gfx.setColor(1, 1, 1)
    dress:draw()
end
