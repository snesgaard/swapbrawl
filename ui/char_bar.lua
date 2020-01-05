local charbar = {}
local uibar = require "ui.bar"

local ping = {}

function ping:create(pos)
    self.radius = 0
    self.alpha = 2
    self.thickness = 3
    self.__transform.pos = pos
    self:fork(ping.life)
end

function ping:__draw()
    gfx.setLineWidth(self.thickness)
    gfx.setColor(0.7, 0.7, 0.1, self.alpha)
    gfx.circle("line", 0, 0, self.radius)
end

function ping:life()
    local t = tween(0.3, self, {radius=40, alpha=0})
        :ease(ease.outQuad)
    event:wait(t, "finish")
    self:destroy()
    print("free")
end

function charbar:create()
    self.drawstack = DrawStack.create()
    self.stamina = {
        -- Bar components
        bar = {
            min=0,
            max=100,
            value=50,
            color={1.0, 0.7, 0.5}
        },
        -- Label components
        str = {
            str="50 / 100",
            font=font(12),
            align="right",
            valign="center",
            color = {
                normal = {
                    fg = {1.0, 1.0, 1.0}
                }
            }
        }
    }
    self.hp = {
        -- Bar components
        bar={
            min=0,
            max=50,
            value=25,
            color = {1.0, 0.5, 0.5},
        },
        str={
            -- Label components
            str="25 / 50",
            font=font(12),
            align="right",
            valign="center",
            color = {
                normal = {
                    fg = {1.0, 1.0, 1.0}
                }
            }
        }
    }
    self.layout = self:build_layout()
    self.icons = {
        weapon=get_atlas("art/ui"):get_frame("buff_icons/weapon"),
        body=get_atlas("art/ui"):get_frame("buff_icons/body"),
        soul=get_atlas("art/ui"):get_frame("buff_icons/soul")
    }
    self.user_icons = {

    }
end

function charbar:set_stamina(value, max)
    local bar = self.stamina.bar
    bar.max = max or bar.max
    bar.value = value
    self.stamina.str.str = string.format("%i / %i", bar.value, bar.max)
    return self
end

function charbar:set_hp(value, max)
    local bar = self.hp.bar
    bar.max =  max or bar.max
    bar.value = value
    self.hp.str.str = string.format("%i / %i", bar.value, bar.max)
    return self
end

function charbar:icon_from_atlas(atlas, icon)
    if not atlas then return self end
    self.icon = get_atlas(atlas):get_frame(icon)
    return self:rebuild()
end

function charbar:rebuild()
    local atlas = get_atlas("art/ui")
    local bar = atlas:get_animation("charbar")
    local overlay = atlas:get_animation("char_icon_holder")

    local label_opt = {
        align="left",
        valign="center",
        font = font(12),
    }

    return self
end

function charbar:build_layout()
    local layout = dict()

    layout.icon = spatial(0, 0, 20, 20):scale(2, 2)

    local label = spatial(0, 0, 32, 6):scale(2, 2)
    local bar = spatial(0, 0, 64, 3):scale(2, 2)

    layout.name = layout.icon
        :align(layout.icon, "left", "left", "top", "bottom")
        :move(0, 6)

    layout.hp_bar = bar
        :align(layout.icon, "left", "right", "bottom", "top")
        :move(8, 8)

    layout.stamina_bar = bar
        :align(layout.icon, "left", "right", "bottom", "bottom")
        :move(8, -8)

    layout.hp_label = label
        :align(layout.hp_bar, "left", "left", "bottom", "top")
        :move(0, -6)
    layout.hp_value = layout.hp_label:right()

    layout.stamina_label = label
        :align(layout.stamina_bar, "left", "left", "top", "bottom")
        :move(0, 6)
    layout.stamina_value = layout.stamina_label:right()

    layout.bound = layout.icon
        :join(layout.hp_value, layout.stamina_value)
        :compile()
        :expand(26, 16)

    layout.weapon = layout.bound:up(10, 5, 20, 20)
    layout.body = layout.bound:up(0, 5, 20, 20, "center")
    layout.soul = layout.bound:up(-10, 5, 20, 20, "right")

    return layout
end

local label_opt = {
    align="left",
    valign="center",
    font = font(12),
    color = {
        normal = {
            fg = {1.0, 1.0, 1.0}
        }
    }
}

local COLORS = {
    vanguard = {0, 0, 0.2, 0.3},
    cooldown = {0.2, 0.2, 0.2, 0.3},
    reserve = {0.6, 0, 0, 0.3}
}

function charbar:color_from_place(place)
    self.color = place > 3 and COLORS.reserve or COLORS.vanguard
    return self
end

function charbar:progress(prog)
    self.prog = prog
    return self
end

