local EnemyDB = {}

---@class Enemy
---@field id string
---@field instanceId integer?
---@field name string
---@field maxHp integer
---@field hp integer?       the current hp
---@field damage integer
---@field elite boolean?    defaults to false
---@field hunter boolean?   defaults to false
---@field location string?  set on spawn
---@field alive boolean?    set on spawn

---@param data Enemy
---@return Enemy
function EnemyDB.create(data)
    local enemy = {
        id          = data.id,
        name        = data.name,
        damage      = data.damage,
        maxHp       = data.maxHp,
        elite       = data.elite       or false,
        hunter      = data.hunter      or false,
    }
    return enemy
end


EnemyDB.library = {
    slime = EnemyDB.create({
        id = "slime",
        name = "Slime",
        damage = 5,
        maxHp = 10,
    }),

    stalker = EnemyDB.create({
        id = "stalker",
        name = "Stalker",
        damage = 8,
        maxHp = 15,
        hunter = true,
        elite = true,
    }),
}

---@param id string
---@return Enemy
function EnemyDB:get(id)
    local enemy = self.library[id]
    assert(enemy, "Could not find enemy in library with id: " .. tostring(id))

    return enemy
end

return EnemyDB