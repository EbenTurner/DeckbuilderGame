
local CardDB = {}

---@class Card
---@field id string
---@field instanceId integer?               Unique id for a specific card instance
---@field name string
---@field is_action boolean?
---@field is_equipment boolean?
---@field combat_only boolean?              Clarify whether cards are combat only or not
---@field description string
---@field targeted boolean?
---@field cost number?
---@field actionCost number?
---@field damage number?
---@field block number?
---@field effect function?                  The instant effect of the card
---@field x number?                         X position of card
---@field y number?                         Y position of card
---@field w number?                         Width of card
---@field h number?                         Height of card

---@param data Card
---@return Card
function CardDB.create(data)
    local card = {
        id              = data.id,
        name            = data.name,
        is_action       = data.is_action,
        is_equipment    = data.is_equipment,
        combat_only     = data.combat_only,
        targeted        = data.targeted,
        cost            = data.cost         or 0,
        actionCost      = data.actionCost   or 1,
        damage          = data.damage,
        block           = data.block,
        description     = data.description,
        effect          = data.effect,
    }
    return card
end

CardDB.library = {
    ice_bolt = CardDB.create({
        id = "ice_bolt",
        name = "Ice Bolt",
        type = "EVENT",
        combat_only = true,
        targeted = true,
        cost = 2,
        damage = 7,
        description = "Deal 7 damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    }),

    fireball = CardDB.create({
        id = "fireball",
        name = "Fireball",
        type = "EVENT",
        combat_only = true,
        cost = 2,
        damage = 3,
        description = "Deal 3 damage to all enemies.",
        effect = function(self, ctx)
            for _, target in ipairs(ctx.enemies.engaged_enemies) do
                target.hp = target.hp - self.damage
            end
        end,
    }),

    sprint = CardDB.create({
        id = "sprint",
        name = "Sprint",
        type = "EVENT",
        cost = 1,
        description = "Move up to 3 locations away.",
        effect = function(self, ctx)
            ctx.state:switch("roaming", { speed = 3 })
        end,
    }),

    cleave = CardDB.create({
        id = "cleave",
        name = "Cleave",
        type = "EVENT",
        combat_only = true,
        cost = 1,
        damage = 2,
        description = "Deal 2 damage to all enemies.",
        effect = function(self, ctx)
            for _, target in ipairs(ctx.enemies.engaged_enemies) do
                target.hp = target.hp - self.damage
            end
        end,
    }),

    overhead_slash = CardDB.create({
        id = "overhead_slash",
        name = "Overhead Slash",
        type = "EVENT",
        combat_only = true,
        targeted = true,
        cost = 2,
        damage = 5,
        description = "Deal 5 damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    }),

    rush_attack = CardDB.create({
        id = "rush_attack",
        name = "Rush Attack",
        type = "EVENT",
        combat_only = true,
        targeted = true,
        cost = 1,
        damage = 7,
        description = "Deal 7 damage to an enemy, add unbalanced to your draw pile.",
        effect = function(self, ctx, target)
            target.hp = target.hp - self.damage
        end,
    }),

    defend = CardDB.create({
        id = "defend",
        name = "Defend",
        type = "EVENT",
        cost = 1,
        block = 3,
        description = "Gain 3 block.",
        effect = function(self, ctx)
            ctx.player.block = ctx.player.block + self.block
        end,
    }),

    shield_bash = CardDB.create({
        id = "shield_bash",
        name = "Shield Bash",
        type = "EVENT",
        combat_only = true,
        targeted = true,
        cost = 1,
        damage = 3,
        description = "Deal 3 + current block damage to an enemy.",
        effect = function(self, ctx, target)
            target.hp = target.hp - (self.damage + ctx.player.block)
        end,
    }),

    --- Equipment Cards ---

    longsword = CardDB.create({
        id = "longsword",
        name = "Longsword",
        slot = "hand",
        is_equipment = true,
        description = "A trusty sword. Improves attack action, grants 3 new offensive cards."
    }),

    shield = CardDB.create({
        id = "shield",
        name = "Shield",
        slot = "hand",
        is_equipment = true,
        description = "A worn shield. Grants 2 new defensive cards."
    })
}

---@param id string
---@return Card
function CardDB:get(id)
    local card = self.library[id]
    assert(card, "Could not find card in library with id: " .. tostring(id))

    return card
end

return CardDB