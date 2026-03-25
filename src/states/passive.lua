local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Passive : State
local Passive = setmetatable({}, { __index = State })
Passive.__index = Passive


---@return Passive
function Passive:new(ctx)
    local instance = State.new(self, ctx, "passive")
    ---@cast instance Passive

    return instance
end

function Passive:enter(data)
    -- any UI changes
end

function Passive:update(dt)
    local local_enemies = self.ctx.enemies:getEnemiesInLocation(self.ctx.map.current)

    if #local_enemies > 0 then
        self.state:switch("combat")
    end

    self.deck.selected_idx = 0
    for i, card in ipairs(self.deck:getHand()) do
        if card and card.x then
            if Utils.checkMouseCollision(card.x, card.y, card.w, card.h) then
                self.deck.selected_idx = i
            end
        end
    end

    self.equipment.selected_slot_id = nil
    if self.equipment.slot_hitboxes then
        for id, box in pairs(self.equipment.slot_hitboxes) do
            if Utils.checkMouseCollision(box.x, box.y, box.w, box.h) then
                self.equipment.selected_slot_id = id
                break
            end
        end
    end
end

function Passive:exit()
    -- Clean up passive
end

function Passive:draw(ctx)
    self.ctx.map:draw(ctx)
end

function Passive:mousepressed(x, y, button)
    if button == 1 then
        local _, idx = self.deck:getSelectedCard()
        self:setActiveCard(idx)
    end
end

function Passive:mousereleased(x, y, button)
    if button == 1 then
        if self.ctx.active_card_idx > 0 then
            local card = self.deck:getCard(self.ctx.active_card_idx)

            if card and not card.combat_only then
                self.deck:playCard(self.ctx.active_card_idx, self.ctx)
            end
        end
    elseif button == 2 then
        self:setActiveCard(0)
    end
end

return Passive