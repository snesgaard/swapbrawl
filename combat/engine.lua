local attack_data = {}
attack_data.__index = attack_data

function attack_data.create(target, damage)
    local this = {target = target, damage = damage}
    return setmetatable(this, attack_data)
end

function attack_data:get_target()
    return type(data.target) == "string" and list(data.target) or data.target
end

function attack_data:untangle()
    return self:get_target()
        :map(
            function(id)
                return self:copy(id)
            end
        )
end

function attack_data:copy(target)
    return attack_data.create(target or self.target, self.damage)
end

local function get_target(data)
    return
end

local function calculate_damage(engine, data)
    local hp = engine.state:get_health(id)
    local damage = math.min(hp, data.damage)
    return {
        target = data.target,
        damage = damage
    }
end

local function calculate_heal(engine, data)
    local max_hp = engine.state:get_max_health(id)
    local hp = engine.state:get_max_health(id)
    local heal = math.min(max_hp - hp, data.damge)
    return {
        target = data.target,
        heal = heal
    }
end

local engine = {}

function engine:create()
    self.reactions = {
        on_attack = echo(),
        damage = {
            pre = echo(),
            calc = echo(),
            post = event()
        },
        heal = {
            pre = echo(),
            calc = echo(),
            post = event()
        }
    }
    self.state = require "combat.state"()
    self.position = require "combat.position"()
end

function engine:attack(data)
    return self.reactions.on_attack(data)
end

function engine:damage(data)
    data = self.reactions.damage.pre(data)

    for _, subdata in pairs(data.untangle()) do
        subdata = self.damage.calc(subdata)
        local info = calculate_damage(self, subdata)
        self.state:change_health(-info.damage)
        self.damage.post(info)
    end
end

function engine:heal(data)
    data = self.reactions.heal.pre(data)

    for _, subdata in pairs(data.untangle()) do
        subdata = self.heal.calc(subdata)
        local info = calculate_heal(self, subdata)
        self.state:change_health(info.heal)
        self.heal.post(info)
    end
end

function engine:heal()

function engine.damage()

return engine
