local Renderer = {}

local screenW = love.graphics.getWidth()
local screenH = love.graphics.getHeight()

local layout = {
    handX = screenW * 0.5,
    handY = screenH * 0.7,
    gutter = screenW * 0.05,
    handWidth = screenW * 0.9,
    cardW = 100,
    cardH = 140,
    liftH = 15, -- How high selected card is lifted
}

-- Draws a single enemy
---@param enemy Enemy
---@param x integer
---@param y integer
function Renderer.drawEnemy(enemy, x, y, isSelected)
    -- Background Box
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, 120, 120, 5, 5)

    -- Border
    love.graphics.setColor(isSelected and {1, 1, 0} or {1, 1, 1})
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", x, y, 120, 120, 5, 5)

    -- Health Bar Background
    love.graphics.setColor(0.5, 0.1, 0.1)
    love.graphics.rectangle("fill", x + 10, y + 100, 100, 10)

    -- Health Bar Fill
    local hpPercent = enemy.hp / enemy.maxHp
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", x + 10, y + 100, 100 * hpPercent, 10)

    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(enemy.name, x, y + 40, 120, "center")
    love.graphics.printf(enemy.hp .. "/" .. enemy.maxHp, x, y + 110, 120, "center")
end

---@param card Card
---@param x integer
---@param y integer
---@param isSelected boolean
local function drawCard(card, x, y, isSelected)
    if isSelected then y = y - layout.liftH end -- lift selected card

    -- 1. DRAW THE CARD BODY (The Background)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, layout.cardW, layout.cardH)

    -- 2. DRAW THE CARD BORDER

    -- highlight for selected card
    if isSelected then
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", x - 5, y - 5, layout.cardW + 10, layout.cardH + 10)
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, layout.cardW, layout.cardH)

    -- 3. DRAW THE TEXT (The Foreground)
    love.graphics.print(card.name, x + 10, y + 10)
    love.graphics.print("Cost: " .. card.cost, x + 10, y + 120)
end

-- Helper function for positioning the cards (overlaps them if needed)
local function calculateCardPosition(index, numCards)
    local cardW = layout.cardW
    local spacing = 5

    local naturalWidth = (numCards * cardW) + ((numCards - 1) * spacing)
    local finalHandWidth = math.min(naturalWidth, layout.handWidth)
    local leftBound = layout.handX - (finalHandWidth / 2)

    local x
    if numCards > 1 then
        local travelDistance = finalHandWidth - cardW
        x = leftBound + (index - 1) * (travelDistance / (numCards - 1))
    else
        x = layout.handX - (cardW / 2)
    end

    return x, layout.handY
end

function Renderer.drawHand(deck)
    local numCards = #deck.actions + #deck.hand

    -- Draw cards in hand (overlap cards when there are many)
    for i, card in ipairs(deck.actions) do
        if i ~= deck.selectedIdx then
            local x, y = calculateCardPosition(i, numCards)
            drawCard(card, x, y, false)
        end
    end

    -- set handSelectedIdx relative to hand positioning
    local handSelectedIdx = deck.selectedIdx - #deck.actions
    for i, card in ipairs(deck.hand) do
        if i ~= handSelectedIdx then
            local x, y = calculateCardPosition(#deck.actions + i, numCards)
            drawCard(card, x, y, false)
        end
    end

    if deck.actions[deck.selectedIdx] then
        local x, y = calculateCardPosition(deck.selectedIdx, numCards)
        drawCard(deck.actions[deck.selectedIdx], x, y, true)
    end

    local hand_idx = deck.selectedIdx - #deck.actions
    if deck.hand[hand_idx] then
        local x, y = calculateCardPosition(#deck.actions + hand_idx, numCards)
        drawCard(deck.hand[hand_idx], x, y, true)
    end
end

local printLocation = 0
function Renderer.print(text)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, 20, printLocation)
    printLocation = printLocation + 20
end

return Renderer