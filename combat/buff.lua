local function check_buff(buff)
    return buff == "weapon" or buff == "body" or buff == "soul"
end

local buff = {}

function buff.init_state(state)
    state.buff = dict{
        weapon = dict{},
        body = dict{},
        soul = dict{}
    }
end

function buff.apply(state, args)
    local buff = args.buff
    local target = args.target

    if not check_buff(buff.type) then
        error(string.format("Invalid buff type, <%s>", buff.type))
    end

    local path = join("buff", buff.type, target)
    local prev_buff = state:read(path)
    local next_state = state:write(path, buff)

    local info = {
        prev_buff = prev_buff,
        buff = buff
    }
    return next_state, info
end

-- Dummy function, simply used for signaling the activation of a buff
function buff.activate(state) return state end

function buff.weapon_buff(state, id)
    return state:read(join("buff/weapon", id))
end

function buff.read(state, type, id)
    return state:read(join("buff", type, id))
end

function buff.react(path, state, info, args)
    local buffs = state:read("buff")
    local transforms = list()
    for _, type in ipairs{"weapon", "body", "soul"} do
        for id, data in pairs(buffs[type]) do
            local f = data[path]
            if f then
                local l = list(f(id, state, info, args))
                if #l > 0 then
                    transforms[#transforms + 1] = {
                        path="combat.buff:activate", args = {
                            user=id, type=type
                        }
                    }
                    transforms = transforms + l
                end
            end
        end
    end
    return transforms
end

return buff
