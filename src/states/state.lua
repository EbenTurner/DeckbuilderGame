---@class State
---@field name string
---@field ctx table
---@field state StateManager
---@field deck DeckManager
---@field equipment EquipmentManager
---@field enemies EnemyManager
---@field map MapManager
---@field player Player
---@field last_mouse_x number
---@field last_mouse_y number
local State = {}
State.__index = State


-- TODO: replace the name field, feels messy
function State:new(ctx, name)
    local instance = setmetatable({}, self)

    instance.name = name
    instance.ctx = ctx
    instance.state = ctx.state
    instance.deck = ctx.deck
    instance.equipment = ctx.equipment
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
function State:mousepressed(x, y, button) end
function State:mousereleased(x, y, button) end

---@param idx integer   The index of the card in hand
function State:setActiveCard(idx)
    local card = self.deck:getCard(idx)

    self.ctx.active_card = card
    self.ctx.active_card_idx = idx
    if card then self.ctx.is_targeting = card.targeted else self.ctx.is_targeting = false end
end

return State