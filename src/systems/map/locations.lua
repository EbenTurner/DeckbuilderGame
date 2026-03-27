local LocationDB = {}

---@class Location
---@field id string
---@field instanceId integer?
---@field name string
---@field description string
---@field type "empty"|"event"|"enemy"
---@field enter function?
---@field reveal function?
---@field revealed boolean?
---@field connections Location[]? The locations an instance is connected to
---@field x integer?            Coords set when location initialized
---@field y integer?
---@field screen_x number?      Actual x position on screen
---@field screen_y number?
---@field w number?
---@field h number?
---@field spawns string[]?

local function noop() end

---@param data Location
---@return Location
function LocationDB.create(data)
    local location = {
        id          = data.id,
        name        = data.name,
        description = data.description,
        type        = data.type,
        enter       = data.enter or noop,
        reveal      = data.reveal or noop,
        revealed    = data.revealed or false
    }
    return location
end

LocationDB.library = {
    room = LocationDB.create({
        id = "room",
        name = "Room",
        description = "A generic room.",
        type = "empty",
    }),

    tavern = LocationDB.create({
        id = "tavern",
        name = "Tavern",
        description = "Nestled in the dungeon is Old Joe's tavern. Stop and have a drink.",
        type = "empty",         --TODO: if we want to keep this, turn it into an event
        reveal = function(self, ctx)
            -- heal the player for 30% of max_hp
            local healAmount = math.floor(ctx.player.max_hp * 0.3)
            ctx.player.hp = math.min(ctx.player.max_hp, ctx.player.hp + healAmount)
        end
    }),

    boss = LocationDB.create({
        id = "boss",
        name = "Boss",
        description = "OH NO.",
        type = "enemy",
        enter = function(self, ctx)
            ctx.enemies:spawn("slime", self)
        end
    }),

    exit = LocationDB.create({
        id = "exit",
        name = "Exit",
        description = "A way down.",
        type = "empty",         --TODO: if we want to keep this, turn it into an event
        enter = function(self, ctx)
            -- TODO: move onto the next floor
        end
    }),

    zombie_corpse = LocationDB.create({
        id = "zombie_corpse",
        name = "Zombie Corpse",
        description = "A room with a stalker eating a corpse.",
        type = "event",          -- Room associated events match room id
    })
}

---@param id string
---@return Location
function LocationDB:get(id)
    local location = self.library[id]
    assert(location, "Could not find location in library with id: " .. tostring(id))

    return location
end

return LocationDB