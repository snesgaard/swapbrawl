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
    local _, _, w, h = self.cards:head().shape:unpack()
    self.__select_sfx = Node.create(require "sfx.card_select", w, h)

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
        --obj.adopt(self.__select_sfx)
    end

    if index then
        index = math.cycle(index, 1, #self.cards)
        local obj = self.cards[index]
        obj:highlight(true)
        obj:adopt(self.__select_sfx)
    end

    self.selected = index
    self:__make_order()
end

function hand:trigger()
    if self.__select_sfx then
        self.__select_sfx:trigger()
    end
    return self
end

function hand:fallback()
    if self.__select_sfx then
        self.__select_sfx:fallback()
    end
    return self
end

function hand:insert_card()
    local c = self:child(card)
    function c:__draworder(x, y, ...)
        self:__childdraw(0, 0)
        self:__draw(0, 0, ...)
    end
    self.cards = self.cards:insert(c)
end

function hand:remove_card(index)

end

function hand:build_structure()
    for i, card in ipairs(self.cards) do
        card.__transform.pos.x = 120 * (i - 1)
    end
end

function hand:highlight(doit)
    local obj = self.cards[self.selected]
    if not doit then
        obj:highlight(false)
        self.__select_sfx:orphan()
    elseif obj then
        obj:highlight(true)
        obj:adopt(self.__select_sfx)
    end
    self:__make_order()
end

function hand:left()
    return self:select(self.selected - 1)
end

function hand:right()
    return self:select(self.selected + 1)
end

function hand:current()
    return self.selected
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