function charbar:__draw(x, y)
    --self.drawstack:draw(x, y + 100)
    local prog = self.prog or 1.0
    if prog < 1.0 then
        gfx.stencil(function()
            local x, y, w, h = self.layout.bound:unpack()
            gfx.rectangle("fill", x, y, w * prog, h, 10)
        end, "replace", 1)
        gfx.setStencilTest("equal", 1)
        gfx.setColor(unpack(self.color))
        gfx.rectangle(
            "fill", self.layout.bound.x, self.layout.bound.y,
            self.layout.bound.w, self.layout.bound.h, 10
        )
        gfx.setStencilTest("equal", 0)
        gfx.setColor(unpack(COLORS.cooldown))
        gfx.rectangle(
            "fill", self.layout.bound.x, self.layout.bound.y,
            self.layout.bound.w, self.layout.bound.h, 10
        )
        gfx.setStencilTest()
    else
        gfx.setColor(unpack(self.color or COLORS.reserve))
        gfx.rectangle(
            "fill", self.layout.bound.x, self.layout.bound.y,
            self.layout.bound.w, self.layout.bound.h, 10
        )
    end

    gfx.setColor(1, 1, 1)
    if self.icon then
        self.icon:draw(self.layout.icon.x, self.layout.icon.y, 0, 2, 2)
    end
    gfx.setColor(1, 1, 1, 0.8)
    gfx.rectangle("line", self.layout.icon:unpack())

    suit.theme.Label(
        self.hp.str.str, self.hp.str, self.layout.hp_value:unpack()
    )
    suit.theme.Label(
        "Health", label_opt, self.layout.hp_label:unpack()
    )
    uibar(self.hp.bar, self.layout.hp_bar:unpack())

    suit.theme.Label(
        self.stamina.str.str, self.hp.str, self.layout.stamina_value:unpack()
    )
    suit.theme.Label(
        "Stamina", label_opt, self.layout.stamina_label:unpack()
    )
    uibar(self.stamina.bar, self.layout.stamina_bar:unpack())

    if self._buff_highlight then
        local zone = self.layout[self._buff_highlight]
        if zone then
            gfx.rectangle("line", zone:expand(6, 6):unpack())
        end
    end

    for _, key in ipairs{"weapon", "body", "soul"} do
        local zone = self.layout[key]
        local user_icon = self.user_icons[key]
        if not user_icon then
            --gfx.setColor(COLORS.vanguard)
            --gfx.rectangle("fill", zone:unpack(2))
            --gfx.setColor(1, 1, 1, 0.3)
            --self.icons[key]:draw(zone.x, zone.y)
        else
            gfx.setColor(1, 1, 1)
            user_icon:draw(zone.x, zone.y)
        end
    end
end

function charbar:buff_highlight(buff_name)
    self._buff_highlight = buff_name
    return self
end

local default_icon = gfx.prerender(20, 20, function(w, h)

end)

function charbar:set_user_icon(type, path)
    if not path then
        self.user_icons[type] = {
            draw = function(self, x, y)
                gfx.rectangle("fill", x, y, 20, 20)
            end
        }
    else
        local atlas, image = unpack(string.split(path, ":"))
        self.user_icons[type] = get_atlas(atlas):get_frame(image)
    end
    return self
end


function charbar:remove_user_icon(type)
    self.user_icons[type] = nil
    return self
end


function charbar:position(index)
    local oy = -200
    if index <= 3 then
        return vec2(50 + 225 * (3 - index), gfx.getHeight() + oy)
    else
        return vec2(50 + 225 * (5 - index), gfx.getHeight() + oy + 100)
    end
end

function charbar:set_id(id)
    self.id = id
    return self
end

function charbar:set_position(index)
    self.__transform.pos = self:position(index)
    return self
end

function charbar:ping(buff_type)
    local p = self.layout[buff_type]
    if not p then
        local msg = string.format("invalid buff type <%s>", buff_type)
        error(msg)
    end
    local n = self:child(ping, p:center())
end

function charbar:test()
    self:set_user_icon("weapon", "art/ui:buff_icons/venom_oil")
    for i = 1, 10 do
        self:ping("weapon")
        event:sleep(0.1)
    end
end


charbar.remap = {}

charbar.remap["combat.mechanics:damage"] = function(self, state, info)
    if self.id ~= info.target then return end

    self:set_hp(
        state:read(join("actor/health", self.id)),
        state:read(join("actor/max_health", self.id))
    )
end

charbar.remap["combat.mechanics:true_damage"] = charbar.remap["combat.mechanics:damage"]

charbar.remap["combat.mechanics:heal"] = charbar.remap["combat.mechanics:damage"]

charbar.remap["ui:buff_highlight"] = function(self, buff_type, id)
    if id ~= self.id then
        self:buff_highlight()
    else
        self:buff_highlight(buff_type)
    end
end

charbar.remap["combat.buff:apply"] = function(self, state, info, args)
    if self.id ~= args.target then return end
    local buff = args.buff
    self:set_user_icon(buff.type, buff.icon)
end

charbar.remap["combat.buff:remove"] = function(self, state, info, args)
    if self.id ~= args.target then return end
    if not info.removed then return end
    self:remove_user_icon(info.removed.type)
end

charbar.remap["combat.buff:activate"] = function(self, state, info, args)
    if self.id ~= args.user then return end
    self:ping(args.type)
end

return charbar
