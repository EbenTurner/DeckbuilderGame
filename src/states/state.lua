---@class State
---@field location Location
---@field ctx table
---@field state StateManager
---@field deck DeckManager
---@field enemies EnemyManager
---@field map MapManager
---@field player Player
local State = {}
State.__index = State

function State:new(ctx)
    local instance = setmetatable({}, self)

    instance.ctx = ctx
    instance.state = ctx.state
    instance.deck = ctx.deck
    instance.enemies = ctx.enemies
    instance.map = ctx.map
    instance.player = ctx.player

    return instance
end

function State:enter(data) end
function State:exit() end
function State:update(dt) end
function State:draw() end
function State:keypressed(key) end

return State