local Renderer = {}

local screenW = love.graphics.getWidth()
local screenH = love.graphics.getHeight()

local infoWidth = screenW * 0.2
local infoHeight = screenH * 0.3
local equipmentWidth = infoWidth
local equipmentHeight = screenH - infoHeight
local mainWidth = screenW - infoWidth
local handHeight = screenH * 0.35
local mainHeight = screenH - handHeight

local layout = {
    -- Screen zones
    infoZone = { x = 0, y = 0, w = infoWidth, h = infoHeight },
    equipmentZone = { 
        x = 0, y = infoHeight, w = equipmentWidth, h = equipmentHeight,
        slotSize = equipmentWidth * 0.4, padding = equipmentWidth * 0.05
    },
    mainZone = { x = infoWidth, y = 0, w = mainWidth, h = mainHeight },
    handZone = { x = 0, y = mainHeight, w = screenW, h = handHeight },

    -- Card specifics
    cardW = 100,
    cardH = 140,
    liftH = 15,
}

-- Draws a single enemy
---@param enemy Enemy
---@param isSelected boolean
function Renderer.drawEnemy(enemy, isSelected)
    -- Background Box
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.w, enemy.h, 5, 5)

    -- Border
    love.graphics.setColor(isSelected and {1, 1, 0} or {1, 1, 1})
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", enemy.x, enemy.y, enemy.w, enemy.h, 5, 5)

    -- Health Bar Background
    love.graphics.setColor(0.5, 0.1, 0.1)
    love.graphics.rectangle("fill", enemy.x + 10, enemy.y + 90, enemy.w * 0.8, 10)

    -- Health Bar Fill
    local hpPercent = enemy.hp / enemy.max_hp
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", enemy.x + 10, enemy.y + 90, enemy.w * 0.8 * hpPercent, 10)

    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(enemy.name, enemy.x, enemy.y + 20, 120, "center")
    love.graphics.printf(enemy.damage .. " dmg", enemy.x, enemy.y + 60, 120, "center")
    love.graphics.printf(enemy.hp .. "/" .. enemy.max_hp, enemy.x, enemy.y + 100, 120, "center")
end

local Palette = {
    event       = { 0.94, 0.90, 0.90 },
    action      = { 0.82, 0.75, 0.60 },
    text        = { 0.15, 0.12, 0.10 }, -- Not pure black, but a "Dried Ink" dark brown
    text_error  = { 0.60, 0.20, 0.20 }, -- Faded Blood/Red Ink
    disabled    = { 0.40, 0.38, 0.35 }, -- Muted "Mud" color
    highlight   = { 0.85, 0.45, 0.20 }, -- A burnt orange/copper for selection
    transform   = { 0.20, 0.50, 0.20 }, -- A deep forest green for gear-modified cards
}

---@param card Card
---@param isSelected boolean
---@param ctx Context
local function drawCard(card, isSelected, ctx)
    local state = ctx.state.current.name
    local currentMana = ctx.player.mana

    local draw_y = card.y or 0
    if isSelected then draw_y = card.y - layout.liftH end

    -- 1. DRAW THE CARD BODY (The Background)
    local bgColor = Palette.event
    local borderColor = {0, 0, 0}
    local isCombatLocked = (state ~= "combat" and card.combat_only)

    if isCombatLocked then
        bgColor = Palette.disabled
    elseif card.is_action then
        bgColor = Palette.action
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", card.x, draw_y, card.w, card.h)

    -- 2. DRAW THE CARD BORDER

    -- highlight for selected card
    if isSelected then
        love.graphics.setColor(Palette.highlight)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", card.x - 4, draw_y - 4, card.w + 8, card.h + 8)
    end

    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", card.x, draw_y, card.w, card.h)

    -- 3. DRAW THE TEXT (The Foreground)
    love.graphics.setColor(Palette.text)
    love.graphics.print(card.name, card.x + 10, draw_y + 10)

    if card.cost > currentMana then
        love.graphics.setColor(Palette.text_error)
    end
    love.graphics.print("Cost: " .. card.cost, card.x + 10, draw_y + card.h - 30)
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

