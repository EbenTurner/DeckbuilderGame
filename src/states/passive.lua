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

-- Stop combat cards (i.e. attacks) being used outside of combat
-- function Passive:keypressed(key)
--     if key == "right" or key == "left" then
--         self.deck:cycle(key)
--     elseif key == "return" then
--         local card = self.deck:getSelectedCard()
--         if not card then return end

--         if not card.combat_only then
--             self.deck:playCard(self.ctx)
--         end
--     end
-- end

function Passive:onClick()
    local card = self.deck:getSelectedCard()

    if card and not card.combat_only then
        self.deck:playCard(self.ctx)
    end
end

return Passive