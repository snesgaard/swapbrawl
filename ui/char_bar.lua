local charbar = {}
local uibar = require "ui.bar"

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
        :expand(25, 15)

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

function charbar:__draw(x, y)
    --self.drawstack:draw(x, y + 100)
    gfx.setColor(0, 0, 0.2, 0.3)
    gfx.rectangle(
        "fill", self.layout.bound.x, self.layout.bound.y,
        self.layout.bound.w, self.layout.bound.h, 10
    )

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
end

function charbar:position(index)
    return vec2(50 + 225 * (3 - index), 50)
end

function charbar:set_id(id)
    self.id = id
    return self
end

function charbar:set_position(index)
    self.__transform.pos = self:position(index)
    return self
end

charbar.remap = {}

charbar.remap["combat.mechanics:damage"] = function(self, state, info)
    if self.id ~= info.target then return end

    self:set_hp(
        state:read(join("actor/health", self.id)),
        state:read(join("actor/max_health", self.id))
    )
end

return charbar
