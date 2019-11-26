local textbox = {}
textbox.__index = textbox


textbox.theme = {
    background = {color = {0, 0, 0.2, 0.3}},
    text = {color = {1, 1, 1}}
}

function textbox.get_vertical_alignment(valign, font, h)
	if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font:getHeight()
	end
	-- else: "middle"
	return (h - font:getHeight()) / 2
end

function textbox.draw_text(text, x, y, w, h, font, opt)
    y = y + textbox.get_vertical_alignment(opt.valign, font, h)

    gfx.setColor(unpack(opt.color or textbox.theme.text.color))
    gfx.setFont(font)
    gfx.printf(text, x+2, y, w-4, opt.align or "center")
end

function textbox:__call(text, x, y, w, h, opt)
    opt = opt or {}
    local font = opt.font or font(12)
    w = w or font:getWidth(text) + 4
    h = h or font:getHeight() + 4

    if not opt.hide_background then
        local color = opt.backgound_color or textbox.theme.background.color
        gfx.setColor(unpack(color))
        gfx.rectangle("fill", x, y, w, h, opt.backround_radius or 10)
    end

    textbox.draw_text(text, x, y, w, h, font, opt)
end

return setmetatable(textbox, textbox)
