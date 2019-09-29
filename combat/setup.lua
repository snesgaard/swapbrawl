local setup = {}
local actor = require "actor"
local position = require "combat.position"
local animation = require "combat.animation"

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

    for _, key in pairs({"agility", "power"}) do
        local p = join("actor", key, id)
        state = state:map(p, function(v) return v or 0 end)
    end

    return state, id
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
    end

    root.actors[id] = actor_root

    -- Setup ui, if in party
    if state:position(id) then
        root.ui[id] = root.ui:child(require "ui.char_bar")
            :position(state:position(id))
            :set_icon(data.icon and data.icon())
            :set_hp(state:health(id))
            :set_stamina(state:stamina(id))
    end

    if data.attack_offset then
        state = state:write(
            join("actor/offset", id),
            calc_attack_offset(data.atlas, data.attack_offset)
        )
    end

    return state
end

return setup
