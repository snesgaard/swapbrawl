require "combat.update_state"
local actor = require "actor"

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

local combat = {}

combat.position = require "combat.position"
combat.animation = require "combat.animation"

function combat.setup(party, foes)
    local root = combat.setup_scene()

    local state = state.create()
    local party_id = list()
    for position, type in pairs(party) do
        state, party_id[#party_id + 1] = combat.init_actor_state(
            state, position, type
        )
    end

    local foe_id = list()
    for position, type in pairs(foes) do
        state, foe_id[#foe_id + 1] = combat.init_actor_state(
            state, -position, type
        )
    end

    for _, id in pairs(party_id + foe_id) do
        state = combat.init_actor_visual(root, state, id)
    end

    for _, id in pairs(party_id + foe_id) do
        root.actors[id].player:play{"idle", loop=true}
    end

    root.actors.__transform.scale = vec2(2, 2)

    root:commit(state)

    return root
end

function combat.setup_scene()
    local root = Node.create(require "combat.state_store")

    root.state = state.create()

    root.actors = root:child()

    root.ui = root:child()

    return root
end

function combat.init_actor_state(state, position, type)
    local data = actor(type)
    local id = id_gen.register(type)

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
        :map("position", combat.position.set, id, position)

    for _, key in pairs({"agility", "power"}) do
        local p = join("actor", key, id)
        state = state:map(p, function(v) return v or 0 end)
    end

    return state, id
end

function combat.init_actor_visual(root, state, id)
    local type = state:read(join("actor/type", id))
    if not type then
        log.warn("Type for %i is not defined", id)
        return
    end

    local data = actor(type)

    -- Setup sprite
    local actor_root = root.actors:child()

    actor_root.sprite = actor_root:child(Sprite)
    if state:position(id) < 0 then
        actor_root.sprite.__transform.scale.x = -1
    end
    actor_root.sprite.__transform.pos = combat.position.get_world(
        state:position(), id
    )
    actor_root.player = actor_root:child(animation_player)

    local atlas = data.atlas and get_atlas(data.atlas) or nil

    if atlas and data.animations then
        actor_root.player = atlas:animation_player(data.animations)

        for key, f in pairs(data.post_animation or {}) do
            local anime = actor_root.player:animation(key)
            local frames = atlas:get_animation(data.animations[key])
            if anime and frames then f(combat.animation, frames, anime) end
        end

        actor_root:adopt(actor_root.player)
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

return combat
