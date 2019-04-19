local card = require "ui.card"

local function sort_cards(a, b)
    local ax = a.highlighted and 10000 or a.__transform.pos.x
    local bx = b.highlighted and 10000 or b.__transform.pos.x
    return ax < bx
end

local hand = {}

function hand:create()
    self.cards = list()
    for i = 1, 10 do
        self:insert_card()
    end
    self.activated = true
    self:select(1)
    self:build_structure()
    self:set_order(sort_cards)
    self.on_select = event()
    self:__make_order()
end

function hand:select(index)
    if self.selected then
        local obj = self.cards[self.selected]
        obj:highlight(false)
    end

    if index then
        index = math.cycle(index, 1, #self.cards)
        local obj = self.cards[index]
        obj:highlight(true)
    end

    self.selected = index
    self:__make_order()
end

function hand:insert_card()
    self.cards = self.cards:insert(self:child(card))
end

function hand:remove_card(index)

end

function hand:build_structure()
    for i, card in ipairs(self.cards) do
        card.__transform.pos.x = 120 * (i - 1)
    end
end

function hand:keypressed(key)
    if not self.activated then return end
    if key == "right" and self.activated then
        self:select(self.selected + 1)
    elseif key == "left" and self.activated then
        self:select(self.selected - 1)
    elseif key == "space" then
        self.on_select(self.selected)
    end
end

function hand:activate(do_it)
    self.activated = do_it
    local obj = self.cards[self.selected]
    if self.activated then
        obj:highlight(true)
    else
        obj:highlight(false)
    end

    self:__make_order()
end



return hand
