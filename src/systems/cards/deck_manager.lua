local CardDB = require("src.systems.cards.cards")
local ActionDB = require("src.systems.cards.actions")

---@class Equipment
---@field weapon Card|nil

---@class DeckManager
---@field deck Card[]
---@field hand Card[]
---@field _basehand Card[]
---@field discard Card[]
---@field actions Action[]
---@field _baseActions Action[]
---@field equipment Equipment
---@field selectedIdx integer
---@field maxHandSize integer
---@field _instance_counter integer
local DeckManager = {}

DeckManager.deck = {}
DeckManager.hand = {}
DeckManager._baseHand = {}
DeckManager.discard = {}
DeckManager.actions = {}
DeckManager._baseActions = {}
DeckManager.equipment = {
    weapon = nil
}

DeckManager.selectedIdx = 1
DeckManager.maxHandSize = 10
DeckManager._instance_counter = 0

---@param id string
function DeckManager:addCard(id)
    local template = CardDB:get(id)
    assert(template, "No card associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local newCard = {
        instanceId = self._instance_counter,
    }
    setmetatable(newCard, { __index = template })

    table.insert(self.deck, newCard)
end

---@param id string
function DeckManager:addAction(id)
    local template = ActionDB:get(id)
    assert(template, "No action associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local newAction = {
        instanceId = self._instance_counter,
    }
    setmetatable(newAction, { __index = template })

    table.insert(self._baseActions, newAction)

    self:sync()
end

function DeckManager:initialize()
    -- Create a standard starter set: to be replaced later
    self:addAction("attack")
    self:addAction("move")
    self:addCard("ice_bolt")
    self:addCard("fireball")
    self:addCard("longsword")
    self:addCard("sprint")

    self:shuffle()
end

-- Initial deck shuffle
function DeckManager:shuffle()
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

-- Shuffle discard back into deck
function DeckManager:reshuffle()
    if #self.discard > 0 then
        for i = #self.discard, 2, -1 do
            local j = math.random(i)
            self.discard[i], self.discard[j] = self.discard[j], self.discard[i]
        end
        self.deck = self.discard
        self.discard = {}
    end
end

-- Updates the current effective hand using base hand
-- Should be triggered every time the potential hand state has changed (e.g. drawing, equipping)
function DeckManager:sync()
    self.hand = {}
    for i, base in ipairs(self._baseHand) do
        self.hand[i] = self:getEffectiveCard(base)
    end

    self.actions = {}
    for i, base in ipairs(self._baseActions) do
        local effective = self:getEffectiveCard(base)

        ---@cast effective Action
        self.actions[i] = effective
    end
end

function DeckManager:addToHand(card)
    table.insert(self._baseHand, card)
    self:sync()
end

function DeckManager:removeFromHand(index)
    local card = table.remove(self._baseHand, index)
    self:sync()
    return card
end

function DeckManager:clearHand()
    for i = #self._baseHand, 1, -1 do
        local card = table.remove(self._baseHand, i)
        table.insert(self.discard, card)
    end
end

function DeckManager:drawCard(deck)
    if #self.deck == 0 then
        self:reshuffle()
    end

    local card = table.remove(self.deck)
    self:addToHand(card)
end


function DeckManager:startTurn()
    for _ = 1, 5 do
        self:drawCard()
    end

    self.selectedIdx = 1
end


function DeckManager:endTurn()
    self:clearHand()
end


function DeckManager:handSize()
    return #self.actions + #self.hand
end

function DeckManager:cycle(direction)
    local hand_size = self:handSize()
    if direction == "right" then
        self.selectedIdx = self.selectedIdx + 1
        if self.selectedIdx > hand_size then self.selectedIdx = 1 end
    elseif direction == "left" then
        self.selectedIdx = self.selectedIdx - 1
        if self.selectedIdx < 1 then self.selectedIdx = #self.hand end
    end
end

---@return Card, integer
function DeckManager:getSelectedCard()
    if self.selectedIdx <= #self.actions then
        return self.actions[self.selectedIdx], self.selectedIdx
    else
        local idx = self.selectedIdx - #self.actions
        return self.hand[self.selectedIdx - #self.actions], idx
    end
end

---@param ctx table
---@param target any?   -- should replace with some "Entity" class or something
function DeckManager:playCard(ctx, target)
    local card, idx = self:getSelectedCard()

    if not card then return end

    -- TODO: replace this with proper checking
    local playable, reason = ctx.player:playCard(card)

    if not playable then
        if reason == "ACTIONS" then
            ShowMessage("Insufficient Actions")
        elseif reason == "MANA" then
            ShowMessage("Insufficient Mana")
        else
            ShowMessage("Unknown error reason, please fix")
        end

        return
    end

    if card.targeted then
        card:effect(ctx, target)
    elseif card.effect then
        card:effect(ctx)
    end

    if card.type == "ACTION" then
        return
    end

    self:removeFromHand(idx)
    if self.selectedIdx > self:handSize() then
        if self:handSize() then self.selectedIdx = self:handSize() else self.selectedIdx = 1 end
    end

    if card.type == "ASSET" then
        self:equipAsset(card)
    else
        table.insert(self.discard, card)
    end
    self:sync()
end

---@param asset Card
function DeckManager:equipAsset(asset)
    assert(asset.slot, "The asset " .. asset.name .. " does not have a slot defined.")
    self.equipment[asset.slot] = asset
end

---@param originalCard Card
---@return Card
function DeckManager:getEffectiveCard(originalCard)
    local weapon = self.equipment.weapon

    if weapon and weapon.transforms[originalCard.id] then
        local transformedId = weapon.transforms[originalCard.id]
        local effectiveData = ActionDB:get(transformedId)

        return setmetatable({
            instanceId = originalCard.instanceId,
            isTransformed = true
        }, { __index = effectiveData })
    end

    return originalCard
end

return DeckManager