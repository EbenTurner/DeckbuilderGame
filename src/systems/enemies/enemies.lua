local EnemyDB = {}

---@class Enemy
---@field id string
---@field instanceId integer?
---@field name string
---@field max_hp integer
---@field hp integer?       the current hp
---@field damage integer
---@field elite boolean?    defaults to false
---@field hunter boolean?   defaults to false
---@field location string?  set on spawn
---@field alive boolean?    set on spawn
---@field attack function?
---@field moveTowardsPlayer function?

-- EnemyFunctons is a way to link defined functions to every enemy object
local EnemyFunctions = {}

function EnemyFunctions:attack(ctx)
    if ctx.player.block >= self.damage then
        ctx.player.block = ctx.player.block - self.damage
    else
        local hp_loss = self.damage - ctx.player.block
        ctx.player.block = 0
        ctx.player.hp = ctx.player.hp - hp_loss
    end
end

function EnemyFunctions:moveTowardsPlayer(ctx)
    local shortestPath = ctx.map:shortestPath(self.location, ctx.map.current)

    -- May want to have a speed stat for multiple locations per turn
    self.location = shortestPath[2]
end

---@param data Enemy
---@return Enemy
function EnemyDB.create(data)
    local enemy = {
        id          = data.id,
        name        = data.name,
        damage      = data.damage,
        max_hp       = data.max_hp,
        elite       = data.elite       or false,
        hunter      = data.hunter      or false,
    }

    setmetatable(enemy, { __index = EnemyFunctions })

    return enemy
end

EnemyDB.library = {
    slime = EnemyDB.create({
        id = "slime",
        name = "Slime",
        damage = 5,
        max_hp = 10,
    }),

    stalker = EnemyDB.create({
        id = "stalker",
        name = "Stalker",
        damage = 8,
        max_hp = 15,
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