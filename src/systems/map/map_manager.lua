local LocationDB = require("src.systems.map.locations")

---@class MapManager
---@field locations Location[]
---@field current Location
---@field _instance_counter integer
---@field selected_location Location
local MapManager = {}

MapManager.locations = {}
MapManager._instance_counter = 0

function MapManager:initialize()
    -- Add one room and start there
    local startRoom = self:addLocation("room", 0, 0)
    local tavern = self:addLocation("tavern", 1, 0)
    local boss = self:addLocation("boss", 1, 1)
    local horRoom = self:addLocation("room", 2, 0)

    self:addConnection(startRoom, tavern)
    self:addConnection(tavern, boss)
    self:addConnection(horRoom, tavern)

    self:setCurrentLocation(startRoom)
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

function MapManager:moveTo(target, ctx)
    local isConnected = false
    for _, conn in ipairs(self.current.connections) do
        if conn == target then
            isConnected = true
            break
        end
    end

    if isConnected then
        self:setCurrentLocation(target)

        if not target.discovered then
            target:reveal(ctx)
            target.discovered = true
        end

        target:enter(ctx)
    end
    return false
end


function MapManager:draw()
    local GRID_SIZE = 100
    local OFFSET = 200
    local box_size = 30

    for _, loc in ipairs(self.locations) do
        local screenX = loc.x * GRID_SIZE + OFFSET
        local screenY = loc.y * GRID_SIZE + OFFSET

        love.graphics.setColor(0.5, 0.5, 0.5)
        for _, conn in ipairs(loc.connections) do
            love.graphics.line(screenX, screenY, conn.x * GRID_SIZE + OFFSET, conn.y * GRID_SIZE + OFFSET)
        end
    end

    for _, loc in ipairs(self.locations) do
        local screenX = loc.x * GRID_SIZE + OFFSET
        local screenY = loc.y * GRID_SIZE + OFFSET

        if loc == self.current then
            love.graphics.setColor(1, 1, 0) -- Highlight current location
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.circle("fill", screenX, screenY, 10)
        love.graphics.print(loc.name, screenX + 12, screenY - 6)

        if loc == self.selected_location then
            love.graphics.setColor(1, 1, 0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle(
                "line",
                screenX - (box_size / 2),
                screenY - (box_size / 2),
                box_size,
                box_size,
                4
            )
        end
    end
end

function MapManager:moveSelected(dx, dy)
    local tx, ty  = self.selected_location.x + dx, self.selected_location.y + dy

    -- only want to be able to move hover to adjacent locations
    for _, loc in ipairs(self.selected_location.connections) do
        if loc.x == tx and loc.y == ty then
            self.selected_location = loc
            return true
        end
    end

    return false
end

return MapManager