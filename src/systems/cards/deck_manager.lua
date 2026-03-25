local CardDB = require("src.systems.cards.cards")
local ActionDB = require("src.systems.cards.actions")

---@class DeckManager
---@field deck Card[]
---@field hand Card[]
---@field _base_hand Card[]
---@field discard Card[]
---@field actions Action[]
---@field _base_actions Action[]
---@field selected_idx integer
---@field maxHandSize integer
---@field _instance_counter integer
local DeckManager = {
    deck = {},
    hand = {},
    _base_hand = {},
    discard = {},
    actions = {},
    _base_actions = {},
    selected_idx = 1,
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

---@param ctx Context
function DeckManager:update(ctx)
    -- sync the base hand and shown hand
    self:sync(ctx)
end

function DeckManager:getHand()
    local joined = {}
    for _, card in ipairs(self.actions) do
        table.insert(joined, card)
    end

    for _, card in ipairs(self.hand) do
        table.insert(joined, card)
    end

    return joined
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
    for i = #self.discard, 1, -1 do
        table.insert(self.deck, self.discard[i])
        table.remove(self.discard, i)
    end

    self:shuffle()
end

-- Updates the current effective hand using base hand
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

---@param idx integer   Should be relative to the entire hand (actions included)
function DeckManager:removeFromHand(idx)
    if idx <= #self.actions then return end

    -- Get idx relative to hand array
    idx = idx - #self.actions

    local card = table.remove(self._base_hand, idx)
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

    self.selected_idx = 1
end


function DeckManager:endTurn()
    self:clearHand()
end

---@param idx integer
---@return Card?
function DeckManager:getCard(idx)
    if not idx or idx <= 0 then return nil end

    if idx <= #self.actions then
        return self.actions[idx]
    else
        idx = idx - #self.actions
        return self.hand[idx]
    end
end

---@return Card?, integer
function DeckManager:getSelectedCard()
    return self:getCard(self.selected_idx), self.selected_idx
end


--TODO: replace relative card index with an overall index
---@param idx integer       The card index
---@param ctx Context
---@param target any?       TODO: Should replace with some "Entity" class or something
function DeckManager:playCard(idx, ctx, target)
    local card

    if idx then
        card = self:getCard(idx)
    else
        card, idx = self:getSelectedCard()
    end

    if not card then return end

    -- TODO: replace this with proper checking
    local playable, reason = ctx.player:canPlayCard(card)

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
        if not target then return end
        card:effect(ctx, target)
    elseif card.effect then
        card:effect(ctx)
    end

    ctx.player:playCard(card) -- Do costs here only if card is resolved

    if card.is_action then
        return
    end

    self:removeFromHand(idx)
    self:sync(ctx)

    table.insert(self.discard, card)
end

---@param originalCard Card
---@param ctx Context
---@return Card
function DeckManager:getEffectiveCard(originalCard, ctx)
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