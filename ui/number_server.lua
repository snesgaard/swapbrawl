local DamageNumber = {}
DamageNumber.__index = DamageNumber

function DamageNumber:create(number, master, type)
    local type2color = {
        heal = {50, 255, 120, 0},
        default = {255, 120, 50, 0},
        crit = {255, 50, 20, 0}
    }

    local color = type2color[type] or type2color.default
    for i, c in ipairs(color) do
        color[i] = c / 255
    end

    self.opt = {
        align = "center",
        valign = "center",
        font = font(25),
        color = {
            normal = {
                fg = color
            }
        }
    }

    self.text = tostring(number)

    local type2scale = {
        default = 1,
        crit = 1,
    }

    self.scale = 5
    self.end_scale = type2scale[type] or type2scale.default
    self.master = master

    self.spatial = spatial():expand(200, 50)

    self:fork(DamageNumber.animate)
end

function DamageNumber.animate(self)--
    --[[
    local tween = timer.tween(0.15, {
        [self.opt.color.normal.fg] = {[4] = 1},
        [self] = {scale = self.end_scale}
    })
    ]]--
    local num_tween = tween(
        0.15,
        self.opt.color.normal.fg, {[4] = 1},
        self, {scale = self.end_scale}
    )
    self:wait(num_tween)
    self:wait(1)
    local spatial = self.spatial
    --[[
    tween = timer.tween(0.25, {
        [self.opt.color.normal.fg] = {[4] = 0},
        [self.spatial] = spatial:move(0, -50)
    })
    ]]--
    num_tween = tween(
        0.25,
        self.opt.color.normal.fg, {[4] = 0},
        self.spatial, spatial:move(0, -50)
    )
    self:wait(num_tween)
    self:remove()
end

function DamageNumber:remove()
    --self.animation:terminate()
    self.master:remove(self)
end

function label_draw(text, opt, x, y, w, h, sx, sy)
	y = y + suit.theme.getVerticalOffsetForAlign(opt.valign, opt.font, h)

	gfx.setColor(unpack(opt.color.normal.fg))
	gfx.setFont(opt.font)
	gfx.printf(
        text, x + 2 + w / 2, y, w - 4, opt.align or "center", 0, sx, sy,
        w / 2, h / 2
    )
end

function DamageNumber:draw(x, y)
    local _x, _y, w, h = self.spatial:unpack()
    label_draw(
        self.text, self.opt, _x + x, _y + y, w, h, self.scale, self.scale
    )
end

local DamageNumberServer = {}
DamageNumberServer.__index = DamageNumberServer

function DamageNumberServer:create()
    self.numbers = {}
    self.x = {}
    self.y = {}
    self.time = {}
    self.draworder = {}
end

function DamageNumberServer:heal(pos, info)
    self:number(info.heal, pos.x, pos.y, "heal")
end

function DamageNumberServer:damage(pos, info)
    local dmg = info.damage

    if info.miss then
        self:number("Miss", pos.x, pos.y)
    elseif info.shielded then
        self:number("Void", pos.x, pos.y)
    elseif info.crit or info.charged then
        dmg = tostring(dmg) .. "\nCritical"
        self:number(dmg, pos.x, pos.y, "crit")
    else
        self:number(dmg, pos.x, pos.y)
    end
end

function DamageNumberServer:heal(pos, info)
    local heal = info.heal

    self:number(heal, pos.x, pos.y, "heal")
end

function DamageNumberServer:number(number, x, y, type)
    number = Node.create(DamageNumber, number, self, type)
    --number = DamageNumber.create(number, self, type)
    self.numbers[number] = true
    self.time[number] = love.timer.getTime()
    self.x[number] = x + love.math.random(-10, 10)
    self.y[number] = y + love.math.random(-10, 10)
    self.draworder = self:get_draworder()
    return self
end

function DamageNumberServer:remove(number)
    self.numbers[number] = nil
    self.time[number] = nil
    self.x[number] = nil
    self.y[number] = nil
    self.draworder = self:get_draworder()
    return self
end

function DamageNumberServer:__update(dt)
    for number, _ in pairs(self.numbers) do
        number:update(dt)
    end
end

function DamageNumberServer:get_draworder()
    local order = List.create()
    for number, _ in pairs(self.numbers) do
        order[#order + 1] = number
    end
    local function sort(a, b)
        return self.time[a] < self.time[b]
    end
    table.sort(order, sort)
    return order
end

function DamageNumberServer:__draw(x, y, r)
    x = x or 0
    y = y or 0
    for _, number in ipairs(self.draworder) do
        number:draw(self.x[number] + x, self.y[number] + y, r)
    end
end

return DamageNumberServer
