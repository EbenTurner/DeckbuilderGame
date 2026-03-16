local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Roaming : State
---@field moving boolean
---@field target_location Location
---@field target_x integer
---@field target_y integer
local Roaming = setmetatable({}, { __index = State })
Roaming.__index = Roaming


---@return Roaming
function Roaming:new(ctx)
    local instance = State.new(self, ctx)
    ---@cast instance Roaming

    return instance
end

function Roaming:enter(data)
    self.ctx.map.selected_location = self.ctx.map.current
    -- set up UI
end

function Roaming:update(dt)
    local local_enemies = self.ctx.enemies:getEnemiesInLocation(self.ctx.map.current) -- TODO: replace this with current ocation asap

    if #local_enemies > 0 then
        self.state:switch("combat")
    end
end

function Roaming:exit()
    -- Clean up roaming
end

function Roaming:draw()
    self.ctx.map:draw()

    -- TODO: Add the map + add separate controls for roaming if wanted
    -- Stop combat cards (i.e. attacks) being used outside of combat
end

function Roaming:keypressed(key)
    if key == "up" then
        self.map:moveSelected(0, -1)
    elseif key == "down" then
        self.map:moveSelected(0, 1)
    elseif key == "left" then
        self.map:moveSelected(-1, 0)
    elseif key == "right" then
        self.map:moveSelected(1, 0)
    elseif key == "return" or key == "space" then
        self.map:moveTo(self.map.selected_location, self.ctx)
    end
end

return Roaming