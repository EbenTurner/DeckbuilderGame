local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Combat : State
---@field target_idx integer
local Combat = setmetatable({}, { __index = State })
Combat.__index = Combat

---@return Combat
function Combat:new(ctx)
    local instance = State.new(self, ctx, "combat")
    ---@cast instance Combat

    return instance
end

function Combat:enter(data)
    local location_enemies = self.ctx.enemies:getEnemiesInLocation(self.map.current)

    for _, enemy in ipairs(location_enemies) do
        self.enemies:engage(enemy.instanceId)
    end
end

function Combat:update(dt)
    local location_enemies = self.ctx.enemies:getEnemiesInLocation(self.map.current)
    for _, enemy in ipairs(location_enemies) do
        self.enemies:engage(enemy.instanceId)
    end

    for i = #self.enemies.engaged_enemies, 1, -1 do
        local enemy = self.enemies.engaged_enemies[i]

        if enemy.hp <= 0 then
            table.remove(self.enemies.engaged_enemies, i)
        end
    end

    if #self.enemies.engaged_enemies <= 0 then
        self.state:switch("passive")
    end

    self.deck.selected_idx = 0
    if not self.ctx.is_targeting then
        for i, card in ipairs(self.deck:getHand()) do
            if card and card.x then
                if Utils.checkMouseCollision(card.x, card.y, card.w, card.h) then
                    self.deck.selected_idx = i
                    break
                end
            end
        end
    else
        self.target_idx = 0
        for i, enemy in ipairs(self.enemies.engaged_enemies) do
            -- Ensure your Enemy renderer 'stamps' x, y, w, h similar to cards
            if enemy.x and Utils.checkMouseCollision(enemy.x, enemy.y, enemy.w, enemy.h) then
                self.target_idx = i
                break
            end
        end
    end

    self.equipment.selected_slot_id = nil
    if self.ctx.is_targeting then
        self.equipment.selected_slot_id = self:checkUICollisions()
    end
end

function Combat:exit()
    -- Unengage all enemies at the location
     for i = #self.enemies.engaged_enemies, 1, -1 do
        local enemy = self.enemies.engaged_enemies[i]
        table.remove(self.enemies.engaged_enemies, i)
        table.insert(self.enemies.unengaged_enemies, enemy)
    end
end

function Combat:draw(ctx)
    -- 1. Draw Enemies from the local list we populated in :enter()
    for i, enemy in ipairs(self.enemies.engaged_enemies) do
        local isSelected = (ctx.is_targeting and self.target_idx == i)
        local x = 400 + (i - 1) * 140 - (#self.enemies.engaged_enemies * 70)

        --TODO: move these hardcoded values
        enemy.x = x
        enemy.y = 200
        enemy.w = 120
        enemy.h = 120

        UI.drawEnemy(enemy, isSelected)
    end
end

function Combat:mousepressed(x, y, button)
    if button == 1 then
        local _, idx = self.deck:getSelectedCard()
        self:setActiveCard(idx)
    end
end

function Combat:mousereleased(x, y, button)
    local target = nil

    if button == 1 then
        if self.ctx.active_card_idx > 0 then
            local card = self.deck:getCard(self.ctx.active_card_idx)
            if not card then return end

            if self.ctx.is_targeting and self.target_idx and self.target_idx > 0 then
                target = self.enemies.engaged_enemies[self.target_idx]
            end

            if card.is_equipment and not self.ctx.equipment.selected_slot_id then
                goto cleanup
            end

            self.deck:playCard(self.ctx.active_card_idx, self.ctx, target)
        end
    end

    ::cleanup::
    self:setActiveCard(0)
    assert(self.ctx.active_card_idx == 0)
end

return Combat