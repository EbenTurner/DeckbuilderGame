local EnemyDB = require("src.systems.enemies.enemies")

---@class EnemyManager
---@field unengaged_enemies Enemy[]
---@field engaged_enemies Enemy[]
---@field _instance_counter integer
local EnemyManager = {}

EnemyManager.unengaged_enemies = {}
EnemyManager.engaged_enemies = {}
EnemyManager._instance_counter = 0

function EnemyManager:initialize()
    -- Any setup that needs to be done
end

---@param id string
---@param location Location
function EnemyManager:spawn(id, location)
    -- create an instance of an enemy in a location
    local template = EnemyDB:get(id)
    assert(template, "No enemy associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local instance = {
        instanceId = self._instance_counter,
        template_id = id,
        hp = template.max_hp,
        location = location,
        alive = true,
    }
    setmetatable(instance, { __index = template })

    table.insert(self.unengaged_enemies, instance)
end

---@param instanceId integer
function EnemyManager:engage(instanceId)
    for i = #self.unengaged_enemies, 1, -1 do
        local enemy = self.unengaged_enemies[i]

        if enemy.instanceId == instanceId then
            table.remove(self.unengaged_enemies, i)
            table.insert(self.engaged_enemies, enemy)
        end
    end
end

--TODO: this function is currently not being used
---@param instanceId integer
function EnemyManager:kill(instanceId)
    for i = #self.engaged_enemies, 1, -1 do
        local enemy = self.engaged_enemies[i]

        if enemy.instanceId == instanceId then
            table.remove(self.engaged_enemies, i)
        end
    end
end


---@param location Location
function EnemyManager:getEnemiesInLocation(location)
    local found = {}
    for _, enemy in ipairs(self.unengaged_enemies) do
        if enemy.location == location then
            table.insert(found, enemy)
        end
    end
    return found
end

-- Defines the behaviour of what enemies do during their turn
function EnemyManager:enemyPhase(ctx)
    -- Enemies move if they are unengaged
    for _, enemy in ipairs(self.unengaged_enemies) do
        enemy:moveTowardsPlayer(ctx)
    end

    -- For now just attack player if they are engaged
    for _, enemy in ipairs(self.engaged_enemies) do
        enemy:attack(ctx)
    end
end

return EnemyManager