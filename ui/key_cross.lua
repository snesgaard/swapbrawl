local keybutton = require "ui.keybutton"

local keycross = {}

function get_cross_offset(v)
    return v * vec2(75, 65)
end

local cross_offset = {
    W = vec2(0, -1),
    A = vec2(-1, 0),
    S = vec2(0, 0),
    D = vec2(1, 0),
    up = vec2(0, -1),
    left = vec2(-1, 0),
    down = vec2(0, 0),
    right = vec2(1, 0),
}

function get_global_offset(v)
    return v * vec2(250, 100)
end

local global_offset = {
    W = vec2(-1, 0),
    A = vec2(-1, 0),
    S = vec2(-1, 0),
    D = vec2(-1, 0),
    up = vec2(1, 0),
    left = vec2(1, 0),
    down = vec2(1, 0),
    right = vec2(1, 0),
}

local function draw_arrow(dir, x, y, w, h)
    local ey = y + h - 5
    local cy = y + h * 0.5
    local by = y + 5
    local ex = x + w - 5
    local cx = x + w * 0.5
    local bx = x + 5
    gfx.setLineWidth(3)
    if dir == "right" then
        gfx.line(bx, cy, ex, cy)
        gfx.polygon(
            "fill",
            ex + 5, cy,
            ex - 10, cy + 5,
            ex - 10, cy - 5
        )
    elseif dir == "up" then
        gfx.line(cx, by, cx, ey)
        gfx.polygon(
            "fill",
            cx, by - 5,
            cx - 5, by + 5,
            cx + 5, by + 5
        )
    elseif dir == "left" then
        gfx.line(bx, cy, ex, cy)
        gfx.polygon(
            "fill",
            bx - 5, cy,
            bx + 10, cy + 5,
            bx + 10, cy - 5
        )
    elseif dir == "down" then
        gfx.line(cx, by, cx, ey)
        gfx.polygon(
            "fill",
            cx, ey + 5,
            cx - 5, ey - 5,
            cx + 5, ey - 5
        )
    end
end

function keycross:create()
    self.keys = {
        W = self:child(keybutton):set_key("W"):set_dir("up"),
        A = self:child(keybutton):set_key("A"):set_dir("left"),
        S = self:child(keybutton):set_key("S"):set_dir("down"),
        D = self:child(keybutton):set_key("D"):set_dir("right"),
        up = self:child(keybutton)
            :set_key(curry(draw_arrow, "up"))
            :set_dir("up"),
        left = self:child(keybutton)
            :set_key(curry(draw_arrow, "left"))
            :set_dir("left"),
        down = self:child(keybutton)
            :set_key(curry(draw_arrow, "down"))
            :set_dir("down"),
        right = self:child(keybutton)
            :set_key(curry(draw_arrow, "right"))
            :set_dir("right"),
    }

    for key, node in pairs(self.keys) do
        local co = get_cross_offset(cross_offset[key])
        local go = get_global_offset(global_offset[key])
        node.__transform.pos = co + go
    end

    self:set_text()
end


function keycross:set_text(text)
    text = text or {}
    for key, node in pairs(self.keys) do
        local t = text[key]
        if not t then
            node:hide()
        else
            node:show():set_text(t)
        end
    end
    return self
end


function keycross:test()
    self:set_text{
        A = "Roundslash", S = "Backstep", D = "Jab", W = "Flying Kick",
        up = "Potion", down = "Guard", left = "Swap", right = "Antidote"
    }
    self:select("A")
end

function keycross:select(key)
    if not key then
        for _ , node in pairs(self.keys) do
            node.selected = false
        end
    else
        self.keys[key].selected = true
    end
end

return keycross
