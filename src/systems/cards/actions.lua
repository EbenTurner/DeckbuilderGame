local CardDB = require("src.systems.cards.cards")

local ActionDB = {}
setmetatable(ActionDB, { __index = CardDB })

---@class Action : Card
---@field cost number?
local Action = {}
Action.__index = Action
setmetatable(Action, { __index = CardDB.Card })

---@param data Action
---@return Action
function ActionDB.create(data)
    data.is_action = true
    data.cost = data.cost or 0

    local instance = CardDB.create(data)

    ---@cast instance Action
    setmetatable(instance, Action)

    return instance
end

ActionDB.library = {
    attack = ActionDB.create({
        id = "attack",
        name = "Attack",
        combat_only = true,
        targeted = true,
        damage = 1,
        description = "Deal 1 damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    }),

    move = ActionDB.create({
        id = "move",
        name = "Move",
        description = "Move to a connected location.",
        effect = function(self, ctx)
            -- TODO: Add ability to cancel the card, not spending actions, etc.
            ctx.state:switch("roaming", { speed = 1 })
        end,
    }),

    -- Made from asset "Longsword"
    slice = ActionDB.create({
        id = "slice",
        name = "Slice",
        combat_only = true,
        targeted = true,
        damage = 3,
        description = "Deal 3 damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    })
}

return ActionDB