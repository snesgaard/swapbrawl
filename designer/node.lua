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
        local n = nodes:child(t)
        nodes[p] = n
        return n
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

local tvec = vec2(0, 0)

function love.update(dt)
    require("lovebird").update()
    local step = dt * 100
    if not settings.disable_navigation then
        if love.keyboard.isDown("left") then
            tvec.x = tvec.x + step
        end
        if love.keyboard.isDown("right") then
            tvec.x = tvec.x - step
        end
        if love.keyboard.isDown("up") then
            tvec.y = tvec.y + step
        end
        if love.keyboard.isDown("down") then
            tvec.y = tvec.y - step
        end
    end

   --dress:Input(input, dress.layout:row())
   tween.update(dt)
   nodes:update(dt)
   lurker:update(dt)
   event:update(dt)
   event:spin()
end



function love.draw()
    local w, h = gfx.getWidth(), gfx.getHeight()
    gfx.translate(tvec.x, tvec.y)
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