---@param deck DeckManager
---@param ctx Context
function Renderer.drawHand(deck, ctx)
    local numActions = #deck.actions
    local numHand = #deck.hand
    local totalCards = numActions + numHand

    -- 1. Helper to handle the "Update + Draw" logic per card
    local function processCard(card, i, isTotalIndex)
        local x, y = calculateCardPosition(isTotalIndex, totalCards)

        -- Update the card's physical data
        card.x, card.y = x, y
        card.w, card.h = layout.cardW, layout.cardH

        -- Draw the card (only if it's NOT the selected one; we draw that last for layering)
        if isTotalIndex ~= deck.selected_idx then
            drawCard(card, false, ctx)
        end
    end

    -- 2. Process Actions
    for i, card in ipairs(deck.actions) do
        processCard(card, i, i)
    end

    -- 3. Process Hand
    for i, card in ipairs(deck.hand) do
        processCard(card, i, numActions + i)
    end

    -- 4. Draw the Selected Card last (so it appears on top)
    local selected_card = deck.actions[deck.selected_idx] or deck.hand[deck.selected_idx - numActions]
    if selected_card then
        drawCard(selected_card, true, ctx)
    end
end

---@param ctx Context
function Renderer.drawMap(ctx)
    local map = ctx.map
    local enemies = ctx.enemies
    local zone = layout.mainZone
    local GRID_SIZE = 100
    local box_size = 30

    -- Determine map bounds
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for _, loc in ipairs(map.locations) do
        minX, maxX = math.min(minX, loc.x), math.max(maxX, loc.x)
        minY, maxY = math.min(minY, loc.y), math.max(maxY, loc.y)
    end
    local mapMidX, mapMidY = (minX + maxX) / 2, (minY + maxY) / 2
    local offsetX = (zone.x + zone.w / 2) - (mapMidX * GRID_SIZE)
    local offsetY = (zone.y + zone.h / 2) - (mapMidY * GRID_SIZE)

    -- Helper function to convert grid units to screen units
    local function toScreen(gx, gy)
        return gx * GRID_SIZE + offsetX, gy * GRID_SIZE + offsetY
    end

    local mx, my = love.mouse.getPosition()
    Renderer.lastMx, Renderer.lastMy = mx, my

    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, loc in ipairs(map.locations) do
        local sx, sy = toScreen(loc.x, loc.y)
        for _, conn in ipairs(loc.connections) do
            local tx, ty = toScreen(conn.x, conn.y)
            love.graphics.line(sx, sy, tx, ty)
        end
    end

    local path = (map.selected_location ~= map.current) and map:shortestPath(map.current, map.selected_location) or {}

    for _, loc in ipairs(map.locations) do
        local sx, sy = toScreen(loc.x, loc.y)

        loc.w, loc.h = box_size, box_size
        loc.screen_x = sx - (loc.w / 2)
        loc.screen_y = sy - (loc.h / 2)

        local onPath = false -- find locations on the selected path
        for _, path_loc in ipairs(path) do if loc == path_loc then onPath = true end end

        -- Set location colour dependent on conditions
        if loc == map.current then love.graphics.setColor(0.2, 0.8, 0.2)
        elseif loc.revealed and #enemies:getEnemiesInLocation(loc) > 0 then love.graphics.setColor(1, 0.2, 0.2)
        elseif onPath then love.graphics.setColor(loc.revealed and {0.4, 0.7, 1} or {1, 0.6, 0})
        else love.graphics.setColor(1, 1, 1) end

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

---@param ctx Context
function Renderer.drawEquipment(ctx)
    local equip = ctx.equipment.equipment
    local zone = layout.equipmentZone

    local slots = {
        { id = "hand1", col = 0, row = 0, label = "L. Hand" },
        { id = "hand2", col = 1, row = 0, label = "R. Hand" },
        { id = "body",  col = 0.5, row = 1, label = "Body" } -- 0.5 centers it under the two
    }

    for _, slot in ipairs(slots) do
        -- Calculate Screen Position
        slot.x = zone.padding + zone.x + (slot.col * (zone.slotSize + zone.padding))
        slot.y = zone.y + (slot.row * (zone.slotSize + zone.padding))
        slot.w, slot.h = zone.slotSize, zone.slotSize

        -- 1. Draw the Slot Box (The Background)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", slot.x, slot.y, slot.w, slot.h, 4)

        -- 2. Draw the Item (if equipped)
        local item = equip[slot.id]
        if item then
            love.graphics.setColor(1, 1, 1)
            -- Draw a mini version of the card or an icon
            love.graphics.print(item.name, slot.x + 5, slot.y + 20, 0, 0.7) 
        else
            -- Draw Placeholder Label
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf(slot.label, slot.x, slot.y + 20, slot.w, "center")
        end

        -- 3. Highlight if Hovered
        if ctx.equipment.selected_slot_id == slot.id then
            love.graphics.setColor(1, 1, 0, 0.5)
            love.graphics.rectangle("line", slot.x, slot.y, slot.w, slot.h, 4)
        end

        -- Stamp for the Update loop
        -- We store this in the context so the State can see it
        ctx.equipment.slot_hitboxes = ctx.equipment.slot_hitboxes or {}
        ctx.equipment.slot_hitboxes[slot.id] = { x = slot.x, y = slot.y, w = slot.w, h = slot.h }
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

---@param ctx Context
function Renderer.drawTargetingUI(ctx)
    if ctx.is_targeting and ctx.active_card then
        local mx, my = love.mouse.getPosition()
        local cardX = ctx.active_card.x + (ctx.active_card.w / 2)
        local cardY = ctx.active_card.y * 1

        -- Draw a line or curve from card to mouse
        love.graphics.setLineWidth(4)
        love.graphics.setColor(1, 0, 0, 0.6) -- Semi-transparent red
        love.graphics.line(cardX, cardY, mx, my)

        -- Draw a reticle at the mouse
        love.graphics.circle("line", mx, my, 15)
    end
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