local keybutton = {}

function keybutton:create()
    local prop_atlas = get_atlas("art/props")

    self.stack = DrawStack.create()
        :stack(prop_atlas:get_frame("button"))
        :within(
            function(x, y, w, h)
                gfx.setColor(0.3, 0.3, 0.3)
                gfx.setFont(font(20))
                gfx.printf("<--", x, y, w, "center")
            end,
            "textbox"
        )
end

function keybutton:__draw()
    self.stack:draw()
end

function keybutton:test(settings)
    --settings.origin = true
end

return keybutton
