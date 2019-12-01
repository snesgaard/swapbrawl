local textbox = require "ui.textbox"
local helpbox = {}

function helpbox:create()
    self.opt = {margin=vec2(10, 10)}
end

function helpbox:set_text(text)
    self.text = text
    return self
end

function helpbox:set_size(w)
    self.width = w or self.width
    return self
end

function helpbox:__draw()
    if not self.text or not self.width then return end
    textbox(self.text, 0, 0, self.width, nil, self.opt)
end

function helpbox:test()
    self:set_size(200)
    self:set_text("Deal heavy damage and stun. Deal heavy damage and stun. Deal heavy damage and stun. Deal heavy damage and stun.Deal heavy damage and stun.")
end

return helpbox
