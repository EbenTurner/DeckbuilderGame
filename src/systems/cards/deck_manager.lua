local CardDB = require("src.systems.cards.cards")
local ActionDB = require("src.systems.cards.actions")

---@class DeckManager
---@field deck Card[]
---@field hand Card[]
---@field _base_hand Card[]
---@field discard Card[]
---@field actions Action[]
---@field _base_actions Action[]
---@field selectedIdx integer
---@field maxHandSize integer
---@field _instance_counter integer
local DeckManager = {
    deck = {},
    hand = {},
    _base_hand = {},
    discard = {},
    actions = {},
    _base_actions = {},
    selectedIdx = 1,
    maxHandSize = 10,
    _instance_counter = 0
}

function DeckManager:initialize()
    -- Create a standard starter set: to be replaced later
    self:addAction("attack")
    self:addAction("move")
    self:addCard("sprint")

    self:shuffle()
end

---@param ctx table
function DeckManager:update(ctx)
    -- sync the base hand and shown hand
    self:sync(ctx)
end

---@param id string
---@return Card
function DeckManager:addCard(id)
    local template = CardDB:get(id)
    assert(template, "No card associated with template for id: " .. id)

    self._instance_counter = self._instance_counter + 1

    local newCard = {
        instanceId = self._instance_counter,
    }
    setmetatable(newCard, { __index = template })

    table.insert(self.deck, newCard)

    return newCard
end

---@param card Card
function DeckManager:removeCard(card)
    for i = #self.deck, 1, -1 do
        if self.deck[i] == card then
            table.remove(self.deck, i)
            break
        end
    end

    for i = #self.hand, 1, -1 do
        if self.hand[i] == card then
            self:removeFromHand(i)
            break
        end
    end

    for i = #self.discard, 1, -1 do
        if self.discard[i] == card then
            table.remove(self.discard, i)
            break
        end
    end
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

    table.insert(self._base_actions, newAction)
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
-- TODO: does this need to still exist?
function DeckManager:sync(ctx)
    self.hand = {}
    for i, base in ipairs(self._base_hand) do
        self.hand[i] = self:getEffectiveCard(base, ctx)
    end

    self.actions = {}
    for i, base in ipairs(self._base_actions) do
        local effective = self:getEffectiveCard(base, ctx)
        ---@cast effective Action

        self.actions[i] = effective
    end
end

function DeckManager:addToHand(card)
    table.insert(self._base_hand, card)
end

function DeckManager:removeFromHand(index)
    local card = table.remove(self._base_hand, index)
    return card
end

function DeckManager:clearHand()
    for i = #self._base_hand, 1, -1 do
        local card = table.remove(self._base_hand, i)
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
        if self.selectedIdx < 1 then self.selectedIdx = hand_size end
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

    if card.is_action then
        return
    end

    self:removeFromHand(idx)
    self:sync(ctx)
    if self.selectedIdx > self:handSize() then
        if self:handSize() then self.selectedIdx = self:handSize() else self.selectedIdx = 1 end
    end

    table.insert(self.discard, card)
end

---@param originalCard Card
---@param ctx table
---@return Card
function DeckManager:getEffectiveCard(originalCard, ctx)
    ---@type table<string, Equipment|nil>
    local equipmentMap = ctx.equipment.equipment

    for _, item in pairs(equipmentMap) do
        if item.transforms and item.transforms[originalCard.id] then
            local transformedId = item.transforms[originalCard.id]
            local effectiveData = ActionDB:get(transformedId)

            return setmetatable({
                instanceId = originalCard.instanceId,
                isTransformed = true
            }, { __index = effectiveData })
        end
    end

    return originalCard
end

return DeckManager