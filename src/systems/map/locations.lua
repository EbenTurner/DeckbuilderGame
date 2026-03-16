local LocationDB = {}

---@class Location
---@field id string
---@field instanceId integer?
---@field name string
---@field description string
---@field enter function?
---@field reveal function?
---@field revealed boolean?
---@field connections Location[]? The locations an instance is connected to
---@field x integer?    Coords set when location initialized
---@field y integer?
---@field spawns string[]?

local function noop() end

---@param data Location
---@return Location
function LocationDB.create(data)
    local location = {
        id          = data.id,
        name        = data.name,
        description = data.description,
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
        description = "A generic room."
    }),

    tavern = LocationDB.create({
        id = "tavern",
        name = "Tavern",
        description = "Nestled in the dungeon is Old Joe's tavern. Stop and have a drink.",
        reveal = function(_, ctx)
            -- heal the player for 30% of max_hp
            local healAmount = math.floor(ctx.player.max_hp * 0.3)
            ctx.player.hp = math.min(ctx.player.max_hp, ctx.player.hp + healAmount)
        end
    }),

    boss = LocationDB.create({
        id = "boss",
        name = "Boss",
        description = "OH NO.",
        enter = function(self, ctx)
            ctx.enemies:spawn("slime", self)
        end
    }),
}

---@param id string
---@return Location
function LocationDB:get(id)
    local location = self.library[id]
    assert(location, "Could not find location in library with id: " .. tostring(id))

    return location
end

return LocationDB