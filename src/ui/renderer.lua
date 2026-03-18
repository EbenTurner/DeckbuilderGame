local Renderer = {}

local screenW = love.graphics.getWidth()
local screenH = love.graphics.getHeight()

local infoWidth = screenW * 0.2
local mainWidth = screenW - infoWidth
local handHeight = screenH * 0.35
local mainHeight = screenH - handHeight

local layout = {
    -- Screen zones
    infoZone = { x = 0, y = 0, w = infoWidth, h = mainHeight },
    mainZone = { x = infoWidth, y = 0, w = mainWidth, h = mainHeight },
    handZone = { x = 0, y = mainHeight, w = screenW, h = handHeight },

    -- Card specifics
    cardW = 100,
    cardH = 140,
    liftH = 15,
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
    local hpPercent = enemy.hp / enemy.max_hp
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", x + 10, y + 100, 100 * hpPercent, 10)

    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(enemy.name, x, y + 40, 120, "center")
    love.graphics.printf(enemy.hp .. "/" .. enemy.max_hp, x, y + 110, 120, "center")
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
    local zone = layout.handZone
    local spacing = 5

    local naturalWidth = (numCards * layout.cardW) + ((numCards - 1) * spacing)
    local finalHandWidth = math.min(naturalWidth, zone.w * 0.95)
    local leftBound = zone.x + (zone.w / 2) - (finalHandWidth / 2)

    local centerY = zone.y + (zone.h / 2) - (layout.cardH / 2)

    local x
    if numCards > 1 then
        local travelDistance = finalHandWidth - layout.cardW
        x = leftBound + (index - 1) * (travelDistance / (numCards - 1))
    else
        x = zone.x + (zone.w / 2) - (layout.cardW / 2)
    end

    return x, centerY
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

function Renderer.drawMap(ctx)
    ---@type MapManager
    local map = ctx.map
    ---@type EnemyManager
    local enemies = ctx.enemies

    local zone = layout.mainZone
    local GRID_SIZE = 100
    local box_size = 30

    -- Determine map bounds
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for _, loc in ipairs(map.locations) do
        minX = math.min(minX, loc.x)
        maxX = math.max(maxX, loc.x)
        minY = math.min(minY, loc.y)
        maxY = math.max(maxY, loc.y)
    end

    -- Determine map center
    local mapMidX = (minX + maxX) / 2
    local mapMidY = (minY + maxY) / 2

    local offsetX = (zone.x + zone.w / 2) - (mapMidX * GRID_SIZE)
    local offsetY = (zone.y + zone.h / 2) - (mapMidY * GRID_SIZE)

    -- Helper function to convert grid units to screen units
    local function toScreen(gx, gy)
        return gx * GRID_SIZE + offsetX, gy * GRID_SIZE + offsetY
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, loc in ipairs(map.locations) do
        local sx, sy = toScreen(loc.x, loc.y)
        for _, conn in ipairs(loc.connections) do
            local tx, ty = toScreen(conn.x, conn.y)
            love.graphics.line(sx, sy, tx, ty)
        end
    end

    local path = {}
    if map.selected_location ~= map.current then
        path = map:shortestPath(map.current, map.selected_location)
    end

    for _, loc in ipairs(map.locations) do
        local sx, sy = toScreen(loc.x, loc.y)

        local onPath = false -- find locations on the selected path
        for _, path_loc in ipairs(path) do
            if loc == path_loc then
                onPath = true
            end
        end

        local locationEnemies = enemies:getEnemiesInLocation(loc)
        local containsEnemies = (#locationEnemies > 0)

        if loc == map.current then
            love.graphics.setColor(0.2, 0.8, 0.2) -- Current Location: GREEN
        elseif onPath then
            if loc.revealed then
                if containsEnemies then
                    love.graphics.setColor(1, 0.2, 0.2) -- Enemies: RED
                else
                    love.graphics.setColor(0.4, 0.7, 1) -- Unrevealed: AMBER
                end
            else
                love.graphics.setColor(1, 0.6, 0) -- Revealed: Blue
            end
        else
            love.graphics.setColor(1, 1, 1) -- Unselected: White
        end

        love.graphics.circle("fill", sx, sy, 10)

        -- Text with drop shadow
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(loc.name, sx + 13, sy - 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(loc.name, sx + 12, sy - 6)

        if loc == map.selected_location then
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", sx - (box_size/2), sy - (box_size/2), box_size, box_size, 4)
        end
    end
end

-- TODO: remove / change this, used for identifying sections
function Renderer.drawLayout()
    love.graphics.setLineWidth(1)
    -- Info Section
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("line", layout.infoZone.x, layout.infoZone.y, layout.infoZone.w, layout.infoZone.h)

    -- Main Section
    love.graphics.setColor(0.2, 0.1, 0.1)
    love.graphics.rectangle("line", layout.mainZone.x, layout.mainZone.y, layout.mainZone.w, layout.mainZone.h)

    -- Hand Section
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("line", layout.handZone.x, layout.handZone.y, layout.handZone.w, layout.handZone.h)
end

-- Draw Info Text (Corrected to stay in the 10% column)
local printLocation = 10

function Renderer.resetPrint()
    printLocation = 10
end

function Renderer.print(text)
    love.graphics.setColor(1, 1, 1)
    
    local font = love.graphics.getFont()
    local widthLimit = layout.infoZone.w - 10
    
    -- 1. Draw the text
    love.graphics.printf(text, layout.infoZone.x + 5, printLocation, widthLimit, "left")
    
    -- 2. Calculate how many lines were actually rendered
    local _, wrappedLines = font:getWrap(text, widthLimit)
    local lineCount = #wrappedLines
    
    -- 3. Move the pointer down based on line count + a small gap (2px)
    printLocation = printLocation + (lineCount * font:getHeight()) + 5
end

return Renderer