local StateManager = require("src.state_manager")
local DeckManager = require("src.systems.cards.deck_manager")
local EnemyManager = require("src.systems.enemies.enemy_manager")
local MapManager = require("src.systems.map.map_manager")
local Player = require("src.systems.player.player")

local context = {
    state = StateManager,
    deck = DeckManager,
    enemies = EnemyManager,
    map = MapManager,
    player = Player
}

local feedback = {
    message = "",
    timer = 0,
    duration = 2.0, -- How many seconds the box stays
    alpha = 0       -- For a nice fade-out effect
}

function ShowMessage(text)
    feedback.message = text
    feedback.timer = feedback.duration
    feedback.alpha = 1
end

local function updateFeedback(dt)
    if feedback.timer > 0 then
        feedback.timer = feedback.timer - dt
        -- Start fading out in the last 0.5 seconds
        if feedback.timer < 0.5 then
            feedback.alpha = feedback.timer / 0.5
        end
    end
end

local function drawFeedback()
    if feedback.timer <= 0 then return end

    local screenW = love.graphics.getWidth()
    local width = 400
    local height = 500
    local x = (screenW - width) / 2
    local y = 50 -- Top of the screen

    -- Draw Box with alpha transparency
    love.graphics.setColor(0, 0, 0, 0.8 * feedback.alpha)
    love.graphics.rectangle("fill", x, y, width, 40, 10)
    
    -- Draw Border
    love.graphics.setColor(1, 0.3, 0.3, feedback.alpha) -- Reddish tint for errors
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, 40, 10)

    -- Draw Text
    love.graphics.setColor(1, 1, 1, feedback.alpha)
    love.graphics.printf(feedback.message, x, y + 12, width, "center")
    
    -- Always reset color!
    love.graphics.setColor(1, 1, 1, 1)
end

-- For now, just draw 5 cards. Reset actions and mana.
local function startTurn()
    DeckManager:startTurn()
    Player:startTurn()
end

-- For now, just move all cards from hand to discard
local function endTurn()
    DeckManager:endTurn()
    EnemyManager:enemyPhase(context)
end

-- Love2D's initialization function
function love.load()
    math.randomseed(os.time())

    require("src.systems.player.player")

    DeckManager:initialize()
    EnemyManager:initialize()
    MapManager:initialize(context)

    StateManager:initialize(context)

    startTurn()
end

function love.update(dt)
    StateManager:update()
    updateFeedback(dt)
end

-- Love2D's drawing
function love.draw()
    StateManager:draw()
    drawFeedback()
end

-- Handle keyboard input
function love.keypressed(key)
    if key == "d" then
        DeckManager:drawCard()
    elseif key == "h" then
        endTurn()
        startTurn() -- Start a new turn immediately after ending the current one (nothing in between for now)
    else
        StateManager:keypressed(key)
    end
end