local State = require("src.states.state")
local UI = require("src.ui.renderer")

---@class Passive : State
local Passive = setmetatable({}, { __index = State })
Passive.__index = Passive


---@return Passive
function Passive:new(ctx)
    local instance = State.new(self, ctx, "passive")
    ---@cast instance Passive

    return instance
end

function Passive:enter(data)
    -- any UI changes
end

function Passive:update(dt)
    local local_enemies = self.ctx.enemies:getEnemiesInLocation(self.ctx.map.current)

    if #local_enemies > 0 then
        self.state:switch("combat")
    end
end

function Passive:exit()
    -- Clean up passive
end

function Passive:draw(ctx)
    self.ctx.map:draw(ctx)
end

-- Stop combat cards (i.e. attacks) being used outside of combat
function Passive:keypressed(key)
    if key == "right" or key == "left" then
        self.deck:cycle(key)
    elseif key == "return" then
        local card = self.deck:getSelectedCard()
        if not card.combat_only then
            self.deck:playCard(self.ctx)
        end
    end
end

return Passive