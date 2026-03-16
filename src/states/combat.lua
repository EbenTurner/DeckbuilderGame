local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Combat : State
---@field is_targeting boolean
---@field target_idx integer
local Combat = setmetatable({}, { __index = State })
Combat.__index = Combat

---@return Combat
function Combat:new(ctx)
    local instance = State.new(self, ctx)
    ---@cast instance Combat

    instance.is_targeting = false

    return instance
end

function Combat:enter(data)
    local location_enemies = self.ctx.enemies:getEnemiesInLocation(self.map.current)

    for i, enemy in ipairs(location_enemies) do
        self.enemies:engage(enemy.instanceId)
    end

    self.deck.selectedIdx = 1
end

function Combat:update(dt)
    for i = #self.enemies.engaged_enemies, 1, -1 do
        local enemy = self.enemies.engaged_enemies[i]

        if enemy.hp <= 0 then
            table.remove(self.enemies.engaged_enemies, i)
        end
    end

    if #self.enemies.engaged_enemies <= 0 then
        self.state:switch("roaming")
    end
end

function Combat:exit()
    -- Clean up combat

end

function Combat:draw()
    -- 1. Draw Enemies from the local list we populated in :enter()
    for i, enemy in ipairs(self.enemies.engaged_enemies) do
        local isSelected = (self.is_targeting and self.target_idx == i)
        local x = 400 + (i - 1) * 140 - (#self.enemies.engaged_enemies * 70)
        UI.drawEnemy(enemy, x, 200, isSelected)
    end
end

function Combat:keypressed(key)
    if not self.is_targeting then
        -- PHASE 1: Selecting a Card
        if key == "right" or key == "left" then
            self.deck:cycle(key)
        elseif key == "return" then
            local card = self.deck:getSelectedCard()
            if card.targeted then
                self.is_targeting = true
                self.target_idx = 1 -- Start by targeting the first enemy
            else
                self.deck:playCard(self.ctx) -- Play non-targeted card immediately
            end
        end
    else
        -- PHASE 2: Selecting a Target
        if key == "left" or key == "up" then
            self.target_idx = math.max(1, self.target_idx - 1)
        elseif key == "right" or key == "down" then
            self.target_idx = math.min(#self.enemies.engaged_enemies, self.target_idx + 1)
        elseif key == "escape" then
            self.is_targeting = false -- Cancel targeting
        elseif key == "return" then
            -- CONFIRM ATTACK
            local target = self.enemies.engaged_enemies[self.target_idx]
            self.deck:playCard(self.ctx, target)
            self.is_targeting = false -- Return to card selection
        end
    end
end

return Combat