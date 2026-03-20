---@class State
---@field name string
---@field ctx table
---@field state StateManager
---@field deck DeckManager
---@field enemies EnemyManager
---@field map MapManager
---@field player Player
local State = {}
State.__index = State


-- TODO: replace the name field, feels messy
function State:new(ctx, name)
    local instance = setmetatable({}, self)

    instance.name = name
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
function State:draw(ctx) end
function State:keypressed(key) end

return State