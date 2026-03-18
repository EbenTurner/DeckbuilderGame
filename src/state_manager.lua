local RoamingState = require("src.states.roaming")
local CombatState = require("src.states.combat")
local PassiveState = require("src.states.passive")
local UI = require("src.ui.renderer")

---@class States
---@field combat State | nil
---@field roaming State | nil
---@field passive State | nil

---@class StateManager
---@field states States
---@field current State
---@field ctx table
local StateManager = {}

StateManager.states = {
    roaming = nil,
    combat = nil,
    passive = nil
}

function StateManager:initialize(ctx)
    -- store references
    self.ctx = ctx

    -- create state instances
    self.states.roaming = RoamingState:new(ctx)
    self.states.combat  = CombatState:new(ctx)
    self.states.passive = PassiveState:new(ctx)

    -- inject global information into the instances
    for _, state in pairs(self.states) do
        state.ctx = ctx
    end

    -- start game in passive
    self:switch("passive")
end

function StateManager:switch(stateName, data)
    if self.current then self.current:exit() end

    self.current = self.states[stateName]
    assert(self.current, "State '" .. stateName .. "' dies not exist!")

    self.current:enter(data)
end

function StateManager:update(dt)
    if self.current then self.current:update(dt) end
end


function StateManager:draw()
    local deck = self.ctx.deck
    local map = self.ctx.map
    local player = self.ctx.player

    -- 1. UI information
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. #deck.deck .. ". Discard: " .. #deck.discard, 20, 20)
    love.graphics.print("Use Left/Right Arrows to cycle. Press 'D' to draw. Press 'Enter' to play selected card. Press 'H' to end turn.", 20, 40)
    love.graphics.print("Active card: " .. deck.selectedIdx, 20, 60)
    love.graphics.print("Current Location: " .. map.current.name, 20, 80)
    love.graphics.print("Current Location Desc: " .. map.current.description, 20, 100)
    love.graphics.print("Player health: " .. player.hp .. "/" .. player.max_hp, 20, 120)
    love.graphics.print("Actions: " .. player.actions .. "/" .. player.max_actions, 20, 140)
    love.graphics.print("Mana: " .. player.mana .. "/" .. player.max_mana, 20, 160)
    if deck.equipment.weapon then
        love.graphics.print("Equipped weapon: " .. deck.equipment.weapon.name, 20, 180)
    end

    -- 2. Draw current environment (e.g. Combat enemies)
    self.current:draw()

    -- 3. Draw Hand from the injected context
    UI.drawHand(deck)
end

function StateManager:keypressed(key)
    self.current:keypressed(key)
end

return StateManager