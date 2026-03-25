local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Roaming : State
---@field target_location Location
---@field target_x integer
---@field target_y integer
---@field speed integer     How many locations can be moved
local Roaming = setmetatable({}, { __index = State })
Roaming.__index = Roaming


---@return Roaming
function Roaming:new(ctx)
    local instance = State.new(self, ctx, "roaming")
    ---@cast instance Roaming

    return instance
end

function Roaming:enter(data)
    self.ctx.map.selected_location = self.ctx.map.current
    self.ctx.map.speed = data.speed
    -- set up UI
end

function Roaming:update(dt)
    self.map.selected_location = nil
    for _, location in ipairs(self.map:getLocationsInSpeed()) do
        if Utils.checkMouseCollision(location.screen_x, location.screen_y, location.w, location.h) then
            self.map.selected_location = location
        end
    end
end

function Roaming:exit()
    -- Clean up roaming
    self.ctx.map.selected_location = nil
end

---@param ctx Context
function Roaming:draw(ctx)
    self.ctx.map:draw(ctx)
end

function Roaming:mousereleased(x, y, button)
    self.map:moveTo(self.map.selected_location, self.ctx)
    self.state:switch("passive")
end

return Roaming