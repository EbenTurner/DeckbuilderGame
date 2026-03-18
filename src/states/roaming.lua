local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Roaming : State
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
    -- Update roaming
end

function Roaming:exit()
    -- Clean up roaming
    self.ctx.map.selected_location = nil
end

function Roaming:draw()
    self.ctx.map:draw()
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
        self.state:switch("passive")
    end
end

return Roaming