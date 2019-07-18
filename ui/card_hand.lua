local card = require "ui.card"
local state = require "combat.state"

local function sort_cards(a, b)
    local ax = a.highlighted and 10000 or a.__transform.pos.x
    local bx = b.highlighted and 10000 or b.__transform.pos.x
    return ax < bx
end

local hand = {}

function hand:test()
    local state = state()
    self:select(1)
    self:insert(state, "1", "2", "3")
    self:remove("2")
end

function hand:create()
    self.cards = list()
    self:set_order(sort_cards)
    self.cardids = dict()
    self.anime_queue = self:child(require "combat.action_queue")
end

function hand:insert(state, ...)
    local ids = list(...)
    local nodes = ids:map(
        function(id)
            local c = self:child(card, state, id)
            function c:__draworder(x, y, ...)
                self:__childdraw(0, 0)
                self:__draw(0, 0, ...)
            end
            c.__transform.pos.x = 2000
            return c
        end
    )

    for i, n in ipairs(nodes) do
        local id = ids[i]
        n.__transform.pos.x = n.__transform.pos.x + i
        self.cardids[n] = id
        self.cardids[id] = n
    end

    if #nodes <= 0 then return end

    local cards = self.cards + nodes
    self.cards = cards

    if not self.__select_sfx then
        local _, _, w, h = self.cards:head().shape:unpack()
        self.__select_sfx = Node.create(require "sfx.card_select", w, h)
    end

    local function action(handle)
        local structure = self.build_structure(cards)
        local tween_table = {}
        self:__make_order()
        for i, node in ipairs(cards) do
            tween_table[#tween_table + 1] = node.__transform.pos
            tween_table[#tween_table + 1] = structure[i]
        end
        local tween = tween(0.25, unpack(tween_table))
        self:wait(tween)
    end

    self:select(self.selected)

    self.anime_queue:submit(action)
end

function hand:clear()
    local indices = {}
    for i, _ in ipairs(self.cards) do
        indices[#indices + 1] = i
    end

    return self:remove(unpack(indices))
end

function hand:remove(...)
    local function arg2indices(arg)
        if type(arg) == "string" then
            local obj = self.cardids[arg]
            return self.cards:argfind(obj)
        elseif type(arg) == "table" then
            return self.cards:argfind(arg)
        else
            return arg
        end
    end

    local function get_tween_node(indices, nodes)
        local cards = self.cards
        for _, i in ipairs(indices:sort():reverse()) do
            cards = cards:erase(i)
        end

        local structure = self.build_structure(cards)

        local tween_table = {}
        for i, card in ipairs(cards) do
            --tween_table[card.__transform.pos] = structure[i]
            tween_table[#tween_table + 1] = card.__transform.pos
            tween_table[#tween_table + 1] = structure[i]
        end

        for i, node in ipairs(nodes) do
            local index = indices[i]
            local end_pos = hand.card_pos(index) - vec2(0, 100)
            --tween_table[node.__transform.pos] = end_pos
            tween_table[#tween_table + 1] = node.__transform.pos
            tween_table[#tween_table + 1] = end_pos
        end

        return tween_table, cards
    end

    local indices = list(...)
        :map(arg2indices)
        :filter(function(index) return self.cards[index] end)

    local nodes = indices
        :map(function(index) return self.cards[index] end)


    if not #indices then return end

    local tween_table, cards = get_tween_node(indices, nodes)

    local s = self.selected

    local index = self.cards:argfind(s)

    self:select()

    self.cards = cards
    for _, n in ipairs(nodes) do
        local id = self.cardids[n]
        self.cardids[n] = nil
        self.cardids[id] = nil
    end

    self:select(index)

    -- Remove from lookup table

    local function action(handle)
        local tween = tween(0.25, unpack(tween_table))
        handle:wait(tween)
        for _, n in ipairs(nodes) do
            n:destroy()
        end
    end

    self.anime_queue:submit(action)
end

function hand:select(index)
    local function get_obj()
        if not index then return end
        if type(index) == "number" then
            return self.cards[index]
        elseif type(index) == "string" then
            return self.cardids[index]
        else
            return index
        end
    end

    local next_obj = get_obj()

    if self.selected then
        self.selected:highlight(false)
    end

    if self.__select_sfx then
        if next_obj then
            next_obj:highlight(true)
            next_obj:adopt(self.__select_sfx)
        else
            self.__select_sfx:orphan()
        end
    end

    self.selected = next_obj
    self:__make_order()
end

function hand:is_present(index)
    if type(index) == "number" then
        return self.cards[index]
    elseif type(index) == "string" then
        return self.cardids[index]
    end
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

function hand.card_pos(index)
    return vec2(120 * (index - 1), 0)
end

function hand.build_structure(cards)
    local pos = {}
    for i, card in ipairs(cards) do
        pos[i] = hand.card_pos(i)
    end
    return pos
end

function hand:highlight(doit)
    local obj = self.cards[self.selected or 1]

    if not doit then
        if obj then
            obj:highlight(false)
        end
        if self.__select_sfx then
            self.__select_sfx:orphan()
        end
    else
        obj:highlight(true)
        obj:adopt(self.__select_sfx)
    end
    self.highlighted = doit
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
