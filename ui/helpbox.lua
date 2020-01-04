local textbox = require "ui.textbox"
local helpbox = {}

function helpbox:create()
    self.opt = {margin=vec2(10, 10), title="<Help>"}
    self.text = list()
end

function helpbox:set_text(text)
    error("deprecated")
    return self
end

function helpbox:set_size(w)
    self.width = w or self.width
    return self
end

function helpbox:__draw()
    local text = self.text:tail()
    if not text or not self.width then return end
    local text, title = unpack(self.text:tail())
    self.opt.title = title or "<Help>"
    textbox(text, 0, 0, self.width, nil, self.opt)
end

function helpbox:test()
    self:set_size(200)
    self:push("Deal heavy damage and stun.")
end

function helpbox:push(text, title)
    if not text then
        error("you cannot push an empty text field")
    end
    self.text[#self.text + 1] = {text, title}
    return self
end

function helpbox:pop()
    self.text[#self.text] = nil
    return self
end

function helpbox:swap(...)
    return self:pop():push(...)
end

return helpbox
