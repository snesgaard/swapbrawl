function state._init()
    local root = dict{
        actor = dict{
            health = dict{},
            max_health = dict{},
            stamina = dict{},
            max_stamina = dict{},
            agility = dict{},
            power = dict{},
            charge = dict{},
            shield = dict{},
            offset = dict{},
            type = dict{},
        },
        buff = dict{
            body = dict{},
            weapon = dict{}
        },
        position = dict{
            -- Convention : abs(1-3) is frontline. abs(3-) is reserve
            -- Negative numbers are foes, positve are players
        },
        react = dict{
            pre = dict{},
            post = dict{},
        },
        --ailment = dict{
        --    poison = dict{}, burn=dict{}, stun=dict{}
        --}
    }

    require("combat.turn_queue").init_state(root)
    require("combat.deck").init_state(root)
    require("combat.combotree").init_state(root)
    require("combat.ai").init_state(root)
    require("combat.ailments").init_state(root)

    for _, d in pairs(root.react) do
        d.order = list()
        d.func = dict()
    end

    return root
end

function state:type(id)
    local type_path = self:read(join("actor/type", id))
    print(id, type_path)
    return require("actor." .. type_path)
end

-- Utility functions
function state:agility(id)
    local a = self:read("actor/agility")
    return id and a[id] or a
end

function state:position(id)
    local p = self:read("position")
    return id and p[id] or p
end

function state:health(id)
    return self:read("actor/health/" .. id), self:read("actor/max_health/" .. id)
end

function state:stamina(id)
    return self:read("actor/stamina/" .. id), self:read("actor/max_stamina/" .. id)
end
