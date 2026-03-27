local LocationDB = require("src.systems.map.locations")
local UI = require("src.ui.renderer")

---@class MapManager
---@field locations Location[]
---@field current Location
---@field _instance_counter integer
---@field selected_location Location
---@field speed integer
local MapManager = {}

MapManager.locations = {}
MapManager._instance_counter = 0

function MapManager:initialize(ctx)
    -- Add one room and start there
    local startRoom = self:addLocation("room", 0, 1)
    local tavern = self:addLocation("tavern", 1, 1)
    local zombieRoom = self:addLocation("zombie_corpse", 1, 0)
    local horRoom = self:addLocation("room", 2, 1)
    local boss = self:addLocation("boss", 1, 2)
    local exit = self:addLocation("exit", 2, 2)

    self:addConnection(startRoom, tavern)
    self:addConnection(tavern, boss)
    self:addConnection(tavern, zombieRoom)
    self:addConnection(horRoom, tavern)
    self:addConnection(boss, exit)

    self:enterLocation(startRoom, ctx)
end

---@return Location[]
function MapManager:getLocations()
    return self.locations
end

---@param id string
---@param x integer
---@param y integer
function MapManager:addLocation(id, x, y)
    local template = LocationDB:get(id)
    assert(template, "No card associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local newLocation = {
        instanceId = self._instance_counter,
        templateId = id,
        connections = {},
        x = x, -- Grid X
        y = y
    }
    setmetatable(newLocation, { __index = template })
    table.insert(self.locations, newLocation)

    return newLocation
end

function MapManager:addConnection(location1, location2)
    table.insert(location1.connections, location2)
    table.insert(location2.connections, location1)
end

function MapManager:setCurrentLocation(location)
    self.current = location
end

---@param location Location
---@param ctx Context
function MapManager:revealLocation(location, ctx)
    location:reveal(ctx)
    location.revealed = true

    if location.type == "event" then
        ctx.state:switch("event", { id = location.id })
    end
end


---@param location Location
---@param ctx Context
function MapManager:enterLocation(location, ctx)
    self:setCurrentLocation(location)
    location:enter(ctx)

    -- Don't switch to passive for event rooms (switch to event)
    if location.type ~= "event" or location.revealed then
        ctx.state:switch("passive")
    end

    if not location.revealed then
        self:revealLocation(location, ctx)
    end
end

---@param destination Location
function MapManager:moveTo(destination, ctx)
    local path = self:shortestPath(self.current, destination)

    for i = 2, #path do
        local nextStep = path[i]

        self:enterLocation(nextStep, ctx)
        -- TODO: expand this for different kinds of obstacles + potential to run past with opportunity attack?
        local enemies = ctx.enemies:getEnemiesInLocation(self.current)
        if enemies and #enemies > 0 then
            ctx.state:switch("passive")
            break
        end
    end
end


function MapManager:draw(ctx)
    UI.drawMap(ctx)
end

---@param distance integer
---@return Location[]
function MapManager:getLocationsWithin(distance)
    local visited = {}
    local currentLevel = {}

    currentLevel[self.current] = true
    visited[self.current] = true

    for i = 1, distance do
        local nextLevel = {}
        for location, _ in pairs(currentLevel) do
            for _, neighbour in ipairs(location.connections) do
                if not visited[neighbour] then
                    visited[neighbour] = true
                    nextLevel[neighbour] = true
                end
            end
        end

        currentLevel = nextLevel
        if next(currentLevel) == nil then break end
    end

    local result = {}
    for loc, _ in pairs(visited) do
        table.insert(result, loc)
    end

    return result
end

---@return Location[]
function MapManager:getLocationsInSpeed()
    return self:getLocationsWithin(self.speed)
end

---@param start Location
---@param destination   Location       
function MapManager:shortestPath(start, destination)
    local distances = {}
    local previous = {}
    local unvisited = {}

    for _, location in ipairs(self.locations) do
        distances[location] = math.huge
        previous[location] = nil
        table.insert(unvisited, location)
    end

    distances[start] = 0

    while #unvisited > 0 do
        table.sort(unvisited, function(a, b) return distances[a] < distances[b] end)
        local current = table.remove(unvisited, 1)

        if current == destination then break end

        for _, neighbour in ipairs(current.connections) do
            local alt = distances[current] + 1
            if alt < distances[neighbour] then
                distances[neighbour] = alt
                previous[neighbour] = current
            end
        end
    end

    local path = {}
    local curr = destination
    while curr do
        table.insert(path, 1, curr)
        curr = previous[curr]
    end

    return path
end

return MapManager