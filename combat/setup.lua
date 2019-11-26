local setup = {}
local actor = require "actor"
local position = require "combat.position"
local animation = require "combat.animation"
local deck = require "combat.deck"
local combo = require "combat.combotree"

local function calc_attack_offset(atlas, offset_animation, name)
    atlas = get_atlas(atlas)
    local anime = atlas:get_animation(offset_animation)

    name = name or "attack"
    local frames = atlas:get_animation(offset_animation)
    local f = frames:find(function(f) return f.slices[name] end)
    local dst = f.slices[name] or spatial()
    local src = f.slices.origin or spatial()
    return math.ceil(dst:center().x - src:center().x)
end

function setup.init_actor_state(state, id, place, type)
    local data = actor(type)

    local bs = data.basestats()
    for key, value in pairs(bs) do
        state = state:write(join("actor", key, id), value)
    end

    local s, ms = state:stamina(id)
    local h, mh = state:health(id)
    h = h or 10
    s = s or 5

    state = state
    :write(join("actor/health", id), h)
    :write(join("actor/max_health", id), h)
    :write(join("actor/stamina", id), s)
    :write(join("actor/max_stamina", id), s)
    :write(join("actor/type", id), type)
    :map("position", position.set, id, place)
    :map(join("combo", id), combo.init, data.combo or {})

    for _, key in pairs({"agility", "power"}) do
        local p = join("actor", key, id)
        state = state:map(p, function(v) return v or 0 end)
    end

    return state, id
end

function setup.init_actor_ui(root, state, id)
    local type = state:read(join("actor/type", id))
    if not type then
        log.warn("Type for %i is not defined", id)
        return
    end

    local data = actor(type)
end

function setup.init_actor_visual(root, state, id)
    local type = state:read(join("actor/type", id))
    if not type then
        log.warn("Type for %i is not defined", id)
        return
    end

    local data = actor(type)

    -- Setup sprite
    local actor_root = root.actors:child()
    local _, place = position.pairget(state:position(), id)

    if data.atlas and data.animations then
        actor_root.sprite = actor_root:child(
            Sprite, data.animations, data.atlas
        )
        if state:position(id) < 0 then
            actor_root.sprite.__transform.scale.x = -1
        end

        actor_root.sprite.__transform.pos = position.get_world(
            state:position(), id
        )
        actor_root.sprite:queue({"idle"})
        if math.abs(place) > 3 then
            actor_root.sprite:hide()
        end
    end

    root.actors[id] = actor_root

    -- Setup ui, if in party
    if state:position(id) > 0 then
        local uitype = require "ui.char_bar"
        root.ui[id] = root.ui:child(uitype)
            :set_position(state:position(id))
            :set_hp(state:health(id))
            :set_stamina(state:stamina(id))
            :icon_from_atlas(unpack(data.icon or {}))
            :set_id(id)
        root.ui[id]:color_from_place(place)
        remap(root.ui[id])
    end

    if data.attack_offset then
        state = state:write(
            join("actor/offset", id),
            calc_attack_offset(data.atlas, data.attack_offset)
        )
    end

    if data.icon then
        root.ui.turn:icon(id, unpack(data.icon))
    end

    return state
end

return setup
