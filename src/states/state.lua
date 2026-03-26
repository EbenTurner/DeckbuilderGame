---@class State
---@field name string
---@field ctx Context
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
---@param ctx Context
---@param name string
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

---@param idx integer   The index of the card in hand | 0 for no active card
function State:setActiveCard(idx)
    local card = self.deck:getCard(idx)

    self.ctx.active_card = card
    self.ctx.active_card_idx = idx
    --- not sets nil to true, not not sets nil to false
    self.ctx.is_targeting = false
    if card and (card.targeted or card.is_equipment) then
        self.ctx.is_targeting = true
    end
end

---@return string|nil slot_id
function State:checkUICollisions()
    local equipment_slots = self.ctx.equipment.slot_hitboxes

    if equipment_slots then
        for id, box in pairs(equipment_slots) do
            if Utils.checkMouseCollision(box.x, box.y, box.w, box.h) then
                return id
            end
        end
    end
    return nil
end

return State