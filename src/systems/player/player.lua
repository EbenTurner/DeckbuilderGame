---@class Player
---@field hp integer
---@field max_hp integer
---@field actions integer
---@field max_actions integer
---@field mana integer
---@field max_mana integer
local Player = {
    max_hp = 30,
    hp = 15,
    actions = 3,
    max_actions = 3,
    mana = 3,
    max_mana = 3,
}

function Player:startTurn()
    self.actions = self.max_actions
    self.mana = self.max_mana
end

---@param card Card
---@return boolean, string
function Player:playCard(card)
    if card.actionCost > self.actions then
        return false, "ACTIONS"
    elseif card.cost > self.mana then
        return false, "MANA"
    end

    self.mana = self.mana - card.cost
    self.actions = self.actions - card.actionCost

    return true, ""
end

return Player