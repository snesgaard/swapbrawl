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
            color={0.85, 0.45, 0.1}
        },
        -- Label components
        str = {
            str="50 / 100",
            font=font(12),
            align="right",
            valign="center",
        }
    }
    self.hp = {
        -- Bar components
        bar={
            min=0,
            max=50,
            value=25,
            color = {0.1, 0.65, 0.3},
        },
        str={
            -- Label components
            str="25 / 50",
            font=font(12),
            align="right",
            valign="center",
        }
    }
    self:rebuild()
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

function charbar:set_icon(icon)
    self.icon = icon
    return self:rebuild()
end

function charbar:rebuild()
    local atlas = get_atlas("art/ui")
    local bar = atlas:get_animation("charbar")
    local overlay = atlas:get_animation("char_icon_holder")

    self.drawstack:clear(0, 0)
        :stack(bar)
        :within(
            function(x, y, w, h)
                gfx.rectangle("fill", x, y, w, h)
            end,
            "icon"
        )

    if self.icon then
        self.drawstack:with(self.icon, "icon")
    end

    local label_opt = {
        align="left",
        valign="center",
        font = font(12)
    }

    self.drawstack
        :with(overlay, "icon")
        :within(
            function(x, y, w, h)
                uibar(self.hp.bar, x, y, w, h)
            end,
            "hp"
        )
        :within(
            function(x, y, w, h)
                uibar(self.stamina.bar, x, y, w, h)
            end,
            "stamina"
        )
        :within(
            function(x, y, w, h)
                suit.theme.Label("Stamina", label_opt, x, y, w, h)
            end,
            "stamina_label"
        )
        :within(
            function(x, y, w, h)
                suit.theme.Label(
                    self.stamina.str.str, self.stamina.str, x, y, w, h
                )
            end,
            "stamina_value"
        )
        :within(
            function(x, y, w, h)
                suit.theme.Label("Health", label_opt, x, y, w, h)
            end,
            "hp_label"
        )
        :within(
            function(x, y, w, h)
                suit.theme.Label(
                    self.hp.str.str, self.hp.str, x, y, w, h
                )
            end,
            "hp_value"
        )
    return self
end

function charbar:__draw(x, y)
    self.drawstack:draw(x, y)
end

return charbar
