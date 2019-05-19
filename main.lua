--require("lovedebug")
require "nodeworks"

actor = require "actor"

ui = require "ui"

charbarui = require "ui.char_bar"

state = require "combat.state"

function love.load(arg)
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
    }

    entry = entrymap[entry]
    if entry then
        require(entry)
    end
    if love.load ~= old_load then
        return love.load(arg:sub(2))
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end

    if root and root.keypressed then
        root.keypressed(key, scancode, isrepeat)
    end
end
