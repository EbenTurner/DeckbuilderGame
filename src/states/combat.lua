local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Combat : State
---@field is_targeting boolean
---@field target_idx integer
---@field targeting_card integer
local Combat = setmetatable({}, { __index = State })
Combat.__index = Combat

---@return Combat
function Combat:new(ctx)
    local instance = State.new(self, ctx, "combat")
    ---@cast instance Combat

    instance.is_targeting = false
    instance.targeting_card = nil

    return instance
end

function Combat:enter(data)
    local location_enemies = self.ctx.enemies:getEnemiesInLocation(self.map.current)

    for _, enemy in ipairs(location_enemies) do
        self.enemies:engage(enemy.instanceId)
    end

    self.deck.selected_idx = 1
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
    self.target_idx = 0

    if not self.is_targeting then
        for i, card in ipairs(self.deck:getHand()) do
            if card and card.x then
                if Utils.checkMouseCollision(card.x, card.y, card.w, card.h) then
                    self.deck.selected_idx = i
                end
            end
        end
    else
        for i, enemy in ipairs(self.enemies.engaged_enemies) do
            -- Ensure your Enemy renderer 'stamps' x, y, w, h similar to cards
            if enemy.x and Utils.checkMouseCollision(enemy.x, enemy.y, enemy.w, enemy.h) then
                self.target_idx = i
                break
            end
        end
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
        local isSelected = (self.is_targeting and self.target_idx == i)
        local x = 400 + (i - 1) * 140 - (#self.enemies.engaged_enemies * 70)

        --TODO: move these hardcoded values
        enemy.x = x
        enemy.y = 200
        enemy.w = 120
        enemy.h = 120

        UI.drawEnemy(enemy, isSelected)
    end
end

function Combat:keypressed(key)
    if self.is_targeting then
        if key == "escape" then
            self.is_targeting = false -- Cancel targeting
        elseif key == "return" then
            local target = self.enemies.engaged_enemies[self.target_idx]
            if not target then return end

            self.deck:playCard(self.ctx, target, self.targeting_card)
            self.is_targeting = false
            self.targeting_card = nil
        end
    end
end

function Combat:onClick()
    if not self.is_targeting then
        local card, idx = self.deck:getSelectedCard()
        if not card then return end

        if card.targeted then
            self.is_targeting = true
            self.targeting_card = idx
            self.target_idx = 1
        else
            self.deck:playCard(self.ctx)
        end
    else
        local target = self.enemies.engaged_enemies[self.target_idx]
        if not target then return end

        self.deck:playCard(self.ctx, target, self.targeting_card)
        self.is_targeting = false
        self.targeting_card = nil
    end
end

return Combat