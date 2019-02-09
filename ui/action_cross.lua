local node = {}

function node:create()
    self.layout = node:build_layout(0, 0)
    self.particles = node.build_particles()

    self.blur = moon(moon.effects.gaussianblur)
end

function node:set_keys(keys)
    self._keys = keys
    return self
end

function node:set_texts(texts)
    self._texts = texts
    return self
end

function node:set_icons(icons)
    self._frames = {}

    local atlas = get_atlas("art/icons")
    for key, path in pairs(icons) do
        local p = "action/" .. path
        self._frames[key] = atlas:get_animation(p)
    end

    return self
end

function node:icons()
    return self._icons or {}
end

function node:texts()
    return self._texts or {}
end

function node:build_particles()
    local function circle(...)
        gfx.circle("fill", 3, 3, 3)
    end
    local im = gfx.prerender(7, 7, circle)
    return particles{
        image = im,
        buffer = 80,
        rate = 80,
        lifetime = 0.75,
        area = {
            "borderrectangle", 16, 16, 0, true
        },
        speed = 15,
        color = {
            1.0, 1.0, 1.0, 0.05,
            1.0, 1.0, 0.1, 0.3,
            1, 1, 1, 0
        },
    }
end

function node:build_layout(x, y)
    local root = spatial(x, y, 0, 0)

    local icon = spatial(0, 0, 16, 16):scale(2, 2)
    local key = spatial(0, 0, 10, 10):scale(2, 2)
    local text = spatial(0, 0, 27, 8):scale(2, 2)

    local layout = dict{
        text = dict(),
        icon = dict(),
        key = dict(),
        bound = dict(),
    }

    layout.key.up = key
        :xalign(root, "center", "center")
        :yalign(root, "bottom", "top")
        :move(0, -6)

    layout.text.up = text
        :xalign(layout.key.up, "center", "center")
        :yalign(layout.key.up, "bottom", "top")
        :move(0, -6)

    layout.icon.up = icon
        :xalign(layout.text.up, "center", "center")
        :yalign(layout.text.up, "bottom", "top")
        :move(0, -6)

    layout.key.down = key
        :xalign(root, "center", "center")
        :yalign(root, "top", "top")
        :move(0, 6)

    layout.icon.down = icon
        :xalign(layout.key.down, "center", "center")
        :yalign(layout.key.down, "top", "bottom")
        :move(0, 6)

    layout.text.down = text
        :xalign(layout.icon.down, "center", "center")
        :yalign(layout.icon.down, "top", "bottom")
        :move(0, 6)

    layout.key.left = key
        :xalign(layout.key.down, "right", "left")
        :yalign(layout.key.down, "center", "center")
        :move(-12, 0)

    layout.icon.left = icon
        :xalign(layout.key.left, "right", "left")
        :yalign(layout.key.left, "center", "center")
        :move(-12, 0)

    layout.text.left = text
        :xalign(layout.icon.left, "center", "center")
        :yalign(layout.icon.left, "top", "bottom")
        :move(0, 3)

    layout.key.right = key
        :xalign(layout.key.down, "left", "right")
        :yalign(layout.key.down, "center", "center")
        :move(12, 0)

    layout.icon.right = icon
        :xalign(layout.key.right, "left", "right")
        :yalign(layout.key.right, "center", "center")
        :move(6, 0)

    layout.text.right = text
        :xalign(layout.icon.right, "center", "center")
        :yalign(layout.icon.right, "top", "bottom")
        :move(0, 3)

    layout.bound.horz = layout.key.left
        :join(
            layout.icon.left, layout.text.left,
            layout.icon.right, layout.text.right, layout.key.right
        )
        :compile()
        :expand(15, 15)

    layout.bound.vert = layout.key.up
        :join(
            layout.icon.up, layout.text.up,
            layout.icon.down, layout.text.down, layout.key.down
        )
        :compile()
        :expand(15, 15)

    layout.bound.total = layout.bound.horz:join(layout.bound.vert):compile()


    return layout
end

function node:test()
    local keys = {
        up = "W",
        down = "S",
        left = "A",
        right = "D"
    }

    local name = {
        up = "Magick",
        left = "Attack",
        right = "Defend",
        down = "Item"
    }

    local icons = {
        left = "attack_bw",
        up = "magick_bw",
        down = "item_bw",
        right = "defend_bw"
    }

    self:set_keys(keys)
    self:set_texts(name)
    self:set_icons(icons)
end

local function smooth_spatial_draw(x, y, w, h)
    gfx.rectangle("fill", x, y, w, h, 10)
end


local text_opt = {
    align="center",
    valign="center",
    font = font(12),
    color = {
        normal = {
            fg = {1, 1, 1}
        }
    }
}

local key_opt = {
    align="center",
    valign="center",
    font = font(15),
    color = {
        normal = {
            fg = {1, 1, 1}
        }
    }
}

function node:__update(dt)
    self.particles:update(dt)
end

function node:__draw(x, y)
    gfx.setColor(1, 1, 1)
    for key, s in pairs(self.layout.key) do
        gfx.rectangle("line", s:unpack())
    end
    if render_boxes then

        for key, s in pairs(self.layout.text) do
            gfx.rectangle("line", s:unpack())
        end
    end

    gfx.stencil(function()
        smooth_spatial_draw(self.layout.bound.horz:unpack())
        smooth_spatial_draw(self.layout.bound.vert:unpack())
    end, "replace", 1)

    gfx.setStencilTest("equal", 1)
    gfx.setColor(0, 0, 0.2, 0.3)
    gfx.rectangle("fill", self.layout.bound.total:unpack())
    gfx.setStencilTest()

    --[[
    gfx.setColor(1, 1, 1)
    gfx.setBlendMode("add", "alphamultiply")
    self.blur(function()
        gfx.draw(self.particles, x + self.layout.icon.up.x + 16, y + self.layout.icon.up.y + 16)
    end)
    gfx.setBlendMode("alpha")
    ]]--

    for key, text in pairs(self._keys or {}) do
        local s = self.layout.key[key]
        suit.theme.Label(text, key_opt, s:unpack())
    end

    for key, text in pairs(self._texts or {}) do
        local s = self.layout.text[key]
        suit.theme.Label(text, text_opt, s:unpack())
    end

    for key, f in pairs(self._frames or {}) do
        local s = self.layout.icon[key]
        f:draw(s.x, s.y, 0, 2, 2)
    end
end

return node
