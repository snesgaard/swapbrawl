local textbox = require "ui.textbox"

local offset = {
    up = vec2(0, 10),
    down = vec2(0, 25),
    right = vec2(20, 0),
    left = vec2(20, 0)
}

local keybutton = {}

function keybutton:create()
    local prop_atlas = get_atlas("art/props")
    self.frame = prop_atlas:get_frame("button")

    self.stack = DrawStack.create()
        :stack(self.frame)
        :within(
            function(x, y, w, h)
                gfx.setColor(0.3, 0.3, 0.3)
                if type(self.key) == "string" then
                    gfx.setFont(font(20))
                    gfx.printf(self.key or "", x, y, w, "center")
                elseif type(self.key) == "function" then
                    self.key(x, y, w, h)
                end
                local dir = self.dir or "up"
                local f = Spatial[dir]
                local o = offset[dir]
                local text = self.text or ""
                local text_width = font(20):getWidth(text) + 20
                local s = f(
                    spatial(x, y, w, h), o.x, o.y, text_width, 40, "center"
                )
                textbox(
                    text, s.x, s.y, s.w, s.h,
                    {font=font(20), hide_background=false}
                )
            end,
            "textbox"
        )
end

function keybutton:__draw(x, y)
    if self.selected then
        local _, _, w, h = self.frame.quad:getViewport()
        local ox, oy = self.frame.offset:unpack()
        local s = spatial(x + ox, y + oy, w, h):scale(2, 2):expand(10, 10)
        gfx.setColor(0.6, 0.7, 0.1, 0.7)
        gfx.rectangle("fill", s.x, s.y, s.w, s.h, 10)
    end
    self.stack:draw()
end

function keybutton:set_key(key)
    self.key = key
    return self
end

function keybutton:set_text(text)
    self.text = text
    return self
end

function keybutton:set_dir(dir)
    if dir ~= "up" and dir ~= "down" and dir ~= "left" and dir ~= "right" then
        error("Invalid dir %s", dir)
    end
    self.dir = dir
    return self
end

function keybutton:test(settings)
    --settings.origin = true
    self:set_dir("right")
end

return keybutton
