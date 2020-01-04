local textbox = {}
textbox.__index = textbox


textbox.theme = {
    background = {color = {0, 0, 0.2, 0.3}},
    text = {color = {1, 1, 1}}
}

function textbox.get_vertical_alignment(valign, font, h)
	if valign == "center" then
		return (h - font:getHeight()) / 2
	elseif valign == "bottom" then
		return h - font:getHeight()
	end
	-- else: "middle"
	return 0
end

function textbox.draw_text(text, x, y, w, h, font, opt)
    y = y + textbox.get_vertical_alignment(opt.valign, font, h)

    gfx.setColor(unpack(opt.color or textbox.theme.text.color))
    gfx.setFont(font)
    gfx.printf(text, x+2, y, w-4, opt.align or "center")
end

function textbox:get_shape(text, w, opt)
    local font = opt.font or font(12)
    local lh = font:getHeight()
    local w, wrapped_text = font:getWrap(text, w)
    return w, #wrapped_text * lh
end

function textbox:__call(text, x, y, w, h, opt)
    opt = opt or {}
    text = text or ""
    local font = opt.font or font(12)
    local default_w, default_h = self:get_shape(text, w, opt)
    w = w or default_w
    h = h or default_h

    local margin = opt.margin or vec2()

    local text_border = spatial(x, y, w, h)
        :move(margin.x, margin.y)
        :expand(margin.x * 2, margin.y * 2)
    local title_width = math.max(
        font:getWidth(opt.title or "") + margin.x,
        100
    )
    local title_border = text_border
        :up(10, 0, title_width, 15)
        :expand(margin.x, margin.y, "left", "bottom")
    local title_text = title_border
        :expand(-margin.x, -margin.y)


    if not opt.hide_background then
        local color = opt.backgound_color or textbox.theme.background.color
        gfx.setColor(unpack(color))
        gfx.rectangle("fill", text_border:unpack(5))
        if opt.title then
            gfx.rectangle("fill", title_border:unpack(5))
        end
    end

    textbox.draw_text(text, x + margin.x, y + margin.y, w, h, font, opt)
    if opt.title then
        local title_opt = {
            color = opt.color
        }
        textbox.draw_text(
            opt.title, title_text.x, title_text.y, title_text.w, title_text.h,
            font, title_opt
        )
    end
end

return setmetatable(textbox, textbox)
