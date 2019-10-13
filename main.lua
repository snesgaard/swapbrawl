require "lovedebug"
require "nodeworks"

function love.load(arg)
    log.outfile = "./log.txt"
    -- SET A BATTLE AS DEFALT
    gfx.setBackgroundColor(0, 0, 0, 0)
    arg = list(unpack(arg))

    local old_load = love.load
    local entry = arg[1] or "battle"
    log.info("Entering %s", entry)

    entry = entry:gsub('/', '')

    local entrymap = {
        node = "designer/node",
        ui = "designer/ui",
        battle = "designer/battle",
        sprite = "designer/sprite",
        ability = "designer/ability",
        card = "designer/card",
        cards = "designer/card",
        animation = "test/animation"
    }
    entry = entrymap[entry]
    if entry then
        require(entry)
    end
    if love.load ~= old_load then
        return love.load(arg:sub(2))
    end
end

local input_from_key = {
    left = "left", right = "right", space = "confirm", escape = "abort",
    tab = "swap"
}

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end

    if root and root.keypressed then
        root:invoke("keypressed", key, scancode, isrepeat)
    end

    local input = input_from_key[key]

    if input then event("inputpressed", input) end

    event("keypressed", key, scancode, isrepeat)
end
