return function(opt, x, y, w, h)
    local color = opt.color or {1, 1, 1}
    gfx.setColor(unpack(color))
    gfx.rectangle("fill", x, y, w, h, 2)
    gfx.setColor(0, 0, 0, 0.6)
    gfx.rectangle("fill", x, y, w, h, 2)
    gfx.setColor(unpack(color))
    if opt.value > opt.min then
        local ratio = (opt.value - opt.min) / (opt.max - opt.min)
        gfx.rectangle("fill", x, y, w * ratio, h, 2)
    end
end
