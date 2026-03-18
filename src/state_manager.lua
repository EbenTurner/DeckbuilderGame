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
    UI.resetPrint()
    UI.print("Deck: " .. #deck.deck .. ". Discard: " .. #deck.discard)
    UI.print("Current Location: " .. map.current.name)
    UI.print(map.current.description)
    UI.print("Player health: " .. player.hp .. "/" .. player.max_hp)
    UI.print("Actions: " .. player.actions .. "/" .. player.max_actions)
    UI.print("Mana: " .. player.mana .. "/" .. player.max_mana)
    if deck.equipment.weapon then
        UI.print("Equipped weapon: " .. deck.equipment.weapon.name)
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