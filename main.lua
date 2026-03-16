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

-- For now, just draw 5 cards at the start of the turn
local function startTurn()
    DeckManager:startTurn()
end

-- For now, just move all cards from hand to discard
local function endTurn()
    DeckManager:endTurn()
end

-- Love2D's initialization function
function love.load()
    math.randomseed(os.time())

    require("src.systems.player.player")

    DeckManager:initialize()
    EnemyManager:initialize()
    MapManager:initialize()

    StateManager:initialize(context)

    startTurn()
end

function love.update()
    StateManager:update()
end

-- Love2D's drawing
function love.draw()
    StateManager:draw()
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